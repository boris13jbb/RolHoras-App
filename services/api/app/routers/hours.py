from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models import CalculationRuleSet, HourEntry, PeriodBalance
from app.schemas import HourEntryCreate, HourEntryOut, PeriodBalanceOut
from app.security.auth import AuthUser, get_current_user, require_org_membership
from app.services.calculations import apply_totals_to_balance, compute_period_totals, equivalent_minutes

router = APIRouter(tags=["hours"])


@router.post("/hours/entries", response_model=HourEntryOut)
async def create_hour_entry(
    body: HourEntryCreate,
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    percent = Decimal(body.surcharge_percent)
    # Regla vigente (si existe)
    rule = (
        await db.execute(
            select(CalculationRuleSet)
            .where(CalculationRuleSet.organization_id == organization_id)
            .order_by(CalculationRuleSet.version.desc())
        )
    ).scalars().first()
    formula = rule.formula if rule else None
    eq = equivalent_minutes(body.minutes, percent, formula)
    entry = HourEntry(
        organization_id=organization_id,
        user_id=user.user_id,
        entry_date=date.fromisoformat(body.entry_date),
        period_year=body.period_year,
        period_month=body.period_month,
        minutes=body.minutes,
        surcharge_percent=percent,
        equivalent_minutes=eq,
        entry_type=body.entry_type,
        notes=body.notes,
        rule_set_id=rule.id if rule else None,
    )
    db.add(entry)

    balance = (
        await db.execute(
            select(PeriodBalance).where(
                PeriodBalance.organization_id == organization_id,
                PeriodBalance.user_id == user.user_id,
                PeriodBalance.period_year == body.period_year,
                PeriodBalance.period_month == body.period_month,
            )
        )
    ).scalar_one_or_none()
    if balance is None:
        balance = PeriodBalance(
            organization_id=organization_id,
            user_id=user.user_id,
            period_year=body.period_year,
            period_month=body.period_month,
            rule_set_id=rule.id if rule else None,
        )
        db.add(balance)
    if balance.is_closed:
        raise HTTPException(status_code=409, detail={"code": "period_closed", "message": "Periodo cerrado"})

    await db.flush()
    entries = (
        await db.execute(
            select(HourEntry).where(
                HourEntry.organization_id == organization_id,
                HourEntry.user_id == user.user_id,
                HourEntry.period_year == body.period_year,
                HourEntry.period_month == body.period_month,
            )
        )
    ).scalars().all()
    apply_totals_to_balance(balance, compute_period_totals(entries))
    await db.commit()
    await db.refresh(entry)
    return HourEntryOut(
        id=entry.id,
        minutes=entry.minutes,
        surcharge_percent=str(entry.surcharge_percent),
        equivalent_minutes=entry.equivalent_minutes,
        entry_type=entry.entry_type,
        period_year=entry.period_year,
        period_month=entry.period_month,
    )


@router.get("/hours/balances", response_model=list[PeriodBalanceOut])
async def list_balances(
    organization_id: uuid.UUID = Query(...),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await require_org_membership(organization_id, user, db)
    result = await db.execute(
        select(PeriodBalance)
        .where(PeriodBalance.organization_id == organization_id, PeriodBalance.user_id == user.user_id)
        .order_by(PeriodBalance.period_year.desc(), PeriodBalance.period_month.desc())
    )
    return list(result.scalars().all())


@router.post("/hours/rules")
async def create_rule_set(
    organization_id: uuid.UUID = Query(...),
    name: str = Query("default"),
    effective_from: str = Query(...),
    change_reason: str = Query(...),
    percent_divisor: int = Query(100),
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models import MembershipRole

    await require_org_membership(
        organization_id,
        user,
        db,
        roles={MembershipRole.owner, MembershipRole.admin, MembershipRole.payroll_manager},
    )
    latest = (
        await db.execute(
            select(CalculationRuleSet)
            .where(CalculationRuleSet.organization_id == organization_id, CalculationRuleSet.name == name)
            .order_by(CalculationRuleSet.version.desc())
        )
    ).scalars().first()
    version = (latest.version + 1) if latest else 1
    if latest and latest.effective_to is None:
        # Cierra vigencia anterior sin borrar historial
        latest.effective_to = date.fromisoformat(effective_from)
    rule = CalculationRuleSet(
        organization_id=organization_id,
        name=name,
        version=version,
        effective_from=date.fromisoformat(effective_from),
        unit="minutes",
        formula={"type": "percent_factor", "percent_is_factor_divisor": percent_divisor},
        created_by=user.user_id,
        change_reason=change_reason,
    )
    db.add(rule)
    await db.commit()
    return {"id": str(rule.id), "version": version}
