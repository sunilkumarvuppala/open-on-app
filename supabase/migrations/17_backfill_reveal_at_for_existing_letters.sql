-- ============================================================================
-- Backfill reveal_at for Existing Opened Anonymous Letters
-- ============================================================================
-- WHAT: Backfills reveal_at for anonymous letters that were opened before
--      the reveal_at calculation was added to the open_capsule endpoint
-- WHY: Ensures existing opened anonymous letters can still reveal properly
-- BEHAVIOR:
--   - Finds anonymous letters that are opened but missing reveal_at
--   - Calculates reveal_at = opened_at + reveal_delay_seconds
--   - Uses default 6 hours if reveal_delay_seconds is missing
-- ============================================================================

-- Backfill reveal_at for existing opened anonymous letters
UPDATE public.capsules
SET 
  reveal_at = opened_at + (
    COALESCE(reveal_delay_seconds, 21600) || ' seconds'
  )::INTERVAL,
  updated_at = now()
WHERE 
  is_anonymous = TRUE
  AND opened_at IS NOT NULL
  AND reveal_at IS NULL
  AND deleted_at IS NULL;

-- Log how many were updated
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'Backfilled reveal_at for % existing opened anonymous letters', v_count;
END $$;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON COLUMN public.capsules.reveal_at IS 
  'Timestamp when anonymous sender will be revealed (opened_at + reveal_delay_seconds). Backfilled for existing letters.';
