"""
Connections API routes matching Supabase schema.

This module handles all connection-related endpoints:
- Sending connection requests
- Responding to connection requests (accept/decline)
- Listing pending requests (incoming/outgoing)
- Listing mutual connections
- Searching users to connect with

Business Rules:
- Users can only send letters to mutual connections
- Connection requests must be accepted by both parties
- Prevents duplicate pending requests
- Enforces cooldown periods and rate limits

Security:
- All inputs are sanitized
- Ownership is verified for all operations
- Prevents self-requests and duplicate requests
"""
from typing import Optional
from uuid import UUID
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status, Query
from app.models.schemas import (
    ConnectionRequestCreate,
    ConnectionRequestResponse,
    ConnectionRequestUpdate,
    ConnectionRequestListResponse,
    ConnectionResponse,
    ConnectionListResponse,
    MessageResponse
)
from app.dependencies import DatabaseSession, CurrentUser
from app.core.logging import get_logger
from app.utils.helpers import sanitize_text
from app.core.constants import (
    MAX_CONNECTION_MESSAGE_LENGTH,
    MAX_DECLINED_REASON_LENGTH,
    MAX_DAILY_CONNECTION_REQUESTS,
    CONNECTION_COOLDOWN_DAYS,
    DEFAULT_QUERY_LIMIT,
    MAX_QUERY_LIMIT,
    MIN_QUERY_LIMIT
)
from app.services.connection_service import ConnectionService
from app.api.connection_helpers import build_connection_request_response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, DatabaseError

# Router for all connection endpoints
router = APIRouter(prefix="/connections", tags=["Connections"])
logger = get_logger(__name__)


@router.post("/requests", response_model=ConnectionRequestResponse, status_code=status.HTTP_201_CREATED)
async def send_connection_request(
    request_data: ConnectionRequestCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> ConnectionRequestResponse:
    """
    Send a connection request to another user.
    
    Creates a pending connection request. The recipient must accept
    before a mutual connection is established.
    """
    # Prevent self-requests
    if request_data.to_user_id == current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot send connection request to yourself"
        )
    
    # Sanitize message if provided
    message = None
    if request_data.message:
        message = sanitize_text(
            request_data.message.strip(),
            max_length=MAX_CONNECTION_MESSAGE_LENGTH
        )
    
    # Validate connection request using service layer
    connection_service = ConnectionService(session)
    
    # Check if already connected
    if await connection_service.check_existing_connection(
        current_user.user_id,
        request_data.to_user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already connected with this user"
        )
    
    # Check for existing pending request
    if await connection_service.check_pending_request(
        current_user.user_id,
        request_data.to_user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pending request already exists"
        )
    
    # Check cooldown period
    if await connection_service.check_cooldown(
        current_user.user_id,
        request_data.to_user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Please wait {CONNECTION_COOLDOWN_DAYS} days before sending another request to this user"
        )
    
    # Check rate limit
    rate_exceeded, _ = await connection_service.check_rate_limit(
        current_user.user_id
    )
    if rate_exceeded:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Rate limit exceeded: Maximum {MAX_DAILY_CONNECTION_REQUESTS} connection requests per day"
        )
    
    # Create the request
    try:
        result = await session.execute(
            text("""
                INSERT INTO public.connection_requests (from_user_id, to_user_id, message, status)
                VALUES (:from_id, :to_id, :message, 'pending')
                RETURNING id, from_user_id, to_user_id, status, message, declined_reason, acted_at, created_at, updated_at
            """),
            {
                "from_id": current_user.user_id,
                "to_id": request_data.to_user_id,
                "message": message
            }
        )
        row = result.fetchone()
        
        if not row:
            await session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create connection request"
            )
        
        await session.commit()
        
        # Build response with profile data
        return await build_connection_request_response(
            session,
            row,
            profile_user_id=request_data.to_user_id
        )
    except IntegrityError as e:
        await session.rollback()
        error_msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        logger.error(f"Database integrity error sending connection request: {error_msg}")
        
        # Check for unique constraint violation (duplicate request)
        if "unique" in error_msg.lower() or "duplicate" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A pending request already exists"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Database error: Unable to create connection request"
        )
    except DatabaseError as e:
        await session.rollback()
        error_msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        logger.error(f"Database error sending connection request: {error_msg}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred. Please try again."
        )
    except Exception as e:
        error_msg = str(e)
        logger.error(f"Error sending connection request: {error_msg}")
        
        # Handle specific error cases
        if "cooldown_active" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Please wait 7 days before sending another request to this user"
            )
        elif "already connected" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already connected with this user"
            )
        elif "blocked" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot send request: user is blocked"
            )
        elif "already sent" in error_msg.lower() or "duplicate" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A pending request already exists"
            )
        elif "rate limit" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded: Maximum {MAX_DAILY_CONNECTION_REQUESTS} requests per day"
            )
        else:
            await session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to send connection request: {error_msg}"
            )


