from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from typing import Iterable

from app.models import HourEntry, PeriodBalance


def hours_to_minutes(hours: Decimal) -> int:
    return int((hours * Decimal(60)).quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def minutes_to_hours(minutes: int) -> Decimal:
    return (Decimal(minutes) / Decimal(60)).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)


def equivalent_minutes(minutes: int, surcharge_percent: Decimal, formula: dict | None = None) -> int:
    """Calcula minutos equivalentes según fórmula de la empresa.

    formula ejemplo:
      {"type": "percent_factor", "percent_is_factor_divisor": 100}
    No se asume que 50% = 0.5 si la empresa define otra semántica.
    """
    formula = formula or {"type": "percent_factor", "percent_is_factor_divisor": 100}
    if formula.get("type") == "percent_factor":
        divisor = Decimal(str(formula.get("percent_is_factor_divisor", 100)))
        factor = surcharge_percent / divisor
        value = Decimal(minutes) * factor
        return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    if formula.get("type") == "fixed_multiplier":
        factor = Decimal(str(formula.get("multiplier", 1)))
        value = Decimal(minutes) * factor
        return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    raise ValueError("Fórmula de cálculo no soportada")


def compute_period_totals(entries: Iterable[HourEntry]) -> dict[str, int]:
    debt = 0
    paid = 0
    for entry in entries:
        if entry.entry_type in {"worked", "debt"}:
            debt += entry.equivalent_minutes
        elif entry.entry_type in {"paid", "compensation"}:
            paid += entry.equivalent_minutes
        elif entry.entry_type == "adjustment":
            # ajuste positivo aumenta deuda; negativo reduce
            debt += entry.equivalent_minutes
    pending = max(debt - paid, 0)
    credit = max(paid - debt, 0)
    return {
        "debt_minutes": debt,
        "paid_minutes": paid,
        "pending_minutes": pending,
        "credit_minutes": credit,
    }


def apply_totals_to_balance(balance: PeriodBalance, totals: dict[str, int]) -> None:
    if balance.is_closed:
        raise ValueError("No se puede recalcular un periodo cerrado")
    balance.debt_minutes = totals["debt_minutes"]
    balance.paid_minutes = totals["paid_minutes"]
    balance.pending_minutes = totals["pending_minutes"]
    balance.credit_minutes = totals["credit_minutes"]
