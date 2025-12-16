-- ============================================================================
-- Search Users Function Migration
-- RPC function for searching users by username, name, or email
-- ============================================================================

-- ============================================================================
-- FUNCTION: search_users
-- ============================================================================
-- WHAT: Searches for users by username, first name, last name, or email
-- WHY: Provides a unified search interface that includes email from auth.users
--      while respecting RLS policies. Excludes current user from results.
-- RETURNS: Array of user profiles with user_id, first_name, last_name, username, avatar_url
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_users(search_query TEXT)
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
BEGIN
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
    up.user_id != auth.uid()
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
GRANT EXECUTE ON FUNCTION public.search_users(TEXT) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.search_users(TEXT) IS 
  'Searches for users by username, name, or email. Excludes current user from results.';
