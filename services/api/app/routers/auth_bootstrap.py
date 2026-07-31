"""Reexporta bootstrap de desarrollo."""

from app.routers.organizations import bootstrap_router as router

__all__ = ["router"]
