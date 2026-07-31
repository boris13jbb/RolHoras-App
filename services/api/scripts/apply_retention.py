"""
Política de retención: elimina documentos y archivos locales más antiguos
que organizations.retention_days. Ejecutar vía Cloud Scheduler.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import get_settings


async def apply_retention() -> int:
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    deleted = 0
    async with engine.begin() as conn:
        rows = (
            await conn.execute(
                text(
                    """
                    SELECT d.id, d.storage_path, o.retention_days
                    FROM payroll_documents d
                    JOIN organizations o ON o.id = d.organization_id
                    WHERE d.created_at < now() - make_interval(days => o.retention_days)
                    """
                )
            )
        ).mappings().all()
        for row in rows:
            path = Path(settings.local_storage_path) / row["storage_path"]
            if path.exists():
                path.unlink()
            await conn.execute(text("DELETE FROM payroll_documents WHERE id = :id"), {"id": row["id"]})
            deleted += 1
    await engine.dispose()
    return deleted


if __name__ == "__main__":
    n = asyncio.run(apply_retention())
    print(f"deleted={n}")
