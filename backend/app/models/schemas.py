"""
Pydantic models for request/response validation.

This module defines all Pydantic models used for API request/response validation.
These models ensure type safety, data validation, and automatic serialization.

Model Categories:
- User Models: Authentication and user management
- Capsule Models: Time-locked letter creation and management
- Draft Models: Unsent capsule drafts
- Recipient Models: Saved recipient contacts
- Common Models: Shared response types

Benefits:
- Automatic validation of input data
- Type safety with Python type hints
- Automatic serialization/deserialization
- Clear API contracts
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.db.models import CapsuleState
from app.core.config import settings


# ===== User Models =====
class UserBase(BaseModel):
    """
    Base user model with common user fields.
    
    This is the base class for user-related models.
    Contains fields shared across user creation and response models.
    
    Fields:
    - email: User email address (validated as EmailStr)
    - username: Unique username (3-100 characters)
    - first_name: User's first name (1-100 characters)
    - last_name: User's last name (1-100 characters)
    - full_name: Optional full name (computed from first_name + last_name)
    
    Note:
        full_name is optional and can be computed from first_name + last_name
        All length constraints come from settings for consistency
    """
    email: EmailStr  # Pydantic validates email format automatically
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
    )  # Computed from first_name + last_name if not provided


class UserCreate(UserBase):
    """
    User creation model for signup endpoint.
    
    Extends UserBase with password field for account creation.
    
    Fields:
    - Inherits all fields from UserBase
    - password: User password (8-128 characters, validated for strength)
    
    Validation:
    - Email format validated by Pydantic EmailStr
    - Username length validated (3-100 characters)
    - Password length validated (8-128 characters)
    - Password strength validated in API endpoint (uppercase, lowercase, number)
    - full_name computed automatically from first_name + last_name if not provided
    """
    password: str = Field(
        min_length=settings.min_password_length,
        max_length=settings.max_password_length
    )
    
    @field_validator("full_name", mode="before")
    @classmethod
    def compute_full_name(cls, v, info):
        """
        Compute full_name from first_name and last_name if not provided.
        
        This validator automatically creates full_name from first_name and last_name
        if full_name is not explicitly provided in the request.
        
        Args:
            v: Value of full_name field (may be None)
            info: Validation info containing other field values
        
        Returns:
            Computed full_name or original value if already provided
        """
        if v is None and "first_name" in info.data and "last_name" in info.data:
            first = info.data.get("first_name", "").strip()
            last = info.data.get("last_name", "").strip()
            if first and last:
                return f"{first} {last}"
        return v


class UserLogin(BaseModel):
    """
    User login model for authentication endpoint.
    
    Contains only the fields needed for login.
    
    Fields:
    - username: User's username (not email, for login)
    - password: User's password (plain text, will be hashed and verified)
    
    Note:
        Password is sent as plain text but never stored or logged
        Password is verified against hashed password in database
    """
    username: str
    password: str


class UserResponse(BaseModel):
    """
    User response model for API responses.
    
    Contains user information returned to clients.
    Excludes sensitive fields like password hash.
    
    Fields:
    - id: User UUID
    - email: User email address
    - username: User username
    - first_name: Parsed from full_name
    - last_name: Parsed from full_name
    - full_name: Full name from database
    - is_active: Account status
    - created_at: Account creation timestamp
    
    Note:
        Database stores only full_name, so first_name and last_name
        are parsed from full_name in from_user_model()
    """
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
        Create UserResponse from User database model.
        
        Converts database model to API response model.
        Parses full_name into first_name and last_name for API compatibility.
        
        Args:
            user: User database model instance
        
        Returns:
            UserResponse instance with parsed name fields
        
        Note:
            Database User model only has full_name, so we parse it
            into first_name and last_name for the API response
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
        from_attributes = True  # Allow creation from ORM models


class TokenResponse(BaseModel):
    """
    Token response model for authentication endpoints.
    
    Returned after successful login or signup.
    
    Fields:
    - access_token: JWT access token (short-lived, used for API requests)
    - refresh_token: JWT refresh token (long-lived, used to get new access tokens)
    - token_type: Token type (always "bearer" for JWT)
    
    Note:
        Access token expires in 30 minutes (configurable)
        Refresh token expires in 7 days (configurable)
        Tokens are JWT format and contain user ID and username
    """
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ===== Capsule Models =====
class CapsuleBase(BaseModel):
    """
    Base capsule model with common capsule fields.
    
    Contains fields shared across capsule creation, update, and response models.
    
    Fields:
    - title: Capsule title/label (1-255 characters)
    - body: Capsule content/message (minimum 1 character)
    - media_urls: Optional list of media URLs (photos, etc.)
    - theme: Optional theme name for styling (max 50 characters)
    - allow_early_view: Whether receiver can view before unlock time (default: False)
    - allow_receiver_reply: Whether receiver can reply (default: True, future feature)
    
    Note:
        media_urls is stored as JSON string in database
        theme is optional and used for UI customization
    """
    title: str = Field(min_length=1, max_length=255)
    body: str = Field(min_length=1)  # Minimum 1 character, no maximum (uses Text field in DB)
    media_urls: Optional[list[str]] = None  # List of URLs, stored as JSON string
    theme: Optional[str] = Field(None, max_length=50)
    allow_early_view: bool = False  # Default: no early viewing
    allow_receiver_reply: bool = True  # Default: allow replies (future feature)


class CapsuleCreate(CapsuleBase):
    """
    Capsule creation model for creating new capsules.
    
    Extends CapsuleBase with receiver_id field.
    
    Fields:
    - Inherits all fields from CapsuleBase
    - receiver_id: UUID of the user who will receive the capsule
    
    Validation:
    - receiver_id must be a valid UUID
    - receiver_id must reference an existing user
    - All fields validated according to CapsuleBase rules
    
    Note:
        Capsules are created in DRAFT state
        Must be sealed (set unlock time) before sending
    """
    receiver_id: str  # UUID of receiver user


class CapsuleUpdate(BaseModel):
    """
    Capsule update model (only for drafts).
    
    All fields are optional to allow partial updates.
    Only drafts can be updated (capsules are immutable after sealing).
    
    Fields:
    - title: Optional new title
    - body: Optional new content
    - media_urls: Optional new media URLs
    - theme: Optional new theme
    - receiver_id: Optional new receiver (can change recipient)
    - allow_early_view: Optional early view setting
    - allow_receiver_reply: Optional reply permission
    
    Note:
        This model is only used for updating drafts
        Sealed capsules cannot be updated
    """
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body: Optional[str] = Field(None, min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    receiver_id: Optional[str] = None  # Can change recipient for drafts
    allow_early_view: Optional[bool] = None
    allow_receiver_reply: Optional[bool] = None


class CapsuleSeal(BaseModel):
    """
    Model for sealing a capsule (setting unlock time).
    
    Used when converting a draft to a sealed capsule.
    
    Fields:
    - scheduled_unlock_at: Future datetime when capsule should unlock
    
    Validation:
    - scheduled_unlock_at must be timezone-aware (converted to UTC)
    - Must be at least min_unlock_minutes in the future
    - Cannot be more than max_unlock_years in the future
    
    Note:
        Once sealed, capsule cannot be edited
        Unlock time cannot be changed after sealing
    """
    scheduled_unlock_at: datetime
    
    @field_validator("scheduled_unlock_at")
    @classmethod
    def validate_unlock_time(cls, v: datetime) -> datetime:
        """
        Validate unlock time is in the future and within limits.
        
        Ensures:
        - Datetime is timezone-aware (converts to UTC)
        - Unlock time is at least min_unlock_minutes in the future
        - Unlock time is not more than max_unlock_years in the future
        
        Args:
            v: Datetime to validate
        
        Returns:
            Timezone-aware UTC datetime
        
        Raises:
            ValueError: If unlock time is invalid
        """
        from datetime import timedelta, timezone
        from app.core.config import settings
        
        # ===== Ensure Timezone-Aware (UTC) =====
        # Convert incoming datetime to UTC if it's naive or has a different timezone
        if v.tzinfo is None:
            # If naive, assume it's UTC
            v = v.replace(tzinfo=timezone.utc)
        else:
            # If timezone-aware, convert to UTC
            v = v.astimezone(timezone.utc)
        
        # ===== Validate Time Constraints =====
        # Use timezone-aware UTC datetime for comparison
        now = datetime.now(timezone.utc)
        min_unlock_time = now + timedelta(minutes=settings.min_unlock_minutes)
        
        # Check minimum time (must be at least X minutes in the future)
        if v <= min_unlock_time:
            raise ValueError(f"Unlock time must be at least {settings.min_unlock_minutes} minute(s) in the future")
        
        # Check maximum time (cannot be more than X years in the future)
        max_future = now + timedelta(days=settings.max_unlock_years * 365)
        if v > max_future:
            raise ValueError(f"Unlock time cannot be more than {settings.max_unlock_years} years in the future")
        
        return v


class CapsuleResponse(CapsuleBase):
    """
    Capsule response model for API responses.
    
    Contains all capsule information returned to clients.
    Extends CapsuleBase with metadata fields.
    
    Fields:
    - Inherits all fields from CapsuleBase
    - id: Capsule UUID
    - sender_id: UUID of user who sent the capsule
    - receiver_id: UUID of user who will receive the capsule
    - state: Current capsule state (DRAFT, SEALED, UNFOLDING, READY, OPENED)
    - created_at: When capsule was created
    - sealed_at: When capsule was sealed (unlock time set)
    - scheduled_unlock_at: When capsule will unlock
    - opened_at: When receiver opened the capsule (if opened)
    
    Note:
        All timestamps are timezone-aware (UTC)
        State follows strict state machine rules
    """
    id: str
    sender_id: str
    receiver_id: str
    state: CapsuleState
    created_at: datetime
    sealed_at: Optional[datetime]
    scheduled_unlock_at: Optional[datetime]
    opened_at: Optional[datetime]
    
    class Config:
        from_attributes = True  # Allow creation from ORM models
        use_enum_values = True  # Use enum values instead of enum objects


class CapsuleListResponse(BaseModel):
    """
    Paginated capsule list response.
    
    Used for listing capsules with pagination support.
    
    Fields:
    - capsules: List of capsule responses
    - total: Total number of capsules (across all pages)
    - page: Current page number (1-indexed)
    - page_size: Number of items per page
    
    Note:
        Used for both inbox and outbox queries
        Supports pagination for large result sets
    """
    capsules: list[CapsuleResponse]
    total: int
    page: int
    page_size: int


# ===== Draft Models =====
class DraftBase(BaseModel):
    """
    Base draft model with common draft fields.
    
    Drafts are unsent capsules that can be edited freely.
    
    Fields:
    - title: Draft title (1-255 characters)
    - body: Draft content (minimum 1 character)
    - media_urls: Optional list of media URLs
    - theme: Optional theme name (max 50 characters)
    - recipient_id: Optional recipient ID (can be set later)
    
    Note:
        Similar structure to CapsuleBase for easy conversion
        recipient_id is optional (can be added later)
    """
    title: str = Field(min_length=1, max_length=255)
    body: str = Field(min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    recipient_id: Optional[str] = None  # Optional recipient


class DraftCreate(DraftBase):
    """
    Draft creation model for creating new drafts.
    
    Inherits all fields from DraftBase.
    No additional fields needed for creation.
    """
    pass


class DraftUpdate(BaseModel):
    """
    Draft update model for updating existing drafts.
    
    All fields are optional to allow partial updates.
    Drafts can be freely edited until converted to capsules.
    
    Fields:
    - title: Optional new title
    - body: Optional new content
    - media_urls: Optional new media URLs
    - theme: Optional new theme
    - recipient_id: Optional new recipient
    
    Note:
        All fields are optional for partial updates
        Drafts can be updated multiple times
    """
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body: Optional[str] = Field(None, min_length=1)
    media_urls: Optional[list[str]] = None
    theme: Optional[str] = Field(None, max_length=50)
    recipient_id: Optional[str] = None


class DraftResponse(DraftBase):
    """
    Draft response model for API responses.
    
    Contains all draft information returned to clients.
    Extends DraftBase with metadata fields.
    
    Fields:
    - Inherits all fields from DraftBase
    - id: Draft UUID
    - owner_id: UUID of user who owns the draft
    - created_at: When draft was created
    - updated_at: When draft was last updated (auto-updated on changes)
    
    Note:
        updated_at is automatically updated on every save
        Used to show most recently edited drafts first
    """
    id: str
    owner_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True  # Allow creation from ORM models


# ===== Recipient Models =====
class RecipientBase(BaseModel):
    """
    Base recipient model with common recipient fields.
    
    Recipients are saved contacts that can be used when creating capsules.
    
    Fields:
    - name: Recipient name (1-255 characters)
    - email: Optional email address (validated if provided)
    - user_id: Optional link to registered user account
    
    Use Cases:
    - Linked recipient (user_id set): Recipient is a registered user
    - Unlinked recipient (user_id null): Recipient is just a contact
    
    Note:
        user_id links recipient to a User account
        When creating capsules, linked recipients use user_id as receiver_id
    """
    name: str = Field(min_length=1, max_length=255)
    email: Optional[EmailStr] = None  # Optional, validated if provided
    user_id: Optional[str] = None  # Optional link to registered user


class RecipientCreate(RecipientBase):
    """
    Recipient creation model for adding new recipients.
    
    Inherits all fields from RecipientBase.
    No additional fields needed for creation.
    """
    pass


class RecipientResponse(RecipientBase):
    """
    Recipient response model for API responses.
    
    Contains all recipient information returned to clients.
    Extends RecipientBase with metadata fields.
    
    Fields:
    - Inherits all fields from RecipientBase
    - id: Recipient UUID
    - owner_id: UUID of user who saved this recipient
    - created_at: When recipient was saved
    
    Note:
        owner_id identifies who saved the recipient
        Recipients are private to the owner
    """
    id: str
    owner_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True  # Allow creation from ORM models


# ===== Common Models =====
class MessageResponse(BaseModel):
    """
    Generic message response for simple API responses.
    
    Used for endpoints that return a simple message.
    
    Fields:
    - message: Main message text
    - detail: Optional additional details
    
    Usage:
        Used for success/error messages, confirmations, etc.
    """
    message: str
    detail: Optional[str] = None


class HealthResponse(BaseModel):
    """
    Health check response for monitoring endpoints.
    
    Used by health check endpoint to indicate API status.
    
    Fields:
    - status: Health status (e.g., "healthy", "unhealthy")
    - timestamp: Current server timestamp
    - version: Application version
    
    Usage:
        Used by monitoring systems to check API availability
    """
    status: str
    timestamp: datetime
    version: str
