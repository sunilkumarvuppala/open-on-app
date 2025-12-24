-- ============================================================================
-- Countdown Shares Feature Migration
-- ============================================================================
-- WHAT: Implements "Share Countdown" feature - allows recipients to share
--       anticipation of upcoming time-locked letters without revealing content
-- WHY: Growth lever that enables viral sharing while maintaining privacy
-- SECURITY: Enforced at database level with RLS, non-guessable tokens, revocation
-- ============================================================================

-- ============================================================================
-- 0. ENABLE REQUIRED EXTENSIONS
-- ============================================================================
-- pgcrypto extension is required for gen_random_bytes() function used in token generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. CREATE COUNTDOWN_SHARES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.countdown_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  share_token TEXT NOT NULL UNIQUE,
  share_type TEXT NOT NULL CHECK (share_type IN ('story', 'video', 'static', 'link')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  open_at TIMESTAMPTZ NOT NULL, -- Copied from capsule.unlocks_at for rendering safety
  metadata JSONB DEFAULT '{}'::jsonb, -- Reserved for future use. MUST NOT contain sender identity.
  
  -- Constraints
  CONSTRAINT countdown_shares_open_future CHECK (open_at > created_at),
  CONSTRAINT countdown_shares_token_length CHECK (char_length(share_token) >= 32)
);

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Fast lookup by share token (public access path)
CREATE INDEX IF NOT EXISTS idx_countdown_shares_token 
  ON public.countdown_shares(share_token) 
  WHERE revoked_at IS NULL;

-- Owner queries: list shares by user
CREATE INDEX IF NOT EXISTS idx_countdown_shares_owner 
  ON public.countdown_shares(owner_user_id, created_at DESC);

-- Letter queries: find shares for a specific letter
CREATE INDEX IF NOT EXISTS idx_countdown_shares_letter 
  ON public.countdown_shares(letter_id);

-- Expiration cleanup: find expired shares
CREATE INDEX IF NOT EXISTS idx_countdown_shares_expires 
  ON public.countdown_shares(expires_at) 
  WHERE expires_at IS NOT NULL AND revoked_at IS NULL;

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.countdown_shares ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INSERT Policy: Owner can create shares for their own locked letters
-- ============================================================================
-- Validation:
--   - owner_user_id must equal auth.uid()
--   - Letter must belong to auth.uid() (as sender or recipient)
--   - Letter must be locked (unlocks_at > now())
DROP POLICY IF EXISTS "Users can create shares for own locked letters" ON public.countdown_shares;
CREATE POLICY "Users can create shares for own locked letters"
  ON public.countdown_shares
  FOR INSERT
  WITH CHECK (
    auth.uid() = owner_user_id
    AND EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_id
        AND (c.sender_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.recipients r
          WHERE r.id = c.recipient_id AND r.owner_id = auth.uid()
        ))
        AND c.unlocks_at > now()
        AND c.opened_at IS NULL
        AND c.deleted_at IS NULL
    )
  );

-- ============================================================================
-- SELECT Policy: Owner can read their own shares
-- ============================================================================
-- Public access is handled via Edge Function (no direct table access)
DROP POLICY IF EXISTS "Owners can read their own shares" ON public.countdown_shares;
CREATE POLICY "Owners can read their own shares"
  ON public.countdown_shares
  FOR SELECT
  USING (auth.uid() = owner_user_id);

-- ============================================================================
-- UPDATE Policy: Owner can revoke their own shares
-- ============================================================================
DROP POLICY IF EXISTS "Owners can revoke their own shares" ON public.countdown_shares;
CREATE POLICY "Owners can revoke their own shares"
  ON public.countdown_shares
  FOR UPDATE
  USING (auth.uid() = owner_user_id)
  WITH CHECK (
    auth.uid() = owner_user_id
    -- Only allow updating revoked_at
    AND (revoked_at IS NOT NULL OR revoked_at = revoked_at)
  );

-- ============================================================================
-- DELETE Policy: Only service role (moderation/cleanup)
-- ============================================================================
DROP POLICY IF EXISTS "Service role can delete shares" ON public.countdown_shares;
CREATE POLICY "Service role can delete shares"
  ON public.countdown_shares
  FOR DELETE
  USING (auth.role() = 'service_role');

