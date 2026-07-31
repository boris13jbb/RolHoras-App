from __future__ import annotations

import base64
import hashlib
import json
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import MembershipRole
from app.schemas import GmailAuthorizeResponse, GmailStatusResponse, GmailSyncResponse
from app.security.auth import AuthUser, TokenCipher, get_current_user, get_token_cipher, require_org_membership
from app.services.audit import record_audit
from app.services.gmail_client import HttpGmailClient
from app.services.gmail_service import GmailIntegrationService
from app.services.pubsub_auth import verify_pubsub_push_jwt

router = APIRouter(tags=["gmail"])


def _service(
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    cipher: TokenCipher = Depends(get_token_cipher),
) -> GmailIntegrationService:
    return GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))


@router.get("/integrations/gmail/authorize", response_model=GmailAuthorizeResponse)
async def gmail_authorize(
    organization_id: str = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: GmailIntegrationService = Depends(_service),
):
    from uuid import UUID

    org_id = UUID(organization_id)
    await require_org_membership(org_id, user, db)
    try:
        data = await service.begin_authorize(user.user_id, org_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=503,
            detail={"code": "oauth_not_configured", "message": str(exc)},
        ) from exc
    await record_audit(
        db,
        organization_id=org_id,
        actor_user_id=user.user_id,
        action="gmail.authorize_started",
        resource_type="gmail_connection",
    )
    return data


@router.get("/integrations/gmail/callback")
async def gmail_callback(
    code: str | None = None,
    state: str | None = None,
    error: str | None = None,
    service: GmailIntegrationService = Depends(_service),
    settings: Settings = Depends(get_settings),
):
    result = await service.handle_callback(code, state, error)
    if result.get("ok"):
        # Redirige al panel/app; no expone tokens.
        target = f"{settings.admin_web_url}/gmail/connected?email={result.get('email_address','')}"
        return RedirectResponse(url=target, status_code=302)
    html = f"""<!doctype html><html lang="es"><body>
    <h1>No se pudo conectar Gmail</h1>
    <p>{result.get('message')}</p>
    <p>Código: {result.get('error')}</p>
    </body></html>"""
    return HTMLResponse(content=html, status_code=400)


@router.get("/integrations/gmail/status", response_model=GmailStatusResponse)
async def gmail_status(
    organization_id: str = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: GmailIntegrationService = Depends(_service),
):
    from uuid import UUID

    org_id = UUID(organization_id)
    await require_org_membership(org_id, user, db)
    return await service.get_status(user.user_id, org_id)


@router.post("/integrations/gmail/sync", response_model=GmailSyncResponse)
async def gmail_sync(
    organization_id: str = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: GmailIntegrationService = Depends(_service),
):
    from uuid import UUID

    from sqlalchemy import select

    from app.models import GmailConnection

    org_id = UUID(organization_id)
    await require_org_membership(org_id, user, db)
    result = await db.execute(
        select(GmailConnection).where(
            GmailConnection.organization_id == org_id,
            GmailConnection.user_id == user.user_id,
        )
    )
    conn = result.scalar_one_or_none()
    if conn is None:
        raise HTTPException(status_code=404, detail={"code": "not_connected", "message": "Gmail no conectado"})
    imported = await service.sync_connection(conn.id, full=False)
    return GmailSyncResponse(
        status="ok",
        documents_imported=imported,
        message=f"Sincronización completada. Documentos nuevos: {imported}",
    )


@router.delete("/integrations/gmail")
async def gmail_disconnect(
    organization_id: str = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: GmailIntegrationService = Depends(_service),
):
    from uuid import UUID

    org_id = UUID(organization_id)
    await require_org_membership(org_id, user, db)
    await service.disconnect(user.user_id, org_id)
    await record_audit(
        db,
        organization_id=org_id,
        actor_user_id=user.user_id,
        action="gmail.disconnected",
        resource_type="gmail_connection",
    )
    return {"status": "revoked"}


@router.post("/webhooks/gmail/pubsub")
async def gmail_pubsub_webhook(
    request: Request,
    authorization: str | None = Header(default=None),
    service: GmailIntegrationService = Depends(_service),
    settings: Settings = Depends(get_settings),
):
    """Webhook Pub/Sub: valida JWT, persiste evento, responde 2xx rápido. No procesa PDF."""
    body = await request.body()
    if settings.app_env == "production" or settings.gmail_pubsub_audience:
        try:
            verify_pubsub_push_jwt(authorization, audience=settings.gmail_pubsub_audience or settings.api_public_url)
        except Exception as exc:
            raise HTTPException(status_code=401, detail={"code": "invalid_pubsub_jwt", "message": "JWT inválido"}) from exc

    try:
        envelope = json.loads(body.decode() or "{}")
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail={"code": "invalid_payload", "message": "JSON inválido"}) from exc

    message = envelope.get("message") or {}
    message_id = message.get("messageId") or message.get("message_id")
    data_b64 = message.get("data")
    if not message_id or not data_b64:
        raise HTTPException(status_code=400, detail={"code": "invalid_payload", "message": "Mensaje incompleto"})

    try:
        decoded = base64.b64decode(data_b64)
        notification = json.loads(decoded.decode())
    except Exception as exc:
        raise HTTPException(status_code=400, detail={"code": "invalid_payload", "message": "data inválida"}) from exc

    email_address = notification.get("emailAddress") or ""
    history_id = str(notification.get("historyId") or "")
    digest = hashlib.sha256(body).hexdigest()
    await service.ingest_pubsub(
        message_id=message_id,
        email_address=email_address,
        history_id=history_id,
        raw_digest=digest,
    )
    # Siempre 204/200 para ack; duplicados ya son no-ops.
    return {"status": "accepted"}
