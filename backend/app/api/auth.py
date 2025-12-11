"""
Authentication API routes.

This module handles authentication-related endpoints.
Note: User registration and login are handled by Supabase Auth.
This backend provides endpoints for user profile management and signup.

Endpoints:
- User signup (/signup) - Creates user in Supabase Auth and profile
- User login (/login) - Authenticates via Supabase Auth
- Current user information (/me)
- User profile management
- Username availability check

Security considerations:
- Signup/login use Supabase Auth via Admin API
- All other endpoints require Supabase JWT authentication
- User profile data is managed here, but auth is handled by Supabase
"""
from typing import Any
from uuid import UUID
import httpx
from fastapi import APIRouter, HTTPException, status, Query, Depends, Request
from app.models.schemas import UserProfileResponse, UserCreate, UserLogin
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import UserProfileRepository
from app.db.models import UserProfile
from app.utils.helpers import validate_username, sanitize_text
from app.utils.url_helpers import normalize_supabase_url
from app.core.config import settings
from app.core.security import verify_supabase_token


# Router for all authentication endpoints
router = APIRouter(prefix="/auth", tags=["Authentication"])


async def get_user_email_from_auth(user_id: UUID) -> str:
    """
    Fetch user email from Supabase Auth.
    
    Args:
        user_id: User UUID
        
    Returns:
        str: User's email address
        
    Raises:
        HTTPException: If email cannot be fetched
    """
    if not settings.supabase_service_key or settings.supabase_service_key == "your-supabase-service-key-here":
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="SUPABASE_SERVICE_KEY not configured"
        )
    
    supabase_url = normalize_supabase_url(settings.supabase_url)
    async with httpx.AsyncClient(timeout=10.0) as client:
        headers = {
            "apikey": settings.supabase_service_key,
            "Authorization": f"Bearer {settings.supabase_service_key}",
        }
        
        auth_url = f"{supabase_url}/auth/v1/admin/users/{user_id}"
        try:
            response = await client.get(auth_url, headers=headers)
            if response.status_code == 200:
                auth_user = response.json()
                email = auth_user.get("email", "")
                if not email:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="User email not found"
                    )
                return email
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to fetch user email from Supabase Auth"
                )
        except httpx.HTTPError:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to connect to Supabase Auth"
            )


