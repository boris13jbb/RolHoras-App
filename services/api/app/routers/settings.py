from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import GmailConnection, PdfSecret
from app.security.auth import AuthUser, TokenCipher, get_current_user, get_token_cipher, require_org_membership
from app.services.audit import record_audit
from app.services.gmail_client import HttpGmailClient
from app.services.gmail_service import GmailIntegrationService

router = APIRouter(tags=["settings"])


class PdfPasswordUpsert(BaseModel):
    password: str = Field(min_length=1, max_length=256)


class PdfPasswordStatus(BaseModel):
    configured: bool


class GmailFiltersUpdate(BaseModel):
    sender_filter: str | None = Field(default=None, max_length=320)
    subject_pattern: str | None = Field(default=None, max_length=320)


class GmailFiltersOut(BaseModel):
    sender_filter: str | None = None
    subject_pattern: str | None = None
    connected: bool = False
    email_address: str | None = None
    documents_imported: int | None = None


@router.get("/settings/pdf-password", response_model=PdfPasswordStatus)
async def pdf_password_status(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    row = (
        await db.execute(
            select(PdfSecret).where(
                PdfSecret.organization_id == organization_id,
                PdfSecret.user_id == user.user_id,
            )
        )
    ).scalar_one_or_none()
    return PdfPasswordStatus(configured=row is not None)


@router.put("/settings/pdf-password", response_model=PdfPasswordStatus)
async def upsert_pdf_password(
    body: PdfPasswordUpsert,
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    cipher: TokenCipher = Depends(get_token_cipher),
):
    await require_org_membership(organization_id, user, db)
    row = (
        await db.execute(
            select(PdfSecret).where(
                PdfSecret.organization_id == organization_id,
                PdfSecret.user_id == user.user_id,
            )
        )
    ).scalar_one_or_none()
    ciphertext = cipher.encrypt(body.password)
    if row is None:
        row = PdfSecret(
            organization_id=organization_id,
            user_id=user.user_id,
            password_ciphertext=ciphertext,
            key_version=cipher.key_version,
        )
        db.add(row)
    else:
        row.password_ciphertext = ciphertext
        row.key_version = cipher.key_version
    await db.commit()
    await record_audit(
        db,
        organization_id=organization_id,
        actor_user_id=user.user_id,
        action="pdf_password.upserted",
        resource_type="pdf_secret",
    )
    return PdfPasswordStatus(configured=True)


@router.delete("/settings/pdf-password", response_model=PdfPasswordStatus)
async def delete_pdf_password(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    row = (
        await db.execute(
            select(PdfSecret).where(
                PdfSecret.organization_id == organization_id,
                PdfSecret.user_id == user.user_id,
            )
        )
    ).scalar_one_or_none()
    if row is not None:
        await db.delete(row)
        await db.commit()
        await record_audit(
            db,
            organization_id=organization_id,
            actor_user_id=user.user_id,
            action="pdf_password.deleted",
            resource_type="pdf_secret",
        )
    return PdfPasswordStatus(configured=False)


@router.get("/settings/gmail-filters", response_model=GmailFiltersOut)
async def get_gmail_filters(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    conn = (
        await db.execute(
            select(GmailConnection).where(
                GmailConnection.organization_id == organization_id,
                GmailConnection.user_id == user.user_id,
            )
        )
    ).scalar_one_or_none()
    if conn is None:
        return GmailFiltersOut(connected=False)
    return GmailFiltersOut(
        sender_filter=conn.sender_filter,
        subject_pattern=conn.subject_pattern,
        connected=conn.refresh_token_ciphertext is not None,
        email_address=conn.email_address,
    )


@router.put("/settings/gmail-filters", response_model=GmailFiltersOut)
async def update_gmail_filters(
    body: GmailFiltersUpdate,
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    cipher: TokenCipher = Depends(get_token_cipher),
):
    await require_org_membership(organization_id, user, db)
    conn = (
        await db.execute(
            select(GmailConnection).where(
                GmailConnection.organization_id == organization_id,
                GmailConnection.user_id == user.user_id,
            )
        )
    ).scalar_one_or_none()
    if conn is None:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "not_connected",
                "message": "Conecta Gmail primero en la sección Gmail, luego configura el remitente.",
            },
        )
    if body.sender_filter is not None:
        conn.sender_filter = body.sender_filter.strip() or None
    if body.subject_pattern is not None:
        conn.subject_pattern = body.subject_pattern.strip() or None
    await db.commit()
    await record_audit(
        db,
        organization_id=organization_id,
        actor_user_id=user.user_id,
        action="gmail.filters_updated",
        resource_type="gmail_connection",
        resource_id=str(conn.id),
        metadata={"has_sender_filter": bool(conn.sender_filter)},
    )
    imported = 0
    try:
        service = GmailIntegrationService(db, settings, cipher, HttpGmailClient(settings))
        imported = await service.sync_connection(conn.id, full=True)
    except Exception:
        imported = 0
    return GmailFiltersOut(
        sender_filter=conn.sender_filter,
        subject_pattern=conn.subject_pattern,
        connected=True,
        email_address=conn.email_address,
        documents_imported=imported,
    )
