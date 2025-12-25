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
from app.db.models import CapsuleStatus
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


class UserProfileUpdate(BaseModel):
    """
    User profile update request model.
    
    All fields are optional for partial updates.
    Only provided fields will be updated.
    """
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    country: Optional[str] = None
    device_token: Optional[str] = None
    
    @field_validator('first_name', 'last_name')
    @classmethod
    def validate_name_fields(cls, v: Optional[str]) -> Optional[str]:
        """Validate name fields only if provided."""
        if v is not None:
            if len(v) < settings.min_name_length or len(v) > settings.max_name_length:
                raise ValueError(f"Name must be between {settings.min_name_length} and {settings.max_name_length} characters")
        return v
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: Optional[str]) -> Optional[str]:
        """Validate username only if provided."""
        if v is not None:
            if len(v) < settings.min_username_length or len(v) > settings.max_username_length:
                raise ValueError(f"Username must be between {settings.min_username_length} and {settings.max_username_length} characters")
        return v


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
    reveal_delay_seconds: Optional[int] = Field(None, ge=0, le=259200)  # 0-72 hours
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
    - sender_name: Display name of sender (from user_profiles, or 'Anonymous' if is_anonymous)
    - sender_avatar_url: Avatar URL of sender (None if is_anonymous)
    - recipient_id: UUID of recipient (references recipients table)
    - recipient_name: Name of recipient (from recipients table)
    - status: Current capsule status (sealed, ready, opened, expired)
    - unlocks_at: When capsule becomes available to open
    - opened_at: When receiver opened the capsule (if opened)
    - deleted_at: Soft delete timestamp (for disappearing messages)
    - created_at: When capsule was created
    - updated_at: When capsule was last updated
    
    Note:
        All timestamps are timezone-aware (UTC)
        Status follows Supabase schema (no DRAFT state)
        sender_name and sender_avatar_url respect is_anonymous flag
    """
    id: UUID
    sender_id: Optional[UUID] = None  # None if is_anonymous
    sender_name: Optional[str] = None  # 'Anonymous' if is_anonymous, otherwise sender's display name
    sender_avatar_url: Optional[str] = None  # None if is_anonymous
    recipient_id: UUID
    recipient_name: Optional[str] = None  # Name from recipients table
    recipient_avatar_url: Optional[str] = None  # Avatar URL of recipient (from linked user profile or recipient's own avatar_url)
    status: CapsuleStatus
    unlocks_at: datetime
    opened_at: Optional[datetime] = None
    reveal_at: Optional[datetime] = None  # When anonymous sender will be revealed
    sender_revealed_at: Optional[datetime] = None  # When anonymous sender was actually revealed
    deleted_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    @classmethod
    def from_orm_with_profile(cls, capsule, sender_profile=None, recipient=None, recipient_user_profile=None):
        """
        Create CapsuleResponse from ORM model with populated sender/recipient info.
        
        Args:
            capsule: Capsule database model instance
            sender_profile: Optional UserProfile for sender (if not provided, will use relationship)
            recipient: Optional Recipient model (if not provided, will use relationship)
            recipient_user_profile: Optional UserProfile for recipient (for connection-based recipients)
        
        Returns:
            CapsuleResponse with populated sender_name and recipient_name
        """
        # Get sender profile from relationship if not provided
        if sender_profile is None:
            sender_profile = capsule.sender_profile if hasattr(capsule, 'sender_profile') else None
        
        # Get recipient from relationship if not provided
        if recipient is None:
            recipient = capsule.recipient if hasattr(capsule, 'recipient') else None
        
        # Build sender name (respects is_anonymous and reveal status)
        sender_name = None
        sender_avatar_url = None
        sender_id = None
        
        # Check if anonymous sender should be revealed
        is_revealed = False
        if capsule.is_anonymous:
            # Check if sender has been revealed
            reveal_at = getattr(capsule, 'reveal_at', None)
            sender_revealed_at = getattr(capsule, 'sender_revealed_at', None)
            opened_at = getattr(capsule, 'opened_at', None)
            reveal_delay_seconds = getattr(capsule, 'reveal_delay_seconds', None)
            
            if sender_revealed_at is not None:
                # Explicitly revealed by job
                is_revealed = True
            elif reveal_at is not None:
                # Check if reveal time has passed
                from datetime import datetime, timezone
                now = datetime.now(timezone.utc)
                if reveal_at <= now:
                    is_revealed = True
            elif opened_at is not None and reveal_delay_seconds is not None:
                # Backward compatibility: Calculate reveal_at on the fly if missing
                # This handles existing letters opened before reveal_at was added
                from datetime import timedelta
                calculated_reveal_at = opened_at + timedelta(seconds=reveal_delay_seconds)
                from datetime import datetime, timezone
                now = datetime.now(timezone.utc)
                if calculated_reveal_at <= now:
                    is_revealed = True
        
        if capsule.is_anonymous and not is_revealed:
            # Anonymous and not yet revealed
            sender_name = 'Anonymous'
            sender_id = None
            sender_avatar_url = None
        elif sender_profile:
            # Build display name from first_name and last_name
            name_parts = []
            if sender_profile.first_name:
                name_parts.append(sender_profile.first_name)
            if sender_profile.last_name:
                name_parts.append(sender_profile.last_name)
            
            if name_parts:
                sender_name = ' '.join(name_parts)
            elif sender_profile.username:
                sender_name = sender_profile.username
            else:
                sender_name = f"User {str(capsule.sender_id)[:8]}"
            
            sender_id = capsule.sender_id
            sender_avatar_url = sender_profile.avatar_url
        
        # Get recipient name and avatar
        recipient_name = None
        recipient_avatar_url = None
        if recipient:
            recipient_name = recipient.name
            # For connection-based recipients, prefer linked user's avatar (always up-to-date)
            # Fall back to recipient's own avatar_url if linked user profile doesn't have one
            # For email-based recipients, use recipient's own avatar_url
            linked_user_id = getattr(recipient, 'linked_user_id', None)
            recipient_own_avatar_url = getattr(recipient, 'avatar_url', None)
            
            if linked_user_id and recipient_user_profile:
                # Connection-based recipient: prefer linked user's avatar (most up-to-date)
                # But fall back to recipient's own avatar_url if linked user doesn't have one
                recipient_avatar_url = recipient_user_profile.avatar_url or recipient_own_avatar_url
            elif recipient_own_avatar_url:
                # Email-based recipient or connection-based with no linked profile: use recipient's own avatar_url
                recipient_avatar_url = recipient_own_avatar_url
            else:
                recipient_avatar_url = None
        
        # Create response dict
        response_data = {
            'id': capsule.id,
            'sender_id': sender_id,
            'sender_name': sender_name,
            'sender_avatar_url': sender_avatar_url,
            'recipient_id': capsule.recipient_id,
            'recipient_name': recipient_name,
            'recipient_avatar_url': recipient_avatar_url,
            'title': capsule.title,
            'body_text': capsule.body_text,
            'body_rich_text': capsule.body_rich_text,
            'is_anonymous': capsule.is_anonymous,
            'reveal_delay_seconds': getattr(capsule, 'reveal_delay_seconds', None),
            'is_disappearing': capsule.is_disappearing,
            'disappearing_after_open_seconds': capsule.disappearing_after_open_seconds,
            'theme_id': capsule.theme_id,
            'animation_id': capsule.animation_id,
            'expires_at': capsule.expires_at,
            'status': capsule.status,
            'unlocks_at': capsule.unlocks_at,
            'opened_at': capsule.opened_at,
            'reveal_at': getattr(capsule, 'reveal_at', None),
            'sender_revealed_at': getattr(capsule, 'sender_revealed_at', None),
            'deleted_at': capsule.deleted_at,
            'created_at': capsule.created_at,
            'updated_at': capsule.updated_at,
        }
        
        return cls(**response_data)
    
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
    theme: Optional[str] = Field(None, max_length=50)  # Matches MAX_THEME_NAME_LENGTH constant
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
    theme: Optional[str] = Field(None, max_length=50)  # Matches MAX_THEME_NAME_LENGTH constant
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
    - username: Optional @username for display
    
    Note:
        Matches Supabase schema exactly
        No user_id field (recipients are independent contacts)
    """
    name: str = Field(min_length=1, max_length=255)
    email: Optional[str] = None  # Optional, validated if provided
    avatar_url: Optional[str] = None
    username: Optional[str] = None  # Optional @username for display


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
    
    If linked_user_id is provided, this recipient represents a connection
    (mutual friend) rather than a manually added contact.
    
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
    linked_user_id: Optional[UUID] = None  # If set, this recipient represents a connection
    
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


