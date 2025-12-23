# How to Apply Thoughts Feature Migration

## Quick Start - Choose Your Method

### ✅ Method 1: Supabase Dashboard (Recommended - Easiest)

**Best for**: Quick one-time application, no CLI setup needed

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Open SQL Editor**
   - Click **SQL Editor** in the left sidebar
   - Click **New Query** button

3. **Copy Migration File**
   ```bash
   # In your terminal, view the file:
   cat supabase/migrations/15_thoughts_feature.sql
   
   # Or open it in your editor and copy all contents
   ```

4. **Paste and Run**
   - Paste the entire SQL content into the SQL Editor
   - Click **Run** (or press `Cmd/Ctrl + Enter`)
   - Wait for "Success. No rows returned" message

5. **Verify Migration Applied**
   ```sql
   -- Run this in SQL Editor to verify:
   SELECT routine_name 
   FROM information_schema.routines 
   WHERE routine_schema = 'public' 
     AND routine_name LIKE '%thought%';
   ```
   
   You should see:
   - `rpc_send_thought`
   - `rpc_list_incoming_thoughts`
   - `rpc_list_sent_thoughts`
   - `set_thought_day_bucket`

---

### ✅ Method 2: Supabase CLI (Best for Development)

**Best for**: Automated deployments, version control, team collaboration

#### Prerequisites
```bash
# Install Supabase CLI (if not installed)
# macOS:
brew install supabase/tap/supabase

# Or download from: https://github.com/supabase/cli/releases
```

#### Steps

**For LOCAL Database** (when running `supabase start`):
```bash
cd /Users/sunilvuppala/Career/Projects/FlutterProjects/openon

# Apply migration to local database
supabase migration up
```

**For REMOTE Database** (production/staging):
```bash
cd /Users/sunilvuppala/Career/Projects/FlutterProjects/openon

# 1. Link your project (if not already linked)
# Get your project reference ID from Supabase dashboard
# Settings > General > Reference ID
supabase link --project-ref your-project-ref

# 2. Apply migration to remote database
supabase migration up --linked

# OR use db push (alternative method)
supabase db push
```

**Which command to use?**
- **Local development**: `supabase migration up` (applies to local DB)
- **Production/Remote**: `supabase migration up --linked` or `supabase db push`

3. **Verify**
   ```bash
   # Check migration status
   supabase migration list
   ```

---

### ✅ Method 3: Direct Database Connection (psql)

**Best for**: Advanced users, CI/CD pipelines

#### Prerequisites
- PostgreSQL client (`psql`) installed
- Database connection string from Supabase dashboard

#### Steps

1. **Get Connection String**
   - Go to Supabase Dashboard
   - Settings > Database > Connection string
   - Copy the URI (looks like: `postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres`)

2. **Apply Migration**
   ```bash
   cd /Users/sunilvuppala/Career/Projects/FlutterProjects/openon
   
   # Replace [CONNECTION_STRING] with your actual connection string
   psql "[CONNECTION_STRING]" -f supabase/migrations/15_thoughts_feature.sql
   ```

   **Or with environment variable:**
   ```bash
   export DATABASE_URL="postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"
   psql "$DATABASE_URL" -f supabase/migrations/15_thoughts_feature.sql
   ```

---

## Verification Steps

After applying the migration, verify everything is set up correctly:

### 1. Check Functions Exist
```sql
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%'
ORDER BY routine_name;
```

**Expected Output:**
```
routine_name              | routine_type
--------------------------|-------------
rpc_list_incoming_thoughts | FUNCTION
rpc_list_sent_thoughts     | FUNCTION
rpc_send_thought          | FUNCTION
set_thought_day_bucket     | FUNCTION
```

### 2. Check Tables Exist
```sql
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits')
ORDER BY table_name;
```

**Expected Output:**
```
table_name          | table_type
--------------------|------------
thought_rate_limits | BASE TABLE
thoughts            | BASE TABLE
```

### 3. Check Indexes Exist
```sql
SELECT 
  indexname,
  tablename
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE '%thought%'
ORDER BY tablename, indexname;
```

**Expected Output:**
```
indexname                      | tablename
-------------------------------|------------------
idx_thought_rate_limits_day    | thought_rate_limits
idx_thoughts_receiver_created  | thoughts
idx_thoughts_sender_created    | thoughts
idx_thoughts_sender_day         | thoughts
```

### 4. Check RLS Policies
```sql
SELECT 
  schemaname,
  tablename,
  policyname
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('thoughts', 'thought_rate_limits')
ORDER BY tablename, policyname;
```

