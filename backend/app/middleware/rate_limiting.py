"""Rate limiting middleware for FastAPI."""
import time
from collections import defaultdict
from typing import Dict, Tuple
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
from app.core.config import settings
import logging


logger = logging.getLogger(__name__)


class RateLimitingMiddleware(BaseHTTPMiddleware):
    """
    Rate limiting middleware to prevent abuse.
    
    Uses a simple in-memory sliding window algorithm.
    For production, consider using Redis-based rate limiting.
    
    Configuration:
    - rate_limit_per_minute: Maximum requests per minute per IP
    """
    
    def __init__(self, app: ASGIApp):
        """Initialize rate limiting middleware."""
        super().__init__(app)
        # Store request timestamps per IP: {ip: [timestamp1, timestamp2, ...]}
        self._request_times: Dict[str, list[float]] = defaultdict(list)
        # Cleanup interval (clean old entries every N requests)
        self._cleanup_counter = 0
        self._cleanup_interval = 1000
        logger.info(
            f"🛡️  Rate limiting middleware initialized: "
            f"{settings.rate_limit_per_minute} requests/minute"
        )
    
    def _cleanup_old_entries(self):
        """Remove old entries to prevent memory leak."""
        self._cleanup_counter += 1
        if self._cleanup_counter < self._cleanup_interval:
            return
        
        self._cleanup_counter = 0
        current_time = time.time()
        cutoff_time = current_time - 60  # Keep only last minute
        
        # Clean up old entries
        ips_to_remove = []
        for ip, timestamps in self._request_times.items():
            # Keep only timestamps from the last minute
            self._request_times[ip] = [
                ts for ts in timestamps if ts > cutoff_time
            ]
            # Remove IP if no recent requests
            if not self._request_times[ip]:
                ips_to_remove.append(ip)
        
        for ip in ips_to_remove:
            del self._request_times[ip]
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP address, considering proxies."""
        # Check for forwarded IP (from reverse proxy)
        if "x-forwarded-for" in request.headers:
            return request.headers["x-forwarded-for"].split(",")[0].strip()
        
        # Check for real IP header
        if "x-real-ip" in request.headers:
            return request.headers["x-real-ip"]
        
        # Fallback to direct client IP
        if request.client:
            return request.client.host
        
        return "unknown"
    
    def _is_rate_limited(self, ip: str) -> bool:
        """Check if IP has exceeded rate limit."""
        current_time = time.time()
        window_start = current_time - 60  # Last 60 seconds
        
        # Get recent requests for this IP
        timestamps = self._request_times[ip]
        
        # Remove timestamps outside the window
        timestamps[:] = [ts for ts in timestamps if ts > window_start]
        
        # Check if limit exceeded
        if len(timestamps) >= settings.rate_limit_per_minute:
            return True
        
        # Add current request
        timestamps.append(current_time)
        return False
    
    async def dispatch(self, request: Request, call_next):
        """Process request with rate limiting."""
        # Skip rate limiting for health checks
        if request.url.path in ["/", "/health", "/docs", "/redoc", "/openapi.json"]:
            return await call_next(request)
        
        # Get client IP
        client_ip = self._get_client_ip(request)
        
        # Check rate limit
        if self._is_rate_limited(client_ip):
            logger.warning(
                f"Rate limit exceeded for IP: {client_ip} - "
                f"{request.method} {request.url.path}"
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Maximum {settings.rate_limit_per_minute} requests per minute.",
                headers={"Retry-After": "60"}
            )
        
        # Periodic cleanup
        self._cleanup_old_entries()
        
        # Process request
        return await call_next(request)

