# How to Update Existing Migrations

## Quick Decision Tree

```
Has the migration been applied to production?
├─ NO → Edit the migration file directly (Option 1)
└─ YES → Create a new migration to fix it (Option 2) ✅ Current approach
```

## Option 1: Edit Migration Directly (If NOT Applied)

**Use this when:** Migration hasn't been applied to production yet (development/local only)

### Steps

1. **Check if migration is applied:**
   ```bash
   # Check migration status
   supabase migration list
   
   # Or check in Supabase Dashboard
   # Go to Database > Migrations
   ```

2. **Edit the migration file directly:**
   ```bash
   # Edit migration 25
   code supabase/migrations/25_fix_open_letter_self_send.sql
   
   # Edit migration 26
   code supabase/migrations/26_fix_open_letter_security_self_send_only.sql
   ```

3. **Apply the fixes from migration 27:**
   - Fix ambiguous column: Change `WHERE id = letter_id` to `WHERE c.id = letter_id` (with table alias)
   - Fix datatype: Change `c.status` to `c.status::TEXT` in RETURN QUERY statements

4. **Delete migration 27** (since fixes are now in 25 and 26):
   ```bash
   rm supabase/migrations/27_fix_open_letter_ambiguous_column.sql
   ```

## Option 2: Keep Fix Migration (If Already Applied) ✅

**Use this when:** Migration has already been applied to production

**Current Status:** Migration 27 is the correct approach - it fixes issues in migrations 25 and 26.

### Why This is Correct

- ✅ Migrations 25 and 26 are already applied
- ✅ Migration 27 creates a new migration that fixes the issues
- ✅ This is the standard practice for fixing applied migrations
- ✅ No need to modify existing migrations

### Apply Migration 27

```bash
# For local development
supabase migration up

# For production (if linked)
supabase migration up --linked

# Or use Supabase Dashboard SQL Editor
# Copy contents of migration 27 and run it
```

## How to Check if Migration is Applied

### Method 1: Supabase CLI
```bash
supabase migration list
```

### Method 2: SQL Query
```sql
-- Check if open_letter function exists and has the fix
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'open_letter';

-- Check migration history (if using Supabase migrations table)
SELECT * FROM supabase_migrations.schema_migrations 
ORDER BY version DESC 
LIMIT 10;
```

### Method 3: Test the Function
```sql
-- This will fail if migration 27 is not applied
-- (will show ambiguous column error)
SELECT * FROM public.open_letter('00000000-0000-0000-0000-000000000000');
```

## Recommended Approach for Your Case

Since migrations 25 and 26 likely have bugs and migration 27 fixes them:

1. **If migrations 25 and 26 are NOT applied:**
   - Edit migrations 25 and 26 directly
   - Delete migration 27
   - Apply migrations 25 and 26

2. **If migrations 25 and 26 ARE applied:**
   - Keep migration 27 as-is ✅
   - Apply migration 27 to fix the issues

## Best Practices

1. **Never modify applied migrations in production**
   - Always create a new migration to fix issues

2. **Test migrations locally first**
   ```bash
   # Reset local database
   supabase db reset
   
   # Apply all migrations
   supabase migration up
   
   # Test the function
   ```

3. **Use descriptive migration names**
   - ✅ `27_fix_open_letter_ambiguous_column.sql`
   - ❌ `27_fix.sql`

4. **Document what each migration fixes**
   - Migration 27 has good documentation explaining the fixes

## Current Status

**Migration 27** is correctly set up to fix:
- ✅ Ambiguous column reference (`id` → `c.id`)
- ✅ Datatype mismatch (`c.status` → `c.status::TEXT`)

**Next Step:** Apply migration 27 to your database.

