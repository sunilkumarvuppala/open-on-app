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
    if not is_sender and user_email:
        recipient_repo = RecipientRepository(session)
        recipient = await recipient_repo.get_by_id(capsule.recipient_id)
        if recipient and recipient.email:
            user_email_lower = user_email.lower().strip()
            recipient_email_lower = recipient.email.lower().strip()
            is_recipient = user_email_lower == recipient_email_lower
    
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
    
    if not recipient.email:
        logger.error(
            f"Recipient {capsule.recipient_id} has no email set for capsule {capsule_id}. "
            f"User attempting to open: {user_id} ({user_email}). "
            f"Recipient name: {recipient.name}, owner_id: {recipient.owner_id}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Recipient email not set. Cannot verify recipient permission."
        )
    
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
