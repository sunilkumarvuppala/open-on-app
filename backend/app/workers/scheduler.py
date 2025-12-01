"""Background worker for scheduled capsule unlock checks."""
import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from app.db.base import AsyncSessionLocal
from app.services.unlock_service import run_unlock_check
from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger(__name__)


class UnlockWorker:
    """Background worker for capsule unlock monitoring."""
    
    def __init__(self):
        """Initialize the worker with scheduler."""
        self.scheduler = AsyncIOScheduler()
        self.is_running = False
    
    async def unlock_check_job(self) -> None:
        """Job that checks and updates capsule states."""
        try:
            async with AsyncSessionLocal() as session:
                stats = await run_unlock_check(session)
                logger.debug(f"Unlock check completed: {stats}")
        except Exception as e:
            logger.error(f"Error in unlock check job: {str(e)}", exc_info=True)
    
    def start(self) -> None:
        """Start the background worker."""
        if self.is_running:
            logger.warning("Worker is already running")
            return
        
        # Add the unlock check job
        self.scheduler.add_job(
            self.unlock_check_job,
            trigger=IntervalTrigger(seconds=settings.worker_check_interval_seconds),
            id="unlock_watcher",
            name="Capsule Unlock Watcher",
            replace_existing=True,
            max_instances=1,  # Prevent concurrent runs
        )
        
        # Start the scheduler
        self.scheduler.start()
        self.is_running = True
        
        logger.info(
            f"🚀 Background worker started (check interval: "
            f"{settings.worker_check_interval_seconds}s)"
        )
    
    def shutdown(self) -> None:
        """Shutdown the background worker."""
        if not self.is_running:
            return
        
        self.scheduler.shutdown()
        self.is_running = False
        logger.info("🛑 Background worker stopped")
    
    def get_job_info(self) -> dict:
        """Get information about running jobs."""
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


# Global worker instance
_worker: UnlockWorker | None = None


def get_worker() -> UnlockWorker:
    """Get or create the global worker instance."""
    global _worker
    if _worker is None:
        _worker = UnlockWorker()
    return _worker


def start_worker() -> None:
    """Start the global worker instance."""
    worker = get_worker()
    worker.start()


def shutdown_worker() -> None:
    """Shutdown the global worker instance."""
    worker = get_worker()
    worker.shutdown()
