# Clearing Database Data

This guide explains how to clear all data from the OpenOn database.

## Quick Methods

### Method 1: Using the Clear Script (Recommended)

The easiest way to clear all data is using the provided script:

```bash
cd backend
python clear_database.py
```

This will:
- Clear all data from all tables (users, capsules, drafts, recipients)
- Keep the database structure intact
- Ask for confirmation before proceeding

**Skip confirmation:**
```bash
python clear_database.py --confirm
```

**Drop and recreate all tables:**
```bash
python clear_database.py --recreate
```

### Method 2: Delete SQLite Database File (SQLite Only)

If you're using SQLite (default), you can simply delete the database file:

```bash
cd backend
rm openon.db
```

The database will be automatically recreated when you start the server next time.

**Note:** This only works for SQLite. For PostgreSQL, use Method 1 or Method 3.

### Method 3: Manual SQL Commands

You can also connect to your database and run SQL commands directly:

**For SQLite:**
```bash
sqlite3 openon.db
```

Then run:
```sql
DELETE FROM recipients;
DELETE FROM drafts;
DELETE FROM capsules;
DELETE FROM users;
DELETE FROM sqlite_sequence;
```

**For PostgreSQL:**
```bash
psql -U your_user -d openon
```

Then run:
```sql
TRUNCATE TABLE recipients, drafts, capsules, users CASCADE;
```

## What Gets Cleared

When you clear the database, the following data is removed:

- ✅ **Users**: All user accounts and authentication data
- ✅ **Capsules**: All time-locked capsules (draft, sealed, ready, opened)
- ✅ **Drafts**: All draft messages
- ✅ **Recipients**: All saved recipient contacts

## What Stays Intact

- ✅ **Database Structure**: Tables and schema remain unchanged
- ✅ **Indexes**: All database indexes are preserved
- ✅ **Constraints**: Foreign keys and other constraints remain

## Recreating Tables

If you want to completely reset the database (drop and recreate all tables):

```bash
python clear_database.py --recreate
```

This is useful when:
- You've made schema changes and want a fresh start
- You're experiencing database corruption
- You want to ensure a completely clean state

## Safety Notes

⚠️ **Warning**: Clearing the database is **irreversible**. All data will be permanently deleted.

- Make sure you have backups if you need to preserve any data
- This action cannot be undone
- All user accounts, capsules, and recipients will be lost

## Troubleshooting

### Database Locked Error

If you get a "database is locked" error:

1. Make sure the backend server is stopped
2. Check for any other processes accessing the database
3. For SQLite, remove any `.db-journal` or `.db-wal` files:
   ```bash
   rm openon.db-journal openon.db-wal 2>/dev/null
   ```

### Permission Errors

If you get permission errors:

```bash
# Make sure you have write permissions
chmod 644 openon.db  # For SQLite
```

### Foreign Key Constraint Errors

If you get foreign key constraint errors, use the script which handles deletion order:

```bash
python clear_database.py
```

The script deletes records in the correct order to avoid constraint violations.

## After Clearing

After clearing the database:

1. **Restart the server** - The database will be ready for new data
2. **Create a new account** - You'll need to sign up again
3. **Test the app** - Verify everything works with a clean database

---

**Last Updated**: 2025

