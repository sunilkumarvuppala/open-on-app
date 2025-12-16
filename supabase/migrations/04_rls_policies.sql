-- ============================================================================
-- RLS Policies Migration
-- Row-level security policies for all tables
-- ============================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.animations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = user_id); -- No deleted_at check (user_profiles don't have soft deletes)

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;
CREATE POLICY "Users can delete own profile"
  ON public.user_profiles
  FOR DELETE
  USING (auth.uid() = user_id);

-- Recipients Policies

DROP POLICY IF EXISTS "Users can read own recipients" ON public.recipients;
CREATE POLICY "Users can read own recipients"
  ON public.recipients
  FOR SELECT
  USING (auth.uid() = owner_id); -- No deleted_at check (recipients don't have soft deletes)

DROP POLICY IF EXISTS "Users can insert own recipients" ON public.recipients;
CREATE POLICY "Users can insert own recipients"
  ON public.recipients
  FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Users can update own recipients" ON public.recipients;
CREATE POLICY "Users can update own recipients"
  ON public.recipients
  FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Users can delete own recipients" ON public.recipients;
CREATE POLICY "Users can delete own recipients"
  ON public.recipients
  FOR DELETE
  USING (auth.uid() = owner_id);

-- Capsules Policies

DROP POLICY IF EXISTS "Senders can view own sent capsules" ON public.capsules;
CREATE POLICY "Senders can view own sent capsules"
  ON public.capsules
  FOR SELECT
  USING (
    auth.uid() = sender_id
    AND deleted_at IS NULL -- Exclude soft-deleted capsules
  );

DROP POLICY IF EXISTS "Recipients can view received capsules" ON public.capsules;
CREATE POLICY "Recipients can view received capsules"
  ON public.capsules
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.recipients r
      WHERE r.id = capsules.recipient_id
        AND r.email IS NOT NULL
        AND LOWER(TRIM(r.email)) = LOWER(TRIM((auth.jwt() ->> 'email')::text))
    )
    AND deleted_at IS NULL -- Exclude soft-deleted capsules
  );

DROP POLICY IF EXISTS "Users can create capsules" ON public.capsules;
CREATE POLICY "Users can create capsules"
  ON public.capsules
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND deleted_at IS NULL -- New capsules should not be soft-deleted
  );

DROP POLICY IF EXISTS "Senders can update unopened capsules" ON public.capsules;
CREATE POLICY "Senders can update unopened capsules"
  ON public.capsules
  FOR UPDATE
  USING (
    auth.uid() = sender_id
    AND deleted_at IS NULL -- Exclude soft-deleted capsules
    AND opened_at IS NULL  -- Must not be opened
    AND status IN ('sealed', 'ready')  -- Must be sealed or ready (not opened/expired)
  )
  WITH CHECK (
    auth.uid() = sender_id
    AND deleted_at IS NULL -- Exclude soft-deleted capsules
    AND opened_at IS NULL
    AND status IN ('sealed', 'ready')
  );

DROP POLICY IF EXISTS "Users can delete own unopened capsules" ON public.capsules;
CREATE POLICY "Users can delete own unopened capsules"
  ON public.capsules
  FOR DELETE
  USING (
    auth.uid() = sender_id
    AND deleted_at IS NULL -- Only allow deleting non-soft-deleted capsules
    AND (opened_at IS NULL OR status = 'sealed')
  );

-- Notifications Policies

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role'); -- Only service_role can insert (via triggers/functions)

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- User Subscriptions Policies

DROP POLICY IF EXISTS "Users can read own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can read own subscriptions"
  ON public.user_subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert subscriptions" ON public.user_subscriptions;
CREATE POLICY "System can insert subscriptions"
  ON public.user_subscriptions
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role'); -- Only service_role can insert (via Stripe webhooks)

DROP POLICY IF EXISTS "System can update subscriptions" ON public.user_subscriptions;
CREATE POLICY "System can update subscriptions"
  ON public.user_subscriptions
  FOR UPDATE
  USING (auth.role() = 'service_role') -- Only service_role can update (via Stripe webhooks)
  WITH CHECK (auth.role() = 'service_role');

-- Themes Policies

DROP POLICY IF EXISTS "All users can read themes" ON public.themes;
CREATE POLICY "All users can read themes"
  ON public.themes
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can insert themes" ON public.themes;
CREATE POLICY "Admins can insert themes"
  ON public.themes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can update themes" ON public.themes;
CREATE POLICY "Admins can update themes"
  ON public.themes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can delete themes" ON public.themes;
CREATE POLICY "Admins can delete themes"
  ON public.themes
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

-- Animations Policies

DROP POLICY IF EXISTS "All users can read animations" ON public.animations;
CREATE POLICY "All users can read animations"
  ON public.animations
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can insert animations" ON public.animations;
CREATE POLICY "Admins can insert animations"
  ON public.animations
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can update animations" ON public.animations;
CREATE POLICY "Admins can update animations"
  ON public.animations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can delete animations" ON public.animations;
CREATE POLICY "Admins can delete animations"
  ON public.animations
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

-- Audit Logs Policies

DROP POLICY IF EXISTS "Users can read own audit logs" ON public.audit_logs;
CREATE POLICY "Users can read own audit logs"
  ON public.audit_logs
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert audit logs" ON public.audit_logs;
CREATE POLICY "System can insert audit logs"
  ON public.audit_logs
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role'); -- Only service_role can insert (via SECURITY DEFINER triggers)

DROP POLICY IF EXISTS "Admins can read all audit logs" ON public.audit_logs;
CREATE POLICY "Admins can read all audit logs"
  ON public.audit_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

-- View Policies

-- Grant access to views
GRANT SELECT ON public.recipient_safe_capsules_view TO authenticated;
GRANT SELECT ON public.inbox_view TO authenticated;
GRANT SELECT ON public.outbox_view TO authenticated;

-- Function Security
GRANT EXECUTE ON FUNCTION public.update_capsule_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_updated_at() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_expired_disappearing_messages() TO authenticated;

-- SECURITY DEFINER functions (revoke public access)
REVOKE EXECUTE ON FUNCTION public.handle_capsule_opened() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.notify_capsule_unlocked() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.create_audit_log() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.send_unlock_soon_notifications() FROM PUBLIC;

