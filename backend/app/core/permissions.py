"""
Permission checking utilities for API endpoints.

This module provides reusable permission checking functions to eliminate
duplicate code across API endpoints.
"""
from uuid import UUID
from fastapi import HTTPException, status
from app.db.repositories import RecipientRepository, CapsuleRepository
from app.db.models import CapsuleStatus
from app.core.logging import get_logger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

logger = get_logger(__name__)


async def verify_recipient_ownership(
    session: AsyncSession,
    recipient_id: UUID,
    user_id: UUID,
    raise_on_not_found: bool = True
) -> bool:
    """
    Verify that a user owns a recipient.
    
    Args:
        session: Database session
        recipient_id: Recipient ID to check
        user_id: User ID to verify ownership
        raise_on_not_found: If True, raise 404 if recipient not found
        
    Returns:
        True if user owns recipient, False otherwise
        
    Raises:
        HTTPException 404: If recipient not found and raise_on_not_found=True
        HTTPException 403: If user doesn't own recipient
    """
    recipient_repo = RecipientRepository(session)
    recipient = await recipient_repo.get_by_id(recipient_id)
    
    if not recipient:
        if raise_on_not_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipient not found"
            )
        return False
    
    if recipient.owner_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this recipient"
        )
    
    return True


async def verify_users_are_connected(
    session: AsyncSession,
    user_id_1: UUID,
    user_id_2: UUID,
    raise_on_not_connected: bool = True
) -> bool:
    """
    Verify that two users are mutually connected.
    
    This enforces that letters can only be sent to mutual friends.
    
    Args:
        session: Database session
        user_id_1: First user ID
        user_id_2: Second user ID
        raise_on_not_connected: If True, raise 403 if users are not connected
        
    Returns:
        True if users are connected, False otherwise
        
    Raises:
        HTTPException 403: If users are not connected and raise_on_not_connected=True
    """
    # Sort user IDs to match how connections are stored
    user1 = min(user_id_1, user_id_2)
    user2 = max(user_id_1, user_id_2)
    
    # Check if connection exists
    result = await session.execute(
        text("""
            SELECT 1 FROM public.connections
            WHERE user_id_1 = :user1 AND user_id_2 = :user2
        """),
        {"user1": user1, "user2": user2}
    )
    
    is_connected = result.scalar() is not None
    
    if not is_connected and raise_on_not_connected:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only send letters to users you are connected with. Please send a connection request first."
        )
    
    return is_connected


async def verify_capsule_access(
    session: AsyncSession,
    capsule_id: UUID,
    user_id: UUID,
    user_email: str | None = None,
    raise_on_not_found: bool = True
) -> tuple[bool, bool]:
    """
    Verify that a user can access a capsule (as sender or recipient).
    
    Args:
        session: Database session
        capsule_id: Capsule ID to check
        user_id: User ID to verify access
        user_email: User email for recipient verification (optional)
        raise_on_not_found: If True, raise 404 if capsule not found
        
    Returns:
        Tuple of (is_sender, is_recipient)
        
    Raises:
        HTTPException 404: If capsule not found and raise_on_not_found=True
        HTTPException 403: If user doesn't have access
    """
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    if not capsule:
        if raise_on_not_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Capsule not found"
            )
        return False, False
    
    is_sender = capsule.sender_id == user_id
    
    is_recipient = False
    if not is_sender:
        recipient_repo = RecipientRepository(session)
        recipient = await recipient_repo.get_by_id(capsule.recipient_id)
        
        if recipient:
            # Email-based recipient: match email
            if recipient.email and user_email:
                user_email_lower = user_email.lower().strip()
                recipient_email_lower = recipient.email.lower().strip()
                is_recipient = user_email_lower == recipient_email_lower
            # Connection-based recipient: check if sender and user are connected
            elif not recipient.email:
                is_recipient = await verify_users_are_connected(
                    session,
                    capsule.sender_id,
                    user_id,
                    raise_on_not_connected=False
                )
    
    if not is_sender and not is_recipient:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view this capsule"
        )
    
    return is_sender, is_recipient


