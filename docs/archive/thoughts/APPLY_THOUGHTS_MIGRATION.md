# How to Apply Thoughts Feature Migration

## Quick Fix: Apply Migration to Database

The error "could not find function public.rpc_send_thought" means the migration hasn't been applied yet.

### Option 1: Supabase Dashboard (Easiest)

1. Go to your Supabase project dashboard: https://app.supabase.com
2. Select your project
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `supabase/migrations/15_thoughts_feature.sql`
6. Paste into the SQL editor
7. Click **Run** (or press Cmd/Ctrl + Enter)
8. Wait for "Success. No rows returned"

### Option 2: Supabase CLI (If Linked)

If you have Supabase CLI linked to your project:

```bash
# Link your project (if not already linked)
supabase link --project-ref your-project-ref

# Apply the migration
supabase db push
```

### Option 3: Direct Database Connection (psql)

If you have direct database access:

```bash
# Get your database connection string from Supabase dashboard
# Settings > Database > Connection string (URI)

psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-HOST]:5432/postgres" \
  -f supabase/migrations/15_thoughts_feature.sql
```

### Verify Migration Applied

After applying, verify the function exists:

```sql
-- Run this in Supabase SQL Editor
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%';
```

You should see:
- `rpc_send_thought`
- `rpc_list_incoming_thoughts`
- `rpc_list_sent_thoughts`
- `set_thought_day_bucket`

### Check Tables Created

```sql
-- Verify tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits');
```

You should see both tables listed.

## After Migration

Once the migration is applied:
1. Restart your Flutter app
2. The Thought button should work
3. You can send thoughts to your connections

## Troubleshooting

**If you get permission errors:**
- Make sure you're using the correct database role
- Check that RLS policies are enabled (they should be created by the migration)

**If tables already exist:**
- The migration uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run again
- If you get constraint errors, the migration may have partially applied

**If you need to rollback:**
- See the rollback section in `docs/THOUGHTS_FEATURE.md`

