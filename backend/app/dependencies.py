"""
FastAPI dependencies for authentication and database access.

This module provides dependency injection functions for:
- Database session management
- User authentication via JWT tokens
- Current user retrieval

Dependencies:
- get_db: Provides database session
- get_current_user: Validates JWT and returns authenticated user
- CurrentUser: Type alias for authenticated user dependency
- DatabaseSession: Type alias for database session dependency
"""
from typing import Annotated
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.base import get_db
from app.db.repositories import UserProfileRepository
from app.db.models import UserProfile
from app.core.security import verify_supabase_token


# ===== Security Scheme =====
# HTTPBearer extracts Bearer token from Authorization header
# Used by FastAPI to automatically extract JWT tokens
security = HTTPBearer()


async def get_current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    session: Annotated[AsyncSession, Depends(get_db)]
) -> UserProfile:
    """
    Get current authenticated user from Supabase JWT token.
    
    This dependency validates the Supabase JWT token, extracts user information,
    and returns the authenticated user profile object. It's used by all
    protected endpoints.
    
    Args:
        request: FastAPI request object (for setting user_id in state)
        credentials: Supabase JWT token from Authorization header
        session: Database session dependency
    
    Returns:
        UserProfile: Authenticated user profile object
    
    Raises:
        HTTPException: If token is invalid, expired, or user not found
    
    Security:
        - Validates Supabase JWT signature using Supabase JWT secret
        - Verifies token audience (must be "authenticated")
        - Checks user profile exists in database
        - Sets user_id in request.state for logging
    
    Note:
        Authentication is handled by Supabase Auth. This backend only
        verifies the JWT token and looks up the user profile.
    """
    token = credentials.credentials
    
    # ===== Supabase Token Verification =====
    # Verify and decode Supabase JWT token
    # Raises ValueError if token is invalid or expired
    try:
        payload = verify_supabase_token(token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== User ID Extraction =====
    # Extract user ID from token payload
    # "sub" (subject) claim contains the user ID (UUID)
    user_id_str: str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Convert string UUID to UUID object
    from uuid import UUID
    try:
        user_id = UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID format",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== Request State =====
    # Set user_id in request.state for logging middleware
    # This allows middleware to log requests with user context
    request.state.user_id = str(user_id)
    
    # ===== User Profile Lookup =====
    # Fetch user profile from database using ID from token
    # User profile extends Supabase Auth user with app-specific data
    user_profile_repo = UserProfileRepository(session)
    user_profile = await user_profile_repo.get_by_id(user_id)
    
    # ===== User Profile Existence Check =====
    # Verify user profile exists
    # If profile doesn't exist, create a basic one (first-time user)
    if not user_profile:
        # Create a basic user profile for first-time users
        # This happens when a user signs up via Supabase Auth but profile hasn't been created yet
        user_profile = await user_profile_repo.create(
            user_id=user_id,
            full_name=None,
            avatar_url=None,
            premium_status=False,
            premium_until=None,
            is_admin=False,
            country=None,
            device_token=None
        )
    
    return user_profile


async def get_current_active_user(
    current_user: Annotated[UserProfile, Depends(get_current_user)]
) -> UserProfile:
    """
    Get current active user (alias for clarity).
    
    This is an alias for get_current_user that explicitly indicates
    the user is active. Useful for endpoints that need to emphasize
    active user requirement.
    
    Args:
        current_user: Authenticated user profile from get_current_user dependency
    
    Returns:
        UserProfile: Active authenticated user profile
    """
    return current_user


# ===== Type Aliases =====
# Type aliases for cleaner endpoint signatures
# These make endpoint function signatures more readable

# CurrentUser: Dependency that provides authenticated user profile
# Usage: current_user: CurrentUser in endpoint function
CurrentUser = Annotated[UserProfile, Depends(get_current_user)]

# DatabaseSession: Dependency that provides database session
# Usage: session: DatabaseSession in endpoint function
DatabaseSession = Annotated[AsyncSession, Depends(get_db)]
