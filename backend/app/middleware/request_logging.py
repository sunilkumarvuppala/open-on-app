"""
Request logging middleware for FastAPI.

This middleware logs all HTTP requests and responses for monitoring,
debugging, and audit purposes. It captures request details, response
status codes, processing times, and user context.

Logs Include:
- HTTP method and path
- Query parameters
- Response status code
- Processing time (milliseconds)
- User ID (if authenticated)
- Client IP address

Excludes:
- Request/response bodies (may contain sensitive data like passwords)
- Health check endpoints (to reduce log noise)

Log Levels:
- INFO: Successful requests (2xx)
- WARNING: Client errors (4xx)
- ERROR: Server errors (5xx)
"""
import time
import logging
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp


# ===== Logger Configuration =====
# Get logger for request logging middleware
# Use a specific name so we can control its level independently
logger = logging.getLogger("app.middleware.request_logging")
# Ensure request logging is always visible (set to INFO level)
# This overrides root logger level for this specific logger
logger.setLevel(logging.INFO)
# Still propagate to root logger (for centralized logging)
logger.propagate = True


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware to log HTTP requests and responses.
    
    Logs all API requests with detailed information for monitoring
    and debugging. Provides audit trail of all API activity.
    
    Logs:
    - Request method, path, and query parameters
    - Response status code
    - Processing time (milliseconds)
    - User ID (if authenticated)
    - Client IP address
    
    Excludes:
    - Request/response bodies (may contain sensitive data)
    - Health check endpoints (to reduce noise)
    
    Log Levels:
    - INFO: 2xx responses (successful)
    - WARNING: 4xx responses (client errors)
    - ERROR: 5xx responses (server errors)
    """
    
    # ===== Endpoints to Skip =====
    # Endpoints that don't need logging (health checks, documentation)
    # These generate too much noise and aren't useful for monitoring
    SKIP_PATHS = {"/", "/health", "/docs", "/redoc", "/openapi.json"}
    
    def __init__(self, app: ASGIApp):
        """
        Initialize middleware and log that it's active.
        
        Args:
            app: ASGI application
        """
        super().__init__(app)
        logger.info("📝 Request logging middleware initialized")
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process request and log details.
        
        This method intercepts all requests, measures processing time,
        and logs request/response information.
        
        Args:
            request: FastAPI request object
            call_next: Next middleware/handler in chain
        
        Returns:
            Response from next handler
        
        Note:
            Logs are written in finally block to ensure they're always logged
            even if an exception occurs
        """
        # ===== Skip Logging for Public Endpoints =====
        # Skip logging for health checks and documentation
        # These generate too much noise and aren't useful for monitoring
        if request.url.path in self.SKIP_PATHS:
            return await call_next(request)
        
        # ===== Start Timer =====
        # Record start time to calculate processing duration
        start_time = time.time()
        
        # ===== Extract Request Details =====
        method = request.method
        path = request.url.path
        query_params = str(request.query_params) if request.query_params else None
        
        # ===== Get Client IP =====
        # Extract client IP, handling reverse proxies
        client_ip = request.client.host if request.client else "unknown"
        if "x-forwarded-for" in request.headers:
            # Use first IP in forwarded chain (original client)
            client_ip = request.headers["x-forwarded-for"].split(",")[0].strip()
        
        # ===== Get User Context =====
        # Get user ID if authenticated (set by auth dependency)
        # This provides user context for audit trails
        user_id = getattr(request.state, "user_id", None)
        
        # ===== Process Request =====
        # Execute request and capture response/errors
        response = None
        status_code = 500
        error = None
        
        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            # Capture exception for logging
            status_code = 500
            error = str(e)
            raise
        finally:
            # ===== Calculate Processing Time =====
            # Calculate time taken to process request (milliseconds)
            process_time = time.time() - start_time
            
            # ===== Determine Log Level =====
            # Use appropriate log level based on response status
            # ERROR: Server errors (5xx)
            # WARNING: Client errors (4xx)
            # INFO: Successful requests (2xx, 3xx)
            if status_code >= 500:
                log_level = logging.ERROR
            elif status_code >= 400:
                log_level = logging.WARNING
            else:
                log_level = logging.INFO
            
            # ===== Build Log Data =====
            # Collect all relevant information for logging
            log_data = {
                "method": method,
                "path": path,
                "status_code": status_code,
                "process_time_ms": round(process_time * 1000, 2),  # Convert to milliseconds
                "client_ip": client_ip,
            }
            
            # Add optional fields if present
            if query_params:
                log_data["query_params"] = query_params
            
            if user_id:
                log_data["user_id"] = user_id  # User context for audit trail
            
            if error:
                log_data["error"] = error  # Error details for debugging
            
            # ===== Build Log Message =====
            # Create human-readable log message
            log_message = (
                f"{method} {path} - {status_code} - "
                f"{log_data['process_time_ms']}ms"
            )
            if user_id:
                log_message += f" - user:{user_id}"
            if error:
                log_message += f" - error:{error}"
            
            # ===== Log Request =====
            # Log with appropriate level and extra data
            logger.log(
                log_level,
                log_message,
                extra=log_data  # Extra data for structured logging
            )
        
        return response

