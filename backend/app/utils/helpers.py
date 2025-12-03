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


def validate_unlock_time(unlock_time: datetime, min_minutes: int = 1, max_years: int = 5) -> tuple[bool, str]:
    """
    Validate unlock time is within acceptable range.
    
    Args:
        unlock_time: The scheduled unlock datetime
        min_minutes: Minimum minutes in the future
        max_years: Maximum years in the future
    
    Returns:
        Tuple of (is_valid, error_message)
    """
    from datetime import timedelta
    
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
    - 3-100 characters
    - Alphanumeric, underscore, hyphen only
    - Must start with letter or number
    """
    from app.core.config import settings
    
    if len(username) < settings.min_username_length:
        return False, f"Username must be at least {settings.min_username_length} characters"
    
    if len(username) > settings.max_username_length:
        return False, f"Username cannot exceed {settings.max_username_length} characters"
    
    pattern = r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$'
    if not re.match(pattern, username):
        return False, "Username must start with letter/number and contain only letters, numbers, underscore, or hyphen"
    
    return True, "OK"


def validate_password(password: str) -> tuple[bool, str]:
    """
    Validate password strength.
    
    Rules:
    - 8-72 bytes (BCrypt limit is 72 bytes)
    - At least one uppercase
    - At least one lowercase
    - At least one number
    
    Note: BCrypt has a 72-byte limit, so we validate byte length, not character length.
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters"
    
    # BCrypt has a 72-byte limit - check byte length, not character length
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        return False, "Password cannot exceed 72 bytes (approximately 72 characters for ASCII, less for Unicode)"
    
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
