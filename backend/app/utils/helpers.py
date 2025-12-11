"""Utility functions for timezone handling and validation."""
from datetime import datetime, timezone
import pytz
import re
from typing import Optional


def utcnow() -> datetime:
    """Get current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)


def to_utc(dt: datetime) -> datetime:
    """Convert datetime to UTC."""
    if dt.tzinfo is None:
        # Assume naive datetime is UTC
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def is_future(dt: datetime) -> bool:
    """Check if datetime is in the future (UTC comparison)."""
    dt_utc = to_utc(dt)
    now_utc = utcnow()
    return dt_utc > now_utc


def validate_unlock_time(
    unlock_time: datetime,
    min_minutes: Optional[int] = None,
    max_years: Optional[int] = None
) -> tuple[bool, str]:
    """
    Validate unlock time is within acceptable range.
    
    Args:
        unlock_time: The scheduled unlock datetime
        min_minutes: Minimum minutes in the future (uses settings if None)
        max_years: Maximum years in the future (uses settings if None)
    
    Returns:
        Tuple of (is_valid, error_message)
    """
    from datetime import timedelta
    from app.core.config import settings
    
    min_minutes = min_minutes if min_minutes is not None else settings.min_unlock_minutes
    max_years = max_years if max_years is not None else settings.max_unlock_years
    
    unlock_utc = to_utc(unlock_time)
    now_utc = utcnow()
    
    # Check minimum future time
    min_future = now_utc + timedelta(minutes=min_minutes)
    if unlock_utc <= min_future:
        return False, f"Unlock time must be at least {min_minutes} minute(s) in the future"
    
    # Check maximum future time
    max_future = now_utc + timedelta(days=max_years * 365)
    if unlock_utc > max_future:
        return False, f"Unlock time cannot be more than {max_years} years in the future"
    
    return True, "OK"


def sanitize_text(text: str, max_length: Optional[int] = None) -> str:
    """
    Sanitize text input by removing harmful characters.
    
    Args:
        text: Input text to sanitize
        max_length: Optional maximum length
    
    Returns:
        Sanitized text
    """
    if not isinstance(text, str):
        text = str(text)
    
    # Remove null bytes and control characters
    text = text.replace('\x00', '').replace('\r', '')
    
    # Strip leading/trailing whitespace
    text = text.strip()
    
    # Truncate if needed
    if max_length and len(text) > max_length:
        text = text[:max_length]
    
    return text


def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_username(username: str) -> tuple[bool, str]:
    """
    Validate username format.
    
    Rules:
    - 3-100 characters (from settings)
    - Lowercase letters and numbers only
    - Must start with a letter
    
    Args:
        username: Username to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    from app.core.config import settings
    
    if not username:
        return False, "Username cannot be empty"
    
    username = username.strip()
    
    if len(username) < settings.min_username_length:
        return False, f"Username must be at least {settings.min_username_length} characters"
    
    if len(username) > settings.max_username_length:
        return False, f"Username cannot exceed {settings.max_username_length} characters"
    
    # Only lowercase letters and numbers, must start with a letter
    pattern = r'^[a-z][a-z0-9]*$'
    if not re.match(pattern, username):
        if not username[0].isalpha():
            return False, "Username must start with a letter"
        if username != username.lower():
            return False, "Username must contain only lowercase letters and numbers"
        if not all(c.isalnum() for c in username):
            return False, "Username can only contain lowercase letters and numbers"
        return False, "Username must start with a letter and contain only lowercase letters and numbers"
    
    return True, "OK"


def validate_password(password: str) -> tuple[bool, str]:
    """
    Validate password strength.
    
    Rules:
    - Minimum length from settings
    - BCrypt byte limit (72 bytes)
    - At least one uppercase
    - At least one lowercase
    - At least one number
    
    Note: BCrypt has a 72-byte limit, so we validate byte length, not character length.
    """
    from app.core.config import settings
    
    if len(password) < settings.min_password_length:
        return False, f"Password must be at least {settings.min_password_length} characters"
    
    # BCrypt has a 72-byte limit - check byte length, not character length
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > settings.bcrypt_max_bytes:
        return False, f"Password cannot exceed {settings.bcrypt_max_bytes} bytes (approximately {settings.bcrypt_max_bytes} characters for ASCII, less for Unicode)"
    
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    
    if not re.search(r'\d', password):
        return False, "Password must contain at least one number"
    
    return True, "OK"