# ===== Connection Models =====
class ConnectionRequestCreate(BaseModel):
    """
    Request model for creating a connection request.
    
    Fields:
    - to_user_id: UUID of user to send request to
    - message: Optional message to include with request
    """
    to_user_id: UUID
    message: Optional[str] = Field(None, max_length=500)  # Matches MAX_CONNECTION_MESSAGE_LENGTH


class ConnectionRequestResponse(BaseModel):
    """
    Response model for connection request.
    
    Matches Supabase connection_requests table schema.
    """
    id: UUID
    from_user_id: UUID
    to_user_id: UUID
    status: str  # pending, accepted, declined
    message: Optional[str] = None
    declined_reason: Optional[str] = None
    acted_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    # User profile info for display
    # from_user_* fields: Profile of the sender (for incoming requests)
    from_user_first_name: Optional[str] = None
    from_user_last_name: Optional[str] = None
    from_user_username: Optional[str] = None
    from_user_avatar_url: Optional[str] = None
    # to_user_* fields: Profile of the recipient (for outgoing requests)
    to_user_first_name: Optional[str] = None
    to_user_last_name: Optional[str] = None
    to_user_username: Optional[str] = None
    to_user_avatar_url: Optional[str] = None


class ConnectionRequestUpdate(BaseModel):
    """
    Request model for responding to a connection request.
    
    Fields:
    - status: Response status (accepted or declined)
    - declined_reason: Optional reason if declining
    """
    status: str = Field(..., pattern="^(accepted|declined)$")
    declined_reason: Optional[str] = Field(None, max_length=500)  # Matches MAX_DECLINED_REASON_LENGTH


