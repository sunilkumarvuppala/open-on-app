"""
Pagination utilities for API endpoints.

This module provides reusable pagination calculation functions.
"""
from app.core.config import settings


def calculate_pagination(page: int, page_size: int) -> tuple[int, int]:
    """
    Calculate skip and limit values for pagination.
    
    Args:
        page: Page number (1-indexed)
        page_size: Number of items per page
        
    Returns:
        Tuple of (skip, limit) for database queries
    """
    skip = (page - 1) * page_size
    return skip, page_size


def get_default_page_size() -> int:
    """Get default page size from settings."""
    return settings.default_page_size


def get_max_page_size() -> int:
    """Get maximum page size from settings."""
    return settings.max_page_size


def get_min_page_size() -> int:
    """Get minimum page size from settings."""
    return settings.min_page_size

