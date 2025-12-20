-- ============================================================================
-- Anonymous Letters Feature Migration
-- ============================================================================
-- WHAT: Implements temporary anonymous letters with automatic identity reveal
-- WHY: Allows senders to temporarily hide identity, automatically revealed
--      after a fixed time window (max 72 hours, default 6 hours)
-- SECURITY: Enforced at database level with RLS, mutual connection checks
-- ============================================================================

-- ============================================================================
-- 1. UPDATE STATUS ENUM
-- ============================================================================
-- Add 'revealed' status to capsule_status enum
DO $$ 
BEGIN
  -- Check if 'revealed' already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'revealed' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'capsule_status')
  ) THEN
    ALTER TYPE capsule_status ADD VALUE 'revealed';
  END IF;
END $$;

-- ============================================================================
-- 2. ADD NEW COLUMNS TO CAPSULES TABLE
-- ============================================================================
ALTER TABLE public.capsules
  ADD COLUMN IF NOT EXISTS reveal_delay_seconds INTEGER NULL,
  ADD COLUMN IF NOT EXISTS reveal_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS sender_revealed_at TIMESTAMPTZ NULL;

-- ============================================================================
-- 2.1 BACKFILL EXISTING ANONYMOUS CAPSULES
-- ============================================================================
-- CRITICAL: Backfill reveal_delay_seconds for existing anonymous capsules
-- before adding the constraint. This ensures backward compatibility.
-- Default to 6 hours (21600 seconds) for existing anonymous capsules.
UPDATE public.capsules
SET reveal_delay_seconds = 21600  -- 6 hours default
WHERE is_anonymous = TRUE
  AND reveal_delay_seconds IS NULL;

-- ============================================================================
-- 3. ADD CONSTRAINTS
-- ============================================================================

-- Constraint: Max 72 hours (259200 seconds) for reveal delay
ALTER TABLE public.capsules
  DROP CONSTRAINT IF EXISTS capsules_reveal_delay_max;
  
ALTER TABLE public.capsules
  ADD CONSTRAINT capsules_reveal_delay_max CHECK (
    reveal_delay_seconds IS NULL
    OR reveal_delay_seconds BETWEEN 0 AND 259200
  );

-- Constraint: Anonymous letters must have delay, non-anonymous must not
-- NOTE: This constraint is safe because we backfilled existing anonymous capsules above
ALTER TABLE public.capsules
  DROP CONSTRAINT IF EXISTS capsules_anonymous_delay;
  
ALTER TABLE public.capsules
  ADD CONSTRAINT capsules_anonymous_delay CHECK (
    (is_anonymous = FALSE AND reveal_delay_seconds IS NULL)
    OR (is_anonymous = TRUE AND reveal_delay_seconds IS NOT NULL)
  );

-- ============================================================================
-- 4. CREATE INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_capsules_reveal_at 
  ON public.capsules (reveal_at) 
  WHERE reveal_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_recipient_status 
  ON public.capsules (recipient_id, status) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_sender_status 
  ON public.capsules (sender_id, status) 
  WHERE deleted_at IS NULL;

-- ============================================================================
-- 5. HELPER FUNCTION: is_mutual_connection
-- ============================================================================
-- WHAT: Checks if two users are mutual connections
-- WHY: Required for anonymous letter validation
-- USAGE: SELECT is_mutual_connection(user_a_id, user_b_id)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_mutual_connection(a UUID, b UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.connections
    WHERE (
      (user_id_1 = a AND user_id_2 = b)
      OR
      (user_id_1 = b AND user_id_2 = a)
    )
  );
$$ LANGUAGE SQL STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_mutual_connection(UUID, UUID) TO authenticated;

-- ============================================================================
-- 6. UPDATE SAFE VIEW FOR REVEAL LOGIC
-- ============================================================================
-- WHAT: Updated view that hides sender_id until reveal_at is reached
-- WHY: Enforces reveal timing at database level
-- BEHAVIOR:
--   - If is_anonymous = FALSE: Always show sender
--   - If is_anonymous = TRUE AND (reveal_at IS NULL OR now() < reveal_at): Hide sender
--   - If is_anonymous = TRUE AND now() >= reveal_at: Show sender
--   - If sender_revealed_at IS NOT NULL: Always show sender (reveal job ran)
-- NOTE: Must DROP and CREATE (not REPLACE) because we're adding new columns
--       in the middle of the column list, which PostgreSQL doesn't allow with REPLACE.
--       Dependent views (like inbox_view) will automatically get new columns via SELECT c.*
-- ============================================================================
DROP VIEW IF EXISTS public.recipient_safe_capsules_view CASCADE;

