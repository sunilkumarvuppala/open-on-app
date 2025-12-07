"""
SQLAlchemy database models matching Supabase schema.

This module defines all database models using SQLAlchemy ORM to match
the Supabase database schema exactly.

Models:
- UserProfile: Extends Supabase Auth users with app-specific data
- Capsule: Time-locked emotional letters
- Recipient: Saved recipient contacts
- Theme: Visual themes for letters
- Animation: Reveal animations for letter opening
- Notification: User notifications
- UserSubscription: Premium subscription tracking
- AuditLog: Action logging for security

Key Features:
- UUID primary keys for all models
- Timezone-aware timestamps (UTC)
- Proper foreign key relationships to auth.users
- Database indexes for performance
- Type hints with SQLAlchemy Mapped types
- Matches Supabase schema exactly
"""
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID
from sqlalchemy import String, Text, DateTime, Boolean, ForeignKey, Enum as SQLEnum, Index, Integer, JSON
from sqlalchemy.orm import foreign
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship as sa_relationship
from app.db.base import Base
import enum


def utcnow() -> datetime:
    """
    Get current UTC time as timezone-aware datetime.
    
    This helper function ensures all timestamps are timezone-aware.
    All database timestamps use UTC to prevent timezone manipulation.
    
    Returns:
        datetime: Current UTC time with timezone info
    """
    return datetime.now(timezone.utc)


# ============================================================================
# ENUMS (matching Supabase schema)
# ============================================================================

class CapsuleStatus(str, enum.Enum):
    """
    Capsule status enumeration matching Supabase schema.
    
    States:
    - SEALED: Capsule created, unlocks_at is in the future
    - READY: unlocks_at has passed, recipient can now open it
    - OPENED: Recipient has opened and read the letter
    - EXPIRED: Letter expired (expires_at passed) or was soft-deleted
    """
    SEALED = "sealed"
    READY = "ready"
    OPENED = "opened"
    EXPIRED = "expired"


class NotificationType(str, enum.Enum):
    """Notification type enumeration matching Supabase schema."""
    UNLOCK_SOON = "unlock_soon"
    UNLOCKED = "unlocked"
    NEW_CAPSULE = "new_capsule"
    DISAPPEARING_WARNING = "disappearing_warning"
    SUBSCRIPTION_EXPIRING = "subscription_expiring"
    SUBSCRIPTION_EXPIRED = "subscription_expired"


class SubscriptionStatus(str, enum.Enum):
    """Subscription status enumeration matching Supabase schema."""
    ACTIVE = "active"
    CANCELED = "canceled"
    PAST_DUE = "past_due"
    TRIALING = "trialing"
    INCOMPLETE = "incomplete"
    INCOMPLETE_EXPIRED = "incomplete_expired"


class RecipientRelationship(str, enum.Enum):
    """Recipient relationship enumeration matching Supabase schema."""
    FRIEND = "friend"
    FAMILY = "family"
    PARTNER = "partner"
    COLLEAGUE = "colleague"
    ACQUAINTANCE = "acquaintance"
    OTHER = "other"


# ============================================================================
# MODELS
# ============================================================================

class UserProfile(Base):
    """
    User profile model - extends Supabase Auth users.
    
    This model matches the Supabase user_profiles table.
    It extends auth.users with application-specific data.
    
    Note: Authentication is handled by Supabase Auth (auth.users table).
    This table only stores app-specific profile data.
    
    Fields:
    - user_id: UUID primary key, references auth.users(id)
    - full_name: User's display name
    - avatar_url: URL to user's profile picture
    - premium_status: Whether user has active premium subscription
    - premium_until: When premium subscription expires
    - is_admin: Admin flag for system administration
    - country: User's country for analytics/localization
    - device_token: Push notification device token
    - created_at: Profile creation timestamp (UTC)
    - updated_at: Last profile update timestamp (UTC)
    """
    __tablename__ = "user_profiles"
    
    # Primary key: UUID, references auth.users(id)
    # Note: No FK constraint because auth.users is in a different schema managed by Supabase Auth
    user_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # Profile fields
    full_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    premium_status: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    premium_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    country: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    device_token: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    # Sent capsules: Capsules this user has sent
    # Note: sender_id in Capsule references auth.users(id), same as user_id here
    # We need to specify primaryjoin with foreign() because there's no direct FK between user_profiles and capsules
    sent_capsules: Mapped[list["Capsule"]] = sa_relationship(
        "Capsule",
        primaryjoin="UserProfile.user_id == foreign(Capsule.sender_id)",
        back_populates="sender_profile"
    )
    # Recipients: Saved contacts owned by this user
    # Note: owner_id in Recipient references auth.users(id), same as user_id here
    # We need to specify primaryjoin with foreign() because there's no direct FK between user_profiles and recipients
    recipients: Mapped[list["Recipient"]] = sa_relationship(
        "Recipient",
        primaryjoin="UserProfile.user_id == foreign(Recipient.owner_id)",
        back_populates="owner_profile"
    )


