"""Tests for capsule state machine."""
import pytest
from datetime import datetime, timedelta
from app.db.models import Capsule, CapsuleState
from app.services.state_machine import CapsuleStateMachine


def create_test_capsule(
    state: CapsuleState = CapsuleState.DRAFT,
    sender_id: str = "sender123",
    receiver_id: str = "receiver123",
    scheduled_unlock_at: datetime = None
) -> Capsule:
    """Helper to create a test capsule object."""
    capsule = Capsule(
        sender_id=sender_id,
        receiver_id=receiver_id,
        title="Test Capsule",
        body="Test body",
        state=state,
        scheduled_unlock_at=scheduled_unlock_at
    )
    return capsule


class TestStateTransitions:
    """Test state machine transitions."""
    
    def test_valid_transitions(self):
        """Test all valid state transitions."""
        assert CapsuleStateMachine.can_transition(
            CapsuleState.DRAFT, CapsuleState.SEALED
        )
        assert CapsuleStateMachine.can_transition(
            CapsuleState.SEALED, CapsuleState.UNFOLDING
        )
        assert CapsuleStateMachine.can_transition(
            CapsuleState.UNFOLDING, CapsuleState.READY
        )
        assert CapsuleStateMachine.can_transition(
            CapsuleState.READY, CapsuleState.OPENED
        )
    
    def test_invalid_transitions(self):
        """Test invalid state transitions are blocked."""
        # Cannot reverse states
        assert not CapsuleStateMachine.can_transition(
            CapsuleState.SEALED, CapsuleState.DRAFT
        )
        assert not CapsuleStateMachine.can_transition(
            CapsuleState.OPENED, CapsuleState.READY
        )
        
        # Cannot skip states
        assert not CapsuleStateMachine.can_transition(
            CapsuleState.DRAFT, CapsuleState.READY
        )
        assert not CapsuleStateMachine.can_transition(
            CapsuleState.SEALED, CapsuleState.READY
        )
        
        # Terminal state cannot transition
        assert not CapsuleStateMachine.can_transition(
            CapsuleState.OPENED, CapsuleState.OPENED
        )
    
    def test_validate_transition_raises(self):
        """Test validate_transition raises on invalid transitions."""
        with pytest.raises(ValueError, match="Invalid state transition"):
            CapsuleStateMachine.validate_transition(
                CapsuleState.SEALED, CapsuleState.DRAFT
            )


class TestNextStateLogic:
    """Test next state determination logic."""
    
    def test_draft_no_transition(self):
        """Draft state should not auto-transition."""
        capsule = create_test_capsule(state=CapsuleState.DRAFT)
        assert CapsuleStateMachine.get_next_state(capsule) is None
    
    def test_opened_no_transition(self):
        """Opened state is terminal."""
        capsule = create_test_capsule(state=CapsuleState.OPENED)
        assert CapsuleStateMachine.get_next_state(capsule) is None
    
    def test_sealed_to_unfolding(self):
        """Sealed should transition to unfolding when < 3 days."""
        unlock_time = datetime.utcnow() + timedelta(days=2)
        capsule = create_test_capsule(
            state=CapsuleState.SEALED,
            scheduled_unlock_at=unlock_time
        )
        assert CapsuleStateMachine.get_next_state(capsule) == CapsuleState.UNFOLDING
    
    def test_sealed_stays_sealed(self):
        """Sealed should stay sealed when > 3 days."""
        unlock_time = datetime.utcnow() + timedelta(days=5)
        capsule = create_test_capsule(
            state=CapsuleState.SEALED,
            scheduled_unlock_at=unlock_time
        )
        assert CapsuleStateMachine.get_next_state(capsule) is None
    
    def test_unfolding_to_ready(self):
        """Unfolding should transition to ready when time arrives."""
        unlock_time = datetime.utcnow() - timedelta(minutes=1)
        capsule = create_test_capsule(
            state=CapsuleState.UNFOLDING,
            scheduled_unlock_at=unlock_time
        )
        assert CapsuleStateMachine.get_next_state(capsule) == CapsuleState.READY
    
    def test_unfolding_stays_unfolding(self):
        """Unfolding should stay unfolding when time hasn't arrived."""
        unlock_time = datetime.utcnow() + timedelta(hours=12)
        capsule = create_test_capsule(
            state=CapsuleState.UNFOLDING,
            scheduled_unlock_at=unlock_time
        )
        assert CapsuleStateMachine.get_next_state(capsule) is None


