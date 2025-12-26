"""
Self letter service layer for business logic and validation.

This service encapsulates all self letter-related business logic, validation,
and state management.

Responsibilities:
- Self letter creation validation
- Content validation (280-500 characters)
- Scheduled time validation
- Opening validation
- Reflection submission validation
"""
from typing import Optional
from datetime import datetime, timezone
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.repositories import SelfLetterRepository
from app.core.logging import get_logger
from app.utils.helpers import sanitize_text

logger = get_logger(__name__)


class SelfLetterService:
    """Service layer for self letter business logic and validation."""
    
    MIN_CONTENT_LENGTH = 20
    MAX_CONTENT_LENGTH = 500
    
    def __init__(self, session: AsyncSession):
        """Initialize self letter service with database session."""
        self.session = session
        self.self_letter_repo = SelfLetterRepository(session)
    
    def validate_content(self, content: str) -> tuple[str, int]:
        """
        Validate and sanitize letter content.
        
        Args:
            content: Raw content string
            
        Returns:
            Tuple of (sanitized_content, char_count)
            
        Raises:
            HTTPException: If content is invalid
        """
        if not content or not content.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Content cannot be empty"
            )
        
        # Sanitize content
        sanitized = sanitize_text(content.strip(), max_length=self.MAX_CONTENT_LENGTH)
        char_count = len(sanitized)
        
        # Validate length
        if char_count < self.MIN_CONTENT_LENGTH:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Content must be at least {self.MIN_CONTENT_LENGTH} characters (currently {char_count})"
            )
        
        if char_count > self.MAX_CONTENT_LENGTH:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Content must be at most {self.MAX_CONTENT_LENGTH} characters (currently {char_count})"
            )
        
        return sanitized, char_count
    
    def validate_scheduled_time(self, scheduled_open_at: datetime) -> None:
        """
        Validate scheduled open time is in the future.
        
        Args:
            scheduled_open_at: Scheduled open time
            
        Raises:
            HTTPException: If scheduled time is not in the future
        """
        now = datetime.now(timezone.utc)
        if scheduled_open_at <= now:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="scheduled_open_at must be in the future"
            )
    
    def validate_life_area(self, life_area: Optional[str]) -> None:
        """
        Validate life area is one of allowed values.
        
        Args:
            life_area: Life area value
            
        Raises:
            HTTPException: If life_area is invalid
        """
        if life_area is not None and life_area not in ('self', 'work', 'family', 'money', 'health'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="life_area must be one of: self, work, family, money, health"
            )
    
    async def validate_letter_for_opening(
        self,
        letter_id: UUID,
        user_id: UUID
    ) -> None:
        """
        Validate letter can be opened by user.
        
        Args:
            letter_id: Letter ID
            user_id: User ID
            
        Raises:
            HTTPException: If letter cannot be opened
        """
        letter = await self.self_letter_repo.get_by_id(letter_id)
        
        if not letter:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Letter not found"
            )
        
        if letter.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to open this letter"
            )
        
        now = datetime.now(timezone.utc)
        if letter.scheduled_open_at > now:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Letter cannot be opened before scheduled time"
            )
    
    async def validate_letter_for_reflection(
        self,
        letter_id: UUID,
        user_id: UUID
    ) -> None:
        """
        Validate letter can have reflection submitted.
        
        Args:
            letter_id: Letter ID
            user_id: User ID
            
        Raises:
            HTTPException: If reflection cannot be submitted
        """
        letter = await self.self_letter_repo.get_by_id(letter_id)
        
        if not letter:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Letter not found"
            )
        
        if letter.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to submit reflection for this letter"
            )
        
        if letter.opened_at is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Letter must be opened before submitting reflection"
            )
        
        if letter.reflection_answer is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reflection already submitted and cannot be changed"
            )
    
    async def open_letter(self, letter_id: UUID, user_id: UUID) -> dict:
        """
        Open a self letter using database function.
        
        Args:
            letter_id: Letter ID
            user_id: User ID
            
        Returns:
            Dictionary with letter data
            
        Raises:
            HTTPException: If letter cannot be opened
        """
        # Validate first
        await self.validate_letter_for_opening(letter_id, user_id)
        
        # Use database function to open letter atomically
        result = await self.session.execute(
            text("SELECT * FROM public.open_self_letter(:letter_id, :user_id)"),
            {"letter_id": str(letter_id), "user_id": str(user_id)}
        )
        row = result.fetchone()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to open letter"
            )
        
        # Convert row to dict
        return {
            "id": row[0],
            "content": row[1],
            "char_count": row[2],
            "scheduled_open_at": row[3],
            "opened_at": row[4],
            "mood": row[5],
            "life_area": row[6],
            "city": row[7],
            "created_at": row[8]
        }
    
    async def submit_reflection(
        self,
        letter_id: UUID,
        user_id: UUID,
        answer: str
    ) -> bool:
        """
        Submit reflection for a self letter using database function.
        
        Args:
            letter_id: Letter ID
            user_id: User ID
            answer: Reflection answer ("yes", "no", or "skipped")
            
        Returns:
            True if successful
            
        Raises:
            HTTPException: If reflection cannot be submitted
        """
        # Validate answer
        if answer not in ('yes', 'no', 'skipped'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="answer must be one of: yes, no, skipped"
            )
        
        # Validate letter
        await self.validate_letter_for_reflection(letter_id, user_id)
        
        # Use database function to submit reflection atomically
        result = await self.session.execute(
            text("SELECT public.submit_self_letter_reflection(:letter_id, :user_id, :answer)"),
            {"letter_id": str(letter_id), "user_id": str(user_id), "answer": answer}
        )
        success = result.scalar_one()
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to submit reflection"
            )
        
        return True
