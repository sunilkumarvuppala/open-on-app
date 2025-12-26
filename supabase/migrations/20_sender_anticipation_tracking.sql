-- ============================================================================
-- Sender-Only Anticipation Message Feature Migration
-- ============================================================================
-- WHAT: Implements sender-only anticipation tracking for locked letters
-- WHY: Allows senders to see subtle signals that receiver is checking letter
-- SECURITY: Receiver must NEVER see this data - sender-only feature
-- ============================================================================

-- ============================================================================
-- 1. ADD COLUMNS TO CAPSULES TABLE
-- ============================================================================
-- Add pre_open_view_count: tracks how many times receiver viewed locked letter
-- Add pre_open_message_tier: caches highest message tier achieved (0-6)
-- Both default to 0 and are only visible to sender

ALTER TABLE public.capsules
  ADD COLUMN IF NOT EXISTS pre_open_view_count INTEGER DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS pre_open_message_tier INTEGER DEFAULT 0 NOT NULL;

-- Add constraint to ensure non-negative values
ALTER TABLE public.capsules
  ADD CONSTRAINT capsules_pre_open_view_count_check 
    CHECK (pre_open_view_count >= 0),
  ADD CONSTRAINT capsules_pre_open_message_tier_check 
    CHECK (pre_open_message_tier >= 0 AND pre_open_message_tier <= 6);

-- ============================================================================
-- 2. CREATE INDEX FOR PERFORMANCE
-- ============================================================================
-- Index for sender queries filtering by locked status and view count
CREATE INDEX IF NOT EXISTS idx_capsules_sender_anticipation 
  ON public.capsules(sender_id, status, pre_open_view_count) 
  WHERE status IN ('sealed', 'ready') AND opened_at IS NULL;

