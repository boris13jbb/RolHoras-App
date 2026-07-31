from __future__ import annotations

import hashlib
import hmac
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import PaymentEvent, Plan, Subscription, SubscriptionStatus


@dataclass
class CheckoutResult:
    provider: str
    checkout_url: Optional[str]
    subscription_id: Optional[str]


class PaymentProvider(ABC):
    name: str

    @abstractmethod
    async def create_checkout(
        self, *, organization_id: UUID, plan_code: str, success_url: str, cancel_url: str
    ) -> CheckoutResult: ...

    @abstractmethod
    def verify_webhook(self, payload: bytes, signature: str | None, secret: str) -> dict[str, Any]: ...


class NoopPaymentProvider(PaymentProvider):
    name = "noop"

    async def create_checkout(
        self, *, organization_id: UUID, plan_code: str, success_url: str, cancel_url: str
    ) -> CheckoutResult:
        return CheckoutResult(provider=self.name, checkout_url=None, subscription_id=f"noop_{organization_id}")

    def verify_webhook(self, payload: bytes, signature: str | None, secret: str) -> dict[str, Any]:
        if secret and signature:
            expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
            if not hmac.compare_digest(expected, signature):
                raise ValueError("Firma de webhook inválida")
        import json

        return json.loads(payload.decode() or "{}")


class KushkiPaymentProvider(PaymentProvider):
    """Adaptador preparado para Kushki (Ecuador). Requiere credenciales reales."""

    name = "kushki"

    def __init__(self, public_merchant_id: str, private_merchant_id: str) -> None:
        self.public_merchant_id = public_merchant_id
        self.private_merchant_id = private_merchant_id

    async def create_checkout(
        self, *, organization_id: UUID, plan_code: str, success_url: str, cancel_url: str
    ) -> CheckoutResult:
        if not self.private_merchant_id:
            raise RuntimeError("Kushki no configurado")
        # La integración HTTP real se activa con credenciales; no se simula cobro.
        raise RuntimeError(
            "Kushki requiere configuración de comercio y endpoints oficiales. "
            "Usa PAYMENT_PROVIDER=noop en desarrollo."
        )

    def verify_webhook(self, payload: bytes, signature: str | None, secret: str) -> dict[str, Any]:
        if not secret or not signature:
            raise ValueError("Webhook Kushki sin firma")
        expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, signature):
            raise ValueError("Firma Kushki inválida")
        import json

        return json.loads(payload.decode())


def get_payment_provider(name: str, **kwargs: str) -> PaymentProvider:
    if name == "kushki":
        return KushkiPaymentProvider(
            kwargs.get("kushki_public_merchant_id", ""),
            kwargs.get("kushki_private_merchant_id", ""),
        )
    return NoopPaymentProvider()


async def apply_subscription_event(
    db: AsyncSession,
    *,
    provider: str,
    event_id: str,
    event_type: str,
    organization_id: UUID | None,
    plan_code: str | None = None,
    payload_digest: str | None = None,
) -> bool:
    """Idempotente: eventos repetidos no duplican efectos."""
    existing = await db.execute(
        select(PaymentEvent).where(PaymentEvent.provider == provider, PaymentEvent.event_id == event_id)
    )
    if existing.scalar_one_or_none():
        return False

    db.add(
        PaymentEvent(
            organization_id=organization_id,
            provider=provider,
            event_id=event_id,
            event_type=event_type,
            payload_digest=payload_digest,
        )
    )

    if organization_id and plan_code and event_type in {"subscription.activated", "invoice.paid"}:
        plan = (await db.execute(select(Plan).where(Plan.code == plan_code))).scalar_one_or_none()
        if plan:
            sub = (
                await db.execute(select(Subscription).where(Subscription.organization_id == organization_id))
            ).scalar_one_or_none()
            now = datetime.now(timezone.utc)
            if sub is None:
                sub = Subscription(organization_id=organization_id, plan_id=plan.id, provider=provider)
                db.add(sub)
            sub.plan_id = plan.id
            sub.status = SubscriptionStatus.active
            sub.current_period_start = now
            sub.current_period_end = now + timedelta(days=30)
            sub.grace_ends_at = None

    if organization_id and event_type in {"invoice.payment_failed", "subscription.past_due"}:
        sub = (
            await db.execute(select(Subscription).where(Subscription.organization_id == organization_id))
        ).scalar_one_or_none()
        if sub:
            sub.status = SubscriptionStatus.past_due
            sub.grace_ends_at = datetime.now(timezone.utc) + timedelta(days=7)

    if organization_id and event_type in {"subscription.canceled"}:
        sub = (
            await db.execute(select(Subscription).where(Subscription.organization_id == organization_id))
        ).scalar_one_or_none()
        if sub:
            sub.status = SubscriptionStatus.canceled
            sub.cancel_at = datetime.now(timezone.utc)

    await db.commit()
    return True
