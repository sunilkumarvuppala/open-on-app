"""
Time-lock unlock service for automated capsule status transitions matching Supabase schema.

This service handles automatic status transitions for capsules based on time.
It's called periodically by the background worker to check if any capsules
need to transition statuses (SEALED → READY).

Status Transitions:
- SEALED → READY: When unlocks_at has passed

This service ensures capsules automatically progress through their lifecycle
without manual intervention.
"""
from typing import TYPE_CHECKING
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.repositories import CapsuleRepository
from app.services.state_machine import CapsuleStateMachine
from app.core.logging import get_logger

if TYPE_CHECKING:
    from app.db.models import Capsule


logger = get_logger(__name__)


class UnlockService:
    """
    Service for checking and updating capsule unlock statuses.
    
    This service periodically checks all capsules that might need status
    transitions and updates them based on their unlock time.
    
    Responsibilities:
    - Check capsules for status transitions
    - Update capsule statuses via state machine
    - Track statistics for monitoring
    - Trigger notifications when capsules become ready
    
    Usage:
        Called by background worker on a schedule (e.g., every 60 seconds)
    """
    
    def __init__(self, session: AsyncSession):
        """
        Initialize unlock service with database session.
        
        Args:
            session: Async database session for queries and updates
        """
        self.session = session
        self.repository = CapsuleRepository(session)
        self.state_machine = CapsuleStateMachine()
    
    async def check_and_update_capsules(self) -> dict[str, int]:
        """
        Check all sealed capsules and update statuses as needed.
        
        This is the main entry point for the unlock check cycle.
        It finds all capsules that might need status transitions, checks
        each one, and updates their statuses if needed.
        
        Returns:
            Dictionary with statistics:
            - checked: Number of capsules checked
            - sealed_to_ready: Number of SEALED → READY transitions
            - errors: Number of errors encountered
        
        Note:
            All changes are committed at the end of the cycle
            Errors are logged but don't stop the entire cycle
        """
        logger.info("Starting unlock check cycle")
        
        # ===== Get Capsules to Check =====
        # Get all capsules that might need status updates
        # This includes SEALED capsules with unlocks_at in the past
        capsules = await self.repository.get_capsules_for_unlock()
        
        # ===== Initialize Statistics =====
        # Track transitions and errors for monitoring
        stats = {
            "checked": len(capsules),
            "sealed_to_ready": 0,
            "errors": 0
        }
        
        # ===== Process Each Capsule =====
        # Check each capsule and update status if needed
        for capsule in capsules:
            try:
                await self._update_capsule_status(capsule, stats)
            except Exception as e:
                # Log error but continue processing other capsules
                logger.error(f"Error updating capsule {capsule.id}: {str(e)}")
                stats["errors"] += 1
        
        # ===== Commit Changes =====
        # Commit all status updates in a single transaction
        await self.session.commit()
        
        # ===== Log Results =====
        logger.info(
            f"Unlock check complete: {stats['checked']} checked, "
            f"{stats['sealed_to_ready']} sealed→ready, "
            f"{stats['errors']} errors"
        )
        
        return stats
    
    async def _update_capsule_status(
        self,
        capsule: "Capsule",
        stats: dict[str, int]
    ) -> None:
        """
        Update a single capsule's status if needed.
        
        Checks if the capsule needs a status transition based on time,
        validates the transition, and updates the capsule if needed.
        
        Args:
            capsule: Capsule to check and potentially update
            stats: Statistics dictionary to update with transition counts
        
        Note:
            Uses state machine to determine next status and validate transitions
            Updates statistics for monitoring
            Triggers notification if capsule becomes ready
        """
        current_status = capsule.status
        next_status = self.state_machine.get_next_status(capsule)
        
        # ===== Check if Transition Needed =====
        # If no next status, capsule doesn't need a transition
        if not next_status:
            return  # No transition needed
        
        # ===== Validate Transition =====
        # Ensure transition is valid according to state machine rules
        self.state_machine.validate_transition(current_status, next_status)
        
        # ===== Update Capsule Status =====
        # Update capsule status in database
        await self.repository.transition_status(
            capsule.id,
            next_status
        )
        
        # ===== Update Statistics =====
        # Track transition for monitoring
        transition_key = f"{current_status.value}_to_{next_status.value}"
        if transition_key in stats:
            stats[transition_key] += 1
        
        # ===== Log Transition =====
        logger.info(
            f"Capsule {capsule.id}: {current_status} → {next_status} "
            f"(unlocks_at: {capsule.unlocks_at})"
        )
        
        # ===== Trigger Notification =====
        # If capsule is now ready, notify the recipient
        if next_status.value == "ready":
            await self._notify_ready(capsule)
    
    async def _notify_ready(self, capsule: "Capsule") -> None:
        """
        Send notification that capsule is ready (placeholder for future).
        
        This method is called when a capsule transitions to READY status.
        Currently logs the event, but can be extended to send push notifications,
        emails, or other alerts to the recipient.
        
        Args:
            capsule: Capsule that is now ready
        
        Note:
            This is a placeholder for future notification integration
            TODO: Integrate with notification service (FCM, APNS, email, etc.)
        """
        # TODO: Integrate with notification service
        logger.info(
            f"📬 Notification: Capsule {capsule.id} is ready for "
            f"recipient {capsule.recipient_id}"
        )
        # Future: await notification_service.send_capsule_ready(capsule)


async def run_unlock_check(session: AsyncSession) -> dict[str, int]:
    """
    Run a single unlock check cycle.
    
    This is the entry point called by the background worker.
    Creates a new UnlockService instance and runs the check cycle.
    
    Args:
        session: Async database session
    
    Returns:
        Dictionary with statistics from the unlock check
    
    Note:
        This function is called periodically by the scheduler
        It should be idempotent (safe to call multiple times)
    """
    service = UnlockService(session)
    return await service.check_and_update_capsules()
