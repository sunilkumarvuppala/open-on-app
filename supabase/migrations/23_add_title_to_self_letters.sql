-- ============================================================================
-- Add title field to self_letters table
-- ============================================================================
-- WHAT: Adds optional title field to self_letters for better display
-- WHY: Users can provide a title when creating self letters through regular flow
-- ============================================================================

-- Add title column (nullable, optional)
ALTER TABLE public.self_letters
ADD COLUMN IF NOT EXISTS title TEXT;

-- Add comment
COMMENT ON COLUMN public.self_letters.title IS 
  'Optional title for the self letter (e.g., "Open on your birthday")';

-- Note: The function update is in a separate migration (24_update_open_self_letter_for_title.sql)
-- to avoid permission issues. Run that migration after this one.
