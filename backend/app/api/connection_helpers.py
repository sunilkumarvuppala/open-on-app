"""
Helper functions for connection API endpoints.

This module provides reusable functions to reduce code duplication
in connection-related endpoints.
"""
from typing import Optional, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.models.schemas import ConnectionRequestResponse


async def build_connection_request_response(
    session: AsyncSession,
    request_row: tuple,
    profile_user_id: Optional[Any] = None
) -> ConnectionRequestResponse:
    """
    Build a ConnectionRequestResponse from database row and profile data.
    
    Args:
        session: Database session
        request_row: Tuple from connection_requests query
        profile_user_id: User ID to fetch profile for (if None, uses from_user_id)
    
    Returns:
        ConnectionRequestResponse with profile data
    """
    from_user_id = request_row[1] if len(request_row) > 1 else None
    profile_id = profile_user_id or from_user_id
    
    # Get user profile
    profile_row = None
    if profile_id:
        profile_result = await session.execute(
            text("""
                SELECT first_name, last_name, username, avatar_url
                FROM public.user_profiles
                WHERE user_id = :user_id
            """),
            {"user_id": profile_id}
        )
        profile_row = profile_result.fetchone()
    
    return ConnectionRequestResponse(
        id=request_row[0],
        from_user_id=request_row[1],
        to_user_id=request_row[2],
        status=request_row[3],
        message=request_row[4] if len(request_row) > 4 else None,
        declined_reason=request_row[5] if len(request_row) > 5 else None,
        acted_at=request_row[6] if len(request_row) > 6 else None,
        created_at=request_row[7],
        updated_at=request_row[8] if len(request_row) > 8 else request_row[7],
        from_user_first_name=profile_row[0] if profile_row and len(profile_row) > 0 else None,
        from_user_last_name=profile_row[1] if profile_row and len(profile_row) > 1 else None,
        from_user_username=profile_row[2] if profile_row and len(profile_row) > 2 else None,
        from_user_avatar_url=profile_row[3] if profile_row and len(profile_row) > 3 else None,
    )
