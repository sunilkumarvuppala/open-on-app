"""
Drafts API routes.

This module handles draft management endpoints:
- Creating drafts (unsent capsules)
- Listing drafts (with pagination)
- Getting draft details
- Updating drafts
- Deleting drafts

Business Rules:
- Drafts are unsent capsules that can be freely edited
- Drafts are owned by the user who created them
- Only owners can view/edit/delete their drafts
- Drafts can be converted to capsules when ready to send

Security:
- All inputs are sanitized
- Ownership is verified for all operations
"""
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import DraftCreate, DraftUpdate, DraftResponse, MessageResponse
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import DraftRepository
from app.core.logging import get_logger
from app.core.config import settings
import json


# Router for all draft endpoints
router = APIRouter(prefix="/drafts", tags=["Drafts"])
logger = get_logger(__name__)


@router.post("", response_model=DraftResponse, status_code=status.HTTP_201_CREATED)
async def create_draft(
    draft_data: DraftCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> DraftResponse:
    """
    Create a new draft.
    
    Drafts are unsent capsules that can be edited and deleted freely.
    """
    draft_repo = DraftRepository(session)
    
    # ===== Media URLs Serialization =====
    # Serialize media_urls list to JSON string for database storage
    # SQLite/PostgreSQL Text field stores JSON as string
    media_urls_json = json.dumps(draft_data.media_urls) if draft_data.media_urls else None
    
    # ===== Draft Creation =====
    # Create draft record with current user as owner
    # Drafts can be edited and deleted freely until converted to capsules
    draft = await draft_repo.create(
        owner_id=current_user.id,
        title=draft_data.title,
        body=draft_data.body,
        media_urls=media_urls_json,
        theme=draft_data.theme,
        recipient_id=draft_data.recipient_id
    )
    
    logger.info(f"Draft {draft.id} created by user {current_user.id}")
    
    return DraftResponse.model_validate(draft)


@router.get("", response_model=list[DraftResponse])
async def list_drafts(
    current_user: CurrentUser,
    session: DatabaseSession,
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(50, ge=1, le=100)
) -> list[DraftResponse]:
    """
    List all drafts for the current user.
    
    Returns drafts ordered by most recently updated first.
    """
    draft_repo = DraftRepository(session)
    skip = (page - 1) * page_size
    
    drafts = await draft_repo.get_by_owner(
        current_user.id,
        skip=skip,
        limit=page_size
    )
    
    return [DraftResponse.model_validate(d) for d in drafts]


@router.get("/{draft_id}", response_model=DraftResponse)
async def get_draft(
    draft_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> DraftResponse:
    """
    Get a specific draft.
    
    Users can only access their own drafts.
    """
    draft_repo = DraftRepository(session)
    draft = await draft_repo.get_by_id(draft_id)
    
    # ===== Existence Check =====
    if not draft:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Draft not found"
        )
    
    # ===== Ownership Verification =====
    # Verify that current user owns this draft
    # Users can only access their own drafts
    # This prevents unauthorized access to draft content
    if not await draft_repo.verify_ownership(draft_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this draft"
        )
    
    return DraftResponse.model_validate(draft)


@router.put("/{draft_id}", response_model=DraftResponse)
async def update_draft(
    draft_id: str,
    update_data: DraftUpdate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> DraftResponse:
    """
    Update a draft.
    
    Only the owner can update their drafts.
    """
    draft_repo = DraftRepository(session)
    draft = await draft_repo.get_by_id(draft_id)
    
    if not draft:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Draft not found"
        )
    
    # Verify ownership
    if not await draft_repo.verify_ownership(draft_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to update this draft"
        )
    
    # ===== Prepare Update Data =====
    # Only include fields that were explicitly set (exclude_unset=True)
    # This allows partial updates without overwriting unchanged fields
    update_dict = update_data.model_dump(exclude_unset=True)
    
    # ===== Serialize Media URLs =====
    # Convert media_urls list to JSON string for database storage
    if "media_urls" in update_dict:
        update_dict["media_urls"] = json.dumps(update_dict["media_urls"]) if update_dict["media_urls"] else None
    
    # Update draft
    updated_draft = await draft_repo.update(draft_id, **update_dict)
    
    logger.info(f"Draft {draft_id} updated by user {current_user.id}")
    
    return DraftResponse.model_validate(updated_draft)


@router.delete("/{draft_id}", response_model=MessageResponse)
async def delete_draft(
    draft_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Delete a draft.
    
    Only the owner can delete their drafts.
    """
    draft_repo = DraftRepository(session)
    draft = await draft_repo.get_by_id(draft_id)
    
    if not draft:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Draft not found"
        )
    
    # Verify ownership
    if not await draft_repo.verify_ownership(draft_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to delete this draft"
        )
    
    await draft_repo.delete(draft_id)
    
    logger.info(f"Draft {draft_id} deleted by user {current_user.id}")
    
    return MessageResponse(message="Draft deleted successfully")
