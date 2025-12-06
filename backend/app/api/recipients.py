"""
Recipients API routes matching Supabase schema.

This module handles recipient management endpoints:
- Creating recipients (can include relationship and avatar_url)
- Listing recipients (with pagination)
- Getting recipient details
- Updating recipients
- Deleting recipients

Business Rules:
- Recipients are owned by the user who created them
- Only owners can view/edit/delete their recipients
- Email is optional but validated if provided
- Relationship defaults to 'friend' if not specified
- Avatar URL is optional

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- Email format is validated
"""
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import RecipientCreate, RecipientResponse, MessageResponse
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import RecipientRepository
from app.db.models import RecipientRelationship
from app.core.config import settings
from app.core.logging import get_logger
from app.utils.helpers import sanitize_text, validate_email
from app.core.constants import MAX_URL_LENGTH


# Router for all recipient endpoints
router = APIRouter(prefix="/recipients", tags=["Recipients"])
logger = get_logger(__name__)


@router.post("", response_model=RecipientResponse, status_code=status.HTTP_201_CREATED)
async def create_recipient(
    recipient_data: RecipientCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> RecipientResponse:
    """
    Add a new recipient to saved contacts.
    
    Recipients can be linked to existing users or just stored as contacts.
    Relationship defaults to 'friend' if not specified.
    """
    recipient_repo = RecipientRepository(session)
    
    # ===== Name Validation =====
    # Sanitize and validate recipient name
    # Name is required and must not be empty after sanitization
    name = sanitize_text(recipient_data.name.strip(), max_length=settings.max_full_name_length)
    if not name or len(name) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Recipient name is required"
        )
    
    # ===== Email Validation =====
    # Email is optional but must be valid format if provided
    # Lowercase email for consistency
    email = None
    if recipient_data.email:
        email = sanitize_text(recipient_data.email.lower().strip(), max_length=settings.max_email_length)
        if not validate_email(email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid email format"
            )
    
    # ===== Avatar URL Validation =====
    # Avatar URL is optional, but if provided, should be a valid URL
    avatar_url = None
    if recipient_data.avatar_url:
        avatar_url = sanitize_text(recipient_data.avatar_url.strip(), max_length=MAX_URL_LENGTH)
    
    # ===== Relationship =====
    # Use provided relationship or default to 'friend'
    relationship = recipient_data.relationship if recipient_data.relationship else RecipientRelationship.FRIEND
    
    # Create recipient
    recipient = await recipient_repo.create(
        owner_id=current_user.user_id,
        name=name,
        email=email,
        avatar_url=avatar_url,
        relationship=relationship
    )
    
    logger.info(f"Recipient {recipient.id} created by user {current_user.user_id}")
    
    return RecipientResponse.model_validate(recipient)


@router.get("", response_model=list[RecipientResponse])
async def list_recipients(
    current_user: CurrentUser,
    session: DatabaseSession,
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(settings.default_page_size, ge=settings.min_page_size, le=settings.max_page_size)
) -> list[RecipientResponse]:
    """
    List all recipients for the current user.
    
    Returns recipients ordered by most recently created first.
    """
    recipient_repo = RecipientRepository(session)
    
    # ===== Pagination Calculation =====
    skip = (page - 1) * page_size
    
    recipients = await recipient_repo.get_by_owner(
        current_user.user_id,
        skip=skip,
        limit=page_size
    )
    
    logger.info(
        f"Listed {len(recipients)} recipients for user {current_user.user_id}, "
        f"page={page}, page_size={page_size}"
    )
    
    return [RecipientResponse.model_validate(r) for r in recipients]


@router.get("/{recipient_id}", response_model=RecipientResponse)
async def get_recipient(
    recipient_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> RecipientResponse:
    """
    Get details of a specific recipient.
    
    Only the owner can view their recipients.
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    # ===== Existence Check =====
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # ===== Ownership Check =====
    # Only the owner can view their recipients
    if recipient.owner_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view this recipient"
        )
    
    return RecipientResponse.model_validate(recipient)


@router.put("/{recipient_id}", response_model=RecipientResponse)
async def update_recipient(
    recipient_id: UUID,
    recipient_data: RecipientCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> RecipientResponse:
    """
    Update a recipient.
    
    Only the owner can update their recipients.
    All fields are optional for partial updates.
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    # ===== Existence Check =====
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # ===== Ownership Check =====
    # Only the owner can update their recipients
    if recipient.owner_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update this recipient"
        )
    
    # ===== Prepare Update Data =====
    # Only include fields that were provided
    update_dict = {}
    
    if recipient_data.name:
        name = sanitize_text(recipient_data.name.strip(), max_length=settings.max_full_name_length)
        if name:
            update_dict["name"] = name
    
    if recipient_data.email is not None:
        if recipient_data.email:
            email = sanitize_text(recipient_data.email.lower().strip(), max_length=settings.max_email_length)
            if not validate_email(email):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid email format"
                )
            update_dict["email"] = email
        else:
            update_dict["email"] = None  # Allow clearing email
    
    if recipient_data.avatar_url is not None:
        if recipient_data.avatar_url:
            update_dict["avatar_url"] = sanitize_text(recipient_data.avatar_url.strip(), max_length=500)
        else:
            update_dict["avatar_url"] = None  # Allow clearing avatar
    
    if recipient_data.relationship:
        update_dict["relationship"] = recipient_data.relationship
    
    if not update_dict:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update"
        )
    
    # Update recipient
    updated_recipient = await recipient_repo.update(recipient_id, **update_dict)
    
    logger.info(f"Recipient {recipient_id} updated by user {current_user.user_id}")
    
    return RecipientResponse.model_validate(updated_recipient)


@router.delete("/{recipient_id}", response_model=MessageResponse)
async def delete_recipient(
    recipient_id: UUID,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Delete a recipient.
    
    Only the owner can delete their recipients.
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    # ===== Existence Check =====
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # ===== Ownership Check =====
    # Only the owner can delete their recipients
    if recipient.owner_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this recipient"
        )
    
    # ===== Check for Associated Capsules =====
    # Note: In Supabase, we might want to check if there are capsules
    # associated with this recipient before allowing deletion.
    # For now, we'll allow deletion (cascading is handled by database)
    
    await recipient_repo.delete(recipient_id)
    
    logger.info(f"Recipient {recipient_id} deleted by user {current_user.user_id}")
    
    return MessageResponse(message="Recipient deleted successfully")