class ConnectionResponse(BaseModel):
    """
    Response model for a mutual connection.
    
    Matches Supabase connections table schema.
    """
    user_id_1: UUID
    user_id_2: UUID
    connected_at: datetime
    # User profile info for the other user (not the current user)
    other_user_first_name: Optional[str] = None
    other_user_last_name: Optional[str] = None
    other_user_username: Optional[str] = None
    other_user_avatar_url: Optional[str] = None


class ConnectionListResponse(BaseModel):
    """
    Response model for listing connections.
    
    Fields:
    - connections: List of connections
    - total: Total count
    """
    connections: list[ConnectionResponse]
    total: int


class ConnectionRequestListResponse(BaseModel):
    """
    Response model for listing connection requests.
    
    Fields:
    - requests: List of connection requests
    - total: Total count
    """
    requests: list[ConnectionRequestResponse]
    total: int


# ===== Self Letter Models =====
class SelfLetterCreate(BaseModel):
    """
    Request model for creating a self letter.
    
    Fields:
    - content: Letter content (required, 280-500 characters)
    - scheduled_open_at: When letter can be opened (must be in future)
    - mood: Optional context at write time
    - life_area: Optional life area context
    - city: Optional city where letter was written
    """
    content: str = Field(..., min_length=280, max_length=500, description="Letter content (280-500 characters)")
    scheduled_open_at: datetime = Field(..., description="When letter can be opened (must be in future)")
    mood: Optional[str] = Field(None, description="Context at write time (e.g. 'calm', 'anxious', 'tired')")
    life_area: Optional[str] = Field(None, description="Life area context ('self', 'work', 'family', 'money', 'health')")
    city: Optional[str] = Field(None, description="City where letter was written")
    
    @field_validator('scheduled_open_at')
    @classmethod
    def validate_scheduled_open_at(cls, v: datetime) -> datetime:
        """Ensure scheduled_open_at is in the future."""
        from datetime import timezone
        now = datetime.now(timezone.utc)
        if v <= now:
            raise ValueError('scheduled_open_at must be in the future')
        return v
    
    @field_validator('life_area')
    @classmethod
    def validate_life_area(cls, v: Optional[str]) -> Optional[str]:
        """Validate life_area is one of allowed values."""
        if v is not None and v not in ('self', 'work', 'family', 'money', 'health'):
            raise ValueError('life_area must be one of: self, work, family, money, health')
        return v


