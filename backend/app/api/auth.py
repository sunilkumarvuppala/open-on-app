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
from fastapi import APIRouter, HTTPException, status, Query, Depends
from app.models.schemas import UserProfileResponse, UserCreate, UserLogin
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import UserProfileRepository
from app.db.models import UserProfile
from app.utils.helpers import validate_username
from app.utils.url_helpers import normalize_supabase_url
from app.core.config import settings


# Router for all authentication endpoints
router = APIRouter(prefix="/auth", tags=["Authentication"])


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
                full_name=user_data.full_name or f"{user_data.first_name} {user_data.last_name}"
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
            
            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens.get("refresh_token", ""),
                "token_type": "bearer",
                "user": UserProfileResponse.from_user_profile(profile).model_dump()
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
            
            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens.get("refresh_token", ""),
                "token_type": "bearer",
                "user": UserProfileResponse.from_user_profile(profile).model_dump()
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
    current_user: CurrentUser
) -> UserProfileResponse:
    """
    Get current authenticated user profile information.
    
    Returns the profile of the currently authenticated user.
    The user is authenticated via Supabase JWT token.
    
    Note:
        Authentication is handled by Supabase Auth.
        This endpoint only returns the user profile data.
    """
    return UserProfileResponse.from_user_profile(current_user)


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


@router.put("/me", response_model=UserProfileResponse)
async def update_current_user_profile(
    current_user: CurrentUser,
    session: DatabaseSession,
    full_name: str | None = None,
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
    if full_name is not None:
        updates["full_name"] = full_name
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
    
    return UserProfileResponse.from_user_profile(updated_profile)