CREATE VIEW public.recipient_safe_capsules_view AS
SELECT 
  c.id,
  CASE 
    -- Non-anonymous: always show
    WHEN c.is_anonymous = FALSE THEN c.sender_id
    -- Anonymous but revealed: show sender
    WHEN c.sender_revealed_at IS NOT NULL THEN c.sender_id
    -- Anonymous and reveal time passed: show sender
    WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN c.sender_id
    -- Anonymous and not yet revealed: hide sender
    ELSE NULL
  END AS sender_id,
  CASE 
    -- Non-anonymous: show real name
    WHEN c.is_anonymous = FALSE THEN COALESCE(
      NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
      up.first_name,
      up.last_name,
      ''
    )
    -- Anonymous but revealed: show real name
    WHEN c.sender_revealed_at IS NOT NULL THEN COALESCE(
      NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
      up.first_name,
      up.last_name,
      ''
    )
    -- Anonymous and reveal time passed: show real name
    WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN COALESCE(
      NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
      up.first_name,
      up.last_name,
      ''
    )
    -- Anonymous and not yet revealed: show 'Anonymous'
    ELSE 'Anonymous'
  END AS sender_name,
  CASE 
    -- Non-anonymous: show avatar
    WHEN c.is_anonymous = FALSE THEN up.avatar_url
    -- Anonymous but revealed: show avatar
    WHEN c.sender_revealed_at IS NOT NULL THEN up.avatar_url
    -- Anonymous and reveal time passed: show avatar
    WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN up.avatar_url
    -- Anonymous and not yet revealed: hide avatar
    ELSE NULL
  END AS sender_avatar_url,
  c.recipient_id,
  r.name AS recipient_name,
  c.is_anonymous,
  c.is_disappearing,
  c.disappearing_after_open_seconds,
  c.unlocks_at,
  c.opened_at,
  c.expires_at,
  c.reveal_delay_seconds,
  c.reveal_at,
  c.sender_revealed_at,
  c.title,
  c.body_text,
  c.body_rich_text,
  c.theme_id,
  c.animation_id,
  c.status,
  c.deleted_at,
  c.created_at,
  c.updated_at
FROM public.capsules c
LEFT JOIN public.recipients r ON c.recipient_id = r.id
LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
WHERE c.deleted_at IS NULL;

-- Grant permissions on the view
GRANT SELECT ON public.recipient_safe_capsules_view TO authenticated;

-- Recreate inbox_view (was dropped by CASCADE)
-- This view depends on recipient_safe_capsules_view and uses SELECT c.*
-- so it will automatically include the new reveal columns
CREATE OR REPLACE VIEW public.inbox_view AS
SELECT 
  c.*,
  auth.uid() AS current_user_id
FROM public.recipient_safe_capsules_view c
JOIN public.recipients r ON c.recipient_id = r.id
WHERE r.email IS NOT NULL
  AND LOWER(TRIM(r.email)) = LOWER(TRIM((auth.jwt() ->> 'email')::text))
  AND c.deleted_at IS NULL;

-- Grant permissions on inbox_view
GRANT SELECT ON public.inbox_view TO authenticated;

-- ============================================================================
-- 7. RPC FUNCTION: open_letter
-- ============================================================================
-- WHAT: Server-side function to open a letter (sets opened_at, calculates reveal_at)
-- WHY: Prevents client from manipulating reveal timing
-- SECURITY: Only recipient can open, verifies eligibility
-- BEHAVIOR:
--   - Verifies caller is recipient
--   - Sets opened_at = now() (only once)
--   - If anonymous: calculates reveal_at = opened_at + delay
--   - Returns safe capsule data
-- ============================================================================
CREATE OR REPLACE FUNCTION public.open_letter(letter_id UUID)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  sender_name TEXT,
  sender_avatar_url TEXT,
  recipient_id UUID,
  is_anonymous BOOLEAN,
  status TEXT,
  reveal_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_capsule RECORD;
  v_recipient_user_id UUID;