class SelfLetterResponse(BaseModel):
    """
    Response model for self letter.
    
    Content is only included if letter has been opened or scheduled time has passed.
    """
    id: UUID
    user_id: UUID
    content: Optional[str] = Field(None, description="Content only visible after scheduled_open_at")
    char_count: int
    scheduled_open_at: datetime
    opened_at: Optional[datetime] = None
    mood: Optional[str] = None
    life_area: Optional[str] = None
    city: Optional[str] = None
    reflection_answer: Optional[str] = Field(None, description="'yes', 'no', or 'skipped'")
    reflected_at: Optional[datetime] = None
    sealed: bool = Field(True, description="Always TRUE - letters are sealed immediately")
    created_at: datetime
    
    class Config:
        from_attributes = True


class SelfLetterListResponse(BaseModel):
    """
    Response model for listing self letters.
    
    Returns metadata for all letters, but content only for opened letters.
    """
    letters: list[SelfLetterResponse]
    total: int


class SelfLetterReflectionRequest(BaseModel):
    """
    Request model for submitting reflection.
    
    Fields:
    - answer: Reflection answer - "yes", "no", or "skipped"
    """
    answer: str = Field(..., description="Reflection answer: 'yes', 'no', or 'skipped'")
    
    @field_validator('answer')
    @classmethod
    def validate_answer(cls, v: str) -> str:
        """Validate answer is one of allowed values."""
        if v not in ('yes', 'no', 'skipped'):
            raise ValueError('answer must be one of: yes, no, skipped')
        return v


# ===== Letter Reply Models =====
class LetterReplyCreate(BaseModel):
    """
    Request model for creating a letter reply.
    
    Fields:
    - reply_text: Reply text content (max 60 characters)
    - reply_emoji: Selected emoji from fixed set: ❤️ 🥹 😊 😎 😢 🤍 🙏
    """
    reply_text: str = Field(..., max_length=60, description="Reply text, max 60 characters")
    reply_emoji: str = Field(..., description="Selected emoji: ❤️ 🥹 😊 😎 😢 🤍 🙏")
    
    @field_validator('reply_text')
    @classmethod
    def validate_reply_text(cls, v: str) -> str:
        """Validate reply text length."""
        if len(v) > 60:
            raise ValueError('reply_text must be 60 characters or less')
        if not v.strip():
            raise ValueError('reply_text cannot be empty')
        return v.strip()
    
    @field_validator('reply_emoji')
    @classmethod
    def validate_reply_emoji(cls, v: str) -> str:
        """Validate emoji is from allowed set."""
        allowed_emojis = {'❤️', '🥹', '😊', '😎', '😢', '🤍', '🙏'}
        if v not in allowed_emojis:
            raise ValueError(f'reply_emoji must be one of: {", ".join(allowed_emojis)}')
        return v


class LetterReplyResponse(BaseModel):
    """
    Response model for letter reply.
    
    Fields:
    - id: Reply UUID
    - letter_id: Letter (capsule) UUID this reply is for
    - reply_text: Reply text content
    - reply_emoji: Selected emoji
    - receiver_animation_seen_at: When receiver saw animation (after sending)
    - sender_animation_seen_at: When sender saw animation (when viewing)
    - created_at: Creation timestamp
    """
    id: UUID
    letter_id: UUID
    reply_text: str
    reply_emoji: str
    receiver_animation_seen_at: Optional[datetime] = None
    sender_animation_seen_at: Optional[datetime] = None
    created_at: datetime
    
    @classmethod
    def from_orm_reply(cls, reply: "LetterReply") -> "LetterReplyResponse":
        """Create LetterReplyResponse from LetterReply database model."""
        return cls(
            id=reply.id,
            letter_id=reply.letter_id,
            reply_text=reply.reply_text,
            reply_emoji=reply.reply_emoji,
            receiver_animation_seen_at=reply.receiver_animation_seen_at,
            sender_animation_seen_at=reply.sender_animation_seen_at,
            created_at=reply.created_at
        )
    
    class Config:
        from_attributes = True
