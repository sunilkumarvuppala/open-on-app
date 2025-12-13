"""
Connection service layer for business logic.

This service encapsulates connection-related business logic to reduce
duplication and improve maintainability.
"""
from typing import Optional
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
        No-op: Recipients are now connections.
        
        Previously created recipient entries when connections were established.
        Now recipients = connections, so no separate recipient entries are needed.
        The recipients API endpoint returns connections directly.
        """
        # Recipients are now just connections - no need to create separate entries
        # The list_recipients endpoint queries connections directly
        pass
