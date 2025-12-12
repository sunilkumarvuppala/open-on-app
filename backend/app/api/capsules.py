"""
Capsules API routes matching Supabase schema.

This module handles all capsule-related endpoints:
- Creating capsules (in sealed status with unlocks_at)
- Listing capsules (inbox/outbox with pagination)
- Viewing capsule details
- Updating capsules (before opening)
- Opening capsules (recipient only)
- Deleting capsules (soft delete for disappearing messages)

Business Rules:
- Capsules are created in 'sealed' status with unlocks_at set
- Once unlocks_at passes, status becomes 'ready'
- Only recipients can open capsules (when status is 'ready')
- Anonymous capsules hide sender identity from recipient
- Disappearing messages are soft-deleted after opening

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- Status-based permissions are enforced
- Anonymous sender info is hidden from recipient
"""
from typing import Optional
from datetime import datetime, timezone
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Query, Request
from app.models.schemas import (
    CapsuleCreate,
    CapsuleUpdate,
    CapsuleResponse,
    CapsuleListResponse,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import CapsuleRepository, RecipientRepository
from app.db.models import CapsuleStatus
from app.core.logging import get_logger
from app.core.permissions import verify_capsule_access, verify_capsule_sender, verify_capsule_recipient
from app.core.pagination import calculate_pagination
from app.services.capsule_service import CapsuleService
from app.core.config import settings


# Router for all capsule endpoints
router = APIRouter(prefix="/capsules", tags=["Capsules"])
logger = get_logger(__name__)


@router.post("", response_model=CapsuleResponse, status_code=status.HTTP_201_CREATED)
async def create_capsule(
    capsule_data: CapsuleCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Create a new capsule (in sealed status).
    
    The capsule will be in 'sealed' status until unlocks_at time passes.
    Once unlocks_at passes, status automatically becomes 'ready'.
    """
    capsule_service = CapsuleService(session)
    capsule_repo = CapsuleRepository(session)
    
    # Validate recipient and permissions
    await capsule_service.validate_recipient_for_capsule(
        capsule_data.recipient_id,
        current_user.user_id
    )
    
    # Validate content
    capsule_service.validate_content(
        capsule_data.body_text,
        capsule_data.body_rich_text
    )
    
    # Sanitize inputs
    title, body_text = capsule_service.sanitize_content(
        capsule_data.title,
        capsule_data.body_text
    )
    
    # Validate and normalize unlock time
    unlocks_at = capsule_service.validate_unlock_time(capsule_data.unlocks_at)
    
    # Validate disappearing message configuration
    capsule_service.validate_disappearing_message(
        capsule_data.is_disappearing,
        capsule_data.disappearing_after_open_seconds
    )
    
    logger.info(
        f"Creating capsule: sender_id={current_user.user_id}, recipient_id={capsule_data.recipient_id}, "
        f"unlocks_at={unlocks_at}, is_anonymous={capsule_data.is_anonymous}"
    )
    
    # Create capsule in sealed status
    capsule = await capsule_repo.create(
        sender_id=current_user.user_id,
        recipient_id=capsule_data.recipient_id,
        title=title,
        body_text=body_text,
        body_rich_text=capsule_data.body_rich_text,
        is_anonymous=capsule_data.is_anonymous,
        is_disappearing=capsule_data.is_disappearing,
        disappearing_after_open_seconds=capsule_data.disappearing_after_open_seconds,
        unlocks_at=unlocks_at,
        expires_at=capsule_data.expires_at,
        theme_id=capsule_data.theme_id,
        animation_id=capsule_data.animation_id,
        status=CapsuleStatus.SEALED
    )
    
    logger.info(
        f"Capsule {capsule.id} created by user {current_user.user_id} "
        f"for recipient {capsule.recipient_id}"
    )
    
    return CapsuleResponse.from_orm_with_profile(capsule)


@router.get("", response_model=CapsuleListResponse)
async def list_capsules(
    request: Request,  # Added to access user_email from request state
    current_user: CurrentUser,
    session: DatabaseSession,
    box: str = Query("inbox", regex="^(inbox|outbox)$"),
    status_filter: Optional[CapsuleStatus] = Query(None, alias="status"),
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(settings.default_page_size, ge=settings.min_page_size, le=settings.max_page_size)
) -> CapsuleListResponse:
    """
    List capsules for the current user.
    
    - **box**: 'inbox' for received capsules, 'outbox' for sent capsules
    - **status**: Optional filter by capsule status (sealed, ready, opened, expired)
    - **page**: Page number (1-indexed)
    - **page_size**: Number of items per page (1-100)
    
    Note:
        Inbox shows capsules where current user owns the recipient.
        Outbox shows capsules sent by current user.
    """
    capsule_repo = CapsuleRepository(session)
    recipient_repo = RecipientRepository(session)
    
    # ===== Pagination Calculation =====
    skip, limit = calculate_pagination(page, page_size)
    
    logger.info(
        f"Listing capsules: user_id={current_user.user_id}, box={box}, status={status_filter}, "
        f"page={page}, page_size={page_size}"
    )
    
    # ===== Query Based on Box Type =====
    # "inbox" = capsules where recipient email matches current user's email
    #           OR capsules for connection-based recipients (email=NULL)
    # "outbox" = capsules sent by current user
    if box == "inbox":
        # Get current user's email from request state (set by get_current_user)
        user_email = getattr(request.state, 'user_email', None)
        
        # Get user profile for display name (needed for connection-based matching)
        from app.db.repositories import UserProfileRepository
        user_profile_repo = UserProfileRepository(session)
        user_profile = await user_profile_repo.get_by_id(current_user.user_id)
        
        # Build user display name
        user_display_name = None
        if user_profile:
            user_display_name = " ".join(filter(None, [user_profile.first_name, user_profile.last_name])).strip()
            if not user_display_name:
                user_display_name = user_profile.username or f"User {str(current_user.user_id)[:8]}"
        
        # Use optimized unified query that handles both email-based and connection-based recipients
        # This applies pagination at the database level for better performance
        user_email_normalized = user_email.lower().strip() if user_email else None
        capsules, total = await capsule_repo.get_inbox_capsules(
            user_id=current_user.user_id,
            user_email=user_email_normalized,
            user_display_name=user_display_name,
            status=status_filter,
            skip=skip,
            limit=limit
        )
        
        logger.info(
            f"Inbox query result: found {len(capsules)} capsules (after pagination) "
            f"out of {total} total for user_id={current_user.user_id}"
        )
    else:  # outbox
        # Get capsules where current user is the sender
        capsules = await capsule_repo.get_by_sender(
            current_user.user_id,
            status=status_filter,
            skip=skip,
            limit=limit
        )
        total = await capsule_repo.count_by_sender(current_user.user_id, status=status_filter)
        logger.info(
            f"Outbox query result: found {len(capsules)} capsules for sender_id={current_user.user_id}, "
            f"total={total}"
        )
    
    return CapsuleListResponse(
        capsules=[CapsuleResponse.from_orm_with_profile(c) for c in capsules],
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{capsule_id}", response_model=CapsuleResponse)
async def get_capsule(
    capsule_id: UUID,
    request: Request,  # Added to access user_email from request state
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Get details of a specific capsule.
    
    Users can view capsules they sent or received.
    For anonymous capsules, sender info is hidden from recipient.
    """
    capsule_repo = CapsuleRepository(session)
    user_email = getattr(request.state, 'user_email', None)
    
    # Verify access (raises 404 or 403 if not authorized)
    is_sender, is_recipient = await verify_capsule_access(
        session,
        capsule_id,
        current_user.user_id,
        user_email
    )
    
    # Get capsule (already verified to exist by verify_capsule_access)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # Recipients can only view if status is ready or opened
    if is_recipient and not is_sender:
        if capsule.status not in [CapsuleStatus.READY, CapsuleStatus.OPENED]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Capsule is not ready yet (current status: {capsule.status.value})"
            )
    
    return CapsuleResponse.from_orm_with_profile(capsule)


@router.put("/{capsule_id}", response_model=CapsuleResponse)
async def update_capsule(
    capsule_id: UUID,
    update_data: CapsuleUpdate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Update a capsule (only before opening).
    
    Only the sender can edit, and only before the capsule is opened.
    """
    capsule_service = CapsuleService(session)
    capsule_repo = CapsuleRepository(session)
    
    # Validate capsule can be updated
    await capsule_service.validate_capsule_for_update(
        capsule_id,
        current_user.user_id
    )
    
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # Prepare update data
    update_dict = update_data.model_dump(exclude_unset=True)
    
    # Sanitize text fields
    if "title" in update_dict and update_dict["title"]:
        title, _ = capsule_service.sanitize_content(update_dict["title"], None)
        update_dict["title"] = title
    if "body_text" in update_dict and update_dict["body_text"]:
        _, body_text = capsule_service.sanitize_content(None, update_dict["body_text"])
        update_dict["body_text"] = body_text
    
    # Validate content if updating body
    if "body_text" in update_dict or "body_rich_text" in update_dict:
        new_body_text = update_dict.get("body_text") or capsule.body_text
        new_body_rich_text = update_dict.get("body_rich_text") or capsule.body_rich_text
        capsule_service.validate_content(new_body_text, new_body_rich_text)
    
    # Validate disappearing message configuration
    new_is_disappearing = update_dict.get("is_disappearing", capsule.is_disappearing)
    new_disappearing_seconds = update_dict.get("disappearing_after_open_seconds") or capsule.disappearing_after_open_seconds
    capsule_service.validate_disappearing_message(new_is_disappearing, new_disappearing_seconds)
    
    # Update capsule
    updated_capsule = await capsule_repo.update(capsule_id, **update_dict)
    
    logger.info(f"Capsule {capsule_id} updated by user {current_user.user_id}")
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.post("/{capsule_id}/open", response_model=CapsuleResponse)
async def open_capsule(
    capsule_id: UUID,
    request: Request,  # Added to access user_email from request state
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Open a capsule (transition from 'ready' to 'opened').
    
    Only the recipient can open a capsule, and only when it's in 'ready' status.
    This action is irreversible and triggers disappearing message deletion if applicable.
    """
    user_email = getattr(request.state, 'user_email', None)
    if not user_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User email not found. Cannot verify recipient permission."
        )
    
    # Verify recipient access (raises 404 or 403 if not authorized)
    await verify_capsule_recipient(
        session,
        capsule_id,
        current_user.user_id,
        user_email
    )
    
    capsule_service = CapsuleService(session)
    capsule_repo = CapsuleRepository(session)
    
    # Validate capsule can be opened
    await capsule_service.validate_capsule_for_opening(capsule_id)
    
    # ===== State Transition =====
    # Transition capsule to OPENED status
    # Record the exact UTC timestamp when capsule was opened
    # The trigger in Supabase will handle:
    # - Setting status to 'opened'
    # - Creating notification for sender
    # - Setting deleted_at for disappearing messages
    updated_capsule = await capsule_repo.transition_status(
        capsule_id,
        CapsuleStatus.OPENED,
        opened_at=datetime.now(timezone.utc)
    )
    
    logger.info(f"Capsule {capsule_id} opened by user {current_user.user_id}")
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.delete("/{capsule_id}", response_model=MessageResponse)
async def delete_capsule(
    capsule_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Soft delete a capsule (for disappearing messages or sender deletion).
    
    Only the sender can delete their own capsules.
    For disappearing messages, deletion is automatic after opening.
    """
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # ===== Existence Check =====
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # ===== Ownership Check =====
    # Only the sender can delete their own capsules
    if capsule.sender_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the sender can delete this capsule"
        )
    
    # ===== Soft Delete =====
    # Set deleted_at timestamp (soft delete)
    # The capsule will be filtered out by repository queries (deleted_at IS NULL)
    await capsule_repo.update(capsule_id, deleted_at=datetime.now(timezone.utc))
    
    logger.info(f"Capsule {capsule_id} soft-deleted by user {current_user.user_id}")
    
    return MessageResponse(message="Capsule deleted successfully")
