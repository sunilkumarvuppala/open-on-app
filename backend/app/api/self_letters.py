"""
Self Letters API routes.

This module handles all self letter-related endpoints:
- Creating self letters (sealed immediately, irreversible)
- Listing self letters (with time-locked content visibility)
- Opening self letters (only after scheduled time)
- Submitting reflection (one-time, after opening)

Business Rules:
- Self letters are sealed immediately upon creation
- Cannot be edited or deleted after creation
- Content only visible after scheduled_open_at
- Reflection can only be submitted once after opening

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- Time-based access control enforced
- Immutability enforced at database level
"""
from datetime import datetime, timezone
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import (
    SelfLetterCreate,
    SelfLetterResponse,
    SelfLetterListResponse,
    SelfLetterReflectionRequest,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import SelfLetterRepository
from app.core.logging import get_logger
from app.core.pagination import calculate_pagination
from app.core.config import settings
from app.services.self_letter_service import SelfLetterService

# Router for all self letter endpoints
router = APIRouter(prefix="/self-letters", tags=["Self Letters"])
logger = get_logger(__name__)


@router.post("", response_model=SelfLetterResponse, status_code=status.HTTP_201_CREATED)
async def create_self_letter(
    letter_data: SelfLetterCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> SelfLetterResponse:
    """
    Create a new self letter (sealed immediately, irreversible).
    
    Once created, the letter cannot be edited or deleted.
    Content will only be visible after scheduled_open_at.
    """
    logger.info(
        f"Creating self letter: user_id={current_user.user_id}, "
        f"scheduled_open_at={letter_data.scheduled_open_at}"
    )
    
    self_letter_service = SelfLetterService(session)
    self_letter_repo = SelfLetterRepository(session)
    
    # Validate content
    sanitized_content, char_count = self_letter_service.validate_content(letter_data.content)
    
    # Validate scheduled time
    self_letter_service.validate_scheduled_time(letter_data.scheduled_open_at)
    
    # Validate life area
    self_letter_service.validate_life_area(letter_data.life_area)
    
    # Create letter (sealed immediately)
    letter = await self_letter_repo.create(
        user_id=current_user.user_id,
        content=sanitized_content,
        char_count=char_count,
        scheduled_open_at=letter_data.scheduled_open_at,
        title=letter_data.title,
        mood=letter_data.mood,
        life_area=letter_data.life_area,
        city=letter_data.city
    )
    
    await session.commit()
    await session.refresh(letter)
    
    logger.info(f"Self letter created: id={letter.id}, user_id={current_user.user_id}")
    
    # Return response (content only if scheduled time has passed)
    now = datetime.now(timezone.utc)
    return SelfLetterResponse(
        id=letter.id,
        user_id=letter.user_id,
        title=letter.title,
        content=letter.content if now >= letter.scheduled_open_at else None,
        char_count=letter.char_count,
        scheduled_open_at=letter.scheduled_open_at,
        opened_at=letter.opened_at,
        mood=letter.mood,
        life_area=letter.life_area,
        city=letter.city,
        reflection_answer=letter.reflection_answer,
        reflected_at=letter.reflected_at,
        sealed=letter.sealed,
        created_at=letter.created_at
    )


@router.get("", response_model=SelfLetterListResponse)
async def list_self_letters(
    current_user: CurrentUser,
    session: DatabaseSession,
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(
        settings.default_page_size,
        ge=settings.min_page_size,
        le=settings.max_page_size,
        description="Maximum number of records to return"
    )
) -> SelfLetterListResponse:
    """
    List all self letters for the current user.
    
    Returns:
    - Sealed letters (not yet openable): metadata only, no content
    - Openable letters (scheduled time passed, not opened): metadata only, no content
    - Opened letters: full content visible
    
    Content is only included if letter has been opened or scheduled time has passed.
    """
    logger.info(f"Listing self letters: user_id={current_user.user_id}, skip={skip}, limit={limit}")
    
    self_letter_repo = SelfLetterRepository(session)
    now = datetime.now(timezone.utc)
    
    # Get letters for user with pagination
    letters = await self_letter_repo.get_by_user(
        user_id=current_user.user_id,
        skip=skip,
        limit=limit
    )
    
    # Get total count using optimized COUNT query (not len() which is incorrect for pagination)
    total = await self_letter_repo.count_by_user(user_id=current_user.user_id)
    
    # Convert to response models (hide content if not yet openable)
    letter_responses = []
    for letter in letters:
        # Content only visible if opened or scheduled time has passed
        content = None
        if letter.opened_at is not None or now >= letter.scheduled_open_at:
            content = letter.content
        
        letter_responses.append(SelfLetterResponse(
            id=letter.id,
            user_id=letter.user_id,
            title=letter.title,
            content=content,
            char_count=letter.char_count,
            scheduled_open_at=letter.scheduled_open_at,
            opened_at=letter.opened_at,
            mood=letter.mood,
            life_area=letter.life_area,
            city=letter.city,
            reflection_answer=letter.reflection_answer,
            reflected_at=letter.reflected_at,
            sealed=letter.sealed,
            created_at=letter.created_at
        ))
    
    logger.info(
        f"Returning {len(letter_responses)} self letters (total: {total}) "
        f"for user {current_user.user_id}"
    )
    
    return SelfLetterListResponse(
        letters=letter_responses,
        total=total
    )


@router.post("/{letter_id}/open", response_model=SelfLetterResponse)
async def open_self_letter(
    letter_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> SelfLetterResponse:
    """
    Open a self letter (only allowed after scheduled time).
    
    Sets opened_at timestamp and returns full letter content.
    This triggers the reflection prompt in the frontend.
    """
    logger.info(
        f"Opening self letter: letter_id={letter_id}, user_id={current_user.user_id}"
    )
    
    self_letter_service = SelfLetterService(session)
    
    # Open letter using service (validates and uses database function)
    letter_data = await self_letter_service.open_letter(letter_id, current_user.user_id)
    
    await session.commit()
    
    logger.info(f"Self letter opened: letter_id={letter_id}, user_id={current_user.user_id}")
    
    # Reload letter to get all fields (including reflection_answer, reflected_at, etc.)
    # RLS policies ensure only the owner can access their letter
    # The database function already validated ownership, so this is safe
    self_letter_repo = SelfLetterRepository(session)
    letter = await self_letter_repo.get_by_id(letter_id)
    
    if not letter:
        # This should not happen since function validated ownership
        # But provides safety in case of race condition
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Letter not found"
        )
    
    # Extra safety: Verify ownership (RLS should already enforce this, but explicit check is safer)
    if letter.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this letter"
        )
    
    return SelfLetterResponse(
        id=letter.id,
        user_id=letter.user_id,
        title=letter.title,
        content=letter.content,
        char_count=letter.char_count,
        scheduled_open_at=letter.scheduled_open_at,
        opened_at=letter.opened_at,
        mood=letter.mood,
        life_area=letter.life_area,
        city=letter.city,
        reflection_answer=letter.reflection_answer,
        reflected_at=letter.reflected_at,
        sealed=letter.sealed,
        created_at=letter.created_at
    )


@router.post("/{letter_id}/reflection", response_model=MessageResponse)
async def submit_reflection(
    letter_id: UUID,
    reflection_data: SelfLetterReflectionRequest,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Submit reflection for an opened self letter.
    
    One-time submission - cannot be changed after submission.
    Only allowed after letter has been opened.
    """
    logger.info(
        f"Submitting reflection: letter_id={letter_id}, "
        f"user_id={current_user.user_id}, answer={reflection_data.answer}"
    )
    
    self_letter_service = SelfLetterService(session)
    
    # Submit reflection using service (validates and uses database function)
    await self_letter_service.submit_reflection(
        letter_id,
        current_user.user_id,
        reflection_data.answer
    )
    
    await session.commit()
    
    logger.info(
        f"Reflection submitted: letter_id={letter_id}, "
        f"user_id={current_user.user_id}, answer={reflection_data.answer}"
    )
    
    return MessageResponse(message="Reflection submitted successfully")
