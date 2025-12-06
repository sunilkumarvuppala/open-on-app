"""URL helper utilities for consistent URL handling."""
from app.core.config import settings


def normalize_supabase_url(url: str) -> str:
    """
    Normalize Supabase URL for better compatibility.
    
    Replaces 'localhost' with '127.0.0.1' for httpx compatibility.
    
    Args:
        url: Supabase URL (from settings or parameter)
    
    Returns:
        Normalized URL with localhost replaced
    """
    return url.replace("localhost", "127.0.0.1")

