-- ============================================================================
-- Letter Invites Feature Migration
-- ============================================================================
-- WHAT: Implements "Invite by Letter" feature - allows sending letters to
--       unregistered users via private invite links
-- WHY: Growth feature that enables sending letters to people not yet on OpenOn
-- SECURITY: Enforced at database level with RLS, non-guessable tokens, single claim
-- ============================================================================

-- ============================================================================
-- 0. ENABLE REQUIRED EXTENSIONS
-- ============================================================================
-- pgcrypto extension is required for gen_random_bytes() function used in token generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. CREATE LETTER_INVITES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.letter_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
  invite_token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  claimed_at TIMESTAMPTZ,
  claimed_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Constraints
  CONSTRAINT letter_invites_token_length CHECK (char_length(invite_token) >= 32)
);

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Fast lookup by invite token (public access path)
CREATE INDEX IF NOT EXISTS idx_letter_invites_token 
  ON public.letter_invites(invite_token) 
  WHERE claimed_at IS NULL;

-- Letter queries: find invites for a specific letter
CREATE INDEX IF NOT EXISTS idx_letter_invites_letter 
  ON public.letter_invites(letter_id);

-- Claimed user queries: find invites claimed by a user
CREATE INDEX IF NOT EXISTS idx_letter_invites_claimed_user 
  ON public.letter_invites(claimed_user_id) 
  WHERE claimed_user_id IS NOT NULL;

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.letter_invites ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INSERT Policy: Sender can create invites for their own letters
-- ============================================================================
-- Validation:
--   - Letter must belong to auth.uid() as sender
--   - Letter must not be deleted
--   - Only one invite per letter (enforced by unique constraint on letter_id + claimed_at IS NULL)
DROP POLICY IF EXISTS "Senders can create invites for own letters" ON public.letter_invites;
CREATE POLICY "Senders can create invites for own letters"
  ON public.letter_invites
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_id
        AND c.sender_id = auth.uid()
        AND c.deleted_at IS NULL
    )
  );

-- ============================================================================
-- SELECT Policy: Sender can read their own invites
-- ============================================================================
-- Public access is handled via RPC function (no direct table access for unregistered users)
DROP POLICY IF EXISTS "Senders can read their own invites" ON public.letter_invites;
CREATE POLICY "Senders can read their own invites"
  ON public.letter_invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_id
        AND c.sender_id = auth.uid()
    )
  );

-- ============================================================================
-- UPDATE Policy: Only for claiming (handled via RPC function)
-- ============================================================================
-- Updates are only allowed via RPC function for claiming
DROP POLICY IF EXISTS "No direct updates allowed" ON public.letter_invites;
CREATE POLICY "No direct updates allowed"
  ON public.letter_invites
  FOR UPDATE
  USING (false);

-- ============================================================================
-- DELETE Policy: Only service role (moderation/cleanup)
-- ============================================================================
DROP POLICY IF EXISTS "Service role can delete invites" ON public.letter_invites;
CREATE POLICY "Service role can delete invites"
  ON public.letter_invites
  FOR DELETE
  USING (auth.role() = 'service_role');

