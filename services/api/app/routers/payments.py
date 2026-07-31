from __future__ import annotations

import hashlib
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import MembershipRole, Plan, Subscription
from app.security.auth import AuthUser, get_current_user, require_org_membership
from app.services.payments import apply_subscription_event, get_payment_provider

router = APIRouter(tags=["payments"])


@router.get("/billing/plans")
async def list_plans(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Plan).where(Plan.is_active.is_(True)))
    return [
        {
            "code": p.code,
            "name": p.name,
            "max_employees": p.max_employees,
            "max_documents_per_month": p.max_documents_per_month,
            "features": p.features,
        }
        for p in result.scalars().all()
    ]


@router.get("/billing/subscription")
async def get_subscription(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    sub = (
        await db.execute(select(Subscription).where(Subscription.organization_id == organization_id))
    ).scalar_one_or_none()
    if sub is None:
        return {"status": "none"}
    plan = (await db.execute(select(Plan).where(Plan.id == sub.plan_id))).scalar_one()
    return {
        "status": sub.status.value,
        "plan_code": plan.code,
        "provider": sub.provider,
        "trial_ends_at": sub.trial_ends_at,
        "current_period_end": sub.current_period_end,
        "grace_ends_at": sub.grace_ends_at,
    }


@router.post("/billing/checkout")
async def create_checkout(
    organization_id: uuid.UUID = Query(...),
    plan_code: str = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
):
    await require_org_membership(
        organization_id,
        user,
        db,
        roles={MembershipRole.owner, MembershipRole.admin},
    )
    provider = get_payment_provider(
        settings.payment_provider,
        kushki_public_merchant_id="",
        kushki_private_merchant_id="",
    )
    result = await provider.create_checkout(
        organization_id=organization_id,
        plan_code=plan_code,
        success_url=f"{settings.admin_web_url}/billing/success",
        cancel_url=f"{settings.admin_web_url}/billing/cancel",
    )
    return {
        "provider": result.provider,
        "checkout_url": result.checkout_url,
        "subscription_id": result.subscription_id,
    }


@router.post("/webhooks/payments/{provider_name}")
async def payment_webhook(
    provider_name: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
    x_signature: str | None = Header(default=None),
):
    body = await request.body()
    provider = get_payment_provider(provider_name)
    try:
        event = provider.verify_webhook(body, x_signature, settings.kushki_webhook_secret)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail={"code": "invalid_signature", "message": str(exc)}) from exc

    event_id = str(event.get("id") or event.get("event_id") or "")
    event_type = str(event.get("type") or event.get("event_type") or "")
    if not event_id or not event_type:
        raise HTTPException(status_code=400, detail={"code": "invalid_event", "message": "Evento incompleto"})

    org_raw = event.get("organization_id")
    organization_id = uuid.UUID(str(org_raw)) if org_raw else None
    digest = hashlib.sha256(body).hexdigest()
    applied = await apply_subscription_event(
        db,
        provider=provider_name,
        event_id=event_id,
        event_type=event_type,
        organization_id=organization_id,
        plan_code=event.get("plan_code"),
        payload_digest=digest,
    )
    return {"accepted": True, "applied": applied}
