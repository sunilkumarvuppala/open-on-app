"""Recipients API routes."""
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import RecipientCreate, RecipientResponse, MessageResponse
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import RecipientRepository
from app.core.config import settings
from app.core.logging import get_logger
from app.utils.helpers import sanitize_text, validate_email


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
    """
    recipient_repo = RecipientRepository(session)
    
    from app.core.config import settings
    
    # Sanitize and validate inputs
    name = sanitize_text(recipient_data.name.strip(), max_length=settings.max_full_name_length)
    if not name or len(name) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Recipient name is required"
        )
    
    from app.core.config import settings
    
    email = None
    if recipient_data.email:
        email = sanitize_text(recipient_data.email.lower().strip(), max_length=settings.max_email_length)
        if not validate_email(email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid email format"
            )
    
    user_id = recipient_data.user_id.strip() if recipient_data.user_id else None
    
    # Create recipient
    recipient = await recipient_repo.create(
        owner_id=current_user.id,
        name=name,
        email=email,
        user_id=user_id
    )
    
    logger.info(f"Recipient {recipient.id} created by user {current_user.id}")
    
    return RecipientResponse.model_validate(recipient)


@router.get("", response_model=list[RecipientResponse])
async def list_recipients(
    current_user: CurrentUser,
    session: DatabaseSession,
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(settings.default_page_size, ge=settings.min_page_size, le=settings.max_page_size)
) -> list[RecipientResponse]:
    """
    List all saved recipients for the current user.
    
    Returns recipients ordered by most recently added first.
    """
    recipient_repo = RecipientRepository(session)
    skip = (page - 1) * page_size
    
    recipients = await recipient_repo.get_by_owner(
        current_user.id,
        skip=skip,
        limit=page_size
    )
    
    return [RecipientResponse.model_validate(r) for r in recipients]


@router.get("/{recipient_id}", response_model=RecipientResponse)
async def get_recipient(
    recipient_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> RecipientResponse:
    """
    Get a specific recipient.
    
    Users can only access their own saved recipients.
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # Verify ownership
    if not await recipient_repo.verify_ownership(recipient_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this recipient"
        )
    
    return RecipientResponse.model_validate(recipient)


@router.delete("/{recipient_id}", response_model=MessageResponse)
async def delete_recipient(
    recipient_id: str,
    current_user: CurrentUser,
    session: DatabaseSession
) -> MessageResponse:
    """
    Delete a saved recipient.
    
    Only the owner can delete their saved recipients.
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient not found"
        )
    
    # Verify ownership
    if not await recipient_repo.verify_ownership(recipient_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to delete this recipient"
        )
    
    await recipient_repo.delete(recipient_id)
    
    logger.info(f"Recipient {recipient_id} deleted by user {current_user.id}")
    
    return MessageResponse(message="Recipient deleted successfully")
