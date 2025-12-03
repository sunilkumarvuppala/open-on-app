"""
Background worker for scheduled capsule unlock checks.

This module provides a background worker that periodically checks capsules
for state transitions. It uses APScheduler to run unlock checks on a schedule.

The worker:
- Runs unlock checks at regular intervals (configurable)
- Prevents concurrent runs (max_instances=1)
- Handles errors gracefully
- Can be started/stopped on application lifecycle

Configuration:
- worker_check_interval_seconds: How often to run unlock checks (default: 60s)
"""
import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from app.db.base import AsyncSessionLocal
from app.services.unlock_service import run_unlock_check
from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger(__name__)


class UnlockWorker:
    """
    Background worker for capsule unlock monitoring.
    
    This worker runs periodically to check if any capsules need state
    transitions (e.g., SEALED → UNFOLDING → READY). It uses APScheduler
    to schedule and run unlock checks.
    
    Features:
    - Scheduled execution at configurable intervals
    - Prevents concurrent runs (max_instances=1)
    - Graceful error handling
    - Start/stop lifecycle management
    
    Usage:
        Worker is started automatically when application starts
        Worker is stopped automatically when application shuts down
    """
    
    def __init__(self):
        """
        Initialize the worker with scheduler.
        
        Creates an AsyncIOScheduler instance for scheduling jobs.
        Worker is not running until start() is called.
        """
        self.scheduler = AsyncIOScheduler()
        self.is_running = False
    
    async def unlock_check_job(self) -> None:
        """
        Job that checks and updates capsule states.
        
        This is the scheduled job that runs periodically.
        It creates a new database session, runs the unlock check,
        and handles any errors that occur.
        
        Note:
            Creates a new session for each run to ensure isolation
            Errors are logged but don't crash the worker
        """
        try:
            # ===== Create New Session =====
            # Create a new session for this job run
            # This ensures each run has a clean database connection
            async with AsyncSessionLocal() as session:
                stats = await run_unlock_check(session)
                logger.debug(f"Unlock check completed: {stats}")
        except Exception as e:
            # ===== Error Handling =====
            # Log errors but don't crash the worker
            # This ensures the worker continues running even if one check fails
            logger.error(f"Error in unlock check job: {str(e)}", exc_info=True)
    
    def start(self) -> None:
        """
        Start the background worker.
        
        Schedules the unlock check job to run at regular intervals
        and starts the scheduler. If already running, logs a warning.
        
        Configuration:
            - Interval: settings.worker_check_interval_seconds
            - Max instances: 1 (prevents concurrent runs)
            - Job ID: "unlock_watcher" (for identification)
        
        Note:
            replace_existing=True ensures we can restart the worker safely
            max_instances=1 prevents multiple jobs running simultaneously
        """
        if self.is_running:
            logger.warning("Worker is already running")
            return
        
        # ===== Schedule Unlock Check Job =====
        # Add the unlock check job to the scheduler
        # Runs at regular intervals (e.g., every 60 seconds)
        self.scheduler.add_job(
            self.unlock_check_job,
            trigger=IntervalTrigger(seconds=settings.worker_check_interval_seconds),
            id="unlock_watcher",
            name="Capsule Unlock Watcher",
            replace_existing=True,  # Replace if job already exists
            max_instances=1,  # Prevent concurrent runs (important for database consistency)
        )
        
        # ===== Start Scheduler =====
        # Start the scheduler to begin running jobs
        self.scheduler.start()
        self.is_running = True
        
        logger.info(
            f"🚀 Background worker started (check interval: "
            f"{settings.worker_check_interval_seconds}s)"
        )
    
    def shutdown(self) -> None:
        """
        Shutdown the background worker.
        
        Stops the scheduler and marks the worker as not running.
        If not running, does nothing.
        
        Note:
            Called automatically on application shutdown
            Ensures clean shutdown of background tasks
        """
        if not self.is_running:
            return
        
        # ===== Stop Scheduler =====
        # Shutdown scheduler (stops all jobs gracefully)
        self.scheduler.shutdown()
        self.is_running = False
        logger.info("🛑 Background worker stopped")
    
    def get_job_info(self) -> dict:
        """
        Get information about running jobs.
        
        Returns information about the worker status and scheduled jobs.
        Useful for monitoring and debugging.
        
        Returns:
            Dictionary with:
            - is_running: Whether worker is active
            - jobs: List of job information (ID, name, next run time)
        """
        jobs = self.scheduler.get_jobs()
        return {
            "is_running": self.is_running,
            "jobs": [
                {
                    "id": job.id,
                    "name": job.name,
                    "next_run": str(job.next_run_time) if job.next_run_time else None,
                }
                for job in jobs
            ]
        }


# ===== Global Worker Instance =====
# Singleton pattern: one worker instance per application
_worker: UnlockWorker | None = None


def get_worker() -> UnlockWorker:
    """
    Get or create the global worker instance.
    
    Uses singleton pattern to ensure only one worker instance exists.
    Creates the worker on first call, returns existing instance on subsequent calls.
    
    Returns:
        Global UnlockWorker instance
    """
    global _worker
    if _worker is None:
        _worker = UnlockWorker()
    return _worker


def start_worker() -> None:
    """
    Start the global worker instance.
    
    Convenience function to start the global worker.
    Called automatically on application startup.
    
    Note:
        This is the entry point called from main.py lifespan
    """
    worker = get_worker()
    worker.start()


def shutdown_worker() -> None:
    """
    Shutdown the global worker instance.
    
    Convenience function to shutdown the global worker.
    Called automatically on application shutdown.
    
    Note:
        This is the entry point called from main.py lifespan
    """
    worker = get_worker()
    worker.shutdown()
