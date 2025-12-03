"""
Logging configuration for OpenOn backend.

This module configures application-wide logging for the backend.
It sets up console logging with appropriate levels and formatters.

Logging Configuration:
- Console handler: Outputs to stdout
- Format: Timestamp, logger name, level, message
- Levels: INFO for application logs, WARNING for noisy libraries
- Request logging: Always at INFO level for visibility

Logger Levels:
- Root logger: INFO (minimum)
- Request logging: INFO (always visible)
- Uvicorn access: WARNING (reduce noise)
- SQLAlchemy engine: WARNING (reduce noise)
"""
import logging
import sys
from typing import Any


def setup_logging(level: int = logging.INFO) -> None:
    """
    Configure application logging.
    
    Sets up logging configuration for the entire application.
    Configures console handler, formatters, and logger levels.
    
    Args:
        level: Root logger level (default: INFO)
    
    Configuration:
        - Console handler outputs to stdout
        - Formatter includes timestamp, logger name, level, message
        - Request logging always at INFO level
        - Noisy loggers (uvicorn, sqlalchemy) set to WARNING
    
    Note:
        Called once at application startup
        Ensures request logs are always visible (INFO level)
    """
    # ===== Create Formatter =====
    # Format: timestamp - logger name - level - message
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    
    # ===== Console Handler =====
    # Output logs to stdout (standard output)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    # Set handler level to INFO to ensure request logs are visible
    # This overrides root logger level for this handler
    console_handler.setLevel(logging.INFO)
    
    # ===== Root Logger =====
    # Configure root logger (affects all loggers)
    root_logger = logging.getLogger()
    # Ensure root logger is at least INFO to see request logs
    # Use minimum of requested level and INFO
    root_logger.setLevel(min(level, logging.INFO))
    root_logger.addHandler(console_handler)
    
    # ===== Request Logging Logger =====
    # Ensure request logging middleware always logs at INFO level
    # This is important for monitoring API activity
    request_logger = logging.getLogger("app.middleware.request_logging")
    request_logger.setLevel(logging.INFO)
    
    # ===== Silence Noisy Loggers =====
    # Reduce noise from third-party libraries
    # Uvicorn access logs: Set to WARNING (only show errors)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    # SQLAlchemy engine logs: Set to WARNING (only show errors)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger instance.
    
    Convenience function to get a logger with the specified name.
    All loggers inherit from root logger configuration.
    
    Args:
        name: Logger name (typically __name__ of the module)
    
    Returns:
        Logger instance configured with application settings
    
    Usage:
        logger = get_logger(__name__)
        logger.info("Message")
    """
    return logging.getLogger(name)
