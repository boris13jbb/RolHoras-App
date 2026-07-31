from __future__ import annotations

import uuid
from pathlib import Path

from app.config import Settings


class StorageService:
    """Almacenamiento privado local (dev) o interfaz lista para GCS."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.root = Path(settings.local_storage_path)
        self.root.mkdir(parents=True, exist_ok=True)

    async def save_bytes(
        self,
        *,
        organization_id: uuid.UUID,
        user_id: uuid.UUID,
        filename: str,
        data: bytes,
    ) -> str:
        safe_name = Path(filename).name.replace("..", "_")
        rel = Path(str(organization_id)) / str(user_id) / f"{uuid.uuid4().hex}_{safe_name}"
        target = self.root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        return str(rel).replace("\\", "/")

    def absolute_path(self, storage_path: str) -> Path:
        return self.root / storage_path

    async def read_bytes(self, storage_path: str) -> bytes:
        path = self.absolute_path(storage_path)
        return path.read_bytes()
