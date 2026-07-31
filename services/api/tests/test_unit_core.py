from __future__ import annotations

import base64
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from uuid import uuid4

import pytest
from cryptography.fernet import Fernet

from app.security.auth import TokenCipher, create_signed_oauth_state, generate_pkce_pair, verify_signed_oauth_state
from app.services.calculations import compute_period_totals, equivalent_minutes, hours_to_minutes
from app.services.gmail_client import (
    decode_base64url,
    sender_matches,
    subject_matches,
    validate_pdf_bytes,
    walk_mime_parts,
)
from app.services.payments import NoopPaymentProvider, apply_subscription_event


def test_pkce_and_signed_state_roundtrip():
    secret = "test-secret-key-for-hmac-signing-32"
    verifier, challenge = generate_pkce_pair()
    assert verifier and challenge and verifier != challenge
    state = create_signed_oauth_state(secret, f"{uuid4()}:{uuid4()}:nonce", ttl_seconds=60)
    payload = verify_signed_oauth_state(secret, state)
    assert "nonce" in payload


def test_state_rejects_tampering_and_reuse_signature():
    secret = "test-secret-key-for-hmac-signing-32"
    state = create_signed_oauth_state(secret, "payload", ttl_seconds=60)
    bad = state[:-2] + ("00" if state[-2:] != "00" else "11")
    with pytest.raises(ValueError):
        verify_signed_oauth_state(secret, bad)


def test_token_cipher_roundtrip():
    key = Fernet.generate_key().decode()
    cipher = TokenCipher(key, "v1")
    token = "1//refresh-token-value"
    enc = cipher.encrypt(token)
    assert enc != token
    assert cipher.decrypt(enc) == token


def test_base64url_and_pdf_validation():
    raw = b"%PDF-1.4 fake content"
    encoded = base64.urlsafe_b64encode(raw).decode().rstrip("=")
    assert decode_base64url(encoded) == raw
    validate_pdf_bytes(raw, 1024)
    with pytest.raises(ValueError):
        validate_pdf_bytes(b"NOTPDF", 1024)
    with pytest.raises(ValueError):
        validate_pdf_bytes(raw, 5)


def test_walk_mime_nested_parts():
    payload = {
        "mimeType": "multipart/mixed",
        "parts": [
            {
                "mimeType": "multipart/alternative",
                "parts": [
                    {"mimeType": "text/plain", "body": {"data": "aGVsbG8="}},
                    {
                        "mimeType": "application/pdf",
                        "filename": "rol.pdf",
                        "body": {"attachmentId": "ATT123", "size": 10},
                        "headers": [{"name": "Content-Disposition", "value": 'attachment; filename="rol.pdf"'}],
                    },
                ],
            }
        ],
    }
    parts = walk_mime_parts(payload)
    assert len(parts) == 1
    assert parts[0]["attachment_id"] == "ATT123"


def test_sender_and_subject_filters():
    assert sender_matches("Rol Pagos <nomina@empresa.com>", "nomina@empresa.com")
    assert not sender_matches("Otro <otro@x.com>", "nomina@empresa.com")
    assert subject_matches("Rol de pago Marzo 2026", r"rol.*pago")
    assert not subject_matches("Factura", r"rol.*pago")


def test_calculations_use_decimal_semantics():
    # 60 minutos al 50% con divisor 100 => 30 minutos equivalentes
    assert equivalent_minutes(60, __import__("decimal").Decimal("50")) == 30
    # Si la empresa define divisor 1, 50 significa factor 50 (no asumir 0.5)
    assert equivalent_minutes(
        60,
        __import__("decimal").Decimal("50"),
        {"type": "percent_factor", "percent_is_factor_divisor": 1},
    ) == 3000
    assert hours_to_minutes(__import__("decimal").Decimal("1.5")) == 90


class _Entry:
    def __init__(self, entry_type: str, equivalent_minutes: int):
        self.entry_type = entry_type
        self.equivalent_minutes = equivalent_minutes


def test_period_totals():
    totals = compute_period_totals(
        [_Entry("worked", 100), _Entry("paid", 40), _Entry("compensation", 20)]
    )
    assert totals["debt_minutes"] == 100
    assert totals["paid_minutes"] == 60
    assert totals["pending_minutes"] == 40
    assert totals["credit_minutes"] == 0


def test_noop_webhook_signature():
    provider = NoopPaymentProvider()
    payload = b'{"id":"evt_1","type":"invoice.paid","organization_id":null}'
    secret = "whsec"
    import hmac

    sig = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    event = provider.verify_webhook(payload, sig, secret)
    assert event["id"] == "evt_1"
    with pytest.raises(ValueError):
        provider.verify_webhook(payload, "bad", secret)
