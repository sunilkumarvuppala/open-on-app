-- ============================================================================
-- Migration: Remove Recipients Table - Use Connections Only
-- ============================================================================
-- WHAT: Refactors capsules to use receiver_user_id instead of recipient_id
-- WHY: Simplifies architecture - recipients = connections, no need for separate table
-- ============================================================================

-- Step 1: Add new receiver_user_id column to capsules (nullable for migration)
ALTER TABLE public.capsules 
ADD COLUMN IF NOT EXISTS receiver_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Step 2: Migrate existing data
-- For each capsule, find the recipient's linked user from connections
-- If recipient has email, try to match to user
-- If recipient has no email (connection-based), find the connection
UPDATE public.capsules c
SET receiver_user_id = (
    -- Try to find user by recipient email first
    SELECT u.id
    FROM auth.users u
    WHERE u.email = (
        SELECT r.email 
        FROM public.recipients r 
        WHERE r.id = c.recipient_id 
        AND r.email IS NOT NULL
    )
    LIMIT 1
)
WHERE receiver_user_id IS NULL
AND EXISTS (
    SELECT 1 FROM public.recipients r 
    WHERE r.id = c.recipient_id 
    AND r.email IS NOT NULL
);

-- For connection-based recipients (no email), find the connection
-- This is trickier - we need to match by name or find the connection
-- For now, we'll set it to NULL and handle manually if needed
-- In practice, connection-based recipients should have been created recently
-- and we can verify connections exist

-- Step 3: Make receiver_user_id NOT NULL (after data migration)
-- ALTER TABLE public.capsules 
-- ALTER COLUMN receiver_user_id SET NOT NULL;

-- Step 4: Drop foreign key constraint on recipient_id
ALTER TABLE public.capsules 
DROP CONSTRAINT IF EXISTS capsules_recipient_id_fkey;

-- Step 5: Drop recipient_id column (commented out - do this after verifying migration)
-- ALTER TABLE public.capsules 
-- DROP COLUMN recipient_id;

-- Step 6: Add index on receiver_user_id
CREATE INDEX IF NOT EXISTS idx_capsules_receiver_user 
ON public.capsules(receiver_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_capsules_receiver_user_status 
ON public.capsules(receiver_user_id, status, created_at DESC);

-- Step 7: Update RLS policies to use receiver_user_id
-- (Will be done in separate migration after verifying this works)

-- Note: Keep recipients table for now until all migrations are verified
-- DROP TABLE public.recipients CASCADE; -- Do this last, after everything is migrated
