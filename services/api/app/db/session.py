from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

_engine: AsyncEngine | None = None
async_session_factory: async_sessionmaker[AsyncSession] | None = None


class Base(DeclarativeBase):
    pass


def init_engine(database_url: str) -> None:
    global _engine, async_session_factory
    _engine = create_async_engine(database_url, pool_pre_ping=True, echo=False)
    async_session_factory = async_sessionmaker(_engine, expire_on_commit=False)


async def dispose_engine() -> None:
    global _engine, async_session_factory
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    async_session_factory = None


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    if async_session_factory is None:
        raise RuntimeError("Database engine no inicializado")
    async with async_session_factory() as session:
        yield session
