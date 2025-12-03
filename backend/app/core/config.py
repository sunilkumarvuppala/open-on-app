"""
Core configuration and settings for OpenOn backend.

This module centralizes all application configuration using Pydantic Settings.
All configuration values can be overridden via environment variables.

Configuration Categories:
- Application: Name, version, debug mode
- Database: Connection string, echo mode
- Security: JWT secret key, token expiration
- CORS: Allowed origins
- Rate Limiting: Requests per minute
- Capsule Constraints: Unlock time limits
- Pagination: Default page sizes
- Validation: Field length limits
"""
from typing import Optional
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from datetime import timedelta


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    
    All settings can be overridden via environment variables or .env file.
    Settings are validated on load and provide type safety.
    """
    
    # ===== Application Settings =====
    app_name: str = "OpenOn API"
    app_version: str = "1.0.0"
    debug: bool = False  # Enable debug mode (shows detailed errors, auto-reload)
    
    # ===== Database Configuration =====
    database_url: str = Field(
        default="sqlite+aiosqlite:///./openon.db",
        description="Database connection string"
    )
    db_echo: bool = False  # Echo SQL queries to console (useful for debugging)
    
    # ===== Security Settings =====
    secret_key: str = Field(
        default="CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE",
        description="Secret key for JWT encoding"
    )
    algorithm: str = "HS256"  # JWT signing algorithm
    access_token_expire_minutes: int = 30  # Access token lifetime (short-lived)
    refresh_token_expire_days: int = 7  # Refresh token lifetime (long-lived)
    
    # ===== CORS Configuration =====
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8000"]
    # Allowed origins for cross-origin requests
    # In production, set to your frontend domain(s)
    
    # ===== Rate Limiting =====
    rate_limit_per_minute: int = 60
    # Maximum requests per minute per IP address
    # Prevents abuse and DoS attacks
    
    # ===== Capsule Constraints =====
    min_unlock_minutes: int = 1  # Minimum time until unlock (prevents past dates)
    max_unlock_years: int = 5  # Maximum time until unlock (prevents excessive storage)
    early_view_threshold_days: int = 3  # Days before unlock for UNFOLDING state
    
    # ===== Pagination Defaults =====
    default_page: int = 1  # Default page number (1-indexed)
    default_page_size: int = 20  # Default items per page
    max_page_size: int = 100  # Maximum items per page (prevents DoS)
    min_page_size: int = 1  # Minimum items per page
    
    # ===== Search Constraints =====
    min_search_query_length: int = 2  # Minimum search query length
    max_search_query_length: int = 100  # Maximum search query length
    default_search_limit: int = 10  # Default search results limit
    max_search_limit: int = 50  # Maximum search results (prevents DoS)
    
    # ===== Username Constraints =====
    min_username_length: int = 3  # Minimum username length
    max_username_length: int = 100  # Maximum username length
    
    # ===== Name Constraints =====
    min_name_length: int = 1  # Minimum name length
    max_name_length: int = 100  # Maximum first/last name length
    max_full_name_length: int = 255  # Maximum full name length
    
    # ===== Email Constraints =====
    max_email_length: int = 254  # RFC 5321 maximum email length
    
    # ===== Password Constraints =====
    min_password_length: int = 8  # Minimum password length
    max_password_length: int = 128  # Maximum password length
    # Note: BCrypt has 72-byte limit, but we allow longer for hashing truncation
    
    # ===== Content Constraints =====
    min_content_length: int = 1  # Minimum capsule content length
    max_content_length: int = 10000  # Maximum capsule content length
    max_title_length: int = 255  # Maximum capsule title length
    max_theme_length: int = 50  # Maximum theme name length
    
    # ===== Background Worker =====
    worker_check_interval_seconds: int = 60
    # Interval for background worker to check capsule unlock times
    # Lower values = more frequent checks but higher CPU usage
    
    # ===== Notifications (Future Integration) =====
    fcm_api_key: Optional[str] = None  # Firebase Cloud Messaging API key
    apns_key_path: Optional[str] = None  # Apple Push Notification Service key path
    email_smtp_host: Optional[str] = None  # SMTP server host for email notifications
    email_smtp_port: Optional[int] = None  # SMTP server port
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    @field_validator("secret_key")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """
        Validate secret key and warn if using default.
        
        This validator ensures that the default secret key is not used
        in production, as it would be a critical security vulnerability.
        
        Args:
            v: The secret key value
        
        Returns:
            The secret key value (unchanged)
        
        Note:
            Emits a warning if default key is detected
            In production, always use a strong random secret key
        """
        if v == "CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE":
            import warnings
            warnings.warn(
                "Using default secret key! Change this in production!",
                UserWarning
            )
        return v


# ===== Global Settings Instance =====
# Single instance loaded at module import time
# All modules import this instance for configuration access
settings = Settings()
