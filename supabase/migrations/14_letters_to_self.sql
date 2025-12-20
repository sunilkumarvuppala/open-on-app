-- ============================================================================
-- Letters to Self Feature Migration
-- ============================================================================
-- WHAT: Implements irreversible time-locked letters to future self
-- WHY: Allows users to write sealed messages to themselves for reflection
-- SECURITY: Enforced at database level with RLS, no editing/deleting after seal
-- ============================================================================

-- ============================================================================
-- 1. CREATE SELF_LETTERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.self_letters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Content (immutable after seal)
  content TEXT NOT NULL,
  char_count INTEGER NOT NULL,
  
  -- Time-locking
  scheduled_open_at TIMESTAMPTZ NOT NULL,
  opened_at TIMESTAMPTZ,
  
  -- Context captured at write time
  mood TEXT,                    -- e.g. "calm", "anxious", "tired"
  life_area TEXT,               -- "self" | "work" | "family" | "money" | "health"
  city TEXT,
  
  -- Reflection
  reflection_answer TEXT,       -- "yes" | "no" | "skipped"
  reflected_at TIMESTAMPTZ,
  
  -- Immutability flag
  sealed BOOLEAN DEFAULT TRUE NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT self_letters_char_count_check CHECK (char_count >= 0),
  CONSTRAINT self_letters_scheduled_open_future CHECK (scheduled_open_at > created_at),
  CONSTRAINT self_letters_reflection_answer_check CHECK (
    reflection_answer IS NULL OR reflection_answer IN ('yes', 'no', 'skipped')
  ),
  CONSTRAINT self_letters_life_area_check CHECK (
    life_area IS NULL OR life_area IN ('self', 'work', 'family', 'money', 'health')
  ),
  CONSTRAINT self_letters_immutable_after_seal CHECK (sealed = TRUE)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_self_letters_user_id ON public.self_letters(user_id);
CREATE INDEX IF NOT EXISTS idx_self_letters_user_scheduled_open ON public.self_letters(user_id, scheduled_open_at);
CREATE INDEX IF NOT EXISTS idx_self_letters_user_opened_at ON public.self_letters(user_id, opened_at) WHERE opened_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_self_letters_scheduled_open_at ON public.self_letters(scheduled_open_at) WHERE opened_at IS NULL;

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.self_letters ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. RLS POLICIES
-- ============================================================================

-- Policy: Users can insert their own letters
DROP POLICY IF EXISTS "Users can create their own self letters" ON public.self_letters;
CREATE POLICY "Users can create their own self letters"
  ON public.self_letters
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND sealed = TRUE
    AND char_count >= 0
    AND scheduled_open_at > created_at
  );

-- Policy: Users can read their own letters
-- Content is only visible if now() >= scheduled_open_at
DROP POLICY IF EXISTS "Users can read their own self letters" ON public.self_letters;
CREATE POLICY "Users can read their own self letters"
  ON public.self_letters
  FOR SELECT
  USING (
    auth.uid() = user_id
    AND (
      -- Content visible if opened or if scheduled time has passed
      opened_at IS NOT NULL
      OR now() >= scheduled_open_at
    )
  );

-- Policy: NO UPDATE allowed (immutable after creation)
-- This is intentional - letters to self cannot be edited or deleted

-- Policy: NO DELETE allowed (irreversible)
-- This is intentional - letters to self cannot be deleted

-- ============================================================================
-- 5. FUNCTION: Open self letter
-- ============================================================================
-- WHAT: Opens a self letter (sets opened_at if not already set)
-- WHY: Ensures opened_at is set atomically and only once
-- SECURITY: Only allows opening if scheduled time has passed
-- ============================================================================
CREATE OR REPLACE FUNCTION public.open_self_letter(letter_id UUID)
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
  -- Get the letter
  SELECT * INTO v_letter
  FROM public.self_letters
  WHERE id = letter_id
    AND user_id = auth.uid();
  
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
      AND opened_at IS NULL;  -- Prevent race conditions
    
    -- Reload to get updated opened_at
    SELECT * INTO v_letter
    FROM public.self_letters
    WHERE self_letters.id = letter_id;
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.open_self_letter(UUID) TO authenticated;

-- ============================================================================
-- 6. FUNCTION: Submit reflection
-- ============================================================================
-- WHAT: Records reflection answer for an opened self letter
-- WHY: Ensures reflection can only be submitted once after opening
-- SECURITY: Only allows reflection on opened letters
-- ============================================================================
CREATE OR REPLACE FUNCTION public.submit_self_letter_reflection(
  letter_id UUID,
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
  
  -- Get the letter
  SELECT * INTO v_letter
  FROM public.self_letters
  WHERE self_letters.id = letter_id
    AND user_id = auth.uid();
  
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
    AND reflection_answer IS NULL;  -- Prevent race conditions
  
  RETURN TRUE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.submit_self_letter_reflection(UUID, TEXT) TO authenticated;

-- ============================================================================
-- 7. COMMENTS
-- ============================================================================
COMMENT ON TABLE public.self_letters IS 
  'Irreversible time-locked letters to future self. Cannot be edited or deleted after creation.';
COMMENT ON COLUMN public.self_letters.sealed IS 
  'Always TRUE. Letters are sealed immediately upon creation and cannot be unsealed.';
COMMENT ON COLUMN public.self_letters.content IS 
  'Letter content. Only visible after scheduled_open_at has passed.';
COMMENT ON COLUMN public.self_letters.reflection_answer IS 
  'One-time reflection answer: "yes", "no", or "skipped". Cannot be changed after submission.';
COMMENT ON FUNCTION public.open_self_letter(UUID) IS 
  'Opens a self letter. Only allowed if scheduled time has passed. Sets opened_at atomically.';
COMMENT ON FUNCTION public.submit_self_letter_reflection(UUID, TEXT) IS 
  'Records reflection answer. Only allowed after letter is opened. One-time submission.';