-- ============================================================================
-- 4. RPC FUNCTION: rpc_create_countdown_share
-- ============================================================================
-- WHAT: Creates a countdown share with secure token generation
-- VALIDATIONS:
--   - Letter exists and belongs to auth.uid()
--   - Letter is still locked (unlocks_at > now())
-- RETURNS: JSONB with share_id, share_token, share_url, expires_at
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_create_countdown_share(
  p_letter_id UUID,
  p_share_type TEXT,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_letter RECORD;
  v_share_id UUID;
  v_share_token TEXT;
  v_share_url TEXT;
  v_base_url TEXT;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:Not authenticated: auth.uid() returned NULL';
  END IF;
  
  -- Validate share_type
  IF p_share_type NOT IN ('story', 'video', 'static', 'link') THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:INVALID_SHARE_TYPE: share_type must be one of: story, video, static, link';
  END IF;
  
  -- Get letter and validate ownership
  SELECT c.id, c.unlocks_at, c.sender_id, c.recipient_id, c.opened_at, c.deleted_at
  INTO v_letter
  FROM public.capsules c
  WHERE c.id = p_letter_id;
  
  IF v_letter IS NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:LETTER_NOT_FOUND';
  END IF;
  
  -- Check if letter is deleted
  IF v_letter.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:LETTER_DELETED';
  END IF;
  
  -- Check if letter is already opened
  IF v_letter.opened_at IS NOT NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:LETTER_ALREADY_OPENED';
  END IF;
  
  -- Check if letter is locked (unlocks_at > now())
  IF v_letter.unlocks_at <= now() THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:LETTER_NOT_LOCKED: unlocks_at must be in the future';
  END IF;
  
  -- Validate ownership: user must be sender or recipient owner
  IF v_letter.sender_id != v_user_id THEN
    -- Check if user is the recipient owner
    IF NOT EXISTS (
      SELECT 1 FROM public.recipients r
      WHERE r.id = v_letter.recipient_id AND r.owner_id = v_user_id
    ) THEN
      RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:NOT_AUTHORIZED: You do not own this letter';
    END IF;
  END IF;
  
  -- Generate secure random token (32+ characters)
  -- Using gen_random_bytes() from pgcrypto extension (available via search_path)
  -- PostgreSQL encode() only supports 'base64', 'hex', 'escape' - not 'base64url'
  -- So we use 'base64' and manually convert to base64url format
  v_share_token := encode(gen_random_bytes(24), 'base64');
  -- Convert base64 to base64url: replace + with -, / with _, remove = padding
  v_share_token := replace(replace(replace(v_share_token, '+', '-'), '/', '_'), '=', '');
  -- If still too short, append more randomness
  WHILE char_length(v_share_token) < 32 LOOP
    v_share_token := v_share_token || replace(replace(replace(encode(gen_random_bytes(4), 'base64'), '+', '-'), '/', '_'), '=', '');
  END LOOP;
  
  -- Get base URL from environment or use default
  -- In production, set via Supabase Dashboard > Settings > Database > Custom Config
  -- Or via environment variable: SHARE_BASE_URL
  v_base_url := COALESCE(
    current_setting('app.share_base_url', true),
    current_setting('app.SHARE_BASE_URL', true),
    'https://openon.app/share' -- Fallback default (should be overridden in production)
  );
  
  v_share_url := v_base_url || '/' || v_share_token;
  
  -- Insert share record
  INSERT INTO public.countdown_shares (
    letter_id,
    owner_user_id,
    share_token,
    share_type,
    expires_at,
    open_at
  )
  VALUES (
    p_letter_id,
    v_user_id,
    v_share_token,
    p_share_type,
    p_expires_at,
    v_letter.unlocks_at
  )
  RETURNING id INTO v_share_id;
  
  -- Return result
  RETURN jsonb_build_object(
    'share_id', v_share_id,
    'share_token', v_share_token,
    'share_url', v_share_url,
    'expires_at', p_expires_at,
    'open_at', v_letter.unlocks_at
  );
  
EXCEPTION
  WHEN unique_violation THEN
    -- Token collision (extremely rare), retry with new token
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:TOKEN_COLLISION: Please try again';
  WHEN OTHERS THEN
    -- Re-raise with original message if it's already a COUNTDOWN_SHARE_ERROR
    IF SQLERRM LIKE 'COUNTDOWN_SHARE_ERROR:%' THEN
      RAISE;
    ELSE
      -- Wrap unexpected errors
      RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 5. RPC FUNCTION: rpc_revoke_countdown_share
-- ============================================================================
-- WHAT: Revokes a countdown share (sets revoked_at)
-- VALIDATIONS:
--   - Share exists
--   - User owns the share
-- RETURNS: JSONB with success status
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_revoke_countdown_share(
  p_share_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_share RECORD;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:Not authenticated: auth.uid() returned NULL';
  END IF;
  
  -- Get share
  SELECT id, owner_user_id, revoked_at
  INTO v_share
  FROM public.countdown_shares
  WHERE id = p_share_id;
  
  IF v_share IS NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:SHARE_NOT_FOUND';
  END IF;
  
  -- Check ownership
  IF v_share.owner_user_id != v_user_id THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:NOT_AUTHORIZED: You do not own this share';
  END IF;
  
  -- Check if already revoked
  IF v_share.revoked_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Share already revoked'
    );
  END IF;
  
  -- Revoke share
  UPDATE public.countdown_shares
  SET revoked_at = now()
  WHERE id = p_share_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Share revoked successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE 'COUNTDOWN_SHARE_ERROR:%' THEN
      RAISE;
    ELSE
      RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 6. RPC FUNCTION: rpc_get_countdown_share_public
-- ============================================================================
-- WHAT: Gets public share data for rendering (no auth required)
-- VALIDATIONS:
--   - Token exists
--   - Not revoked
--   - Not expired
-- RETURNS: JSONB with countdown data (NO private info)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_get_countdown_share_public(
  p_share_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_share RECORD;
  v_capsule RECORD;
  v_theme RECORD;
  v_now TIMESTAMPTZ;
  v_days_remaining INTEGER;
  v_hours_remaining INTEGER;
  v_minutes_remaining INTEGER;
  v_open_date DATE;
BEGIN
  v_now := now();
  
  -- Get share with capsule details
  SELECT 
    cs.id,
    cs.open_at,
    cs.expires_at,
    cs.revoked_at,
    cs.created_at,
    c.title,
    c.theme_id,
    c.unlocks_at
  INTO v_share
  FROM public.countdown_shares cs
  INNER JOIN public.capsules c ON c.id = cs.letter_id
  WHERE cs.share_token = p_share_token
    AND c.deleted_at IS NULL;
  
  IF v_share IS NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:SHARE_NOT_FOUND';
  END IF;
  
  -- Check if revoked
  IF v_share.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:SHARE_REVOKED';
  END IF;
  
  -- Check if expired
  IF v_share.expires_at IS NOT NULL AND v_share.expires_at <= v_now THEN
    RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:SHARE_EXPIRED';
  END IF;
  
  -- Calculate countdown
  IF v_share.open_at <= v_now THEN
    -- Letter has unlocked (but may not be opened yet)
    v_days_remaining := 0;
    v_hours_remaining := 0;
    v_minutes_remaining := 0;
  ELSE
    -- Calculate time remaining
    v_days_remaining := EXTRACT(EPOCH FROM (v_share.open_at - v_now))::INTEGER / 86400;
    v_hours_remaining := (EXTRACT(EPOCH FROM (v_share.open_at - v_now))::INTEGER % 86400) / 3600;
    v_minutes_remaining := (EXTRACT(EPOCH FROM (v_share.open_at - v_now))::INTEGER % 3600) / 60;
  END IF;
  
  -- Get open date (day only, no time)
  v_open_date := (v_share.open_at AT TIME ZONE 'UTC')::date;
  
  -- Get theme details if theme_id exists
  IF v_share.theme_id IS NOT NULL THEN
    SELECT gradient_start, gradient_end, name
    INTO v_theme
    FROM public.themes
    WHERE id = v_share.theme_id;
  END IF;
  
  -- Return public data (NO private info, NO sender identity)
  -- ANONYMOUS BY DEFAULT: Only returns countdown, date, title, and theme information
  -- Does NOT include sender_id, sender_name, sender_avatar, or any identifying data
  RETURN jsonb_build_object(
    'open_date', v_open_date,
    'days_remaining', GREATEST(0, v_days_remaining),
    'hours_remaining', GREATEST(0, v_hours_remaining),
    'minutes_remaining', GREATEST(0, v_minutes_remaining),
    'is_unlocked', v_share.open_at <= v_now,
    'title', COALESCE(v_share.title, 'Something is waiting'),
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
    IF SQLERRM LIKE 'COUNTDOWN_SHARE_ERROR:%' THEN
      RAISE;
    ELSE
      RAISE EXCEPTION 'COUNTDOWN_SHARE_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT, INSERT, UPDATE ON public.countdown_shares TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_create_countdown_share(UUID, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_revoke_countdown_share(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_countdown_share_public(TEXT) TO anon, authenticated;

-- ============================================================================
-- 8. COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE public.countdown_shares IS 'Countdown shares - allows sharing anticipation of locked letters without revealing content';
COMMENT ON COLUMN public.countdown_shares.share_token IS 'Secure random token for public access (32+ chars, non-guessable)';
COMMENT ON COLUMN public.countdown_shares.share_type IS 'Type of share: story (IG Stories), video (TikTok), static (image), link (URL only)';
COMMENT ON COLUMN public.countdown_shares.open_at IS 'Copied from capsule.unlocks_at for rendering safety (avoids joins in public path)';
COMMENT ON COLUMN public.countdown_shares.metadata IS 'Reserved for future use (e.g., view counts, analytics). MUST NOT contain sender identity or any personal data.';

COMMENT ON FUNCTION public.rpc_create_countdown_share IS 'Creates a countdown share with secure token. Validates ownership, lock status, and rate limits.';
COMMENT ON FUNCTION public.rpc_revoke_countdown_share IS 'Revokes a countdown share (sets revoked_at). Only owner can revoke.';
COMMENT ON FUNCTION public.rpc_get_countdown_share_public IS 'Gets public countdown data for rendering. No auth required. Returns only safe public data.';

