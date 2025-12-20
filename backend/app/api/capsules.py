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
from datetime import datetime, timezone, timedelta
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
    logger.info(
        f"Creating capsule request: sender_id={current_user.user_id}, "
        f"recipient_id={capsule_data.recipient_id}, "
        f"title={capsule_data.title}, "
        f"unlocks_at={capsule_data.unlocks_at}"
    )
    
    capsule_service = CapsuleService(session)
    capsule_repo = CapsuleRepository(session)
    
    # Validate recipient and permissions
    try:
        await capsule_service.validate_recipient_for_capsule(
            capsule_data.recipient_id,
            current_user.user_id
        )
    except HTTPException as e:
        logger.error(
            f"Recipient validation failed for user {current_user.user_id}, "
            f"recipient_id={capsule_data.recipient_id}: {e.detail}"
        )
        raise
    
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
    
    # Validate anonymous letter requirements (mutual connection, reveal delay)
    if capsule_data.is_anonymous:
        await capsule_service.validate_anonymous_letter(
            capsule_data.recipient_id,
            current_user.user_id,
            capsule_data.is_anonymous,
            capsule_data.reveal_delay_seconds
        )
        # Set default reveal delay if not provided (6 hours = 21600 seconds)
        reveal_delay = capsule_data.reveal_delay_seconds or 21600
    else:
        reveal_delay = None
    
    logger.info(
        f"Creating capsule: sender_id={current_user.user_id}, recipient_id={capsule_data.recipient_id}, "
        f"unlocks_at={unlocks_at}, is_anonymous={capsule_data.is_anonymous}, "
        f"reveal_delay_seconds={reveal_delay}"
    )
    
    # Create capsule in sealed status
    capsule = await capsule_repo.create(
        sender_id=current_user.user_id,
        recipient_id=capsule_data.recipient_id,
        title=title,
        body_text=body_text,
        body_rich_text=capsule_data.body_rich_text,
        is_anonymous=capsule_data.is_anonymous,
        reveal_delay_seconds=reveal_delay,
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
    
    # Eagerly load recipient to avoid lazy loading in async context
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(capsule.recipient_id)
    
    return CapsuleResponse.from_orm_with_profile(capsule, recipient=recipient)


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
        
        # Build user display name (normalized for matching)
        # This must match how recipient names are stored when connections are created
        user_display_name = None
        if user_profile:
            # Build display name from first_name and last_name (same logic as connection service)
            name_parts = []
            if user_profile.first_name:
                name_parts.append(user_profile.first_name.strip())
            if user_profile.last_name:
                name_parts.append(user_profile.last_name.strip())
            user_display_name = " ".join(name_parts).strip()
            if not user_display_name:
                user_display_name = (user_profile.username or f"User {str(current_user.user_id)[:8]}").strip()
        
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
    
    # Build response with recipient user profiles for connection-based recipients
    from app.db.repositories import UserProfileRepository
    user_profile_repo = UserProfileRepository(session)
    capsule_responses = []
    
    # Collect all linked_user_ids to batch fetch user profiles
    linked_user_ids = set()
    for capsule in capsules:
        if capsule.recipient:
            # Check if recipient has linked_user_id attribute and it's not None
            linked_user_id = getattr(capsule.recipient, 'linked_user_id', None)
            if linked_user_id:
                linked_user_ids.add(linked_user_id)
                logger.debug(f"Capsule {capsule.id}: recipient has linked_user_id={linked_user_id}")
            else:
                logger.debug(f"Capsule {capsule.id}: recipient has no linked_user_id (email-based or missing)")
    
    # Batch fetch all user profiles at once
    user_profiles_map = {}
    if linked_user_ids:
        logger.info(f"Fetching {len(linked_user_ids)} user profiles for recipient avatars: {linked_user_ids}")
        for user_id in linked_user_ids:
            try:
                profile = await user_profile_repo.get_by_id(user_id)
                if profile:
                    user_profiles_map[user_id] = profile
                    logger.info(f"Fetched profile for user {user_id}, avatar_url={profile.avatar_url}")
                else:
                    logger.warning(f"User profile not found for linked_user_id {user_id}")
            except Exception as e:
                logger.error(f"Failed to fetch user profile for linked_user_id {user_id}: {e}", exc_info=True)
    
    # Build responses using the cached user profiles
    for capsule in capsules:
        recipient_user_profile = None
        if capsule.recipient:
            linked_user_id = getattr(capsule.recipient, 'linked_user_id', None)
            recipient_own_avatar = getattr(capsule.recipient, 'avatar_url', None)
            
            if linked_user_id:
                recipient_user_profile = user_profiles_map.get(linked_user_id)
                if recipient_user_profile:
                    logger.info(f"Capsule {capsule.id}: Using linked user avatar_url={recipient_user_profile.avatar_url}")
                else:
                    logger.warning(f"Capsule {capsule.id}: Linked user profile not found for linked_user_id={linked_user_id}, falling back to recipient.avatar_url={recipient_own_avatar}")
            else:
                logger.info(f"Capsule {capsule.id}: Recipient has no linked_user_id (email-based), using recipient.avatar_url={recipient_own_avatar}")
        
        response = CapsuleResponse.from_orm_with_profile(
            capsule,
            recipient_user_profile=recipient_user_profile
        )
        # Log the recipient_avatar_url from the response dict
        response_dict = response.model_dump()
        logger.info(f"Capsule {capsule.id}: Final recipient_avatar_url={response_dict.get('recipient_avatar_url')}")
        capsule_responses.append(response)
    
    return CapsuleListResponse(
        capsules=capsule_responses,
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
    # get_by_id eagerly loads sender_profile and recipient relationships
    capsule = await capsule_repo.get_by_id(capsule_id)
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # Recipients can only view if status is ready or opened
    if is_recipient and not is_sender:
        if capsule.status not in [CapsuleStatus.READY, CapsuleStatus.OPENED]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Capsule is not ready yet (current status: {capsule.status.value})"
            )
    
    # get_by_id already eagerly loads relationships, so from_orm_with_profile is safe
    # Get recipient user profile if recipient is connection-based
    recipient_user_profile = None
    if capsule.recipient:
        linked_user_id = getattr(capsule.recipient, 'linked_user_id', None)
        if linked_user_id:
            from app.db.repositories import UserProfileRepository
            user_profile_repo = UserProfileRepository(session)
            try:
                recipient_user_profile = await user_profile_repo.get_by_id(linked_user_id)
            except Exception as e:
                logger.warning(f"Failed to fetch recipient user profile for linked_user_id {linked_user_id}: {e}")
    
    return CapsuleResponse.from_orm_with_profile(
        capsule,
        recipient_user_profile=recipient_user_profile
    )


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
    
    # SECURITY: Explicitly exclude reveal-related fields from updates
    # These fields are server-managed and must never be updated by clients
    update_dict.pop('reveal_at', None)
    update_dict.pop('reveal_delay_seconds', None)
    update_dict.pop('sender_revealed_at', None)
    update_dict.pop('opened_at', None)  # Must be set via open_letter RPC
    update_dict.pop('sender_id', None)  # Cannot change sender
    update_dict.pop('status', None)  # Status is managed by state machine/triggers
    update_dict.pop('unlocks_at', None)  # Cannot change unlock time after creation
    
    # Update capsule
    updated_capsule = await capsule_repo.update(capsule_id, **update_dict)
    
    logger.info(f"Capsule {capsule_id} updated by user {current_user.user_id}")
    
    # Reload capsule with relationships to ensure all data is available
    # update() returns capsule but relationships may not be loaded
    capsule_with_relations = await capsule_repo.get_by_id(capsule_id)
    if not capsule_with_relations:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found after update"
        )
    
    return CapsuleResponse.from_orm_with_profile(capsule_with_relations)


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
    
    # Get capsule to check if it's anonymous and get reveal_delay_seconds
    capsule = await capsule_repo.get_by_id(capsule_id)
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # Calculate opened_at timestamp
    opened_at = datetime.now(timezone.utc)
    
    # If anonymous, calculate reveal_at = opened_at + reveal_delay_seconds
    reveal_at = None
    if capsule.is_anonymous and capsule.reveal_delay_seconds is not None:
        reveal_delay = capsule.reveal_delay_seconds
        # Enforce max 72 hours (safety check)
        if reveal_delay > 259200:
            reveal_delay = 259200
        reveal_at = opened_at + timedelta(seconds=reveal_delay)
        logger.info(
            f"Anonymous capsule {capsule_id}: reveal_at will be {reveal_at} "
            f"(delay: {reveal_delay} seconds)"
        )
    
    # ===== State Transition =====
    # Transition capsule to OPENED status
    # Record the exact UTC timestamp when capsule was opened
    # For anonymous letters, also set reveal_at
    # The trigger in Supabase will handle:
    # - Setting status to 'opened'
    # - Creating notification for sender
    # - Setting deleted_at for disappearing messages
    update_fields = {
        "opened_at": opened_at,
        "status": CapsuleStatus.OPENED
    }
    if reveal_at is not None:
        update_fields["reveal_at"] = reveal_at
    
    updated_capsule = await capsule_repo.update(capsule_id, **update_fields)
    
    logger.info(
        f"Capsule {capsule_id} opened by user {current_user.user_id} "
        f"(anonymous: {capsule.is_anonymous}, reveal_at: {reveal_at})"
    )
    
    # Eagerly load recipient to avoid lazy loading in async context
    # get_by_id already loads relationships, but transition_status uses update() which doesn't
    # Reload capsule with relationships to ensure all data is available
    capsule_with_relations = await capsule_repo.get_by_id(capsule_id)
    if not capsule_with_relations:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found after update"
        )
    
    return CapsuleResponse.from_orm_with_profile(capsule_with_relations)


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
