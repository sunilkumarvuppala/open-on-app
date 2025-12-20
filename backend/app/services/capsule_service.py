"""
Capsule service layer for business logic and validation.

This service encapsulates all capsule-related business logic, validation,
and state management to eliminate duplicate code across API endpoints.

Responsibilities:
- Capsule creation validation
- Content validation and sanitization
- Unlock time validation
- Status transition validation
- Permission checks
"""
from typing import Optional
from datetime import datetime, timezone
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.repositories import CapsuleRepository, RecipientRepository
from app.db.models import CapsuleStatus
from app.core.logging import get_logger
from app.core.permissions import verify_recipient_ownership, verify_users_are_connected
from app.utils.helpers import sanitize_text
from app.core.config import settings

logger = get_logger(__name__)


class CapsuleService:
    """Service layer for capsule business logic and validation."""
    
    def __init__(self, session: AsyncSession):
        """Initialize capsule service with database session."""
        self.session = session
        self.capsule_repo = CapsuleRepository(session)
        self.recipient_repo = RecipientRepository(session)
    
    async def validate_recipient_for_capsule(
        self,
        recipient_id: UUID,
        sender_id: UUID
    ) -> UUID:
        """
        Validate recipient exists and sender has permission to send.
        
        Args:
            recipient_id: Recipient ID to validate
            sender_id: User ID of the sender
            
        Raises:
            HTTPException: If recipient not found or permission denied
        """
        logger.info(
            f"Validating recipient for capsule: recipient_id={recipient_id}, sender_id={sender_id}"
        )
        
        # First check if recipient exists
        recipient = await self.recipient_repo.get_by_id(recipient_id)
        if not recipient:
            logger.error(
                f"Recipient not found in database: recipient_id={recipient_id}, sender_id={sender_id}"
            )
            # Try to find recipient by linked_user_id as fallback
            from sqlalchemy import select
            from app.db.models import Recipient
            result = await self.session.execute(
                select(Recipient).where(
                    Recipient.linked_user_id == recipient_id,
                    Recipient.owner_id == sender_id
                )
            )
            fallback_recipient = result.scalar_one_or_none()
            if fallback_recipient:
                logger.warning(
                    f"Found recipient by linked_user_id: recipient_id={fallback_recipient.id}, "
                    f"linked_user_id={recipient_id}"
                )
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid recipient ID. Please use recipient UUID {fallback_recipient.id} instead of user ID {recipient_id}."
                )
            
            # Special case: Self-send (sender sending to themselves)
            # Check if a self-recipient already exists
            result = await self.session.execute(
                select(Recipient).where(
                    Recipient.linked_user_id == sender_id,
                    Recipient.owner_id == sender_id
                )
            )
            existing_self_recipient = result.scalar_one_or_none()
            
            if existing_self_recipient:
                # Self-recipient exists - check if the provided ID matches
                if str(recipient_id) == str(existing_self_recipient.id):
                    # Correct ID provided - use existing self-recipient
                    recipient = existing_self_recipient
                    logger.info(f"Using existing self-recipient {recipient.id} for user {sender_id}")
                elif str(recipient_id) == str(sender_id):
                    # User ID provided instead of recipient ID - use existing self-recipient
                    recipient = existing_self_recipient
                    logger.info(
                        f"Self-send detected: Using existing self-recipient {recipient.id} "
                        f"for user {sender_id} (user ID was provided instead of recipient ID)"
                    )
                else:
                    # Wrong ID provided
                    logger.warning(
                        f"Self-send detected: Found self-recipient {existing_self_recipient.id} for user {sender_id}, "
                        f"but wrong recipient_id {recipient_id} was provided"
                    )
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Invalid recipient ID for self-send. Please use recipient UUID {existing_self_recipient.id}."
                    )
            elif str(recipient_id) == str(sender_id):
                # No self-recipient exists, but user ID was provided - create it automatically
                from app.db.repositories import UserProfileRepository
                user_profile_repo = UserProfileRepository(self.session)
                user_profile = await user_profile_repo.get_by_id(sender_id)
                
                if user_profile:
                    logger.info(f"Creating self-recipient for user {sender_id}")
                    self_recipient = await self.recipient_repo.create(
                        owner_id=sender_id,
                        name='To Self',
                        email=None,
                        avatar_url=user_profile.avatar_url,
                        username=user_profile.username,
                        linked_user_id=sender_id,
                    )
                    await self.session.flush()
                    logger.info(f"Created self-recipient {self_recipient.id} for user {sender_id}")
                    # Use the newly created self-recipient
                    recipient = self_recipient
                else:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="User profile not found. Please try again."
                    )
            else:
                # Not a self-send and recipient not found
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Recipient not found. Please ensure you are connected with this user and try again."
                )
        
        logger.info(
            f"Recipient found: recipient_id={recipient.id}, owner_id={recipient.owner_id}, "
            f"name={recipient.name}, linked_user_id={getattr(recipient, 'linked_user_id', None)}"
        )
        
        # Verify recipient belongs to sender
        if recipient.owner_id != sender_id:
            logger.error(
                f"Recipient ownership mismatch: recipient.owner_id={recipient.owner_id}, sender_id={sender_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only send letters to your own recipients"
            )
        
        # Verify recipient exists and belongs to sender (redundant check but ensures consistency)
        await verify_recipient_ownership(
            self.session,
            recipient.id,
            sender_id
        )
        
        # For legacy recipients with email, verify mutual connection
        if recipient.email:
            from sqlalchemy import text
            result = await self.session.execute(
                text("""
                    SELECT id FROM auth.users
                    WHERE email = :email
                """),
                {"email": recipient.email.lower().strip()}
            )
            recipient_user_id = result.scalar_one_or_none()
            
            if recipient_user_id:
                await verify_users_are_connected(
                    self.session,
                    sender_id,
                    recipient_user_id,
                    raise_on_not_connected=True
                )
        
        # Return the validated recipient ID (may differ from input if self-recipient was created)
        return recipient.id
    
    async def validate_anonymous_letter(
        self,
        recipient_id: UUID,
        sender_id: UUID,
        is_anonymous: bool,
        reveal_delay_seconds: Optional[int]
    ) -> None:
        """
        Validate anonymous letter requirements.
        
        Args:
            recipient_id: Recipient ID
            sender_id: User ID of the sender
            is_anonymous: Whether letter is anonymous
            reveal_delay_seconds: Reveal delay in seconds (0-259200)
            
        Raises:
            HTTPException: If validation fails
        """
        if not is_anonymous:
            return  # No validation needed for non-anonymous letters
        
        # Anonymous letters require reveal_delay_seconds
        if reveal_delay_seconds is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Anonymous letters must have a reveal delay (reveal_delay_seconds)"
            )
        
        # Enforce max 72 hours (259200 seconds)
        if reveal_delay_seconds > 259200:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reveal delay cannot exceed 72 hours (259200 seconds)"
            )
        
        # Get recipient to check if it's a connection-based recipient
        recipient = await self.recipient_repo.get_by_id(recipient_id)
        if not recipient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipient not found"
            )
        
        # Verify recipient belongs to sender
        if recipient.owner_id != sender_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only send anonymous letters to your own recipients"
            )
        
        # Anonymous letters require mutual connection
        linked_user_id = getattr(recipient, 'linked_user_id', None)
        if linked_user_id:
            # Connection-based recipient: verify mutual connection
            from app.core.permissions import verify_users_are_connected
            await verify_users_are_connected(
                self.session,
                sender_id,
                linked_user_id,
                raise_on_not_connected=True
            )
        elif recipient.email:
            # Email-based recipient: find user and verify connection
            from sqlalchemy import text
            result = await self.session.execute(
                text("""
                    SELECT id FROM auth.users
                    WHERE email = :email
                """),
                {"email": recipient.email.lower().strip()}
            )
            recipient_user_id = result.scalar_one_or_none()
            
            if recipient_user_id:
                from app.core.permissions import verify_users_are_connected
                await verify_users_are_connected(
                    self.session,
                    sender_id,
                    recipient_user_id,
                    raise_on_not_connected=True
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Anonymous letters can only be sent to mutual connections. Please connect with this user first."
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Anonymous letters can only be sent to mutual connections"
            )
    
    def validate_content(
        self,
        body_text: Optional[str],
        body_rich_text: Optional[str]
    ) -> None:
        """
        Validate capsule content.
        
        Args:
            body_text: Plain text content
            body_rich_text: Rich text content
            
        Raises:
            HTTPException: If content validation fails
        """
        if not body_text and not body_rich_text:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either body_text or body_rich_text is required"
            )
    
    def sanitize_content(
        self,
        title: Optional[str],
        body_text: Optional[str]
    ) -> tuple[Optional[str], Optional[str]]:
        """
        Sanitize capsule title and body text.
        
        Args:
            title: Title to sanitize
            body_text: Body text to sanitize
            
        Returns:
            Tuple of (sanitized_title, sanitized_body_text)
        """
        sanitized_title = None
        if title:
            sanitized_title = sanitize_text(
                title.strip(),
                max_length=settings.max_title_length
            )
        
        sanitized_body_text = None
        if body_text:
            sanitized_body_text = sanitize_text(
                body_text.strip(),
                max_length=settings.max_content_length
            )
        
        return sanitized_title, sanitized_body_text
    
    def validate_unlock_time(self, unlocks_at: datetime) -> datetime:
        """
        Validate and normalize unlock time.
        
        Args:
            unlocks_at: Unlock datetime to validate
            
        Returns:
            Normalized UTC datetime
            
        Raises:
            HTTPException: If unlock time is invalid
        """
        # Ensure timezone-aware and convert to UTC
        if unlocks_at.tzinfo is None:
            unlocks_at = unlocks_at.replace(tzinfo=timezone.utc)
        else:
            unlocks_at = unlocks_at.astimezone(timezone.utc)
        
        # Validate future time
        now = datetime.now(timezone.utc)
        if unlocks_at <= now:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unlock time must be in the future"
            )
        
        return unlocks_at
    
    def validate_disappearing_message(
        self,
        is_disappearing: bool,
        disappearing_after_open_seconds: Optional[int]
    ) -> None:
        """
        Validate disappearing message configuration.
        
        Args:
            is_disappearing: Whether message is disappearing
            disappearing_after_open_seconds: Seconds until deletion after opening
            
        Raises:
            HTTPException: If validation fails
        """
        if is_disappearing and not disappearing_after_open_seconds:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="disappearing_after_open_seconds is required when is_disappearing is true"
            )
    
    async def validate_capsule_for_update(
        self,
        capsule_id: UUID,
        sender_id: UUID
    ) -> None:
        """
        Validate capsule can be updated.
        
        Args:
            capsule_id: Capsule ID to validate
            sender_id: User ID attempting update
            
        Raises:
            HTTPException: If update is not allowed
        """
        capsule = await self.capsule_repo.get_by_id(capsule_id)
        
        if not capsule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Capsule not found"
            )
        
        if capsule.sender_id != sender_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the sender can edit this capsule"
            )
        
        if capsule.status == CapsuleStatus.OPENED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot edit capsule that has been opened"
            )
    
    async def validate_capsule_for_opening(
        self,
        capsule_id: UUID
    ) -> None:
        """
        Validate capsule can be opened.
        
        Args:
            capsule_id: Capsule ID to validate
            
        Raises:
            HTTPException: If capsule cannot be opened
        """
        capsule = await self.capsule_repo.get_by_id(capsule_id)
        
        if not capsule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Capsule not found"
            )
        
        if capsule.status != CapsuleStatus.READY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Capsule is not ready yet (current status: {capsule.status.value})"
            )
