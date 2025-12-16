-- ============================================================================
-- Connection Notifications Migration
-- Database triggers for connection request notifications
-- ============================================================================

-- ============================================================================
-- FUNCTION: notify_connection_request
-- ============================================================================
-- WHAT: Creates notification when a new connection request is created
-- WHY: Notifies the receiver that someone wants to connect
-- USAGE: Called automatically by trigger when connection request is created
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_connection_request()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  from_display_name TEXT;
BEGIN
  -- Get sender's display name
  SELECT COALESCE(
    NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
    up.first_name,
    up.last_name,
    up.username,
    'Someone'
  ) INTO from_display_name
  FROM public.user_profiles up
  WHERE up.user_id = NEW.from_user_id;

  -- Create notification for receiver
  INSERT INTO public.notifications (user_id, type, title, body)
  VALUES (
    NEW.to_user_id,
    'new_capsule', -- Reusing notification_type enum, or add 'connection_request' type
    'New Connection Request',
    from_display_name || ' wants to connect with you on OpenOn.'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: notify_connection_accepted
-- ============================================================================
-- WHAT: Creates notification when a connection request is accepted
-- WHY: Notifies the sender that their request was accepted
-- USAGE: Called automatically by trigger when request status changes to 'accepted'
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_connection_accepted()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  to_display_name TEXT;
BEGIN
  -- Only notify on status change to accepted
  IF OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
    -- Get receiver's display name (who accepted)
    SELECT COALESCE(
      NULLIF(TRIM(up.first_name || ' ' || up.last_name), ''),
      up.first_name,
      up.last_name,
      up.username,
      'Someone'
    ) INTO to_display_name
    FROM public.user_profiles up
    WHERE up.user_id = NEW.to_user_id;

    -- Create notification for sender
    INSERT INTO public.notifications (user_id, type, title, body)
    VALUES (
      NEW.from_user_id,
      'new_capsule', -- Reusing notification_type enum
      'Connection Request Accepted',
      'Your connection request to ' || to_display_name || ' was accepted! You can now send letters.'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGER: trigger_notify_connection_request
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_notify_connection_request ON public.connection_requests;
CREATE TRIGGER trigger_notify_connection_request
  AFTER INSERT ON public.connection_requests
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION public.notify_connection_request();

-- ============================================================================
-- TRIGGER: trigger_notify_connection_accepted
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_notify_connection_accepted ON public.connection_requests;
CREATE TRIGGER trigger_notify_connection_accepted
  AFTER UPDATE ON public.connection_requests
  FOR EACH ROW
  WHEN (OLD.status != 'accepted' AND NEW.status = 'accepted')
  EXECUTE FUNCTION public.notify_connection_accepted();

-- Grant execute permissions (functions are SECURITY DEFINER, so no grants needed)
-- But revoke public access for security
REVOKE EXECUTE ON FUNCTION public.notify_connection_request() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.notify_connection_accepted() FROM PUBLIC;
