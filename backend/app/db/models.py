"""
SQLAlchemy database models.

This module defines all database models using SQLAlchemy ORM.
All models inherit from Base and use timezone-aware datetimes.

Models:
- User: User accounts with authentication
- Capsule: Time-locked emotional letters
- Draft: Unsent capsules that can be edited
- Recipient: Saved recipient contacts

Key Features:
- UUID primary keys for all models
- Timezone-aware timestamps (UTC)
- Proper foreign key relationships
- Database indexes for performance
- Type hints with SQLAlchemy Mapped types
"""
from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4
from sqlalchemy import String, Text, DateTime, Boolean, ForeignKey, Enum as SQLEnum, Index, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
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


class CapsuleState(str, enum.Enum):
    """
    Capsule state enumeration.
    
    Defines the possible states a capsule can be in.
    States follow a strict lifecycle and cannot be reversed.
    
    States:
    - DRAFT: Capsule is being created, can be edited
    - SEALED: Unlock time is set, no edits allowed
    - UNFOLDING: Less than 3 days until unlock (teaser state)
    - READY: Unlock time has arrived, can be opened
    - OPENED: Receiver has opened the capsule (terminal state)
    """
    DRAFT = "draft"
    SEALED = "sealed"
    UNFOLDING = "unfolding"
    READY = "ready"
    OPENED = "opened"


class User(Base):
    """
    User model - represents user accounts.
    
    Stores user authentication and profile information.
    All passwords are hashed using BCrypt before storage.
    
    Fields:
    - id: UUID primary key
    - email: Unique email address (indexed for fast lookups)
    - username: Unique username (indexed for fast lookups)
    - hashed_password: BCrypt hashed password (never store plain text)
    - full_name: User's full name (optional)
    - is_active: Account status (inactive accounts cannot authenticate)
    - created_at: Account creation timestamp (UTC)
    
    Relationships:
    - sent_capsules: Capsules sent by this user
    - received_capsules: Capsules received by this user
    - drafts: Drafts owned by this user
    - recipients: Recipients saved by this user
    """
    __tablename__ = "users"
    
    # Primary key: UUID string (36 characters)
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    
    # Authentication fields
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    username: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)  # BCrypt hash
    
    # Profile fields
    full_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    # Sent capsules: Capsules this user has sent
    sent_capsules: Mapped[list["Capsule"]] = relationship(
        "Capsule", 
        back_populates="sender",
        foreign_keys="Capsule.sender_id"
    )
    # Received capsules: Capsules this user has received
    received_capsules: Mapped[list["Capsule"]] = relationship(
        "Capsule",
        back_populates="receiver", 
        foreign_keys="Capsule.receiver_id"
    )
    # Drafts: Unsent capsules owned by this user
    drafts: Mapped[list["Draft"]] = relationship("Draft", back_populates="owner")
    # Recipients: Saved contacts owned by this user
    recipients: Mapped[list["Recipient"]] = relationship(
        "Recipient",
        back_populates="owner",
        foreign_keys="Recipient.owner_id"
    )


class Capsule(Base):
    """Capsule model - time-locked emotional letters."""
    __tablename__ = "capsules"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    sender_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    receiver_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    media_urls: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON string
    theme: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    
    # State management
    state: Mapped[CapsuleState] = mapped_column(
        SQLEnum(CapsuleState),
        default=CapsuleState.DRAFT,
        nullable=False,
        index=True
    )
    
    # Timestamps (all timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    sealed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    scheduled_unlock_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    opened_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Permissions
    allow_early_view: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    allow_receiver_reply: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    
    # Relationships
    sender: Mapped["User"] = relationship(
        "User",
        back_populates="sent_capsules",
        foreign_keys=[sender_id]
    )
    receiver: Mapped["User"] = relationship(
        "User",
        back_populates="received_capsules",
        foreign_keys=[receiver_id]
    )
    
    # Indexes for performance
    __table_args__ = (
        Index("idx_sender_state", "sender_id", "state"),
        Index("idx_receiver_state", "receiver_id", "state"),
        Index("idx_state_unlock", "state", "scheduled_unlock_at"),
    )


class Draft(Base):
    """
    Draft model - unsent capsules.
    
    Drafts are capsules that haven't been sent yet.
    They can be freely edited and deleted until converted to capsules.
    
    Fields:
    - id: UUID primary key
    - owner_id: User who owns this draft
    - title: Draft title
    - body: Draft content
    - media_urls: JSON string of media URLs
    - theme: Optional theme name
    - recipient_id: Optional recipient ID (can be set later)
    - created_at: When draft was created
    - updated_at: When draft was last updated (auto-updated on changes)
    
    Note:
    - Drafts are separate from capsules to allow editing before sending
    - When ready, drafts are converted to capsules (which cannot be edited)
    """
    __tablename__ = "drafts"
    
    # Primary key: UUID string
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    
    # Ownership
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    
    # Content fields (same structure as Capsule for easy conversion)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    media_urls: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON string
    theme: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    recipient_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)  # Optional recipient
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        onupdate=utcnow,  # Auto-update on every save
        nullable=False
    )
    
    # ===== Relationships =====
    owner: Mapped["User"] = relationship("User", back_populates="drafts")
    
    # ===== Database Indexes =====
    # Index for fast queries of user's drafts (ordered by most recently updated)
    __table_args__ = (
        Index("idx_owner_updated", "owner_id", "updated_at"),
    )


class Recipient(Base):
    """
    Recipient model - saved recipient contacts.
    
    Represents a saved contact that can be used when creating capsules.
    Recipients can be linked to registered users or just stored as contacts.
    
    Fields:
    - id: UUID primary key
    - owner_id: User who saved this recipient
    - name: Recipient name
    - email: Recipient email (optional, validated if provided)
    - user_id: Optional link to registered user account
    - created_at: When recipient was saved
    
    Use Cases:
    - Linked recipient (user_id set): Recipient is a registered user
    - Unlinked recipient (user_id null): Recipient is just a contact
    
    Note:
    - user_id links recipient to a User account
    - When creating capsules, linked recipients use user_id as receiver_id
    - Unlinked recipients cannot receive capsules (must be registered users)
    """
    __tablename__ = "recipients"
    
    # Primary key: UUID string
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    
    # Ownership
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    
    # Contact information
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)  # Optional email
    # Link to registered user (optional - allows linking contacts to accounts)
    user_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    
    # Timestamps (timezone-aware UTC)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # ===== Relationships =====
    owner: Mapped["User"] = relationship(
        "User",
        back_populates="recipients",
        foreign_keys=[owner_id]
    )
    
    # ===== Database Indexes =====
    # Index for fast queries of user's recipients (ordered by most recently added)
    __table_args__ = (
        Index("idx_owner_created", "owner_id", "created_at"),
    )
