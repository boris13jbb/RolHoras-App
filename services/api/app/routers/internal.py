from __future__ import annotations

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


def _verify_scheduler(
    authorization: str | None,
    x_internal_token: str | None,
    settings: Settings,
) -> None:
    """Autoriza jobs de reconciliación / renovación de watch.

    Preferido: `X-Internal-Token` == SCHEDULER_SECRET (cron Render / Cloud Scheduler).
    Alternativa en no-producción: Bearer presente (OIDC pendiente de endurecer).
    """
    expected = (settings.scheduler_secret or settings.supabase_jwt_secret or "").strip()
    if expected and x_internal_token and x_internal_token.strip() == expected:
        return
    if settings.app_env == "production":
        raise HTTPException(
            status_code=401,
            detail={
                "code": "unauthorized",
                "message": "Se requiere X-Internal-Token válido (SCHEDULER_SECRET)",
            },
        )
    # desarrollo: permitir sin token si no hay secreto configurado
    if expected and x_internal_token and x_internal_token.strip() != expected:
        raise HTTPException(
            status_code=401,
            detail={"code": "unauthorized", "message": "Token interno inválido"},
        )


@router.post("/internal/gmail/renew-watches")
async def renew_watches(
    authorization: str | None = Header(default=None),
    x_internal_token: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    cipher: TokenCipher = Depends(get_token_cipher),
):
    _verify_scheduler(authorization, x_internal_token, settings)

    service = GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))
    result = await db.execute(
        select(GmailConnection).where(
            GmailConnection.status.in_(
                [
                    GmailConnectionStatus.active,
                    GmailConnectionStatus.syncing,
                    GmailConnectionStatus.error,
                ]
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
    _verify_scheduler(authorization, x_internal_token, settings)
    service = GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))
    result = await db.execute(
        select(GmailConnection).where(GmailConnection.status == GmailConnectionStatus.active)
    )
    total = 0
    synced = 0
    for conn in result.scalars().all():
        # Reconciliación periódica: sync incremental; si no hay historyId, completa.
        full = not bool(conn.history_id)
        total += await service.sync_connection(conn.id, full=full)
        synced += 1
    return {"connections_synced": synced, "documents_imported": total}
