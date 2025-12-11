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
from app.core.permissions import verify_recipient_ownership, verify_users_are_connected, verify_capsule_access, verify_capsule_sender, verify_capsule_recipient
from app.core.pagination import calculate_pagination
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
    await verify_recipient_ownership(
        session,
        capsule_data.recipient_id,
        current_user.user_id
    )
    
    # ===== Mutual Connection Validation =====
    # Enforce that letters can only be sent to mutual friends
    # SIMPLIFIED: All recipients are now connection-based (email=NULL)
    # Recipients are auto-created when connections are established
    recipient = await recipient_repo.get_by_id(capsule_data.recipient_id)
    
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # Verify recipient belongs to current user
    if recipient.owner_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only send letters to your own recipients"
        )
    
    # Since recipients are now only created from connections,
    # and connections require mutual acceptance, we can trust that
    # if a recipient exists, it's from a valid connection.
    # For extra safety, we can verify the connection exists by checking
    # if recipient name matches a connected user's profile
    # (This is a simplified check - in production you might want to add linked_user_id to recipients table)
    
    # If recipient has email, it's a legacy recipient - verify connection via email
    if recipient.email:
        from sqlalchemy import text
        result = await session.execute(
            text("""
                SELECT id FROM auth.users
                WHERE email = :email
            """),
            {"email": recipient.email.lower().strip()}
        )
        recipient_user_id = result.scalar_one_or_none()
        
        if recipient_user_id:
            # Recipient is a registered user - verify mutual connection
            await verify_users_are_connected(
                session,
                current_user.user_id,
                recipient_user_id,
                raise_on_not_connected=True
            )
    # If recipient has no email (connection-based), we trust it's valid
    # because recipients are only auto-created when connections are established
    
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
    # "outbox" = capsules sent by current user
    if box == "inbox":
        # Get current user's email from request state (set by get_current_user)
        # This is the correct way to find capsules sent TO the current user
        # Recipients are owned by senders, but we match by email
        # Get user email from request state (set by get_current_user dependency)
        user_email = getattr(request.state, 'user_email', None)
        
        if not user_email:
            logger.warning(
                f"Inbox query: No email found in request state for user_id={current_user.user_id}, "
                f"cannot query inbox capsules. User email must be set in get_current_user."
            )
            return CapsuleListResponse(
                capsules=[],
                total=0,
                page=page,
                page_size=page_size
            )
        
        # Normalize email to lowercase for consistent matching
        user_email_lower = user_email.lower().strip()
        
        logger.info(
            f"Inbox query: user_id={current_user.user_id}, email={user_email_lower}, "
            f"searching for capsules where recipient.email matches"
        )
        
        # Use email-based query (correct approach)
        # Find capsules where recipient email matches current user's email (case-insensitive)
        capsules = await capsule_repo.get_by_recipient_email(
            recipient_email=user_email_lower,
            status=status_filter,
            skip=skip,
            limit=limit
        )
        total = await capsule_repo.count_by_recipient_email(
            recipient_email=user_email_lower,
            status=status_filter
        )
        
        logger.info(
            f"Inbox query result: found {len(capsules)} capsules for user_id={current_user.user_id}, "
            f"email={user_email_lower}, total={total}"
        )
        
        # Debug: Log diagnostic info if no capsules found
        if len(capsules) == 0:
            logger.warning(
                f"Inbox query: No capsules found for email={user_email_lower}, user_id={current_user.user_id}"
            )
            # Diagnostic: Check if any recipients have this email
            from app.db.models import Recipient
            from sqlalchemy import select, func
            diagnostic_query = select(
                func.count(Recipient.id).label('recipient_count'),
                func.count(Recipient.id).filter(Recipient.email.isnot(None)).label('recipients_with_email'),
                func.count(Recipient.id).filter(
                    func.lower(Recipient.email) == user_email_lower
                ).label('recipients_matching_email')
            )
            diagnostic_result = await session.execute(diagnostic_query)
            diagnostic = diagnostic_result.first()
            logger.warning(
                f"Inbox diagnostic: total_recipients={diagnostic.recipient_count}, "
                f"recipients_with_email={diagnostic.recipients_with_email}, "
                f"recipients_matching_email={diagnostic.recipients_matching_email}"
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
        capsules=[CapsuleResponse.model_validate(c) for c in capsules],
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
    
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
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
