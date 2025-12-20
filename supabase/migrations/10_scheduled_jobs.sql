-- ============================================================================
-- Scheduled Jobs Migration
-- pg_cron jobs for background tasks
-- ============================================================================
-- WHAT: Automated background jobs using pg_cron extension
-- WHY: Automates repetitive tasks like cleanup, notifications, and status updates.
--      Runs at scheduled intervals without manual intervention.
--      Uses PostgreSQL's built-in pg_cron extension for reliability.
-- USAGE: Jobs run automatically, no manual intervention needed.
--        Can be monitored via: SELECT * FROM cron.job_run_details;
-- ============================================================================

-- ============================================================================
-- JOB: Delete expired disappearing messages
-- ============================================================================
-- WHAT: Soft-deletes disappearing messages that have expired
-- WHY: Automates cleanup of disappearing messages after they've been open for specified duration.
--      Runs every minute to ensure timely deletion.
-- SCHEDULE: Every minute (* * * * *)
-- FUNCTION: delete_expired_disappearing_messages()
-- EXAMPLES:
--   - Message opened at 10:00:00, disappearing_after_open_seconds = 60
--     At 10:01:00: Job runs, message soft-deleted (deleted_at = NOW())
--   - Message opened at 10:00:00, disappearing_after_open_seconds = 3600 (1 hour)
--     At 11:00:00: Job runs, message soft-deleted
-- ============================================================================
-- Delete expired disappearing messages (every minute)
DO $cron_job_1$
BEGIN
  -- Remove existing job if it exists
  PERFORM cron.unschedule('delete-expired-disappearing-messages') WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'delete-expired-disappearing-messages'
  );
  
  -- Create new job
  PERFORM cron.schedule(
    'delete-expired-disappearing-messages',
    '* * * * *',
    'SELECT public.delete_expired_disappearing_messages();'
  );
EXCEPTION WHEN OTHERS THEN
  -- Job might not exist, just create it
  PERFORM cron.schedule(
    'delete-expired-disappearing-messages',
    '* * * * *',
    'SELECT public.delete_expired_disappearing_messages();'
  );
END $cron_job_1$;

-- ============================================================================
-- JOB: Send unlock soon notifications
-- ============================================================================
-- WHAT: Sends notifications for capsules unlocking in next 24 hours
-- WHY: Proactively notifies recipients before letters unlock, improving engagement.
--      Runs every hour to catch capsules that will unlock soon.
-- SCHEDULE: Every hour (0 * * * *)
-- FUNCTION: send_unlock_soon_notifications()
-- EXAMPLES:
--   - Capsule unlocks at 2025-12-25 00:00:00, current time is 2025-12-24 01:00:00
--     Job runs at 01:00: Recipient gets notification: "Letter will unlock in 24 hours"
--   - Capsule unlocks at 2025-12-25 00:00:00, current time is 2025-12-24 23:00:00
--     Job runs at 23:00: Recipient gets notification: "Letter will unlock in 1 hour"
-- IDEMPOTENCY: Checks for existing notifications to prevent duplicates
-- ============================================================================
-- Send unlock soon notifications (every hour)
DO $cron_job_2$
BEGIN
  PERFORM cron.unschedule('send-unlock-soon-notifications') WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'send-unlock-soon-notifications'
  );
  
  PERFORM cron.schedule(
    'send-unlock-soon-notifications',
    '0 * * * *',
    'SELECT public.send_unlock_soon_notifications();'
  );
EXCEPTION WHEN OTHERS THEN
  PERFORM cron.schedule(
    'send-unlock-soon-notifications',
    '0 * * * *',
    'SELECT public.send_unlock_soon_notifications();'
  );
END $cron_job_2$;

-- ============================================================================
-- JOB: Update premium status
-- ============================================================================
-- WHAT: Syncs user_profiles.premium_status with active subscriptions
-- WHY: Ensures premium_status is accurate based on subscription data.
--      Runs daily to sync status after subscription changes.
-- SCHEDULE: Daily at midnight (0 0 * * *)
-- FUNCTION: Inline SQL (updates premium_status based on subscription status)
-- EXAMPLES:
--   - User has active subscription: premium_status = TRUE, premium_until = subscription.ends_at
--   - User's subscription expired: premium_status = FALSE, premium_until = NULL
--   - User has no subscription: premium_status = FALSE, premium_until = NULL
-- LOGIC:
--   - Sets premium_status = TRUE if user has active subscription
--   - Sets premium_until = subscription.ends_at
--   - Sets premium_status = FALSE if no active subscription
-- ============================================================================
-- Update premium status (daily at midnight)
DO $cron_job_3$
BEGIN
  PERFORM cron.unschedule('update-premium-status') WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'update-premium-status'
  );
  
  PERFORM cron.schedule(
    'update-premium-status',
    '0 0 * * *',
    'UPDATE public.user_profiles up SET premium_status = EXISTS (SELECT 1 FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'' AND us.ends_at > NOW()), premium_until = (SELECT MAX(ends_at) FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'') WHERE up.premium_status = TRUE OR EXISTS (SELECT 1 FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'');'
  );
EXCEPTION WHEN OTHERS THEN
  PERFORM cron.schedule(
    'update-premium-status',
    '0 0 * * *',
    'UPDATE public.user_profiles up SET premium_status = EXISTS (SELECT 1 FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'' AND us.ends_at > NOW()), premium_until = (SELECT MAX(ends_at) FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'') WHERE up.premium_status = TRUE OR EXISTS (SELECT 1 FROM public.user_subscriptions us WHERE us.user_id = up.user_id AND us.status = ''active'');'
  );
END $cron_job_3$;

