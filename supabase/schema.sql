-- ============================================================================
-- OpenOn Supabase Database Schema
-- Production-ready schema for time-locked letters app
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Capsule status enum
CREATE TYPE capsule_status AS ENUM (
  'sealed',      -- Locked, not yet ready to open
  'ready',        -- Unlocked and ready to open
  'opened',       -- Has been opened by recipient
  'expired'       -- Past expiration date or deleted
);

-- Notification type enum
CREATE TYPE notification_type AS ENUM (
  'unlock_soon',           -- Capsule will unlock soon (24h before)
  'unlocked',              -- Capsule is now ready to open
  'new_capsule',            -- New capsule received
  'disappearing_warning',   -- Disappearing message will delete soon
  'subscription_expiring',  -- Premium subscription expiring
  'subscription_expired'    -- Premium subscription expired
);

-- Subscription status enum
CREATE TYPE subscription_status AS ENUM (
  'active',
  'canceled',
  'past_due',
  'trialing',
  'incomplete',
  'incomplete_expired'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- User Profiles (extends auth.users)
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  premium_status BOOLEAN DEFAULT FALSE NOT NULL,
  premium_until TIMESTAMPTZ,
  country TEXT,
  device_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for user_profiles
CREATE INDEX idx_user_profiles_premium ON public.user_profiles(premium_status, premium_until);
CREATE INDEX idx_user_profiles_country ON public.user_profiles(country);

-- ----------------------------------------------------------------------------
-- Recipients (Contacts)
-- ----------------------------------------------------------------------------
CREATE TABLE public.recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT recipients_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT recipients_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes for recipients
CREATE INDEX idx_recipients_owner ON public.recipients(owner_id);
CREATE INDEX idx_recipients_owner_created ON public.recipients(owner_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- Themes
-- ----------------------------------------------------------------------------
CREATE TABLE public.themes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  gradient_start TEXT NOT NULL,
  gradient_end TEXT NOT NULL,
  preview_url TEXT,
  premium_only BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for themes
CREATE INDEX idx_themes_premium ON public.themes(premium_only);
CREATE INDEX idx_themes_name ON public.themes(name);

-- ----------------------------------------------------------------------------
-- Animations
-- ----------------------------------------------------------------------------
CREATE TABLE public.animations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  preview_url TEXT,
  premium_only BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for animations
CREATE INDEX idx_animations_premium ON public.animations(premium_only);
CREATE INDEX idx_animations_name ON public.animations(name);

-- ----------------------------------------------------------------------------
-- Capsules (Letters)
-- ----------------------------------------------------------------------------
CREATE TABLE public.capsules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.recipients(id) ON DELETE CASCADE,
  is_anonymous BOOLEAN DEFAULT FALSE NOT NULL,
  is_disappearing BOOLEAN DEFAULT FALSE NOT NULL,
  disappearing_after_open_seconds INTEGER,
  unlocks_at TIMESTAMPTZ NOT NULL,
  opened_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  title TEXT,
  body_text TEXT,
  body_rich_text JSONB,
  theme_id UUID REFERENCES public.themes(id) ON DELETE SET NULL,
  animation_id UUID REFERENCES public.animations(id) ON DELETE SET NULL,
  status capsule_status DEFAULT 'sealed' NOT NULL,
  deleted_at TIMESTAMPTZ, -- Soft delete for disappearing messages
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT capsules_unlocks_future CHECK (unlocks_at > created_at),
  CONSTRAINT capsules_disappearing_seconds CHECK (
    (is_disappearing = FALSE) OR 
    (is_disappearing = TRUE AND disappearing_after_open_seconds IS NOT NULL AND disappearing_after_open_seconds > 0)
  ),
  CONSTRAINT capsules_body_content CHECK (
    body_text IS NOT NULL OR body_rich_text IS NOT NULL
  )
);

-- Indexes for capsules
CREATE INDEX idx_capsules_sender ON public.capsules(sender_id, created_at DESC);
CREATE INDEX idx_capsules_recipient ON public.capsules(recipient_id, created_at DESC);
CREATE INDEX idx_capsules_status ON public.capsules(status);
CREATE INDEX idx_capsules_unlocks_at ON public.capsules(unlocks_at) WHERE status = 'sealed';
CREATE INDEX idx_capsules_opened_at ON public.capsules(opened_at) WHERE is_disappearing = TRUE;
CREATE INDEX idx_capsules_deleted_at ON public.capsules(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_capsules_recipient_status ON public.capsules(recipient_id, status, created_at DESC);
CREATE INDEX idx_capsules_sender_status ON public.capsules(sender_id, status, created_at DESC);

-- ----------------------------------------------------------------------------
-- Notifications
-- ----------------------------------------------------------------------------
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  delivered BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_delivered ON public.notifications(user_id, delivered) WHERE delivered = FALSE;
CREATE INDEX idx_notifications_capsule ON public.notifications(capsule_id);

-- ----------------------------------------------------------------------------
-- User Subscriptions (Premium)
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status subscription_status NOT NULL,
  provider TEXT NOT NULL DEFAULT 'stripe',
  plan_id TEXT NOT NULL,
  stripe_subscription_id TEXT UNIQUE,
  started_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  cancel_at_period_end BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT subscriptions_ends_after_start CHECK (ends_at > started_at)
);

-- Indexes for subscriptions
CREATE INDEX idx_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX idx_subscriptions_ends_at ON public.user_subscriptions(ends_at) WHERE status = 'active';
CREATE INDEX idx_subscriptions_stripe ON public.user_subscriptions(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- Audit Logs
-- ----------------------------------------------------------------------------
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for audit_logs
CREATE INDEX idx_audit_logs_user ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_capsule ON public.audit_logs(capsule_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Recipient-safe capsules view (hides sender for anonymous messages)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.recipient_safe_capsules_view AS
SELECT 
  c.id,
  CASE 
    WHEN c.is_anonymous = TRUE THEN NULL
    ELSE c.sender_id
  END AS sender_id,
  CASE 
    WHEN c.is_anonymous = TRUE THEN 'Anonymous'
    ELSE up.full_name
  END AS sender_name,
  CASE 
    WHEN c.is_anonymous = TRUE THEN NULL
    ELSE up.avatar_url
  END AS sender_avatar_url,
  c.recipient_id,
  r.name AS recipient_name,
  c.is_anonymous,
  c.is_disappearing,
  c.disappearing_after_open_seconds,
  c.unlocks_at,
  c.opened_at,
  c.expires_at,
  c.title,
  c.body_text,
  c.body_rich_text,
  c.theme_id,
  c.animation_id,
  c.status,
  c.deleted_at,
  c.created_at,
  c.updated_at
FROM public.capsules c
LEFT JOIN public.recipients r ON c.recipient_id = r.id
LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
WHERE c.deleted_at IS NULL;

-- ----------------------------------------------------------------------------
-- Inbox view (capsules received by current user)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.inbox_view AS
SELECT 
  c.*,
  r.owner_id AS current_user_id
FROM public.recipient_safe_capsules_view c
JOIN public.recipients r ON c.recipient_id = r.id
WHERE r.owner_id = auth.uid()
  AND c.deleted_at IS NULL;

-- ----------------------------------------------------------------------------
-- Outbox view (capsules sent by current user)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.outbox_view AS
SELECT 
  c.*
FROM public.capsules c
WHERE c.sender_id = auth.uid()
  AND c.deleted_at IS NULL;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: Update capsule status based on time
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Function: Handle capsule opening
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Function: Create unlock notification
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Function: Create audit log entry
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Function: Update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Function: Delete expired disappearing messages
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Function: Send unlock soon notifications
-- ----------------------------------------------------------------------------
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

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update capsule status on insert/update
CREATE TRIGGER trigger_update_capsule_status
  BEFORE INSERT OR UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_capsule_status();

-- Handle capsule opening
CREATE TRIGGER trigger_handle_capsule_opened
  BEFORE UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL)
  EXECUTE FUNCTION public.handle_capsule_opened();

-- Notify when capsule becomes ready
CREATE TRIGGER trigger_notify_capsule_unlocked
  AFTER UPDATE ON public.capsules
  FOR EACH ROW
  WHEN (OLD.status = 'sealed' AND NEW.status = 'ready')
  EXECUTE FUNCTION public.notify_capsule_unlocked();

-- Update updated_at timestamps
CREATE TRIGGER trigger_update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trigger_update_recipients_updated_at
  BEFORE UPDATE ON public.recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trigger_update_capsules_updated_at
  BEFORE UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trigger_update_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Audit logging
CREATE TRIGGER trigger_audit_capsules
  AFTER INSERT OR UPDATE OR DELETE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.create_audit_log();

CREATE TRIGGER trigger_audit_recipients
  AFTER INSERT OR UPDATE OR DELETE ON public.recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.create_audit_log();

-- ============================================================================
-- SCHEDULED JOBS (pg_cron)
-- ============================================================================

-- Delete expired disappearing messages every minute
SELECT cron.schedule(
  'delete-expired-disappearing-messages',
  '* * * * *', -- Every minute
  $$SELECT public.delete_expired_disappearing_messages();$$
);

-- Send unlock soon notifications every hour
SELECT cron.schedule(
  'send-unlock-soon-notifications',
  '0 * * * *', -- Every hour
  $$SELECT public.send_unlock_soon_notifications();$$
);

-- Update premium status based on subscriptions (daily)
SELECT cron.schedule(
  'update-premium-status',
  '0 0 * * *', -- Daily at midnight
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
);

