-- ============================================================================
-- Triggers Migration
-- Database triggers for automation
-- ============================================================================

-- Update capsule status on insert/update
DROP TRIGGER IF EXISTS trigger_update_capsule_status ON public.capsules;
CREATE TRIGGER trigger_update_capsule_status
  BEFORE INSERT OR UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_capsule_status();

-- Handle capsule opening
DROP TRIGGER IF EXISTS trigger_handle_capsule_opened ON public.capsules;
CREATE TRIGGER trigger_handle_capsule_opened
  BEFORE UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL)
  EXECUTE FUNCTION public.handle_capsule_opened();

-- Notify when capsule becomes ready
DROP TRIGGER IF EXISTS trigger_notify_capsule_unlocked ON public.capsules;
CREATE TRIGGER trigger_notify_capsule_unlocked
  AFTER UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.status = 'sealed' AND NEW.status = 'ready')
  EXECUTE FUNCTION public.notify_capsule_unlocked();

-- Update updated_at timestamps
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

-- Audit logging
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