@router.patch("/requests/{request_id}", response_model=ConnectionRequestResponse)
async def respond_to_request(
    request_id: UUID,
    response_data: ConnectionRequestUpdate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> ConnectionRequestResponse:
    """
    Respond to a connection request (accept or decline).
    
    Only the recipient (to_user_id) can respond to a request.
    """
    # Verify request exists and user is the recipient
    request_check = await session.execute(
        text("""
            SELECT from_user_id, to_user_id, status FROM public.connection_requests
            WHERE id = :request_id
        """),
        {"request_id": request_id}
    )
    request_row = request_check.fetchone()
    
    if not request_row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection request not found"
        )
    
    if request_row[1] != current_user.user_id:  # to_user_id must match
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to respond to this request"
        )
    
    if request_row[2] != 'pending':  # status must be pending
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This request has already been responded to"
        )
    
    declined_reason = None
    if response_data.status == 'declined' and response_data.declined_reason:
        declined_reason = sanitize_text(
            response_data.declined_reason.strip(),
            max_length=MAX_DECLINED_REASON_LENGTH
        )
    
    # Update request and create connection if accepted
    try:
        if response_data.status == 'accepted':
            # Create mutual connection using service layer
            connection_service = ConnectionService(session)
            from_user_id = request_row[0]
            to_user_id = request_row[1]
            await connection_service.create_connection(from_user_id, to_user_id)
        
        # Update request status
        result = await session.execute(
            text("""
                UPDATE public.connection_requests
                SET status = :status,
                    declined_reason = :declined_reason,
                    acted_at = NOW(),
                    updated_at = NOW()
                WHERE id = :request_id
                RETURNING id, from_user_id, to_user_id, status, message, declined_reason, acted_at, created_at, updated_at
            """),
            {
                "request_id": request_id,
                "status": response_data.status,
                "declined_reason": declined_reason
            }
        )
        row = result.fetchone()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update connection request"
            )
        
        await session.commit()
        
        # Build response with profile data
        return await build_connection_request_response(
            session,
            row,
            profile_user_id=request_row[0]  # from_user_id
        )
    except HTTPException:
        raise
    except IntegrityError as e:
        await session.rollback()
        error_msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        logger.error(f"Database integrity error responding to connection request: {error_msg}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred. Please try again."
        )
    except DatabaseError as e:
        await session.rollback()
        error_msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        logger.error(f"Database error responding to connection request: {error_msg}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred. Please try again."
        )
    except Exception as e:
        await session.rollback()
        error_msg = str(e)
        logger.error(f"Error responding to connection request: {error_msg}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to respond to connection request: {error_msg}"
        )


@router.get("/requests/incoming", response_model=ConnectionRequestListResponse)
async def get_incoming_requests(
    current_user: CurrentUser,
    session: DatabaseSession,
    limit: int = Query(DEFAULT_QUERY_LIMIT, ge=MIN_QUERY_LIMIT, le=MAX_QUERY_LIMIT),
    offset: int = Query(0, ge=0)
) -> ConnectionRequestListResponse:
    """
    Get all pending incoming connection requests for the current user.
    """
    try:
        result = await session.execute(
            text("""
                SELECT 
                    cr.id, 
                    cr.from_user_id, 
                    cr.to_user_id, 
                    cr.status, 
                    cr.message, 
                    cr.declined_reason, 
                    cr.acted_at, 
                    cr.created_at, 
                    cr.updated_at,
                    up.first_name,
                    up.last_name,
                    up.username,
                    up.avatar_url
                FROM public.connection_requests cr
                LEFT JOIN public.user_profiles up ON cr.from_user_id = up.user_id
                WHERE cr.to_user_id = :user_id AND cr.status = 'pending'
                ORDER BY cr.created_at DESC
                LIMIT :limit OFFSET :offset
            """),
            {
                "user_id": current_user.user_id,
                "limit": limit,
                "offset": offset
            }
        )
        rows = result.fetchall()
        
        requests = [
            ConnectionRequestResponse(
                id=row[0],
                from_user_id=row[1],
                to_user_id=row[2],
                status=row[3],
                message=row[4],
                declined_reason=row[5],
                acted_at=row[6],
                created_at=row[7],
                updated_at=row[8],
                from_user_first_name=row[9] if len(row) > 9 else None,
                from_user_last_name=row[10] if len(row) > 10 else None,
                from_user_username=row[11] if len(row) > 11 else None,
                from_user_avatar_url=row[12] if len(row) > 12 else None,
            )
            for row in rows
        ]
        
        # Get total count
        count_result = await session.execute(
            text("""
                SELECT COUNT(*) FROM public.connection_requests
                WHERE to_user_id = :user_id AND status = 'pending'
            """),
            {"user_id": current_user.user_id}
        )
        total = count_result.scalar() or 0
        
        return ConnectionRequestListResponse(requests=requests, total=total)
    except Exception as e:
        logger.error(f"Error getting incoming requests: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get incoming requests: {str(e)}"
        )