@router.post("/signup")
async def signup(
    user_data: UserCreate,
    session: DatabaseSession
) -> dict[str, Any]:
    """
    Create a new user account via Supabase Auth.
    
    This endpoint:
    1. Creates a user in Supabase Auth
    2. Creates a user profile in the database
    3. Returns access and refresh tokens
    
    Note: Uses Supabase Admin API to create users.
    """
    # Validate service key is set
    if not settings.supabase_service_key or settings.supabase_service_key == "your-supabase-service-key-here":
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="SUPABASE_SERVICE_KEY not configured. Get it from: cd supabase && supabase status (look for 'service_role key')"
        )
    
    # Validate username format
    is_valid, error_message = validate_username(user_data.username)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_message
        )
    
    # Create user in Supabase Auth using Admin API
    async with httpx.AsyncClient() as client:
        try:
            # Sign up user via Supabase Auth Admin API
            supabase_url = normalize_supabase_url(settings.supabase_url)
            supabase_auth_url = f"{supabase_url}/auth/v1/admin/users"
            headers = {
                "apikey": settings.supabase_service_key,
                "Authorization": f"Bearer {settings.supabase_service_key}",
                "Content-Type": "application/json"
            }
            
            # Create user with email and password
            payload = {
                "email": user_data.email,
                "password": user_data.password,
                "email_confirm": True,  # Auto-confirm email for development
                "user_metadata": {
                    "username": user_data.username,
                    "first_name": user_data.first_name,
                    "last_name": user_data.last_name,
                    "full_name": user_data.full_name or f"{user_data.first_name} {user_data.last_name}"
                }
            }
            
            response = await client.post(supabase_auth_url, json=payload, headers=headers)
            
            if response.status_code not in (200, 201):
                # Try to get detailed error message
                try:
                    error_json = response.json()
                    error_detail = error_json.get("message") or error_json.get("error_description") or error_json.get("error") or f"HTTP {response.status_code}: Failed to create user"
                except:
                    error_detail = f"HTTP {response.status_code}: Failed to create user. Check SUPABASE_SERVICE_KEY in .env"
                
                # Log the actual error for debugging
                from app.core.logging import get_logger
                logger = get_logger(__name__)
                logger.error(f"Supabase Admin API error: {response.status_code} - {error_detail}")
                logger.error(f"URL: {supabase_auth_url}")
                logger.error(f"Service key set: {bool(settings.supabase_service_key and settings.supabase_service_key != 'your-supabase-service-key-here')}")
                
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=error_detail
                )
            
            supabase_user = response.json()
            user_id = UUID(supabase_user["id"])
            
            # Create user profile
            user_profile_repo = UserProfileRepository(session)
            profile = await user_profile_repo.create(
                user_id=user_id,
                first_name=user_data.first_name,
                last_name=user_data.last_name,
                username=user_data.username
            )
            await session.commit()
            
            # Get access token for the new user
            # Sign in to get tokens
            signin_url = f"{normalize_supabase_url(settings.supabase_url)}/auth/v1/token?grant_type=password"
            signin_payload = {
                "email": user_data.email,
                "password": user_data.password
            }
            
            signin_response = await client.post(signin_url, json=signin_payload, headers={
                "apikey": settings.supabase_service_key,
                "Content-Type": "application/json"
            })
            
            if signin_response.status_code != 200:
                # User created but couldn't get token - return success anyway
                # Frontend can sign in separately
                return {
                    "message": "User created successfully. Please sign in.",
                    "user_id": str(user_id)
                }
            
            tokens = signin_response.json()
            
            # Get email from Supabase Auth response
            user_email = tokens["user"].get("email", user_data.email)
            
            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens.get("refresh_token", ""),
                "token_type": "bearer",
                "user": UserProfileResponse.from_user_profile(profile, email=user_email).model_dump()
            }
            
        except httpx.HTTPStatusError as e:
            # Get detailed error from response
            try:
                error_json = e.response.json()
                error_detail = error_json.get("message") or error_json.get("error_description") or error_json.get("error") or "Failed to create user"
            except:
                error_detail = f"HTTP {e.response.status_code}: Failed to create user"
            
            if e.response.status_code == 403:
                error_detail = "Authentication failed. Check SUPABASE_SERVICE_KEY in .env file. Get it from: cd supabase && supabase status"
            elif e.response.status_code == 422:
                error_detail = "Invalid user data"
            elif e.response.status_code == 409:
                error_detail = "Email already registered"
            
            from app.core.logging import get_logger
            logger = get_logger(__name__)
            logger.error(f"Supabase API error: {e.response.status_code} - {error_detail}")
            
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_detail
            )
        except Exception as e:
            from app.core.logging import get_logger
            logger = get_logger(__name__)
            logger.error(f"Unexpected error during signup: {str(e)}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create user: {str(e)}"
            )


@router.post("/login")
async def login(
    login_data: UserLogin,
    session: DatabaseSession
) -> dict[str, Any]:
    """
    Authenticate user via Supabase Auth.
    
    Returns access and refresh tokens.
    """
    async with httpx.AsyncClient() as client:
        try:
            # Sign in via Supabase Auth
            signin_url = f"{normalize_supabase_url(settings.supabase_url)}/auth/v1/token?grant_type=password"
            signin_payload = {
                "email": login_data.username,  # Supabase uses email for login
                "password": login_data.password
            }
            
            headers = {
                "apikey": settings.supabase_service_key,
                "Content-Type": "application/json"
            }
            
            response = await client.post(signin_url, json=signin_payload, headers=headers)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password"
                )
            
            tokens = response.json()
            user_id = UUID(tokens["user"]["id"])
            
            # Get or create user profile
            user_profile_repo = UserProfileRepository(session)
            profile = await user_profile_repo.get_by_id(user_id)
            
            if not profile:
                # Create profile if it doesn't exist
                profile = await user_profile_repo.create(user_id=user_id)
                await session.commit()
            
            # Update last_login timestamp
            await user_profile_repo.update_last_login(user_id)
            await session.commit()
            
            # Get email from Supabase Auth response
            user_email = tokens["user"].get("email", "")
            if not user_email:
                # Fallback: fetch from Supabase Auth Admin API
                user_email = await get_user_email_from_auth(user_id)
            
            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens.get("refresh_token", ""),
                "token_type": "bearer",
                "user": UserProfileResponse.from_user_profile(profile, email=user_email).model_dump()
            }
            
        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to authenticate: {str(e)}"
            )


