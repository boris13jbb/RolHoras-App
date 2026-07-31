"""API FastAPI — SaaS Rol de Pagos."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.db.session import dispose_engine, init_engine
from app.logging_setup import configure_logging, get_logger
from app.middleware.correlation import CorrelationIdMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.routers import (
    audit,
    auth_bootstrap,
    documents,
    gmail,
    health,
    hours,
    internal,
    organizations,
    payments,
    settings as settings_router,
    webhooks,
)

configure_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    init_engine(settings.database_url)
    logger.info("api_started", env=settings.app_env)
    yield
    await dispose_engine()
    logger.info("api_stopped")


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Rol Pagos SaaS API",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.app_env != "production" else None,
        redoc_url=None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(CorrelationIdMiddleware)
    app.add_middleware(RateLimitMiddleware)

    app.include_router(health.router)
    app.include_router(auth_bootstrap.router, prefix="/api/v1")
    app.include_router(organizations.router, prefix="/api/v1")
    app.include_router(gmail.router, prefix="/api/v1")
    app.include_router(webhooks.router, prefix="/api/v1")
    app.include_router(documents.router, prefix="/api/v1")
    app.include_router(hours.router, prefix="/api/v1")
    app.include_router(audit.router, prefix="/api/v1")
    app.include_router(payments.router, prefix="/api/v1")
    app.include_router(settings_router.router, prefix="/api/v1")
    app.include_router(internal.router, prefix="/api/v1")

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.exception(
            "unhandled_error",
            path=str(request.url.path),
            error_type=type(exc).__name__,
        )
        return JSONResponse(
            status_code=500,
            content={
                "error": {
                    "code": "internal_error",
                    "message": "Ocurrió un error interno. Inténtalo de nuevo.",
                }
            },
        )

    return app


app = create_app()
