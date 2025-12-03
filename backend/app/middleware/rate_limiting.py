"""
Rate limiting middleware for FastAPI.

This middleware implements rate limiting to prevent API abuse and DoS attacks.
Uses a sliding window algorithm to track requests per IP address.

Algorithm:
- Tracks request timestamps per IP address
- Uses 60-second sliding window
- Blocks requests that exceed rate_limit_per_minute

Limitations:
- In-memory storage (lost on restart)
- Not distributed (each instance has separate limits)
- For production, consider Redis-based rate limiting

Configuration:
- rate_limit_per_minute: Maximum requests per minute per IP
"""
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
    
    Implements sliding window rate limiting per IP address.
    Tracks request timestamps and blocks requests that exceed the limit.
    
    Features:
    - Sliding window algorithm (60-second window)
    - Per-IP tracking
    - Automatic cleanup of old entries
    - Skips health check endpoints
    
    Configuration:
    - rate_limit_per_minute: Maximum requests per minute per IP
    
    Note:
    - Uses in-memory storage (not distributed)
    - For production scale, consider Redis-based solution
    """
    
    def __init__(self, app: ASGIApp):
        """
        Initialize rate limiting middleware.
        
        Sets up request tracking dictionary and cleanup configuration.
        """
        super().__init__(app)
        # ===== Request Tracking =====
        # Store request timestamps per IP address
        # Format: {ip_address: [timestamp1, timestamp2, ...]}
        # Only timestamps from last 60 seconds are kept
        self._request_times: Dict[str, list[float]] = defaultdict(list)
        
        # ===== Cleanup Configuration =====
        # Cleanup old entries periodically to prevent memory leaks
        # Cleanup runs every N requests (not every request for performance)
        self._cleanup_counter = 0
        self._cleanup_interval = 1000  # Cleanup every 1000 requests
        
        logger.info(
            f"🛡️  Rate limiting middleware initialized: "
            f"{settings.rate_limit_per_minute} requests/minute"
        )
    
    def _cleanup_old_entries(self):
        """
        Remove old entries to prevent memory leak.
        
        This method periodically removes request timestamps older than 60 seconds.
        Prevents memory from growing indefinitely as new IPs make requests.
        
        Note:
            Runs every N requests (not every request) for performance
            Removes IPs with no recent requests to free memory
        """
        self._cleanup_counter += 1
        if self._cleanup_counter < self._cleanup_interval:
            return
        
        # Reset counter and perform cleanup
        self._cleanup_counter = 0
        current_time = time.time()
        cutoff_time = current_time - 60  # Keep only last 60 seconds
        
        # ===== Cleanup Old Timestamps =====
        # Remove timestamps older than 60 seconds
        # Remove IPs with no recent requests
        ips_to_remove = []
        for ip, timestamps in self._request_times.items():
            # Keep only timestamps from the last minute
            self._request_times[ip] = [
                ts for ts in timestamps if ts > cutoff_time
            ]
            # Mark IP for removal if no recent requests
            if not self._request_times[ip]:
                ips_to_remove.append(ip)
        
        # Remove IPs with no recent requests
        for ip in ips_to_remove:
            del self._request_times[ip]
    
    def _get_client_ip(self, request: Request) -> str:
        """
        Extract client IP address, considering proxies.
        
        Handles requests behind reverse proxies (e.g., nginx, load balancers).
        Checks headers in order of preference.
        
        Args:
            request: FastAPI request object
        
        Returns:
            Client IP address as string
        
        Headers Checked:
        1. x-forwarded-for: Standard proxy header (first IP in chain)
        2. x-real-ip: Alternative proxy header
        3. request.client.host: Direct client IP (fallback)
        """
        # ===== Proxy Header Check =====
        # Check for forwarded IP (from reverse proxy/load balancer)
        # x-forwarded-for contains comma-separated IP chain
        # Use first IP (original client)
        if "x-forwarded-for" in request.headers:
            return request.headers["x-forwarded-for"].split(",")[0].strip()
        
        # ===== Alternative Proxy Header =====
        # Check for real IP header (some proxies use this)
        if "x-real-ip" in request.headers:
            return request.headers["x-real-ip"]
        
        # ===== Direct Client IP =====
        # Fallback to direct client IP (when no proxy)
        if request.client:
            return request.client.host
        
        # Unknown IP (shouldn't happen, but handle gracefully)
        return "unknown"
    
    def _is_rate_limited(self, ip: str) -> bool:
        """
        Check if IP has exceeded rate limit.
        
        Uses sliding window algorithm:
        - Tracks requests in last 60 seconds
        - Counts requests in window
        - Returns True if limit exceeded
        
        Args:
            ip: Client IP address
        
        Returns:
            True if rate limit exceeded, False otherwise
        
        Note:
            Automatically removes old timestamps outside window
            Adds current request timestamp if not rate limited
        """
        current_time = time.time()
        window_start = current_time - 60  # Last 60 seconds (sliding window)
        
        # ===== Get Recent Requests =====
        # Get request timestamps for this IP
        timestamps = self._request_times[ip]
        
        # ===== Remove Old Timestamps =====
        # Remove timestamps outside the 60-second window
        # This implements the sliding window algorithm
        timestamps[:] = [ts for ts in timestamps if ts > window_start]
        
        # ===== Check Rate Limit =====
        # Check if number of requests in window exceeds limit
        if len(timestamps) >= settings.rate_limit_per_minute:
            return True
        
        # ===== Add Current Request =====
        # Add current request timestamp if not rate limited
        timestamps.append(current_time)
        return False
    
    async def dispatch(self, request: Request, call_next):
        """
        Process request with rate limiting.
        
        This method is called for every request. It checks if the client
        has exceeded the rate limit and either processes the request or
        returns a 429 Too Many Requests error.
        
        Args:
            request: FastAPI request object
            call_next: Next middleware/handler in chain
        
        Returns:
            Response from next handler, or 429 error if rate limited
        
        Note:
            Skips rate limiting for health check and documentation endpoints
            Performs periodic cleanup to prevent memory leaks
        """
        # ===== Skip Rate Limiting for Public Endpoints =====
        # Health checks and documentation don't need rate limiting
        # These endpoints are lightweight and don't pose abuse risk
        if request.url.path in ["/", "/health", "/docs", "/redoc", "/openapi.json"]:
            return await call_next(request)
        
        # ===== Get Client IP =====
        # Extract client IP (handles proxies correctly)
        client_ip = self._get_client_ip(request)
        
        # ===== Check Rate Limit =====
        # Check if client has exceeded rate limit
        if self._is_rate_limited(client_ip):
            logger.warning(
                f"Rate limit exceeded for IP: {client_ip} - "
                f"{request.method} {request.url.path}"
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Maximum {settings.rate_limit_per_minute} requests per minute.",
                headers={"Retry-After": "60"}  # Tell client to retry after 60 seconds
            )
        
        # ===== Periodic Cleanup =====
        # Clean up old entries periodically to prevent memory leaks
        # Runs every N requests (not every request for performance)
        self._cleanup_old_entries()
        
        # ===== Process Request =====
        # Request is within rate limit, proceed to next handler
        return await call_next(request)

