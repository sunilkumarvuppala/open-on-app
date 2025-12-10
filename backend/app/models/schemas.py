"""
Pydantic models for request/response validation matching Supabase schema.

This module defines all Pydantic models used for API request/response validation.
These models ensure type safety, data validation, and automatic serialization.

Model Categories:
- User Profile Models: User profile management (auth handled by Supabase)
- Capsule Models: Time-locked letter creation and management
- Recipient Models: Saved recipient contacts
- Theme/Animation Models: Visual customization
- Common Models: Shared response types

Benefits:
- Automatic validation of input data
- Type safety with Python type hints
- Automatic serialization/deserialization
- Clear API contracts
- Matches Supabase schema exactly
"""
from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field, field_validator
from app.db.models import CapsuleStatus, RecipientRelationship
from app.core.config import settings


# ===== User Profile Models =====
class UserProfileResponse(BaseModel):
    """
    User profile response model matching Supabase schema.
    
    Contains user profile information returned to clients.
    Note: Authentication is handled by Supabase Auth (auth.users table).
    This model contains profile data from user_profiles table plus email from auth.users.
    
    Fields:
    - user_id: User UUID (from auth.users)
    - email: User's email address (from auth.users, required)
    - first_name: User's first name
    - last_name: User's last name
    - username: User's username for searching and display
    - avatar_url: URL to user's profile picture
    - premium_status: Whether user has active premium subscription
    - premium_until: When premium subscription expires
    - is_admin: Admin flag
    - country: User's country
    - device_token: Push notification device token
    - last_login: Last login timestamp
    - created_at: Profile creation timestamp
    - updated_at: Last profile update timestamp
    """
    user_id: UUID
    email: str  # Email from Supabase Auth (required)
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    premium_status: bool = False
    premium_until: Optional[datetime] = None
    is_admin: bool = False
    country: Optional[str] = None
    device_token: Optional[str] = None
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    @classmethod
    def from_user_profile(cls, profile: "UserProfile", email: Optional[str] = None) -> "UserProfileResponse":
        """
        Create UserProfileResponse from UserProfile database model.
        
        Args:
            profile: UserProfile database model
            email: User's email from Supabase Auth (required, must be provided)
        """
        if email is None:
            raise ValueError("Email is required for UserProfileResponse. Fetch from Supabase Auth.")
        
        return cls(
            user_id=profile.user_id,
            email=email,
            first_name=profile.first_name,
            last_name=profile.last_name,
            username=profile.username,
            avatar_url=profile.avatar_url,
            premium_status=profile.premium_status,
            premium_until=profile.premium_until,
            is_admin=profile.is_admin,
            country=profile.country,
            device_token=profile.device_token,
            last_login=profile.last_login,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )
    
    @property
    def full_name(self) -> Optional[str]:
        """Computed property for backward compatibility."""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.first_name:
            return self.first_name
        elif self.last_name:
            return self.last_name
        return None
    
    class Config:
        from_attributes = True


