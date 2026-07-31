from __future__ import annotations

import base64
import hashlib
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Optional
from urllib.parse import urlencode

import httpx

from app.config import Settings

GMAIL_READONLY = "https://www.googleapis.com/auth/gmail.readonly"
PDF_MAGIC = b"%PDF"


@dataclass
class GmailTokenSet:
    access_token: str
    refresh_token: Optional[str]
    expires_in: int
    scope: str
    token_type: str = "Bearer"
    id_token: Optional[str] = None


@dataclass
class GmailAttachment:
    message_id: str
    attachment_id: str
    filename: str
    mime_type: str
    data: bytes
    internal_date: Optional[datetime] = None


@dataclass
class GmailHistoryPage:
    history_id: str
    message_ids: list[str] = field(default_factory=list)
    next_page_token: Optional[str] = None


class GmailClient(ABC):
    @abstractmethod
    async def exchange_code(self, code: str, code_verifier: str | None) -> GmailTokenSet: ...

    @abstractmethod
    async def refresh_access_token(self, refresh_token: str) -> GmailTokenSet: ...

    @abstractmethod
    async def get_profile(self, access_token: str) -> dict[str, Any]: ...

    @abstractmethod
    async def start_watch(self, access_token: str, topic_name: str, label_ids: list[str]) -> dict[str, Any]: ...

    @abstractmethod
    async def list_history(
        self, access_token: str, start_history_id: str, page_token: str | None = None
    ) -> GmailHistoryPage: ...

    @abstractmethod
    async def search_messages(self, access_token: str, query: str, max_results: int = 50) -> list[str]: ...

    @abstractmethod
    async def get_message(self, access_token: str, message_id: str) -> dict[str, Any]: ...

    @abstractmethod
    async def download_attachment(
        self, access_token: str, message_id: str, attachment_id: str
    ) -> bytes: ...

    @abstractmethod
    async def revoke_token(self, token: str) -> None: ...


