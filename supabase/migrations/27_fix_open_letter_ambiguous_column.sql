-- ============================================================================
-- Migration 27: Fix ambiguous column reference and datatype mismatch in open_letter function
-- ============================================================================
-- WHAT: Fixes bugs introduced in migrations 25 and 26:
--   - Ambiguous column references in UPDATE statement
--   - Datatype mismatch for status column (enum vs TEXT)
-- WHY: 
--   1. PostgreSQL was unable to determine if column names referred to RETURNS TABLE columns or table columns
--   2. Status column is capsule_status enum but RETURNS TABLE expects TEXT
-- FIXES:
--   1. Use table alias (AS c) in UPDATE statement and qualify all column references (c.id, c.is_anonymous, etc.)
--   2. Cast status to TEXT in RETURN QUERY statements (c.status::TEXT)
-- DEPENDS ON: Migrations 25 and 26 (applies fixes to their changes)
-- FINAL STATE: This is the final, working version of the open_letter function
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
  
  -- Verify caller is recipient OR sender (ONLY for confirmed self-sent letters)
  -- First check: Is caller the sender? Only allow if this is a confirmed self-send
  IF auth.uid() = v_capsule.sender_id THEN
    -- Caller is the sender - ONLY allow if this is a confirmed self-send
    -- For self-sends, recipient's linked_user_id MUST match sender_id
    IF v_capsule.linked_user_id IS NOT NULL AND v_capsule.linked_user_id = v_capsule.sender_id THEN
      -- Confirmed self-send - allow sender to open
      v_recipient_user_id := v_capsule.sender_id;
    ELSE
      -- Sender trying to open letter sent to someone else - NOT ALLOWED
      -- This is a security check: senders cannot open letters they sent to others
      RAISE EXCEPTION 'Only recipient can open this letter';
    END IF;
  -- Second check: Is caller the recipient? (normal case)
  ELSIF v_capsule.linked_user_id IS NOT NULL THEN
    -- Recipient is linked to a user (connection-based)
    IF auth.uid() != v_capsule.linked_user_id THEN
      RAISE EXCEPTION 'Only recipient can open this letter';
    END IF;
    v_recipient_user_id := v_capsule.linked_user_id;
  ELSIF v_capsule.email IS NOT NULL THEN
    -- Recipient is email-based
    IF LOWER(TRIM(v_capsule.email)) != LOWER(TRIM((auth.jwt() ->> 'email')::text)) THEN
      RAISE EXCEPTION 'Only recipient can open this letter';
    END IF;
    -- For email-based, we can't get user_id directly, but email check is sufficient
    v_recipient_user_id := NULL;
  ELSE
    -- No linked_user_id and no email - invalid recipient configuration
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
  
  -- Open the letter: set opened_at and calculate reveal_at for anonymous letters
  -- FIX: Use table alias to avoid ambiguity with RETURNS TABLE column "id"
  UPDATE public.capsules AS c
  SET 
    opened_at = now(),
    status = 'opened',
    -- For anonymous letters: calculate reveal_at = opened_at + delay
    -- Note: Database constraint enforces max 259200 seconds (72 hours)
    reveal_at = CASE 
      WHEN c.is_anonymous = TRUE AND c.reveal_at IS NULL THEN
        now() + (
          LEAST(COALESCE(c.reveal_delay_seconds, 21600), 259200) || ' seconds'
        )::INTERVAL
      ELSE c.reveal_at
    END,
    updated_at = now()
  WHERE c.id = letter_id;
  
  -- Return the updated capsule data
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

COMMENT ON FUNCTION public.open_letter(UUID) IS 
'Opens a letter (sets opened_at, calculates reveal_at for anonymous letters). 
SECURITY: Only recipients can open letters sent to them.
EXCEPTION: Senders can ONLY open letters they sent to themselves (self-sends where recipient.linked_user_id = sender_id).
Senders CANNOT open letters they sent to other people.
FIX: 
1. UPDATE statement uses table alias (AS c) and all column references are qualified (c.id, c.is_anonymous, c.reveal_at, etc.) to avoid ambiguity with RETURNS TABLE columns.
2. Status column is cast to TEXT (c.status::TEXT) in RETURN QUERY statements to match RETURNS TABLE declaration.';