class Recipient(Base):
    """
    Recipient model - saved recipient contacts matching Supabase schema.
    
    Represents a saved contact that can be used when creating capsules.
    
    Fields:
    - id: UUID primary key
    - owner_id: User who saved this recipient (references auth.users)
    - name: Recipient name (required)
    - email: Recipient email (optional)
    - avatar_url: URL to recipient's avatar image
    - relationship: Relationship type (defaults to 'friend')
    - created_at: When recipient was saved
    - updated_at: Last update timestamp
    """
    __tablename__ = "recipients"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # Ownership: references auth.users(id)
    # Note: No FK constraint because auth.users is in a different schema managed by Supabase Auth
    owner_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), nullable=False)
    
    # Contact information
    name: Mapped[str] = mapped_column(Text, nullable=False)
    email: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    relationship: Mapped[RecipientRelationship] = mapped_column(
        SQLEnum(RecipientRelationship),
        default=RecipientRelationship.FRIEND,
        nullable=False
    )
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    # Note: Using sa_relationship() to avoid conflict with 'relationship' column name
    # owner_id references auth.users(id), same as UserProfile.user_id
    # We need foreign() annotation because there's no FK constraint
    owner_profile: Mapped[Optional["UserProfile"]] = sa_relationship(
        "UserProfile",
        primaryjoin="foreign(Recipient.owner_id) == UserProfile.user_id",
        back_populates="recipients"
    )
    # Capsules sent to this recipient
    # Note: Capsule.recipient_id has FK to recipients(id)
    # We use foreign() annotation to help SQLAlchemy understand the relationship
    capsules: Mapped[list["Capsule"]] = sa_relationship(
        "Capsule",
        primaryjoin="Recipient.id == foreign(Capsule.recipient_id)",
        back_populates="recipient"
    )


class Theme(Base):
    """
    Theme model - visual themes for letters matching Supabase schema.
    
    Fields:
    - id: UUID primary key
    - name: Theme name (unique)
    - description: Theme description
    - gradient_start: Start color hex code
    - gradient_end: End color hex code
    - preview_url: URL to preview image
    - premium_only: Whether theme requires premium subscription
    - created_at: Creation timestamp
    - updated_at: Last update timestamp
    """
    __tablename__ = "themes"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # Theme fields
    name: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gradient_start: Mapped[str] = mapped_column(Text, nullable=False)
    gradient_end: Mapped[str] = mapped_column(Text, nullable=False)
    preview_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    premium_only: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    capsules: Mapped[list["Capsule"]] = sa_relationship(
        "Capsule",
        primaryjoin="Theme.id == foreign(Capsule.theme_id)",
        back_populates="theme"
    )


class Animation(Base):
    """
    Animation model - reveal animations for letter opening matching Supabase schema.
    
    Fields:
    - id: UUID primary key
    - name: Animation name (unique)
    - description: Animation description
    - preview_url: URL to preview video
    - premium_only: Whether animation requires premium subscription
    - created_at: Creation timestamp
    - updated_at: Last update timestamp
    """
    __tablename__ = "animations"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # Animation fields
    name: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    preview_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    premium_only: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    capsules: Mapped[list["Capsule"]] = sa_relationship(
        "Capsule",
        primaryjoin="Animation.id == foreign(Capsule.animation_id)",
        back_populates="animation"
    )


class Capsule(Base):
    """
    Capsule model - time-locked emotional letters matching Supabase schema.
    
    This is the main feature - letters that unlock at a specific time.
    Supports anonymous messages, disappearing messages, and time-based unlocking.
    
    Fields:
    - id: UUID primary key
    - sender_id: User who sent the capsule (references auth.users)
    - recipient_id: Recipient of the capsule (references recipients table)
    - is_anonymous: Hide sender identity from recipient
    - is_disappearing: Delete message after opening
    - disappearing_after_open_seconds: Seconds before deletion (if disappearing)
    - unlocks_at: When capsule becomes available to open
    - opened_at: When capsule was opened (NULL if not opened yet)
    - expires_at: When capsule expires (optional)
    - title: Letter title (optional)
    - body_text: Plain text content
    - body_rich_text: Rich text content as JSONB
    - theme_id: Visual theme (references themes)
    - animation_id: Reveal animation (references animations)
    - status: Current status (auto-updated by trigger)
    - deleted_at: Soft delete timestamp (for disappearing messages)
    - created_at: Creation timestamp
    - updated_at: Last update timestamp
    """
    __tablename__ = "capsules"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # Relationships: sender and recipient
    # Note: sender_id references auth.users(id) but no FK constraint (auth schema managed by Supabase)
    sender_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), nullable=False)
    recipient_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), ForeignKey("recipients(id)"), nullable=False)
    
    # Anonymous and disappearing message flags
    is_anonymous: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_disappearing: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    disappearing_after_open_seconds: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    
    # Timestamps (all timezone-aware UTC)
    unlocks_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    opened_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Content fields
    title: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    body_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    body_rich_text: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)
    
    # Theme and animation references
    theme_id: Mapped[Optional[UUID]] = mapped_column(PostgresUUID(as_uuid=True), ForeignKey("themes(id)"), nullable=True)
    animation_id: Mapped[Optional[UUID]] = mapped_column(PostgresUUID(as_uuid=True), ForeignKey("animations(id)"), nullable=True)
    
    # Status and soft delete
    status: Mapped[CapsuleStatus] = mapped_column(
        SQLEnum(CapsuleStatus),
        default=CapsuleStatus.SEALED,
        nullable=False,
        index=True
    )
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    # sender_id references auth.users(id), same as UserProfile.user_id
    # We need foreign() annotation because there's no FK constraint
    sender_profile: Mapped[Optional["UserProfile"]] = sa_relationship(
        "UserProfile",
        primaryjoin="foreign(Capsule.sender_id) == UserProfile.user_id",
        back_populates="sent_capsules"
    )
    recipient: Mapped["Recipient"] = sa_relationship(
        "Recipient",
        primaryjoin="foreign(Capsule.recipient_id) == Recipient.id",
        back_populates="capsules"
    )
    theme: Mapped[Optional["Theme"]] = sa_relationship(
        "Theme",
        primaryjoin="foreign(Capsule.theme_id) == Theme.id",
        back_populates="capsules"
    )
    animation: Mapped[Optional["Animation"]] = sa_relationship(
        "Animation",
        primaryjoin="foreign(Capsule.animation_id) == Animation.id",
        back_populates="capsules"
    )
    
    # ===== Database Indexes =====
    __table_args__ = (
        Index("idx_capsules_sender", "sender_id", "created_at"),
        Index("idx_capsules_recipient", "recipient_id", "created_at"),
        Index("idx_capsules_status_unlocks", "status", "unlocks_at"),
    )


