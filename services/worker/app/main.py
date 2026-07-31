from __future__ import annotations

import asyncio
import os
import re
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Optional
from uuid import UUID

import structlog
from pydantic_settings import BaseSettings, SettingsConfigDict
from pypdf import PdfReader
from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, select, update
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from cryptography.fernet import Fernet
import base64
import hashlib
from io import BytesIO
from pathlib import Path

structlog.configure(processors=[structlog.processors.TimeStamper(fmt="iso"), structlog.processors.JSONRenderer()])
logger = structlog.get_logger(__name__)

PARSER_NAME = "payroll_notas_horas"
PARSER_VERSION = "1.0.0"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    database_url: str = "postgresql+asyncpg://rolpagos:rolpagos_dev@localhost:5433/rolpagos"
    local_storage_path: str = "./storage/private"
    token_encryption_key: str = ""
    worker_poll_interval_seconds: int = 2
    worker_id: str = "worker-1"


class Base(DeclarativeBase):
    pass


class ProcessingJob(Base):
    __tablename__ = "processing_jobs"
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    organization_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    document_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    job_type: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text)
    attempts: Mapped[int] = mapped_column(Integer)
    max_attempts: Mapped[int] = mapped_column(Integer)
    available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    locked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    locked_by: Mapped[Optional[str]] = mapped_column(Text)
    last_error_code: Mapped[Optional[str]] = mapped_column(Text)
    last_error_message: Mapped[Optional[str]] = mapped_column(Text)
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB)


class PayrollDocument(Base):
    __tablename__ = "payroll_documents"
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    organization_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    owner_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    storage_path: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text)
    status_message: Mapped[Optional[str]] = mapped_column(Text)
    period_year: Mapped[Optional[int]] = mapped_column(Integer)
    period_month: Mapped[Optional[int]] = mapped_column(Integer)


class PdfSecret(Base):
    __tablename__ = "pdf_secrets"
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    organization_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    password_ciphertext: Mapped[str] = mapped_column(Text)
    key_version: Mapped[str] = mapped_column(Text)


class ExtractionRun(Base):
    __tablename__ = "extraction_runs"
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    document_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    organization_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    parser_name: Mapped[str] = mapped_column(Text)
    parser_version: Mapped[str] = mapped_column(Text)
    overall_confidence: Mapped[Optional[Any]] = mapped_column(Numeric(5, 4))
    warnings: Mapped[list] = mapped_column(JSONB)
    requires_review: Mapped[bool] = mapped_column()


class ExtractedField(Base):
    __tablename__ = "extracted_fields"
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    extraction_run_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    organization_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True))
    field_key: Mapped[str] = mapped_column(Text)
    field_value: Mapped[Optional[str]] = mapped_column(Text)
    page_number: Mapped[Optional[int]] = mapped_column(Integer)
    label_text: Mapped[Optional[str]] = mapped_column(Text)
    evidence_snippet: Mapped[Optional[str]] = mapped_column(Text)
    confidence: Mapped[Optional[Any]] = mapped_column(Numeric(5, 4))
    is_manual_override: Mapped[bool] = mapped_column()


def cipher_from_settings(settings: Settings) -> Fernet:
    key = settings.token_encryption_key
    if not key:
        material = base64.urlsafe_b64encode(hashlib.sha256(b"dev-only-not-for-prod").digest())
    else:
        try:
            Fernet(key.encode())
            material = key.encode()
        except Exception:
            material = base64.urlsafe_b64encode(hashlib.sha256(key.encode()).digest())
    return Fernet(material)


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower().replace("\u00a0", " ")).strip()


