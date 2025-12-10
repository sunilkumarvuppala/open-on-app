"""
Specific repositories for each model matching Supabase schema.

This module implements repository pattern for database operations.
Each repository provides type-safe, optimized database queries for its model.

Repositories:
- UserProfileRepository: User profile operations (extends Supabase Auth)
- CapsuleRepository: Capsule operations (by sender/recipient, status transitions)
- RecipientRepository: Recipient operations (CRUD for saved contacts)
- ThemeRepository: Theme operations
- AnimationRepository: Animation operations
- NotificationRepository: Notification operations
- UserSubscriptionRepository: Subscription operations
- AuditLogRepository: Audit log operations

Benefits:
- Separation of concerns (business logic vs. data access)
- Reusable query methods
- Type safety with SQLAlchemy
- Optimized queries with proper indexing
"""
from typing import Optional
from datetime import datetime, timezone
from uuid import UUID
from sqlalchemy import select, and_, or_, case, func, delete, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import (
    UserProfile, Capsule, Recipient, Theme, Animation, Notification,
    UserSubscription, AuditLog, CapsuleStatus, NotificationType,
    SubscriptionStatus, RecipientRelationship
)
from app.db.repository import BaseRepository


class UserProfileRepository(BaseRepository[UserProfile]):
    """
    Repository for user profile operations.
    
    Note: Authentication is handled by Supabase Auth (auth.users table).
    This repository only manages the user_profiles table which extends
    Supabase Auth users with app-specific data.
    """
    
    def __init__(self, session: AsyncSession):
        super().__init__(UserProfile, session)
    
    async def get_by_id(self, id: UUID) -> Optional[UserProfile]:
        """Get user profile by user_id (UUID)."""
        result = await self.session.execute(
            select(UserProfile).where(UserProfile.user_id == id)
        )
        return result.scalar_one_or_none()
    
    async def create(
        self,
        user_id: UUID,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        username: Optional[str] = None,
        avatar_url: Optional[str] = None,
        premium_status: bool = False,
        premium_until: Optional[datetime] = None,
        is_admin: bool = False,
        country: Optional[str] = None,
        device_token: Optional[str] = None
    ) -> UserProfile:
        """Create a new user profile."""
        instance = UserProfile(
            user_id=user_id,
            first_name=first_name,
            last_name=last_name,
            username=username,
            avatar_url=avatar_url,
            premium_status=premium_status,
            premium_until=premium_until,
            is_admin=is_admin,
            country=country,
            device_token=device_token
        )
        self.session.add(instance)
        await self.session.flush()
        await self.session.refresh(instance)
        return instance
    
    async def update_last_login(self, user_id: UUID) -> Optional[UserProfile]:
        """Update the last_login timestamp for a user."""
        profile = await self.get_by_id(user_id)
        if profile:
            profile.last_login = datetime.now(timezone.utc)
            await self.session.flush()
            await self.session.refresh(profile)
        return profile