class Notification(Base):
    """
    Notification model - user notifications matching Supabase schema.
    
    Fields:
    - id: UUID primary key
    - user_id: User who receives notification (references auth.users)
    - type: Notification type
    - capsule_id: Related capsule (if applicable)
    - title: Notification title
    - body: Notification body text
    - delivered: Whether notification was delivered
    - created_at: Creation timestamp
    """
    __tablename__ = "notifications"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # User reference
    # Note: No FK constraint because auth.users is in a different schema managed by Supabase Auth
    user_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), nullable=False)
    
    # Notification fields
    type: Mapped[NotificationType] = mapped_column(SQLEnum(NotificationType), nullable=False)
    capsule_id: Mapped[Optional[UUID]] = mapped_column(PostgresUUID(as_uuid=True), ForeignKey("capsules(id)"), nullable=True)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    delivered: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    capsule: Mapped[Optional["Capsule"]] = sa_relationship(
        "Capsule",
        primaryjoin="foreign(Notification.capsule_id) == Capsule.id"
    )


class UserSubscription(Base):
    """
    User subscription model - premium subscription tracking matching Supabase schema.
    
    Fields:
    - id: UUID primary key
    - user_id: User who has subscription (references auth.users)
    - status: Subscription status
    - provider: Payment provider (default 'stripe')
    - plan_id: Subscription plan ID
    - stripe_subscription_id: Stripe subscription ID (unique)
    - started_at: When subscription started
    - ends_at: When subscription ends
    - cancel_at_period_end: Whether subscription will cancel at period end
    - created_at: Creation timestamp
    - updated_at: Last update timestamp
    """
    __tablename__ = "user_subscriptions"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # User reference
    # Note: No FK constraint because auth.users is in a different schema managed by Supabase Auth
    user_id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), nullable=False)
    
    # Subscription fields
    status: Mapped[SubscriptionStatus] = mapped_column(SQLEnum(SubscriptionStatus), nullable=False)
    provider: Mapped[str] = mapped_column(Text, default="stripe", nullable=False)
    plan_id: Mapped[str] = mapped_column(Text, nullable=False)
    stripe_subscription_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True, unique=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    cancel_at_period_end: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)


class AuditLog(Base):
    """
    Audit log model - action logging for security matching Supabase schema.
    
    Fields:
    - id: UUID primary key
    - user_id: User who performed action (references auth.users, nullable)
    - action: Action type (INSERT, UPDATE, DELETE)
    - capsule_id: Related capsule (if applicable, nullable)
    - metadata: JSONB with table name, old row data, new row data
    - created_at: Creation timestamp
    """
    __tablename__ = "audit_logs"
    
    # Primary key: UUID
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    
    # References (nullable for audit preservation)
    # Note: No FK constraint because auth.users is in a different schema managed by Supabase Auth
    user_id: Mapped[Optional[UUID]] = mapped_column(PostgresUUID(as_uuid=True), nullable=True)
    capsule_id: Mapped[Optional[UUID]] = mapped_column(PostgresUUID(as_uuid=True), ForeignKey("capsules(id)"), nullable=True)
    
    # Audit fields
    action: Mapped[str] = mapped_column(Text, nullable=False)
    metadata_json: Mapped[Optional[dict]] = mapped_column("metadata", JSONB, nullable=True)  # Column name is 'metadata', but attribute is 'metadata_json' to avoid conflict
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