def parse_payroll_text(text: str) -> dict[str, Any]:
    """Parser versionado alineado con la heurística Flutter (NOTAS HORAS)."""
    normalized = normalize(text)
    fields: dict[str, dict[str, Any]] = {}
    warnings: list[str] = []

    period = None
    m = re.search(r"(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)\s+(\d{4})", normalized)
    months = {
        "enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6,
        "julio": 7, "agosto": 8, "septiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12,
    }
    if m:
        period = (int(m.group(2)), months[m.group(1)])

    def grab(patterns: list[str], key: str, label: str) -> None:
        for pat in patterns:
            mm = re.search(pat, normalized)
            if mm:
                raw = mm.group(1).replace(",", ".")
                fields[key] = {
                    "value": raw,
                    "label": label,
                    "evidence": mm.group(0)[:120],
                    "confidence": Decimal("0.85"),
                    "page": 1,
                }
                return
        warnings.append(f"campo_no_encontrado:{key}")

    grab(
        [
            r"(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+saldo\s+anterior\b",
            r"\bhoras\s+saldo\s+anterior\b\s+(-?\d{1,6}(?:[.,]\d{1,4})?)",
        ],
        "debt_hours",
        "horas saldo anterior",
    )
    grab(
        [
            r"(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+compens\w+",
            r"\bhoras\s+compens\w+\s+(-?\d{1,6}(?:[.,]\d{1,4})?)",
            r"(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+pagadas\b",
        ],
        "paid_hours",
        "horas compensadas/pagadas",
    )
    grab(
        [
            r"(-?\d{1,6}(?:[.,]\d{1,4})?)\s+saldo\s+actual\b",
            r"\bsaldo\s+actual\b\s+(-?\d{1,6}(?:[.,]\d{1,4})?)",
            r"(-?\d{1,6}(?:[.,]\d{1,4})?)\s+horas\s+pendientes\b",
        ],
        "pending_hours",
        "saldo actual/pendiente",
    )

    confidences = [f["confidence"] for f in fields.values()]
    overall = (sum(confidences) / len(confidences)) if confidences else Decimal("0")
    requires_review = overall < Decimal("0.80") or len(fields) < 2
    return {
        "fields": fields,
        "warnings": warnings,
        "overall_confidence": overall,
        "requires_review": requires_review,
        "period": period,
    }


def extract_text_from_pdf(data: bytes, password: str | None) -> tuple[str, bool]:
    reader = PdfReader(BytesIO(data))
    if reader.is_encrypted:
        if not password:
            raise PermissionError("needs_password")
        ok = reader.decrypt(password)
        if ok == 0:
            raise PermissionError("bad_password")
    chunks: list[str] = []
    for page in reader.pages:
        chunks.append(page.extract_text() or "")
    text = "\n".join(chunks).strip()
    return text, bool(text)


async def claim_job(session: AsyncSession, worker_id: str) -> Optional[ProcessingJob]:
    result = await session.execute(
        select(ProcessingJob)
        .where(
            ProcessingJob.status.in_(["pending", "failed"]),
            ProcessingJob.available_at <= datetime.now(timezone.utc),
            ProcessingJob.attempts < ProcessingJob.max_attempts,
        )
        .order_by(ProcessingJob.available_at.asc())
        .limit(1)
        .with_for_update(skip_locked=True)
    )
    job = result.scalar_one_or_none()
    if job is None:
        return None
    job.status = "running"
    job.locked_at = datetime.now(timezone.utc)
    job.locked_by = worker_id
    job.attempts += 1
    await session.commit()
    return job


