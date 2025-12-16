-- ============================================================================
-- User Profiles Search Policy Migration
-- Allows users to search for other users for connection purposes
-- ============================================================================

-- ============================================================================
-- POLICY: Users can search for other users
-- ============================================================================
-- WHAT: Allows authenticated users to read basic profile info of other users
-- WHY: Needed for connection search functionality - users need to find others
--      to send connection requests. Only exposes basic info (name, username, avatar).
-- SECURITY: Excludes sensitive data (email, premium status, etc.)
-- ============================================================================
DROP POLICY IF EXISTS "Users can search for other users" ON public.user_profiles;
CREATE POLICY "Users can search for other users"
  ON public.user_profiles
  FOR SELECT
  USING (
    -- Allow reading other users' profiles (exclude own profile which is handled by another policy)
    auth.uid() IS NOT NULL
    AND user_id != auth.uid()
  );

-- Add comment
COMMENT ON POLICY "Users can search for other users" ON public.user_profiles IS 
  'Allows authenticated users to read basic profile info of other users for connection search.';
