from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import GmailConnection, GmailConnectionStatus
from app.security.auth import TokenCipher, get_token_cipher
from app.services.gmail_client import HttpGmailClient
from app.services.gmail_service import GmailIntegrationService

router = APIRouter(tags=["internal"])


def _verify_scheduler(authorization: str | None, settings: Settings) -> None:
    """Protección mínima para Scheduler/Cloud Tasks.

    En producción debe validarse OIDC de Google. En desarrollo se acepta
    el header `X-Internal-Token` comparado con SUPABASE_JWT_SECRET.
    """
    if settings.app_env == "production":
        if not authorization or not authorization.lower().startswith("bearer "):
            raise HTTPException(status_code=401, detail={"code": "unauthorized", "message": "OIDC requerido"})
        return
    # desarrollo: sin OIDC obligatorio


@router.post("/internal/gmail/renew-watches")
async def renew_watches(
    authorization: str | None = Header(default=None),
    x_internal_token: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    cipher: TokenCipher = Depends(get_token_cipher),
):
    _verify_scheduler(authorization, settings)
    if settings.app_env != "production" and x_internal_token and x_internal_token != settings.supabase_jwt_secret:
        raise HTTPException(status_code=401, detail={"code": "unauthorized", "message": "Token interno inválido"})

    service = GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))
    result = await db.execute(
        select(GmailConnection).where(
            GmailConnection.status.in_(
                [GmailConnectionStatus.active, GmailConnectionStatus.syncing, GmailConnectionStatus.error]
            )
        )
    )
    renewed = 0
    for conn in result.scalars().all():
        try:
            await service.renew_watch(conn.id)
            renewed += 1
        except Exception:
            conn.last_error_code = "watch_renew_failed"
            conn.last_error_message = "No se pudo renovar users.watch"
            await db.commit()
    return {"renewed": renewed}


@router.post("/internal/gmail/reconcile")
async def reconcile_gmail(
    authorization: str | None = Header(default=None),
    x_internal_token: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    cipher: TokenCipher = Depends(get_token_cipher),
):
    _verify_scheduler(authorization, settings)
    service = GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))
    result = await db.execute(
        select(GmailConnection).where(GmailConnection.status == GmailConnectionStatus.active)
    )
    total = 0
    for conn in result.scalars().all():
        total += await service.sync_connection(conn.id, full=False)
    return {"documents_imported": total}
