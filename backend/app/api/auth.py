"""
Authentication API routes.

This module handles all authentication-related endpoints:
- User registration (signup)
- User login
- Current user information
- Username availability checking
- User search for recipient selection

Security considerations:
- All passwords are hashed using BCrypt before storage
- JWT tokens are used for authentication
- Input sanitization is applied to all user inputs
- Email and username uniqueness is enforced
"""
from fastapi import APIRouter, HTTPException, status, Query, Depends
from app.models.schemas import UserCreate, UserLogin, UserResponse, TokenResponse
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import UserRepository
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.core.config import settings
from app.utils.helpers import validate_username, validate_password, sanitize_text, validate_email


# Router for all authentication endpoints
router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    user_data: UserCreate,
    session: DatabaseSession
) -> TokenResponse:
    """
    Register a new user.
    
    Creates a new user account with validated credentials.
    Returns access and refresh tokens.
    """
    user_repo = UserRepository(session)
    
    # ===== Input Sanitization =====
    # Sanitize all inputs to prevent injection attacks and ensure data consistency
    # Lowercase email for case-insensitive uniqueness
    email = sanitize_text(user_data.email.lower().strip(), max_length=settings.max_email_length)
    username = sanitize_text(user_data.username.strip(), max_length=settings.max_username_length)
    first_name = sanitize_text(user_data.first_name.strip(), max_length=settings.max_name_length)
    last_name = sanitize_text(user_data.last_name.strip(), max_length=settings.max_name_length)
    
    # Compute full_name from first_name and last_name
    # This ensures consistent full name format across the application
    full_name = f"{first_name} {last_name}".strip()
    
    # ===== Input Validation =====
    # Validate email format using regex pattern
    # This prevents invalid email addresses from being stored
    if not validate_email(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email format"
        )
    
    # Validate username format and length
    # Username must be 3-100 characters, alphanumeric with underscore/hyphen
    username_valid, username_msg = validate_username(username)
    if not username_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=username_msg
        )
    
    # Validate password strength
    # Password must be 8+ characters with uppercase, lowercase, and number
    # BCrypt has 72-byte limit, so we validate byte length
    password_valid, password_msg = validate_password(user_data.password)
    if not password_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=password_msg
        )
    
    # ===== Uniqueness Checks =====
    # Check if email already exists in database
    # Email must be unique across all users
    if await user_repo.email_exists(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if username already exists in database
    # Username must be unique across all users
    if await user_repo.username_exists(username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # ===== User Creation =====
    # Hash password using BCrypt before storage
    # BCrypt automatically generates a salt and handles secure hashing
    hashed_password = get_password_hash(user_data.password)
    
    # Create user record in database
    user = await user_repo.create(
        email=email,
        username=username,
        full_name=full_name,
        hashed_password=hashed_password
    )
    
    # ===== Token Generation =====
    # Generate JWT tokens for immediate authentication
    # Access token: short-lived (30 minutes default)
    # Refresh token: long-lived (7 days default)
    token_data = {"sub": user.id, "username": user.username}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    credentials: UserLogin,
    session: DatabaseSession
) -> TokenResponse:
    """
    Authenticate user and return tokens.
    
    Validates credentials and returns access and refresh tokens.
    Accepts either username or email as the login identifier.
    """
    user_repo = UserRepository(session)
    
    # ===== User Lookup =====
    # Try to get user by username first, then by email
    # This allows flexible login: users can use either username or email
    # This improves UX while maintaining security
    user = await user_repo.get_by_username(credentials.username)
    if not user:
        # If not found by username, try email
        # This dual lookup supports both login methods
        user = await user_repo.get_by_email(credentials.username)
    
    # ===== Password Verification =====
    # Verify password using BCrypt comparison
    # Uses constant-time comparison to prevent timing attacks
    # Generic error message prevents user enumeration attacks
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
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
    
    # ===== Token Generation =====
    # Generate new JWT tokens for authenticated session
    # Tokens include user ID and username in payload
    token_data = {"sub": user.id, "username": user.username}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: CurrentUser
) -> UserResponse:
    """
    Get current authenticated user information.
    
    Returns the profile of the currently authenticated user.
    """
    return UserResponse.from_user_model(current_user)


@router.get("/username/check", response_model=dict)
async def check_username_availability(
    session: DatabaseSession,
    username: str = Query(
        ..., 
        min_length=3, 
        max_length=100, 
        description="Username to check"
    ),
) -> dict:
    """
    Check if a username is available.
    
    Returns availability status for real-time username validation.
    """
    user_repo = UserRepository(session)
    
    # ===== Input Sanitization =====
    # Sanitize username input to prevent injection and ensure consistency
    sanitized_username = sanitize_text(username.strip(), max_length=settings.max_username_length)
    
    # ===== Format Validation =====
    # Validate username format before checking availability
    # This provides immediate feedback on invalid formats
    username_valid, username_msg = validate_username(sanitized_username)
    if not username_valid:
        return {
            "available": False,
            "message": username_msg
        }
    
    # ===== Availability Check =====
    # Check if username already exists in database
    # This enables real-time validation in the frontend
    exists = await user_repo.username_exists(sanitized_username)
    
    return {
        "available": not exists,
        "message": "Username is available" if not exists else "Username already taken"
    }


@router.get("/users/search", response_model=list[UserResponse])
async def search_users(
    current_user: CurrentUser,
    session: DatabaseSession,
    query: str = Query(
        ..., 
        min_length=settings.min_search_query_length, 
        description="Search query (email, username, or name)"
    ),
    limit: int = Query(
        settings.default_search_limit, 
        ge=1, 
        le=settings.max_search_limit, 
        description="Maximum number of results"
    ),
) -> list[UserResponse]:
    """
    Search for registered users.
    
    Searches users by email, username, or full name.
    Useful for finding users to add as recipients.
    Excludes the current user from results.
    """
    user_repo = UserRepository(session)
    
    from app.core.config import settings
    
    # ===== Input Sanitization =====
    # Sanitize search query to prevent injection attacks
    # Limit query length to prevent DoS attacks
    sanitized_query = sanitize_text(query.strip(), max_length=settings.max_search_query_length)
    
    # ===== Privacy Protection =====
    # Exclude current user from search results
    # Users should not see themselves in recipient search
    exclude_user_id = current_user.id if current_user else None
    
    # ===== User Search =====
    # Search users by email, username, or full name
    # Results are ordered by relevance (exact username matches first)
    # Only active users are returned
    users = await user_repo.search_users(
        query=sanitized_query,
        limit=limit,
        exclude_user_id=exclude_user_id
    )
    
    return [UserResponse.from_user_model(user) for user in users]
