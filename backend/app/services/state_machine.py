"""
Capsule state machine matching Supabase schema.

This module implements the state machine that controls capsule lifecycle transitions.
It enforces business rules and prevents invalid state changes.

State Flow (Supabase):
    SEALED → READY → OPENED
      ↓        ↓        ↓
  (locked) (openable) (terminal)

Key Rules:
- States cannot be reversed
- All timestamps are UTC (prevents timezone manipulation)
- State transitions are time-based and automatic
- Capsules are created in 'sealed' status (no draft state)
"""
from datetime import datetime, timezone
from typing import Optional
from app.db.models import Capsule, CapsuleStatus
from app.core.logging import get_logger


logger = get_logger(__name__)


class CapsuleStateMachine:
    """
    State machine for capsule transitions matching Supabase schema.
    
    This class enforces the capsule lifecycle and prevents invalid state changes.
    It validates permissions, timestamps, and business rules.
    
    States and transitions (Supabase):
    - SEALED → READY: When unlocks_at time passes (automatic)
    - READY → OPENED: When recipient opens (manual)
    - OPENED: Terminal state - no further transitions
    - EXPIRED: Soft-deleted or expired capsules
    
    Rules:
    - Cannot reverse states
    - All timestamps use UTC
    - Time-based transitions are automatic (via background worker or triggers)
    """
    
    # Valid state transitions - defines allowed state changes
    # Each state can only transition to states in its list
    # Empty list means terminal state (no further transitions)
    VALID_TRANSITIONS = {
        CapsuleStatus.SEALED: [CapsuleStatus.READY],  # Auto-transitions when unlocks_at passes
        CapsuleStatus.READY: [CapsuleStatus.OPENED],  # Can be opened by recipient
        CapsuleStatus.OPENED: [],  # Terminal state - no further transitions
        CapsuleStatus.EXPIRED: [],  # Terminal state - no further transitions
    }
    
    @classmethod
    def can_transition(cls, from_status: CapsuleStatus, to_status: CapsuleStatus) -> bool:
        """Check if state transition is valid."""
        return to_status in cls.VALID_TRANSITIONS.get(from_status, [])
    
    @classmethod
    def validate_transition(cls, from_status: CapsuleStatus, to_status: CapsuleStatus) -> None:
        """Validate state transition or raise error."""
        if not cls.can_transition(from_status, to_status):
            raise ValueError(
                f"Invalid state transition: {from_status} → {to_status}. "
                f"Valid transitions from {from_status}: {cls.VALID_TRANSITIONS.get(from_status, [])}"
            )
    
    @classmethod
    def get_next_status(cls, capsule: Capsule) -> Optional[CapsuleStatus]:
        """
        Determine the next status for a capsule based on time.
        
        This method is called by the background worker to automatically
        transition capsules based on their unlock time.
        
        Args:
            capsule: The capsule to check for state transitions
        
        Returns:
            Next status if transition is needed, None otherwise
        
        Business Logic:
        - SEALED → READY: When unlocks_at has passed
        - READY and OPENED: No automatic transitions
        """
        now = datetime.now(timezone.utc)
        
        # ===== Terminal States =====
        # OPENED and EXPIRED are terminal states - no further transitions
        if capsule.status in [CapsuleStatus.OPENED, CapsuleStatus.EXPIRED]:
            return None
        
        # ===== Unlock Time Check =====
        # Can't transition without an unlock time
        if not capsule.unlocks_at:
            return None
        
        # ===== Timezone Normalization =====
        # Ensure unlocks_at is timezone-aware (UTC)
        # This prevents timezone manipulation attacks
        unlock_time = capsule.unlocks_at
        if unlock_time.tzinfo is None:
            # If naive datetime, assume it's UTC
            unlock_time = unlock_time.replace(tzinfo=timezone.utc)
        else:
            # Convert to UTC if it has a different timezone
            unlock_time = unlock_time.astimezone(timezone.utc)
        
        # ===== SEALED → READY Transition =====
        # Transition when unlock time has arrived
        # Capsule is now ready to be opened by recipient
        if capsule.status == CapsuleStatus.SEALED:
            if now >= unlock_time:
                logger.info(f"Capsule {capsule.id} is now ready (unlocks_at: {unlock_time})")
                return CapsuleStatus.READY
        
        # No transition needed
        return None
    
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
        - Can edit if status is SEALED or READY (before opening)
        - Cannot edit after opening
        """
        # ===== Ownership Check =====
        # Only the sender can edit their own capsules
        if capsule.sender_id != user_id:
            return False, "Only the sender can edit this capsule"
        
        # ===== Status Check =====
        # Can edit capsules in SEALED or READY status (before opening)
        # Once opened, content cannot be changed
        if capsule.status == CapsuleStatus.OPENED:
            return False, "Cannot edit capsule that has been opened"
        
        if capsule.status == CapsuleStatus.EXPIRED:
            return False, "Cannot edit expired capsule"
        
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
        - Only recipient owner can open
        - Capsule must be in READY status
        - Cannot reopen already opened capsules
        """
        # ===== Status Check =====
        # Cannot open already opened capsules (terminal state)
        if capsule.status == CapsuleStatus.OPENED:
            return False, "Capsule is already opened"
        
        if capsule.status == CapsuleStatus.EXPIRED:
            return False, "Capsule has expired"
        
        # ===== Readiness Check =====
        # Capsule must be in READY status to be opened
        # This ensures unlock time has arrived
        if capsule.status != CapsuleStatus.READY:
            return False, f"Capsule is not ready yet (current status: {capsule.status.value})"
        
        # Note: Recipient ownership is checked in the API endpoint
        # This method only checks status-based rules
        
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
        - Recipient can view if status is READY or OPENED
        - Others cannot view
        """
        # ===== Sender Permission =====
        # Sender can always view their sent capsules
        # This allows senders to review what they sent
        if capsule.sender_id == user_id:
            return True, "OK"
        
        # ===== Recipient Permission =====
        # Recipient can view if status is READY or OPENED
        # Note: Recipient ownership is checked in the API endpoint
        # This method only checks status-based rules
        if capsule.status in [CapsuleStatus.READY, CapsuleStatus.OPENED]:
            return True, "OK"
        
        # ===== Not Ready =====
        # Capsule is not ready to view yet
        return False, f"Capsule is not ready yet (current status: {capsule.status.value})"