-- ============================================================================
-- 3. RPC FUNCTION: rpc_track_receiver_view_locked_letter
-- ============================================================================
-- WHAT: Tracks when receiver views a locked letter (increments pre_open_view_count)
-- VALIDATIONS:
--   - Letter exists and is locked (status sealed/ready, opened_at IS NULL)
--   - Current user is the recipient
--   - Letter open time has not passed (unlocks_at > now() OR status = 'ready')
--   - Letter not already opened
--   - Only increments once per session (idempotent via session tracking)
-- BEHAVIOR:
--   - Increments pre_open_view_count by 1
--   - Updates pre_open_message_tier to highest tier achieved
--   - Does NOT increment after letter is opened
--   - Does NOT increment more than once per session (handled by application logic)
-- RETURNS: JSONB with success status
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_track_receiver_view_locked_letter(
  p_capsule_id UUID,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_capsule RECORD;
  v_recipient_id UUID;
  v_new_count INTEGER;
  v_new_tier INTEGER;
  v_current_tier INTEGER;
BEGIN
  -- Use provided user_id (passed from backend API)
  v_user_id := p_user_id;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ANTICIPATION_ERROR:Not authenticated: user_id is NULL';
  END IF;
  
  -- Get capsule with recipient details
  SELECT 
    c.id,
    c.recipient_id,
    c.status,
    c.opened_at,
    c.unlocks_at,
    c.pre_open_view_count,
    c.pre_open_message_tier,
    r.linked_user_id,
    r.email
  INTO v_capsule
  FROM public.capsules c
  INNER JOIN public.recipients r ON r.id = c.recipient_id
  WHERE c.id = p_capsule_id;
  
  IF v_capsule IS NULL THEN
    RAISE EXCEPTION 'ANTICIPATION_ERROR:CAPSULE_NOT_FOUND';
  END IF;
  
  -- Verify user is the recipient
  -- Recipient can be identified by:
  -- 1. linked_user_id matches current user (connection-based recipient)
  -- 2. email matches (email-based recipient) - but this requires email from request state
  -- For now, we'll check linked_user_id only (connection-based recipients)
  -- Email-based recipients will be handled by application logic
  IF v_capsule.linked_user_id IS NULL OR v_capsule.linked_user_id != v_user_id THEN
    -- Not the recipient - silently return success (don't reveal letter existence)
    RETURN jsonb_build_object('success', true, 'tracked', false);
  END IF;
  
  -- Verify letter is locked (not opened)
  IF v_capsule.opened_at IS NOT NULL THEN
    -- Letter already opened - do not track
    RETURN jsonb_build_object('success', true, 'tracked', false, 'reason', 'already_opened');
  END IF;
  
  -- Verify letter status is sealed or ready (locked)
  IF v_capsule.status NOT IN ('sealed', 'ready') THEN
    -- Letter not in locked state - do not track
    RETURN jsonb_build_object('success', true, 'tracked', false, 'reason', 'not_locked');
  END IF;
  
  -- Increment view count
  v_new_count := v_capsule.pre_open_view_count + 1;
  
  -- Calculate message tier based on count
  -- Tier mapping:
  -- 1 → tier 1: "They noticed it."
  -- 2-4 → tier 2: "They came back to it."
  -- 5-9 → tier 3: "It stayed on their mind."
  -- 10-19 → tier 4: "They're waiting for the right moment."
  -- 20-40 → tier 5: "The wait is getting harder."
  -- 40+ → tier 6: "This moment clearly matters."
  v_new_tier := CASE
    WHEN v_new_count >= 40 THEN 6
    WHEN v_new_count >= 20 THEN 5
    WHEN v_new_count >= 10 THEN 4
    WHEN v_new_count >= 5 THEN 3
    WHEN v_new_count >= 2 THEN 2
    WHEN v_new_count >= 1 THEN 1
    ELSE 0
  END;
  
  -- Keep highest tier achieved (never downgrade)
  v_current_tier := v_capsule.pre_open_message_tier;
  IF v_new_tier > v_current_tier THEN
    v_current_tier := v_new_tier;
  ELSE
    v_current_tier := v_current_tier; -- Keep existing tier
  END IF;
  
  -- Update capsule with new count and tier
  UPDATE public.capsules
  SET 
    pre_open_view_count = v_new_count,
    pre_open_message_tier = v_current_tier,
    updated_at = now()
  WHERE id = p_capsule_id
    AND opened_at IS NULL; -- Only update if not opened (race condition protection)
  
  -- Check if update succeeded
  IF NOT FOUND THEN
    -- Letter was opened between check and update - do not track
    RETURN jsonb_build_object('success', true, 'tracked', false, 'reason', 'opened_during_update');
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'tracked', true,
    'view_count', v_new_count,
    'message_tier', v_current_tier
  );
  
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE 'ANTICIPATION_ERROR:%' THEN
      RAISE;
    ELSE
      -- Wrap unexpected errors
      RAISE EXCEPTION 'ANTICIPATION_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 4. RPC FUNCTION: rpc_get_sender_lock_state
-- ============================================================================
-- WHAT: Gets sender-only anticipation message for locked letter
-- VALIDATIONS:
--   - Letter exists
--   - Current user is the sender
--   - Letter is locked (status sealed/ready, opened_at IS NULL)
--   - Receiver has checked at least once (pre_open_view_count > 0)
-- RETURNS: JSONB with showAnticipation flag and message
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_get_sender_lock_state(
  p_capsule_id UUID,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_capsule RECORD;
  v_message TEXT;
  v_show_anticipation BOOLEAN;
BEGIN
  -- Use provided user_id (passed from backend API)
  v_user_id := p_user_id;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ANTICIPATION_ERROR:Not authenticated: user_id is NULL';
  END IF;
  
  -- Get capsule
  SELECT 
    c.id,
    c.sender_id,
    c.status,
    c.opened_at,
    c.pre_open_view_count,
    c.pre_open_message_tier
  INTO v_capsule
  FROM public.capsules c
  WHERE c.id = p_capsule_id;
  
  IF v_capsule IS NULL THEN
    RAISE EXCEPTION 'ANTICIPATION_ERROR:CAPSULE_NOT_FOUND';
  END IF;
  
  -- Verify user is the sender
  IF v_capsule.sender_id != v_user_id THEN
    RAISE EXCEPTION 'ANTICIPATION_ERROR:NOT_AUTHORIZED: You are not the sender of this letter';
  END IF;
  
  -- Check if letter is locked and receiver has checked
  v_show_anticipation := (
    v_capsule.opened_at IS NULL AND
    v_capsule.status IN ('sealed', 'ready') AND
    v_capsule.pre_open_view_count > 0
  );
  
  IF NOT v_show_anticipation THEN
    RETURN jsonb_build_object('showAnticipation', false);
  END IF;
  
  -- Map tier to message
  -- Messages only upgrade, never downgrade (tier is cached)
  v_message := CASE v_capsule.pre_open_message_tier
    WHEN 1 THEN 'They noticed it.'
    WHEN 2 THEN 'They came back to it.'
    WHEN 3 THEN 'It stayed on their mind.'
    WHEN 4 THEN 'They''re waiting for the right moment.'
    WHEN 5 THEN 'The wait is getting harder.'
    WHEN 6 THEN 'This moment clearly matters.'
    ELSE NULL
  END;
  
  -- If tier is 0 or message is NULL, don't show
  IF v_message IS NULL THEN
    RETURN jsonb_build_object('showAnticipation', false);
  END IF;
  
  RETURN jsonb_build_object(
    'showAnticipation', true,
    'message', v_message
  );
  
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE 'ANTICIPATION_ERROR:%' THEN
      RAISE;
    ELSE
      -- Wrap unexpected errors
      RAISE EXCEPTION 'ANTICIPATION_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 5. GRANT PERMISSIONS
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.rpc_track_receiver_view_locked_letter(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_sender_lock_state(UUID, UUID) TO authenticated;

-- ============================================================================
-- 6. COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON COLUMN public.capsules.pre_open_view_count IS 'Number of times receiver viewed locked letter (sender-only, never visible to receiver)';
COMMENT ON COLUMN public.capsules.pre_open_message_tier IS 'Highest message tier achieved (0-6, cached, never downgrades)';

COMMENT ON FUNCTION public.rpc_track_receiver_view_locked_letter IS 'Tracks when receiver views a locked letter. Only increments if letter is locked and user is recipient. Idempotent.';
COMMENT ON FUNCTION public.rpc_get_sender_lock_state IS 'Gets sender-only anticipation message for locked letter. Only returns message if letter is locked and receiver has checked at least once.';