BEGIN
  -- Get capsule and verify it exists
  SELECT c.*, r.linked_user_id, r.email
  INTO v_capsule
  FROM public.capsules c
  JOIN public.recipients r ON c.recipient_id = r.id
  WHERE c.id = letter_id
    AND c.deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Capsule not found or deleted';
  END IF;
  
  -- Verify caller is recipient
  -- Check if recipient is linked to a user (connection-based)
  IF v_capsule.linked_user_id IS NOT NULL THEN
    IF auth.uid() != v_capsule.linked_user_id THEN
      RAISE EXCEPTION 'Only recipient can open this letter';
    END IF;
    v_recipient_user_id := v_capsule.linked_user_id;
  -- Check if recipient is email-based
  ELSIF v_capsule.email IS NOT NULL THEN
    IF LOWER(TRIM(v_capsule.email)) != LOWER(TRIM((auth.jwt() ->> 'email')::text)) THEN
      RAISE EXCEPTION 'Only recipient can open this letter';
    END IF;
    -- For email-based, we can't get user_id directly, but email check is sufficient
    v_recipient_user_id := NULL;
  ELSE
    RAISE EXCEPTION 'Invalid recipient configuration';
  END IF;
  
  -- Verify letter is eligible to open (status must be 'ready' or 'sealed' with unlocks_at passed)
  IF v_capsule.status NOT IN ('sealed', 'ready') THEN
    RAISE EXCEPTION 'Letter is not eligible to open (status: %)', v_capsule.status;
  END IF;
  
  IF v_capsule.unlocks_at > now() THEN
    RAISE EXCEPTION 'Letter is not yet unlocked';
  END IF;
  
  -- Check if already opened
  IF v_capsule.opened_at IS NOT NULL THEN
    -- Return existing data (idempotent)
    RETURN QUERY
    SELECT 
      c.id,
      CASE 
        WHEN c.is_anonymous = FALSE THEN c.sender_id
        WHEN c.sender_revealed_at IS NOT NULL THEN c.sender_id
        WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN c.sender_id
        ELSE NULL
      END AS sender_id,
      CASE 
        WHEN c.is_anonymous = FALSE THEN COALESCE(
          NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
          up.first_name,
          up.last_name,
          ''
        )
        WHEN c.sender_revealed_at IS NOT NULL THEN COALESCE(
          NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
          up.first_name,
          up.last_name,
          ''
        )
        WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN COALESCE(
          NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
          up.first_name,
          up.last_name,
          ''
        )
        ELSE 'Anonymous'
      END AS sender_name,
      CASE 
        WHEN c.is_anonymous = FALSE THEN up.avatar_url
        WHEN c.sender_revealed_at IS NOT NULL THEN up.avatar_url
        WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN up.avatar_url
        ELSE NULL
      END AS sender_avatar_url,
      c.recipient_id,
      c.is_anonymous,
      c.status::TEXT,
      c.reveal_at,
      c.opened_at,
      c.created_at
    FROM public.capsules c
    LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
    WHERE c.id = letter_id;
    RETURN;
  END IF;
  
  -- Set opened_at
  UPDATE public.capsules
  SET 
    opened_at = now(),
    status = 'opened',
    updated_at = now()
  WHERE id = letter_id;
  
  -- If anonymous, calculate reveal_at
  IF v_capsule.is_anonymous = TRUE THEN
    DECLARE
      v_delay INTEGER;
      v_reveal_at TIMESTAMPTZ;
    BEGIN
      v_delay := COALESCE(v_capsule.reveal_delay_seconds, 21600); -- Default 6 hours
      
      -- Enforce max 72 hours
      IF v_delay > 259200 THEN
        v_delay := 259200;
      END IF;
      
      v_reveal_at := now() + (v_delay || ' seconds')::INTERVAL;
      
      UPDATE public.capsules
      SET 
        reveal_at = v_reveal_at,
        updated_at = now()
      WHERE id = letter_id;
    END;
  END IF;
  
  -- Return safe capsule data
  RETURN QUERY
  SELECT 
    c.id,
    CASE 
      WHEN c.is_anonymous = FALSE THEN c.sender_id
      WHEN c.sender_revealed_at IS NOT NULL THEN c.sender_id
      WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN c.sender_id
      ELSE NULL
    END AS sender_id,
    CASE 
      WHEN c.is_anonymous = FALSE THEN COALESCE(
        NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
        up.first_name,
        up.last_name,
        ''
      )
      WHEN c.sender_revealed_at IS NOT NULL THEN COALESCE(
        NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
        up.first_name,
        up.last_name,
        ''
      )
      WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN COALESCE(
        NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
        up.first_name,
        up.last_name,
        ''
      )
      ELSE 'Anonymous'
    END AS sender_name,
    CASE 
      WHEN c.is_anonymous = FALSE THEN up.avatar_url
      WHEN c.sender_revealed_at IS NOT NULL THEN up.avatar_url
      WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN up.avatar_url
      ELSE NULL
    END AS sender_avatar_url,
    c.recipient_id,
    c.is_anonymous,
    c.status::TEXT,
    c.reveal_at,
    c.opened_at,
    c.created_at
  FROM public.capsules c
  LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
  WHERE c.id = letter_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.open_letter(UUID) TO authenticated;

