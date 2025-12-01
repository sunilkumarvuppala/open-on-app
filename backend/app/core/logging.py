"""Logging configuration for OpenOn backend."""
import logging
import sys
from typing import Any


def setup_logging(level: int = logging.INFO) -> None:
    """Configure application logging."""
    # Create formatter
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    # Set handler level to INFO to ensure request logs are visible
    console_handler.setLevel(logging.INFO)
    
    # Root logger
    root_logger = logging.getLogger()
    # Ensure root logger is at least INFO to see request logs
    root_logger.setLevel(min(level, logging.INFO))
    root_logger.addHandler(console_handler)
    
    # Ensure request logging middleware always logs at INFO level
    request_logger = logging.getLogger("app.middleware.request_logging")
    request_logger.setLevel(logging.INFO)
    
    # Silence noisy loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance."""
    return logging.getLogger(name)
