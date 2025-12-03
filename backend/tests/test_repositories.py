"""Tests for database repositories."""
import pytest
from datetime import datetime, timedelta
from app.db.repositories import CapsuleRepository, DraftRepository, UserRepository
from app.db.models import CapsuleState


@pytest.mark.asyncio
class TestUserRepository:
    """Test user repository operations."""
    
    async def test_create_user(self, test_session):
        """Test creating a user."""
        repo = UserRepository(test_session)
        user = await repo.create(
            email="newuser@example.com",
            username="newuser",
            hashed_password="hashed_pass",
            full_name="New User"
        )
        
        assert user.id is not None
        assert user.email == "newuser@example.com"
        assert user.username == "newuser"
    
    async def test_get_by_email(self, test_session, test_user):
        """Test getting user by email."""
        repo = UserRepository(test_session)
        user = await repo.get_by_email(test_user.email)
        
        assert user is not None
        assert user.id == test_user.id
    
    async def test_get_by_username(self, test_session, test_user):
        """Test getting user by username."""
        repo = UserRepository(test_session)
        user = await repo.get_by_username(test_user.username)
        
        assert user is not None
        assert user.id == test_user.id
    
    async def test_email_exists(self, test_session, test_user):
        """Test checking if email exists."""
        repo = UserRepository(test_session)
        
        assert await repo.email_exists(test_user.email) is True
        assert await repo.email_exists("nonexistent@example.com") is False
    
    async def test_username_exists(self, test_session, test_user):
        """Test checking if username exists."""
        repo = UserRepository(test_session)
        
        assert await repo.username_exists(test_user.username) is True
        assert await repo.username_exists("nonexistent") is False


@pytest.mark.asyncio
class TestCapsuleRepository:
    """Test capsule repository operations."""
    
    async def test_create_capsule(self, test_session, test_user, test_user2):
        """Test creating a capsule."""
        repo = CapsuleRepository(test_session)
        capsule = await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Test Capsule",
            body="Test body",
            state=CapsuleState.DRAFT
        )
        
        assert capsule.id is not None
        assert capsule.sender_id == test_user.id
        assert capsule.receiver_id == test_user2.id
        assert capsule.state == CapsuleState.DRAFT
    
    async def test_get_by_sender(self, test_session, test_user, test_user2):
        """Test getting capsules by sender."""
        repo = CapsuleRepository(test_session)
        
        # Create multiple capsules
        await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule 1",
            body="Body 1",
            state=CapsuleState.DRAFT
        )
        await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule 2",
            body="Body 2",
            state=CapsuleState.SEALED
        )
        
        # Get all
        capsules = await repo.get_by_sender(test_user.id)
        assert len(capsules) == 2
        
        # Get by state
        drafts = await repo.get_by_sender(test_user.id, state=CapsuleState.DRAFT)
        assert len(drafts) == 1
        assert drafts[0].state == CapsuleState.DRAFT
    
    async def test_get_by_receiver(self, test_session, test_user, test_user2):
        """Test getting capsules by receiver."""
        repo = CapsuleRepository(test_session)
        
        await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule",
            body="Body",
            state=CapsuleState.READY
        )
        
        capsules = await repo.get_by_receiver(test_user2.id)
        assert len(capsules) == 1
        assert capsules[0].receiver_id == test_user2.id
    
    async def test_transition_state(self, test_session, test_user, test_user2):
        """Test transitioning capsule state."""
        repo = CapsuleRepository(test_session)
        
        capsule = await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule",
            body="Body",
            state=CapsuleState.DRAFT
        )
        
        # Transition to sealed
        updated = await repo.transition_state(
            capsule.id,
            CapsuleState.SEALED,
            sealed_at=datetime.utcnow()
        )
        
        assert updated.state == CapsuleState.SEALED
        assert updated.sealed_at is not None
    
    async def test_verify_ownership(self, test_session, test_user, test_user2):
        """Test verifying capsule ownership."""
        repo = CapsuleRepository(test_session)
        
        capsule = await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule",
            body="Body",
            state=CapsuleState.DRAFT
        )
        
        assert await repo.verify_ownership(capsule.id, test_user.id) is True
        assert await repo.verify_ownership(capsule.id, test_user2.id) is False
    
    async def test_can_open(self, test_session, test_user, test_user2):
        """Test checking if user can open capsule."""
        repo = CapsuleRepository(test_session)
        
        capsule = await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule",
            body="Body",
            state=CapsuleState.READY
        )
        
        # Receiver can open
        can_open, msg = await repo.can_open(capsule.id, test_user2.id)
        assert can_open is True
        
        # Sender cannot open
        can_open, msg = await repo.can_open(capsule.id, test_user.id)
        assert can_open is False
    
    async def test_get_capsules_for_unlock(self, test_session, test_user, test_user2):
        """Test getting capsules that need unlock checking."""
        repo = CapsuleRepository(test_session)
        
        # Create sealed capsule
        await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Capsule",
            body="Body",
            state=CapsuleState.SEALED,
            scheduled_unlock_at=datetime.utcnow() + timedelta(days=1)
        )
        
        # Create draft (should not be included)
        await repo.create(
            sender_id=test_user.id,
            receiver_id=test_user2.id,
            title="Draft",
            body="Body",
            state=CapsuleState.DRAFT
        )
        
        capsules = await repo.get_capsules_for_unlock()
        assert len(capsules) == 1
        assert capsules[0].state == CapsuleState.SEALED


@pytest.mark.asyncio
class TestDraftRepository:
    """Test draft repository operations."""
    
    async def test_create_draft(self, test_session, test_user):
        """Test creating a draft."""
        repo = DraftRepository(test_session)
        draft = await repo.create(
            owner_id=test_user.id,
            title="Draft Title",
            body="Draft body"
        )
        
        assert draft.id is not None
        assert draft.owner_id == test_user.id
        assert draft.title == "Draft Title"
    
    async def test_get_by_owner(self, test_session, test_user):
        """Test getting drafts by owner."""
        repo = DraftRepository(test_session)
        
        # Create multiple drafts
        await repo.create(owner_id=test_user.id, title="Draft 1", body="Body 1")
        await repo.create(owner_id=test_user.id, title="Draft 2", body="Body 2")
        
        drafts = await repo.get_by_owner(test_user.id)
        assert len(drafts) == 2
    
    async def test_update_draft(self, test_session, test_user):
        """Test updating a draft."""
        repo = DraftRepository(test_session)
        
        draft = await repo.create(
            owner_id=test_user.id,
            title="Original",
            body="Original body"
        )
        
        updated = await repo.update(draft.id, title="Updated")
        assert updated.title == "Updated"
        assert updated.body == "Original body"  # Unchanged
    
    async def test_verify_ownership(self, test_session, test_user, test_user2):
        """Test verifying draft ownership."""
        repo = DraftRepository(test_session)
        
        draft = await repo.create(
            owner_id=test_user.id,
            title="Draft",
            body="Body"
        )
        
        assert await repo.verify_ownership(draft.id, test_user.id) is True
        assert await repo.verify_ownership(draft.id, test_user2.id) is False