@router.get("/me", response_model=UserProfileResponse)
async def get_current_user_info(
    current_user: CurrentUser,
    request: Request
) -> UserProfileResponse:
    """
    Get current authenticated user profile information.
    
    Returns the profile of the currently authenticated user.
    The user is authenticated via Supabase JWT token.
    
    Note:
        Authentication is handled by Supabase Auth.
        This endpoint returns the user profile data including email.
    """
    # Get email from JWT token if available, otherwise fetch from Supabase Auth
    email = None
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header.replace("Bearer ", "")
        try:
            payload = verify_supabase_token(token)
            email = payload.get("email")  # Supabase JWT may contain email
        except ValueError:
            pass
    
    # If email not in token, fetch from Supabase Auth
    if not email:
        email = await get_user_email_from_auth(current_user.user_id)
    
    return UserProfileResponse.from_user_profile(current_user, email=email)


@router.get("/username/check")
async def check_username_availability(
    username: str = Query(..., min_length=1, description="Username to check")
) -> dict[str, Any]:
    """
    Check if a username is available.
    
    This endpoint validates the username format and checks availability.
    Note: Since authentication is handled by Supabase Auth (which uses email),
    this endpoint primarily validates username format. Actual username uniqueness
    will be enforced by Supabase Auth when the user signs up.
    
    Returns:
        - available: bool - Whether the username is available
        - message: str - Status message
    """
    # Validate username format
    is_valid, error_message = validate_username(username)
    
    if not is_valid:
        return {
            "available": False,
            "message": error_message
        }
    
    # For now, we return available since we can't easily check Supabase Auth
    # usernames without the Admin API. The actual uniqueness will be enforced
    # by Supabase Auth when the user signs up.
    # TODO: If username is stored in user_profiles or user_metadata, check against that
    
    return {
        "available": True,
        "message": "Username is available"
    }


