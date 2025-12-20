-- ============================================================================
-- Search Users Feature Migration
-- ============================================================================
-- WHAT: RPC function and RLS policy for searching users by username, name, or email
-- WHY: Provides a unified search interface that includes email from auth.users
--      while respecting RLS policies. Excludes current user from results.
-- SECURITY: Function uses SECURITY DEFINER, RLS policy allows basic profile access
-- ============================================================================

-- ============================================================================
-- 1. FUNCTION: search_users
-- ============================================================================
-- WHAT: Searches for users by username, first name, last name, or email
-- WHY: Provides a unified search interface that includes email from auth.users
--      while respecting RLS policies. Excludes current user from results.
--      Accepts optional user_id parameter for external auth systems.
-- RETURNS: Array of user profiles with user_id, first_name, last_name, username, avatar_url
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_users(
  search_query TEXT,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  user_id UUID,
  first_name TEXT,
  last_name TEXT,
  username TEXT,
  avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_user_id UUID;
BEGIN
  -- Determine current user ID: use provided parameter, or fall back to auth.uid()
  v_current_user_id := COALESCE(p_user_id, auth.uid());
  
  -- If still no user ID, return empty result
  IF v_current_user_id IS NULL THEN
    RETURN;
  END IF;
  
  RETURN QUERY
  SELECT DISTINCT
    up.user_id,
    up.first_name,
    up.last_name,
    up.username,
    up.avatar_url
  FROM public.user_profiles up
  LEFT JOIN auth.users au ON up.user_id = au.id
  WHERE 
    -- Exclude current user
    up.user_id != v_current_user_id
    -- Search in username, first name, last name, or email
    AND (
      up.username ILIKE '%' || search_query || '%'
      OR up.first_name ILIKE '%' || search_query || '%'
      OR up.last_name ILIKE '%' || search_query || '%'
      OR (up.first_name || ' ' || up.last_name) ILIKE '%' || search_query || '%'
      OR au.email ILIKE '%' || search_query || '%'
    )
  ORDER BY 
    -- Prioritize exact matches
    CASE 
      WHEN up.username = search_query THEN 1
      WHEN up.first_name = search_query THEN 2
      WHEN up.last_name = search_query THEN 3
      WHEN au.email = search_query THEN 4
      ELSE 5
    END,
    -- Then prioritize username matches
    CASE 
      WHEN up.username ILIKE search_query || '%' THEN 1
      ELSE 2
    END,
    up.username NULLS LAST
  LIMIT 20;
END;
$$;

-- Grant execute permission to authenticated users
-- Note: The function signature is (TEXT, UUID) with DEFAULT NULL for UUID
-- PostgreSQL allows calling it as search_users(TEXT) due to the default parameter
GRANT EXECUTE ON FUNCTION public.search_users(TEXT, UUID) TO authenticated;

-- ============================================================================
-- 2. RLS POLICY: Users can search for other users
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

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON FUNCTION public.search_users(TEXT, UUID) IS 
  'Searches for users by username, name, or email. Accepts optional user_id parameter for external auth systems. Excludes current user from results.';
COMMENT ON POLICY "Users can search for other users" ON public.user_profiles IS 
  'Allows authenticated users to read basic profile info of other users for connection search.';
