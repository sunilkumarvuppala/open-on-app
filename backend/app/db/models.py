"""SQLAlchemy database models."""
from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4
from sqlalchemy import String, Text, DateTime, Boolean, ForeignKey, Enum as SQLEnum, Index, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
import enum


def utcnow() -> datetime:
    """Get current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)


class CapsuleState(str, enum.Enum):
    """Capsule state enumeration."""
    DRAFT = "draft"
    SEALED = "sealed"
    UNFOLDING = "unfolding"
    READY = "ready"
    OPENED = "opened"


class User(Base):
    """User model."""
    __tablename__ = "users"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    username: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # Relationships
    sent_capsules: Mapped[list["Capsule"]] = relationship(
        "Capsule", 
        back_populates="sender",
        foreign_keys="Capsule.sender_id"
    )
    received_capsules: Mapped[list["Capsule"]] = relationship(
        "Capsule",
        back_populates="receiver", 
        foreign_keys="Capsule.receiver_id"
    )
    drafts: Mapped[list["Draft"]] = relationship("Draft", back_populates="owner")
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
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    sealed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    scheduled_unlock_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True, index=True)
    opened_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
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
    """Draft model - unsent capsules."""
    __tablename__ = "drafts"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    media_urls: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    theme: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    recipient_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        onupdate=utcnow,
        nullable=False
    )
    
    # Relationships
    owner: Mapped["User"] = relationship("User", back_populates="drafts")
    
    __table_args__ = (
        Index("idx_owner_updated", "owner_id", "updated_at"),
    )


class Recipient(Base):
    """Recipient model - saved recipient contacts."""
    __tablename__ = "recipients"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    user_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    
    # Relationships
    owner: Mapped["User"] = relationship(
        "User",
        back_populates="recipients",
        foreign_keys=[owner_id]
    )
    
    __table_args__ = (
        Index("idx_owner_created", "owner_id", "created_at"),
    )