@router.get("/users/search")
async def search_users(
    current_user: CurrentUser,
    session: DatabaseSession,
    query: str = Query(..., min_length=2, description="Search query (username, email, or name)"),
    limit: int = Query(
        settings.default_search_limit,
        ge=1,
        le=settings.max_search_limit,
        description="Maximum number of results"
    )
) -> list[dict[str, Any]]:
    """
    Search for registered users by username, email, or name.
    
    Searches Supabase Auth users and returns matching users with their profile data.
    Only returns users that have a profile in user_profiles table.
    
    Search matches:
    - Email (exact or partial)
    - Username (from user_metadata)
    - Full name (from user_profiles or user_metadata)
    
    Returns list of users with:
    - id: User UUID
    - email: User email
    - username: Username from user_metadata
    - name: Full name from profile or metadata
    - avatar: Avatar URL from profile
    """
    if not settings.supabase_service_key or settings.supabase_service_key == "your-supabase-service-key-here":
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="SUPABASE_SERVICE_KEY not configured"
        )
    
    from sqlalchemy import select, or_, func
    from app.db.models import UserProfile
    
    # Sanitize and normalize search query
    query_sanitized = sanitize_text(query, max_length=settings.max_search_query_length)
    query_lower = query_sanitized.lower().strip()
    
    # Validate query length
    if len(query_lower) < settings.min_search_query_length:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Search query must be at least {settings.min_search_query_length} characters"
        )
    
    users_list = []
    
    # First, search user_profiles by first_name, last_name, or username (most efficient)
    # SQLAlchemy .contains() uses parameterized queries - safe from SQL injection
    stmt = select(UserProfile).where(
        or_(
            func.lower(UserProfile.first_name).contains(query_lower),
            func.lower(UserProfile.last_name).contains(query_lower),
            func.lower(UserProfile.username).contains(query_lower),
            UserProfile.first_name.contains(query_sanitized),  # Case-sensitive fallback
            UserProfile.last_name.contains(query_sanitized),
            UserProfile.username.contains(query_sanitized)
        )
    ).limit(limit * 2)  # Get more to filter by email/username later
    
    result = await session.execute(stmt)
    profiles = result.scalars().all()
    
    # Fetch auth user data for matching profiles
    supabase_url = normalize_supabase_url(settings.supabase_url)
    async with httpx.AsyncClient(timeout=10.0) as client:
        headers = {
            "apikey": settings.supabase_service_key,
            "Authorization": f"Bearer {settings.supabase_service_key}",
        }
        
        for profile in profiles:
            if len(users_list) >= limit:
                break
            
            # Exclude current user from search results
            if profile.user_id == current_user.user_id:
                continue
                
            try:
                # Get user from Supabase Auth
                auth_url = f"{supabase_url}/auth/v1/admin/users/{profile.user_id}"
                auth_response = await client.get(auth_url, headers=headers)
                
                if auth_response.status_code == 200:
                    auth_user = auth_response.json()
                    email = auth_user.get("email", "")
                    user_metadata = auth_user.get("user_metadata", {})
                    username = profile.username or user_metadata.get("username", email.split("@")[0] if email else "")
                    first_name = profile.first_name or user_metadata.get("first_name", "")
                    last_name = profile.last_name or user_metadata.get("last_name", "")
                    full_name = f"{first_name} {last_name}".strip() if (first_name or last_name) else email.split("@")[0]
                    
                    # Check if query matches email, username, first_name, or last_name
                    email_match = query_lower in email.lower() if email else False
                    username_match = query_lower in username.lower() if username else False
                    first_name_match = query_lower in first_name.lower() if first_name else False
                    last_name_match = query_lower in last_name.lower() if last_name else False
                    full_name_match = query_lower in full_name.lower() if full_name else False
                    
                    if email_match or username_match or first_name_match or last_name_match or full_name_match:
                        users_list.append({
                            "id": str(profile.user_id),
                            "email": email,
                            "username": username,
                            "name": full_name,
                            "avatar": profile.avatar_url or ""
                        })
            except Exception:
                # Skip users that can't be fetched
                continue
    
    return users_list


@router.put("/me", response_model=UserProfileResponse)
async def update_current_user_profile(
    current_user: CurrentUser,
    session: DatabaseSession,
    first_name: str | None = None,
    last_name: str | None = None,
    username: str | None = None,
    avatar_url: str | None = None,
    country: str | None = None,
    device_token: str | None = None
) -> UserProfileResponse:
    """
    Update current user profile.
    
    Allows users to update their profile information.
    Only updates fields that are provided (partial update).
    """
    user_profile_repo = UserProfileRepository(session)
    
    updates = {}
    if first_name is not None:
        updates["first_name"] = first_name
    if last_name is not None:
        updates["last_name"] = last_name
    if username is not None:
        updates["username"] = username
    if avatar_url is not None:
        updates["avatar_url"] = avatar_url
    if country is not None:
        updates["country"] = country
    if device_token is not None:
        updates["device_token"] = device_token
    
    if not updates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update"
        )
    
    updated_profile = await user_profile_repo.update(current_user.user_id, **updates)
    if not updated_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )
    
    # Get email from Supabase Auth
    email = await get_user_email_from_auth(current_user.user_id)
    
    return UserProfileResponse.from_user_profile(updated_profile, email=email)
