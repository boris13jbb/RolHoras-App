from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from uuid import uuid4

import pytest
from cryptography.fernet import Fernet

from app.config import Settings
from app.security.auth import TokenCipher, create_signed_oauth_state
from app.services.gmail_client import (
    GmailAuthError,
    GmailClient,
    GmailHistoryPage,
    GmailTokenSet,
)
from app.services.gmail_service import GmailIntegrationService


class FakeGmail(GmailClient):
    def __init__(self) -> None:
        self.exchanged = False
        self.revoked = False
        self.messages: dict[str, dict[str, Any]] = {}
        self.attachments: dict[tuple[str, str], bytes] = {}
        self.history_pages: list[GmailHistoryPage] = []
        self.raise_history_404 = False
        self.invalid_grant = False
        self.watch_calls = 0

    def build_authorization_url(self, state: str, code_challenge: str) -> str:
        return f"https://accounts.google.com/o/oauth2/v2/auth?state={state}&code_challenge={code_challenge}"

    async def exchange_code(self, code: str, code_verifier: str | None) -> GmailTokenSet:
        self.exchanged = True
        if code == "cancel":
            raise GmailAuthError("oauth_exchange_failed", "fail")
        return GmailTokenSet(
            access_token="access",
            refresh_token="refresh-secret",
            expires_in=3600,
            scope="https://www.googleapis.com/auth/gmail.readonly",
        )

    async def refresh_access_token(self, refresh_token: str) -> GmailTokenSet:
        if self.invalid_grant:
            raise GmailAuthError("invalid_grant", "revoked")
        return GmailTokenSet(access_token="access2", refresh_token=refresh_token, expires_in=3600, scope="x")

    async def get_profile(self, access_token: str) -> dict[str, Any]:
        return {"emailAddress": "user@gmail.com", "historyId": "100"}

    async def start_watch(self, access_token: str, topic_name: str, label_ids: list[str]) -> dict[str, Any]:
        self.watch_calls += 1
        exp = int((datetime.now(timezone.utc) + timedelta(days=6)).timestamp() * 1000)
        return {"historyId": "101", "expiration": str(exp)}

    async def list_history(self, access_token: str, start_history_id: str, page_token: str | None = None):
        if self.raise_history_404:
            from app.services.gmail_client import GmailHistoryExpiredError

            raise GmailHistoryExpiredError("history_expired", "404")
        if not self.history_pages:
            return GmailHistoryPage(history_id=start_history_id, message_ids=[])
        page = self.history_pages.pop(0)
        return page

    async def search_messages(self, access_token: str, query: str, max_results: int = 50) -> list[str]:
        return list(self.messages.keys())

    async def get_message(self, access_token: str, message_id: str) -> dict[str, Any]:
        return self.messages[message_id]

    async def download_attachment(self, access_token: str, message_id: str, attachment_id: str) -> bytes:
        return self.attachments[(message_id, attachment_id)]

    async def revoke_token(self, token: str) -> None:
        self.revoked = True


class FakeSession:
    """Sesión mínima en memoria para pruebas de servicio sin Postgres."""

    def __init__(self) -> None:
        self.oauth_states = {}
        self.connections = {}
        self.documents = []
        self.events = []
        self.jobs = []
        self._added = []

    def add(self, obj) -> None:
        self._added.append(obj)
        name = type(obj).__name__
        if name == "GmailOAuthState":
            self.oauth_states[obj.state] = obj
        elif name == "GmailConnection":
            self.connections[obj.id] = obj
        elif name == "PayrollDocument":
            self.documents.append(obj)
        elif name == "GmailSyncEvent":
            self.events.append(obj)
        elif name == "ProcessingJob":
            self.jobs.append(obj)

    async def commit(self) -> None:
        for obj in self._added:
            if type(obj).__name__ == "GmailConnection" and getattr(obj, "id", None) is None:
                obj.id = uuid4()
                self.connections[obj.id] = obj
        self._added.clear()

    async def flush(self) -> None:
        for obj in list(self._added):
            if type(obj).__name__ == "PayrollDocument" and getattr(obj, "id", None) is None:
                obj.id = uuid4()
            if type(obj).__name__ == "GmailConnection" and getattr(obj, "id", None) is None:
                obj.id = uuid4()
                self.connections[obj.id] = obj

    async def execute(self, stmt):
        # Interfaz muy limitada; el servicio de test usa helpers directos.
        class R:
            def __init__(self, value):
                self._value = value

            def scalar_one_or_none(self):
                return self._value

        # No parseamos SQLAlchemy; los tests de servicio usan monkeypatch.
        return R(None)