**Expected Output:**
```
schemaname | tablename          | policyname
-----------|--------------------|--------------------------
public     | thought_rate_limits| System can manage rate limits
public     | thought_rate_limits| Users can view own rate limits
public     | thoughts           | Receivers can view incoming thoughts
public     | thoughts           | Senders can view sent thoughts
public     | thoughts           | System can delete thoughts
public     | thoughts           | Users can send thoughts via RPC
```

### 5. Test RPC Function (Optional)
```sql
-- This will fail if not authenticated, but confirms function exists
SELECT public.rpc_send_thought(
  '00000000-0000-0000-0000-000000000000'::uuid,
  'test'::text
);
```

**Expected**: Error about authentication or connection (which is correct - function exists!)

---

## Troubleshooting

### Issue: "relation already exists"
**Solution**: The migration uses `CREATE TABLE IF NOT EXISTS`, so this shouldn't happen. If it does:
```sql
-- Check if tables already exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits');

-- If they exist, you might need to drop and recreate (CAREFUL - deletes data!)
-- Only do this if you're sure:
-- DROP TABLE IF EXISTS public.thoughts CASCADE;
-- DROP TABLE IF EXISTS public.thought_rate_limits CASCADE;
```

### Issue: "permission denied"
**Solution**: Make sure you're using the correct database role:
- Use **postgres** role for migrations (service role)
- Or ensure your user has CREATE privileges

### Issue: "function already exists"
**Solution**: The migration uses `CREATE OR REPLACE FUNCTION`, so this shouldn't happen. If it does:
```sql
-- Check existing functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%';

-- Functions should be replaced automatically
```

### Issue: Migration applied but functions not found
**Solution**: 
1. Check if you're connected to the correct database
2. Verify the migration ran without errors
3. Check function schema:
   ```sql
   SELECT routine_schema, routine_name 
   FROM information_schema.routines 
   WHERE routine_name LIKE '%thought%';
   ```

---

## After Migration

Once the migration is successfully applied:

1. ✅ **Restart your Flutter app** (if running)
2. ✅ **Test the Thought feature**:
   - Go to People screen
   - Click the heart icon on a connection
   - Verify thought is sent successfully

3. ✅ **Monitor for errors**:
   - Check Flutter logs for any errors
   - Check Supabase logs for RPC errors
   - Verify session handling works correctly

---

## Quick Reference

### File Location
```
supabase/migrations/15_thoughts_feature.sql
```

### Migration Contents
- ✅ Creates `thoughts` table
- ✅ Creates `thought_rate_limits` table
- ✅ Creates indexes for performance
- ✅ Sets up RLS policies
- ✅ Creates RPC functions:
  - `rpc_send_thought`
  - `rpc_list_incoming_thoughts`
  - `rpc_list_sent_thoughts`

### Dependencies
- Requires `connections` table (should exist from previous migrations)
- Requires `blocked_users` table (should exist from previous migrations)
- Requires `user_profiles` table (should exist from previous migrations)

---

## Need Help?

If you encounter issues:

1. **Check Migration Status**:
   ```sql
   SELECT * FROM supabase_migrations.schema_migrations 
   ORDER BY version DESC LIMIT 10;
   ```

2. **Check for Errors**:
   - Review Supabase dashboard logs
   - Check Flutter app logs
   - Verify database connection

3. **Rollback** (if needed):
   ```sql
   -- CAREFUL: This deletes all thoughts data!
   DROP TABLE IF EXISTS public.thoughts CASCADE;
   DROP TABLE IF EXISTS public.thought_rate_limits CASCADE;
   DROP FUNCTION IF EXISTS public.rpc_send_thought CASCADE;
   DROP FUNCTION IF EXISTS public.rpc_list_incoming_thoughts CASCADE;
   DROP FUNCTION IF EXISTS public.rpc_list_sent_thoughts CASCADE;
   ```

---

## ✅ Success Checklist

After applying migration, verify:

- [ ] Functions exist (`rpc_send_thought`, etc.)
- [ ] Tables exist (`thoughts`, `thought_rate_limits`)
- [ ] Indexes created (4 indexes)
- [ ] RLS policies enabled (5 policies)
- [ ] Can send thought from Flutter app
- [ ] Can receive thought in Flutter app
- [ ] Rate limiting works (try sending 21 thoughts)
- [ ] Cooldown works (try sending twice to same person)

---

**Ready to apply?** Choose Method 1 (Dashboard) for the easiest experience! 🚀

