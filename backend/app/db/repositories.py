"""Specific repositories for each model."""
from typing import Optional
from datetime import datetime
from sqlalchemy import select, and_, or_, case
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import User, Capsule, Draft, Recipient, CapsuleState
from app.db.repository import BaseRepository


class UserRepository(BaseRepository[User]):
    """Repository for user operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(User, session)
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        result = await self.session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username."""
        result = await self.session.execute(
            select(User).where(User.username == username)
        )
        return result.scalar_one_or_none()
    
    async def email_exists(self, email: str) -> bool:
        """Check if email already exists."""
        return await self.exists(email=email)
    
    async def username_exists(self, username: str) -> bool:
        """Check if username already exists."""
        return await self.exists(username=username)
    
    async def search_users(
        self, 
        query: str, 
        limit: int = 10,
        exclude_user_id: Optional[str] = None
    ) -> list[User]:
        """
        Search users by email, username, or full_name.
        
        Prioritizes exact username matches, then partial matches.
        Username is unique across the database, making it ideal for searching.
        
        Args:
            query: Search query string
            limit: Maximum number of results to return
            exclude_user_id: User ID to exclude from results (e.g., current user)
        
        Returns:
            List of matching users, ordered by relevance (exact username matches first)
        """
        query_lower = query.lower().strip()
        search_term = f"%{query_lower}%"
        
        # Build query to search across email, username, and full_name
        search_conditions = or_(
            User.email.ilike(search_term),
            User.username.ilike(search_term),
            User.full_name.ilike(search_term)
        )
        
        # Exclude specific user if provided
        if exclude_user_id:
            search_conditions = and_(search_conditions, User.id != exclude_user_id)
        
        # Only return active users
        search_conditions = and_(search_conditions, User.is_active == True)
        
        # Order by relevance:
        # 1. Exact username match (case-insensitive) - highest priority
        # 2. Username starts with query
        # 3. Email starts with query
        # 4. Full name starts with query
        # 5. Then by full_name, username
        result = await self.session.execute(
            select(User)
            .where(search_conditions)
            .order_by(
                # Prioritize exact username matches first
                case(
                    (User.username.ilike(query_lower), 1),
                    (User.username.ilike(f"{query_lower}%"), 2),
                    (User.email.ilike(f"{query_lower}%"), 3),
                    (User.full_name.ilike(f"{query_lower}%"), 4),
                    else_=5
                ),
                # Then alphabetical
                User.full_name.nulls_last(),
                User.username
            )
            .limit(limit)
        )
        return list(result.scalars().all())


class CapsuleRepository(BaseRepository[Capsule]):
    """Repository for capsule operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Capsule, session)
    
    async def get_by_sender(
        self,
        sender_id: str,
        state: Optional[CapsuleState] = None,
        skip: int = 0,
        limit: int = 100  # Using default limit, can be overridden
    ) -> list[Capsule]:
        """Get capsules by sender with optional state filter."""
        query = select(Capsule).where(Capsule.sender_id == sender_id)
        
        if state:
            query = query.where(Capsule.state == state)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip).limit(limit)
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def get_by_receiver(
        self,
        receiver_id: str,
        state: Optional[CapsuleState] = None,
        skip: int = 0,
        limit: int = 100  # Using default limit, can be overridden
    ) -> list[Capsule]:
        """Get capsules by receiver with optional state filter."""
        from app.core.logging import get_logger
        logger = get_logger(__name__)
        
        query = select(Capsule).where(Capsule.receiver_id == receiver_id)
        
        if state:
            query = query.where(Capsule.state == state)
        
        query = query.order_by(Capsule.created_at.desc()).offset(skip).limit(limit)
        result = await self.session.execute(query)
        capsules = list(result.scalars().all())
        
        logger.info(
            f"get_by_receiver: receiver_id={receiver_id}, state={state}, "
            f"found {len(capsules)} capsules"
        )
        
        return capsules
    
    async def count_by_sender(
        self,
        sender_id: str,
        state: Optional[CapsuleState] = None
    ) -> int:
        """Count capsules by sender."""
        from sqlalchemy import func
        
        query = select(func.count()).select_from(Capsule).where(
            Capsule.sender_id == sender_id
        )
        
        if state:
            query = query.where(Capsule.state == state)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def count_by_receiver(
        self,
        receiver_id: str,
        state: Optional[CapsuleState] = None
    ) -> int:
        """Count capsules by receiver."""
        from sqlalchemy import func
        
        query = select(func.count()).select_from(Capsule).where(
            Capsule.receiver_id == receiver_id
        )
        
        if state:
            query = query.where(Capsule.state == state)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def get_capsules_for_unlock(self) -> list[Capsule]:
        """Get all capsules that need state updates (sealed/unfolding)."""
        from datetime import timezone
        now = datetime.now(timezone.utc)
        
        query = select(Capsule).where(
            and_(
                or_(
                    Capsule.state == CapsuleState.SEALED,
                    Capsule.state == CapsuleState.UNFOLDING
                ),
                Capsule.scheduled_unlock_at.isnot(None)
            )
        )
        
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def transition_state(
        self,
        capsule_id: str,
        new_state: CapsuleState,
        **extra_fields: datetime
    ) -> Optional[Capsule]:
        """Transition capsule to a new state with timestamp updates."""
        updates = {"state": new_state}
        updates.update(extra_fields)
        return await self.update(capsule_id, **updates)
    
    async def verify_ownership(self, capsule_id: str, user_id: str) -> bool:
        """Verify if user is the sender of a capsule."""
        capsule = await self.get_by_id(capsule_id)
        return capsule is not None and capsule.sender_id == user_id
    
    async def can_open(self, capsule_id: str, user_id: str) -> tuple[bool, str]:
        """Check if user can open a capsule."""
        capsule = await self.get_by_id(capsule_id)
        
        if not capsule:
            return False, "Capsule not found"
        
        if capsule.receiver_id != user_id:
            return False, "You are not the receiver of this capsule"
        
        if capsule.state == CapsuleState.OPENED:
            return False, "Capsule already opened"
        
        if capsule.state != CapsuleState.READY:
            return False, f"Capsule is not ready yet (current state: {capsule.state})"
        
        return True, "OK"


class DraftRepository(BaseRepository[Draft]):
    """Repository for draft operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Draft, session)
    
    async def get_by_owner(
        self,
        owner_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> list[Draft]:
        """Get all drafts by owner."""
        query = (
            select(Draft)
            .where(Draft.owner_id == owner_id)
            .order_by(Draft.updated_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def count_by_owner(self, owner_id: str) -> int:
        """Count drafts by owner."""
        from sqlalchemy import func
        
        query = (
            select(func.count())
            .select_from(Draft)
            .where(Draft.owner_id == owner_id)
        )
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def verify_ownership(self, draft_id: str, user_id: str) -> bool:
        """Verify if user owns a draft."""
        draft = await self.get_by_id(draft_id)
        return draft is not None and draft.owner_id == user_id


class RecipientRepository(BaseRepository[Recipient]):
    """Repository for recipient operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Recipient, session)
    
    async def get_by_owner(
        self,
        owner_id: str,
        skip: int = 0,
        limit: int = 100  # Using default limit, can be overridden
    ) -> list[Recipient]:
        """Get all recipients by owner."""
        query = (
            select(Recipient)
            .where(Recipient.owner_id == owner_id)
            .order_by(Recipient.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def verify_ownership(self, recipient_id: str, user_id: str) -> bool:
        """Verify if user owns a recipient."""
        recipient = await self.get_by_id(recipient_id)
        return recipient is not None and recipient.owner_id == user_id
