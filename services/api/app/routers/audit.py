from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models import AuditEvent, MembershipRole
from app.security.auth import AuthUser, get_current_user, require_org_membership

router = APIRouter(tags=["audit"])


@router.get("/audit/events")
async def list_audit_events(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    limit: int = Query(50, ge=1, le=200),
):
    await require_org_membership(
        organization_id,
        user,
        db,
        roles={MembershipRole.owner, MembershipRole.admin, MembershipRole.auditor},
    )
    result = await db.execute(
        select(AuditEvent)
        .where(AuditEvent.organization_id == organization_id)
        .order_by(AuditEvent.created_at.desc())
        .limit(limit)
    )
    events = result.scalars().all()
    return [
        {
            "id": str(e.id),
            "action": e.action,
            "resource_type": e.resource_type,
            "resource_id": e.resource_id,
            "actor_user_id": str(e.actor_user_id) if e.actor_user_id else None,
            "metadata": e.metadata_,
            "created_at": e.created_at.isoformat() if e.created_at else None,
        }
        for e in events
    ]
