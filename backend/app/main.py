"""Main FastAPI application."""
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.base import init_db, close_db
from app.workers.scheduler import start_worker, shutdown_worker
from app.api import auth, capsules, drafts, recipients
from app.models.schemas import HealthResponse
import logging


# Setup logging
setup_logging(level=logging.INFO if settings.debug else logging.WARNING)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    
    Handles startup and shutdown events:
    - Initialize database
    - Start background worker
    - Cleanup on shutdown
    """
    # Startup
    logger.info("🚀 Starting OpenOn API...")
    
    # Initialize database
    await init_db()
    logger.info("✅ Database initialized")
    
    # Start background worker
    start_worker()
    logger.info("✅ Background worker started")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down OpenOn API...")
    
    # Stop background worker
    shutdown_worker()
    logger.info("✅ Background worker stopped")
    
    # Close database connections
    await close_db()
    logger.info("✅ Database connections closed")


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
    ## OpenOn API - Time-Locked Emotional Capsules
    
    A backend service for managing time-locked emotional letters (capsules).
    
    ### Key Features
    
    - 🔐 **Secure Authentication**: JWT-based auth with access and refresh tokens
    - 📬 **Time-Locked Capsules**: Send messages that unlock at a specific future date
    - 🔄 **State Machine**: Capsules follow strict state transitions (draft → sealed → unfolding → ready → opened)
    - ⏰ **Automated Unlocking**: Background worker automatically updates capsule states
    - 📝 **Drafts**: Save and edit messages before sending
    - 👥 **Recipients**: Manage saved contacts
    - 🔔 **Notifications**: Push and email notifications (coming soon)
    
    ### Capsule States
    
    - **draft**: Capsule is being created and can be edited
    - **sealed**: Unlock time is set, no further edits allowed
    - **unfolding**: Less than 3 days until unlock (teaser state)
    - **ready**: Unlock time has arrived, receiver can open
    - **opened**: Receiver has opened the capsule (terminal state)
    
    ### Security Rules
    
    - Unlock times cannot be changed after sealing
    - States cannot be reversed
    - Users cannot cheat by changing clocks (UTC timestamps)
    - Only senders can edit drafts
    - Only receivers can open capsules
    """,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)


# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routers
app.include_router(auth.router)
app.include_router(capsules.router)
app.include_router(drafts.router)
app.include_router(recipients.router)


@app.get("/", response_model=HealthResponse, tags=["Health"])
async def root() -> HealthResponse:
    """
    Root endpoint - API health check.
    
    Returns basic information about the API status and version.
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
