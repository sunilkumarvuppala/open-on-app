-- ============================================================================
-- Functions Migration
-- Database functions for automation
-- ============================================================================

-- Function: Update capsule status based on time
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

-- Function: Handle capsule opening
CREATE OR REPLACE FUNCTION public.handle_capsule_opened()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if opening for the first time
  IF OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL THEN
    NEW.status := 'opened';
    
    -- Create notification for sender
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

-- Function: Create unlock notification
CREATE OR REPLACE FUNCTION public.notify_capsule_unlocked()
RETURNS TRIGGER AS $$
DECLARE
  recipient_owner_id UUID;
  recipient_name TEXT;
BEGIN
  -- Get recipient owner
  SELECT owner_id, name INTO recipient_owner_id, recipient_name
  FROM public.recipients
  WHERE id = NEW.recipient_id;
  
  -- Create notification for recipient
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

-- Function: Create audit log entry
CREATE OR REPLACE FUNCTION public.create_audit_log()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.audit_logs (user_id, action, capsule_id, metadata)
  VALUES (
    auth.uid(),
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

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Delete expired disappearing messages
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

-- Function: Send unlock soon notifications
CREATE OR REPLACE FUNCTION public.send_unlock_soon_notifications()
RETURNS void AS $$
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