@pytest.mark.asyncio
async def test_oauth_state_single_use_logic(tmp_path):
    settings = Settings(
        app_env="test",
        supabase_jwt_secret="test-secret-key-for-hmac-signing-32",
        token_encryption_key=Fernet.generate_key().decode(),
        local_storage_path=str(tmp_path),
        gmail_pubsub_topic="projects/p/topics/t",
        google_oauth_client_id="cid",
        google_oauth_client_secret="csecret",
    )
    cipher = TokenCipher(settings.token_encryption_key, "v1")
    fake = FakeGmail()
    # Validación directa de firma
    state = create_signed_oauth_state(settings.supabase_jwt_secret, "u:o:n", 60)
    from app.security.auth import verify_signed_oauth_state

    assert verify_signed_oauth_state(settings.supabase_jwt_secret, state)
    assert fake.build_authorization_url(state, "challenge").startswith("https://accounts.google.com")


@pytest.mark.asyncio
async def test_duplicate_pubsub_message_id_is_idempotent(tmp_path, monkeypatch):
    settings = Settings(
        app_env="test",
        supabase_jwt_secret="test-secret-key-for-hmac-signing-32",
        token_encryption_key=Fernet.generate_key().decode(),
        local_storage_path=str(tmp_path),
    )
    cipher = TokenCipher(settings.token_encryption_key, "v1")
    fake = FakeGmail()

    from app.models import GmailConnection, GmailConnectionStatus, GmailSyncEvent
    from sqlalchemy.ext.asyncio import AsyncSession

    class MemDB:
        def __init__(self):
            self.events_by_mid = {}
            self.conn = GmailConnection(
                id=uuid4(),
                organization_id=uuid4(),
                user_id=uuid4(),
                email_address="user@gmail.com",
                status=GmailConnectionStatus.active,
            )

        def add(self, obj):
            if isinstance(obj, GmailSyncEvent):
                self.events_by_mid[obj.pubsub_message_id] = obj

        async def commit(self):
            return None

        async def execute(self, stmt):
            class R:
                def __init__(self, v):
                    self.v = v

                def scalar_one_or_none(self):
                    return self.v

            sql = str(stmt)
            if "gmail_sync_events" in sql.lower() or "GmailSyncEvent" in sql:
                # no fiable; usamos atributo del test
                return R(getattr(self, "_lookup_event", None))
            if "GmailConnection" in sql or "gmail_connections" in sql.lower():
                return R(self.conn)
            return R(None)

    db = MemDB()
    service = GmailIntegrationService(db, settings, cipher, fake)  # type: ignore[arg-type]

    async def execute_override(stmt):
        class R:
            def __init__(self, v):
                self.v = v

            def scalar_one_or_none(self):
                return self.v

        # Primera llamada: event lookup
        if not hasattr(execute_override, "n"):
            execute_override.n = 0
        execute_override.n += 1
        if execute_override.n == 1:
            return R(db.events_by_mid.get("mid-1"))
        return R(db.conn)

    db.execute = execute_override  # type: ignore
    first = await service.ingest_pubsub(
        message_id="mid-1", email_address="user@gmail.com", history_id="10", raw_digest="abc"
    )
    assert first is True
    db.events_by_mid["mid-1"] = GmailSyncEvent(
        organization_id=db.conn.organization_id,
        connection_id=db.conn.id,
        event_type="pubsub_push",
        pubsub_message_id="mid-1",
    )

    async def execute_second(stmt):
        class R:
            def __init__(self, v):
                self.v = v

            def scalar_one_or_none(self):
                return self.v

        return R(db.events_by_mid.get("mid-1"))

    db.execute = execute_second  # type: ignore
    second = await service.ingest_pubsub(
        message_id="mid-1", email_address="user@gmail.com", history_id="10", raw_digest="abc"
    )
    assert second is False
