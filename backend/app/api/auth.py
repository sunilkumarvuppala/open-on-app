"""Authentication API routes."""
from fastapi import APIRouter, HTTPException, status, Query, Depends
from app.models.schemas import UserCreate, UserLogin, UserResponse, TokenResponse
from app.dependencies import DatabaseSession, CurrentUser
from app.db.repositories import UserRepository
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.utils.helpers import validate_username, validate_password, sanitize_text, validate_email


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
    
    from app.core.config import settings
    
    # Sanitize and validate inputs
    email = sanitize_text(user_data.email.lower().strip(), max_length=254)
    username = sanitize_text(user_data.username.strip(), max_length=settings.max_username_length)
    first_name = sanitize_text(user_data.first_name.strip(), max_length=settings.max_name_length)
    last_name = sanitize_text(user_data.last_name.strip(), max_length=settings.max_name_length)
    # Compute full_name from first_name and last_name
    full_name = f"{first_name} {last_name}".strip()
    
    # Validate email format
    if not validate_email(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email format"
        )
    
    # Validate username
    username_valid, username_msg = validate_username(username)
    if not username_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=username_msg
        )
    
    # Validate password
    password_valid, password_msg = validate_password(user_data.password)
    if not password_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=password_msg
        )
    
    # Check if email already exists
    if await user_repo.email_exists(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if username already exists
    if await user_repo.username_exists(username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Create user
    hashed_password = get_password_hash(user_data.password)
    user = await user_repo.create(
        email=email,
        username=username,
        full_name=full_name,
        hashed_password=hashed_password
    )
    
    # Generate tokens
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
    
    # Try to get user by username first, then by email
    # This allows login with either username or email
    user = await user_repo.get_by_username(credentials.username)
    if not user:
        # If not found by username, try email
        user = await user_repo.get_by_email(credentials.username)
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Generate tokens
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
    
    # Sanitize username
    sanitized_username = sanitize_text(username.strip(), max_length=100)
    
    # Validate username format
    username_valid, username_msg = validate_username(sanitized_username)
    if not username_valid:
        return {
            "available": False,
            "message": username_msg
        }
    
    # Check if username exists
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
        min_length=2, 
        description="Search query (email, username, or name)"
    ),
    limit: int = Query(
        10, 
        ge=1, 
        le=50, 
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
    
    # Sanitize search query
    sanitized_query = sanitize_text(query.strip(), max_length=settings.max_search_query_length)
    
    # Exclude current user from search results
    exclude_user_id = current_user.id if current_user else None
    
    users = await user_repo.search_users(
        query=sanitized_query,
        limit=limit,
        exclude_user_id=exclude_user_id
    )
    
    return [UserResponse.from_user_model(user) for user in users]
