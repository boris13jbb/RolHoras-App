from __future__ import annotations

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ErrorBody(BaseModel):
    code: str
    message: str
    details: Optional[dict[str, Any]] = None


class OrganizationCreate(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    is_personal: bool = False
    timezone: str = "America/Guayaquil"


class OrganizationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    timezone: str
    is_personal: bool
    role: Optional[str] = None


class MembershipInvite(BaseModel):
    email: str
    role: str = "employee"


class GmailAuthorizeResponse(BaseModel):
    authorization_url: str
    state: str
    expires_in_seconds: int = 600


class GmailStatusResponse(BaseModel):
    connected: bool
    status: str
    email_address: Optional[str] = None
    last_sync_at: Optional[datetime] = None
    last_success_at: Optional[datetime] = None
    watch_expiration: Optional[datetime] = None
    sender_filter: Optional[str] = None
    last_error_code: Optional[str] = None
    last_error_message: Optional[str] = None


class GmailSyncResponse(BaseModel):
    status: str
    documents_imported: int = 0
    message: str


class DocumentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: str
    original_filename: Optional[str]
    period_year: Optional[int]
    period_month: Optional[int]
    source: str
    content_sha256: str
    created_at: datetime


class HourEntryCreate(BaseModel):
    entry_date: str
    period_year: int
    period_month: int = Field(ge=1, le=12)
    minutes: int = Field(gt=0)
    surcharge_percent: str = "100"
    entry_type: str = "worked"
    notes: Optional[str] = None


class HourEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    minutes: int
    surcharge_percent: str
    equivalent_minutes: int
    entry_type: str
    period_year: int
    period_month: int


class PeriodBalanceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    period_year: int
    period_month: int
    debt_minutes: int
    paid_minutes: int
    pending_minutes: int
    credit_minutes: int
    is_closed: bool


class DevBootstrapRequest(BaseModel):
    email: str
    full_name: str = "Usuario Demo"
    organization_name: str = "Organización Demo"


class DevBootstrapResponse(BaseModel):
    access_token: str
    user_id: UUID
    organization_id: UUID
    email: str