class TestSealCapsule:
    """Test capsule sealing logic."""
    
    def test_valid_seal(self):
        """Test sealing with valid future time."""
        unlock_time = datetime.utcnow() + timedelta(hours=1)
        result = CapsuleStateMachine.seal_capsule(unlock_time)
        
        assert result["state"] == CapsuleState.SEALED
        assert result["sealed_at"] is not None
        assert result["scheduled_unlock_at"] == unlock_time
    
    def test_seal_too_soon_fails(self):
        """Test sealing with time too soon fails."""
        unlock_time = datetime.utcnow() + timedelta(seconds=30)
        with pytest.raises(ValueError, match="at least"):
            CapsuleStateMachine.seal_capsule(unlock_time)
    
    def test_seal_too_far_fails(self):
        """Test sealing with time too far fails."""
        unlock_time = datetime.utcnow() + timedelta(days=6 * 365)
        with pytest.raises(ValueError, match="cannot be more than"):
            CapsuleStateMachine.seal_capsule(unlock_time)


class TestPermissions:
    """Test permission checks."""
    
    def test_can_edit_draft_as_sender(self):
        """Sender can edit draft."""
        capsule = create_test_capsule(
            state=CapsuleState.DRAFT,
            sender_id="user123"
        )
        can_edit, msg = CapsuleStateMachine.can_edit(capsule, "user123")
        assert can_edit is True
    
    def test_cannot_edit_as_non_sender(self):
        """Non-sender cannot edit."""
        capsule = create_test_capsule(
            state=CapsuleState.DRAFT,
            sender_id="user123"
        )
        can_edit, msg = CapsuleStateMachine.can_edit(capsule, "other_user")
        assert can_edit is False
        assert "Only the sender" in msg
    
    def test_cannot_edit_sealed(self):
        """Cannot edit sealed capsule."""
        capsule = create_test_capsule(
            state=CapsuleState.SEALED,
            sender_id="user123"
        )
        can_edit, msg = CapsuleStateMachine.can_edit(capsule, "user123")
        assert can_edit is False
        assert "Cannot edit" in msg
    
    def test_can_open_as_receiver_when_ready(self):
        """Receiver can open ready capsule."""
        capsule = create_test_capsule(
            state=CapsuleState.READY,
            receiver_id="user123"
        )
        can_open, msg = CapsuleStateMachine.can_open(capsule, "user123")
        assert can_open is True
    
    def test_cannot_open_as_sender(self):
        """Sender cannot open capsule."""
        capsule = create_test_capsule(
            state=CapsuleState.READY,
            sender_id="user123",
            receiver_id="other_user"
        )
        can_open, msg = CapsuleStateMachine.can_open(capsule, "user123")
        assert can_open is False
        assert "Only the receiver" in msg
    
    def test_cannot_open_not_ready(self):
        """Cannot open capsule that's not ready."""
        capsule = create_test_capsule(
            state=CapsuleState.SEALED,
            receiver_id="user123"
        )
        can_open, msg = CapsuleStateMachine.can_open(capsule, "user123")
        assert can_open is False
        assert "not ready yet" in msg


class TestViewPermissions:
    """Test view permission checks."""
    
    def test_sender_can_always_view(self):
        """Sender can view in any state."""
        for state in [CapsuleState.DRAFT, CapsuleState.SEALED, CapsuleState.READY]:
            capsule = create_test_capsule(
                state=state,
                sender_id="user123"
            )
            can_view, msg = CapsuleStateMachine.can_view(capsule, "user123")
            assert can_view is True
    
    def test_receiver_can_view_opened(self):
        """Receiver can view opened capsule."""
        capsule = create_test_capsule(
            state=CapsuleState.OPENED,
            receiver_id="user123"
        )
        can_view, msg = CapsuleStateMachine.can_view(capsule, "user123")
        assert can_view is True
    
    def test_receiver_cannot_view_sealed(self):
        """Receiver cannot view sealed capsule."""
        capsule = create_test_capsule(
            state=CapsuleState.SEALED,
            receiver_id="user123"
        )
        capsule.allow_early_view = False
        can_view, msg = CapsuleStateMachine.can_view(capsule, "user123")
        assert can_view is False
    
    def test_receiver_can_view_with_early_view(self):
        """Receiver can view unfolding/ready if early_view enabled."""
        capsule = create_test_capsule(
            state=CapsuleState.UNFOLDING,
            receiver_id="user123"
        )
        capsule.allow_early_view = True
        can_view, msg = CapsuleStateMachine.can_view(capsule, "user123")
        assert can_view is True