def format_time_remaining(unlock_time: datetime) -> str:
    """Format time remaining until unlock in human-readable format."""
    unlock_utc = to_utc(unlock_time)
    now_utc = utcnow()
    delta = unlock_utc - now_utc
    
    if delta.total_seconds() <= 0:
        return "Ready now"
    
    days = delta.days
    hours = delta.seconds // 3600
    minutes = (delta.seconds % 3600) // 60
    
    parts = []
    if days > 0:
        parts.append(f"{days} day{'s' if days != 1 else ''}")
    if hours > 0:
        parts.append(f"{hours} hour{'s' if hours != 1 else ''}")
    if minutes > 0 and days == 0:  # Only show minutes if less than a day
        parts.append(f"{minutes} minute{'s' if minutes != 1 else ''}")
    
    return ", ".join(parts) if parts else "Less than a minute"


def make_user_friendly_error(error_message: str) -> str:
    """
    Convert technical error messages to user-friendly messages.
    
    Removes:
    - HTTP status codes (e.g., "HTTP 422", "400:", etc.)
    - Technical error codes
    - Stack traces
    - Internal error details
    
    Args:
        error_message: Raw error message from API/library
        
    Returns:
        User-friendly error message
    """
    if not error_message:
        return "An error occurred. Please try again."
    
    # Remove HTTP status codes and error codes
    # Patterns like "HTTP 422", "400:", "422 Unprocessable Entity", etc.
    error_message = re.sub(r'HTTP\s+\d+[:\s]*', '', error_message, flags=re.IGNORECASE)
    error_message = re.sub(r'\b\d{3}\s+(?:Bad Request|Unauthorized|Forbidden|Not Found|Conflict|Unprocessable Entity|Internal Server Error)\b', '', error_message, flags=re.IGNORECASE)
    error_message = re.sub(r'\b\d{3}:\s*', '', error_message)
    
    # Remove common technical prefixes
    error_message = re.sub(r'^(Error|Exception|Failed|Invalid):\s*', '', error_message, flags=re.IGNORECASE)
    
    # Remove stack trace indicators
    error_message = re.sub(r'Traceback.*?File.*?line \d+.*?', '', error_message, flags=re.DOTALL)
    
    # Remove file paths and technical details in parentheses
    error_message = re.sub(r'\([^)]*\.py[^)]*\)', '', error_message)
    error_message = re.sub(r'at\s+[^\s]+\s+line\s+\d+', '', error_message, flags=re.IGNORECASE)
    
    # Clean up common Supabase error formats and provide user-friendly translations
    error_lower = error_message.lower()
    
    # Email-related errors
    if 'email' in error_lower and ('already' in error_lower or 'exists' in error_lower or 'registered' in error_lower):
        return "This email is already registered. Please use a different email or log in."
    if 'email' in error_lower and ('invalid' in error_lower or 'format' in error_lower):
        return "Please enter a valid email address."
    
    # Password-related errors
    if 'password' in error_lower:
        if 'weak' in error_lower or 'strength' in error_lower:
            return "Password is too weak. Please use a stronger password with uppercase, lowercase, and numbers."
        if 'length' in error_lower or 'short' in error_lower or 'minimum' in error_lower:
            return "Password is too short. Please use at least 8 characters."
        if 'invalid' in error_lower:
            return "Invalid password. Please check your password and try again."
    
    # Username-related errors
    if 'username' in error_lower and ('already' in error_lower or 'taken' in error_lower or 'exists' in error_lower):
        return "This username is already taken. Please choose a different username."
    if 'username' in error_lower and ('invalid' in error_lower or 'format' in error_lower):
        return "Invalid username format. Please use only letters, numbers, underscore, or hyphen."
    
    # Generic cleanup
    error_message = re.sub(r'User already registered', 'Email already registered', error_message, flags=re.IGNORECASE)
    error_message = re.sub(r'duplicate key value', 'already exists', error_message, flags=re.IGNORECASE)
    error_message = re.sub(r'violates.*constraint', 'already exists', error_message, flags=re.IGNORECASE)
    
    # Capitalize first letter and clean up whitespace
    error_message = error_message.strip()
    if error_message:
        error_message = error_message[0].upper() + error_message[1:] if len(error_message) > 1 else error_message.upper()
    
    # Remove multiple spaces
    error_message = re.sub(r'\s+', ' ', error_message)
    
    # If message is empty or too technical, provide a generic one
    if not error_message or len(error_message) < 3:
        return "An error occurred. Please check your input and try again."
    
    return error_message
