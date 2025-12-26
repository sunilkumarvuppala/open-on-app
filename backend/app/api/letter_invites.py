"""
Letter Invites API routes.

This module handles all letter invite-related endpoints:
- Creating invites for letters (sender only)
- Getting invite preview (public, no auth required)
- Claiming invites (when user signs up)

Business Rules:
- Only senders can create invites for their letters
- One active invite per letter (returns existing if one exists)
- Invites can be viewed by anyone (public preview)
- Invites can only be claimed once (first user wins)
- When claimed, recipient is linked to the claiming user

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- Token is non-guessable (32+ characters)
- No sender identity exposed in preview
"""
from uuid import UUID
from fastapi import APIRouter, HTTPException, status
from app.models.schemas import (
    LetterInviteCreateResponse,
    LetterInvitePreviewResponse,
    LetterInviteClaimResponse,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import LetterInviteRepository, CapsuleRepository, RecipientRepository
from app.core.logging import get_logger
from app.core.permissions import verify_capsule_sender
from sqlalchemy import text

# Router for all letter invite endpoints
router = APIRouter(prefix="/letter-invites", tags=["Letter Invites"])
logger = get_logger(__name__)


@router.post("/letters/{letter_id}", response_model=LetterInviteCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_invite(
    letter_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> LetterInviteCreateResponse:
    """
    Create a letter invite for sending to an unregistered user.
    
    Only the sender can create an invite for their letter.
    If an active invite already exists, returns the existing one.
    """
    # Verify sender ownership
    await verify_capsule_sender(session, letter_id, current_user.user_id)
    
    # Get capsule to verify it exists and is not deleted
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(letter_id)
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Letter not found"
        )
    
    # Check if letter is deleted
    if capsule.deleted_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot create invite for deleted letter"
        )
    
    # Check if invite already exists
    invite_repo = LetterInviteRepository(session)
    existing_invite = await invite_repo.get_by_letter_id(letter_id)
    
    if existing_invite:
        # Return existing invite
        from app.core.config import settings
        base_url = settings.invite_base_url
        if not base_url:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invite base URL not configured"
            )
        invite_url = f"{base_url}/{existing_invite.invite_token}"
        
        return LetterInviteCreateResponse(
            invite_id=existing_invite.id,
            invite_token=existing_invite.invite_token,
            invite_url=invite_url,
            already_exists=True
        )
    
    # Create invite using RPC function (handles token generation)
    try:
        result = await session.execute(
            text("SELECT * FROM public.rpc_create_letter_invite(CAST(:letter_id AS UUID))"),
            {"letter_id": str(letter_id)}
        )
        row = result.first()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create invite"
            )
        
        result_data = row[0]  # JSONB result
        
        return LetterInviteCreateResponse(
            invite_id=UUID(result_data['invite_id']),
            invite_token=result_data['invite_token'],
            invite_url=result_data['invite_url'],
            already_exists=result_data.get('already_exists', False)
        )
    except Exception as e:
        error_str = str(e).lower()
        if 'letter_invite_error' in error_str:
            if 'not_authorized' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You are not authorized to create an invite for this letter"
                )
            elif 'letter_not_found' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Letter not found"
                )
            elif 'letter_deleted' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot create invite for deleted letter"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to create invite: {str(e)}"
                )
        else:
            logger.error(f"Unexpected error creating invite: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create invite"
            )


@router.get("/preview/{invite_token}", response_model=LetterInvitePreviewResponse)
async def get_invite_preview(
    invite_token: str,
    session: DatabaseSession
) -> LetterInvitePreviewResponse:
    """
    Get public preview of a letter invite (no auth required).
    
    Returns only safe public data - no sender identity or private information.
    Can be accessed by anyone with the invite token.
    """
    # Validate token format (security: prevent injection attacks)
    # Tokens should be base64url-encoded, 32+ characters, alphanumeric + - _
    if not invite_token or len(invite_token) < 32:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite token format"
        )
    # Allow only safe characters (base64url: A-Z, a-z, 0-9, -, _)
    import re
    if not re.match(r'^[A-Za-z0-9_-]+$', invite_token):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite token format"
        )
    
    try:
        result = await session.execute(
            text("SELECT * FROM public.rpc_get_letter_invite_public(:invite_token)"),
            {"invite_token": invite_token}
        )
        row = result.first()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invite not found"
            )
        
        result_data = row[0]  # JSONB result
        
        return LetterInvitePreviewResponse(
            invite_id=UUID(result_data['invite_id']),
            letter_id=UUID(result_data['letter_id']),
            unlocks_at=result_data['unlocks_at'],
            is_unlocked=result_data['is_unlocked'],
            days_remaining=result_data['days_remaining'],
            hours_remaining=result_data['hours_remaining'],
            minutes_remaining=result_data['minutes_remaining'],
            seconds_remaining=result_data['seconds_remaining'],
            title=result_data.get('title'),
            theme=result_data.get('theme')
        )
    except Exception as e:
        error_str = str(e).lower()
        if 'letter_invite_error' in error_str:
            if 'invite_not_found' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invite not found"
                )
            elif 'invite_already_claimed' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This letter has already been opened"
                )
            elif 'letter_deleted' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Letter not found"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to get invite preview: {str(e)}"
                )
        else:
            logger.error(f"Unexpected error getting invite preview: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get invite preview"
            )


@router.post("/claim/{invite_token}", response_model=LetterInviteClaimResponse)
async def claim_invite(
    invite_token: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> LetterInviteClaimResponse:
    """
    Claim a letter invite when user signs up.
    
    Only authenticated users can claim invites.
    Each invite can only be claimed once (first user wins).
    When claimed, the recipient is linked to the claiming user.
    """
    # Validate token format (security: prevent injection attacks)
    if not invite_token or len(invite_token) < 32:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite token format"
        )
    # Allow only safe characters (base64url: A-Z, a-z, 0-9, -, _)
    import re
    if not re.match(r'^[A-Za-z0-9_-]+$', invite_token):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite token format"
        )
    
    try:
        result = await session.execute(
            text("SELECT * FROM public.rpc_claim_letter_invite(:invite_token)"),
            {"invite_token": invite_token}
        )
        row = result.first()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to claim invite"
            )
        
        result_data = row[0]  # JSONB result
        
        await session.commit()
        
        return LetterInviteClaimResponse(
            success=result_data['success'],
            letter_id=UUID(result_data['letter_id']),
            message=result_data['message']
        )
    except Exception as e:
        await session.rollback()
        error_str = str(e).lower()
        if 'letter_invite_error' in error_str:
            if 'not_authenticated' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            elif 'invite_not_found' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invite not found"
                )
            elif 'invite_already_claimed' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This letter has already been opened"
                )
            elif 'letter_deleted' in error_str:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Letter not found"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to claim invite: {str(e)}"
                )
        else:
            logger.error(f"Unexpected error claiming invite: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to claim invite"
            )

