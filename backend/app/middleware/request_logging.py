"""Request logging middleware for FastAPI."""
import time
import logging
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp


# Get logger for request logging middleware
# Use a specific name so we can control its level independently
logger = logging.getLogger("app.middleware.request_logging")
# Ensure request logging is always visible (set to INFO level)
logger.setLevel(logging.INFO)
# Prevent propagation to root logger level restrictions
logger.propagate = True  # Still propagate, but our level takes precedence


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware to log HTTP requests and responses.
    
    Logs:
    - Request method, path, and query parameters
    - Response status code
    - Processing time
    - User ID (if authenticated)
    - Client IP address
    
    Excludes:
    - Request/response bodies (may contain sensitive data)
    - Health check endpoints (to reduce noise)
    """
    
    # Endpoints to skip logging (health checks, etc.)
    SKIP_PATHS = {"/", "/health", "/docs", "/redoc", "/openapi.json"}
    
    def __init__(self, app: ASGIApp):
        """Initialize middleware and log that it's active."""
        super().__init__(app)
        logger.info("📝 Request logging middleware initialized")
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and log details."""
        # Skip logging for certain paths
        if request.url.path in self.SKIP_PATHS:
            return await call_next(request)
        
        # Start timer
        start_time = time.time()
        
        # Extract request details
        method = request.method
        path = request.url.path
        query_params = str(request.query_params) if request.query_params else None
        
        # Get client IP (considering proxies)
        client_ip = request.client.host if request.client else "unknown"
        if "x-forwarded-for" in request.headers:
            client_ip = request.headers["x-forwarded-for"].split(",")[0].strip()
        
        # Get user ID if authenticated (from request state set by auth dependency)
        user_id = getattr(request.state, "user_id", None)
        
        # Process request
        response = None
        status_code = 500
        error = None
        
        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            status_code = 500
            error = str(e)
            raise
        finally:
            # Calculate processing time
            process_time = time.time() - start_time
            
            # Determine log level based on status code
            if status_code >= 500:
                log_level = logging.ERROR
            elif status_code >= 400:
                log_level = logging.WARNING
            else:
                log_level = logging.INFO
            
            # Build log message
            log_data = {
                "method": method,
                "path": path,
                "status_code": status_code,
                "process_time_ms": round(process_time * 1000, 2),
                "client_ip": client_ip,
            }
            
            if query_params:
                log_data["query_params"] = query_params
            
            if user_id:
                log_data["user_id"] = user_id
            
            if error:
                log_data["error"] = error
            
            # Log the request
            log_message = (
                f"{method} {path} - {status_code} - "
                f"{log_data['process_time_ms']}ms"
            )
            if user_id:
                log_message += f" - user:{user_id}"
            if error:
                log_message += f" - error:{error}"
            
            logger.log(
                log_level,
                log_message,
                extra=log_data
            )
        
        return response

