-- ============================================================================
-- Update open_self_letter function to return title
-- ============================================================================
-- WHAT: Updates the open_self_letter function to include title in return
-- WHY: Title field was added to self_letters table
-- NOTE: Run this after migration 23_add_title_to_self_letters.sql
-- 
-- IMPORTANT: This migration requires superuser privileges to update the function.
-- If you get permission errors, run the SQL below manually in Supabase Dashboard
-- SQL Editor (which runs as service role with proper permissions).
-- ============================================================================

-- Drop and recreate the function with title in return
-- Note: This may fail if you don't have ownership - run manually if needed
DROP FUNCTION IF EXISTS public.open_self_letter(UUID, UUID);

CREATE FUNCTION public.open_self_letter(letter_id UUID, p_user_id UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
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
    v_letter.title,
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.open_self_letter(UUID, UUID) TO authenticated;
