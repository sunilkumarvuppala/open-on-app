-- ============================================================================
-- Indexes Migration
-- Performance-optimized indexes for all tables
-- ============================================================================
-- WHAT: Database indexes to improve query performance
-- WHY: Indexes speed up common queries (WHERE, JOIN, ORDER BY) by creating sorted data structures.
--      Partial indexes (WHERE clauses) reduce index size and improve performance.
--      Composite indexes support multi-column queries efficiently.
-- USAGE: Indexes are used automatically by PostgreSQL query planner.
--        No manual intervention needed - queries benefit automatically.
-- ============================================================================

-- ============================================================================
-- User Profiles Indexes
-- ============================================================================
-- idx_user_profiles_premium: Composite index for premium status queries
--   - Used for: Filtering premium users, finding expiring subscriptions
--   - Example: SELECT * FROM user_profiles WHERE premium_status = TRUE AND premium_until > NOW()
-- idx_user_profiles_country: Index for country-based queries
--   - Used for: Analytics, localization, country-specific features
--   - Example: SELECT COUNT(*) FROM user_profiles WHERE country = 'US'
-- idx_user_profiles_is_admin: Partial index for admin operations (only indexes admins)
--   - Used for: Finding admin users quickly (smaller index, faster queries)
--   - Example: SELECT * FROM user_profiles WHERE is_admin = TRUE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_premium ON public.user_profiles(premium_status, premium_until);
CREATE INDEX IF NOT EXISTS idx_user_profiles_country ON public.user_profiles(country);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_admin ON public.user_profiles(is_admin) WHERE is_admin = TRUE;

