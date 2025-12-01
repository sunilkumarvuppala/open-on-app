"""Core configuration and settings for OpenOn backend."""
from typing import Optional
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from datetime import timedelta


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # App
    app_name: str = "OpenOn API"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # Database
    database_url: str = Field(
        default="sqlite+aiosqlite:///./openon.db",
        description="Database connection string"
    )
    db_echo: bool = False
    
    # Security
    secret_key: str = Field(
        default="CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE",
        description="Secret key for JWT encoding"
    )
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8000"]
    
    # Rate limiting
    rate_limit_per_minute: int = 60
    
    # Capsule constraints
    min_unlock_minutes: int = 1
    max_unlock_years: int = 5
    early_view_threshold_days: int = 3
    
    # Pagination defaults
    default_page_size: int = 20
    max_page_size: int = 100
    min_page_size: int = 1
    
    # Search constraints
    min_search_query_length: int = 2
    max_search_query_length: int = 100
    default_search_limit: int = 10
    max_search_limit: int = 50
    
    # Username constraints
    min_username_length: int = 3
    max_username_length: int = 100
    
    # Name constraints
    min_name_length: int = 1
    max_name_length: int = 100
    max_full_name_length: int = 255
    
    # Content constraints
    min_content_length: int = 1
    max_content_length: int = 10000
    max_title_length: int = 255
    max_theme_length: int = 50
    
    # Background worker
    worker_check_interval_seconds: int = 60
    
    # Notifications (placeholders for future integration)
    fcm_api_key: Optional[str] = None
    apns_key_path: Optional[str] = None
    email_smtp_host: Optional[str] = None
    email_smtp_port: Optional[int] = None
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    @field_validator("secret_key")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """Ensure secret key is changed in production."""
        if v == "CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE":
            import warnings
            warnings.warn(
                "Using default secret key! Change this in production!",
                UserWarning
            )
        return v


# Global settings instance
settings = Settings()
