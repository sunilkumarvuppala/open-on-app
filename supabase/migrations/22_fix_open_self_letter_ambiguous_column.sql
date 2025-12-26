-- ============================================================================
-- Migration: Fix ambiguous column reference in open_self_letter function
-- ============================================================================
-- WHAT: Fixes ambiguous column reference "id" in open_self_letter function
-- WHY: PostgreSQL was unable to determine if "id" referred to a column or variable
-- FIX: Qualify column names with table name (self_letters.id, self_letters.user_id)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.open_self_letter(letter_id UUID, p_user_id UUID)
RETURNS TABLE (
  id UUID,
  content TEXT,
  char_count INTEGER,
  scheduled_open_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  mood TEXT,
  life_area TEXT,
  city TEXT,
  created_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_letter public.self_letters%ROWTYPE;
BEGIN
  -- Get the letter and verify ownership
  SELECT * INTO v_letter
  FROM public.self_letters
  WHERE self_letters.id = letter_id
    AND self_letters.user_id = p_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Letter not found or access denied';
  END IF;
  
  -- Check if scheduled time has passed
  IF now() < v_letter.scheduled_open_at THEN
    RAISE EXCEPTION 'Letter cannot be opened before scheduled time';
  END IF;
  
  -- Set opened_at if not already set
  IF v_letter.opened_at IS NULL THEN
    UPDATE public.self_letters
    SET opened_at = now()
    WHERE self_letters.id = letter_id
      AND self_letters.opened_at IS NULL;  -- Prevent race conditions
    
    -- Reload to get updated opened_at
    SELECT * INTO v_letter
    FROM public.self_letters
    WHERE self_letters.id = letter_id
      AND self_letters.user_id = p_user_id;
  END IF;
  
  -- Return letter data
  RETURN QUERY
  SELECT 
    v_letter.id,
    v_letter.content,
    v_letter.char_count,
    v_letter.scheduled_open_at,
    v_letter.opened_at,
    v_letter.mood,
    v_letter.life_area,
    v_letter.city,
    v_letter.created_at;
END;
$$;

-- Grant execute permission (already exists, but ensuring it's set)
GRANT EXECUTE ON FUNCTION public.open_self_letter(UUID, UUID) TO authenticated;

-- ============================================================================
-- Also fix submit_self_letter_reflection function to accept user_id parameter
-- ============================================================================
CREATE OR REPLACE FUNCTION public.submit_self_letter_reflection(
  letter_id UUID,
  p_user_id UUID,
  answer TEXT
)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_letter public.self_letters%ROWTYPE;
BEGIN
  -- Validate answer
  IF answer NOT IN ('yes', 'no', 'skipped') THEN
    RAISE EXCEPTION 'Invalid reflection answer. Must be "yes", "no", or "skipped"';
  END IF;
  
  -- Get the letter and verify ownership
  SELECT * INTO v_letter
  FROM public.self_letters
  WHERE self_letters.id = letter_id
    AND self_letters.user_id = p_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Letter not found or access denied';
  END IF;
  
  -- Check if letter has been opened
  IF v_letter.opened_at IS NULL THEN
    RAISE EXCEPTION 'Letter must be opened before submitting reflection';
  END IF;
  
  -- Check if reflection already submitted
  IF v_letter.reflection_answer IS NOT NULL THEN
    RAISE EXCEPTION 'Reflection already submitted and cannot be changed';
  END IF;
  
  -- Update reflection
  UPDATE public.self_letters
  SET 
    reflection_answer = answer,
    reflected_at = now()
  WHERE self_letters.id = letter_id
    AND self_letters.user_id = p_user_id
    AND self_letters.reflection_answer IS NULL;  -- Prevent race conditions
  
  RETURN TRUE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.submit_self_letter_reflection(UUID, UUID, TEXT) TO authenticated;

