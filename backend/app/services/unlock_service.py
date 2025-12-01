"""Time-lock unlock service for automated capsule state transitions."""
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.repositories import CapsuleRepository
from app.services.state_machine import CapsuleStateMachine
from app.core.logging import get_logger


logger = get_logger(__name__)


class UnlockService:
    """Service for checking and updating capsule unlock states."""
    
    def __init__(self, session: AsyncSession):
        """Initialize unlock service with database session."""
        self.session = session
        self.repository = CapsuleRepository(session)
        self.state_machine = CapsuleStateMachine()
    
    async def check_and_update_capsules(self) -> dict[str, int]:
        """
        Check all sealed/unfolding capsules and update states as needed.
        Returns dict with counts of updated capsules by transition type.
        """
        logger.info("Starting unlock check cycle")
        
        # Get all capsules that might need state updates
        capsules = await self.repository.get_capsules_for_unlock()
        
        stats = {
            "checked": len(capsules),
            "sealed_to_unfolding": 0,
            "unfolding_to_ready": 0,
            "errors": 0
        }
        
        for capsule in capsules:
            try:
                await self._update_capsule_state(capsule, stats)
            except Exception as e:
                logger.error(f"Error updating capsule {capsule.id}: {str(e)}")
                stats["errors"] += 1
        
        # Commit all changes
        await self.session.commit()
        
        logger.info(
            f"Unlock check complete: {stats['checked']} checked, "
            f"{stats['sealed_to_unfolding']} sealed→unfolding, "
            f"{stats['unfolding_to_ready']} unfolding→ready, "
            f"{stats['errors']} errors"
        )
        
        return stats
    
    async def _update_capsule_state(
        self,
        capsule,
        stats: dict[str, int]
    ) -> None:
        """Update a single capsule's state if needed."""
        current_state = capsule.state
        next_state = self.state_machine.get_next_state(capsule)
        
        if not next_state:
            return  # No transition needed
        
        # Validate transition
        self.state_machine.validate_transition(current_state, next_state)
        
        # Update capsule state
        await self.repository.transition_state(
            capsule.id,
            next_state
        )
        
        # Update statistics
        transition_key = f"{current_state.value}_to_{next_state.value}"
        if transition_key in stats:
            stats[transition_key] += 1
        
        logger.info(
            f"Capsule {capsule.id}: {current_state} → {next_state} "
            f"(unlock: {capsule.scheduled_unlock_at})"
        )
        
        # Trigger notification if capsule is now ready
        if next_state.value == "ready":
            await self._notify_ready(capsule)
    
    async def _notify_ready(self, capsule) -> None:
        """Send notification that capsule is ready (placeholder for future)."""
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
    """
    service = UnlockService(session)
    return await service.check_and_update_capsules()
