-- ============================================================================
-- Functions Migration
-- Database functions for automation
-- ============================================================================

-- ============================================================================
-- FUNCTION: update_capsule_status
-- ============================================================================
-- WHAT: Automatically updates capsule status based on unlock time and expiration
-- WHY: Ensures status is always correct without manual updates.
--      Called by trigger before INSERT/UPDATE to keep status in sync with time.
--      Prevents status inconsistencies (e.g., sealed capsule with past unlocks_at).
-- USAGE:
--   - Called automatically by trigger_update_capsule_status
--   - Runs BEFORE INSERT OR UPDATE on capsules table
--   - No manual calls needed
-- LOGIC:
--   - If unlocks_at <= NOW() AND status = 'sealed': Set status = 'ready'
--   - If expires_at < NOW() AND status != 'expired': Set status = 'expired'
-- EXAMPLES:
--   - Capsule with unlocks_at = '2025-01-01' and status = 'sealed'
--     On 2025-01-01: Status automatically changes to 'ready'
--   - Capsule with expires_at = '2025-12-31' and status = 'ready'
--     On 2026-01-01: Status automatically changes to 'expired'
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_capsule_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Update status based on current time
  IF NEW.unlocks_at <= NOW() AND NEW.status = 'sealed' THEN
    NEW.status := 'ready';
  END IF;
  
  -- Check expiration
  IF NEW.expires_at IS NOT NULL AND NEW.expires_at < NOW() AND NEW.status != 'expired' THEN
    NEW.status := 'expired';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: handle_capsule_opened
-- ============================================================================
-- WHAT: Handles capsule opening event (sets status, creates notification, schedules deletion)
-- WHY: Automates actions when capsule is opened for the first time.
--      Bypasses RLS (SECURITY DEFINER) to insert notifications even if user lacks permission.
--      Ensures disappearing messages are scheduled for deletion.
-- USAGE:
--   - Called automatically by trigger_handle_capsule_opened
--   - Runs BEFORE UPDATE when opened_at changes from NULL to NOT NULL
--   - No manual calls needed
-- ACTIONS:
--   1. Sets status = 'opened'
--   2. Creates notification for sender ("Your letter was opened")
--   3. Schedules deletion for disappearing messages (sets deleted_at)
-- EXAMPLES:
--   - User opens letter: UPDATE capsules SET opened_at = NOW() WHERE id = '...'
--     → Status changes to 'opened'
--     → Sender gets notification
--     → If disappearing: deleted_at = opened_at + disappearing_after_open_seconds
-- SECURITY: SECURITY DEFINER bypasses RLS to insert notifications
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_capsule_opened()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only update if opening for the first time
  IF OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL THEN
    NEW.status := 'opened';
    
    -- Create notification for sender (bypasses RLS via SECURITY DEFINER)
    INSERT INTO public.notifications (user_id, type, capsule_id, title, body)
    VALUES (
      NEW.sender_id,
      'unlocked',
      NEW.id,
      'Your letter was opened',
      'Your letter to ' || (SELECT name FROM public.recipients WHERE id = NEW.recipient_id) || ' has been opened.'
    );
    
    -- Schedule deletion for disappearing messages
    IF NEW.is_disappearing = TRUE AND NEW.disappearing_after_open_seconds IS NOT NULL THEN
      NEW.deleted_at := NEW.opened_at + (NEW.disappearing_after_open_seconds || ' seconds')::INTERVAL;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: notify_capsule_unlocked
-- ============================================================================
-- WHAT: Creates notification when capsule becomes ready to open
-- WHY: Notifies recipient when their letter is ready, improving user engagement.
--      Handles anonymous sender display ("Anonymous" vs actual name).
--      Bypasses RLS (SECURITY DEFINER) to insert notifications.
-- USAGE:
--   - Called automatically by trigger_notify_capsule_unlocked
--   - Runs AFTER UPDATE when status changes from 'sealed' to 'ready'
--   - No manual calls needed
-- BEHAVIOR:
--   - Gets recipient owner_id from recipients table
--   - Creates notification with type 'unlocked'
--   - Shows 'Anonymous' if is_anonymous = TRUE, else shows sender's full_name
-- EXAMPLES:
--   - Capsule unlocks: Status changes from 'sealed' to 'ready'
--     → Recipient gets notification: "You have a letter from John that is now ready to open"
--   - Anonymous capsule unlocks: Status changes to 'ready'
--     → Recipient gets notification: "You have a letter from Anonymous that is now ready to open"
-- SECURITY: SECURITY DEFINER bypasses RLS to insert notifications
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_capsule_unlocked()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recipient_owner_id UUID;
  recipient_name TEXT;
