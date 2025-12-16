-- ============================================================================
-- Connections Functions Migration
-- RPC functions for connection request management
-- ============================================================================

-- ============================================================================
-- FUNCTION: send_connection_request
-- ============================================================================
-- WHAT: Sends a connection request from one user to another
-- WHY: Centralizes validation logic (blocked users, existing connections, cooldowns)
--      Prevents duplicate requests and enforces abuse prevention rules
-- VALIDATIONS:
--   - Cannot send to self
--   - Check if users are already connected
--   - Check if request already exists (pending)
--   - Check if either user is blocked
--   - Enforce cooldown (7 days after decline)
--   - Rate limiting (max 5 requests per day)
-- RETURNS: The created connection request with profile info
-- ============================================================================
CREATE OR REPLACE FUNCTION public.send_connection_request(
  p_to_user_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_from_user_id UUID;
  v_request_id UUID;
  v_existing_request RECORD;
  v_existing_connection RECORD;
  v_blocked_check BOOLEAN;
  v_recent_decline RECORD;
  v_daily_count INTEGER;
  v_result JSONB;
BEGIN
  -- Get current user
  v_from_user_id := auth.uid();
  
  IF v_from_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validation: Cannot send to self
  IF v_from_user_id = p_to_user_id THEN
    RAISE EXCEPTION 'Cannot send connection request to yourself';
  END IF;
  
  -- Validation: Check if users are already connected
  SELECT * INTO v_existing_connection
  FROM public.connections
  WHERE (user_id_1 = v_from_user_id AND user_id_2 = p_to_user_id)
     OR (user_id_1 = p_to_user_id AND user_id_2 = v_from_user_id);
  
  IF v_existing_connection IS NOT NULL THEN
    RAISE EXCEPTION 'Users are already connected';
  END IF;
  
  -- Validation: Check if blocked (either direction)
  SELECT EXISTS(
    SELECT 1 FROM public.blocked_users
    WHERE (blocker_id = v_from_user_id AND blocked_id = p_to_user_id)
       OR (blocker_id = p_to_user_id AND blocked_id = v_from_user_id)
  ) INTO v_blocked_check;
  
  IF v_blocked_check THEN
    RAISE EXCEPTION 'Cannot send request: user is blocked';
  END IF;
  
  -- Validation: Check for existing pending request (either direction)
  SELECT * INTO v_existing_request
  FROM public.connection_requests
  WHERE (
    (from_user_id = v_from_user_id AND to_user_id = p_to_user_id)
    OR (from_user_id = p_to_user_id AND to_user_id = v_from_user_id)
  )
  AND status = 'pending';
  
  IF v_existing_request IS NOT NULL THEN
    IF v_existing_request.from_user_id = v_from_user_id THEN
      RAISE EXCEPTION 'Request already sent';
    ELSE
      RAISE EXCEPTION 'You have a pending request from this user';
    END IF;
  END IF;
  
  -- Validation: Check cooldown (7 days after decline)
  SELECT * INTO v_recent_decline
  FROM public.connection_requests
  WHERE from_user_id = v_from_user_id
    AND to_user_id = p_to_user_id
    AND status = 'declined'
    AND acted_at > NOW() - INTERVAL '7 days'
  ORDER BY acted_at DESC
  LIMIT 1;
  
  IF v_recent_decline IS NOT NULL THEN
    RAISE EXCEPTION 'cooldown_active: Please wait 7 days before sending another request';
  END IF;
  
  -- Validation: Rate limiting (max 5 requests per day)
  SELECT COUNT(*) INTO v_daily_count
  FROM public.connection_requests
  WHERE from_user_id = v_from_user_id
    AND created_at > NOW() - INTERVAL '1 day';
  
  IF v_daily_count >= 5 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 5 connection requests per day';
  END IF;
  
  -- Create the request
  INSERT INTO public.connection_requests (from_user_id, to_user_id, message, status)
  VALUES (v_from_user_id, p_to_user_id, p_message, 'pending')
  RETURNING id INTO v_request_id;
  
  -- Return the request with profile info
  SELECT jsonb_build_object(
    'id', cr.id,
    'from_user_id', cr.from_user_id,
    'to_user_id', cr.to_user_id,
    'status', cr.status,
    'message', cr.message,
    'created_at', cr.created_at,
    'updated_at', cr.updated_at,
    'from_user_profile', jsonb_build_object(
      'user_id', up_from.user_id,
      'display_name', COALESCE(
        NULLIF(TRIM(up_from.first_name || ' ' || up_from.last_name), ''),
        up_from.first_name,
        up_from.last_name,
        up_from.username,
        'User'
      ),
      'avatar_url', up_from.avatar_url,
      'username', up_from.username
    ),
    'to_user_profile', jsonb_build_object(
      'user_id', up_to.user_id,
      'display_name', COALESCE(
        NULLIF(TRIM(up_to.first_name || ' ' || up_to.last_name), ''),
        up_to.first_name,
        up_to.last_name,
        up_to.username,
        'User'
      ),
      'avatar_url', up_to.avatar_url,
      'username', up_to.username
    )
  ) INTO v_result
  FROM public.connection_requests cr
  LEFT JOIN public.user_profiles up_from ON cr.from_user_id = up_from.user_id
  LEFT JOIN public.user_profiles up_to ON cr.to_user_id = up_to.user_id
  WHERE cr.id = v_request_id;
  
  RETURN v_result;
END;
$$;

-- ============================================================================
-- FUNCTION: respond_to_request
-- ============================================================================
-- WHAT: Responds to a connection request (accept or decline)
-- WHY: Centralizes response logic and creates connection on accept
--      Only receiver can respond
-- VALIDATIONS:
--   - Only receiver can respond
--   - Request must be pending
--   - Action must be 'accept' or 'decline'
-- ACTIONS:
--   - Accept: Creates connection record, updates request status
--   - Decline: Updates request status with optional reason
-- RETURNS: Updated request with connection info if accepted
-- ============================================================================
CREATE OR REPLACE FUNCTION public.respond_to_request(
  p_request_id UUID,
  p_action TEXT,
  p_declined_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_user_id UUID;
  v_request RECORD;
  v_user_id_1 UUID;
  v_user_id_2 UUID;
  v_connection RECORD;
  v_result JSONB;
BEGIN
  -- Get current user
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate action
  IF p_action NOT IN ('accept', 'decline') THEN
    RAISE EXCEPTION 'Invalid action: must be accept or decline';
  END IF;
  
  -- Get the request
  SELECT * INTO v_request
  FROM public.connection_requests
  WHERE id = p_request_id;
  
  IF v_request IS NULL THEN
    RAISE EXCEPTION 'Connection request not found';
  END IF;
  
  -- Validation: Only receiver can respond
  IF v_request.to_user_id != v_current_user_id THEN
    RAISE EXCEPTION 'Only the receiver can respond to this request';
  END IF;
  
  -- Validation: Request must be pending
  IF v_request.status != 'pending' THEN
    RAISE EXCEPTION 'Request is not pending';
  END IF;
  
  -- Handle accept
  IF p_action = 'accept' THEN
    -- Sort user IDs for consistent storage
    v_user_id_1 := LEAST(v_request.from_user_id, v_request.to_user_id);
    v_user_id_2 := GREATEST(v_request.from_user_id, v_request.to_user_id);
    
    -- Check if connection already exists (race condition protection)
    SELECT * INTO v_connection
    FROM public.connections
    WHERE user_id_1 = v_user_id_1 AND user_id_2 = v_user_id_2;
    
    -- Create connection if it doesn't exist
    IF v_connection IS NULL THEN
      INSERT INTO public.connections (user_id_1, user_id_2, connected_at)
      VALUES (v_user_id_1, v_user_id_2, NOW())
      ON CONFLICT DO NOTHING;
    END IF;
    
    -- Update request status
    UPDATE public.connection_requests
    SET status = 'accepted',
        acted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_request_id;
    
  -- Handle decline
  ELSIF p_action = 'decline' THEN
    UPDATE public.connection_requests
    SET status = 'declined',
        declined_reason = p_declined_reason,
        acted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_request_id;
  END IF;
  
  -- Return updated request with profile info
  SELECT jsonb_build_object(
    'id', cr.id,
    'from_user_id', cr.from_user_id,
    'to_user_id', cr.to_user_id,
    'status', cr.status,
    'message', cr.message,
    'declined_reason', cr.declined_reason,
    'acted_at', cr.acted_at,
    'created_at', cr.created_at,
    'updated_at', cr.updated_at,
    'from_user_profile', jsonb_build_object(
      'user_id', up_from.user_id,
      'display_name', COALESCE(
        NULLIF(TRIM(up_from.first_name || ' ' || up_from.last_name), ''),
        up_from.first_name,
        up_from.last_name,
        up_from.username,
        'User'
      ),
      'avatar_url', up_from.avatar_url,
      'username', up_from.username
    ),
    'to_user_profile', jsonb_build_object(
      'user_id', up_to.user_id,
      'display_name', COALESCE(
        NULLIF(TRIM(up_to.first_name || ' ' || up_to.last_name), ''),
        up_to.first_name,
        up_to.last_name,
        up_to.username,
        'User'
      ),
      'avatar_url', up_to.avatar_url,
      'username', up_to.username
    ),
    'connection', CASE
      WHEN cr.status = 'accepted' THEN (
        SELECT jsonb_build_object(
          'user_id_1', c.user_id_1,
          'user_id_2', c.user_id_2,
          'connected_at', c.connected_at
        )
        FROM public.connections c
        WHERE (c.user_id_1 = LEAST(cr.from_user_id, cr.to_user_id)
           AND c.user_id_2 = GREATEST(cr.from_user_id, cr.to_user_id))
        LIMIT 1
      )
      ELSE NULL
    END
  ) INTO v_result
  FROM public.connection_requests cr
  LEFT JOIN public.user_profiles up_from ON cr.from_user_id = up_from.user_id
  LEFT JOIN public.user_profiles up_to ON cr.to_user_id = up_to.user_id
  WHERE cr.id = p_request_id;
  
  RETURN v_result;
END;
$$;

-- ============================================================================
-- FUNCTION: get_pending_requests
-- ============================================================================
-- WHAT: Gets all pending connection requests for the current user
-- WHY: Returns both incoming and outgoing requests with profile info
-- RETURNS: JSON with incoming and outgoing arrays
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_pending_requests()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_user_id UUID;
  v_result JSONB;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  SELECT jsonb_build_object(
    'incoming', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', cr.id,
          'from_user_id', cr.from_user_id,
          'to_user_id', cr.to_user_id,
          'status', cr.status,
          'message', cr.message,
          'created_at', cr.created_at,
          'updated_at', cr.updated_at,
          'from_user_profile', jsonb_build_object(
            'user_id', up.user_id,
            'display_name', COALESCE(
              NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
              up.first_name,
              up.last_name,
              up.username,
              'User'
            ),
            'avatar_url', up.avatar_url,
            'username', up.username
          )
        )
        ORDER BY cr.created_at DESC
      )
      FROM public.connection_requests cr
      LEFT JOIN public.user_profiles up ON cr.from_user_id = up.user_id
      WHERE cr.to_user_id = v_current_user_id
        AND cr.status = 'pending'
    ),
    'outgoing', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', cr.id,
          'from_user_id', cr.from_user_id,
          'to_user_id', cr.to_user_id,
          'status', cr.status,
          'message', cr.message,
          'created_at', cr.created_at,
          'updated_at', cr.updated_at,
          'to_user_profile', jsonb_build_object(
            'user_id', up.user_id,
            'display_name', COALESCE(
              NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
              up.first_name,
              up.last_name,
              up.username,
              'User'
            ),
            'avatar_url', up.avatar_url,
            'username', up.username
          )
        )
        ORDER BY cr.created_at DESC
      )
      FROM public.connection_requests cr
      LEFT JOIN public.user_profiles up ON cr.to_user_id = up.user_id
      WHERE cr.from_user_id = v_current_user_id
        AND cr.status = 'pending'
    )
  ) INTO v_result;
  
  -- Handle NULL arrays
  IF v_result->'incoming' IS NULL THEN
    v_result := jsonb_set(v_result, '{incoming}', '[]'::jsonb);
  END IF;
  
  IF v_result->'outgoing' IS NULL THEN
    v_result := jsonb_set(v_result, '{outgoing}', '[]'::jsonb);
  END IF;
  
  RETURN v_result;
