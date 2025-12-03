"""
Time-lock unlock service for automated capsule state transitions.

This service handles automatic state transitions for capsules based on time.
It's called periodically by the background worker to check if any capsules
need to transition states (e.g., SEALED → UNFOLDING → READY).

State Transitions:
- SEALED → UNFOLDING: When unlock time is within 3 days
- UNFOLDING → READY: When unlock time has arrived

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
    Service for checking and updating capsule unlock states.
    
    This service periodically checks all capsules that might need state
    transitions and updates them based on their scheduled unlock time.
    
    Responsibilities:
    - Check capsules for state transitions
    - Update capsule states via state machine
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
        Check all sealed/unfolding capsules and update states as needed.
        
        This is the main entry point for the unlock check cycle.
        It finds all capsules that might need state transitions, checks
        each one, and updates their states if needed.
        
        Returns:
            Dictionary with statistics:
            - checked: Number of capsules checked
            - sealed_to_unfolding: Number of SEALED → UNFOLDING transitions
            - unfolding_to_ready: Number of UNFOLDING → READY transitions
            - errors: Number of errors encountered
        
        Note:
            All changes are committed at the end of the cycle
            Errors are logged but don't stop the entire cycle
        """
        logger.info("Starting unlock check cycle")
        
        # ===== Get Capsules to Check =====
        # Get all capsules that might need state updates
        # This includes SEALED and UNFOLDING capsules
        capsules = await self.repository.get_capsules_for_unlock()
        
        # ===== Initialize Statistics =====
        # Track transitions and errors for monitoring
        stats = {
            "checked": len(capsules),
            "sealed_to_unfolding": 0,
            "unfolding_to_ready": 0,
            "errors": 0
        }
        
        # ===== Process Each Capsule =====
        # Check each capsule and update state if needed
        for capsule in capsules:
            try:
                await self._update_capsule_state(capsule, stats)
            except Exception as e:
                # Log error but continue processing other capsules
                logger.error(f"Error updating capsule {capsule.id}: {str(e)}")
                stats["errors"] += 1
        
        # ===== Commit Changes =====
        # Commit all state updates in a single transaction
        await self.session.commit()
        
        # ===== Log Results =====
        logger.info(
            f"Unlock check complete: {stats['checked']} checked, "
            f"{stats['sealed_to_unfolding']} sealed→unfolding, "
            f"{stats['unfolding_to_ready']} unfolding→ready, "
            f"{stats['errors']} errors"
        )
        
        return stats
    
    async def _update_capsule_state(
        self,
        capsule: "Capsule",
        stats: dict[str, int]
    ) -> None:
        """
        Update a single capsule's state if needed.
        
        Checks if the capsule needs a state transition based on time,
        validates the transition, and updates the capsule if needed.
        
        Args:
            capsule: Capsule to check and potentially update
            stats: Statistics dictionary to update with transition counts
        
        Note:
            Uses state machine to determine next state and validate transitions
            Updates statistics for monitoring
            Triggers notification if capsule becomes ready
        """
        current_state = capsule.state
        next_state = self.state_machine.get_next_state(capsule)
        
        # ===== Check if Transition Needed =====
        # If no next state, capsule doesn't need a transition
        if not next_state:
            return  # No transition needed
        
        # ===== Validate Transition =====
        # Ensure transition is valid according to state machine rules
        self.state_machine.validate_transition(current_state, next_state)
        
        # ===== Update Capsule State =====
        # Update capsule state in database
        await self.repository.transition_state(
            capsule.id,
            next_state
        )
        
        # ===== Update Statistics =====
        # Track transition for monitoring
        transition_key = f"{current_state.value}_to_{next_state.value}"
        if transition_key in stats:
            stats[transition_key] += 1
        
        # ===== Log Transition =====
        logger.info(
            f"Capsule {capsule.id}: {current_state} → {next_state} "
            f"(unlock: {capsule.scheduled_unlock_at})"
        )
        
        # ===== Trigger Notification =====
        # If capsule is now ready, notify the receiver
        if next_state.value == "ready":
            await self._notify_ready(capsule)
    
    async def _notify_ready(self, capsule: "Capsule") -> None:
        """
        Send notification that capsule is ready (placeholder for future).
        
        This method is called when a capsule transitions to READY state.
        Currently logs the event, but can be extended to send push notifications,
        emails, or other alerts to the receiver.
        
        Args:
            capsule: Capsule that is now ready
        
        Note:
            This is a placeholder for future notification integration
            TODO: Integrate with notification service (FCM, APNS, email, etc.)
        """
        # TODO: Integrate with notification service
        logger.info(
            f"📬 Notification: Capsule {capsule.id} is ready for "
            f"receiver {capsule.receiver_id}"
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
