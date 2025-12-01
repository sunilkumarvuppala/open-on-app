"""Pydantic models for request/response validation."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.db.models import CapsuleState
from app.core.config import settings


# ===== User Models =====
class UserBase(BaseModel):
    """Base user model."""
    email: EmailStr
    username: str = Field(
        min_length=settings.min_username_length,
        max_length=settings.max_username_length
    )
    first_name: str = Field(
        min_length=settings.min_name_length,
        max_length=settings.max_name_length
    )
    last_name: str = Field(
        min_length=settings.min_name_length,
        max_length=settings.max_name_length
    )
    full_name: Optional[str] = Field(
        None,
        max_length=settings.max_full_name_length
    )  # Computed from first_name + last_name


class UserCreate(UserBase):
    """User creation model."""
    password: str = Field(
        min_length=settings.min_password_length,
        max_length=settings.max_password_length
    )
    
    @field_validator("full_name", mode="before")
    @classmethod
    def compute_full_name(cls, v, info):
        """Compute full_name from first_name and last_name if not provided."""
        if v is None and "first_name" in info.data and "last_name" in info.data:
            first = info.data.get("first_name", "").strip()
            last = info.data.get("last_name", "").strip()
            if first and last:
                return f"{first} {last}"
        return v


class UserLogin(BaseModel):
    """User login model."""
    username: str
    password: str


class UserResponse(BaseModel):
    """User response model."""
    id: str
    email: EmailStr
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    full_name: Optional[str] = None
    is_active: bool
    created_at: datetime
    
    @classmethod
    def from_user_model(cls, user: "User") -> "UserResponse":
        """
        Create UserResponse from User model.
        
        The database User model only has full_name, so we parse it into first_name and last_name.
        """
        # Parse full_name into first_name and last_name
        first_name = None
        last_name = None
        if user.full_name:
            name_parts = user.full_name.strip().split(maxsplit=1)
            if len(name_parts) > 0:
                first_name = name_parts[0]
            if len(name_parts) > 1:
                last_name = name_parts[1]
        
        return cls(
            id=user.id,
            email=user.email,
            username=user.username,
            first_name=first_name,
            last_name=last_name,
            full_name=user.full_name,
            is_active=user.is_active,
            created_at=user.created_at,
        )
    
    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    """Token response model."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ===== Capsule Models =====
class CapsuleBase(BaseModel):
    """Base capsule model."""
    title: str = Field(min_length=1, max_length=255)
    body: str = Field(min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    allow_early_view: bool = False
    allow_receiver_reply: bool = True


class CapsuleCreate(CapsuleBase):
    """Capsule creation model."""
    receiver_id: str


class CapsuleUpdate(BaseModel):
    """Capsule update model (only for drafts)."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body: Optional[str] = Field(None, min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    receiver_id: Optional[str] = None
    allow_early_view: Optional[bool] = None
    allow_receiver_reply: Optional[bool] = None


class CapsuleSeal(BaseModel):
    """Model for sealing a capsule."""
    scheduled_unlock_at: datetime
    
    @field_validator("scheduled_unlock_at")
    @classmethod
    def validate_unlock_time(cls, v: datetime) -> datetime:
        """Validate unlock time is in the future."""
        from datetime import timedelta, timezone
        from app.core.config import settings
        
        # Ensure both datetimes are timezone-aware (UTC)
        # Convert incoming datetime to UTC if it's naive or has a different timezone
        if v.tzinfo is None:
            # If naive, assume it's UTC
            v = v.replace(tzinfo=timezone.utc)
        else:
            # If timezone-aware, convert to UTC
            v = v.astimezone(timezone.utc)
        
        # Use timezone-aware UTC datetime
        now = datetime.now(timezone.utc)
        min_unlock_time = now + timedelta(minutes=settings.min_unlock_minutes)
        
        if v <= min_unlock_time:
            raise ValueError(f"Unlock time must be at least {settings.min_unlock_minutes} minute(s) in the future")
        
        max_future = now + timedelta(days=settings.max_unlock_years * 365)
        if v > max_future:
            raise ValueError(f"Unlock time cannot be more than {settings.max_unlock_years} years in the future")
        
        return v


class CapsuleResponse(CapsuleBase):
    """Capsule response model."""
    id: str
    sender_id: str
    receiver_id: str
    state: CapsuleState
    created_at: datetime
    sealed_at: Optional[datetime]
    scheduled_unlock_at: Optional[datetime]
    opened_at: Optional[datetime]
    
    class Config:
        from_attributes = True
        use_enum_values = True


class CapsuleListResponse(BaseModel):
    """Paginated capsule list response."""
    capsules: list[CapsuleResponse]
    total: int
    page: int
    page_size: int


# ===== Draft Models =====
class DraftBase(BaseModel):
    """Base draft model."""
    title: str = Field(min_length=1, max_length=255)
    body: str = Field(min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    recipient_id: Optional[str] = None


class DraftCreate(DraftBase):
    """Draft creation model."""
    pass


class DraftUpdate(BaseModel):
    """Draft update model."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body: Optional[str] = Field(None, min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    recipient_id: Optional[str] = None


class DraftResponse(DraftBase):
    """Draft response model."""
    id: str
    owner_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ===== Recipient Models =====
class RecipientBase(BaseModel):
    """Base recipient model."""
    name: str = Field(min_length=1, max_length=255)
    email: Optional[EmailStr] = None
    user_id: Optional[str] = None


class RecipientCreate(RecipientBase):
    """Recipient creation model."""
    pass


class RecipientResponse(RecipientBase):
    """Recipient response model."""
    id: str
    owner_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# ===== Common Models =====
class MessageResponse(BaseModel):
    """Generic message response."""
    message: str
    detail: Optional[str] = None


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    timestamp: datetime
    version: str
