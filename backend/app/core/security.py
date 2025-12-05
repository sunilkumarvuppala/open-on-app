"""Security utilities for authentication and authorization."""
from datetime import datetime, timedelta, timezone
from typing import Optional, Any
from jose import JWTError, jwt
import bcrypt
from app.core.config import settings


# Use bcrypt directly to avoid passlib initialization issues
# This is more reliable and avoids compatibility issues with newer bcrypt versions


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a hashed password."""
    try:
        # BCrypt has a 72-byte limit - truncate if necessary
        password_bytes = plain_password.encode('utf-8')
        if len(password_bytes) > settings.bcrypt_max_bytes:
            password_bytes = password_bytes[:settings.bcrypt_max_bytes]
        
        # Verify password
        return bcrypt.checkpw(password_bytes, hashed_password.encode('utf-8'))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """
    Hash a password for storage using bcrypt.
    
    BCrypt has a 72-byte limit, so we truncate if necessary.
    This is safe because we validate password length before hashing.
    """
    # BCrypt has a 72-byte limit - ensure we don't exceed it
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > settings.bcrypt_max_bytes:
        # Truncate to BCrypt's limit
        password_bytes = password_bytes[:settings.bcrypt_max_bytes]
    
    # Generate salt and hash password
    salt = bcrypt.gensalt(rounds=settings.bcrypt_rounds)
    hashed = bcrypt.hashpw(password_bytes, salt)
    
    # Return as string
    return hashed.decode('utf-8')


def create_access_token(data: dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.access_token_expire_minutes)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def create_refresh_token(data: dict[str, Any]) -> str:
    """Create a JWT refresh token."""
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=settings.refresh_token_expire_days)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def decode_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError as e:
        raise ValueError(f"Invalid token: {str(e)}")


def verify_token_type(payload: dict[str, Any], expected_type: str) -> bool:
    """Verify the token type matches expected type."""
    return payload.get("type") == expected_type
