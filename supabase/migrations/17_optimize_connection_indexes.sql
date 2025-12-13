-- ============================================================================
-- Connection Query Optimization
-- ============================================================================
-- WHAT: Composite indexes to optimize connection queries
-- WHY: The current query uses OR conditions which can't use indexes efficiently.
--      These composite indexes support the UNION-based optimized queries.
-- ============================================================================

-- Composite index for user_id_1 lookups with sorting
-- Used by: SELECT ... FROM connections WHERE user_id_1 = :user_id ORDER BY connected_at DESC
CREATE INDEX IF NOT EXISTS idx_connections_user1_connected_at 
  ON public.connections(user_id_1, connected_at DESC);

-- Composite index for user_id_2 lookups with sorting
-- Used by: SELECT ... FROM connections WHERE user_id_2 = :user_id ORDER BY connected_at DESC
CREATE INDEX IF NOT EXISTS idx_connections_user2_connected_at 
  ON public.connections(user_id_2, connected_at DESC);

-- ============================================================================
-- Capsule Inbox Query Optimization
-- ============================================================================
-- Composite index for recipient-based capsule queries
-- Used by: inbox queries that join capsules with recipients
CREATE INDEX IF NOT EXISTS idx_capsules_recipient_deleted_created 
  ON public.capsules(recipient_id, deleted_at, created_at DESC) 
  WHERE deleted_at IS NULL;

-- Index for recipient email lookups (for email-based matching)
CREATE INDEX IF NOT EXISTS idx_recipients_email_lower 
  ON public.recipients(LOWER(email)) 
  WHERE email IS NOT NULL;

-- Index for recipient name lookups (for connection-based matching)
CREATE INDEX IF NOT EXISTS idx_recipients_name_lower 
  ON public.recipients(LOWER(TRIM(name))) 
  WHERE email IS NULL;