# Legacy models (kept for backward compatibility during migration)
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
    email: str  # Email address (legacy model, not used in Supabase migration)
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
    email: str  # Email address (legacy model, not used in Supabase migration)
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
    Base capsule model matching Supabase schema.
    
    Contains fields shared across capsule creation, update, and response models.
    
    Fields:
    - title: Capsule title/label (optional, 1-255 characters)
    - body_text: Plain text content (required if body_rich_text is None)
    - body_rich_text: Rich text content as JSONB (required if body_text is None)
    - is_anonymous: Hide sender identity from recipient (default: False)
    - is_disappearing: Delete message after opening (default: False)
    - disappearing_after_open_seconds: Seconds before deletion (required if is_disappearing)
    - theme_id: UUID of visual theme (optional)
    - animation_id: UUID of reveal animation (optional)
    - expires_at: When capsule expires (optional)
    
    Note:
        Must have either body_text OR body_rich_text (not both empty)
        Matches Supabase schema exactly
    """
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body_text: Optional[str] = Field(None, min_length=1)  # Plain text content
    body_rich_text: Optional[dict] = None  # Rich text as JSONB
    is_anonymous: bool = False
    is_disappearing: bool = False
    disappearing_after_open_seconds: Optional[int] = Field(None, gt=0)
    theme_id: Optional[UUID] = None
    animation_id: Optional[UUID] = None
    expires_at: Optional[datetime] = None


class CapsuleCreate(CapsuleBase):
    """
    Capsule creation model matching Supabase schema.
    
    Extends CapsuleBase with recipient_id and unlocks_at fields.
    
    Fields:
    - Inherits all fields from CapsuleBase
    - recipient_id: UUID of the recipient (references recipients table)
    - unlocks_at: When capsule becomes available to open (required, must be future)
    
    Validation:
    - recipient_id must be a valid UUID
    - recipient_id must reference an existing recipient
    - unlocks_at must be in the future
    - Must have either body_text OR body_rich_text
    
    Note:
        Capsules are created in 'sealed' status
        unlocks_at is required (no draft state in Supabase)
    """
    recipient_id: UUID  # UUID of recipient (references recipients table)
    unlocks_at: datetime  # When capsule unlocks (required)


class CapsuleUpdate(BaseModel):
    """
    Capsule update model (only before opening).
    
    All fields are optional to allow partial updates.
    Capsules can only be updated before they are opened.
    
    Fields:
    - title: Optional new title
    - body_text: Optional new plain text content
    - body_rich_text: Optional new rich text content
    - is_anonymous: Optional anonymous flag
    - is_disappearing: Optional disappearing flag
    - disappearing_after_open_seconds: Optional seconds before deletion
    - theme_id: Optional theme UUID
    - animation_id: Optional animation UUID
    - expires_at: Optional expiration datetime
    
    Note:
        Once opened, capsules cannot be updated
        unlocks_at cannot be changed after creation
    """
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body_text: Optional[str] = Field(None, min_length=1)
    body_rich_text: Optional[dict] = None
    is_anonymous: Optional[bool] = None
    is_disappearing: Optional[bool] = None
    disappearing_after_open_seconds: Optional[int] = Field(None, gt=0)
    theme_id: Optional[UUID] = None
    animation_id: Optional[UUID] = None
    expires_at: Optional[datetime] = None


class CapsuleSeal(BaseModel):
    """
    Model for updating capsule unlock time (legacy - kept for compatibility).
    
    Note: In Supabase schema, capsules are created with unlocks_at already set.
    This endpoint may be used to update unlock time before capsule is opened.
    
    Fields:
    - unlocks_at: Future datetime when capsule should unlock
    
    Validation:
    - unlocks_at must be timezone-aware (converted to UTC)
    - Must be at least min_unlock_minutes in the future
    - Cannot be more than max_unlock_years in the future
    """
    unlocks_at: datetime
    
    @field_validator("unlocks_at")
    @classmethod
    def validate_unlock_time(cls, v: datetime) -> datetime:
        """Validate unlock time is in the future and within limits."""
        from datetime import timedelta, timezone
        from app.core.config import settings
        
        # Ensure timezone-aware (UTC)
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        else:
            v = v.astimezone(timezone.utc)
        
        # Validate time constraints
        now = datetime.now(timezone.utc)
        min_unlock_time = now + timedelta(minutes=settings.min_unlock_minutes)
        
        if v <= min_unlock_time:
            raise ValueError(f"Unlock time must be at least {settings.min_unlock_minutes} minute(s) in the future")
        
        max_future = now + timedelta(days=settings.max_unlock_years * 365)
        if v > max_future:
            raise ValueError(f"Unlock time cannot be more than {settings.max_unlock_years} years in the future")
        
        return v


class CapsuleResponse(CapsuleBase):
    """
    Capsule response model matching Supabase schema.
    
    Contains all capsule information returned to clients.
    Extends CapsuleBase with metadata fields.
    
    Fields:
    - Inherits all fields from CapsuleBase
    - id: Capsule UUID
    - sender_id: UUID of user who sent the capsule (references auth.users)
    - recipient_id: UUID of recipient (references recipients table)
    - status: Current capsule status (sealed, ready, opened, expired)
    - unlocks_at: When capsule becomes available to open
    - opened_at: When receiver opened the capsule (if opened)
    - deleted_at: Soft delete timestamp (for disappearing messages)
    - created_at: When capsule was created
    - updated_at: When capsule was last updated
    
    Note:
        All timestamps are timezone-aware (UTC)
        Status follows Supabase schema (no DRAFT state)
    """
    id: UUID
    sender_id: UUID
    recipient_id: UUID
    status: CapsuleStatus
    unlocks_at: datetime
    opened_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
        use_enum_values = True


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
    Base recipient model matching Supabase schema.
    
    Recipients are saved contacts that can be used when creating capsules.
    
    Fields:
    - name: Recipient name (required, 1+ characters)
    - email: Optional email address (validated if provided)
    - avatar_url: Optional URL to recipient's avatar image
    - relationship: Relationship type (defaults to 'friend')
    
    Note:
        Matches Supabase schema exactly
        No user_id field (recipients are independent contacts)
    """
    name: str = Field(min_length=1, max_length=255)
    email: Optional[str] = None  # Optional, validated if provided
    avatar_url: Optional[str] = None
    relationship: RecipientRelationship = RecipientRelationship.FRIEND


class RecipientCreate(RecipientBase):
    """
    Recipient creation model for adding new recipients.
    
    Inherits all fields from RecipientBase.
    No additional fields needed for creation.
    """
    pass


class RecipientResponse(RecipientBase):
    """
    Recipient response model matching Supabase schema.
    
    Contains all recipient information returned to clients.
    Extends RecipientBase with metadata fields.
    
    Fields:
    - Inherits all fields from RecipientBase
    - id: Recipient UUID
    - owner_id: UUID of user who saved this recipient (references auth.users)
    - created_at: When recipient was saved
    - updated_at: When recipient was last updated
    
    Note:
        owner_id identifies who saved the recipient
        Recipients are private to the owner
    """
    id: UUID
    owner_id: UUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


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
