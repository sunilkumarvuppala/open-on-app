-- ============================================================================
-- Check Dependencies Before Applying Thoughts Migration
-- ============================================================================
-- Run this FIRST to make sure required tables exist
-- ============================================================================

-- Check if connections table exists (REQUIRED)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name = 'connections'
    ) THEN '✅ connections table exists'
    ELSE '❌ connections table MISSING - Need to run connections migration first'
  END as connections_status;

-- Check if blocked_users table exists (REQUIRED)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name = 'blocked_users'
    ) THEN '✅ blocked_users table exists'
    ELSE '❌ blocked_users table MISSING - Need to run connections migration first'
  END as blocked_users_status;

-- Check if user_profiles table exists (REQUIRED for RPC functions)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) THEN '✅ user_profiles table exists'
    ELSE '❌ user_profiles table MISSING - Need to run base schema migration first'
  END as user_profiles_status;

-- List all existing tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