BEGIN
  -- Get recipient owner
  SELECT owner_id, name INTO recipient_owner_id, recipient_name
  FROM public.recipients
  WHERE id = NEW.recipient_id;
  
  -- Create notification for recipient (bypasses RLS via SECURITY DEFINER)
  INSERT INTO public.notifications (user_id, type, capsule_id, title, body)
  VALUES (
    recipient_owner_id,
    'unlocked',
    NEW.id,
    'A letter is ready to open',
    'You have a letter from ' || 
    CASE 
      WHEN NEW.is_anonymous = TRUE THEN 'Anonymous'
      ELSE (SELECT full_name FROM public.user_profiles WHERE user_id = NEW.sender_id)
    END || ' that is now ready to open.'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: create_audit_log
-- ============================================================================
-- WHAT: Creates audit log entry for capsule/recipient changes
-- WHY: Tracks all changes for security auditing, compliance (GDPR), and debugging.
--      Stores full change history (old and new row data) in JSONB metadata.
--      Bypasses RLS (SECURITY DEFINER) to insert audit logs even if user lacks permission.
-- USAGE:
--   - Called automatically by triggers on capsules and recipients tables
--   - Runs AFTER INSERT OR UPDATE OR DELETE
--   - No manual calls needed
-- BEHAVIOR:
--   - Attempts to get user_id from JWT claims (for trigger context)
--   - Falls back to auth.uid() if JWT not available
--   - Stores action (INSERT, UPDATE, DELETE), table name, old/new row data
-- EXAMPLES:
--   - User creates recipient: INSERT INTO recipients ...
--     → Audit log: action = 'INSERT', metadata = {table: 'recipients', new: {...}}
--   - User updates capsule: UPDATE capsules SET title = '...' WHERE id = '...'
--     → Audit log: action = 'UPDATE', metadata = {table: 'capsules', old: {...}, new: {...}}
--   - User deletes recipient: DELETE FROM recipients WHERE id = '...'
--     → Audit log: action = 'DELETE', metadata = {table: 'recipients', old: {...}}
-- SECURITY: SECURITY DEFINER bypasses RLS to insert audit logs
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_audit_log()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Try to get user ID from JWT claims (for trigger context)
  BEGIN
    v_user_id := (current_setting('request.jwt.claims', true)::json->>'sub')::UUID;
  EXCEPTION WHEN OTHERS THEN
    -- If not available, try auth.uid() (may not work in triggers)
    BEGIN
      v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
      v_user_id := NULL;
    END;
  END;
  
  -- Insert audit log (bypasses RLS via SECURITY DEFINER)
  INSERT INTO public.audit_logs (user_id, action, capsule_id, metadata)
  VALUES (
    v_user_id,
    TG_OP, -- INSERT, UPDATE, DELETE
    COALESCE(NEW.id, OLD.id),
    jsonb_build_object(
      'table', TG_TABLE_NAME,
      'old', to_jsonb(OLD),
      'new', to_jsonb(NEW)
    )
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: update_updated_at
-- ============================================================================
-- WHAT: Automatically updates updated_at timestamp on row modification
-- WHY: Maintains accurate last-modified timestamps without manual updates.
--      Used by multiple tables (user_profiles, recipients, capsules, subscriptions).
--      Ensures updated_at is always current when row changes.
-- USAGE:
--   - Called automatically by triggers on tables with updated_at column
--   - Runs BEFORE UPDATE
--   - No manual calls needed
-- BEHAVIOR:
--   - Sets NEW.updated_at = NOW() before row is updated
--   - Works on any table with updated_at column
-- EXAMPLES:
--   - User updates profile: UPDATE user_profiles SET full_name = 'John' WHERE user_id = '...'
--     → updated_at automatically set to current timestamp
--   - User updates recipient: UPDATE recipients SET name = 'Sarah' WHERE id = '...'
--     → updated_at automatically set to current timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: delete_expired_disappearing_messages
-- ============================================================================
-- WHAT: Soft-deletes disappearing messages that have expired
-- WHY: Automates cleanup of disappearing messages after they've been open for specified duration.
--      Called by pg_cron job every minute to check for expired messages.
--      Uses soft delete (deleted_at) to preserve data for audit while hiding from users.
-- USAGE:
--   - Called automatically by pg_cron job every minute
--   - Can be called manually: SELECT delete_expired_disappearing_messages()
-- LOGIC:
--   - Finds capsules where: is_disappearing = TRUE, opened_at IS NOT NULL, deleted_at IS NULL
--   - Checks if: opened_at + disappearing_after_open_seconds <= NOW()
--   - Sets deleted_at = NOW() for expired messages
-- EXAMPLES:
--   - Message opened at 10:00:00, disappearing_after_open_seconds = 60
--     At 10:01:00: deleted_at = NOW() (message soft-deleted)
--   - Message opened at 10:00:00, disappearing_after_open_seconds = 3600 (1 hour)
--     At 11:00:00: deleted_at = NOW() (message soft-deleted)
-- IDEMPOTENCY: Safe to call multiple times (only updates if conditions met)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_expired_disappearing_messages()
RETURNS void AS $$
BEGIN
  UPDATE public.capsules
  SET deleted_at = NOW()
  WHERE is_disappearing = TRUE
    AND opened_at IS NOT NULL
    AND deleted_at IS NULL
    AND (opened_at + (disappearing_after_open_seconds || ' seconds')::INTERVAL) <= NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: send_unlock_soon_notifications
-- ============================================================================
-- WHAT: Sends notifications for capsules unlocking in next 24 hours
-- WHY: Proactively notifies recipients before letters unlock, improving engagement.
--      Called by pg_cron job every hour to check for upcoming unlocks.
--      Bypasses RLS (SECURITY DEFINER) to insert notifications.
-- USAGE:
--   - Called automatically by pg_cron job every hour
--   - Can be called manually: SELECT send_unlock_soon_notifications()
-- LOGIC:
--   - Finds capsules where: status = 'sealed', unlocks_at BETWEEN NOW() AND NOW() + 24 hours
--   - Checks for existing 'unlock_soon' notifications (prevents duplicates)
--   - Creates notification for recipient with type 'unlock_soon'
-- EXAMPLES:
--   - Capsule unlocks at 2025-12-25 00:00:00, current time is 2025-12-24 01:00:00
--     → Recipient gets notification: "You have a letter from John that will unlock in 24 hours"
--   - Capsule unlocks at 2025-12-25 00:00:00, current time is 2025-12-24 23:00:00
--     → Recipient gets notification: "You have a letter from Sarah that will unlock in 1 hour"
-- IDEMPOTENCY: Checks for existing notifications to prevent duplicates
-- SECURITY: SECURITY DEFINER bypasses RLS to insert notifications
-- ============================================================================
CREATE OR REPLACE FUNCTION public.send_unlock_soon_notifications()
RETURNS void 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recipient_owner_id UUID;
  sender_name TEXT;
  recipient_name TEXT;
BEGIN
  FOR recipient_owner_id, sender_name, recipient_name IN
    SELECT DISTINCT
      r.owner_id,
      COALESCE(up.full_name, 'Someone'),
      r.name
    FROM public.capsules c
    JOIN public.recipients r ON c.recipient_id = r.id
    LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
    WHERE c.status = 'sealed'
      AND c.unlocks_at BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
      AND c.deleted_at IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.notifications n
        WHERE n.user_id = r.owner_id
          AND n.capsule_id = c.id
          AND n.type = 'unlock_soon'
      )
  LOOP
    -- Insert notification (bypasses RLS via SECURITY DEFINER)
    INSERT INTO public.notifications (user_id, type, capsule_id, title, body)
    SELECT 
      recipient_owner_id,
      'unlock_soon',
      c.id,
      'Letter unlocking soon',
      'You have a letter from ' || sender_name || ' that will unlock in 24 hours.'
    FROM public.capsules c
    JOIN public.recipients r ON c.recipient_id = r.id
    WHERE r.owner_id = recipient_owner_id
      AND c.status = 'sealed'
      AND c.unlocks_at BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
      AND c.deleted_at IS NULL
    LIMIT 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

