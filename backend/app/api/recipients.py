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
    
    Returns actual recipient records from the recipients table.
    For connection-based recipients (linked_user_id IS NOT NULL), includes connection user profile info.
    
    Backward compatibility: If connections exist without recipient records, creates them on-the-fly.
    """
    from sqlalchemy import text
    from app.db.repositories import RecipientRepository, UserProfileRepository
    from app.db.models import RecipientRelationship
    from app.services.connection_service import ConnectionService
    
    skip, limit = calculate_pagination(page, page_size)
    
    # Query actual recipient records from recipients table
    # Handle case where linked_user_id column doesn't exist yet (migration not run)
    recipient_repo = RecipientRepository(session)
    try:
        recipients = await recipient_repo.get_by_owner(
            owner_id=current_user.user_id,
            skip=0,  # Get all to check for missing connections
            limit=None  # Get all to check for missing connections
        )
    except Exception as e:
        error_str = str(e).lower()
        if 'linked_user_id' in error_str and 'does not exist' in error_str:
            # Migration not run yet - return empty list and log warning
            logger.warning(
                f"linked_user_id column does not exist. Please run migration 18. "
                f"Returning empty recipients list for user {current_user.user_id}"
            )
            return []
        raise
    
    # Get connections to ensure all connections have recipient records (backward compatibility)
    # Query connections to find any that don't have recipient records
    connections_result = await session.execute(
        text("""
            SELECT DISTINCT ON (other_user_id)
                other_user_id,
                connected_at
            FROM (
                SELECT 
                    c.user_id_2 as other_user_id,
                    c.connected_at
                FROM public.connections c
                WHERE c.user_id_1 = :user_id
                
                UNION ALL
                
                SELECT 
                    c.user_id_1 as other_user_id,
                    c.connected_at
                FROM public.connections c
                WHERE c.user_id_2 = :user_id
            ) AS combined
            ORDER BY other_user_id, connected_at DESC
        """),
        {"user_id": current_user.user_id}
    )
    connections_rows = connections_result.fetchall()
    
    # Get set of connection user IDs that already have recipient records
    # Handle case where linked_user_id attribute doesn't exist (migration not run)
    existing_linked_user_ids = {
        getattr(r, 'linked_user_id', None) 
        for r in recipients 
        if getattr(r, 'linked_user_id', None) is not None
    }
    
    # Create missing recipient records for connections (backward compatibility)
    # CRITICAL: Handle race conditions where multiple requests create recipients simultaneously
    from sqlalchemy.exc import IntegrityError
    connection_service = ConnectionService(session)
    for row in connections_rows:
        other_user_id = row[0]
        if other_user_id not in existing_linked_user_ids:
            # Create recipient record for this connection
            try:
                await connection_service._create_recipient_entries(
                    from_user_id=current_user.user_id,
                    to_user_id=other_user_id
                )
                await session.commit()
                logger.info(f"Created missing recipient record for connection: {other_user_id}")
            except IntegrityError as e:
                # Unique constraint violation - another request created it first
                # This is expected in concurrent scenarios, just re-query
                await session.rollback()
                logger.info(
                    f"Recipient already exists for connection {other_user_id} "
                    f"(created by concurrent request): {e}"
                )
                # Re-query to get the recipient that was created by the other request
                # This ensures we have the latest data
                try:
                    recipients = await recipient_repo.get_by_owner(
                        owner_id=current_user.user_id,
                        skip=0,
                        limit=None
                    )
                    existing_linked_user_ids = {
                        getattr(r, 'linked_user_id', None) 
                        for r in recipients 
                        if getattr(r, 'linked_user_id', None) is not None
                    }
                except Exception as query_error:
                    logger.warning(f"Failed to re-query recipients after IntegrityError: {query_error}")
            except Exception as e:
                await session.rollback()
                logger.warning(f"Failed to create recipient for connection {other_user_id}: {e}")
    
    # Re-query recipients after creating missing ones
    # Handle case where linked_user_id column doesn't exist yet (migration not run)
    try:
        recipients = await recipient_repo.get_by_owner(
            owner_id=current_user.user_id,
            skip=skip,
            limit=limit
        )
    except Exception as e:
        error_str = str(e).lower()
        if 'linked_user_id' in error_str and 'does not exist' in error_str:
            # Migration not run yet - return empty list
            logger.warning(
                f"linked_user_id column does not exist. Please run migration 18. "
                f"Returning empty recipients list for user {current_user.user_id}"
            )
            return []
        raise
    
    # Get user profile repository for connection user info
    user_profile_repo = UserProfileRepository(session)
    
    # Convert to RecipientResponse objects
    recipient_responses: list[RecipientResponse] = []
    # CRITICAL: Deduplicate by linked_user_id for connection-based recipients
    # Multiple recipient records can exist with different IDs but same linked_user_id
    # This happens when recipients are created multiple times (race conditions)
    # For connection-based recipients (linked_user_id IS NOT NULL), use linked_user_id as unique key
    # For email-based recipients (linked_user_id IS NULL), use id as unique key
    seen_recipient_ids: set[UUID] = set()  # For email-based recipients
    seen_linked_user_ids: set[UUID] = set()  # For connection-based recipients
    
    for recipient in recipients:
        linked_user_id = getattr(recipient, 'linked_user_id', None)
        
        # For connection-based recipients, deduplicate by linked_user_id
        if linked_user_id is not None:
            if linked_user_id in seen_linked_user_ids:
                logger.warning(
                    f"Duplicate recipient with same linked_user_id found: {linked_user_id} "
                    f"(recipient.id: {recipient.id}, name: {recipient.name}) for user {current_user.user_id}. Skipping."
                )
                continue
            seen_linked_user_ids.add(linked_user_id)
        else:
            # For email-based recipients, deduplicate by id
            if recipient.id in seen_recipient_ids:
                logger.warning(
                    f"Duplicate recipient ID found: {recipient.id} for user {current_user.user_id}. Skipping."
                )
                continue
            seen_recipient_ids.add(recipient.id)
        
        # For connection-based recipients (linked_user_id IS NOT NULL), get connection user profile
        # Handle case where linked_user_id attribute doesn't exist (migration not run)
        connection_user_profile = None
        if linked_user_id:
            connection_user_profile = await user_profile_repo.get_by_id(linked_user_id)
        
        # Use connection user profile info if available, otherwise use recipient data
        if connection_user_profile:
            # Build display name from connection user profile
            name_parts = [p for p in [connection_user_profile.first_name, connection_user_profile.last_name] if p]
            display_name = " ".join(name_parts).strip() if name_parts else (
                connection_user_profile.username or f"User {str(linked_user_id)[:8]}"
            )
            avatar_url = connection_user_profile.avatar_url or recipient.avatar_url
        else:
            # Use recipient's own data (for email-based recipients)
            display_name = recipient.name
            avatar_url = recipient.avatar_url
        
        # Build response with ACTUAL recipient UUID (not user ID)
        recipient_response = RecipientResponse(
            id=recipient.id,  # ACTUAL RECIPIENT UUID from database
            owner_id=recipient.owner_id,
            name=display_name,
            email=recipient.email,  # May be None for connection-based recipients
            avatar_url=avatar_url,
            relationship=recipient.relationship,
            created_at=recipient.created_at,
            updated_at=recipient.updated_at,
            linked_user_id=linked_user_id  # Connection user ID if connection-based (None if column doesn't exist)
        )
        recipient_responses.append(recipient_response)
    
    logger.info(
        f"Listed {len(recipient_responses)} unique recipients (actual records) for user {current_user.user_id}, "
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