class HttpGmailClient(GmailClient):
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def build_authorization_url(self, state: str, code_challenge: str) -> str:
        params = {
            "client_id": self.settings.google_oauth_client_id,
            "redirect_uri": self.settings.google_oauth_redirect_uri,
            "response_type": "code",
            "scope": GMAIL_READONLY,
            "access_type": "offline",
            "include_granted_scopes": "true",
            "prompt": "consent",
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
        }
        return f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}"

    async def exchange_code(self, code: str, code_verifier: str | None) -> GmailTokenSet:
        data = {
            "code": code,
            "client_id": self.settings.google_oauth_client_id,
            "client_secret": self.settings.google_oauth_client_secret,
            "redirect_uri": self.settings.google_oauth_redirect_uri,
            "grant_type": "authorization_code",
        }
        if code_verifier:
            data["code_verifier"] = code_verifier
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post("https://oauth2.googleapis.com/token", data=data)
            if resp.status_code >= 400:
                # Mensaje seguro: solo el error de Google, nunca secretos ni tokens.
                google_error = "oauth_exchange_failed"
                try:
                    google_error = str((resp.json() or {}).get("error") or google_error)
                except Exception:
                    pass
                raise GmailAuthError(
                    "oauth_exchange_failed",
                    f"No se pudo completar OAuth ({google_error}). "
                    "Revisa CLIENT_ID, CLIENT_SECRET y la URI de redirección.",
                )
            body = resp.json()
        return GmailTokenSet(
            access_token=body["access_token"],
            refresh_token=body.get("refresh_token"),
            expires_in=int(body.get("expires_in", 3600)),
            scope=body.get("scope", GMAIL_READONLY),
            id_token=body.get("id_token"),
        )

    async def refresh_access_token(self, refresh_token: str) -> GmailTokenSet:
        data = {
            "client_id": self.settings.google_oauth_client_id,
            "client_secret": self.settings.google_oauth_client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post("https://oauth2.googleapis.com/token", data=data)
            if resp.status_code == 400 and "invalid_grant" in resp.text:
                raise GmailAuthError("invalid_grant", "La conexión de Gmail requiere reconexión")
            if resp.status_code >= 400:
                raise GmailAuthError("token_refresh_failed", "No se pudo renovar el token")
            body = resp.json()
        return GmailTokenSet(
            access_token=body["access_token"],
            refresh_token=refresh_token,
            expires_in=int(body.get("expires_in", 3600)),
            scope=body.get("scope", GMAIL_READONLY),
        )

    async def get_profile(self, access_token: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(
                "https://gmail.googleapis.com/gmail/v1/users/me/profile",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            resp.raise_for_status()
            return resp.json()

    async def start_watch(self, access_token: str, topic_name: str, label_ids: list[str]) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                "https://gmail.googleapis.com/gmail/v1/users/me/watch",
                headers={"Authorization": f"Bearer {access_token}"},
                json={"topicName": topic_name, "labelIds": label_ids},
            )
            resp.raise_for_status()
            return resp.json()

    async def list_history(
        self, access_token: str, start_history_id: str, page_token: str | None = None
    ) -> GmailHistoryPage:
        params: dict[str, Any] = {
            "startHistoryId": start_history_id,
            "historyTypes": "messageAdded",
        }
        if page_token:
            params["pageToken"] = page_token
        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.get(
                "https://gmail.googleapis.com/gmail/v1/users/me/history",
                headers={"Authorization": f"Bearer {access_token}"},
                params=params,
            )
            if resp.status_code == 404:
                raise GmailHistoryExpiredError("history_expired", "historyId expirado")
            resp.raise_for_status()
            body = resp.json()
        message_ids: list[str] = []
        for item in body.get("history", []):
            for added in item.get("messagesAdded", []):
                mid = added.get("message", {}).get("id")
                if mid:
                    message_ids.append(mid)
        return GmailHistoryPage(
            history_id=str(body.get("historyId", start_history_id)),
            message_ids=message_ids,
            next_page_token=body.get("nextPageToken"),
        )

    async def search_messages(self, access_token: str, query: str, max_results: int = 50) -> list[str]:
        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.get(
                "https://gmail.googleapis.com/gmail/v1/users/me/messages",
                headers={"Authorization": f"Bearer {access_token}"},
                params={"q": query, "maxResults": max_results},
            )
            resp.raise_for_status()
            body = resp.json()
        return [m["id"] for m in body.get("messages", [])]

    async def get_message(self, access_token: str, message_id: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.get(
                f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}",
                headers={"Authorization": f"Bearer {access_token}"},
                params={"format": "full"},
            )
            resp.raise_for_status()
            return resp.json()

    async def download_attachment(self, access_token: str, message_id: str, attachment_id: str) -> bytes:
        async with httpx.AsyncClient(timeout=120) as client:
            resp = await client.get(
                f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}/attachments/{attachment_id}",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            resp.raise_for_status()
            data_b64 = resp.json().get("data", "")
        return decode_base64url(data_b64)

    async def revoke_token(self, token: str) -> None:
        async with httpx.AsyncClient(timeout=30) as client:
            await client.post("https://oauth2.googleapis.com/revoke", data={"token": token})


class GmailAuthError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        self.message = message
        super().__init__(message)


class GmailHistoryExpiredError(GmailAuthError):
    pass


def decode_base64url(data: str) -> bytes:
    pad = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + pad)


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate_pdf_bytes(data: bytes, max_bytes: int) -> None:
    if len(data) == 0:
        raise ValueError("Archivo vacío")
    if len(data) > max_bytes:
        raise ValueError("Archivo demasiado grande")
    if not data.startswith(PDF_MAGIC):
        raise ValueError("Firma PDF inválida")


def walk_mime_parts(payload: dict[str, Any]) -> list[dict[str, Any]]:
    """Recorre partes MIME de forma recursiva."""
    parts: list[dict[str, Any]] = []

    def _walk(node: dict[str, Any]) -> None:
        if not node:
            return
        filename = None
        for h in node.get("headers", []):
            if h.get("name", "").lower() == "content-disposition":
                match = re.search(r'filename="?([^";]+)"?', h.get("value", ""), re.I)
                if match:
                    filename = match.group(1)
        mime = node.get("mimeType", "")
        body = node.get("body") or {}
        if body.get("attachmentId") and (mime == "application/pdf" or (filename or "").lower().endswith(".pdf")):
            parts.append(
                {
                    "attachment_id": body["attachmentId"],
                    "filename": filename or "rol.pdf",
                    "mime_type": mime or "application/pdf",
                    "size": body.get("size", 0),
                }
            )
        for child in node.get("parts") or []:
            _walk(child)

    _walk(payload)
    return parts


def header_value(message: dict[str, Any], name: str) -> str:
    payload = message.get("payload") or {}
    for h in payload.get("headers") or []:
        if h.get("name", "").lower() == name.lower():
            return h.get("value") or ""
    return ""


def sender_matches(from_header: str, allowed: str | None) -> bool:
    if not allowed:
        return True
    return allowed.lower() in from_header.lower()


def subject_matches(subject: str, pattern: str | None) -> bool:
    if not pattern:
        return True
    return re.search(pattern, subject, re.IGNORECASE) is not None