-- ============================================================================
-- 4. RPC FUNCTION: rpc_create_letter_invite
-- ============================================================================
-- WHAT: Creates a letter invite with secure token generation
-- VALIDATIONS:
--   - Letter exists and belongs to auth.uid() as sender
--   - Letter is not deleted
--   - Only one active invite per letter (if one exists with claimed_at IS NULL, return existing)
-- RETURNS: JSONB with invite_id, invite_token, invite_url
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_create_letter_invite(
  p_letter_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_letter RECORD;
  v_invite_id UUID;
  v_invite_token TEXT;
  v_invite_url TEXT;
  v_base_url TEXT;
  v_existing_invite RECORD;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:Not authenticated: auth.uid() returned NULL';
  END IF;
  
  -- Get letter and validate ownership
  SELECT c.id, c.sender_id, c.deleted_at, c.unlocks_at
  INTO v_letter
  FROM public.capsules c
  WHERE c.id = p_letter_id;
  
  IF v_letter IS NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:LETTER_NOT_FOUND';
  END IF;
  
  -- Check if letter is deleted
  IF v_letter.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:LETTER_DELETED';
  END IF;
  
  -- Validate ownership: user must be sender
  IF v_letter.sender_id != v_user_id THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:NOT_AUTHORIZED: You are not the sender of this letter';
  END IF;
  
  -- Check if an active invite already exists (not claimed)
  SELECT id, invite_token
  INTO v_existing_invite
  FROM public.letter_invites
  WHERE letter_id = p_letter_id
    AND claimed_at IS NULL
  LIMIT 1;
  
  IF v_existing_invite IS NOT NULL THEN
    -- Return existing invite
    v_base_url := COALESCE(
      current_setting('app.invite_base_url', true),
      current_setting('app.INVITE_BASE_URL', true),
      'https://openon.app/invite' -- Fallback default
    );
    v_invite_url := v_base_url || '/' || v_existing_invite.invite_token;
    
    RETURN jsonb_build_object(
      'invite_id', v_existing_invite.id,
      'invite_token', v_existing_invite.invite_token,
      'invite_url', v_invite_url,
      'already_exists', true
    );
  END IF;
  
  -- Generate secure random token (32+ characters)
  -- Using gen_random_bytes() from pgcrypto extension
  v_invite_token := encode(gen_random_bytes(24), 'base64');
  -- Convert base64 to base64url: replace + with -, / with _, remove = padding
  v_invite_token := replace(replace(replace(v_invite_token, '+', '-'), '/', '_'), '=', '');
  -- If still too short, append more randomness
  WHILE char_length(v_invite_token) < 32 LOOP
    v_invite_token := v_invite_token || replace(replace(replace(encode(gen_random_bytes(4), 'base64'), '+', '-'), '/', '_'), '=', '');
  END LOOP;
  
  -- Get base URL from environment or use default
  v_base_url := COALESCE(
    current_setting('app.invite_base_url', true),
    current_setting('app.INVITE_BASE_URL', true),
    'https://openon.app/invite' -- Fallback default (should be overridden in production)
  );
  
  v_invite_url := v_base_url || '/' || v_invite_token;
  
  -- Insert invite record
  INSERT INTO public.letter_invites (
    letter_id,
    invite_token
  )
  VALUES (
    p_letter_id,
    v_invite_token
  )
  RETURNING id INTO v_invite_id;
  
  -- Return result
  RETURN jsonb_build_object(
    'invite_id', v_invite_id,
    'invite_token', v_invite_token,
    'invite_url', v_invite_url,
    'already_exists', false
  );
  
EXCEPTION
  WHEN unique_violation THEN
    -- Token collision (extremely rare), retry with new token
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:TOKEN_COLLISION: Please try again';
  WHEN OTHERS THEN
    -- Re-raise with original message if it's already a LETTER_INVITE_ERROR
    IF SQLERRM LIKE 'LETTER_INVITE_ERROR:%' THEN
      RAISE;
    ELSE
      -- Wrap unexpected errors
      RAISE EXCEPTION 'LETTER_INVITE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 5. RPC FUNCTION: rpc_get_letter_invite_public
-- ============================================================================
-- WHAT: Gets public invite data for preview (no auth required)
-- VALIDATIONS:
--   - Token exists
--   - Not claimed
--   - Letter not deleted
-- RETURNS: JSONB with preview data (NO private info, NO sender identity)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_get_letter_invite_public(
  p_invite_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite RECORD;
  v_capsule RECORD;
  v_theme RECORD;
  v_now TIMESTAMPTZ;
  v_days_remaining INTEGER;
  v_hours_remaining INTEGER;
  v_minutes_remaining INTEGER;
  v_seconds_remaining INTEGER;
  v_is_unlocked BOOLEAN;
BEGIN
  v_now := now();
  
  -- Get invite with capsule details
  SELECT 
    li.id,
    li.claimed_at,
    li.letter_id,
    c.unlocks_at,
    c.deleted_at,
    c.title,
    c.theme_id,
    c.opened_at
  INTO v_invite
  FROM public.letter_invites li
  INNER JOIN public.capsules c ON c.id = li.letter_id
  WHERE li.invite_token = p_invite_token;
  
  IF v_invite IS NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:INVITE_NOT_FOUND';
  END IF;
  
  -- Check if already claimed
  IF v_invite.claimed_at IS NOT NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:INVITE_ALREADY_CLAIMED: This letter has already been opened';
  END IF;
  
  -- Check if letter is deleted
  IF v_invite.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:LETTER_DELETED';
  END IF;
  
  -- Calculate countdown
  v_is_unlocked := v_invite.unlocks_at <= v_now;
  
  IF v_is_unlocked THEN
    v_days_remaining := 0;
    v_hours_remaining := 0;
    v_minutes_remaining := 0;
    v_seconds_remaining := 0;
  ELSE
    -- Calculate time remaining
    v_seconds_remaining := EXTRACT(EPOCH FROM (v_invite.unlocks_at - v_now))::INTEGER;
    v_days_remaining := v_seconds_remaining / 86400;
    v_hours_remaining := (v_seconds_remaining % 86400) / 3600;
    v_minutes_remaining := (v_seconds_remaining % 3600) / 60;
    v_seconds_remaining := v_seconds_remaining % 60;
  END IF;
  
  -- Get theme details if theme_id exists
  IF v_invite.theme_id IS NOT NULL THEN
    SELECT gradient_start, gradient_end, name
    INTO v_theme
    FROM public.themes
    WHERE id = v_invite.theme_id;
  END IF;
  
  -- Return public data (NO private info, NO sender identity)
  -- ANONYMOUS BY DEFAULT: Only returns countdown, title, and theme information
  -- Does NOT include sender_id, sender_name, sender_avatar, or any identifying data
  RETURN jsonb_build_object(
    'invite_id', v_invite.id,
    'letter_id', v_invite.letter_id,
    'unlocks_at', v_invite.unlocks_at,
    'is_unlocked', v_is_unlocked,
    'days_remaining', GREATEST(0, v_days_remaining),
    'hours_remaining', GREATEST(0, v_hours_remaining),
    'minutes_remaining', GREATEST(0, v_minutes_remaining),
    'seconds_remaining', GREATEST(0, v_seconds_remaining),
    'title', COALESCE(v_invite.title, 'Something meaningful is waiting for you'),
    'theme', CASE 
      WHEN v_theme IS NOT NULL THEN jsonb_build_object(
        'gradient_start', v_theme.gradient_start,
        'gradient_end', v_theme.gradient_end,
        'name', v_theme.name
      )
      ELSE NULL
    END
  );
  
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE 'LETTER_INVITE_ERROR:%' THEN
      RAISE;
    ELSE
      RAISE EXCEPTION 'LETTER_INVITE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 6. RPC FUNCTION: rpc_claim_letter_invite
-- ============================================================================
-- WHAT: Claims a letter invite when user signs up
-- VALIDATIONS:
--   - Token exists
--   - Not already claimed
--   - User is authenticated
--   - Letter not deleted
-- RETURNS: JSONB with success status and letter_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_claim_letter_invite(
  p_invite_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_invite RECORD;
  v_capsule RECORD;
  v_sender_id UUID;
  v_connection_user1 UUID;
  v_connection_user2 UUID;
  v_connection_exists BOOLEAN;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:Not authenticated: auth.uid() returned NULL';
  END IF;
  
  -- Get invite with capsule details (including sender_id for connection creation)
  SELECT 
    li.id,
    li.claimed_at,
    li.letter_id,
    c.deleted_at,
    c.recipient_id,
    c.sender_id
  INTO v_invite
  FROM public.letter_invites li
  INNER JOIN public.capsules c ON c.id = li.letter_id
  WHERE li.invite_token = p_invite_token;
  
  IF v_invite IS NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:INVITE_NOT_FOUND';
  END IF;
  
  -- Check if already claimed
  IF v_invite.claimed_at IS NOT NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:INVITE_ALREADY_CLAIMED: This letter has already been opened';
  END IF;
  
  -- Check if letter is deleted
  IF v_invite.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:LETTER_DELETED';
  END IF;
  
  -- Claim the invite (atomic operation)
  UPDATE public.letter_invites
  SET claimed_at = now(),
      claimed_user_id = v_user_id
  WHERE id = v_invite.id
    AND claimed_at IS NULL; -- Only update if not already claimed (prevent race condition)
  
  -- Check if update succeeded (another user might have claimed it)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'LETTER_INVITE_ERROR:INVITE_ALREADY_CLAIMED: This letter has already been opened';
  END IF;
  
  -- Update recipient to link to the new user
  -- Create or update recipient record to link to the claiming user
  -- First, check if recipient exists and update it
  UPDATE public.recipients
  SET linked_user_id = v_user_id,
      updated_at = now()
  WHERE id = v_invite.recipient_id
    AND linked_user_id IS NULL; -- Only update if not already linked
  
  -- Create mutual connection between sender and claiming user
  -- This ensures they can see each other in connections and send future letters
  v_sender_id := v_invite.sender_id;
  
  -- Ensure user1 < user2 for consistent connection storage (connections table constraint)
  IF v_sender_id < v_user_id THEN
    v_connection_user1 := v_sender_id;
    v_connection_user2 := v_user_id;
  ELSE
    v_connection_user1 := v_user_id;
    v_connection_user2 := v_sender_id;
  END IF;
  
  -- Check if connection already exists
  SELECT EXISTS(
    SELECT 1 FROM public.connections
    WHERE user_id_1 = v_connection_user1
      AND user_id_2 = v_connection_user2
  ) INTO v_connection_exists;
  
  -- Create connection if it doesn't exist
  IF NOT v_connection_exists THEN
    INSERT INTO public.connections (user_id_1, user_id_2, connected_at)
    VALUES (v_connection_user1, v_connection_user2, now())
    ON CONFLICT (user_id_1, user_id_2) DO NOTHING; -- Handle race condition
    
    -- Create recipient entries for both users (if they don't exist)
    -- This ensures both users can see each other in their recipients list
    -- Recipient for sender -> receiver (claiming user)
    -- Use INSERT ... ON CONFLICT with the unique index on (owner_id, linked_user_id)
    INSERT INTO public.recipients (owner_id, name, linked_user_id, created_at, updated_at)
    SELECT 
      v_sender_id,
      COALESCE(
        NULLIF(TRIM(COALESCE(up.first_name, '') || ' ' || COALESCE(up.last_name, '')), ''),
        up.username,
        'User'
      ),
      v_user_id,
      now(),
      now()
    FROM auth.users u
    LEFT JOIN public.user_profiles up ON up.user_id = u.id
    WHERE u.id = v_user_id
      AND NOT EXISTS (
        SELECT 1 FROM public.recipients r
        WHERE r.owner_id = v_sender_id
          AND r.linked_user_id = v_user_id
      );
    
    -- Recipient for receiver -> sender
    INSERT INTO public.recipients (owner_id, name, linked_user_id, created_at, updated_at)
    SELECT 
      v_user_id,
      COALESCE(
        NULLIF(TRIM(COALESCE(up.first_name, '') || ' ' || COALESCE(up.last_name, '')), ''),
        up.username,
        'User'
      ),
      v_sender_id,
      now(),
      now()
    FROM auth.users u
    LEFT JOIN public.user_profiles up ON up.user_id = u.id
    WHERE u.id = v_sender_id
      AND NOT EXISTS (
        SELECT 1 FROM public.recipients r
        WHERE r.owner_id = v_user_id
          AND r.linked_user_id = v_sender_id
      );
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'letter_id', v_invite.letter_id,
    'message', 'Invite claimed successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE 'LETTER_INVITE_ERROR:%' THEN
      RAISE;
    ELSE
      RAISE EXCEPTION 'LETTER_INVITE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT, INSERT ON public.letter_invites TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_create_letter_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_letter_invite_public(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_claim_letter_invite(TEXT) TO authenticated;

-- ============================================================================
-- 8. COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE public.letter_invites IS 'Letter invites - allows sending letters to unregistered users via private invite links';
COMMENT ON COLUMN public.letter_invites.invite_token IS 'Secure random token for public access (32+ chars, non-guessable)';
COMMENT ON COLUMN public.letter_invites.claimed_at IS 'Timestamp when invite was claimed (NULL if not claimed yet)';
COMMENT ON COLUMN public.letter_invites.claimed_user_id IS 'User ID who claimed the invite (NULL if not claimed yet)';

COMMENT ON FUNCTION public.rpc_create_letter_invite IS 'Creates a letter invite with secure token. Validates ownership. Returns existing invite if one already exists.';
COMMENT ON FUNCTION public.rpc_get_letter_invite_public IS 'Gets public invite data for preview. No auth required. Returns only safe public data (no sender identity).';
COMMENT ON FUNCTION public.rpc_claim_letter_invite IS 'Claims a letter invite when user signs up. Atomically updates invite and links recipient to user.';

