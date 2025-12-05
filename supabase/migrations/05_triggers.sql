-- ============================================================================
-- Triggers Migration
-- Database triggers for automation
-- ============================================================================

-- ============================================================================
-- TRIGGER: trigger_update_capsule_status
-- ============================================================================
-- WHAT: Automatically updates capsule status based on unlock time
-- WHY: Ensures status is always correct when capsule is created or updated.
--      Prevents manual status management and keeps data consistent.
-- WHEN: BEFORE INSERT OR UPDATE on capsules table
-- FUNCTION: update_capsule_status()
-- EXAMPLES:
--   - Insert capsule with unlocks_at = future: Status set to 'sealed'
--   - Update unlocks_at to past: Status automatically changes to 'ready'
--   - Insert capsule with expires_at = past: Status set to 'expired'
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_update_capsule_status ON public.capsules;
CREATE TRIGGER trigger_update_capsule_status
  BEFORE INSERT OR UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_capsule_status();

-- ============================================================================
-- TRIGGER: trigger_handle_capsule_opened
-- ============================================================================
-- WHAT: Handles capsule opening event (status, notification, deletion scheduling)
-- WHY: Automates actions when capsule is opened for the first time.
--      Ensures sender is notified and disappearing messages are scheduled.
-- WHEN: BEFORE UPDATE on capsules, only when opened_at changes from NULL to NOT NULL
-- FUNCTION: handle_capsule_opened()
-- EXAMPLES:
--   - User opens letter: UPDATE capsules SET opened_at = NOW() WHERE id = '...'
--     → Status changes to 'opened'
--     → Sender gets notification
--     → If disappearing: deleted_at scheduled
--   - Update opened_at again: No trigger (already opened)
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_handle_capsule_opened ON public.capsules;
CREATE TRIGGER trigger_handle_capsule_opened
  BEFORE UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL) -- Only on first open
  EXECUTE FUNCTION public.handle_capsule_opened();

-- ============================================================================
-- TRIGGER: trigger_notify_capsule_unlocked
-- ============================================================================
-- WHAT: Creates notification when capsule becomes ready to open
-- WHY: Notifies recipient when their letter unlocks, improving engagement.
--      Only triggers on status transition (sealed → ready) to prevent duplicates.
-- WHEN: AFTER UPDATE on capsules, only when status changes from 'sealed' to 'ready'
-- FUNCTION: notify_capsule_unlocked()
-- EXAMPLES:
--   - Capsule unlocks: Status changes from 'sealed' to 'ready'
--     → Recipient gets notification: "A letter is ready to open"
--   - Status changes from 'ready' to 'opened': No trigger (already unlocked)
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_notify_capsule_unlocked ON public.capsules;
CREATE TRIGGER trigger_notify_capsule_unlocked
  AFTER UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.status = 'sealed' AND NEW.status = 'ready') -- Only on unlock
  EXECUTE FUNCTION public.notify_capsule_unlocked();

-- ============================================================================
-- TRIGGERS: Update updated_at timestamps
-- ============================================================================
-- WHAT: Automatically updates updated_at timestamp when row is modified
-- WHY: Maintains accurate last-modified timestamps without manual updates.
--      Used by multiple tables to track when data was last changed.
-- WHEN: BEFORE UPDATE on tables with updated_at column
-- FUNCTION: update_updated_at()
-- TABLES: user_profiles, recipients, capsules, user_subscriptions
-- EXAMPLES:
--   - Update profile: UPDATE user_profiles SET full_name = '...' WHERE user_id = '...'
--     → updated_at automatically set to current timestamp
--   - Update recipient: UPDATE recipients SET name = '...' WHERE id = '...'
--     → updated_at automatically set to current timestamp
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER trigger_update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_recipients_updated_at ON public.recipients;
CREATE TRIGGER trigger_update_recipients_updated_at
  BEFORE UPDATE ON public.recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_capsules_updated_at ON public.capsules;
CREATE TRIGGER trigger_update_capsules_updated_at
  BEFORE UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER trigger_update_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- TRIGGERS: Audit logging
-- ============================================================================
-- WHAT: Creates audit log entry for all changes to critical tables
-- WHY: Tracks all changes for security auditing, compliance (GDPR), and debugging.
--      Stores full change history (old and new row data) for investigation.
-- WHEN: AFTER INSERT OR UPDATE OR DELETE on capsules and recipients tables
-- FUNCTION: create_audit_log()
-- TABLES: capsules, recipients
-- EXAMPLES:
--   - Create capsule: INSERT INTO capsules ...
--     → Audit log: action = 'INSERT', metadata = {table: 'capsules', new: {...}}
--   - Update capsule: UPDATE capsules SET title = '...' WHERE id = '...'
--     → Audit log: action = 'UPDATE', metadata = {table: 'capsules', old: {...}, new: {...}}
--   - Delete recipient: DELETE FROM recipients WHERE id = '...'
--     → Audit log: action = 'DELETE', metadata = {table: 'recipients', old: {...}}
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_audit_capsules ON public.capsules;
CREATE TRIGGER trigger_audit_capsules
  AFTER INSERT OR UPDATE OR DELETE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.create_audit_log();

DROP TRIGGER IF EXISTS trigger_audit_recipients ON public.recipients;
CREATE TRIGGER trigger_audit_recipients
  AFTER INSERT OR UPDATE OR DELETE ON public.recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.create_audit_log();

