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
from fastapi import APIRouter, HTTPException, status, Query
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
from app.utils.helpers import sanitize_text
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
    capsule_repo = CapsuleRepository(session)
    recipient_repo = RecipientRepository(session)
    
    # ===== Recipient Validation =====
    # Verify recipient exists and belongs to current user
    recipient = await recipient_repo.get_by_id(capsule_data.recipient_id)
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    if recipient.owner_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only create capsules for your own recipients"
        )
    
    # ===== Content Validation =====
    # Must have either body_text OR body_rich_text
    if not capsule_data.body_text and not capsule_data.body_rich_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either body_text or body_rich_text is required"
        )
    
    # ===== Input Sanitization =====
    title = sanitize_text(capsule_data.title.strip(), max_length=settings.max_title_length) if capsule_data.title else None
    body_text = sanitize_text(capsule_data.body_text.strip(), max_length=settings.max_content_length) if capsule_data.body_text else None
    
    # ===== Unlock Time Validation =====
    # Ensure unlocks_at is timezone-aware and in the future
    unlocks_at = capsule_data.unlocks_at
    if unlocks_at.tzinfo is None:
        unlocks_at = unlocks_at.replace(tzinfo=timezone.utc)
    else:
        unlocks_at = unlocks_at.astimezone(timezone.utc)
    
    now = datetime.now(timezone.utc)
    if unlocks_at <= now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unlock time must be in the future"
        )
    
    # ===== Disappearing Message Validation =====
    if capsule_data.is_disappearing and not capsule_data.disappearing_after_open_seconds:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="disappearing_after_open_seconds is required when is_disappearing is true"
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
    
    return CapsuleResponse.model_validate(capsule)


@router.get("", response_model=CapsuleListResponse)
async def list_capsules(
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
    skip = (page - 1) * page_size
    
    logger.info(
        f"Listing capsules: user_id={current_user.user_id}, box={box}, status={status_filter}, "
        f"page={page}, page_size={page_size}"
    )
    
    # ===== Query Based on Box Type =====
    # "inbox" = capsules where current user owns the recipient
    # "outbox" = capsules sent by current user
    if box == "inbox":
        # Get all recipients owned by current user
        recipients = await recipient_repo.get_by_owner(
            current_user.user_id,
            skip=0,
            limit=settings.max_page_size * 50  # Reasonable limit for inbox query
        )
        recipient_ids = [r.id for r in recipients]
        
        if not recipient_ids:
            # No recipients, so no inbox capsules
            return CapsuleListResponse(
                capsules=[],
                total=0,
                page=page,
                page_size=page_size
            )
        
        # Get capsules for these recipients using a single query with IN clause
        # This avoids N+1 query problem
        capsules = await capsule_repo.get_by_recipient_ids(
            recipient_ids=recipient_ids,
            status=status_filter,
            skip=skip,
            limit=page_size
        )
        total = await capsule_repo.count_by_recipient_ids(
            recipient_ids=recipient_ids,
            status=status_filter
        )
        
        logger.info(
            f"Inbox query result: found {len(capsules)} capsules for user_id={current_user.user_id}, "
            f"total={total}"
        )
    else:  # outbox
        # Get capsules where current user is the sender
        capsules = await capsule_repo.get_by_sender(
            current_user.user_id,
            status=status_filter,
            skip=skip,
            limit=page_size
        )
        total = await capsule_repo.count_by_sender(current_user.user_id, status=status_filter)
        logger.info(
            f"Outbox query result: found {len(capsules)} capsules for sender_id={current_user.user_id}, "
            f"total={total}"
        )
    
    return CapsuleListResponse(
        capsules=[CapsuleResponse.model_validate(c) for c in capsules],
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{capsule_id}", response_model=CapsuleResponse)
async def get_capsule(
    capsule_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Get details of a specific capsule.
    
    Users can view capsules they sent or received.
    For anonymous capsules, sender info is hidden from recipient.
    """
    capsule_repo = CapsuleRepository(session)
    recipient_repo = RecipientRepository(session)
    
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # ===== Existence Check =====
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # ===== Permission Check =====
    # Check if user has permission to view this capsule
    # Rules:
    # - Sender can always view
    # - Recipient owner can view if capsule is ready or opened
    is_sender = capsule.sender_id == current_user.user_id
    recipient = await recipient_repo.get_by_id(capsule.recipient_id)
    is_recipient_owner = recipient and recipient.owner_id == current_user.user_id
    
    if not is_sender and not is_recipient_owner:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view this capsule"
        )
    
    # Recipients can only view if status is ready or opened
    if is_recipient_owner and not is_sender:
        if capsule.status not in [CapsuleStatus.READY, CapsuleStatus.OPENED]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Capsule is not ready yet (current status: {capsule.status.value})"
            )
    
    return CapsuleResponse.model_validate(capsule)


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
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # ===== Existence Check =====
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # ===== Permission Check =====
    # Only sender can edit
    if capsule.sender_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the sender can edit this capsule"
        )
    
    # ===== Status Check =====
    # Cannot edit if already opened
    if capsule.status == CapsuleStatus.OPENED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot edit capsule that has been opened"
        )
    
    # ===== Prepare Update Data =====
    update_dict = update_data.model_dump(exclude_unset=True)
    
    # ===== Sanitize Text Fields =====
    if "title" in update_dict and update_dict["title"]:
        update_dict["title"] = sanitize_text(update_dict["title"].strip(), max_length=settings.max_title_length)
    if "body_text" in update_dict and update_dict["body_text"]:
        update_dict["body_text"] = sanitize_text(update_dict["body_text"].strip(), max_length=settings.max_content_length)
    
    # ===== Content Validation =====
    # If updating body, must have either body_text OR body_rich_text
    if "body_text" in update_dict or "body_rich_text" in update_dict:
        new_body_text = update_dict.get("body_text") or capsule.body_text
        new_body_rich_text = update_dict.get("body_rich_text") or capsule.body_rich_text
        if not new_body_text and not new_body_rich_text:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either body_text or body_rich_text is required"
            )
    
    # ===== Disappearing Message Validation =====
    new_is_disappearing = update_dict.get("is_disappearing", capsule.is_disappearing)
    new_disappearing_seconds = update_dict.get("disappearing_after_open_seconds") or capsule.disappearing_after_open_seconds
    if new_is_disappearing and not new_disappearing_seconds:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="disappearing_after_open_seconds is required when is_disappearing is true"
        )
    
    # Update capsule
    updated_capsule = await capsule_repo.update(capsule_id, **update_dict)
    
    logger.info(f"Capsule {capsule_id} updated by user {current_user.user_id}")
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.post("/{capsule_id}/open", response_model=CapsuleResponse)
async def open_capsule(
    capsule_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Open a capsule (transition from 'ready' to 'opened').
    
    Only the recipient owner can open a capsule, and only when it's in 'ready' status.
    This action is irreversible and triggers disappearing message deletion if applicable.
    """
    capsule_repo = CapsuleRepository(session)
    recipient_repo = RecipientRepository(session)
    
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # ===== Existence Check =====
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # ===== Permission Check =====
    # Check if user can open this capsule
    can_open, message = await capsule_repo.can_open(capsule_id, current_user.user_id)
    if not can_open:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
    
    # ===== Status Check =====
    # Must be in READY status
    if capsule.status != CapsuleStatus.READY:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Capsule is not ready yet (current status: {capsule.status.value})"
        )
    
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
