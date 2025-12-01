"""Capsule state machine and time-lock engine."""
from datetime import datetime, timedelta, timezone
from typing import Optional
from app.db.models import Capsule, CapsuleState
from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger(__name__)


class CapsuleStateMachine:
    """
    State machine for capsule transitions.
    
    States and transitions:
    draft → sealed (when unlock time is set)
    sealed → unfolding (when unlock time < 3 days)
    unfolding → ready (when unlock time arrives)
    ready → opened (when user opens)
    
    Rules:
    - Cannot reverse states
    - Cannot change unlock time after sealing
    - All timestamps use UTC
    """
    
    VALID_TRANSITIONS = {
        CapsuleState.DRAFT: [CapsuleState.SEALED],
        CapsuleState.SEALED: [CapsuleState.UNFOLDING],
        CapsuleState.UNFOLDING: [CapsuleState.READY],
        CapsuleState.READY: [CapsuleState.OPENED],
        CapsuleState.OPENED: [],  # Terminal state
    }
    
    @classmethod
    def can_transition(cls, from_state: CapsuleState, to_state: CapsuleState) -> bool:
        """Check if state transition is valid."""
        return to_state in cls.VALID_TRANSITIONS.get(from_state, [])
    
    @classmethod
    def validate_transition(cls, from_state: CapsuleState, to_state: CapsuleState) -> None:
        """Validate state transition or raise error."""
        if not cls.can_transition(from_state, to_state):
            raise ValueError(
                f"Invalid state transition: {from_state} → {to_state}. "
                f"Valid transitions from {from_state}: {cls.VALID_TRANSITIONS.get(from_state, [])}"
            )
    
    @classmethod
    def get_next_state(cls, capsule: Capsule) -> Optional[CapsuleState]:
        """
        Determine the next state for a capsule based on time.
        Returns None if no transition is needed.
        """
        now = datetime.now(timezone.utc)
        
        # Terminal states don't transition
        if capsule.state in [CapsuleState.DRAFT, CapsuleState.OPENED]:
            return None
        
        # Can't transition without unlock time
        if not capsule.scheduled_unlock_at:
            return None
        
        unlock_time = capsule.scheduled_unlock_at
        time_until_unlock = unlock_time - now
        
        # sealed → unfolding (less than 3 days)
        if capsule.state == CapsuleState.SEALED:
            threshold = timedelta(days=settings.early_view_threshold_days)
            if time_until_unlock <= threshold:
                logger.info(f"Capsule {capsule.id} entering unfolding state")
                return CapsuleState.UNFOLDING
        
        # unfolding → ready (time has arrived)
        elif capsule.state == CapsuleState.UNFOLDING:
            if now >= unlock_time:
                logger.info(f"Capsule {capsule.id} is now ready")
                return CapsuleState.READY
        
        return None
    
    @classmethod
    def seal_capsule(cls, scheduled_unlock_at: datetime) -> dict:
        """
        Prepare capsule for sealing with validation.
        Returns dict with state and timestamp.
        """
        now = datetime.now(timezone.utc)
        
        # Validate unlock time
        min_future = now + timedelta(minutes=settings.min_unlock_minutes)
        if scheduled_unlock_at <= min_future:
            raise ValueError(
                f"Unlock time must be at least {settings.min_unlock_minutes} minute(s) in the future"
            )
        
        max_future = now + timedelta(days=settings.max_unlock_years * 365)
        if scheduled_unlock_at > max_future:
            raise ValueError(
                f"Unlock time cannot be more than {settings.max_unlock_years} years in the future"
            )
        
        return {
            "state": CapsuleState.SEALED,
            "sealed_at": now,
            "scheduled_unlock_at": scheduled_unlock_at
        }
    
    @classmethod
    def can_edit(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """Check if a capsule can be edited."""
        # Only sender can edit
        if capsule.sender_id != user_id:
            return False, "Only the sender can edit this capsule"
        
        # Can only edit drafts
        if capsule.state != CapsuleState.DRAFT:
            return False, f"Cannot edit capsule in {capsule.state} state"
        
        return True, "OK"
    
    @classmethod
    def can_seal(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """Check if a capsule can be sealed."""
        # Only sender can seal
        if capsule.sender_id != user_id:
            return False, "Only the sender can seal this capsule"
        
        # Can only seal drafts
        if capsule.state != CapsuleState.DRAFT:
            return False, f"Cannot seal capsule in {capsule.state} state"
        
        return True, "OK"
    
    @classmethod
    def can_open(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """Check if a capsule can be opened."""
        # Only receiver can open
        if capsule.receiver_id != user_id:
            return False, "Only the receiver can open this capsule"
        
        # Must be in ready state
        if capsule.state == CapsuleState.OPENED:
            return False, "Capsule is already opened"
        
        if capsule.state != CapsuleState.READY:
            return False, f"Capsule is not ready yet (current state: {capsule.state})"
        
        return True, "OK"
    
    @classmethod
    def can_view(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """Check if a user can view a capsule's contents."""
        # Sender can always view
        if capsule.sender_id == user_id:
            return True, "OK"
        
        # Receiver can view if opened
        if capsule.receiver_id == user_id:
            if capsule.state == CapsuleState.OPENED:
                return True, "OK"
            
            # Or if early view is allowed and state is unfolding/ready
            if capsule.allow_early_view and capsule.state in [
                CapsuleState.UNFOLDING,
                CapsuleState.READY
            ]:
                return True, "OK"
            
            return False, f"Capsule is not ready yet (current state: {capsule.state})"
        
        # Others cannot view
        return False, "You do not have permission to view this capsule"
