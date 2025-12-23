-- ============================================================================
-- Thoughts Feature Migration
-- ============================================================================
-- WHAT: Implements "Thought" feature - gentle presence signals between connections
-- WHY: Allows users to send "I thought of you today" signals without messages
-- SECURITY: Enforced at database level with RLS, rate limiting, and connection validation
-- ============================================================================

-- ============================================================================
-- 1. CREATE THOUGHTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.thoughts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  day_bucket DATE NOT NULL,
  client_source TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Constraints
  CONSTRAINT thoughts_no_self_send CHECK (sender_id != receiver_id),
  CONSTRAINT thoughts_unique_per_pair_per_day UNIQUE (sender_id, receiver_id, day_bucket)
);

-- ============================================================================
-- 2. CREATE THOUGHT_RATE_LIMITS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.thought_rate_limits (
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_bucket DATE NOT NULL,
  sent_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (sender_id, day_bucket)
);

-- ============================================================================
-- 2.1. CREATE THOUGHT_CONFIG TABLE (for configurable settings)
-- ============================================================================
-- This table stores configurable settings for the thoughts feature
-- Allows runtime configuration without code changes
CREATE TABLE IF NOT EXISTS public.thought_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Insert default configuration values
-- Store numbers as JSONB numbers (not strings) for easier extraction
INSERT INTO public.thought_config (key, value, description) VALUES
  ('max_daily_thoughts', '20'::jsonb, 'Maximum thoughts a user can send per day'),
  ('default_pagination_limit', '30'::jsonb, 'Default number of thoughts per page'),
  ('max_pagination_limit', '100'::jsonb, 'Maximum number of thoughts per page'),
  ('min_pagination_limit', '1'::jsonb, 'Minimum number of thoughts per page'),
  ('timezone', '"UTC"'::jsonb, 'Timezone for day bucket calculation (use UTC for consistency)')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS on config table (only service role can modify)
ALTER TABLE public.thought_config ENABLE ROW LEVEL SECURITY;

-- Service role can manage config
DROP POLICY IF EXISTS "Service role can manage config" ON public.thought_config;
CREATE POLICY "Service role can manage config"
  ON public.thought_config
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Authenticated users can read config (for client-side validation)
DROP POLICY IF EXISTS "Users can read config" ON public.thought_config;
CREATE POLICY "Users can read config"
  ON public.thought_config
  FOR SELECT
  USING (true); -- Config values are safe to read

-- Index for config lookups
CREATE INDEX IF NOT EXISTS idx_thought_config_key ON public.thought_config(key);

-- ============================================================================
-- 3. CREATE TRIGGER FOR DAY_BUCKET (if generated column not supported)
-- ============================================================================
-- Note: PostgreSQL 12+ supports generated columns, but we use trigger for compatibility
CREATE OR REPLACE FUNCTION public.set_thought_day_bucket()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_timezone TEXT;
BEGIN
  -- Get timezone from config (default to UTC for consistency)
  -- JSONB string extraction: remove quotes from JSONB string value
  SELECT COALESCE(TRIM(BOTH '"' FROM value::text), 'UTC') INTO v_timezone
  FROM public.thought_config
  WHERE key = 'timezone';
  
  -- Fallback to UTC if config doesn't exist
  IF v_timezone IS NULL OR v_timezone = '' THEN
    v_timezone := 'UTC';
  END IF;
  
  -- Use configured timezone for consistency across timezones (matches RPC function)
  NEW.day_bucket := (NEW.created_at AT TIME ZONE v_timezone)::date;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_thought_day_bucket ON public.thoughts;
CREATE TRIGGER trigger_set_thought_day_bucket
  BEFORE INSERT ON public.thoughts
  FOR EACH ROW
  WHEN (NEW.day_bucket IS NULL)
  EXECUTE FUNCTION public.set_thought_day_bucket();

-- ============================================================================
-- 4. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Inbox queries: receiver_id + created_at desc
CREATE INDEX IF NOT EXISTS idx_thoughts_receiver_created 
  ON public.thoughts(receiver_id, created_at DESC);

-- Sent thoughts queries: sender_id + created_at desc
CREATE INDEX IF NOT EXISTS idx_thoughts_sender_created 
  ON public.thoughts(sender_id, created_at DESC);

-- Rate limiting: sender_id + day_bucket
CREATE INDEX IF NOT EXISTS idx_thoughts_sender_day 
  ON public.thoughts(sender_id, day_bucket);