-- ============================================================================
-- 8. AUTOMATIC REVEAL JOB FUNCTION
-- ============================================================================
-- WHAT: Function that reveals anonymous sender identities when reveal_at is reached
-- WHY: Automatically updates status and sets sender_revealed_at
-- BEHAVIOR:
--   - Finds all anonymous letters where reveal_at <= now() and not yet revealed
--   - Sets sender_revealed_at = now() and status = 'revealed'
--   - Idempotent (safe to run multiple times)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.reveal_anonymous_senders()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- First, backfill reveal_at for any opened anonymous letters missing it
  -- This handles existing letters opened before reveal_at was added
  UPDATE public.capsules
  SET 
    reveal_at = opened_at + (
      COALESCE(reveal_delay_seconds, 21600) || ' seconds'
    )::INTERVAL,
    updated_at = now()
  WHERE 
    is_anonymous = TRUE
    AND opened_at IS NOT NULL
    AND reveal_at IS NULL
    AND deleted_at IS NULL;
  
  -- Then reveal anonymous senders where reveal_at has passed
  UPDATE public.capsules
  SET 
    sender_revealed_at = now(),
    status = 'revealed',
    updated_at = now()
  WHERE 
    is_anonymous = TRUE
    AND reveal_at IS NOT NULL
    AND reveal_at <= now()
    AND sender_revealed_at IS NULL
    AND deleted_at IS NULL;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN v_count;
END;
$$;

-- Grant execute permission (service role only, but function is SECURITY DEFINER)
GRANT EXECUTE ON FUNCTION public.reveal_anonymous_senders() TO service_role;

-- ============================================================================
-- 9. SCHEDULED JOB (pg_cron)
-- ============================================================================
-- WHAT: Runs reveal job every 1 minute
-- WHY: Ensures reveals happen promptly
-- NOTE: Requires pg_cron extension (already enabled in consolidated schema)
-- ============================================================================
SELECT cron.schedule(
  'reveal-anonymous-senders',
  '*/1 * * * *', -- Every 1 minute
  $$SELECT public.reveal_anonymous_senders();$$
);

-- ============================================================================
-- 10. UPDATE RLS POLICIES
-- ============================================================================
-- Note: RLS policies will be updated in a separate migration file
-- to keep this migration focused on schema changes

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON COLUMN public.capsules.reveal_delay_seconds IS 
  'Delay in seconds before revealing anonymous sender (0-259200, default 21600 = 6 hours)';
COMMENT ON COLUMN public.capsules.reveal_at IS 
  'Timestamp when anonymous sender will be revealed (opened_at + reveal_delay_seconds)';
COMMENT ON COLUMN public.capsules.sender_revealed_at IS 
  'Timestamp when sender was actually revealed (set by reveal job)';
COMMENT ON FUNCTION public.is_mutual_connection(UUID, UUID) IS 
  'Checks if two users are mutual connections';
COMMENT ON FUNCTION public.open_letter(UUID) IS 
  'Opens a letter (sets opened_at, calculates reveal_at for anonymous letters)';
COMMENT ON FUNCTION public.reveal_anonymous_senders() IS 
  'Automatically reveals anonymous sender identities when reveal_at is reached';
