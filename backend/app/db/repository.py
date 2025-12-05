"""
Base repository class with common CRUD operations.

This module provides a generic base repository that implements
common database operations (Create, Read, Update, Delete).

Benefits:
- Reduces code duplication across repositories
- Provides consistent interface for all models
- Type-safe operations with generics
- Async/await support for non-blocking operations

Usage:
    Specific repositories inherit from BaseRepository and add
    domain-specific query methods (e.g., get_by_email, get_by_username).
"""
from typing import TypeVar, Generic, Type, Optional, Any
from sqlalchemy import select, delete, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.base import Base


# Type variable for model types (all models inherit from Base)
ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Base repository with common CRUD operations.
    
    This generic repository provides standard database operations
    that can be used by any model. Specific repositories inherit
    from this and add domain-specific methods.
    
    Operations:
    - create: Create new record
    - get_by_id: Get record by primary key
    - get_all: Get all records with optional filters and pagination
    - count: Count records with optional filters
    - update: Update record by ID
    - delete: Delete record by ID
    - exists: Check if record exists with given filters
    """
    
    def __init__(self, model: Type[ModelType], session: AsyncSession):
        """
        Initialize repository with model and session.
        
        Args:
            model: SQLAlchemy model class
            session: Async database session
        """
        self.model = model
        self.session = session
    
    async def create(self, **kwargs: Any) -> ModelType:
        """
        Create a new record.
        
        Args:
            **kwargs: Field values for the new record
        
        Returns:
            Created model instance (refreshed from database)
        
        Note:
            Flushes to database to get generated values (e.g., ID)
            Refreshes instance to ensure all fields are current
        """
        instance = self.model(**kwargs)
        self.session.add(instance)
        await self.session.flush()  # Flush to get generated ID
        await self.session.refresh(instance)  # Refresh to get all fields
        return instance
    
    async def get_by_id(self, id: str) -> Optional[ModelType]:
        """
        Get a record by ID.
        
        Args:
            id: Primary key value
        
        Returns:
            Model instance if found, None otherwise
        """
        result = await self.session.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_all(
        self,
        skip: int = 0,
        limit: Optional[int] = None,
        **filters: Any
    ) -> list[ModelType]:
        """
        Get all records with optional filters and pagination.
        
        Args:
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return (uses settings default if None)
            **filters: Field filters (e.g., status="active")
        
        Returns:
            List of matching records
        
        Note:
            Filters are applied as equality checks
            Only filters that match model attributes are applied
        """
        from app.core.config import settings
        
        query = select(self.model)
        
        # Apply filters dynamically
        # Only applies filters for fields that exist on the model
        for key, value in filters.items():
            if hasattr(self.model, key):
                query = query.where(getattr(self.model, key) == value)
        
        # Apply pagination with default from settings
        query = query.offset(skip)
        if limit is not None:
            query = query.limit(limit)
        else:
            query = query.limit(settings.default_page_size)
        result = await self.session.execute(query)
        return list(result.scalars().all())
    
    async def count(self, **filters: Any) -> int:
        """
        Count records with optional filters.
        
        Args:
            **filters: Field filters (e.g., status="active")
        
        Returns:
            Number of matching records
        
        Note:
            More efficient than get_all() when only count is needed
        """
        from sqlalchemy import func
        
        query = select(func.count()).select_from(self.model)
        
        # Apply filters dynamically
        for key, value in filters.items():
            if hasattr(self.model, key):
                query = query.where(getattr(self.model, key) == value)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def update(self, id: str, **kwargs: Any) -> Optional[ModelType]:
        """
        Update a record by ID.
        
        Args:
            id: Primary key value
            **kwargs: Field values to update
        
        Returns:
            Updated model instance if found, None otherwise
        
        Note:
            Uses SQLAlchemy update() with RETURNING clause
            Only updates fields provided in kwargs
        """
        stmt = (
            update(self.model)
            .where(self.model.id == id)
            .values(**kwargs)
            .returning(self.model)  # Return updated record
        )
        result = await self.session.execute(stmt)
        await self.session.flush()  # Flush changes
        return result.scalar_one_or_none()
    
    async def delete(self, id: str) -> bool:
        """
        Delete a record by ID.
        
        Args:
            id: Primary key value
        
        Returns:
            True if record was deleted, False if not found
        
        Note:
            Returns boolean to indicate success
            Does not raise exception if record doesn't exist
        """
        stmt = delete(self.model).where(self.model.id == id)
        result = await self.session.execute(stmt)
        await self.session.flush()  # Flush deletion
        return result.rowcount > 0
    
    async def exists(self, **filters: Any) -> bool:
        """
        Check if a record exists with given filters.
        
        Args:
            **filters: Field filters (e.g., email="user@example.com")
        
        Returns:
            True if matching record exists, False otherwise
        
        Note:
            More efficient than get_by_id() when checking existence
            Uses SQL EXISTS clause for optimal performance
        """
        from sqlalchemy import exists as sql_exists
        
        # Require at least one filter
        if not filters:
            return False
        
        # Build conditions for filters
        conditions = []
        for key, value in filters.items():
            if hasattr(self.model, key):
                conditions.append(getattr(self.model, key) == value)
        
        # Require at least one valid condition
        if not conditions:
            return False
        
        # Use EXISTS clause for efficient existence check
        from sqlalchemy import and_
        query = select(sql_exists().where(and_(*conditions)))
        result = await self.session.execute(query)
        return result.scalar()
