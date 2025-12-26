"""
Letter Replies API routes.

This module handles all letter reply-related endpoints:
- Creating replies (one-time, receiver only)
- Getting replies (for sender and receiver)
- Marking animation as seen (separate for receiver and sender)

Business Rules:
- Only receivers can create replies
- One reply per letter (enforced server-side)
- Replies cannot be edited or deleted
- Animation tracking is separate for receiver and sender

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- One reply per letter enforced at database level
"""
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Request
from app.models.schemas import (
    LetterReplyCreate,
    LetterReplyResponse,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import LetterReplyRepository, CapsuleRepository
from app.core.logging import get_logger
from app.core.permissions import verify_capsule_access, verify_capsule_recipient

# Router for all letter reply endpoints
router = APIRouter(prefix="/letter-replies", tags=["Letter Replies"])
logger = get_logger(__name__)


@router.post("/letters/{letter_id}", response_model=LetterReplyResponse, status_code=status.HTTP_201_CREATED)
async def create_reply(
    letter_id: UUID,
    reply_data: LetterReplyCreate,
    request: Request,
    current_user: CurrentUser,
    session: DatabaseSession
) -> LetterReplyResponse:
    """
    Create a reply to a letter (one-time only, receiver only).
    
    Only the recipient can create a reply, and only once per letter.
    The letter must be opened before a reply can be created.
    """
    user_email = getattr(request.state, 'user_email', None)
    if not user_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User email not found. Cannot verify recipient permission."
        )
    
    # Verify recipient access
    await verify_capsule_recipient(
        session,
        letter_id,
        current_user.user_id,
        user_email
    )
    
    # Get capsule to verify it's opened
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(letter_id)
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Letter not found"
        )
    
    if not capsule.opened_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Letter must be opened before replying"
        )
    
    # Check if reply already exists
    reply_repo = LetterReplyRepository(session)
    existing_reply = await reply_repo.get_by_letter_id(letter_id)
    if existing_reply:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reply already exists for this letter"
        )
    
    # Create reply using repository (will enforce constraints at database level)
    try:
        reply = await reply_repo.create(
            letter_id=letter_id,
            reply_text=reply_data.reply_text,
            reply_emoji=reply_data.reply_emoji
        )
        
        await session.commit()
        await session.refresh(reply)
        
        logger.info(f"Reply created for letter {letter_id} by user {current_user.user_id}")
        
        return LetterReplyResponse.from_orm_reply(reply)
    except Exception as e:
        error_message = str(e).lower()
        await session.rollback()
        
        if "already exists" in error_message or "unique" in error_message or "duplicate" in error_message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reply already exists for this letter"
            )
        elif "not opened" in error_message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Letter must be opened before replying"
            )
        elif "only the recipient" in error_message:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the recipient can reply to this letter"
            )
        elif "invalid emoji" in error_message or "emoji" in error_message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid emoji. Must be one of: ❤️ 🥹 😊 😎 😢 🤍 🙏"
            )
        else:
            logger.error(f"Error creating reply: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create reply: {str(e)}"
            )


@router.get("/letters/{letter_id}")
async def get_reply(
    letter_id: UUID,
    request: Request,
    current_user: CurrentUser,
    session: DatabaseSession
) -> LetterReplyResponse | None:
    """
    Get reply for a letter (sender or receiver can view).
    
    Returns 204 No Content if reply doesn't exist yet (expected case).
    Returns 200 with reply data if reply exists.
    """
    user_email = getattr(request.state, 'user_email', None)
    
    # Verify access (sender or recipient)
    await verify_capsule_access(
        session,
        letter_id,
        current_user.user_id,
        user_email
    )
    
    reply_repo = LetterReplyRepository(session)
    reply = await reply_repo.get_by_letter_id(letter_id)
    
    if not reply:
        # Return 204 No Content instead of 404 - this is expected when no reply exists yet
        # This prevents 404 warnings in logs for normal operation
        from fastapi.responses import Response
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    
    return LetterReplyResponse.from_orm_reply(reply)


@router.post("/letters/{letter_id}/mark-receiver-animation-seen", response_model=MessageResponse)
async def mark_receiver_animation_seen(
    letter_id: UUID,
    request: Request,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Mark receiver animation as seen (after sending reply).
    
    Only the recipient can mark the receiver animation as seen.
    """
    user_email = getattr(request.state, 'user_email', None)
    if not user_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User email not found. Cannot verify recipient permission."
        )
    
    # Verify recipient access
    await verify_capsule_recipient(
        session,
        letter_id,
        current_user.user_id,
        user_email
    )
    
    # Mark animation as seen using repository
    try:
        reply_repo = LetterReplyRepository(session)
        success = await reply_repo.mark_receiver_animation_seen(letter_id)
        
        if success:
            await session.commit()
            logger.info(f"Receiver animation marked as seen for letter {letter_id} by user {current_user.user_id}")
            return MessageResponse(message="Animation marked as seen")
        else:
            # Reply doesn't exist or already marked
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reply not found for this letter"
            )
    except HTTPException:
        raise
    except Exception as e:
        await session.rollback()
        logger.error(f"Error marking receiver animation as seen: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to mark animation as seen: {str(e)}"
        )


@router.post("/letters/{letter_id}/mark-sender-animation-seen", response_model=MessageResponse)
async def mark_sender_animation_seen(
    letter_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Mark sender animation as seen (when viewing reply).
    
    Only the sender can mark the sender animation as seen.
    """
    # Verify sender access
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(letter_id)
    
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Letter not found"
        )
    
    if capsule.sender_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the sender can mark sender animation as seen"
        )
    
    # Mark animation as seen using repository
    try:
        reply_repo = LetterReplyRepository(session)
        success = await reply_repo.mark_sender_animation_seen(letter_id)
        
        if success:
            await session.commit()
            logger.info(f"Sender animation marked as seen for letter {letter_id} by user {current_user.user_id}")
            return MessageResponse(message="Animation marked as seen")
        else:
            # Reply doesn't exist or already marked
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reply not found for this letter"
            )
    except HTTPException:
        raise
    except Exception as e:
        await session.rollback()
        logger.error(f"Error marking sender animation as seen: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to mark animation as seen: {str(e)}"
        )

