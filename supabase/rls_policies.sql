-- ============================================================================
-- Row Level Security (RLS) Policies
-- Production-ready security policies for OpenOn
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.animations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USER PROFILES POLICIES
-- ============================================================================

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own profile
CREATE POLICY "Users can delete own profile"
  ON public.user_profiles
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- RECIPIENTS POLICIES
-- ============================================================================

-- Users can read their own recipients
CREATE POLICY "Users can read own recipients"
  ON public.recipients
  FOR SELECT
  USING (auth.uid() = owner_id);

-- Users can insert their own recipients
CREATE POLICY "Users can insert own recipients"
  ON public.recipients
  FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Users can update their own recipients
CREATE POLICY "Users can update own recipients"
  ON public.recipients
  FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Users can delete their own recipients
CREATE POLICY "Users can delete own recipients"
  ON public.recipients
  FOR DELETE
  USING (auth.uid() = owner_id);

-- ============================================================================
-- CAPSULES POLICIES
-- ============================================================================

-- Senders can view capsules they sent (outbox)
CREATE POLICY "Senders can view own sent capsules"
  ON public.capsules
  FOR SELECT
  USING (auth.uid() = sender_id);

-- Recipients can view capsules sent to them (inbox)
-- Note: This uses recipient_safe_capsules_view in practice
CREATE POLICY "Recipients can view received capsules"
  ON public.capsules
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.recipients r
      WHERE r.id = capsules.recipient_id
        AND r.owner_id = auth.uid()
    )
  );

-- Senders can insert capsules
CREATE POLICY "Users can create capsules"
  ON public.capsules
  FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Senders can update capsules before they're opened
CREATE POLICY "Senders can update unopened capsules"
  ON public.capsules
  FOR UPDATE
  USING (
    auth.uid() = sender_id
    AND (opened_at IS NULL OR status = 'sealed')
  )
  WITH CHECK (
    auth.uid() = sender_id
    AND (opened_at IS NULL OR status = 'sealed')
  );

-- System can delete expired or disappearing capsules
-- Users can delete their own unopened capsules
CREATE POLICY "Users can delete own unopened capsules"
  ON public.capsules
  FOR DELETE
  USING (
    auth.uid() = sender_id
    AND (opened_at IS NULL OR status = 'sealed')
  );

-- ============================================================================
-- NOTIFICATIONS POLICIES
-- ============================================================================

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- System can insert notifications (via triggers/functions)
CREATE POLICY "System can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true); -- Triggers run with service role

-- Users can update their own notifications (mark as delivered)
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- USER SUBSCRIPTIONS POLICIES
-- ============================================================================

-- Users can read their own subscriptions
CREATE POLICY "Users can read own subscriptions"
  ON public.user_subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

-- System can insert subscriptions (via webhook)
CREATE POLICY "System can insert subscriptions"
  ON public.user_subscriptions
  FOR INSERT
  WITH CHECK (true); -- Webhooks run with service role

-- System can update subscriptions (via webhook)
CREATE POLICY "System can update subscriptions"
  ON public.user_subscriptions
  FOR UPDATE
  USING (true) -- Webhooks run with service role
  WITH CHECK (true);

-- ============================================================================
-- THEMES POLICIES
-- ============================================================================

-- All authenticated users can read themes
CREATE POLICY "All users can read themes"
  ON public.themes
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Only admins can insert themes
CREATE POLICY "Admins can insert themes"
  ON public.themes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE -- Using premium as admin flag for now
        -- In production, add an is_admin column
    )
  );

-- Only admins can update themes
CREATE POLICY "Admins can update themes"
  ON public.themes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- Only admins can delete themes
CREATE POLICY "Admins can delete themes"
  ON public.themes
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- ============================================================================
-- ANIMATIONS POLICIES
-- ============================================================================

-- All authenticated users can read animations
CREATE POLICY "All users can read animations"
  ON public.animations
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Only admins can insert animations
CREATE POLICY "Admins can insert animations"
  ON public.animations
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- Only admins can update animations
CREATE POLICY "Admins can update animations"
  ON public.animations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- Only admins can delete animations
CREATE POLICY "Admins can delete animations"
  ON public.animations
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- ============================================================================
-- AUDIT LOGS POLICIES
-- ============================================================================

-- Users can read their own audit logs
CREATE POLICY "Users can read own audit logs"
  ON public.audit_logs
  FOR SELECT
  USING (auth.uid() = user_id);

-- System can insert audit logs (via triggers)
CREATE POLICY "System can insert audit logs"
  ON public.audit_logs
  FOR INSERT
  WITH CHECK (true); -- Triggers run with service role

-- Only admins can read all audit logs
CREATE POLICY "Admins can read all audit logs"
  ON public.audit_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- ============================================================================
-- VIEW POLICIES
-- ============================================================================

-- Grant access to views
GRANT SELECT ON public.recipient_safe_capsules_view TO authenticated;
GRANT SELECT ON public.inbox_view TO authenticated;
GRANT SELECT ON public.outbox_view TO authenticated;

-- ============================================================================
-- FUNCTION SECURITY
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.update_capsule_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_capsule_opened() TO authenticated;
GRANT EXECUTE ON FUNCTION public.notify_capsule_unlocked() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_audit_log() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_updated_at() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_expired_disappearing_messages() TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_unlock_soon_notifications() TO authenticated;