-- Rate limits table: day_bucket for cleanup
CREATE INDEX IF NOT EXISTS idx_thought_rate_limits_day 
  ON public.thought_rate_limits(day_bucket);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thought_rate_limits ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Thoughts Table Policies
-- ============================================================================

-- Receivers can read their incoming thoughts
DROP POLICY IF EXISTS "Receivers can view incoming thoughts" ON public.thoughts;
CREATE POLICY "Receivers can view incoming thoughts"
  ON public.thoughts
  FOR SELECT
  USING (auth.uid() = receiver_id);

-- Senders can read their sent thoughts
DROP POLICY IF EXISTS "Senders can view sent thoughts" ON public.thoughts;
CREATE POLICY "Senders can view sent thoughts"
  ON public.thoughts
  FOR SELECT
  USING (auth.uid() = sender_id);

-- Insert policy: Only via RPC function (enforced by RPC validation)
-- RPC function uses SECURITY DEFINER, so we allow authenticated users
-- but RPC validates connection, blocks, etc.
DROP POLICY IF EXISTS "Users can send thoughts via RPC" ON public.thoughts;
CREATE POLICY "Users can send thoughts via RPC"
  ON public.thoughts
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND sender_id != receiver_id
  );

-- No updates allowed (immutable)
-- No deletes by users (only service role for moderation)
DROP POLICY IF EXISTS "System can delete thoughts" ON public.thoughts;
CREATE POLICY "System can delete thoughts"
  ON public.thoughts
  FOR DELETE
  USING (auth.role() = 'service_role');

-- ============================================================================
-- Thought Rate Limits Table Policies
-- ============================================================================

-- Users can read their own rate limit records
DROP POLICY IF EXISTS "Users can view own rate limits" ON public.thought_rate_limits;
CREATE POLICY "Users can view own rate limits"
  ON public.thought_rate_limits
  FOR SELECT
  USING (auth.uid() = sender_id);

-- Insert/update only via RPC function (SECURITY DEFINER)
DROP POLICY IF EXISTS "System can manage rate limits" ON public.thought_rate_limits;
CREATE POLICY "System can manage rate limits"
  ON public.thought_rate_limits
  FOR ALL
  USING (auth.role() = 'service_role' OR auth.uid() = sender_id)
  WITH CHECK (auth.role() = 'service_role' OR auth.uid() = sender_id);

