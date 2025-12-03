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
from app.db.repositories import UserRepository
from app.db.models import User
from app.core.security import decode_token, verify_token_type


# ===== Security Scheme =====
# HTTPBearer extracts Bearer token from Authorization header
# Used by FastAPI to automatically extract JWT tokens
security = HTTPBearer()


async def get_current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    session: Annotated[AsyncSession, Depends(get_db)]
) -> User:
    """
    Get current authenticated user from JWT token.
    
    This dependency validates the JWT token, extracts user information,
    and returns the authenticated user object. It's used by all
    protected endpoints.
    
    Args:
        request: FastAPI request object (for setting user_id in state)
        credentials: JWT token from Authorization header
        session: Database session dependency
    
    Returns:
        User: Authenticated user object
    
    Raises:
        HTTPException: If token is invalid, expired, or user not found
    
    Security:
        - Validates JWT signature
        - Verifies token type (access vs refresh)
        - Checks user exists and is active
        - Sets user_id in request.state for logging
    """
    token = credentials.credentials
    
    # ===== Token Decoding =====
    # Decode and validate JWT token
    # Raises ValueError if token is invalid or expired
    try:
        payload = decode_token(token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== Token Type Verification =====
    # Verify it's an access token (not refresh token)
    # Prevents using refresh tokens for API access
    if not verify_token_type(payload, "access"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== User ID Extraction =====
    # Extract user ID from token payload
    # "sub" (subject) claim contains the user ID
    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== Request State =====
    # Set user_id in request.state for logging middleware
    # This allows middleware to log requests with user context
    request.state.user_id = user_id
    
    # ===== User Lookup =====
    # Fetch user from database using ID from token
    user_repo = UserRepository(session)
    user = await user_repo.get_by_id(user_id)
    
    # ===== User Existence Check =====
    # Verify user exists (handles deleted users)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # ===== Account Status Check =====
    # Verify user account is active
    # Inactive accounts cannot authenticate (e.g., banned users)
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)]
) -> User:
    """
    Get current active user (alias for clarity).
    
    This is an alias for get_current_user that explicitly indicates
    the user is active. Useful for endpoints that need to emphasize
    active user requirement.
    
    Args:
        current_user: Authenticated user from get_current_user dependency
    
    Returns:
        User: Active authenticated user
    """
    return current_user


# ===== Type Aliases =====
# Type aliases for cleaner endpoint signatures
# These make endpoint function signatures more readable

# CurrentUser: Dependency that provides authenticated user
# Usage: current_user: CurrentUser in endpoint function
CurrentUser = Annotated[User, Depends(get_current_user)]

# DatabaseSession: Dependency that provides database session
# Usage: session: DatabaseSession in endpoint function
DatabaseSession = Annotated[AsyncSession, Depends(get_db)]