END;
$$;

-- ============================================================================
-- FUNCTION: get_connections
-- ============================================================================
-- WHAT: Gets all mutual connections for the current user
-- WHY: Returns list of connected users with profile info
-- RETURNS: Array of connections with user profiles
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_connections()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_user_id UUID;
  v_result JSONB;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  SELECT jsonb_agg(
    jsonb_build_object(
      'user_id_1', c.user_id_1,
      'user_id_2', c.user_id_2,
      'connected_at', c.connected_at,
      'other_user_id', CASE
        WHEN c.user_id_1 = v_current_user_id THEN c.user_id_2
        ELSE c.user_id_1
      END,
      'other_user_profile', CASE
        WHEN c.user_id_1 = v_current_user_id THEN (
          SELECT jsonb_build_object(
            'user_id', up.user_id,
            'display_name', COALESCE(
              NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
              up.first_name,
              up.last_name,
              up.username,
              'User'
            ),
            'avatar_url', up.avatar_url,
            'username', up.username
          )
          FROM public.user_profiles up
          WHERE up.user_id = c.user_id_2
        )
        ELSE (
          SELECT jsonb_build_object(
            'user_id', up.user_id,
            'display_name', COALESCE(
              NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
              up.first_name,
              up.last_name,
              up.username,
              'User'
            ),
            'avatar_url', up.avatar_url,
            'username', up.username
          )
          FROM public.user_profiles up
          WHERE up.user_id = c.user_id_1
        )
      END
    )
    ORDER BY c.connected_at DESC
  ) INTO v_result
  FROM public.connections c
  WHERE c.user_id_1 = v_current_user_id OR c.user_id_2 = v_current_user_id;
  
  -- Handle NULL result
  IF v_result IS NULL THEN
    v_result := '[]'::jsonb;
  END IF;
  
  RETURN v_result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.send_connection_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_request(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_connections() TO authenticated;
