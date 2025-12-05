-- ============================================================================
-- Indexes Migration
-- Performance-optimized indexes for all tables
-- ============================================================================

-- User Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_premium ON public.user_profiles(premium_status, premium_until);
CREATE INDEX IF NOT EXISTS idx_user_profiles_country ON public.user_profiles(country);

-- Recipients Indexes
CREATE INDEX IF NOT EXISTS idx_recipients_owner ON public.recipients(owner_id);
CREATE INDEX IF NOT EXISTS idx_recipients_owner_created ON public.recipients(owner_id, created_at DESC);

-- Themes Indexes
CREATE INDEX IF NOT EXISTS idx_themes_premium ON public.themes(premium_only);
CREATE INDEX IF NOT EXISTS idx_themes_name ON public.themes(name);

-- Animations Indexes
CREATE INDEX IF NOT EXISTS idx_animations_premium ON public.animations(premium_only);
CREATE INDEX IF NOT EXISTS idx_animations_name ON public.animations(name);

-- Capsules Indexes
CREATE INDEX IF NOT EXISTS idx_capsules_sender ON public.capsules(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_recipient ON public.capsules(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules(status);
CREATE INDEX IF NOT EXISTS idx_capsules_unlocks_at ON public.capsules(unlocks_at) WHERE status = 'sealed';
CREATE INDEX IF NOT EXISTS idx_capsules_opened_at ON public.capsules(opened_at) WHERE is_disappearing = TRUE;
CREATE INDEX IF NOT EXISTS idx_capsules_deleted_at ON public.capsules(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_capsules_recipient_status ON public.capsules(recipient_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capsules_sender_status ON public.capsules(sender_id, status, created_at DESC);

-- Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_delivered ON public.notifications(user_id, delivered) WHERE delivered = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_capsule ON public.notifications(capsule_id);

-- Subscriptions Indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_ends_at ON public.user_subscriptions(ends_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe ON public.user_subscriptions(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;

-- Audit Logs Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_capsule ON public.audit_logs(capsule_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

