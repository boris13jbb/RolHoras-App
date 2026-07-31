from __future__ import annotations

import re
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import (
    Membership,
    MembershipRole,
    MembershipStatus,
    Organization,
    Plan,
    Profile,
    Subscription,
    SubscriptionStatus,
)
from app.schemas import (
    DevBootstrapRequest,
    DevBootstrapResponse,
    MembershipInvite,
    OrganizationCreate,
    OrganizationOut,
)
from app.security.auth import AuthUser, get_current_user, issue_dev_jwt, require_org_membership
from app.services.audit import record_audit

router = APIRouter(tags=["organizations"])


def _slugify(name: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") or "org"
    return f"{base}-{uuid.uuid4().hex[:8]}"


@router.post("/organizations", response_model=OrganizationOut)
async def create_organization(
    body: OrganizationCreate,
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    org = Organization(name=body.name, slug=_slugify(body.name), timezone=body.timezone, is_personal=body.is_personal)
    db.add(org)
    await db.flush()
    db.add(
        Membership(
            organization_id=org.id,
            user_id=user.user_id,
            role=MembershipRole.owner,
            status=MembershipStatus.active,
        )
    )
    plan = (await db.execute(select(Plan).where(Plan.code == ("personal" if body.is_personal else "empresa")))).scalar_one_or_none()
    if plan:
        db.add(
            Subscription(
                organization_id=org.id,
                plan_id=plan.id,
                status=SubscriptionStatus.trialing,
                trial_ends_at=datetime.now(timezone.utc) + timedelta(days=14),
                provider="noop",
            )
        )
    await db.commit()
    await record_audit(
        db,
        organization_id=org.id,
        actor_user_id=user.user_id,
        action="organization.created",
        resource_type="organization",
        resource_id=str(org.id),
    )
    return OrganizationOut(
        id=org.id,
        name=org.name,
        slug=org.slug,
        timezone=org.timezone,
        is_personal=org.is_personal,
        role=MembershipRole.owner.value,
    )


@router.get("/organizations", response_model=list[OrganizationOut])
async def list_organizations(
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Organization, Membership)
        .join(Membership, Membership.organization_id == Organization.id)
        .where(Membership.user_id == user.user_id, Membership.status == MembershipStatus.active)
    )
    items = []
    for org, membership in result.all():
        items.append(
            OrganizationOut(
                id=org.id,
                name=org.name,
                slug=org.slug,
                timezone=org.timezone,
                is_personal=org.is_personal,
                role=membership.role.value,
            )
        )
    return items


@router.post("/organizations/{organization_id}/invitations")
async def invite_member(
    organization_id: uuid.UUID,
    body: MembershipInvite,
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(
        organization_id,
        user,
        db,
        roles={MembershipRole.owner, MembershipRole.admin},
    )
    try:
        role = MembershipRole(body.role)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail={"code": "invalid_role", "message": "Rol inválido"}) from exc

    # Invitación simplificada: si el perfil existe, crea membership invited/active
    profile = (await db.execute(select(Profile).where(Profile.email == body.email.lower()))).scalar_one_or_none()
    if profile is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "user_not_found", "message": "El usuario debe registrarse antes de ser invitado"},
        )
    existing = (
        await db.execute(
            select(Membership).where(
                Membership.organization_id == organization_id, Membership.user_id == profile.id
            )
        )
    ).scalar_one_or_none()
    if existing:
        return {"status": "already_member", "membership_id": str(existing.id)}

    membership = Membership(
        organization_id=organization_id,
        user_id=profile.id,
        role=role,
        status=MembershipStatus.active,
        invited_email=body.email.lower(),
        invited_by=user.user_id,
    )
    db.add(membership)
    await db.commit()
    await record_audit(
        db,
        organization_id=organization_id,
        actor_user_id=user.user_id,
        action="membership.invited",
        resource_type="membership",
        resource_id=str(membership.id),
        metadata={"email": body.email.lower(), "role": role.value},
    )
    return {"status": "invited", "membership_id": str(membership.id)}


# Router separado de bootstrap de desarrollo
bootstrap_router = APIRouter(tags=["dev"])


@bootstrap_router.post("/dev/bootstrap", response_model=DevBootstrapResponse)
async def dev_bootstrap(
    body: DevBootstrapRequest,
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
):
    if settings.app_env == "production" and not settings.enable_dev_bootstrap:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "No disponible"})

    email = body.email.lower().strip()
    existing = (
        await db.execute(select(Profile).where(Profile.email == email))
    ).scalar_one_or_none()

    if existing is not None:
        # Idempotente: reutiliza perfil/org y emite JWT nuevo (útil tras reiniciar API / rotar secreto).
        membership = (
            await db.execute(
                select(Membership)
                .where(
                    Membership.user_id == existing.id,
                    Membership.status == MembershipStatus.active,
                )
                .order_by(Membership.created_at.asc())
                .limit(1)
            )
        ).scalar_one_or_none()
        if membership is None:
            raise HTTPException(
                status_code=409,
                detail={
                    "code": "bootstrap_incomplete",
                    "message": "El usuario existe pero no tiene organización activa.",
                },
            )
        token = issue_dev_jwt(settings, existing.id, email)
        return DevBootstrapResponse(
            access_token=token,
            user_id=existing.id,
            organization_id=membership.organization_id,
            email=email,
        )

    user_id = uuid.uuid4()
    profile = Profile(id=user_id, email=email, full_name=body.full_name)
    db.add(profile)
    org = Organization(name=body.organization_name, slug=_slugify(body.organization_name), is_personal=True)
    db.add(org)
    await db.flush()
    db.add(
        Membership(
            organization_id=org.id,
            user_id=user_id,
            role=MembershipRole.owner,
            status=MembershipStatus.active,
        )
    )
    plan = (await db.execute(select(Plan).where(Plan.code == "personal"))).scalar_one_or_none()
    if plan:
        db.add(
            Subscription(
                organization_id=org.id,
                plan_id=plan.id,
                status=SubscriptionStatus.trialing,
                trial_ends_at=datetime.now(timezone.utc) + timedelta(days=14),
            )
        )
    await db.commit()
    token = issue_dev_jwt(settings, user_id, email)
    return DevBootstrapResponse(
        access_token=token,
        user_id=user_id,
        organization_id=org.id,
        email=email,
    )
