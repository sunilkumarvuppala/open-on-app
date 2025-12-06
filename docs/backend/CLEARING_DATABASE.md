# Clearing Database Data

This guide explains how to clear all data from the OpenOn Supabase database.

## Quick Methods

### Method 1: Reset Supabase Database (Recommended)

The easiest way to clear all data is to reset the Supabase database:

```bash
cd supabase
supabase db reset
```

This will:
- Drop all tables
- Re-run all migrations
- Start with a fresh database

**Note:** This resets the entire Supabase database. All data will be permanently deleted.

### Method 2: Manual SQL Commands

You can also connect to your Supabase database and run SQL commands directly:

**Connect to Supabase:**
```bash
cd supabase
supabase db connect
```

Then run:
```sql
-- Clear all data (keeps tables)
TRUNCATE TABLE 
  public.recipients,
  public.capsules,
  public.user_profiles,
  public.notifications,
  public.user_subscriptions,
  public.audit_logs
CASCADE;
```

**Or via Supabase Studio:**
- Open http://localhost:54323
- Go to SQL Editor
- Run the TRUNCATE command above

### Method 3: Delete Specific Tables

If you only want to clear specific data:

```sql
-- Clear only capsules
TRUNCATE TABLE public.capsules CASCADE;

-- Clear only recipients
TRUNCATE TABLE public.recipients CASCADE;

-- Clear user profiles (note: auth.users are managed by Supabase Auth)
-- You may need to delete users via Supabase Auth API or Dashboard
```

## What Gets Cleared

When you clear the database, the following data is removed:

- ✅ **Capsules**: All time-locked capsules (sealed, ready, opened, expired)
- ✅ **Recipients**: All saved recipient contacts
- ✅ **User Profiles**: All user profile data (note: auth.users are managed by Supabase Auth)
- ✅ **Notifications**: All user notifications
- ✅ **Subscriptions**: All subscription records
- ✅ **Audit Logs**: All audit log entries

## What Stays Intact

- ✅ **Database Structure**: Tables and schema remain unchanged (if using TRUNCATE)
- ✅ **Indexes**: All database indexes are preserved
- ✅ **Constraints**: Foreign keys and other constraints remain
- ✅ **Migrations**: All migration history is preserved
- ✅ **Auth Users**: Supabase Auth users (auth.users) are managed separately)

## Resetting Everything

If you want to completely reset the database (drop and recreate all tables):

```bash
cd supabase
supabase db reset
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
- Supabase Auth users (auth.users) are managed separately and may need to be deleted via Supabase Dashboard

## Troubleshooting

### Database Connection Error

If you get a database connection error:

1. Make sure Supabase is running:
   ```bash
   cd supabase
   supabase status
   ```

2. If not running, start it:
   ```bash
   supabase start
   ```

3. Verify DATABASE_URL in `.env` matches Supabase connection string:
   ```bash
   supabase status | grep DB_URL
   ```

### Permission Errors

If you get permission errors:

1. Check Supabase is accessible:
   ```bash
   cd supabase
   supabase status
   ```

2. Verify database connection string in `.env` file

3. Ensure you're using the correct database user (postgres for local)

### Foreign Key Constraint Errors

If you get foreign key constraint errors, use `CASCADE` in your TRUNCATE command:

```sql
TRUNCATE TABLE 
  public.recipients,
  public.capsules,
  public.user_profiles
CASCADE;
```

The `CASCADE` option automatically truncates dependent tables.

## After Clearing

After clearing the database:

1. **Restart the server** - The database will be ready for new data
2. **Create a new account** - You'll need to sign up again
3. **Test the app** - Verify everything works with a clean database

---

**Last Updated**: January 2025

