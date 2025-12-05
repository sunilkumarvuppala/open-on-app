-- ============================================================================
-- Initial Database Schema Migration
-- This migration creates all tables, enums, and basic structure
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Capsule status enum
DO $$ BEGIN
    CREATE TYPE capsule_status AS ENUM (
      'sealed',      -- Locked, not yet ready to open
      'ready',        -- Unlocked and ready to open
      'opened',       -- Has been opened by recipient
      'expired'       -- Past expiration date or deleted
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Notification type enum
DO $$ BEGIN
    CREATE TYPE notification_type AS ENUM (
      'unlock_soon',           -- Capsule will unlock soon (24h before)
      'unlocked',              -- Capsule is now ready to open
      'new_capsule',            -- New capsule received
      'disappearing_warning',   -- Disappearing message will delete soon
      'subscription_expiring',  -- Premium subscription expiring
      'subscription_expired'    -- Premium subscription expired
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Subscription status enum
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM (
      'active',
      'canceled',
      'past_due',
      'trialing',
      'incomplete',
      'incomplete_expired'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- TABLES
-- ============================================================================

-- User Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
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

-- Recipients (Contacts)
CREATE TABLE IF NOT EXISTS public.recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  CONSTRAINT recipients_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT recipients_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Themes
CREATE TABLE IF NOT EXISTS public.themes (
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

-- Animations
CREATE TABLE IF NOT EXISTS public.animations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  preview_url TEXT,
  premium_only BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Capsules (Letters)
CREATE TABLE IF NOT EXISTS public.capsules (
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
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  CONSTRAINT capsules_unlocks_future CHECK (unlocks_at > created_at),
  CONSTRAINT capsules_disappearing_seconds CHECK (
    (is_disappearing = FALSE) OR 
    (is_disappearing = TRUE AND disappearing_after_open_seconds IS NOT NULL AND disappearing_after_open_seconds > 0)
  ),
  CONSTRAINT capsules_body_content CHECK (
    body_text IS NOT NULL OR body_rich_text IS NOT NULL
  )
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  delivered BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- User Subscriptions (Premium)
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
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
  
  CONSTRAINT subscriptions_ends_after_start CHECK (ends_at > started_at)
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