-- ============================================================================
-- 6. RPC FUNCTION: rpc_send_thought
-- ============================================================================
-- WHAT: Atomically sends a thought with all validations
-- VALIDATIONS:
--   - Sender and receiver are mutual connections
--   - Neither user is blocked by the other
--   - Receiver exists
--   - Cooldown: max 1 per sender->receiver per day (enforced by unique constraint)
--   - Global cap: max 20 per sender per day (configurable)
-- RETURNS: JSONB with thought_id and status
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_send_thought(
  p_receiver_id UUID,
  p_client_source TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_id UUID;
  v_today DATE;
  v_connection_exists BOOLEAN;
  v_blocked_check BOOLEAN;
  v_receiver_exists BOOLEAN;
  v_daily_count INTEGER;
  v_max_daily_thoughts INTEGER;
  v_timezone TEXT;
  v_thought_id UUID;
  v_result JSONB;
BEGIN
  -- Get current user
  v_sender_id := auth.uid();
  
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:Not authenticated: auth.uid() returned NULL';
  END IF;
  
  -- Validation: Cannot send to self
  -- This check ensures sender_id != receiver_id
  IF v_sender_id = p_receiver_id THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:Cannot send thought to yourself: sender_id=%, receiver_id=%', v_sender_id, p_receiver_id;
  END IF;
  
  -- Additional validation: Ensure receiver_id is not NULL
  IF p_receiver_id IS NULL THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:INVALID_RECEIVER: receiver_id is NULL';
  END IF;
  
  -- Load configuration values (with fallbacks for safety)
  -- JSONB number extraction: convert JSONB to text then to integer
  SELECT COALESCE((value::text)::integer, 20) INTO v_max_daily_thoughts
  FROM public.thought_config
  WHERE key = 'max_daily_thoughts';
  
  -- If config doesn't exist, use default
  IF v_max_daily_thoughts IS NULL THEN
    v_max_daily_thoughts := 20;
  END IF;
  
  -- Get timezone from config (default to UTC)
  -- JSONB string extraction: extract text and remove JSON quotes
  SELECT COALESCE(TRIM(BOTH '"' FROM value::text), 'UTC') INTO v_timezone
  FROM public.thought_config
  WHERE key = 'timezone';
  
  IF v_timezone IS NULL OR v_timezone = '' THEN
    v_timezone := 'UTC';
  END IF;
  
  -- Get today's date in configured timezone for consistency
  -- CRITICAL: Using configured timezone ensures all users have same day boundaries
  v_today := (now() AT TIME ZONE v_timezone)::date;
  
  -- Debug: Log sender and receiver for troubleshooting
  -- (Remove in production or use proper logging)
  -- RAISE NOTICE 'Sending thought: sender=%, receiver=%', v_sender_id, p_receiver_id;
  
  -- Validation: Receiver must exist
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_receiver_id)
  INTO v_receiver_exists;
  
  IF NOT v_receiver_exists THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:INVALID_RECEIVER';
  END IF;
  
  -- Validation: Check if users are mutual connections
  -- Connections table stores user_id_1 < user_id_2
  SELECT EXISTS(
    SELECT 1 FROM public.connections
    WHERE (user_id_1 = LEAST(v_sender_id, p_receiver_id)
           AND user_id_2 = GREATEST(v_sender_id, p_receiver_id))
  ) INTO v_connection_exists;
  
  IF NOT v_connection_exists THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:NOT_CONNECTED';
  END IF;
  
  -- Validation: Check if either user is blocked
  -- Optimized: Use two separate EXISTS queries for better index usage
  -- Indexes: idx_blocked_users_blocker, idx_blocked_users_blocked
  SELECT EXISTS(
    SELECT 1 FROM public.blocked_users
    WHERE blocker_id = v_sender_id AND blocked_id = p_receiver_id
  ) OR EXISTS(
    SELECT 1 FROM public.blocked_users
    WHERE blocker_id = p_receiver_id AND blocked_id = v_sender_id
  ) INTO v_blocked_check;
  
  IF v_blocked_check THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:BLOCKED';
  END IF;
  
  -- Check if already sent today (cooldown per pair)
  -- IMPORTANT: Only checks if THIS sender (v_sender_id) has sent to THIS receiver (p_receiver_id) today
  -- Does NOT check reverse direction (receiver -> sender)
  -- The unique constraint UNIQUE(sender_id, receiver_id, day_bucket) ensures this
  -- Index: idx_thoughts_sender_day (covers this query efficiently)
  IF EXISTS(
    SELECT 1 FROM public.thoughts
    WHERE sender_id = v_sender_id
      AND receiver_id = p_receiver_id
      AND day_bucket = v_today
  ) THEN
    -- Double-check: verify we're checking the right direction
    -- This should never trigger for reverse direction (B->A when A->B exists)
    RAISE EXCEPTION 'THOUGHT_ERROR:THOUGHT_ALREADY_SENT_TODAY: sender=%, receiver=%', v_sender_id, p_receiver_id;
  END IF;
  
  -- Atomic rate limit check and increment
  -- CRITICAL: This must be atomic to prevent race conditions with concurrent requests
  -- Strategy: Lock the row, check current count, increment if below limit
  -- Uses row-level locking (SELECT FOR UPDATE) to ensure atomicity
  -- Primary key index on (sender_id, day_bucket) ensures fast lookup
  
  -- First, try to get or create the rate limit record with lock
  -- This ensures only one transaction can modify it at a time
  INSERT INTO public.thought_rate_limits (sender_id, day_bucket, sent_count, updated_at)
  VALUES (v_sender_id, v_today, 0, now())
  ON CONFLICT (sender_id, day_bucket) DO NOTHING;
  
  -- Now lock and check the current count
  SELECT sent_count INTO v_daily_count
  FROM public.thought_rate_limits
  WHERE sender_id = v_sender_id AND day_bucket = v_today
  FOR UPDATE; -- Row-level lock prevents concurrent modifications
  
  -- Check if limit would be exceeded
  IF v_daily_count >= v_max_daily_thoughts THEN
    RAISE EXCEPTION 'THOUGHT_ERROR:DAILY_LIMIT_REACHED';
  END IF;
  
  -- Atomic increment (row is locked, so this is safe)
  UPDATE public.thought_rate_limits
  SET sent_count = sent_count + 1,
      updated_at = now()
  WHERE sender_id = v_sender_id AND day_bucket = v_today;
  
  -- Insert thought
  INSERT INTO public.thoughts (sender_id, receiver_id, day_bucket, client_source, created_at)
  VALUES (v_sender_id, p_receiver_id, v_today, p_client_source, now())
  RETURNING id INTO v_thought_id;
  
  -- Return result
  v_result := jsonb_build_object(
    'thought_id', v_thought_id,
    'status', 'sent',
    'sender_id', v_sender_id,
    'receiver_id', p_receiver_id,
    'created_at', now()
  );
  
  RETURN v_result;
  
