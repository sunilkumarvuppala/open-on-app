-- ============================================================================
-- Quick Check: Is Thoughts Migration Applied?
-- ============================================================================
-- Run this in your Supabase SQL Editor to verify migration status
-- ============================================================================

-- 1. Check if function exists (THIS IS THE KEY CHECK)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' 
        AND routine_name = 'rpc_send_thought'
    ) THEN '✅ Function EXISTS - Migration applied!'
    ELSE '❌ Function MISSING - Migration NOT applied'
  END as migration_status;

-- 2. List all thought-related functions
SELECT 
  routine_name as function_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%'
ORDER BY routine_name;

-- Expected: Should see:
-- - rpc_list_incoming_thoughts
-- - rpc_list_sent_thoughts  
-- - rpc_send_thought
-- - set_thought_day_bucket

-- 3. Check if tables exist
SELECT 
  table_name,
  CASE 
    WHEN table_name = 'thoughts' THEN '✅'
    WHEN table_name = 'thought_rate_limits' THEN '✅'
    ELSE '❌'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits')
ORDER BY table_name;

-- Expected: Should see both tables

-- 4. Test function exists (will fail with auth error, but confirms function exists)
-- Uncomment to test:
-- SELECT public.rpc_send_thought('00000000-0000-0000-0000-000000000000'::uuid, 'test');

-- ============================================================================
-- IF FUNCTION IS MISSING:
-- ============================================================================
-- 1. Copy entire contents of: supabase/migrations/15_thoughts_feature.sql
-- 2. Paste in SQL Editor
-- 3. Run it
-- 4. Run this check again
-- ============================================================================

