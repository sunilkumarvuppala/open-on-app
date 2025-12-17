"""
Connection service layer for business logic.

This service encapsulates connection-related business logic to reduce
duplication and improve maintainability.
"""
from typing import Optional, Any
from uuid import UUID
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, DatabaseError
from fastapi import HTTPException, status
from app.core.logging import get_logger
from app.core.constants import (
    MAX_DAILY_CONNECTION_REQUESTS,
    CONNECTION_COOLDOWN_DAYS
)

logger = get_logger(__name__)


class ConnectionService:
    """Service for connection-related business logic."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        # Recipients are now connections - no separate repository needed
    
    async def check_existing_connection(
        self,
        user_id_1: UUID,
        user_id_2: UUID
    ) -> bool:
        """
        Check if two users are already connected.
        
        Returns:
            True if connection exists, False otherwise
        """
        user1 = min(user_id_1, user_id_2)
        user2 = max(user_id_1, user_id_2)
        
        result = await self.session.execute(
            text("""
                SELECT 1 FROM public.connections
                WHERE user_id_1 = :user1 AND user_id_2 = :user2
            """),
            {"user1": user1, "user2": user2}
        )
        return result.scalar() is not None
    
    async def check_pending_request(
        self,
        from_user_id: UUID,
        to_user_id: UUID
    ) -> bool:
        """
        Check if a pending request already exists between two users.
        
        Returns:
            True if pending request exists, False otherwise
        """
        result = await self.session.execute(
            text("""
                SELECT id FROM public.connection_requests
                WHERE (
                    (from_user_id = :from_id AND to_user_id = :to_id)
                    OR (from_user_id = :to_id AND to_user_id = :from_id)
                )
                AND status = 'pending'
            """),
            {
                "from_id": from_user_id,
                "to_id": to_user_id
            }
        )
        return result.scalar() is not None
    
    async def check_cooldown(
        self,
        from_user_id: UUID,
        to_user_id: UUID
    ) -> bool:
        """
        Check if user is in cooldown period after a declined request.
        
        Returns:
            True if in cooldown, False otherwise
        """
        # Use parameterized query with make_interval for security
        # CONNECTION_COOLDOWN_DAYS is a constant, but we still use parameterized query for best practices
        result = await self.session.execute(
            text("""
                SELECT 1 FROM public.connection_requests
                WHERE from_user_id = :from_id
                  AND to_user_id = :to_id
                  AND status = 'declined'
                  AND acted_at > NOW() - make_interval(days => :cooldown_days)
            """),
            {
                "from_id": from_user_id,
                "to_id": to_user_id,
                "cooldown_days": CONNECTION_COOLDOWN_DAYS
            }
        )
        return result.scalar() is not None
    
    async def check_rate_limit(
        self,
        user_id: UUID
    ) -> tuple[bool, int]:
        """
        Check if user has exceeded daily connection request rate limit.
        
        Returns:
            Tuple of (exceeded, current_count)
        """
        result = await self.session.execute(
            text("""
                SELECT COUNT(*) FROM public.connection_requests
                WHERE from_user_id = :user_id
                  AND created_at > NOW() - INTERVAL '1 day'
            """),
            {"user_id": user_id}
        )
        count = result.scalar() or 0
        return count >= MAX_DAILY_CONNECTION_REQUESTS, count
    
    async def create_connection(
        self,
        user_id_1: UUID,
        user_id_2: UUID
    ) -> None:
        """
        Create a mutual connection between two users.
        
        Also auto-creates recipient entries for both users.
        """
        user1 = min(user_id_1, user_id_2)
        user2 = max(user_id_1, user_id_2)
        
        try:
            await self.session.execute(
                text("""
                    INSERT INTO public.connections (user_id_1, user_id_2, connected_at)
                    VALUES (:user1, :user2, NOW())
                    ON CONFLICT DO NOTHING
                """),
                {"user1": user1, "user2": user2}
            )
            
            # Auto-create recipient entries for both users
            await self._create_recipient_entries(user_id_1, user_id_2)
            
        except IntegrityError as e:
            await self.session.rollback()
            logger.error(f"Failed to create connection: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create connection"
            )
        except DatabaseError as e:
            await self.session.rollback()
            logger.error(f"Database error creating connection: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Database error occurred"
            )
    
    async def _create_recipient_entries(
        self,
        from_user_id: UUID,
        to_user_id: UUID
    ) -> None:
        """
        Create recipient entries for both users when connection is established.
        
        This ensures recipient records exist in the database so capsules can be created.
        Recipients are created with linked_user_id set to the connection user ID.
        """
        from app.db.repositories import RecipientRepository, UserProfileRepository
        
        recipient_repo = RecipientRepository(self.session)
        user_profile_repo = UserProfileRepository(self.session)
        
        # Get user profiles for display names
        user1_profile = await user_profile_repo.get_by_id(from_user_id)
        user2_profile = await user_profile_repo.get_by_id(to_user_id)
        
        # Build display names
        def get_display_name(profile: Optional[Any]) -> str:
            if profile:
                name_parts = [p for p in [profile.first_name, profile.last_name] if p]
                if name_parts:
                    return " ".join(name_parts)
                if profile.username:
                    return profile.username
            return f"User {str(from_user_id)[:8]}"
        
        user1_display_name = get_display_name(user1_profile) if user1_profile else f"User {str(from_user_id)[:8]}"
        user2_display_name = get_display_name(user2_profile) if user2_profile else f"User {str(to_user_id)[:8]}"
        
        # Create recipient for user1 -> user2 (if doesn't exist)
        # CRITICAL: Check again after potential concurrent creation
        existing_recipient_1 = await recipient_repo.get_by_owner_and_linked_user(
            owner_id=from_user_id,
            linked_user_id=to_user_id
        )
        if not existing_recipient_1:
            try:
                await recipient_repo.create(
                    owner_id=from_user_id,
                    name=user2_display_name,
                    email=None,  # Connection-based recipients have no email
                    avatar_url=user2_profile.avatar_url if user2_profile else None,
                    username=user2_profile.username if user2_profile else None,
                    linked_user_id=to_user_id,
                )
                logger.info(f"Created recipient for user {from_user_id} -> {to_user_id}")
            except IntegrityError as e:
                # Unique constraint violation - recipient was created by concurrent request
                # This is expected and safe to ignore
                logger.info(
                    f"Recipient already exists for {from_user_id} -> {to_user_id} "
                    f"(created by concurrent request): {e}"
                )
        
        # Create recipient for user2 -> user1 (if doesn't exist)
        # CRITICAL: Check again after potential concurrent creation
        existing_recipient_2 = await recipient_repo.get_by_owner_and_linked_user(
            owner_id=to_user_id,
            linked_user_id=from_user_id
        )
        if not existing_recipient_2:
            try:
                await recipient_repo.create(
                    owner_id=to_user_id,
                    name=user1_display_name,
                    email=None,  # Connection-based recipients have no email
                    avatar_url=user1_profile.avatar_url if user1_profile else None,
                    username=user1_profile.username if user1_profile else None,
                    linked_user_id=from_user_id,
                )
                logger.info(f"Created recipient for user {to_user_id} -> {from_user_id}")
            except IntegrityError as e:
                # Unique constraint violation - recipient was created by concurrent request
                # This is expected and safe to ignore
                logger.info(
                    f"Recipient already exists for {to_user_id} -> {from_user_id} "
                    f"(created by concurrent request): {e}"
                )
