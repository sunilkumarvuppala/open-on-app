"""
Main FastAPI application.

This module is the entry point for the OpenOn backend API.
It configures the FastAPI application, middleware, routes, and lifecycle.

Application Structure:
- Lifespan management (startup/shutdown)
- Middleware configuration (CORS, rate limiting, logging)
- Route registration (auth, capsules, recipients)
- Health check endpoints

Key Features:
- Async database operations
- JWT authentication
- Request logging
- Rate limiting
- Background worker for capsule state transitions
"""
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.base import init_db, close_db
from app.workers.scheduler import start_worker, shutdown_worker
from app.api import auth, capsules, recipients, connections, self_letters, letter_replies
# Note: Drafts API removed - Supabase schema doesn't include drafts table
# Capsules are created directly in 'sealed' status with unlocks_at set
from app.middleware.request_logging import RequestLoggingMiddleware
from app.middleware.rate_limiting import RateLimitingMiddleware
from app.models.schemas import HealthResponse
import logging


# ===== Logging Configuration =====
# Setup logging based on debug mode
# Use INFO level in debug mode, WARNING in production
# Request logs will still show (middleware sets its own level to INFO)
log_level = logging.INFO if settings.debug else logging.WARNING
setup_logging(level=log_level)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    
    Handles startup and shutdown events for the FastAPI application.
    This ensures proper initialization and cleanup of resources.
    
    Startup Sequence:
    1. Initialize database tables
    2. Start background worker for capsule state transitions
    
    Shutdown Sequence:
    1. Stop background worker
    2. Close database connections
    
    Yields:
        Control to FastAPI application
    """
    # ===== Startup =====
    logger.info("🚀 Starting OpenOn API...")
    
    # Initialize database tables
    # Creates all tables defined in models if they don't exist
    await init_db()
    logger.info("✅ Database initialized")
    
    # Start background worker
    # Worker periodically checks capsule unlock times and updates states
    # Runs in separate thread, doesn't block main application
    start_worker()
    logger.info("✅ Background worker started")
    
    # Yield control to FastAPI application
    # Application runs until shutdown signal
    yield
    
    # ===== Shutdown =====
    logger.info("🛑 Shutting down OpenOn API...")
    
    # Stop background worker
    # Gracefully stops worker thread and completes any in-progress tasks
    shutdown_worker()
    logger.info("✅ Background worker stopped")
    
    # Close database connections
    # Disposes of connection pool and releases all database resources
    await close_db()
    logger.info("✅ Database connections closed")


# ===== FastAPI Application =====
# Create FastAPI app with configuration
# lifespan: Manages startup/shutdown events
# docs_url: Swagger UI documentation endpoint
# redoc_url: ReDoc documentation endpoint
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
    ## OpenOn API - Time-Locked Emotional Capsules
    
    A backend service for managing time-locked emotional letters (capsules).
    
    ### Key Features
    
    - 🔐 **Secure Authentication**: JWT-based auth with access and refresh tokens
    - 📬 **Time-Locked Capsules**: Send messages that unlock at a specific future date
    - 🔄 **State Machine**: Capsules follow strict state transitions (sealed → ready → opened → expired)
    - ⏰ **Automated Unlocking**: Background worker automatically updates capsule states
    - 👥 **Recipients**: Manage saved contacts
    - 🔔 **Notifications**: Push and email notifications (coming soon)
    
    ### Capsule States
    
    - **sealed**: Capsule is created with unlock time set, can be edited before opening
    - **ready**: Unlock time has arrived, recipient can open
    - **opened**: Recipient has opened the capsule (terminal state)
    - **expired**: Capsule has expired or been soft-deleted (disappearing messages)
    
    ### Security Rules
    
    - Capsules are created in 'sealed' status with unlocks_at set
    - Status automatically transitions to 'ready' when unlocks_at passes
    - Only recipients can open capsules (when status is 'ready')
    - Anonymous capsules hide sender identity from recipient
    - Disappearing messages are soft-deleted after opening
    """,
    lifespan=lifespan,
    docs_url="/docs",  # Swagger UI at /docs
    redoc_url="/redoc"  # ReDoc at /redoc
)


# ===== Middleware Configuration =====
# Middleware order matters - they execute in reverse order
# Rate limiting first (protects against abuse)
# Request logging second (logs all requests including rate-limited ones)
# CORS last (handles cross-origin requests)

# Rate limiting middleware (add first to protect against abuse)
# Prevents DoS attacks and API abuse
app.add_middleware(RateLimitingMiddleware)

# Request logging middleware (add after rate limiting to log all requests)
# Logs all API requests with timing and user context
app.add_middleware(RequestLoggingMiddleware)

# CORS middleware
# Handles cross-origin requests from frontend
# Only allows requests from configured origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # Allowed frontend origins
    allow_credentials=True,  # Allow cookies/auth headers
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)


# ===== Route Registration =====
# Register all API routers
# Each router handles a specific domain (auth, capsules, recipients)
app.include_router(auth.router)  # Authentication endpoints
app.include_router(capsules.router)  # Capsule management endpoints
app.include_router(recipients.router)  # Recipient management endpoints
app.include_router(connections.router)  # Connection management endpoints
app.include_router(self_letters.router)  # Self letters endpoints
app.include_router(letter_replies.router)  # Letter replies endpoints
# Note: Drafts API removed - not in Supabase schema


@app.get("/", response_model=HealthResponse, tags=["Health"])
async def root() -> HealthResponse:
    """
    Root endpoint - API health check.
    
    Returns basic information about the API status and version.
    Useful for verifying the API is running and accessible.
    
    Returns:
        HealthResponse: API status, timestamp, and version
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc),
        version=settings.app_version
    )


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check() -> HealthResponse:
    """
    Health check endpoint.
    
    Can be used by monitoring systems to verify API availability.
    Returns API status and version information.
    
    Returns:
        HealthResponse: API status, timestamp, and version
    
    Note:
        This endpoint does not require authentication
        Useful for load balancers and monitoring tools
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc),
        version=settings.app_version
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )
