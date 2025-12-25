-- ============================================================================
-- Anonymous Identity Hints Feature Migration
-- ============================================================================
-- WHAT: Adds support for progressive anonymous identity hints
-- WHY: Allows senders to add optional hints that reveal over time before identity reveal
-- SCOPE: Applies ONLY to anonymous letters, max 3 hints, max 60 chars each
-- SECURITY: Hints are only visible to recipients, backend determines eligibility
-- ============================================================================

-- ============================================================================
-- 1. CREATE ANONYMOUS_IDENTITY_HINTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.anonymous_identity_hints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL UNIQUE REFERENCES public.capsules(id) ON DELETE CASCADE,
  hint_1 TEXT,
  hint_2 TEXT,
  hint_3 TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT anonymous_identity_hints_hint_1_length CHECK (
    hint_1 IS NULL OR LENGTH(hint_1) <= 60
  ),
  CONSTRAINT anonymous_identity_hints_hint_2_length CHECK (
    hint_2 IS NULL OR LENGTH(hint_2) <= 60
  ),
  CONSTRAINT anonymous_identity_hints_hint_3_length CHECK (
    hint_3 IS NULL OR LENGTH(hint_3) <= 60
  )
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_anonymous_identity_hints_letter_id 
  ON public.anonymous_identity_hints(letter_id);

-- ============================================================================
-- 3. RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.anonymous_identity_hints ENABLE ROW LEVEL SECURITY;

-- Policy: Senders can insert hints for their own anonymous letters
DROP POLICY IF EXISTS "Senders can insert hints for their own anonymous letters" ON public.anonymous_identity_hints;
CREATE POLICY "Senders can insert hints for their own anonymous letters"
  ON public.anonymous_identity_hints
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.capsules
      WHERE capsules.id = letter_id
      AND capsules.sender_id = auth.uid()
      AND capsules.is_anonymous = TRUE
    )
  );

-- Policy: Recipients can view hints (backend will determine eligibility)
DROP POLICY IF EXISTS "Recipients can view hints for received anonymous letters" ON public.anonymous_identity_hints;
CREATE POLICY "Recipients can view hints for received anonymous letters"
  ON public.anonymous_identity_hints
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.capsules c
      INNER JOIN public.recipients r ON r.id = c.recipient_id
      WHERE c.id = letter_id
      AND c.is_anonymous = TRUE
      AND (
        -- Email-based recipient
        (r.email IS NOT NULL AND r.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        OR
        -- Connection-based recipient (linked_user_id matches)
        (r.linked_user_id = auth.uid())
      )
    )
  );

-- Policy: Senders can view hints for their own letters
DROP POLICY IF EXISTS "Senders can view hints for their own letters" ON public.anonymous_identity_hints;
CREATE POLICY "Senders can view hints for their own letters"
  ON public.anonymous_identity_hints
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.capsules
      WHERE capsules.id = letter_id
      AND capsules.sender_id = auth.uid()
    )
  );

-- Policy: No updates or deletes (hints are immutable once created)
-- This ensures hints cannot be modified after letter creation

-- ============================================================================
-- 4. FUNCTION: Get current eligible hint
-- ============================================================================
-- WHAT: Determines which hint (if any) should be shown based on number of hints
-- WHY: Centralizes hint eligibility logic at database level
-- RETURNS: hint_text (nullable), hint_index (1, 2, or 3, nullable)
-- 
-- HINT DISPLAY RULES (based on number of hints provided):
--   - 1 hint:  Show at 50% elapsed
--   - 2 hints: Show at 35% and 70% elapsed
--   - 3 hints: Show at 30%, 50%, and 85% elapsed
-- ============================================================================
DROP FUNCTION IF EXISTS public.get_current_anonymous_hint(UUID);
CREATE OR REPLACE FUNCTION public.get_current_anonymous_hint(letter_id_param UUID)
RETURNS TABLE (
  hint_text TEXT,
  hint_index INTEGER
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_capsule RECORD;
  v_hints RECORD;
  v_opened_at TIMESTAMPTZ;
  v_reveal_at TIMESTAMPTZ;
  v_now TIMESTAMPTZ := NOW();
  v_total_duration INTERVAL;
  v_elapsed INTERVAL;
  v_remaining INTERVAL;
  v_elapsed_ratio NUMERIC;
  v_hint_1 TEXT;
  v_hint_2 TEXT;
  v_hint_3 TEXT;
  v_available_hints TEXT[];
  v_hint_count INTEGER;
  v_eligible_hint_index INTEGER;
  v_eligible_hint_text TEXT;
BEGIN
  -- Get capsule and hints
  SELECT 
    c.opened_at,
    c.reveal_at,
    c.is_anonymous,
    c.sender_revealed_at
  INTO v_capsule
  FROM public.capsules c
  WHERE c.id = letter_id_param;
  
  -- If capsule doesn't exist, not anonymous, not opened, or already revealed, return nothing
  IF v_capsule IS NULL 
     OR NOT v_capsule.is_anonymous 
     OR v_capsule.opened_at IS NULL 
     OR v_capsule.reveal_at IS NULL
     OR v_capsule.sender_revealed_at IS NOT NULL THEN
    RETURN;
  END IF;
  
  -- Get hints
  SELECT hint_1, hint_2, hint_3
  INTO v_hints
  FROM public.anonymous_identity_hints
  WHERE letter_id = letter_id_param;
  
  -- If no hints exist, return nothing
  IF v_hints IS NULL THEN
    RETURN;
  END IF;
  
  -- Collect available hints (non-null only)
  v_available_hints := ARRAY[]::TEXT[];
  IF v_hints.hint_1 IS NOT NULL AND LENGTH(TRIM(v_hints.hint_1)) > 0 THEN
    v_available_hints := array_append(v_available_hints, v_hints.hint_1);
  END IF;
  IF v_hints.hint_2 IS NOT NULL AND LENGTH(TRIM(v_hints.hint_2)) > 0 THEN
    v_available_hints := array_append(v_available_hints, v_hints.hint_2);
  END IF;
  IF v_hints.hint_3 IS NOT NULL AND LENGTH(TRIM(v_hints.hint_3)) > 0 THEN
    v_available_hints := array_append(v_available_hints, v_hints.hint_3);
  END IF;
  
  -- If no available hints, return nothing
  IF array_length(v_available_hints, 1) IS NULL THEN
    RETURN;
  END IF;
  
  v_hint_count := array_length(v_available_hints, 1);
  
  v_opened_at := v_capsule.opened_at;
  v_reveal_at := v_capsule.reveal_at;
  v_total_duration := v_reveal_at - v_opened_at;
  v_elapsed := v_now - v_opened_at;
  v_remaining := v_reveal_at - v_now;
  v_elapsed_ratio := EXTRACT(EPOCH FROM v_elapsed) / NULLIF(EXTRACT(EPOCH FROM v_total_duration), 0);
  
  -- If already past reveal time, return nothing (shouldn't happen, but safety check)
  IF v_remaining <= INTERVAL '0' THEN
    RETURN;
  END IF;
  
  -- Determine eligible hint based on number of hints provided
  -- New logic: Show hints based on count, not total duration
  -- 1 hint: Show at 50% elapsed
  -- 2 hints: Show at 35% and 70% elapsed
  -- 3 hints: Show at 30%, 50%, and 85% elapsed
  
  IF v_hint_count = 1 THEN
    -- Single hint: Show at 50% elapsed
    IF v_elapsed_ratio >= 0.50 THEN
      v_eligible_hint_index := 1;
      v_eligible_hint_text := v_available_hints[1];
    END IF;
  
  ELSIF v_hint_count = 2 THEN
    -- Two hints: Show at 35% and 70% elapsed
    IF v_elapsed_ratio >= 0.70 THEN
      v_eligible_hint_index := 2;
      v_eligible_hint_text := v_available_hints[2];
    ELSIF v_elapsed_ratio >= 0.35 THEN
      v_eligible_hint_index := 1;
      v_eligible_hint_text := v_available_hints[1];
    END IF;
  
  ELSIF v_hint_count = 3 THEN
    -- Three hints: Show at 30%, 50%, and 85% elapsed
    IF v_elapsed_ratio >= 0.85 THEN
      v_eligible_hint_index := 3;
      v_eligible_hint_text := v_available_hints[3];
    ELSIF v_elapsed_ratio >= 0.50 THEN
      v_eligible_hint_index := 2;
      v_eligible_hint_text := v_available_hints[2];
    ELSIF v_elapsed_ratio >= 0.30 THEN
      v_eligible_hint_index := 1;
      v_eligible_hint_text := v_available_hints[1];
    END IF;
  END IF;
  
  -- Return eligible hint if found
  IF v_eligible_hint_text IS NOT NULL THEN
    RETURN QUERY SELECT v_eligible_hint_text, v_eligible_hint_index;
  END IF;
  
  RETURN;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_current_anonymous_hint(UUID) TO authenticated;

-- ============================================================================
-- 5. COMMENTS
-- ============================================================================
COMMENT ON TABLE public.anonymous_identity_hints IS 
  'Stores optional progressive identity hints for anonymous letters. Hints reveal automatically based on time remaining until identity reveal.';

COMMENT ON FUNCTION public.get_current_anonymous_hint(UUID) IS 
  'Determines which hint (if any) should be shown based on number of hints provided. Rules: 1 hint at 50%, 2 hints at 35%/70%, 3 hints at 30%/50%/85% elapsed. Returns hint_text and hint_index (1, 2, or 3).';

