-- ============================================================================
-- Scheduled Jobs Migration
-- pg_cron jobs for background tasks
-- ============================================================================

-- Delete expired disappearing messages every minute
SELECT cron.schedule(
  'delete-expired-disappearing-messages',
  '* * * * *',
  $$SELECT public.delete_expired_disappearing_messages();$$
) ON CONFLICT (jobname) DO UPDATE SET
  schedule = EXCLUDED.schedule,
  command = EXCLUDED.command;

-- Send unlock soon notifications every hour
SELECT cron.schedule(
  'send-unlock-soon-notifications',
  '0 * * * *',
  $$SELECT public.send_unlock_soon_notifications();$$
) ON CONFLICT (jobname) DO UPDATE SET
  schedule = EXCLUDED.schedule,
  command = EXCLUDED.command;

-- Update premium status based on subscriptions (daily)
SELECT cron.schedule(
  'update-premium-status',
  '0 0 * * *',
  $$
  UPDATE public.user_profiles up
  SET premium_status = EXISTS (
    SELECT 1 FROM public.user_subscriptions us
    WHERE us.user_id = up.user_id
      AND us.status = 'active'
      AND us.ends_at > NOW()
  ),
  premium_until = (
    SELECT MAX(ends_at) FROM public.user_subscriptions us
    WHERE us.user_id = up.user_id
      AND us.status = 'active'
  )
  WHERE up.premium_status = TRUE OR EXISTS (
    SELECT 1 FROM public.user_subscriptions us
    WHERE us.user_id = up.user_id
      AND us.status = 'active'
  );
  $$
) ON CONFLICT (jobname) DO UPDATE SET
  schedule = EXCLUDED.schedule,
  command = EXCLUDED.command;