async def verify_capsule_sender(
    session: AsyncSession,
    capsule_id: UUID,
    user_id: UUID,
    raise_on_not_found: bool = True
) -> bool:
    """
    Verify that a user is the sender of a capsule.
    
    Args:
        session: Database session
        capsule_id: Capsule ID to check
        user_id: User ID to verify
        raise_on_not_found: If True, raise 404 if capsule not found
        
    Returns:
        True if user is sender
        
    Raises:
        HTTPException 404: If capsule not found and raise_on_not_found=True
        HTTPException 403: If user is not the sender
    """
    capsule_repo = CapsuleRepository(session)
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    if not capsule:
        if raise_on_not_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Capsule not found"
            )
        return False
    
    if capsule.sender_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the sender can perform this action"
        )
    
    return True


async def verify_capsule_recipient(
    session: AsyncSession,
    capsule_id: UUID,
    user_id: UUID,
    user_email: str,
    raise_on_not_found: bool = True
) -> bool:
    """
    Verify that a user is the recipient of a capsule.
    
    Args:
        session: Database session
        capsule_id: Capsule ID to check
        user_id: User ID to verify
        user_email: User email for verification
        raise_on_not_found: If True, raise 404 if capsule not found
        
    Returns:
        True if user is recipient
        
    Raises:
        HTTPException 404: If capsule not found and raise_on_not_found=True
        HTTPException 403: If user is not the recipient
    """
    capsule_repo = CapsuleRepository(session)
    recipient_repo = RecipientRepository(session)
    
    capsule = await capsule_repo.get_by_id(capsule_id)
    
    if not capsule:
        if raise_on_not_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Capsule not found"
            )
        return False
    
    recipient = await recipient_repo.get_by_id(capsule.recipient_id)
    if not recipient:
        logger.error(
            f"Recipient {capsule.recipient_id} not found for capsule {capsule_id}. "
            f"User attempting to open: {user_id} ({user_email})"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Recipient not found for this capsule"
        )
    
    # ===== Email-based Recipients =====
    # If recipient has email, verify by email matching
    if recipient.email:
        user_email_lower = user_email.lower().strip()
        recipient_email_lower = recipient.email.lower().strip()
        
        if user_email_lower != recipient_email_lower:
            logger.warning(
                f"Email mismatch for capsule {capsule_id}. "
                f"User email: {user_email_lower}, Recipient email: {recipient_email_lower}. "
                f"User ID: {user_id}, Recipient ID: {capsule.recipient_id}, Recipient owner: {recipient.owner_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not the recipient of this capsule"
            )
        
        return True
    
    # ===== Connection-based Recipients =====
    # If recipient doesn't have email, it's a connection-based recipient
    # Verify that the sender and current user are connected
    # This allows users to open capsules sent to them via connections
    
    # Special case: Self-send (sender sending to themselves)
    # Check if recipient's linked_user_id matches sender_id, or if sender == user
    recipient_linked_user_id = getattr(recipient, 'linked_user_id', None)
    is_self_send = (
        recipient_linked_user_id is not None and 
        str(recipient_linked_user_id) == str(capsule.sender_id) and
        str(capsule.sender_id) == str(user_id)
    ) or str(capsule.sender_id) == str(user_id)
    
    if is_self_send:
        logger.info(
            f"Self-send detected for capsule {capsule_id}. "
            f"Sender {capsule.sender_id} is sending to themselves. Allowing access."
        )
        return True
    
    logger.info(
        f"Recipient {capsule.recipient_id} has no email for capsule {capsule_id}. "
        f"Verifying connection between sender {capsule.sender_id} and user {user_id}"
    )
    
    # Check if sender and current user are connected
    is_connected = await verify_users_are_connected(
        session,
        capsule.sender_id,
        user_id,
        raise_on_not_connected=False
    )
    
    if not is_connected:
        logger.warning(
            f"Connection verification failed for capsule {capsule_id}. "
            f"Sender {capsule.sender_id} and user {user_id} are not connected. "
            f"Recipient name: {recipient.name}, owner_id: {recipient.owner_id}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not the recipient of this capsule"
        )
    
    logger.info(
        f"Connection verified for capsule {capsule_id}. "
        f"User {user_id} is connected to sender {capsule.sender_id}"
    )
    
    return True
