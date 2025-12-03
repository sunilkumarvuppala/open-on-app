"""
Database base configuration and session management.

This module provides:
- Database engine configuration
- Session factory for async operations
- Base class for all ORM models
- Database initialization and cleanup functions

Key Features:
- Async SQLAlchemy for non-blocking database operations
- Connection pooling for efficient resource usage
- Automatic session management with dependency injection
- Proper transaction handling (commit/rollback)
"""
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings


# ===== Database Engine =====
# Create async engine with connection pooling
# pool_pre_ping: Verifies connections before use (handles stale connections)
# echo: Logs SQL queries (useful for debugging, disabled in production)
engine = create_async_engine(
    settings.database_url,
    echo=settings.db_echo,
    future=True,  # Use SQLAlchemy 2.0 style
    pool_pre_ping=True,  # Verify connections before use
)

# ===== Session Factory =====
# Create async session factory for dependency injection
# expire_on_commit=False: Objects remain accessible after commit
# autocommit=False: Manual transaction control
# autoflush=False: Manual flush control (better performance)
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Keep objects accessible after commit
    autocommit=False,  # Manual transaction control
    autoflush=False,  # Manual flush control
)


# ===== Base Model Class =====
# Base class for all database models
# All models inherit from this to get ORM functionality
class Base(DeclarativeBase):
    """
    Base class for all database models.
    
    All ORM models should inherit from this class.
    Provides SQLAlchemy ORM functionality and metadata.
    """
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency for database sessions.
    
    This function is used as a FastAPI dependency to provide
    database sessions to route handlers.
    
    Yields:
        AsyncSession: Database session
    
    Note:
        Automatically commits on success, rolls back on exception
        Always closes session in finally block
    """
    async with AsyncSessionLocal() as session:
        try:
            # Yield session to route handler
            yield session
            # Commit transaction if no exceptions occurred
            await session.commit()
        except Exception:
            # Rollback transaction on any exception
            await session.rollback()
            raise
        finally:
            # Always close session to return connection to pool
            await session.close()


async def init_db() -> None:
    """
    Initialize database tables.
    
    Creates all tables defined in models that inherit from Base.
    This is called on application startup.
    
    Note:
        Uses run_sync to execute synchronous create_all in async context
        Only creates tables that don't already exist
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def close_db() -> None:
    """
    Close database connections.
    
    Disposes of the engine and closes all connection pools.
    This is called on application shutdown.
    
    Note:
        Should be called during application shutdown to clean up resources
    """
    await engine.dispose()
