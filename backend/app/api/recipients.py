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
from app.core.permissions import verify_recipient_ownership
from app.core.pagination import calculate_pagination
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
    DEPRECATED: Manual recipient creation is disabled.
    
    Recipients are now automatically created when connections are established.
    To add someone as a recipient, send them a connection request instead.
    """
    raise HTTPException(
        status_code=status.HTTP_410_GONE,
        detail="Manual recipient creation is no longer supported. Please use connection requests to add recipients."
    )
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
    # Ensure we have a valid RecipientRelationship enum object
    # The TypeDecorator with values_callable will convert it to the enum value ('friend')
    relationship = recipient_data.relationship if recipient_data.relationship else RecipientRelationship.FRIEND
    
    # Ensure we have a valid enum (convert string to enum if needed)
    if isinstance(relationship, str):
        try:
            relationship = RecipientRelationship(relationship.lower())
        except ValueError:
            relationship = RecipientRelationship.FRIEND
    elif not isinstance(relationship, RecipientRelationship):
        relationship = RecipientRelationship.FRIEND
    
    # Create recipient
    # The TypeDecorator's values_callable and bind_processor will ensure
    # enum.value ('friend') is used, not enum.name ('FRIEND')
    recipient = await recipient_repo.create(
        owner_id=current_user.user_id,
        name=name,
        email=email,
        avatar_url=avatar_url,
        relationship=relationship  # Pass enum object, TypeDecorator handles conversion
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
    
    UNIFIED: Recipients = Connections. This endpoint queries connections directly
    and returns them as recipients. The recipients table is only used as a cache
    for the capsule foreign key constraint.
    
    Returns recipients ordered by most recently connected first.
    """
    from sqlalchemy import text
    from uuid import uuid5, NAMESPACE_DNS
    from app.db.models import RecipientRelationship
    
    skip, limit = calculate_pagination(page, page_size)
    
    # Query connections directly (single source of truth)
    connections_result = await session.execute(
        text("""
            SELECT 
                c.user_id_1, 
                c.user_id_2, 
                c.connected_at,
                up.first_name,
                up.last_name,
                up.username,
                up.avatar_url,
                CASE 
                    WHEN c.user_id_1 = :user_id THEN c.user_id_2
                    ELSE c.user_id_1
                END as other_user_id
            FROM public.connections c
            LEFT JOIN public.user_profiles up ON (
                (c.user_id_1 = :user_id AND up.user_id = c.user_id_2)
                OR
                (c.user_id_2 = :user_id AND up.user_id = c.user_id_1)
            )
            WHERE c.user_id_1 = :user_id OR c.user_id_2 = :user_id
            ORDER BY c.connected_at DESC
            LIMIT :limit OFFSET :skip
        """),
        {
            "user_id": current_user.user_id,
            "limit": limit,
            "skip": skip
        }
    )
    connections_rows = connections_result.fetchall()
    
    # Convert connections to RecipientResponse objects
    recipient_responses = []
    for row in connections_rows:
        other_user_id = row[7]  # other_user_id
        first_name = row[3] if len(row) > 3 else None
        last_name = row[4] if len(row) > 4 else None
        username = row[5] if len(row) > 5 else None
        avatar_url = row[6] if len(row) > 6 else None
        connected_at = row[2]  # connected_at
        
        # Build display name
        display_name = " ".join(filter(None, [first_name, last_name])).strip()
        if not display_name:
            display_name = username or f"User {str(other_user_id)[:8]}"
        
        # Generate deterministic UUID for recipient (matches what we use when auto-creating)
        virtual_id = uuid5(NAMESPACE_DNS, f"connection_{current_user.user_id}_{other_user_id}")
        
        recipient_response = RecipientResponse(
            id=virtual_id,
            owner_id=current_user.user_id,
            name=display_name,
            email=None,  # Connections don't have email
            avatar_url=avatar_url,
            relationship=RecipientRelationship.FRIEND,
            created_at=connected_at,
            updated_at=connected_at,
            linked_user_id=other_user_id
        )
        recipient_responses.append(recipient_response)
    
    logger.info(
        f"Listed {len(recipient_responses)} recipients (from connections) for user {current_user.user_id}, "
        f"page={page}, page_size={page_size}"
    )
    
    return recipient_responses


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
    await verify_recipient_ownership(session, recipient_id, current_user.user_id)
    
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
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
    await verify_recipient_ownership(session, recipient_id, current_user.user_id)
    
    recipient_repo = RecipientRepository(session)
    
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
            update_dict["avatar_url"] = sanitize_text(
                recipient_data.avatar_url.strip(),
                max_length=MAX_URL_LENGTH
            )
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
    await verify_recipient_ownership(session, recipient_id, current_user.user_id)
    
    recipient_repo = RecipientRepository(session)
    
    # ===== Check for Associated Capsules =====
    # Note: In Supabase, we might want to check if there are capsules
    # associated with this recipient before allowing deletion.
    # For now, we'll allow deletion (cascading is handled by database)
    
    await recipient_repo.delete(recipient_id)
    
    logger.info(f"Recipient {recipient_id} deleted by user {current_user.user_id}")
    
    return MessageResponse(message="Recipient deleted successfully")
