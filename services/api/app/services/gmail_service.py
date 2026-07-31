from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.logging_setup import get_logger
from app.models import (
    DocumentStatus,
    GmailConnection,
    GmailConnectionStatus,
    GmailOAuthState,
    GmailSyncEvent,
    JobStatus,
    PayrollDocument,
    ProcessingJob,
)
from app.security.auth import TokenCipher, create_signed_oauth_state, generate_pkce_pair, verify_signed_oauth_state
from app.services.gmail_client import (
    GmailAuthError,
    GmailHistoryExpiredError,
    HttpGmailClient,
    header_value,
    sender_matches,
    sha256_hex,
    subject_matches,
    validate_pdf_bytes,
    walk_mime_parts,
)
from app.services.storage import StorageService

logger = get_logger(__name__)


class GmailIntegrationService:
    def __init__(
        self,
        db: AsyncSession,
        settings: Settings,
        cipher: TokenCipher,
        gmail: HttpGmailClient | None = None,
        storage: StorageService | None = None,
    ) -> None:
        self.db = db
        self.settings = settings
        self.cipher = cipher
        self.gmail = gmail or HttpGmailClient(settings)
        self.storage = storage or StorageService(settings)

    async def begin_authorize(self, user_id: UUID, organization_id: UUID) -> dict:
        if not self.settings.google_oauth_configured:
            raise ValueError(
                "GOOGLE_OAUTH_CLIENT_ID / GOOGLE_OAUTH_CLIENT_SECRET no están "
                "configurados en el .env de la raíz del proyecto."
            )
        verifier, challenge = generate_pkce_pair()
        nonce = uuid4().hex
        payload = f"{user_id}:{organization_id}:{nonce}"
        state = create_signed_oauth_state(self.settings.supabase_jwt_secret, payload, ttl_seconds=600)
        expires = datetime.now(timezone.utc) + timedelta(seconds=600)
        self.db.add(
            GmailOAuthState(
                state=state,
                user_id=user_id,
                organization_id=organization_id,
                code_verifier=verifier,
                nonce=nonce,
                expires_at=expires,
            )
        )
        await self.db.commit()
        url = self.gmail.build_authorization_url(state, challenge)
        return {"authorization_url": url, "state": state, "expires_in_seconds": 600}

    async def handle_callback(self, code: str | None, state: str | None, error: str | None) -> dict:
        if error:
            return {"ok": False, "error": error, "message": "OAuth cancelado o rechazado"}
        if not code or not state:
            return {"ok": False, "error": "missing_params", "message": "Faltan code o state"}

        try:
            verify_signed_oauth_state(self.settings.supabase_jwt_secret, state)
        except ValueError as exc:
            return {"ok": False, "error": "invalid_state", "message": str(exc)}

        result = await self.db.execute(select(GmailOAuthState).where(GmailOAuthState.state == state))
        row = result.scalar_one_or_none()
        if row is None:
            return {"ok": False, "error": "unknown_state", "message": "state desconocido"}
        if row.used_at is not None:
            return {"ok": False, "error": "state_reused", "message": "state ya utilizado"}
        if row.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
            return {"ok": False, "error": "state_expired", "message": "state expirado"}

        row.used_at = datetime.now(timezone.utc)
        try:
            tokens = await self.gmail.exchange_code(code, row.code_verifier)
        except GmailAuthError as exc:
            await self.db.commit()
            return {"ok": False, "error": exc.code, "message": exc.message}

        if not tokens.refresh_token:
            await self.db.commit()
            return {
                "ok": False,
                "error": "missing_refresh_token",
                "message": "Google no devolvió refresh token. Revoca el acceso y vuelve a conectar.",
            }

        profile = await self.gmail.get_profile(tokens.access_token)
        email_address = profile.get("emailAddress")
        history_id = str(profile.get("historyId", ""))

        conn_result = await self.db.execute(
            select(GmailConnection).where(
                GmailConnection.organization_id == row.organization_id,
                GmailConnection.user_id == row.user_id,
            )
        )
        connection = conn_result.scalar_one_or_none()
        if connection is None:
            connection = GmailConnection(
                organization_id=row.organization_id,
                user_id=row.user_id,
            )
            self.db.add(connection)

        connection.email_address = email_address
        connection.google_account_id = email_address
        connection.refresh_token_ciphertext = self.cipher.encrypt(tokens.refresh_token)
        connection.refresh_token_key_version = self.cipher.key_version
        connection.scopes = [s for s in tokens.scope.split() if s]
        connection.history_id = history_id
        connection.status = GmailConnectionStatus.active
        connection.last_error_code = None
        connection.last_error_message = None

        if self.settings.gmail_pubsub_topic:
            try:
                labels = [x.strip() for x in self.settings.gmail_watch_labels.split(",") if x.strip()]
                watch = await self.gmail.start_watch(
                    tokens.access_token, self.settings.gmail_pubsub_topic, labels or ["INBOX"]
                )
                exp_ms = watch.get("expiration")
                if exp_ms:
                    connection.watch_expiration = datetime.fromtimestamp(int(exp_ms) / 1000, tz=timezone.utc)
                if watch.get("historyId"):
                    connection.history_id = str(watch["historyId"])
            except Exception:
                logger.exception("watch_failed")
                connection.last_error_code = "watch_failed"
                connection.last_error_message = "No se pudo registrar users.watch"

        await self.db.commit()

        # Sincronización inicial (no bloquea la respuesta del navegador demasiado; en prod encolar)
        imported = await self.sync_connection(connection.id, full=True)
        return {
            "ok": True,
            "email_address": email_address,
            "organization_id": str(row.organization_id),
            "documents_imported": imported,
        }

    async def get_status(self, user_id: UUID, organization_id: UUID) -> dict:
        result = await self.db.execute(
            select(GmailConnection).where(
                GmailConnection.organization_id == organization_id,
                GmailConnection.user_id == user_id,
            )
        )
        conn = result.scalar_one_or_none()
        if conn is None:
            return {
                "connected": False,
                "status": "disconnected",
            }
        return {
            "connected": conn.status
            in {
                GmailConnectionStatus.active,
                GmailConnectionStatus.syncing,
                GmailConnectionStatus.error,
                GmailConnectionStatus.requires_reauth,
            }
            and conn.refresh_token_ciphertext is not None,
            "status": conn.status.value,
            "email_address": conn.email_address,
            "last_sync_at": conn.last_sync_at,
            "last_success_at": conn.last_success_at,
            "watch_expiration": conn.watch_expiration,
            "sender_filter": conn.sender_filter,
            "last_error_code": conn.last_error_code,
            "last_error_message": conn.last_error_message,
        }

    async def disconnect(self, user_id: UUID, organization_id: UUID) -> None:
        result = await self.db.execute(
            select(GmailConnection).where(
                GmailConnection.organization_id == organization_id,
                GmailConnection.user_id == user_id,
            )
        )
        conn = result.scalar_one_or_none()
        if conn is None:
            return
        if conn.refresh_token_ciphertext:
            try:
                token = self.cipher.decrypt(conn.refresh_token_ciphertext)
                await self.gmail.revoke_token(token)
            except Exception:
                logger.info("revoke_failed_ignored")
        conn.refresh_token_ciphertext = None
        conn.status = GmailConnectionStatus.revoked
        conn.last_error_code = None
        conn.last_error_message = None
        await self.db.commit()

    async def _access_token(self, conn: GmailConnection) -> str:
        if not conn.refresh_token_ciphertext:
            raise GmailAuthError("requires_reauth", "Sin refresh token")
        refresh = self.cipher.decrypt(conn.refresh_token_ciphertext)
        try:
            tokens = await self.gmail.refresh_access_token(refresh)
        except GmailAuthError as exc:
            if exc.code == "invalid_grant":
                conn.status = GmailConnectionStatus.requires_reauth
                conn.last_error_code = "invalid_grant"
                conn.last_error_message = "Debes reconectar Gmail"
                await self.db.commit()
            raise
        return tokens.access_token

    async def sync_connection(self, connection_id: UUID, full: bool = False) -> int:
        result = await self.db.execute(select(GmailConnection).where(GmailConnection.id == connection_id))
        conn = result.scalar_one_or_none()
        if conn is None:
            return 0

        conn.status = GmailConnectionStatus.syncing
        conn.last_sync_at = datetime.now(timezone.utc)
        await self.db.commit()

        try:
            access = await self._access_token(conn)
        except GmailAuthError:
            return 0

        imported = 0
        try:
            if full or not conn.history_id:
                imported = await self._full_sync(conn, access)
            else:
                try:
                    imported = await self._history_sync(conn, access)
                except GmailHistoryExpiredError:
                    imported = await self._full_sync(conn, access)
            conn.status = GmailConnectionStatus.active
            conn.last_success_at = datetime.now(timezone.utc)
            conn.last_error_code = None
            conn.last_error_message = None
        except Exception as exc:
            logger.exception("sync_failed", connection_id=str(connection_id))
            conn.status = GmailConnectionStatus.error
            conn.last_error_code = "sync_failed"
            conn.last_error_message = "Error al sincronizar Gmail"
            # no filtrar str(exc) sensible
            _ = exc
        await self.db.commit()
        return imported

    async def _full_sync(self, conn: GmailConnection, access: str) -> int:
        query_parts = ["has:attachment filename:pdf"]
        if conn.sender_filter:
            query_parts.append(f"from:{conn.sender_filter}")
        if conn.subject_pattern:
            query_parts.append(f"subject:{conn.subject_pattern}")
        message_ids = await self.gmail.search_messages(access, " ".join(query_parts), max_results=30)
        imported = 0
        for mid in message_ids:
            imported += await self._import_message(conn, access, mid)
        profile = await self.gmail.get_profile(access)
        if profile.get("historyId"):
            conn.history_id = str(profile["historyId"])
        return imported

    async def _history_sync(self, conn: GmailConnection, access: str) -> int:
        assert conn.history_id
        imported = 0
        page_token: Optional[str] = None
        latest_history = conn.history_id
        while True:
            page = await self.gmail.list_history(access, conn.history_id, page_token)
            latest_history = page.history_id
            for mid in page.message_ids:
                imported += await self._import_message(conn, access, mid)
            if not page.next_page_token:
                break
            page_token = page.next_page_token
        conn.history_id = latest_history
        return imported

    async def _import_message(self, conn: GmailConnection, access: str, message_id: str) -> int:
        message = await self.gmail.get_message(access, message_id)
        from_h = header_value(message, "From")
        subject = header_value(message, "Subject")
        if not sender_matches(from_h, conn.sender_filter):
            return 0
        if not subject_matches(subject, conn.subject_pattern):
            return 0

        parts = walk_mime_parts(message.get("payload") or {})
        count = 0
        for part in parts:
            # Idempotencia previa
            existing = await self.db.execute(
                select(PayrollDocument).where(
                    PayrollDocument.gmail_connection_id == conn.id,
                    PayrollDocument.gmail_message_id == message_id,
                    PayrollDocument.gmail_attachment_id == part["attachment_id"],
                )
            )
            if existing.scalar_one_or_none():
                continue

            raw = await self.gmail.download_attachment(access, message_id, part["attachment_id"])
            try:
                validate_pdf_bytes(raw, self.settings.pdf_max_bytes)
            except ValueError:
                continue

            digest = sha256_hex(raw)
            dup = await self.db.execute(
                select(PayrollDocument).where(
                    PayrollDocument.organization_id == conn.organization_id,
                    PayrollDocument.content_sha256 == digest,
                )
            )
            if dup.scalar_one_or_none():
                continue

            storage_path = await self.storage.save_bytes(
                organization_id=conn.organization_id,
                user_id=conn.user_id,
                filename=part["filename"],
                data=raw,
            )
            doc = PayrollDocument(
                organization_id=conn.organization_id,
                owner_user_id=conn.user_id,
                gmail_connection_id=conn.id,
                gmail_message_id=message_id,
                gmail_attachment_id=part["attachment_id"],
                source="gmail",
                original_filename=part["filename"],
                content_sha256=digest,
                storage_path=storage_path,
                mime_type="application/pdf",
                size_bytes=len(raw),
                status=DocumentStatus.queued,
            )
            self.db.add(doc)
            await self.db.flush()
            self.db.add(
                ProcessingJob(
                    organization_id=conn.organization_id,
                    document_id=doc.id,
                    job_type="extract_payroll_pdf",
                    status=JobStatus.pending,
                    payload={"document_id": str(doc.id)},
                )
            )
            count += 1
        await self.db.commit()
        return count

    async def ingest_pubsub(
        self,
        *,
        message_id: str,
        email_address: str,
        history_id: str,
        raw_digest: str,
    ) -> bool:
        """Persiste evento e encola sync. Idempotente por pubsub_message_id."""
        existing = await self.db.execute(
            select(GmailSyncEvent).where(GmailSyncEvent.pubsub_message_id == message_id)
        )
        if existing.scalar_one_or_none():
            return False

        result = await self.db.execute(
            select(GmailConnection).where(GmailConnection.email_address == email_address)
        )
        conn = result.scalar_one_or_none()
        if conn is None:
            # Evento huérfano: se registra sin conexión
            return False

        event = GmailSyncEvent(
            organization_id=conn.organization_id,
            connection_id=conn.id,
            event_type="pubsub_push",
            history_id=history_id,
            pubsub_message_id=message_id,
            payload_digest=raw_digest,
            status="queued",
        )
        self.db.add(event)
        self.db.add(
            ProcessingJob(
                organization_id=conn.organization_id,
                job_type="gmail_sync",
                status=JobStatus.pending,
                payload={"connection_id": str(conn.id), "history_id": history_id},
            )
        )
        await self.db.commit()
        return True

    async def renew_watch(self, connection_id: UUID) -> None:
        result = await self.db.execute(select(GmailConnection).where(GmailConnection.id == connection_id))
        conn = result.scalar_one_or_none()
        if conn is None or not self.settings.gmail_pubsub_topic:
            return
        access = await self._access_token(conn)
        labels = [x.strip() for x in self.settings.gmail_watch_labels.split(",") if x.strip()]
        watch = await self.gmail.start_watch(access, self.settings.gmail_pubsub_topic, labels or ["INBOX"])
        exp_ms = watch.get("expiration")
        if exp_ms:
            conn.watch_expiration = datetime.fromtimestamp(int(exp_ms) / 1000, tz=timezone.utc)
        await self.db.commit()