@router.get("/requests/outgoing", response_model=ConnectionRequestListResponse)
async def get_outgoing_requests(
    current_user: CurrentUser,
    session: DatabaseSession,
    limit: int = Query(DEFAULT_QUERY_LIMIT, ge=MIN_QUERY_LIMIT, le=MAX_QUERY_LIMIT),
    offset: int = Query(0, ge=0)
) -> ConnectionRequestListResponse:
    """
    Get all pending outgoing connection requests sent by the current user.
    """
    try:
        result = await session.execute(
            text("""
                SELECT 
                    cr.id, 
                    cr.from_user_id, 
                    cr.to_user_id, 
                    cr.status, 
                    cr.message, 
                    cr.declined_reason, 
                    cr.acted_at, 
                    cr.created_at, 
                    cr.updated_at,
                    up.first_name,
                    up.last_name,
                    up.username,
                    up.avatar_url
                FROM public.connection_requests cr
                LEFT JOIN public.user_profiles up ON cr.to_user_id = up.user_id
                WHERE cr.from_user_id = :user_id AND cr.status = 'pending'
                ORDER BY cr.created_at DESC
                LIMIT :limit OFFSET :offset
            """),
            {
                "user_id": current_user.user_id,
                "limit": limit,
                "offset": offset
            }
        )
        rows = result.fetchall()
        
        requests = [
            ConnectionRequestResponse(
                id=row[0],
                from_user_id=row[1],
                to_user_id=row[2],
                status=row[3],
                message=row[4],
                declined_reason=row[5],
                acted_at=row[6],
                created_at=row[7],
                updated_at=row[8],
                from_user_first_name=row[9] if len(row) > 9 else None,
                from_user_last_name=row[10] if len(row) > 10 else None,
                from_user_username=row[11] if len(row) > 11 else None,
                from_user_avatar_url=row[12] if len(row) > 12 else None,
            )
            for row in rows
        ]
        
        # Get total count
        count_result = await session.execute(
            text("""
                SELECT COUNT(*) FROM public.connection_requests
                WHERE from_user_id = :user_id AND status = 'pending'
            """),
            {"user_id": current_user.user_id}
        )
        total = count_result.scalar() or 0
        
        return ConnectionRequestListResponse(requests=requests, total=total)
    except Exception as e:
        logger.error(f"Error getting outgoing requests: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get outgoing requests: {str(e)}"
        )


@router.get("", response_model=ConnectionListResponse)
async def get_connections(
    current_user: CurrentUser,
    session: DatabaseSession,
    limit: int = Query(DEFAULT_QUERY_LIMIT, ge=MIN_QUERY_LIMIT, le=MAX_QUERY_LIMIT),
    offset: int = Query(0, ge=0)
) -> ConnectionListResponse:
    """
    Get all mutual connections for the current user.
    """
    try:
        # Optimized query using UNION instead of OR for better index usage
        # PostgreSQL can use indexes efficiently with UNION, but not with OR
        # This splits the query into two parts that can each use their respective indexes
        result = await session.execute(
            text("""
                (
                    SELECT 
                        c.user_id_1, 
                        c.user_id_2, 
                        c.connected_at,
                        up.first_name,
                        up.last_name,
                        up.username,
                        up.avatar_url
                    FROM public.connections c
                    LEFT JOIN public.user_profiles up ON up.user_id = c.user_id_2
                    WHERE c.user_id_1 = :user_id
                )
                UNION ALL
                (
                    SELECT 
                        c.user_id_1, 
                        c.user_id_2, 
                        c.connected_at,
                        up.first_name,
                        up.last_name,
                        up.username,
                        up.avatar_url
                    FROM public.connections c
                    LEFT JOIN public.user_profiles up ON up.user_id = c.user_id_1
                    WHERE c.user_id_2 = :user_id
                )
                ORDER BY connected_at DESC
                LIMIT :limit OFFSET :offset
            """),
            {
                "user_id": current_user.user_id,
                "limit": limit,
                "offset": offset
            }
        )
        rows = result.fetchall()
        
        connections = [
            ConnectionResponse(
                user_id_1=row[0],
                user_id_2=row[1],
                connected_at=row[2],
                other_user_first_name=row[3] if len(row) > 3 else None,
                other_user_last_name=row[4] if len(row) > 4 else None,
                other_user_username=row[5] if len(row) > 5 else None,
                other_user_avatar_url=row[6] if len(row) > 6 else None,
            )
            for row in rows
        ]
        
        # Optimized count query using UNION for better index usage
        count_result = await session.execute(
            text("""
                SELECT COUNT(*) FROM (
                    SELECT 1 FROM public.connections WHERE user_id_1 = :user_id
                    UNION ALL
                    SELECT 1 FROM public.connections WHERE user_id_2 = :user_id
                ) AS combined
            """),
            {"user_id": current_user.user_id}
        )
        total = count_result.scalar() or 0
        
        return ConnectionListResponse(connections=connections, total=total)
    except Exception as e:
        logger.error(f"Error getting connections: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get connections: {str(e)}"
        )
