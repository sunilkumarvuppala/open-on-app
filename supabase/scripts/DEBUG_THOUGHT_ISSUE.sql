-- ============================================================================
-- Debug: Check Thought Sending Issue
-- ============================================================================
-- Run this to diagnose why User B gets "already sent" error
-- ============================================================================

-- Replace these with actual user IDs from your test
-- User A's ID
-- User B's ID

-- 1. Check if User B has actually sent to User A today
SELECT 
  'User B sent to User A' as check_type,
  COUNT(*) as count,
  MAX(created_at) as last_sent
FROM public.thoughts
WHERE sender_id = 'USER_B_ID_HERE'::uuid  -- Replace with User B's actual ID
  AND receiver_id = 'USER_A_ID_HERE'::uuid  -- Replace with User A's actual ID
  AND day_bucket = CURRENT_DATE;

-- Expected: Should be 0 if User B never sent

-- 2. Check if User A sent to User B today
SELECT 
  'User A sent to User B' as check_type,
  COUNT(*) as count,
  MAX(created_at) as last_sent
FROM public.thoughts
WHERE sender_id = 'USER_A_ID_HERE'::uuid  -- Replace with User A's actual ID
  AND receiver_id = 'USER_B_ID_HERE'::uuid  -- Replace with User B's actual ID
  AND day_bucket = CURRENT_DATE;

-- Expected: Should be 1 if User A sent

-- 3. Check all thoughts between these users today
SELECT 
  sender_id,
  receiver_id,
  created_at,
  day_bucket
FROM public.thoughts
WHERE (sender_id = 'USER_A_ID_HERE'::uuid AND receiver_id = 'USER_B_ID_HERE'::uuid)
   OR (sender_id = 'USER_B_ID_HERE'::uuid AND receiver_id = 'USER_A_ID_HERE'::uuid)
  AND day_bucket = CURRENT_DATE
ORDER BY created_at;

-- This shows all thoughts in both directions today

-- 4. Test the RPC function as User B (you'll need to be authenticated as User B)
-- SELECT public.rpc_send_thought('USER_A_ID_HERE'::uuid, 'test');

-- ============================================================================
-- Possible Issues to Check:
-- ============================================================================
-- 1. Are sender_id and receiver_id swapped in the check?
-- 2. Is the session set correctly (auth.uid() returns User B's ID)?
-- 3. Is there a race condition?
-- 4. Is the unique constraint being violated for wrong reason?
-- ============================================================================

