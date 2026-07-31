from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import List, Tuple

from pydantic_settings import BaseSettings, SettingsConfigDict


def _resolve_env_files() -> Tuple[str, ...]:
    """Busca `.env` en la raíz del monorepo y en `services/api`.

    Uvicorn arranca con cwd=`services/api`, así que `env_file=".env"` solo
    no encuentra el `.env` de la raíz y deja `google_oauth_client_id` vacío
    (Google: Missing required parameter: client_id).
    """
    here = Path(__file__).resolve()
    # app/config.py → api → services → repo root
    repo_root = here.parents[3]
    api_dir = here.parents[1]
    candidates = (repo_root / ".env", api_dir / ".env", Path.cwd() / ".env")
    found = tuple(str(p) for p in candidates if p.is_file())
    return found if found else (".env",)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_resolve_env_files(),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = "development"
    app_name: str = "rol-pagos-saas"
    api_public_url: str = "http://localhost:8000"
    admin_web_url: str = "http://localhost:3000"
    cors_origins: str = "http://localhost:3000"

    database_url: str = "postgresql+asyncpg://rolpagos:rolpagos_dev@localhost:5433/rolpagos"
    database_url_sync: str = "postgresql://rolpagos:rolpagos_dev@localhost:5433/rolpagos"

    supabase_url: str = ""
    supabase_jwt_secret: str = "change-me-local-jwt-secret-min-32-chars"
    supabase_service_role_key: str = ""

    token_encryption_key: str = ""
    token_encryption_key_version: str = "v1"
    use_gcp_secret_manager: bool = False
    gcp_project_id: str = ""

    google_oauth_client_id: str = ""
    google_oauth_client_secret: str = ""
    google_oauth_redirect_uri: str = (
        "http://localhost:8000/api/v1/integrations/gmail/callback"
    )
    gmail_pubsub_topic: str = ""
    gmail_pubsub_audience: str = ""
    gmail_watch_labels: str = "INBOX"

    storage_backend: str = "local"
    local_storage_path: str = "./storage/private"
    gcs_bucket: str = ""
    signed_url_ttl_seconds: int = 300

    pdf_max_bytes: int = 15_728_640
    rate_limit_per_minute: int = 120
    log_level: str = "INFO"
    payment_provider: str = "noop"
    kushki_webhook_secret: str = ""

    # En tests / desarrollo se puede desactivar validación JWT real
    auth_disabled_for_tests: bool = False

    @property
    def cors_origin_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def google_oauth_configured(self) -> bool:
        return bool(
            self.google_oauth_client_id.strip()
            and self.google_oauth_client_secret.strip()
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
