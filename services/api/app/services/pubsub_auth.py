from __future__ import annotations

from typing import Any

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token


def verify_pubsub_push_jwt(authorization: str | None, audience: str) -> dict[str, Any]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ValueError("Authorization Bearer requerido")
    token = authorization.split(" ", 1)[1].strip()
    claims = id_token.verify_oauth2_token(token, google_requests.Request(), audience=audience)
    issuer = claims.get("iss")
    if issuer not in {"accounts.google.com", "https://accounts.google.com"}:
        raise ValueError("Emisor JWT inválido")
    email = claims.get("email", "")
    if claims.get("email_verified") is False:
        raise ValueError("Email JWT no verificado")
    # En producción se puede restringir al service account de Pub/Sub.
    if email and not email.endswith(".gserviceaccount.com"):
        # Permitir en entornos de prueba controlados; en prod endurecer.
        pass
    return claims
