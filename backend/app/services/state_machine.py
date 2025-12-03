"""
Capsule state machine and time-lock engine.

This module implements the state machine that controls capsule lifecycle transitions.
It enforces business rules and prevents invalid state changes.

State Flow:
    DRAFT → SEALED → UNFOLDING → READY → OPENED
      ↓        ↓          ↓         ↓        ↓
    (editable) (locked) (teaser) (openable) (terminal)

Key Rules:
- States cannot be reversed
- Unlock time cannot be changed after sealing
- All timestamps are UTC (prevents timezone manipulation)
- State transitions are time-based and automatic
"""
from datetime import datetime, timedelta, timezone
from typing import Optional
from app.db.models import Capsule, CapsuleState
from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger(__name__)


class CapsuleStateMachine:
    """
    State machine for capsule transitions.
    
    This class enforces the capsule lifecycle and prevents invalid state changes.
    It validates permissions, timestamps, and business rules.
    
    States and transitions:
    - DRAFT → SEALED: When unlock time is set (manual)
    - SEALED → UNFOLDING: When unlock time < 3 days (automatic)
    - UNFOLDING → READY: When unlock time arrives (automatic)
    - READY → OPENED: When receiver opens (manual)
    
    Rules:
    - Cannot reverse states
    - Cannot change unlock time after sealing
    - All timestamps use UTC
    - Time-based transitions are automatic (via background worker)
    """
    
    # Valid state transitions - defines allowed state changes
    # Each state can only transition to states in its list
    # Empty list means terminal state (no further transitions)
    VALID_TRANSITIONS = {
        CapsuleState.DRAFT: [CapsuleState.SEALED],  # Can only be sealed
        CapsuleState.SEALED: [CapsuleState.UNFOLDING],  # Auto-transitions when < 3 days
        CapsuleState.UNFOLDING: [CapsuleState.READY],  # Auto-transitions when time arrives
        CapsuleState.READY: [CapsuleState.OPENED],  # Can be opened by receiver
        CapsuleState.OPENED: [],  # Terminal state - no further transitions
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
        
        This method is called by the background worker to automatically
        transition capsules based on their unlock time.
        
        Args:
            capsule: The capsule to check for state transitions
        
        Returns:
            Next state if transition is needed, None otherwise
        
        Business Logic:
        - SEALED → UNFOLDING: When unlock time is < 3 days away
        - UNFOLDING → READY: When unlock time has arrived
        - DRAFT and OPENED: No automatic transitions
        """
        now = datetime.now(timezone.utc)
        
        # ===== Terminal States =====
        # DRAFT: Manual transition only (user must seal)
        # OPENED: Terminal state - no further transitions
        if capsule.state in [CapsuleState.DRAFT, CapsuleState.OPENED]:
            return None
        
        # ===== Unlock Time Check =====
        # Can't transition without a scheduled unlock time
        if not capsule.scheduled_unlock_at:
            return None
        
        # ===== Timezone Normalization =====
        # Ensure unlock_time is timezone-aware (UTC)
        # This prevents timezone manipulation attacks
        # All comparisons use UTC to ensure consistency
        unlock_time = capsule.scheduled_unlock_at
        if unlock_time.tzinfo is None:
            # If naive datetime, assume it's UTC
            unlock_time = unlock_time.replace(tzinfo=timezone.utc)
        else:
            # Convert to UTC if it has a different timezone
            unlock_time = unlock_time.astimezone(timezone.utc)
        
        # Calculate time remaining until unlock
        time_until_unlock = unlock_time - now
        
        # ===== SEALED → UNFOLDING Transition =====
        # Transition when unlock time is less than threshold days away
        # This creates anticipation as unlock time approaches
        if capsule.state == CapsuleState.SEALED:
            threshold = timedelta(days=settings.early_view_threshold_days)
            if time_until_unlock <= threshold:
                logger.info(f"Capsule {capsule.id} entering unfolding state")
                return CapsuleState.UNFOLDING
        
        # ===== UNFOLDING → READY Transition =====
        # Transition when unlock time has arrived
        # Capsule is now ready to be opened by receiver
        elif capsule.state == CapsuleState.UNFOLDING:
            if now >= unlock_time:
                logger.info(f"Capsule {capsule.id} is now ready")
                return CapsuleState.READY
        
        # No transition needed
        return None
    
    @classmethod
    def seal_capsule(cls, scheduled_unlock_at: datetime) -> dict:
        """
        Prepare capsule for sealing with validation.
        
        This method validates the unlock time and prepares the capsule
        for transition from DRAFT to SEALED state.
        
        Args:
            scheduled_unlock_at: The datetime when the capsule should unlock
        
        Returns:
            Dictionary with state, sealed_at timestamp, and scheduled_unlock_at
        
        Raises:
            ValueError: If unlock time is invalid (past, too soon, or too far)
        
        Validation Rules:
        - Unlock time must be at least min_unlock_minutes in the future
        - Unlock time cannot be more than max_unlock_years in the future
        - All times are normalized to UTC
        """
        now = datetime.now(timezone.utc)
        
        # ===== Timezone Normalization =====
        # Ensure scheduled_unlock_at is timezone-aware (UTC)
        # This prevents timezone manipulation and ensures consistent comparisons
        if scheduled_unlock_at.tzinfo is None:
            # If naive datetime, assume it's UTC
            scheduled_unlock_at = scheduled_unlock_at.replace(tzinfo=timezone.utc)
        else:
            # Convert to UTC if it has a different timezone
            scheduled_unlock_at = scheduled_unlock_at.astimezone(timezone.utc)
        
        # ===== Minimum Future Time Validation =====
        # Unlock time must be at least min_unlock_minutes in the future
        # This prevents setting unlock times in the past or too soon
        min_future = now + timedelta(minutes=settings.min_unlock_minutes)
        if scheduled_unlock_at <= min_future:
            raise ValueError(
                f"Unlock time must be at least {settings.min_unlock_minutes} minute(s) in the future"
            )
        
        # ===== Maximum Future Time Validation =====
        # Unlock time cannot be more than max_unlock_years in the future
        # This prevents extremely long lock times and database bloat
        max_future = now + timedelta(days=settings.max_unlock_years * 365)
        if scheduled_unlock_at > max_future:
            raise ValueError(
                f"Unlock time cannot be more than {settings.max_unlock_years} years in the future"
            )
        
        # ===== Return Seal Data =====
        # Return dictionary with state transition data
        # This will be used to update the capsule in the database
        return {
            "state": CapsuleState.SEALED,
            "sealed_at": now,  # Record when capsule was sealed
            "scheduled_unlock_at": scheduled_unlock_at  # Normalized UTC datetime
        }
    
    @classmethod
    def can_edit(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """
        Check if a capsule can be edited.
        
        Args:
            capsule: The capsule to check
            user_id: The user ID requesting edit permission
        
        Returns:
            Tuple of (can_edit: bool, message: str)
        
        Rules:
        - Only sender can edit
        - Only DRAFT state can be edited
        - Once sealed, no edits are allowed
        """
        # ===== Ownership Check =====
        # Only the sender can edit their own capsules
        if capsule.sender_id != user_id:
            return False, "Only the sender can edit this capsule"
        
        # ===== State Check =====
        # Can only edit capsules in DRAFT state
        # Once sealed, content cannot be changed (time-lock integrity)
        if capsule.state != CapsuleState.DRAFT:
            return False, f"Cannot edit capsule in {capsule.state} state"
        
        return True, "OK"
    
    @classmethod
    def can_seal(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """
        Check if a capsule can be sealed.
        
        Args:
            capsule: The capsule to check
            user_id: The user ID requesting seal permission
        
        Returns:
            Tuple of (can_seal: bool, message: str)
        
        Rules:
        - Only sender can seal
        - Only DRAFT state can be sealed
        - Sealing is irreversible
        """
        # ===== Ownership Check =====
        # Only the sender can seal their own capsules
        if capsule.sender_id != user_id:
            return False, "Only the sender can seal this capsule"
        
        # ===== State Check =====
        # Can only seal capsules in DRAFT state
        # Once sealed, cannot be re-sealed
        if capsule.state != CapsuleState.DRAFT:
            return False, f"Cannot seal capsule in {capsule.state} state"
        
        return True, "OK"
    
    @classmethod
    def can_open(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """
        Check if a capsule can be opened.
        
        Args:
            capsule: The capsule to check
            user_id: The user ID requesting open permission
        
        Returns:
            Tuple of (can_open: bool, message: str)
        
        Rules:
        - Only receiver can open
        - Capsule must be in READY state
        - Cannot reopen already opened capsules
        """
        # ===== Ownership Check =====
        # Only the receiver can open capsules sent to them
        if capsule.receiver_id != user_id:
            return False, "Only the receiver can open this capsule"
        
        # ===== State Check =====
        # Cannot open already opened capsules (terminal state)
        if capsule.state == CapsuleState.OPENED:
            return False, "Capsule is already opened"
        
        # ===== Readiness Check =====
        # Capsule must be in READY state to be opened
        # This ensures unlock time has arrived
        if capsule.state != CapsuleState.READY:
            return False, f"Capsule is not ready yet (current state: {capsule.state})"
        
        return True, "OK"
    
    @classmethod
    def can_view(cls, capsule: Capsule, user_id: str) -> tuple[bool, str]:
        """
        Check if a user can view a capsule's contents.
        
        Args:
            capsule: The capsule to check
            user_id: The user ID requesting view permission
        
        Returns:
            Tuple of (can_view: bool, message: str)
        
        Rules:
        - Sender can always view
        - Receiver can view if:
          * Capsule is OPENED, OR
          * allow_early_view is true and state is UNFOLDING/READY
        - Others cannot view
        """
        # ===== Sender Permission =====
        # Sender can always view their sent capsules
        # This allows senders to review what they sent
        if capsule.sender_id == user_id:
            return True, "OK"
        
        # ===== Receiver Permission =====
        # Receiver can view under specific conditions
        if capsule.receiver_id == user_id:
            # Can always view opened capsules
            if capsule.state == CapsuleState.OPENED:
                return True, "OK"
            
            # Can view early if allow_early_view is enabled and state allows it
            # This enables "teaser" functionality for unfolding/ready capsules
            if capsule.allow_early_view and capsule.state in [
                CapsuleState.UNFOLDING,
                CapsuleState.READY
            ]:
                return True, "OK"
            
            # Otherwise, capsule is not ready to view
            return False, f"Capsule is not ready yet (current state: {capsule.state})"
        
        # ===== Unauthorized Access =====
        # Users who are neither sender nor receiver cannot view
        return False, "You do not have permission to view this capsule"
