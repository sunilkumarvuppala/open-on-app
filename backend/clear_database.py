#!/usr/bin/env python3
"""
Script to clear all data from the OpenOn database.

This script will:
1. Delete all records from all tables (users, capsules, drafts, recipients)
2. Keep the database structure intact
3. Optionally drop and recreate all tables (use --recreate flag)

Usage:
    python clear_database.py              # Clear all data, keep tables
    python clear_database.py --recreate   # Drop and recreate all tables
    python clear_database.py --confirm    # Skip confirmation prompt
"""

import asyncio
import sys
import logging
from sqlalchemy import text
from app.db.base import engine, Base
from app.db.models import User, Capsule, Draft, Recipient
from app.core.config import settings
from app.core.logging import setup_logging

# Setup logging
setup_logging(level=logging.INFO)
logger = logging.getLogger(__name__)


async def clear_all_data():
    """Clear all data from all tables."""
    logger.info("🗑️  Clearing all data from database...")
    
    async with engine.begin() as conn:
        # Delete in reverse order of dependencies to avoid foreign key constraints
        logger.info("  - Deleting recipients...")
        await conn.execute(text("DELETE FROM recipients"))
        
        logger.info("  - Deleting drafts...")
        await conn.execute(text("DELETE FROM drafts"))
        
        logger.info("  - Deleting capsules...")
        await conn.execute(text("DELETE FROM capsules"))
        
        logger.info("  - Deleting users...")
        await conn.execute(text("DELETE FROM users"))
        
        # Reset SQLite sequences (if using SQLite)
        if "sqlite" in settings.database_url:
            logger.info("  - Resetting SQLite sequences...")
            await conn.execute(text("DELETE FROM sqlite_sequence"))
    
    logger.info("✅ All data cleared successfully!")


async def recreate_tables():
    """Drop and recreate all tables."""
    logger.info("🔄 Recreating database tables...")
    
    async with engine.begin() as conn:
        logger.info("  - Dropping all tables...")
        await conn.run_sync(Base.metadata.drop_all)
        
        logger.info("  - Creating all tables...")
        await conn.run_sync(Base.metadata.create_all)
    
    logger.info("✅ Database tables recreated successfully!")


async def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Clear OpenOn database data")
    parser.add_argument(
        "--recreate",
        action="store_true",
        help="Drop and recreate all tables (instead of just clearing data)"
    )
    parser.add_argument(
        "--confirm",
        action="store_true",
        help="Skip confirmation prompt"
    )
    args = parser.parse_args()
    
    # Show database info
    logger.info(f"📊 Database: {settings.database_url}")
    
    if not args.confirm:
        action = "recreate tables" if args.recreate else "clear all data"
        response = input(f"\n⚠️  This will {action}. Are you sure? (yes/no): ")
        if response.lower() not in ["yes", "y"]:
            logger.warning("❌ Operation cancelled.")
            sys.exit(0)
    
    try:
        if args.recreate:
            await recreate_tables()
        else:
            await clear_all_data()
        
        logger.info("\n✨ Done! Database is now empty.")
        
    except Exception as e:
        logger.error(f"\n❌ Error: {e}", exc_info=True)
        sys.exit(1)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())

