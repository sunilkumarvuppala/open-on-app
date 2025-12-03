"""
Capsules API routes.

This module handles all capsule-related endpoints:
- Creating capsules (in draft state)
- Listing capsules (inbox/outbox with pagination)
- Viewing capsule details
- Updating capsules (drafts only)
- Sealing capsules (setting unlock time)
- Opening capsules (receiver only)
- Deleting capsules (drafts only)

Business Rules:
- Capsules start in DRAFT state and can be edited
- Once sealed, unlock time cannot be changed
- Only senders can edit/delete drafts
- Only receivers can open capsules
- State transitions are enforced by CapsuleStateMachine

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- State-based permissions are enforced
"""
from typing import Optional
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import (
    CapsuleCreate,
    CapsuleUpdate,
    CapsuleSeal,
    CapsuleResponse,
    CapsuleListResponse,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import CapsuleRepository
from app.db.models import CapsuleState
from app.services.state_machine import CapsuleStateMachine
from app.core.logging import get_logger
from app.utils.helpers import sanitize_text
from app.core.config import settings
import json


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
    Create a new capsule (initially in draft state).
    
    The capsule will be in 'draft' state until sealed with an unlock time.
    """
    capsule_repo = CapsuleRepository(session)
    
    # ===== Input Sanitization =====
    # Sanitize all text inputs to prevent injection attacks
    # Strip whitespace and enforce maximum lengths
    title = sanitize_text(capsule_data.title.strip(), max_length=settings.max_title_length)
    body = sanitize_text(capsule_data.body.strip(), max_length=settings.max_content_length)
    theme = sanitize_text(capsule_data.theme.strip(), max_length=settings.max_theme_length) if capsule_data.theme else None
    
    # ===== Receiver ID Validation =====
    # Validate that receiver_id is provided and not empty
    if not capsule_data.receiver_id or len(capsule_data.receiver_id.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Receiver ID is required"
        )
    
    receiver_id = capsule_data.receiver_id.strip()
    
    # Validate receiver_id format (must be valid UUID)
    # This prevents invalid IDs and potential injection attacks
    import uuid
    try:
        uuid.UUID(receiver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid receiver ID format"
        )
    
    # Note: Full receiver existence validation would require a database query
    # This is intentionally lightweight - receiver validation happens when capsule is sealed
    
    # ===== Media URLs Serialization =====
    # Serialize media_urls list to JSON string for database storage
    # SQLite/PostgreSQL Text field stores JSON as string
    media_urls_json = json.dumps(capsule_data.media_urls) if capsule_data.media_urls else None
    
    logger.info(
        f"Creating capsule: sender_id={current_user.id}, receiver_id={receiver_id}, "
        f"title={title[:50]}..."
    )
    
    # Create capsule in draft state
    capsule = await capsule_repo.create(
        sender_id=current_user.id,
        receiver_id=receiver_id,
        title=title,
        body=body,
        media_urls=media_urls_json,
        theme=theme,
        state=CapsuleState.DRAFT,
        allow_early_view=capsule_data.allow_early_view,
        allow_receiver_reply=capsule_data.allow_receiver_reply
    )
    
    logger.info(
        f"Capsule {capsule.id} created by user {current_user.id} "
        f"for receiver {capsule.receiver_id}"
    )
    
    return CapsuleResponse.model_validate(capsule)


@router.get("", response_model=CapsuleListResponse)
async def list_capsules(
    current_user: CurrentUser,
    session: DatabaseSession,
    box: str = Query("inbox", regex="^(inbox|outbox)$"),
    state: Optional[CapsuleState] = None,
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(settings.default_page_size, ge=settings.min_page_size, le=settings.max_page_size)
) -> CapsuleListResponse:
    """
    List capsules for the current user.
    
    - **box**: 'inbox' for received capsules, 'outbox' for sent capsules
    - **state**: Optional filter by capsule state
    - **page**: Page number (1-indexed)
    - **page_size**: Number of items per page (1-100)
    """
    capsule_repo = CapsuleRepository(session)
    
    # ===== Pagination Calculation =====
    # Calculate skip value for database offset
    # Page is 1-indexed, so page 1 = skip 0, page 2 = skip page_size, etc.
    skip = (page - 1) * page_size
    
    logger.info(
        f"Listing capsules: user_id={current_user.id}, box={box}, state={state}, "
        f"page={page}, page_size={page_size}"
    )
    
    # ===== Query Based on Box Type =====
    # "inbox" = capsules received by current user (receiver_id matches)
    # "outbox" = capsules sent by current user (sender_id matches)
    if box == "inbox":
        # Get capsules where current user is the receiver
        capsules = await capsule_repo.get_by_receiver(
            current_user.id,
            state=state,
            skip=skip,
            limit=page_size
        )
        # Get total count for pagination metadata
        total = await capsule_repo.count_by_receiver(current_user.id, state=state)
        logger.info(
            f"Inbox query result: found {len(capsules)} capsules for receiver_id={current_user.id}, "
            f"total={total}"
        )
        # Log each capsule for debugging
        for cap in capsules:
            logger.info(
                f"  - Capsule {cap.id}: receiver_id={cap.receiver_id}, sender_id={cap.sender_id}, "
                f"state={cap.state}"
            )
    else:  # outbox
        # Get capsules where current user is the sender
        capsules = await capsule_repo.get_by_sender(
            current_user.id,
            state=state,
            skip=skip,
            limit=page_size
        )
        # Get total count for pagination metadata
        total = await capsule_repo.count_by_sender(current_user.id, state=state)
        logger.info(
            f"Outbox query result: found {len(capsules)} capsules for sender_id={current_user.id}, "
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
    capsule_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Get details of a specific capsule.
    
    Users can view capsules they sent or received.
    Receivers can only view content if capsule is opened or if early_view is enabled.
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
    # Check if user has permission to view this capsule
    # Rules:
    # - Sender can always view
    # - Receiver can view if:
    #   * Capsule is opened, OR
    #   * allow_early_view is true and state is UNFOLDING/READY
    can_view, message = CapsuleStateMachine.can_view(capsule, current_user.id)
    if not can_view:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
    
    return CapsuleResponse.model_validate(capsule)


@router.put("/{capsule_id}", response_model=CapsuleResponse)
async def update_capsule(
    capsule_id: str,
    update_data: CapsuleUpdate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Update a capsule (only works for drafts).
    
    Only the sender can edit, and only before the capsule is sealed.
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
    # Check if user has permission to edit this capsule
    # Rules:
    # - Only sender can edit
    # - Only DRAFT state can be edited
    # - Once sealed, no edits are allowed
    can_edit, message = CapsuleStateMachine.can_edit(capsule, current_user.id)
    if not can_edit:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
    
    # ===== Prepare Update Data =====
    # Only include fields that were explicitly set (exclude_unset=True)
    # This allows partial updates without overwriting unchanged fields
    update_dict = update_data.model_dump(exclude_unset=True)
    
    # ===== Sanitize Text Fields =====
    # Sanitize all text inputs to prevent injection attacks
    # Only sanitize fields that are being updated
    if "title" in update_dict:
        update_dict["title"] = sanitize_text(update_dict["title"].strip(), max_length=settings.max_title_length)
    if "body" in update_dict:
        update_dict["body"] = sanitize_text(update_dict["body"].strip(), max_length=settings.max_content_length)
    if "theme" in update_dict and update_dict["theme"]:
        update_dict["theme"] = sanitize_text(update_dict["theme"].strip(), max_length=settings.max_theme_length)
    
    # ===== Serialize Media URLs =====
    # Convert media_urls list to JSON string for database storage
    if "media_urls" in update_dict:
        update_dict["media_urls"] = json.dumps(update_dict["media_urls"]) if update_dict["media_urls"] else None
    
    # Update capsule
    updated_capsule = await capsule_repo.update(capsule_id, **update_dict)
    
    logger.info(f"Capsule {capsule_id} updated by user {current_user.id}")
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.post("/{capsule_id}/seal", response_model=CapsuleResponse)
async def seal_capsule(
    capsule_id: str,
    seal_data: CapsuleSeal,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Seal a capsule with an unlock time.
    
    This transitions the capsule from 'draft' to 'sealed' state.
    Once sealed, the unlock time CANNOT be changed.
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
    # Check if user has permission to seal this capsule
    # Rules:
    # - Only sender can seal
    # - Only DRAFT state can be sealed
    # - Once sealed, unlock time cannot be changed
    can_seal, message = CapsuleStateMachine.can_seal(capsule, current_user.id)
    if not can_seal:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
    
    # ===== Unlock Time Validation =====
    # Validate and prepare seal data
    # This validates:
    # - Unlock time is in the future
    # - Unlock time is within acceptable range (1 minute to 5 years)
    # - Converts to UTC timezone-aware datetime
    try:
        seal_updates = CapsuleStateMachine.seal_capsule(seal_data.scheduled_unlock_at)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    # Update capsule
    updated_capsule = await capsule_repo.update(capsule_id, **seal_updates)
    
    logger.info(
        f"Capsule {capsule_id} sealed by user {current_user.id} "
        f"(unlock: {seal_data.scheduled_unlock_at})"
    )
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.post("/{capsule_id}/open", response_model=CapsuleResponse)
async def open_capsule(
    capsule_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """
    Open a capsule (transition from 'ready' to 'opened').
    
    Only the receiver can open a capsule, and only when it's in 'ready' state.
    This action is irreversible.
    """
    from datetime import datetime, timezone
    
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    # ===== Existence Check =====
    if not capsule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Capsule not found"
        )
    
    # ===== Permission Check =====
    # Check if user has permission to open this capsule
    # Rules:
    # - Only receiver can open
    # - Capsule must be in READY state
    # - This action is irreversible (terminal state)
    can_open, message = CapsuleStateMachine.can_open(capsule, current_user.id)
    if not can_open:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
    
    # ===== State Transition =====
    # Transition capsule to OPENED state
    # This is a terminal state - capsule cannot be reopened
    # Record the exact UTC timestamp when capsule was opened
    updated_capsule = await capsule_repo.transition_state(
        capsule_id,
        CapsuleState.OPENED,
        opened_at=datetime.now(timezone.utc)
    )
    
    logger.info(f"Capsule {capsule_id} opened by user {current_user.id}")
    
    return CapsuleResponse.model_validate(updated_capsule)


@router.delete("/{capsule_id}", response_model=MessageResponse)
async def delete_capsule(
    capsule_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Delete a capsule (only works for drafts).
    
    Only the sender can delete, and only before the capsule is sealed.
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
    # This prevents unauthorized deletion attempts
    if capsule.sender_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the sender can delete this capsule"
        )
    
    # ===== State Check =====
    # Only DRAFT state capsules can be deleted
    # Once sealed, capsules cannot be deleted (they must be delivered)
    # This ensures time-lock integrity
    if capsule.state != CapsuleState.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete capsule in {capsule.state} state"
        )
    
    await capsule_repo.delete(capsule_id)
    
    logger.info(f"Capsule {capsule_id} deleted by user {current_user.id}")
    
    return MessageResponse(message="Capsule deleted successfully")
