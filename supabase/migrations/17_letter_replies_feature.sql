-- ============================================================================
-- Letter Replies Feature Migration
-- ============================================================================
-- WHAT: Implements one-time receiver reply feature for letters (capsules)
-- WHY: Allows receivers to send a one-time acknowledgment reply to letter senders
-- SECURITY: Enforced at database level with RLS, one reply per letter
-- ============================================================================
-- NON-BREAKING: This is a purely additive feature. No existing tables or
-- columns are modified. Existing letter flows remain unchanged.
-- ============================================================================

-- ============================================================================
-- 1. CREATE LETTER_REPLIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.letter_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
  
  -- Reply content
  reply_text VARCHAR(60) NOT NULL,
  reply_emoji VARCHAR(4) NOT NULL,
  
  -- Animation tracking (separate for receiver and sender)
  receiver_animation_seen_at TIMESTAMPTZ,
  sender_animation_seen_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT letter_replies_text_length CHECK (char_length(reply_text) <= 60),
  CONSTRAINT letter_replies_emoji_check CHECK (
    reply_emoji IN ('❤️', '🥹', '😊', '😎', '😢', '🤍', '🙏')
  ),
  CONSTRAINT letter_replies_one_per_letter UNIQUE (letter_id)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_letter_replies_letter_id ON public.letter_replies(letter_id);
CREATE INDEX IF NOT EXISTS idx_letter_replies_created_at ON public.letter_replies(created_at);

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE public.letter_replies ENABLE ROW LEVEL SECURITY;

-- SELECT Policy: Users can view replies for letters they sent or received
CREATE POLICY letter_replies_select_policy ON public.letter_replies
  FOR SELECT
  USING (
    -- Receiver can view their own reply
    EXISTS (
      SELECT 1 FROM public.capsules c
      JOIN public.recipients r ON c.recipient_id = r.id
      WHERE c.id = letter_replies.letter_id
        AND (
          -- Email-based recipient
          (r.email IS NOT NULL AND r.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
          OR
          -- Connection-based recipient (linked_user_id matches)
          (r.linked_user_id = auth.uid())
        )
    )
    OR
    -- Sender can view replies to their letters
    EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_replies.letter_id
        AND c.sender_id = auth.uid()
    )
  );

