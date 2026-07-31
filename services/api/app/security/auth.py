from __future__ import annotations

import base64
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from cryptography.fernet import Fernet, InvalidToken
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import get_db
from app.models import Membership, MembershipRole, MembershipStatus, Profile

bearer_scheme = HTTPBearer(auto_error=False)


class TokenCipher:
    """Cifrado de secretos (refresh tokens / contraseñas PDF).

    En desarrollo usa Fernet. En producción puede sustituirse por KMS/Secret Manager
    sin cambiar la interfaz de los servicios.
    """

    def __init__(self, key: str, key_version: str) -> None:
        if not key:
            # Clave determinista solo para tests locales sin .env; nunca usar en prod.
            material = base64.urlsafe_b64encode(hashlib.sha256(b"dev-only-not-for-prod").digest())
        else:
            try:
                Fernet(key.encode("utf-8"))
                material = key.encode("utf-8")
            except Exception:
                material = base64.urlsafe_b64encode(hashlib.sha256(key.encode("utf-8")).digest())
        self._fernet = Fernet(material)
        self.key_version = key_version

    def encrypt(self, plaintext: str) -> str:
        return self._fernet.encrypt(plaintext.encode("utf-8")).decode("utf-8")

    def decrypt(self, ciphertext: str) -> str:
        try:
            return self._fernet.decrypt(ciphertext.encode("utf-8")).decode("utf-8")
        except InvalidToken as exc:
            raise ValueError("No se pudo descifrar el secreto") from exc


def get_token_cipher(settings: Settings = Depends(get_settings)) -> TokenCipher:
    return TokenCipher(settings.token_encryption_key, settings.token_encryption_key_version)


class AuthUser:
    def __init__(self, user_id: UUID, email: str, claims: dict[str, Any]) -> None:
        self.user_id = user_id
        self.email = email
        self.claims = claims


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    settings: Settings = Depends(get_settings),
    db: AsyncSession = Depends(get_db),
) -> AuthUser:
    if settings.auth_disabled_for_tests and credentials is None:
        raise HTTPException(status_code=401, detail={"code": "unauthorized", "message": "Token requerido"})

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "unauthorized", "message": "Autenticación requerida"},
        )

    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_token", "message": "Token inválido o expirado"},
        ) from exc

    sub = payload.get("sub")
    email = payload.get("email") or payload.get("user_metadata", {}).get("email")
    if not sub:
        raise HTTPException(status_code=401, detail={"code": "invalid_token", "message": "Token sin sujeto"})

    user_id = UUID(str(sub))
    result = await db.execute(select(Profile).where(Profile.id == user_id))
    profile = result.scalar_one_or_none()
    if profile is None:
        profile = Profile(id=user_id, email=email or f"{user_id}@unknown.local")
        db.add(profile)
        await db.commit()

    return AuthUser(user_id=user_id, email=profile.email, claims=payload)


async def require_org_membership(
    organization_id: UUID,
    user: AuthUser,
    db: AsyncSession,
    roles: set[MembershipRole] | None = None,
) -> Membership:
    result = await db.execute(
        select(Membership).where(
            Membership.organization_id == organization_id,
            Membership.user_id == user.user_id,
            Membership.status == MembershipStatus.active,
        )
    )
    membership = result.scalar_one_or_none()
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "forbidden", "message": "No perteneces a esta organización"},
        )
    if roles is not None and membership.role not in roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "forbidden", "message": "Permisos insuficientes"},
        )
    return membership


def create_signed_oauth_state(secret: str, payload: str, ttl_seconds: int = 600) -> str:
    """state = base64(payload).signature HMAC — de un solo uso se valida en BD además."""
    exp = int((datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)).timestamp())
    body = f"{payload}:{exp}"
    encoded = base64.urlsafe_b64encode(body.encode()).decode().rstrip("=")
    sig = hmac.new(secret.encode(), encoded.encode(), hashlib.sha256).hexdigest()
    return f"{encoded}.{sig}"


def verify_signed_oauth_state(secret: str, state: str) -> str:
    try:
        encoded, sig = state.rsplit(".", 1)
    except ValueError as exc:
        raise ValueError("state mal formado") from exc
    expected = hmac.new(secret.encode(), encoded.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, sig):
        raise ValueError("state con firma inválida")
    pad = "=" * (-len(encoded) % 4)
    body = base64.urlsafe_b64decode(encoded + pad).decode()
    payload, exp_s = body.rsplit(":", 1)
    if int(exp_s) < int(datetime.now(timezone.utc).timestamp()):
        raise ValueError("state expirado")
    return payload


def generate_pkce_pair() -> tuple[str, str]:
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip("=")
    return verifier, challenge


def issue_dev_jwt(settings: Settings, user_id: UUID, email: str) -> str:
    """Solo para desarrollo/pruebas locales."""
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {
            "sub": str(user_id),
            "email": email,
            "iat": int(now.timestamp()),
            "exp": int((now + timedelta(hours=12)).timestamp()),
            "role": "authenticated",
        },
        settings.supabase_jwt_secret,
        algorithm="HS256",
    )