async def process_extract_job(session: AsyncSession, settings: Settings, job: ProcessingJob) -> None:
    from uuid import uuid4

    if not job.document_id:
        raise ValueError("document_id requerido")
    doc = (
        await session.execute(select(PayrollDocument).where(PayrollDocument.id == job.document_id))
    ).scalar_one()
    doc.status = "processing"
    await session.commit()

    path = Path(settings.local_storage_path) / doc.storage_path
    data = path.read_bytes()
    if not data.startswith(b"%PDF"):
        raise ValueError("invalid_pdf")

    password = None
    secret = (
        await session.execute(
            select(PdfSecret).where(
                PdfSecret.organization_id == doc.organization_id,
                PdfSecret.user_id == doc.owner_user_id,
            )
        )
    ).scalar_one_or_none()
    if secret:
        password = cipher_from_settings(settings).decrypt(secret.password_ciphertext.encode()).decode()

    try:
        text, has_text = extract_text_from_pdf(data, password)
    except PermissionError as exc:
        code = str(exc)
        doc.status = "needs_password"
        doc.status_message = "Se requiere contraseña del PDF" if code == "needs_password" else "Contraseña incorrecta"
        job.status = "succeeded"
        await session.commit()
        return

    if not has_text:
        # OCR diferido: marcar revisión (sin inventar datos)
        doc.status = "needs_review"
        doc.status_message = "PDF sin texto utilizable; requiere OCR/revisión"
        run_id = uuid4()
        session.add(
            ExtractionRun(
                id=run_id,
                document_id=doc.id,
                organization_id=doc.organization_id,
                parser_name=PARSER_NAME,
                parser_version=PARSER_VERSION,
                overall_confidence=Decimal("0"),
                warnings=["no_text_layer"],
                requires_review=True,
            )
        )
        job.status = "succeeded"
        await session.commit()
        return

    parsed = parse_payroll_text(text)
    run_id = uuid4()
    session.add(
        ExtractionRun(
            id=run_id,
            document_id=doc.id,
            organization_id=doc.organization_id,
            parser_name=PARSER_NAME,
            parser_version=PARSER_VERSION,
            overall_confidence=parsed["overall_confidence"],
            warnings=parsed["warnings"],
            requires_review=parsed["requires_review"],
        )
    )
    for key, meta in parsed["fields"].items():
        # No sobrescribir overrides manuales previos: se inserta nueva corrida; UI elige la vigente.
        session.add(
            ExtractedField(
                id=uuid4(),
                extraction_run_id=run_id,
                organization_id=doc.organization_id,
                field_key=key,
                field_value=meta["value"],
                page_number=meta.get("page"),
                label_text=meta.get("label"),
                evidence_snippet=meta.get("evidence"),
                confidence=meta.get("confidence"),
                is_manual_override=False,
            )
        )
    if parsed.get("period"):
        doc.period_year, doc.period_month = parsed["period"]
    doc.status = "needs_review" if parsed["requires_review"] else "completed"
    doc.status_message = None
    job.status = "succeeded"
    job.last_error_code = None
    job.last_error_message = None
    await session.commit()
    logger.info("extraction_done", document_id=str(doc.id), status=doc.status)


async def fail_job(session: AsyncSession, job: ProcessingJob, code: str) -> None:
    job.last_error_code = code
    job.last_error_message = "Error de procesamiento"
    if job.attempts >= job.max_attempts:
        job.status = "dead"
    else:
        job.status = "failed"
        job.available_at = datetime.now(timezone.utc) + timedelta(minutes=min(30, 2 ** job.attempts))
    if job.document_id:
        doc = (
            await session.execute(select(PayrollDocument).where(PayrollDocument.id == job.document_id))
        ).scalar_one_or_none()
        if doc and job.status == "dead":
            doc.status = "failed"
            doc.status_message = "Procesamiento fallido"
    await session.commit()


async def run_worker() -> None:
    settings = Settings()
    engine = create_async_engine(settings.database_url, pool_pre_ping=True)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    logger.info("worker_started", worker_id=settings.worker_id)
    while True:
        try:
            async with session_factory() as session:
                job = await claim_job(session, settings.worker_id)
                if job is None:
                    await asyncio.sleep(settings.worker_poll_interval_seconds)
                    continue
                try:
                    if job.job_type == "extract_payroll_pdf":
                        await process_extract_job(session, settings, job)
                    elif job.job_type == "gmail_sync":
                        # El sync pesado lo ejecuta la API; aquí solo se marca para reintento externo.
                        job.status = "succeeded"
                        await session.commit()
                    else:
                        await fail_job(session, job, "unknown_job_type")
                except Exception:
                    logger.exception("job_failed", job_id=str(job.id))
                    await fail_job(session, job, "processing_error")
        except Exception:
            logger.exception("worker_loop_error")
            await asyncio.sleep(5)


def main() -> None:
    asyncio.run(run_worker())


if __name__ == "__main__":
    main()
