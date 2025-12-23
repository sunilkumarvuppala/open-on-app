# Troubleshooting: "could not find function public.rpc_send_thought"

## Step 1: Verify Which Database Your App Connects To

The error means the function doesn't exist in the database your app is using.

### Check Your App's Database Connection

1. **Check your `.env` file** in `frontend/.env`:
   ```bash
   cat frontend/.env | grep SUPABASE_URL
   ```

2. **Note the URL**:
   - `http://localhost:54321` = **Local Supabase**
   - `https://xxxxx.supabase.co` = **Remote/Production Supabase**

## Step 2: Verify Migration Was Applied

Run this query in the **SAME database** your app connects to:

### If Using Local Supabase:
```bash
# Get local database connection
supabase status

# Connect to local database
psql postgresql://postgres:postgres@localhost:54322/postgres

# Then run:
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'rpc_send_thought';
```

### If Using Remote Supabase:
1. Go to Supabase Dashboard → SQL Editor
2. Run:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'rpc_send_thought';
```

**Expected Result**: Should return `rpc_send_thought`

**If Empty**: Migration wasn't applied to this database

## Step 3: Apply Migration to Correct Database

### For Local Database:
```bash
cd supabase
supabase migration up
```

### For Remote Database:
1. Go to Supabase Dashboard → SQL Editor
2. Copy entire `supabase/migrations/15_thoughts_feature.sql`
3. Paste and run

## Step 4: Common Issues

### Issue: Migration Applied to Wrong Database
**Solution**: Apply migration to the database your app actually uses (check `.env` file)

### Issue: Migration Had Errors
**Solution**: Check the SQL Editor output for error messages. Common issues:
- Missing dependencies (e.g., `connections` table doesn't exist)
- Permission errors
- Syntax errors

### Issue: App Still Shows Error After Migration
**Solution**: 
1. Restart your Flutter app completely
2. Clear app cache/data
3. Re-authenticate if needed

## Step 5: Verify All Functions Exist

Run this to check all thought-related functions:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%'
ORDER BY routine_name;
```

**Expected Results**:
- `rpc_list_incoming_thoughts`
- `rpc_list_sent_thoughts`
- `rpc_send_thought`
- `set_thought_day_bucket`

## Step 6: Check Tables Exist

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits');
```

**Expected**: Both `thoughts` and `thought_rate_limits` should exist

## Quick Test

After applying migration, test the function directly:

```sql
-- This will fail with "Not authenticated" but confirms function exists
SELECT public.rpc_send_thought('00000000-0000-0000-0000-000000000000'::uuid, 'test');
```

If you get "function does not exist" → Migration not applied
If you get "Not authenticated" → Function exists! ✅