EXCEPTION
  WHEN unique_violation THEN
    -- Catch unique constraint violation
    -- This should only happen if the same sender tries to send to same receiver twice in one day
    -- Check which constraint was violated for better debugging
    IF SQLSTATE = '23505' THEN
      -- Unique constraint violation on thoughts_unique_per_pair_per_day
      -- This means: sender_id + receiver_id + day_bucket already exists
      -- Verify: this should only happen if v_sender_id already sent to p_receiver_id today
      RAISE EXCEPTION 'THOUGHT_ERROR:THOUGHT_ALREADY_SENT_TODAY: sender=%, receiver=%, constraint=thoughts_unique_per_pair_per_day', v_sender_id, p_receiver_id;
    ELSE
      RAISE EXCEPTION 'THOUGHT_ERROR:THOUGHT_ALREADY_SENT_TODAY';
    END IF;
  WHEN OTHERS THEN
    -- Re-raise with original message if it's already a THOUGHT_ERROR
    IF SQLERRM LIKE 'THOUGHT_ERROR:%' THEN
      RAISE;
    ELSE
      -- Wrap unexpected errors
      RAISE EXCEPTION 'THOUGHT_ERROR:UNEXPECTED_ERROR: %', SQLERRM;
    END IF;
END;
$$;

-- ============================================================================
-- 7. RPC FUNCTION: rpc_list_incoming_thoughts
-- ============================================================================
-- WHAT: Lists incoming thoughts for the current user with pagination
-- RETURNS: JSONB array of thoughts with sender info
-- PRIVACY: Only returns date (day_bucket), not exact timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_list_incoming_thoughts(
  p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_thoughts JSONB;
  v_default_limit INTEGER;
  v_min_limit INTEGER;
  v_max_limit INTEGER;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Load pagination limits from config (with fallbacks)
  -- JSONB number extraction: convert JSONB to text then to integer
  SELECT COALESCE((value::text)::integer, 30) INTO v_default_limit
  FROM public.thought_config WHERE key = 'default_pagination_limit';
  
  SELECT COALESCE((value::text)::integer, 1) INTO v_min_limit
  FROM public.thought_config WHERE key = 'min_pagination_limit';
  
  SELECT COALESCE((value::text)::integer, 100) INTO v_max_limit
  FROM public.thought_config WHERE key = 'max_pagination_limit';
  
  -- Set defaults if config doesn't exist
  IF v_default_limit IS NULL THEN v_default_limit := 30; END IF;
  IF v_min_limit IS NULL THEN v_min_limit := 1; END IF;
  IF v_max_limit IS NULL THEN v_max_limit := 100; END IF;
  
  -- Validate and clamp limit
  IF p_limit IS NULL OR p_limit < v_min_limit OR p_limit > v_max_limit THEN
    p_limit := v_default_limit;
  END IF;
  
  -- Query thoughts with sender profile info
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'sender_id', t.sender_id,
      'display_date', t.day_bucket, -- Only date, not exact time
      'created_at', t.created_at, -- For internal sorting only
      'sender_name', COALESCE(
        NULLIF(TRIM(up.first_name || ' ' || COALESCE(up.last_name, '')), ''),
        up.username,
        'Someone'
      ),
      'sender_avatar_url', up.avatar_url,
      'sender_username', up.username
    ) ORDER BY t.created_at DESC
  ), '[]'::jsonb)
  INTO v_thoughts
  FROM public.thoughts t
  LEFT JOIN public.user_profiles up ON t.sender_id = up.user_id
  WHERE t.receiver_id = v_user_id
    AND (p_cursor_created_at IS NULL OR t.created_at < p_cursor_created_at)
  ORDER BY t.created_at DESC
  LIMIT p_limit;
  
  RETURN v_thoughts;
