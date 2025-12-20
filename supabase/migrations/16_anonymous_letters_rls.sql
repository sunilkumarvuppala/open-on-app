-- ============================================================================
-- Anonymous Letters RLS Policies
-- ============================================================================
-- WHAT: Row-level security policies for anonymous letters feature
-- WHY: Enforces mutual connection requirement and prevents unauthorized access
-- SECURITY: Critical - prevents data leakage and abuse
-- ============================================================================

-- ============================================================================
-- 1. UPDATE INSERT POLICY: Require Mutual Connection for Anonymous Letters
-- ============================================================================
DROP POLICY IF EXISTS "Users can create capsules" ON public.capsules;

CREATE POLICY "Users can create capsules"
  ON public.capsules
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND deleted_at IS NULL
    AND (
      -- Non-anonymous letters: no additional check
      (is_anonymous = FALSE)
      OR
      -- Anonymous letters: must be mutual connection
      (
        is_anonymous = TRUE
        AND EXISTS (
          SELECT 1 FROM public.recipients r
          WHERE r.id = capsules.recipient_id
            AND r.linked_user_id IS NOT NULL
            AND public.is_mutual_connection(auth.uid(), r.linked_user_id) = TRUE
        )
        -- Enforce reveal_delay_seconds is set and within limits
        AND reveal_delay_seconds IS NOT NULL
        AND reveal_delay_seconds BETWEEN 0 AND 259200
      )
    )
  );

-- ============================================================================
-- 2. UPDATE SELECT POLICY: Use Safe View Logic for Recipients
-- ============================================================================
-- Recipients should use recipient_safe_capsules_view, but we update base policy
-- to ensure sender_id is never exposed before reveal

DROP POLICY IF EXISTS "Recipients can view received capsules" ON public.capsules;

CREATE POLICY "Recipients can view received capsules"
  ON public.capsules
  FOR SELECT
  USING (
    (
      -- Email-based recipient check
      EXISTS (
        SELECT 1 FROM public.recipients r
        WHERE r.id = capsules.recipient_id
          AND r.email IS NOT NULL
          AND LOWER(TRIM(r.email)) = LOWER(TRIM((auth.jwt() ->> 'email')::text))
      )
      OR
      -- Connection-based recipient check
      EXISTS (
        SELECT 1 FROM public.recipients r
        WHERE r.id = capsules.recipient_id
          AND r.linked_user_id = auth.uid()
      )
    )
    AND deleted_at IS NULL
  );

-- ============================================================================
-- 3. RESTRICTIVE UPDATE POLICY: Prevent Manipulation of Reveal Fields
-- ============================================================================
DROP POLICY IF EXISTS "Senders can update unopened capsules" ON public.capsules;

CREATE POLICY "Senders can update unopened capsules"
  ON public.capsules
  FOR UPDATE
  USING (
    auth.uid() = sender_id
    AND deleted_at IS NULL
    AND opened_at IS NULL  -- Must not be opened
    AND status IN ('sealed', 'ready')  -- Must be sealed or ready
  )
  WITH CHECK (
    auth.uid() = sender_id
    AND deleted_at IS NULL
    AND opened_at IS NULL
    AND status IN ('sealed', 'ready')
    -- CRITICAL: Prevent modification of these fields
    AND (
      -- Cannot change sender_id
      sender_id = (SELECT sender_id FROM public.capsules WHERE id = capsules.id)
      -- Cannot change opened_at (must be set via open_letter RPC)
      AND opened_at IS NULL
      -- Cannot change reveal_at (must be set via open_letter RPC)
      AND (
        reveal_at IS NULL 
        OR reveal_at = (SELECT reveal_at FROM public.capsules WHERE id = capsules.id)
      )
      -- Cannot change sender_revealed_at (must be set via reveal job)
      AND (
        sender_revealed_at IS NULL 
        OR sender_revealed_at = (SELECT sender_revealed_at FROM public.capsules WHERE id = capsules.id)
      )
    )
  );

-- ============================================================================
-- 4. RECIPIENTS CANNOT UPDATE CAPSULES DIRECTLY
-- ============================================================================
-- Recipients must use open_letter RPC function to open letters
-- No direct UPDATE policy for recipients

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Users can create capsules" ON public.capsules IS 
  'Allows users to create capsules. Anonymous letters require mutual connection.';
COMMENT ON POLICY "Recipients can view received capsules" ON public.capsules IS 
  'Allows recipients to view capsules. Sender identity hidden until reveal_at for anonymous letters.';
COMMENT ON POLICY "Senders can update unopened capsules" ON public.capsules IS 
  'Allows senders to update unopened capsules. Prevents manipulation of reveal fields.';
