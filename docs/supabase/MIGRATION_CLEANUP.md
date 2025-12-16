# Migration File Cleanup Guide

## Analysis: Which Migrations Are Needed?

### ✅ **KEEP** - Required for Fresh DB

These migrations are **NOT** included in `00_consolidated_schema.sql` and are still needed:

1. **`00_consolidated_schema.sql`** - Complete schema (tables, indexes, constraints)
2. **`03_views.sql`** - Database views (inbox_view, outbox_view, etc.)
3. **`04_functions.sql`** - Database functions (update_capsule_status, etc.)
4. **`05_triggers.sql`** - Automatic triggers (status updates, timestamps)
5. **`06_rls_policies.sql`** - Row Level Security policies
6. **`07_storage.sql`** - Storage bucket policies
7. **`09_connections_rls.sql`** - Connection RLS policies
8. **`10_connections_functions.sql`** - Connection functions (send_request, accept, etc.)
9. **`11_connections_notifications.sql`** - Connection notification triggers
10. **`12_search_users_function.sql`** - User search function
11. **`13_user_profiles_search_policy.sql`** - Search policies
12. **`14_scheduled_jobs.sql`** - Cron jobs (pg_cron)
13. **`15_search_users_with_user_id.sql`** - Enhanced search with user_id

### ❌ **REDUNDANT** - Already in Consolidated Migration

These migrations are **duplicated** in `00_consolidated_schema.sql` and can be removed:

1. **`01_enums_and_tables.sql`** - ✅ Included in consolidated
2. **`02_indexes.sql`** - ✅ Included in consolidated
3. **`08_connections.sql`** - ✅ Included in consolidated
4. **`17_optimize_connection_indexes.sql`** - ✅ Included in consolidated
5. **`18_add_linked_user_id_to_recipients.sql`** - ✅ Included in consolidated
6. **`20_production_index_optimizations.sql`** - ✅ Included in consolidated
7. **`21_add_unique_constraint_recipients.sql`** - ✅ Included in consolidated

### ⚠️ **OPTIONAL** - Backfill Only (Not Needed for Fresh DB)

This migration is for **existing databases only**:

1. **`19_backfill_recipients_for_connections.sql`** - Backfills recipients for existing connections
   - **Not needed for fresh DB** (no existing connections to backfill)
   - **Safe to keep** (uses `NOT EXISTS`, won't do anything on fresh DB)
   - **Or remove** if you want cleaner migration folder

## Recommended Action

### Option 1: Keep All (Safest)
- Keep all migrations
- `00_consolidated_schema.sql` runs first
- Redundant migrations use `IF NOT EXISTS` (safe, no-ops)
- **Pros**: No risk, can reference old migrations
- **Cons**: More files, some redundancy

### Option 2: Remove Redundant (Cleaner)
Remove these 7 files (already in consolidated):
- `01_enums_and_tables.sql`
- `02_indexes.sql`
- `08_connections.sql`
- `17_optimize_connection_indexes.sql`
- `18_add_linked_user_id_to_recipients.sql`
- `20_production_index_optimizations.sql`
- `21_add_unique_constraint_recipients.sql`

Optionally remove:
- `19_backfill_recipients_for_connections.sql` (not needed for fresh DB)

**Result**: 13-14 files instead of 21

### Option 3: Remove Backfill Only
Keep redundant migrations (they're safe with `IF NOT EXISTS`), but remove:
- `19_backfill_recipients_for_connections.sql` (not needed for fresh DB)

**Result**: 20 files (cleaner, but still some redundancy)

## Recommendation

**For Fresh DB Reset**: **Option 2** (Remove Redundant)

Since you're doing a fresh reset:
1. Remove the 7 redundant migrations (already in consolidated)
2. Remove `19_backfill_recipients_for_connections.sql` (not needed)
3. Keep the 13 essential migrations

**Final Migration List** (13 files):
1. `00_consolidated_schema.sql` - Complete schema
2. `03_views.sql` - Views
3. `04_functions.sql` - Functions
4. `05_triggers.sql` - Triggers
5. `06_rls_policies.sql` - RLS
6. `07_storage.sql` - Storage
7. `09_connections_rls.sql` - Connection RLS
8. `10_connections_functions.sql` - Connection functions
9. `11_connections_notifications.sql` - Connection notifications
10. `12_search_users_function.sql` - Search function
11. `13_user_profiles_search_policy.sql` - Search policy
12. `14_scheduled_jobs.sql` - Cron jobs
13. `15_search_users_with_user_id.sql` - Enhanced search

## Migration Order

Supabase runs migrations in **alphabetical order**:
1. `00_consolidated_schema.sql` (runs first)
2. `03_views.sql`
3. `04_functions.sql`
4. ... (rest in order)

This ensures the schema is created before views, functions, triggers, etc.

---

**Last Updated**: December 2025