-- ============================================================================
-- Recipients Indexes
-- ============================================================================
-- idx_recipients_owner: Most common query - get all recipients for a user
--   - Used for: Loading user's contact list
--   - Example: SELECT * FROM recipients WHERE owner_id = auth.uid()
-- idx_recipients_owner_created: Composite index for sorted recipient lists
--   - Used for: Getting recipients sorted by creation date (newest first)
--   - Example: SELECT * FROM recipients WHERE owner_id = auth.uid() ORDER BY created_at DESC
-- idx_recipients_relationship: Composite index for relationship filtering
--   - Used for: Filtering recipients by relationship type
--   - Example: SELECT * FROM recipients WHERE owner_id = auth.uid() AND relationship = 'family'
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_recipients_owner ON public.recipients(owner_id);
CREATE INDEX IF NOT EXISTS idx_recipients_owner_created ON public.recipients(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipients_relationship ON public.recipients(owner_id, relationship);

-- ============================================================================
-- Themes Indexes
-- ============================================================================
-- idx_themes_premium: Filter by premium status
--   - Used for: Getting free vs premium themes
--   - Example: SELECT * FROM themes WHERE premium_only = FALSE
-- idx_themes_name: Lookup by name (unique constraint also creates index, but explicit for clarity)
--   - Used for: Finding theme by name
--   - Example: SELECT * FROM themes WHERE name = 'Deep Blue'
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_themes_premium ON public.themes(premium_only);
CREATE INDEX IF NOT EXISTS idx_themes_name ON public.themes(name);

-- ============================================================================
-- Animations Indexes
-- ============================================================================
-- idx_animations_premium: Filter by premium status
--   - Used for: Getting free vs premium animations
--   - Example: SELECT * FROM animations WHERE premium_only = FALSE
-- idx_animations_name: Lookup by name (unique constraint also creates index, but explicit for clarity)
--   - Used for: Finding animation by name
--   - Example: SELECT * FROM animations WHERE name = 'Sparkle Unfold'
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_animations_premium ON public.animations(premium_only);
CREATE INDEX IF NOT EXISTS idx_animations_name ON public.animations(name);

-- ============================================================================
-- Capsules Indexes
-- ============================================================================
-- idx_capsules_sender: Outbox query - get capsules sent by user (sorted by date)
--   - Used for: Loading user's outbox (sent letters)
--   - Example: SELECT * FROM capsules WHERE sender_id = auth.uid() ORDER BY created_at DESC
-- idx_capsules_recipient: Inbox query - get capsules received by user (sorted by date)
--   - Used for: Loading user's inbox (received letters)
--   - Example: SELECT * FROM capsules WHERE recipient_id = '...' ORDER BY created_at DESC
-- idx_capsules_status: Filter by status (sealed, ready, opened, expired)
--   - Used for: Filtering capsules by status
--   - Example: SELECT * FROM capsules WHERE status = 'ready'
-- idx_capsules_unlocks_at: Partial index for finding capsules ready to unlock (cron job)
--   - Used for: Cron job that updates status from 'sealed' to 'ready'
--   - Example: SELECT * FROM capsules WHERE status = 'sealed' AND unlocks_at <= NOW()
-- idx_capsules_opened_at: Partial index for finding expired disappearing messages (cron job)
--   - Used for: Cron job that deletes expired disappearing messages
--   - Example: SELECT * FROM capsules WHERE is_disappearing = TRUE AND opened_at + interval < NOW()
-- idx_capsules_deleted_at: Partial index for soft-deleted capsules (exclude from normal queries)
--   - Used for: Efficiently excluding soft-deleted capsules from queries
--   - Example: SELECT * FROM capsules WHERE deleted_at IS NULL (uses index to skip deleted)
-- idx_capsules_recipient_status: Composite index for inbox with status filter
--   - Used for: Getting recipient's capsules filtered by status
--   - Example: SELECT * FROM capsules WHERE recipient_id = '...' AND status = 'ready' ORDER BY created_at DESC
-- idx_capsules_sender_status: Composite index for outbox with status filter
--   - Used for: Getting sender's capsules filtered by status
--   - Example: SELECT * FROM capsules WHERE sender_id = auth.uid() AND status = 'opened' ORDER BY created_at DESC
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_capsules_sender ON public.capsules(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_recipient ON public.capsules(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules(status);
CREATE INDEX IF NOT EXISTS idx_capsules_unlocks_at ON public.capsules(unlocks_at) WHERE status = 'sealed';
CREATE INDEX IF NOT EXISTS idx_capsules_opened_at ON public.capsules(opened_at) WHERE is_disappearing = TRUE;
CREATE INDEX IF NOT EXISTS idx_capsules_deleted_at ON public.capsules(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_capsules_recipient_status ON public.capsules(recipient_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_sender_status ON public.capsules(sender_id, status, created_at DESC);

-- ============================================================================
-- Notifications Indexes
-- ============================================================================
-- idx_notifications_user: Get user's notifications (sorted by date, newest first)
--   - Used for: Loading user's notification list
--   - Example: SELECT * FROM notifications WHERE user_id = auth.uid() ORDER BY created_at DESC
-- idx_notifications_delivered: Partial index for undelivered notifications (push notification queue)
--   - Used for: Finding notifications that need to be sent (push notifications)
--   - Example: SELECT * FROM notifications WHERE user_id = auth.uid() AND delivered = FALSE
-- idx_notifications_capsule: Find notifications for a specific capsule
--   - Used for: Getting all notifications related to a capsule
--   - Example: SELECT * FROM notifications WHERE capsule_id = '...'
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_delivered ON public.notifications(user_id, delivered) WHERE delivered = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_capsule ON public.notifications(capsule_id);

-- ============================================================================
-- Subscriptions Indexes
-- ============================================================================
-- idx_subscriptions_user: Get user's subscription
--   - Used for: Checking if user has active subscription
--   - Example: SELECT * FROM user_subscriptions WHERE user_id = auth.uid()
-- idx_subscriptions_status: Filter by subscription status
--   - Used for: Finding subscriptions by status (active, canceled, etc.)
--   - Example: SELECT * FROM user_subscriptions WHERE status = 'active'
-- idx_subscriptions_ends_at: Partial index for finding active subscriptions expiring soon (cron job)
--   - Used for: Cron job that sends expiration reminders
--   - Example: SELECT * FROM user_subscriptions WHERE status = 'active' AND ends_at < NOW() + INTERVAL '7 days'
-- idx_subscriptions_stripe: Partial index for Stripe webhook lookups (by subscription ID)
--   - Used for: Finding subscription by Stripe ID when webhook arrives
--   - Example: SELECT * FROM user_subscriptions WHERE stripe_subscription_id = 'sub_...'
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_ends_at ON public.user_subscriptions(ends_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe ON public.user_subscriptions(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;

-- ============================================================================
-- Audit Logs Indexes
-- ============================================================================
-- idx_audit_logs_user: Get user's audit logs (sorted by date)
--   - Used for: User viewing their own audit history
--   - Example: SELECT * FROM audit_logs WHERE user_id = auth.uid() ORDER BY created_at DESC
-- idx_audit_logs_capsule: Find audit logs for a specific capsule
--   - Used for: Viewing change history for a capsule
--   - Example: SELECT * FROM audit_logs WHERE capsule_id = '...' ORDER BY created_at
-- idx_audit_logs_action: Filter by action type (security analysis)
--   - Used for: Finding all deletions, updates, etc. for security analysis
--   - Example: SELECT * FROM audit_logs WHERE action = 'DELETE' ORDER BY created_at DESC
-- idx_audit_logs_created: General time-based queries
--   - Used for: Finding recent audit logs, time-range queries
--   - Example: SELECT * FROM audit_logs WHERE created_at > NOW() - INTERVAL '7 days' ORDER BY created_at DESC
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_capsule ON public.audit_logs(capsule_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