-- INSERT Policy: Only receivers can create replies, and only once per letter
CREATE POLICY letter_replies_insert_policy ON public.letter_replies
  FOR INSERT
  WITH CHECK (
    -- Must be the recipient of the letter
    EXISTS (
      SELECT 1 FROM public.capsules c
      JOIN public.recipients r ON c.recipient_id = r.id
      WHERE c.id = letter_replies.letter_id
        AND c.opened_at IS NOT NULL  -- Letter must be opened
        AND (
          -- Email-based recipient
          (r.email IS NOT NULL AND r.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
          OR
          -- Connection-based recipient (linked_user_id matches)
          (r.linked_user_id = auth.uid())
        )
    )
    AND
    -- Ensure only one reply per letter (enforced by UNIQUE constraint, but check here too)
    NOT EXISTS (
      SELECT 1 FROM public.letter_replies lr
      WHERE lr.letter_id = letter_replies.letter_id
    )
  );

-- UPDATE Policy: Allow receivers and senders to update animation seen timestamps
-- Note: Column-level restrictions (only animation timestamps can be updated) are
-- enforced by the backend repository methods, not by RLS policies.
CREATE POLICY letter_replies_update_policy ON public.letter_replies
  FOR UPDATE
  USING (
    -- Receiver can update (their animation timestamp)
    EXISTS (
      SELECT 1 FROM public.capsules c
      JOIN public.recipients r ON c.recipient_id = r.id
      WHERE c.id = letter_replies.letter_id
        AND (
          (r.email IS NOT NULL AND r.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
          OR (r.linked_user_id = auth.uid())
        )
    )
    OR
    -- Sender can update (their animation timestamp)
    EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_replies.letter_id
        AND c.sender_id = auth.uid()
    )
  )
  WITH CHECK (
    -- Same permission check for the new row
    EXISTS (
      SELECT 1 FROM public.capsules c
      JOIN public.recipients r ON c.recipient_id = r.id
      WHERE c.id = letter_replies.letter_id
        AND (
          (r.email IS NOT NULL AND r.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
          OR (r.linked_user_id = auth.uid())
        )
    )
    OR
    EXISTS (
      SELECT 1 FROM public.capsules c
      WHERE c.id = letter_replies.letter_id
        AND c.sender_id = auth.uid()
    )
  );

-- DELETE Policy: No deletes allowed (replies are permanent)
CREATE POLICY letter_replies_delete_policy ON public.letter_replies
  FOR DELETE
  USING (false);  -- Never allow deletes

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================

-- Function to create a reply (with validation)
CREATE OR REPLACE FUNCTION public.create_letter_reply(
  p_letter_id UUID,
  p_reply_text VARCHAR(60),
  p_reply_emoji VARCHAR(4)
)
RETURNS public.letter_replies
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reply public.letter_replies;
  v_user_id UUID;
  v_user_email TEXT;
  v_capsule RECORD;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;
  
  -- Get user email
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  
  -- Get capsule and verify recipient
  SELECT c.*, r.email as recipient_email, r.linked_user_id
  INTO v_capsule
  FROM public.capsules c
  JOIN public.recipients r ON c.recipient_id = r.id
  WHERE c.id = p_letter_id
    AND c.deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Letter not found';
  END IF;
  
  -- Verify letter is opened
  IF v_capsule.opened_at IS NULL THEN
    RAISE EXCEPTION 'Letter must be opened before replying';
  END IF;
  
  -- Verify user is the recipient
  IF NOT (
    (v_capsule.recipient_email IS NOT NULL AND v_capsule.recipient_email = v_user_email)
    OR (v_capsule.linked_user_id = v_user_id)
  ) THEN
    RAISE EXCEPTION 'Only the recipient can reply to this letter';
  END IF;
  
  -- Check if reply already exists
  IF EXISTS (SELECT 1 FROM public.letter_replies WHERE letter_id = p_letter_id) THEN
    RAISE EXCEPTION 'Reply already exists for this letter';
  END IF;
  
  -- Validate emoji
  IF p_reply_emoji NOT IN ('❤️', '🥹', '😊', '😎', '😢', '🤍', '🙏') THEN
    RAISE EXCEPTION 'Invalid emoji. Must be one of: ❤️ 🥹 😊 😎 😢 🤍 🙏';
  END IF;
  
  -- Validate text length
  IF char_length(p_reply_text) > 60 THEN
    RAISE EXCEPTION 'Reply text must be 60 characters or less';
  END IF;
  
  -- Create reply
  INSERT INTO public.letter_replies (letter_id, reply_text, reply_emoji)
  VALUES (p_letter_id, p_reply_text, p_reply_emoji)
  RETURNING * INTO v_reply;
  
  RETURN v_reply;
END;
$$;

-- Function to mark receiver animation as seen
CREATE OR REPLACE FUNCTION public.mark_receiver_animation_seen(
  p_letter_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_user_email TEXT;
  v_capsule RECORD;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;
  
  -- Get user email
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  
  -- Get capsule and verify recipient
  SELECT c.*, r.email as recipient_email, r.linked_user_id
  INTO v_capsule
  FROM public.capsules c
  JOIN public.recipients r ON c.recipient_id = r.id
  WHERE c.id = p_letter_id
    AND c.deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Letter not found';
  END IF;
  
  -- Verify user is the recipient
  IF NOT (
    (v_capsule.recipient_email IS NOT NULL AND v_capsule.recipient_email = v_user_email)
    OR (v_capsule.linked_user_id = v_user_id)
  ) THEN
    RAISE EXCEPTION 'Only the recipient can mark receiver animation as seen';
  END IF;
  
  -- Update animation seen timestamp
  UPDATE public.letter_replies
  SET receiver_animation_seen_at = NOW()
  WHERE letter_id = p_letter_id
    AND receiver_animation_seen_at IS NULL;
END;
$$;

-- Function to mark sender animation as seen
CREATE OR REPLACE FUNCTION public.mark_sender_animation_seen(
  p_letter_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_capsule RECORD;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated';
  END IF;
  
  -- Get capsule and verify sender
  SELECT c.*
  INTO v_capsule
  FROM public.capsules c
  WHERE c.id = p_letter_id
    AND c.deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Letter not found';
  END IF;
  
  -- Verify user is the sender
  IF v_capsule.sender_id != v_user_id THEN
    RAISE EXCEPTION 'Only the sender can mark sender animation as seen';
  END IF;
  
  -- Update animation seen timestamp
  UPDATE public.letter_replies
  SET sender_animation_seen_at = NOW()
  WHERE letter_id = p_letter_id
    AND sender_animation_seen_at IS NULL;
END;
$$;

-- ============================================================================
-- 5. COMMENTS
-- ============================================================================
COMMENT ON TABLE public.letter_replies IS 'One-time replies from letter receivers to senders. One reply per letter, enforced by UNIQUE constraint.';
COMMENT ON COLUMN public.letter_replies.letter_id IS 'References the capsule (letter) this reply is for. UNIQUE constraint ensures one reply per letter.';
COMMENT ON COLUMN public.letter_replies.reply_text IS 'Reply text content, max 60 characters.';
COMMENT ON COLUMN public.letter_replies.reply_emoji IS 'Selected emoji from fixed set: ❤️ 🥹 😊 😢 🤍 🙏';
COMMENT ON COLUMN public.letter_replies.receiver_animation_seen_at IS 'Timestamp when receiver saw the animation (after sending reply).';
COMMENT ON COLUMN public.letter_replies.sender_animation_seen_at IS 'Timestamp when sender saw the animation (when viewing reply).';

