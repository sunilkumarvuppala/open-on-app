-- ============================================================================
-- Connections RLS Policies Migration
-- Row-level security policies for connection-related tables
-- ============================================================================

-- Enable RLS on connection tables
ALTER TABLE public.connection_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Connection Requests Policies
-- ============================================================================

-- Users can see requests where they are sender or receiver
DROP POLICY IF EXISTS "Users can view own connection requests" ON public.connection_requests;
CREATE POLICY "Users can view own connection requests"
  ON public.connection_requests
  FOR SELECT
  USING (
    auth.uid() = from_user_id OR auth.uid() = to_user_id
  );

-- Users can only create requests where they are the sender
DROP POLICY IF EXISTS "Users can send connection requests" ON public.connection_requests;
CREATE POLICY "Users can send connection requests"
  ON public.connection_requests
  FOR INSERT
  WITH CHECK (
    auth.uid() = from_user_id
    AND from_user_id != to_user_id
  );

-- Only receiver can update status (accept/decline)
-- Sender cannot edit after sending
DROP POLICY IF EXISTS "Receivers can respond to requests" ON public.connection_requests;
CREATE POLICY "Receivers can respond to requests"
  ON public.connection_requests
  FOR UPDATE
  USING (
    auth.uid() = to_user_id
    AND status = 'pending'
  )
  WITH CHECK (
    auth.uid() = to_user_id
    AND status IN ('accepted', 'declined')
  );

-- System can update for cooldown/abuse prevention (via RPC)
DROP POLICY IF EXISTS "System can update connection requests" ON public.connection_requests;
CREATE POLICY "System can update connection requests"
  ON public.connection_requests
  FOR UPDATE
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- No direct deletes - rely on status updates
-- Only service role can delete (for cleanup)
DROP POLICY IF EXISTS "System can delete connection requests" ON public.connection_requests;
CREATE POLICY "System can delete connection requests"
  ON public.connection_requests
  FOR DELETE
  USING (auth.role() = 'service_role');

-- ============================================================================
-- Connections Policies
-- ============================================================================

-- Users can see connections where they are user_id_1 or user_id_2
DROP POLICY IF EXISTS "Users can view own connections" ON public.connections;
CREATE POLICY "Users can view own connections"
  ON public.connections
  FOR SELECT
  USING (
    auth.uid() = user_id_1 OR auth.uid() = user_id_2
  );

-- Only system/service role can insert connections (via RPC function)
DROP POLICY IF EXISTS "System can create connections" ON public.connections;
CREATE POLICY "System can create connections"
  ON public.connections
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Allow future "unfriend" feature - users can delete their own connections
DROP POLICY IF EXISTS "Users can delete own connections" ON public.connections;
CREATE POLICY "Users can delete own connections"
  ON public.connections
  FOR DELETE
  USING (
    auth.uid() = user_id_1 OR auth.uid() = user_id_2
  );

-- ============================================================================
-- Blocked Users Policies
-- ============================================================================

-- Users can see blocks where they are the blocker
DROP POLICY IF EXISTS "Users can view own blocks" ON public.blocked_users;
CREATE POLICY "Users can view own blocks"
  ON public.blocked_users
  FOR SELECT
  USING (auth.uid() = blocker_id);

-- Users can create blocks where they are the blocker
DROP POLICY IF EXISTS "Users can block others" ON public.blocked_users;
CREATE POLICY "Users can block others"
  ON public.blocked_users
  FOR INSERT
  WITH CHECK (
    auth.uid() = blocker_id
    AND blocker_id != blocked_id
  );

-- Users can unblock (delete) their own blocks
DROP POLICY IF EXISTS "Users can unblock" ON public.blocked_users;
CREATE POLICY "Users can unblock"
  ON public.blocked_users
  FOR DELETE
  USING (auth.uid() = blocker_id);
