-- ============================================================================
-- Connections Migration
-- Friend Request / Mutual Connection feature
-- ============================================================================
-- WHAT: Tables and functions for managing user connections (friend requests)
-- WHY: Enables users to send connection requests and establish mutual connections
--      before sending letters. Enforces that letters can only be sent to mutual friends.
-- ============================================================================

-- ============================================================================
-- TABLE: connection_requests
-- ============================================================================
-- WHAT: Tracks friend/connection requests between users
-- WHY: Manages the request lifecycle (pending, accepted, declined)
--      Prevents duplicate pending requests and enforces cooldown periods
-- COLUMNS:
--   - id: Unique request identifier
--   - from_user_id: User who sent the request
--   - to_user_id: User who received the request
--   - status: Request status (pending, accepted, declined)
--   - message: Optional note from sender
--   - declined_reason: Optional reason for decline
--   - acted_at: When request was accepted/declined
-- CONSTRAINTS:
--   - Unique pending pair: Prevents duplicate pending requests between same users
--   - Status check: Only allows valid status values
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.connection_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')) DEFAULT 'pending',
  message TEXT,
  declined_reason TEXT,
  acted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Prevent duplicate pending requests between same users
  CONSTRAINT connection_requests_unique_pending UNIQUE (from_user_id, to_user_id) 
    DEFERRABLE INITIALLY DEFERRED
);

-- Partial unique index for pending requests only
CREATE UNIQUE INDEX IF NOT EXISTS idx_connection_requests_unique_pending 
  ON public.connection_requests(from_user_id, to_user_id) 
  WHERE status = 'pending';

-- Index for incoming requests lookup
CREATE INDEX IF NOT EXISTS idx_connection_requests_to_user_id 
  ON public.connection_requests(to_user_id, created_at DESC);

-- Index for outgoing requests lookup
CREATE INDEX IF NOT EXISTS idx_connection_requests_from_user_id 
  ON public.connection_requests(from_user_id, created_at DESC);

-- Index for status filtering
CREATE INDEX IF NOT EXISTS idx_connection_requests_status 
  ON public.connection_requests(status) 
  WHERE status = 'pending';

-- ============================================================================
-- TABLE: connections
-- ============================================================================
-- WHAT: Represents mutual connections (friendships) between users
-- WHY: Stores bidirectional friendships. Users are stored in sorted order
--      to ensure consistency (user_id_1 < user_id_2)
-- COLUMNS:
--   - user_id_1: First user (always the smaller UUID)
--   - user_id_2: Second user (always the larger UUID)
--   - connected_at: When the connection was established
-- CONSTRAINTS:
--   - Primary key on both user IDs ensures uniqueness
--   - Check constraint ensures user_id_1 < user_id_2
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.connections (
  user_id_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  connected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (user_id_1, user_id_2),
  CONSTRAINT connections_user_order CHECK (user_id_1 < user_id_2)
);

-- Index for user1 lookups
CREATE INDEX IF NOT EXISTS idx_connections_user1 
  ON public.connections(user_id_1);

-- Index for user2 lookups
CREATE INDEX IF NOT EXISTS idx_connections_user2 
  ON public.connections(user_id_2);

-- ============================================================================
-- TABLE: blocked_users
-- ============================================================================
-- WHAT: Tracks blocked users for abuse prevention
-- WHY: Prevents blocked users from sending connection requests
--      Enforces blocking in both directions
-- COLUMNS:
--   - blocker_id: User who blocked
--   - blocked_id: User who was blocked
--   - created_at: When the block was created
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT blocked_users_no_self_block CHECK (blocker_id != blocked_id)
);

-- Index for finding who a user has blocked
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker 
  ON public.blocked_users(blocker_id);

-- Index for finding who has blocked a user
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked 
  ON public.blocked_users(blocked_id);

-- ============================================================================
-- TRIGGER: Update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_connection_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_connection_request_updated_at
  BEFORE UPDATE ON public.connection_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_connection_request_updated_at();
