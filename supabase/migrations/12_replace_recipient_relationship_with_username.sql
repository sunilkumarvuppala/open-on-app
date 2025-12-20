-- Migration: Replace recipient relationship with username
-- Description: Removes the relationship enum column and adds username text column to recipients table

-- Step 1: Add username column (nullable, can be NULL for email-based recipients)
ALTER TABLE public.recipients 
ADD COLUMN IF NOT EXISTS username TEXT;

-- Step 2: For connection-based recipients, populate username from user_profiles
-- This ensures existing recipients get their username from the linked user's profile
UPDATE public.recipients r
SET username = up.username
FROM public.user_profiles up
WHERE r.linked_user_id = up.user_id
  AND r.linked_user_id IS NOT NULL
  AND up.username IS NOT NULL;

-- Step 3: Drop the relationship column (after data migration if needed)
-- Note: We're removing the relationship column entirely
ALTER TABLE public.recipients 
DROP COLUMN IF EXISTS relationship;

-- Step 4: Drop the recipient_relationship enum type if it's no longer used
-- Check if it's used elsewhere before dropping
DO $$ 
BEGIN
    -- Only drop if not used in other tables
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        WHERE t.typname = 'recipient_relationship'
        AND EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE data_type = 'USER-DEFINED' 
            AND udt_name = 'recipient_relationship'
        )
    ) THEN
        DROP TYPE IF EXISTS recipient_relationship;
    END IF;
END $$;

-- Step 5: Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_recipients_username 
ON public.recipients(owner_id, username) 
WHERE username IS NOT NULL;

-- Step 6: Update any indexes that referenced relationship
-- The idx_recipients_relationship index will be automatically dropped when column is dropped
DROP INDEX IF EXISTS public.idx_recipients_relationship;