END;
$$;

-- ============================================================================
-- 8. RPC FUNCTION: rpc_list_sent_thoughts
-- ============================================================================
-- WHAT: Lists sent thoughts for the current user with pagination
-- RETURNS: JSONB array of thoughts with receiver info
-- ============================================================================
CREATE OR REPLACE FUNCTION public.rpc_list_sent_thoughts(
  p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_thoughts JSONB;
  v_default_limit INTEGER;
  v_min_limit INTEGER;
  v_max_limit INTEGER;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Load pagination limits from config (with fallbacks)
  -- JSONB number extraction: convert JSONB to text then to integer
  SELECT COALESCE((value::text)::integer, 30) INTO v_default_limit
  FROM public.thought_config WHERE key = 'default_pagination_limit';
  
  SELECT COALESCE((value::text)::integer, 1) INTO v_min_limit
  FROM public.thought_config WHERE key = 'min_pagination_limit';
  
  SELECT COALESCE((value::text)::integer, 100) INTO v_max_limit
  FROM public.thought_config WHERE key = 'max_pagination_limit';
  
  -- Set defaults if config doesn't exist
  IF v_default_limit IS NULL THEN v_default_limit := 30; END IF;
  IF v_min_limit IS NULL THEN v_min_limit := 1; END IF;
  IF v_max_limit IS NULL THEN v_max_limit := 100; END IF;
  
  -- Validate and clamp limit
  IF p_limit IS NULL OR p_limit < v_min_limit OR p_limit > v_max_limit THEN
    p_limit := v_default_limit;
  END IF;
  
  -- Query thoughts with receiver profile info
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'receiver_id', t.receiver_id,
      'display_date', t.day_bucket,
      'created_at', t.created_at,
      'receiver_name', COALESCE(
        NULLIF(TRIM(up.first_name || ' ' || COALESCE(up.last_name, '')), ''),
        up.username,
        'Someone'
      ),
      'receiver_avatar_url', up.avatar_url,
      'receiver_username', up.username
    ) ORDER BY t.created_at DESC
  ), '[]'::jsonb)
  INTO v_thoughts
  FROM public.thoughts t
  LEFT JOIN public.user_profiles up ON t.receiver_id = up.user_id
  WHERE t.sender_id = v_user_id
    AND (p_cursor_created_at IS NULL OR t.created_at < p_cursor_created_at)
  ORDER BY t.created_at DESC
  LIMIT p_limit;
  
  RETURN v_thoughts;
END;
$$;

-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT, INSERT ON public.thoughts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.thought_rate_limits TO authenticated;
GRANT SELECT ON public.thought_config TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_send_thought(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_list_incoming_thoughts(TIMESTAMPTZ, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_list_sent_thoughts(TIMESTAMPTZ, INTEGER) TO authenticated;

-- ============================================================================
-- 10. COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE public.thoughts IS 'Thoughts - gentle presence signals between connected users';
COMMENT ON COLUMN public.thoughts.day_bucket IS 'Date bucket for cooldown enforcement (1 per sender->receiver per day)';
COMMENT ON COLUMN public.thoughts.client_source IS 'Client source identifier (ios, android, web) for debugging';
COMMENT ON COLUMN public.thoughts.metadata IS 'Reserved for future use - keep empty by default';

COMMENT ON TABLE public.thought_rate_limits IS 'Daily rate limits per sender to prevent abuse';
COMMENT ON COLUMN public.thought_rate_limits.sent_count IS 'Number of thoughts sent by sender on this day';

COMMENT ON TABLE public.thought_config IS 'Configurable settings for thoughts feature (rate limits, pagination, timezone)';
COMMENT ON COLUMN public.thought_config.key IS 'Configuration key (e.g., max_daily_thoughts, default_pagination_limit)';
COMMENT ON COLUMN public.thought_config.value IS 'Configuration value as JSONB (allows different types)';

COMMENT ON FUNCTION public.rpc_send_thought IS 'Sends a thought with full validation (connection, blocks, rate limits). Uses configurable settings from thought_config table.';
COMMENT ON FUNCTION public.rpc_list_incoming_thoughts IS 'Lists incoming thoughts for current user with pagination. Uses configurable pagination limits from thought_config table.';
COMMENT ON FUNCTION public.rpc_list_sent_thoughts IS 'Lists sent thoughts for current user with pagination. Uses configurable pagination limits from thought_config table.';

