from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import text

from app.db.session import async_session_factory

router = APIRouter(tags=["health"])


@router.get("/health")
async def health():
    return {"status": "ok"}


@router.get("/ready")
async def ready():
    if async_session_factory is None:
        return {"status": "not_ready", "database": False}
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
        return {"status": "ready", "database": True}
    except Exception:
        return {"status": "not_ready", "database": False}
