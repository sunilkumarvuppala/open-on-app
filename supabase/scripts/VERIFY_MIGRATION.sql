-- ============================================================================
-- Verify Thoughts Migration Applied
-- ============================================================================
-- Run this in your Supabase SQL Editor to check if the migration was applied
-- ============================================================================

-- 1. Check if the function exists
SELECT 
  routine_name,
  routine_type,
  routine_schema
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%'
ORDER BY routine_name;

-- Expected results:
-- - rpc_send_thought
-- - rpc_list_incoming_thoughts
-- - rpc_list_sent_thoughts
-- - set_thought_day_bucket

-- 2. Check if tables exist
SELECT 
  table_name,
  table_schema
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits')
ORDER BY table_name;

-- Expected results:
-- - thoughts
-- - thought_rate_limits

-- 3. Check if indexes exist
SELECT 
  indexname,
  tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND (indexname LIKE '%thought%' OR tablename IN ('thoughts', 'thought_rate_limits'))
ORDER BY tablename, indexname;

-- Expected indexes:
-- - idx_thoughts_receiver_created
-- - idx_thoughts_sender_created
-- - idx_thoughts_sender_day
-- - idx_thought_rate_limits_day

-- 4. Check if RLS is enabled
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('thoughts', 'thought_rate_limits');

-- Expected: rowsecurity = true for both tables

-- ============================================================================
-- If any of the above queries return empty results, the migration hasn't been applied
-- Apply the migration from: supabase/migrations/15_thoughts_feature.sql
-- ============================================================================

