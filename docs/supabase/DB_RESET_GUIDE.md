# Database Reset Guide - Fresh Setup

## Quick Start

After resetting your Supabase database, run migrations in this order:

### Option 1: Use Consolidated Migration (Recommended for Fresh DB)

```bash
# The consolidated migration includes:
# - All tables, enums, indexes
# - Connections tables
# - All optimizations for 1M+ users
# - Unique constraints
supabase migration up
```

The `00_consolidated_schema.sql` file will be applied first (alphabetically), which includes everything needed for a fresh database.

### Option 2: Manual Migration Order (If needed)

If you need to run migrations manually:

1. **Base Schema** (already in consolidated):
   - `00_consolidated_schema.sql` - Complete schema with all optimizations

2. **Additional Features** (run after consolidated):
   - `03_views.sql` - Database views
   - `04_functions.sql` - Database functions
   - `05_triggers.sql` - Automatic triggers
   - `06_rls_policies.sql` - Row Level Security policies
   - `07_storage.sql` - Storage bucket policies
   - `09_connections_rls.sql` - Connection RLS policies
   - `10_connections_functions.sql` - Connection functions
   - `11_connections_notifications.sql` - Connection notifications
   - `12_search_users_function.sql` - User search function
   - `13_user_profiles_search_policy.sql` - Search policies
   - `14_scheduled_jobs.sql` - Cron jobs
   - `15_search_users_with_user_id.sql` - Enhanced search

## What's Included in Consolidated Migration

The `00_consolidated_schema.sql` includes:

✅ **All Tables**:
- `user_profiles`
- `recipients` (with `linked_user_id` column)
- `themes`
- `animations`
- `capsules`
- `notifications`
- `user_subscriptions`
- `audit_logs`
- `connection_requests`
- `connections`
- `blocked_users`

✅ **All Indexes** (optimized for 1M+ users):
- Capsules indexes (letter counting, inbox/outbox, status filtering)
- Recipients indexes (connection-based lookups, unique constraints)
- Connections indexes (UNION ALL optimized)
- All foreign key indexes

✅ **All Constraints**:
- Unique constraints (prevents duplicates)
- Check constraints (data validation)
- Foreign key constraints

✅ **All Enums**:
- `capsule_status`
- `notification_type`
- `subscription_status`
- `username` (replaces deprecated `recipient_relationship`)

## Verification After Reset

After running migrations, verify:

1. **Tables Created**:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

2. **Indexes Created**:
   ```sql
   SELECT indexname 
   FROM pg_indexes 
   WHERE schemaname = 'public' 
   ORDER BY indexname;
   ```

3. **Unique Constraints**:
   ```sql
   SELECT conname, conrelid::regclass 
   FROM pg_constraint 
   WHERE contype = 'u' 
   AND connamespace = 'public'::regnamespace;
   ```

4. **UUID Primary Keys**:
   ```sql
   SELECT 
     table_name,
     column_name,
     data_type
   FROM information_schema.columns
   WHERE table_schema = 'public'
   AND column_name = 'id'
   AND data_type = 'uuid';
   ```

## Important Notes

1. **Migration 16 Removed**: The abandoned `16_remove_recipients_table.sql` has been deleted. Don't worry about the gap in numbering.

2. **Recipients Table**: The `recipients` table is kept (not removed). It includes `linked_user_id` for connection-based recipients.

3. **All UUIDs**: All primary keys and foreign keys use UUIDs - verified and production-ready.

4. **Indexes Optimized**: All indexes are optimized for 1M+ users with partial indexes, composite indexes, and proper column ordering.

## Troubleshooting

### If migrations fail:

1. **Check Supabase Status**: Ensure Supabase is running
   ```bash
   supabase status
   ```

2. **Check Migration Order**: Ensure `00_consolidated_schema.sql` runs first

3. **Check for Conflicts**: If you have existing data, the consolidated migration uses `IF NOT EXISTS` clauses to prevent conflicts

4. **Reset Again**: If needed, reset and start fresh
   ```bash
   supabase db reset
   ```

## Next Steps After Reset

1. ✅ Run consolidated migration
2. ✅ Run additional feature migrations (views, functions, triggers, RLS)
3. ✅ Verify tables and indexes
4. ✅ Test application functionality
5. ✅ Verify no duplicate issues (drafts, recipients)

---

**Last Updated**: December 2025  
**Status**: Ready for Production (1M+ Users)