class CapsuleRepository(BaseRepository[Capsule]):
    """Repository for capsule operations matching Supabase schema."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Capsule, session)
    
    async def get_by_id(self, id: UUID) -> Optional[Capsule]:
        """Get capsule by ID (UUID)."""
        result = await self.session.execute(
            select(Capsule).where(Capsule.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_sender(
        self,
        sender_id: UUID,
        status: Optional[CapsuleStatus] = None,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[Capsule]:
        """
        Get capsules by sender with optional status filter.
        
        Args:
            sender_id: UUID of the user who sent the capsules
            status: Optional status filter (e.g., only SEALED, only READY)
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
        
        Returns:
            List of capsules sent by the specified user, ordered by creation date (newest first)
        """
        from app.core.config import settings
        
        query = select(Capsule).where(
            and_(
                Capsule.sender_id == sender_id,
                Capsule.deleted_at.is_(None)  # Exclude soft-deleted
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def get_by_recipient(
        self,
        recipient_id: UUID,
        status: Optional[CapsuleStatus] = None,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[Capsule]:
        """
        Get capsules by recipient with optional status filter.
        
        Args:
            recipient_id: UUID of the recipient
            status: Optional status filter
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
        
        Returns:
            List of capsules for the specified recipient
        """
        from app.core.config import settings
        
        query = select(Capsule).where(
            and_(
                Capsule.recipient_id == recipient_id,
                Capsule.deleted_at.is_(None)  # Exclude soft-deleted
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def count_by_sender(
        self,
        sender_id: UUID,
        status: Optional[CapsuleStatus] = None
    ) -> int:
        """Count capsules by sender."""
        query = select(func.count()).select_from(Capsule).where(
            and_(
                Capsule.sender_id == sender_id,
                Capsule.deleted_at.is_(None)
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def get_by_recipient_email(
        self,
        recipient_email: str,
        status: Optional[CapsuleStatus] = None,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[Capsule]:
        """
        Get capsules by recipient email with optional status filter.
        
        This is used for inbox queries - finds capsules sent to recipients
        whose email matches the current user's email.
        
        Args:
            recipient_email: Email address of the recipient
            status: Optional status filter
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
        
        Returns:
            List of capsules for recipients with matching email
        """
        from app.core.config import settings
        from sqlalchemy import select, and_, or_
        from app.db.models import Recipient
        
        # Query capsules where recipient email matches (case-insensitive, handle NULL)
        # Use LOWER() for case-insensitive comparison and ensure email is not NULL
        from sqlalchemy import func
        query = (
            select(Capsule)
            .join(Recipient, Capsule.recipient_id == Recipient.id)
            .where(
                and_(
                    Recipient.email.isnot(None),  # Exclude recipients without email
                    func.lower(Recipient.email) == func.lower(recipient_email),  # Case-insensitive match
                    Capsule.deleted_at.is_(None)  # Exclude soft-deleted
                )
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def count_by_recipient_email(
        self,
        recipient_email: str,
        status: Optional[CapsuleStatus] = None
    ) -> int:
        """Count capsules by recipient email."""
        from sqlalchemy import select, func, and_
        from app.db.models import Recipient
        
        # Use LOWER() for case-insensitive comparison and ensure email is not NULL
        query = (
            select(func.count())
            .select_from(Capsule)
            .join(Recipient, Capsule.recipient_id == Recipient.id)
            .where(
                and_(
                    Recipient.email.isnot(None),  # Exclude recipients without email
                    func.lower(Recipient.email) == func.lower(recipient_email),  # Case-insensitive match
                    Capsule.deleted_at.is_(None)  # Exclude soft-deleted
                )
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        result = await self.session.execute(query)
        return result.scalar() or 0
    
    async def get_by_recipient_ids(
        self,
        recipient_ids: list[UUID],
        status: Optional[CapsuleStatus] = None,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[Capsule]:
        """
        Get capsules by multiple recipient IDs (optimized for inbox query).
        
        Uses IN clause to avoid N+1 query problem.
        """
        from app.core.config import settings
        
        if not recipient_ids:
            return []
        
        query = select(Capsule).where(
            and_(
                Capsule.recipient_id.in_(recipient_ids),
                Capsule.deleted_at.is_(None)
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def count_by_recipient_ids(
        self,
        recipient_ids: list[UUID],
        status: Optional[CapsuleStatus] = None
    ) -> int:
        """Count capsules by multiple recipient IDs."""
        if not recipient_ids:
            return 0
        
        query = select(func.count()).select_from(Capsule).where(
            and_(
                Capsule.recipient_id.in_(recipient_ids),
                Capsule.deleted_at.is_(None)
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def count_by_recipient(
        self,
        recipient_id: UUID,
        status: Optional[CapsuleStatus] = None
    ) -> int:
        """Count capsules by recipient."""
        query = select(func.count()).select_from(Capsule).where(
            and_(
                Capsule.recipient_id == recipient_id,
                Capsule.deleted_at.is_(None)
            )
        )
        
        if status:
            query = query.where(Capsule.status == status)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def get_capsules_for_unlock(self) -> list[Capsule]:
        """
        Get all capsules that need status updates.
        
        Returns capsules that are SEALED and have unlocks_at in the past,
        which should transition to READY status.
        """
        now = datetime.now(timezone.utc)
        
        query = select(Capsule).where(
            and_(
                Capsule.status == CapsuleStatus.SEALED,
                Capsule.unlocks_at <= now,
                Capsule.deleted_at.is_(None)
            )
        )
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def transition_status(
        self,
        capsule_id: UUID,
        new_status: CapsuleStatus,
        **extra_fields: datetime
    ) -> Optional[Capsule]:
        """Transition capsule to a new status with timestamp updates."""
        updates = {"status": new_status}
        updates.update(extra_fields)
        return await self.update(capsule_id, **updates)
    
    async def update(self, id: UUID, **kwargs) -> Optional[Capsule]:
        """Update capsule by ID (UUID)."""
        stmt = (
            update(Capsule)
            .where(Capsule.id == id)
            .values(**kwargs)
            .returning(Capsule)
        )
        result = await self.session.execute(stmt)
        await self.session.flush()
        return result.scalar_one_or_none()
    
    async def verify_ownership(self, capsule_id: UUID, user_id: UUID) -> bool:
        """Verify if user is the sender of a capsule."""
        capsule = await self.get_by_id(capsule_id)
        return capsule is not None and capsule.sender_id == user_id
    
class RecipientRepository(BaseRepository[Recipient]):
    """Repository for recipient operations matching Supabase schema."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Recipient, session)
    
    async def get_by_id(self, id: UUID) -> Optional[Recipient]:
        """Get recipient by ID (UUID)."""
        result = await self.session.execute(
            select(Recipient).where(Recipient.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_owner(
        self,
        owner_id: UUID,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[Recipient]:
        """Get all recipients by owner."""
        from app.core.config import settings
        
        query = (
            select(Recipient)
            .where(Recipient.owner_id == owner_id)
            .order_by(Recipient.created_at.desc())
            .offset(skip)
        )
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def update(self, id: UUID, **kwargs) -> Optional[Recipient]:
        """Update recipient by ID (UUID)."""
        stmt = (
            update(Recipient)
            .where(Recipient.id == id)
            .values(**kwargs)
            .returning(Recipient)
        )
        result = await self.session.execute(stmt)
        await self.session.flush()
        return result.scalar_one_or_none()
    
    async def delete(self, id: UUID) -> bool:
        """Delete recipient by ID (UUID)."""
        stmt = delete(Recipient).where(Recipient.id == id)
        result = await self.session.execute(stmt)
        await self.session.flush()
        return result.rowcount > 0
    
    async def verify_ownership(self, recipient_id: UUID, user_id: UUID) -> bool:
        """Verify if user owns a recipient."""
        recipient = await self.get_by_id(recipient_id)
        return recipient is not None and recipient.owner_id == user_id


class ThemeRepository(BaseRepository[Theme]):
    """Repository for theme operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Theme, session)
    
    async def get_by_id(self, id: UUID) -> Optional[Theme]:
        """Get theme by ID (UUID)."""
        result = await self.session.execute(
            select(Theme).where(Theme.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_all_free(self) -> list[Theme]:
        """Get all free (non-premium) themes."""
        result = await self.session.execute(
            select(Theme).where(Theme.premium_only == False)
        )
        return list(result.scalars().all())
    
    async def get_all_premium(self) -> list[Theme]:
        """Get all premium themes."""
        result = await self.session.execute(
            select(Theme).where(Theme.premium_only == True)
        )
        return list(result.scalars().all())


class AnimationRepository(BaseRepository[Animation]):
    """Repository for animation operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Animation, session)
    
    async def get_by_id(self, id: UUID) -> Optional[Animation]:
        """Get animation by ID (UUID)."""
        result = await self.session.execute(
            select(Animation).where(Animation.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_all_free(self) -> list[Animation]:
        """Get all free (non-premium) animations."""
        result = await self.session.execute(
            select(Animation).where(Animation.premium_only == False)
        )
        return list(result.scalars().all())
    
    async def get_all_premium(self) -> list[Animation]:
        """Get all premium animations."""
        result = await self.session.execute(
            select(Animation).where(Animation.premium_only == True)
        )
        return list(result.scalars().all())


class NotificationRepository(BaseRepository[Notification]):
    """Repository for notification operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Notification, session)
    
    async def get_by_id(self, id: UUID) -> Optional[Notification]:
        """Get notification by ID (UUID)."""
        result = await self.session.execute(
            select(Notification).where(Notification.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_user(
        self,
        user_id: UUID,
        skip: int = 0,
        limit: Optional[int] = None,
        delivered: Optional[bool] = None
    ) -> list[Notification]:
        """Get notifications for a user."""
        from app.core.config import settings
        
        query = select(Notification).where(Notification.user_id == user_id)
        
        if delivered is not None:
            query = query.where(Notification.delivered == delivered)
        
        query = query.order_by(Notification.created_at.desc()).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())


class UserSubscriptionRepository(BaseRepository[UserSubscription]):
    """Repository for subscription operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(UserSubscription, session)
    
    async def get_by_id(self, id: UUID) -> Optional[UserSubscription]:
        """Get subscription by ID (UUID)."""
        result = await self.session.execute(
            select(UserSubscription).where(UserSubscription.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_user(self, user_id: UUID) -> Optional[UserSubscription]:
        """Get active subscription for a user."""
        result = await self.session.execute(
            select(UserSubscription)
            .where(
                and_(
                    UserSubscription.user_id == user_id,
                    UserSubscription.status == SubscriptionStatus.ACTIVE
                )
            )
            .order_by(UserSubscription.created_at.desc())
        )
        return result.scalar_one_or_none()


class AuditLogRepository(BaseRepository[AuditLog]):
    """Repository for audit log operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(AuditLog, session)
    
    async def get_by_id(self, id: UUID) -> Optional[AuditLog]:
        """Get audit log by ID (UUID)."""
        result = await self.session.execute(
            select(AuditLog).where(AuditLog.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_user(
        self,
        user_id: UUID,
        skip: int = 0,
        limit: Optional[int] = None
    ) -> list[AuditLog]:
        """Get audit logs for a user."""
        from app.core.config import settings
        
        query = (
            select(AuditLog)
            .where(AuditLog.user_id == user_id)
            .order_by(AuditLog.created_at.desc())
            .offset(skip)
        )
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
