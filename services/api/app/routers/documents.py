from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import DocumentStatus, JobStatus, MembershipRole, PayrollDocument, ProcessingJob
from app.schemas import DocumentOut
from app.security.auth import AuthUser, get_current_user, require_org_membership
from app.services.gmail_client import sha256_hex, validate_pdf_bytes
from app.services.storage import StorageService

router = APIRouter(tags=["documents"])


@router.get("/documents", response_model=list[DocumentOut])
async def list_documents(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    membership = await require_org_membership(organization_id, user, db)
    query = select(PayrollDocument).where(PayrollDocument.organization_id == organization_id)
    if membership.role == MembershipRole.employee:
        query = query.where(PayrollDocument.owner_user_id == user.user_id)
    result = await db.execute(query.order_by(PayrollDocument.created_at.desc()))
    return list(result.scalars().all())


@router.get("/documents/{document_id}", response_model=DocumentOut)
async def get_document(
    document_id: uuid.UUID,
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    membership = await require_org_membership(organization_id, user, db)
    doc = (
        await db.execute(
            select(PayrollDocument).where(
                PayrollDocument.id == document_id,
                PayrollDocument.organization_id == organization_id,
            )
        )
    ).scalar_one_or_none()
    if doc is None:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "Documento no encontrado"})
    if membership.role == MembershipRole.employee and doc.owner_user_id != user.user_id:
        raise HTTPException(status_code=403, detail={"code": "forbidden", "message": "Sin acceso"})
    return doc


@router.post("/documents/upload", response_model=DocumentOut)
async def upload_document(
    organization_id: uuid.UUID = Query(...),
    file: UploadFile = File(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
):
    """Carga manual de respaldo (no reemplaza Gmail automático)."""
    await require_org_membership(organization_id, user, db)
    raw = await file.read()
    try:
        validate_pdf_bytes(raw, settings.pdf_max_bytes)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail={"code": "invalid_pdf", "message": str(exc)}) from exc

    digest = sha256_hex(raw)
    existing = (
        await db.execute(
            select(PayrollDocument).where(
                PayrollDocument.organization_id == organization_id,
                PayrollDocument.content_sha256 == digest,
            )
        )
    ).scalar_one_or_none()
    if existing:
        return existing

    storage = StorageService(settings)
    path = await storage.save_bytes(
        organization_id=organization_id,
        user_id=user.user_id,
        filename=file.filename or "rol.pdf",
        data=raw,
    )
    doc = PayrollDocument(
        organization_id=organization_id,
        owner_user_id=user.user_id,
        source="manual",
        original_filename=file.filename,
        content_sha256=digest,
        storage_path=path,
        mime_type="application/pdf",
        size_bytes=len(raw),
        status=DocumentStatus.queued,
    )
    db.add(doc)
    await db.flush()
    db.add(
        ProcessingJob(
            organization_id=organization_id,
            document_id=doc.id,
            job_type="extract_payroll_pdf",
            status=JobStatus.pending,
            payload={"document_id": str(doc.id)},
        )
    )
    await db.commit()
    await db.refresh(doc)
    return doc
