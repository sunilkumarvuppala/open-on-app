-- ============================================================================
-- CONSOLIDATED DATABASE SCHEMA - Production Ready for 1M+ Users
-- ============================================================================
-- WHAT: Complete database schema with all optimizations merged
-- WHY: Single migration file for fresh database setup
--      All indexes, constraints, and optimizations included
--      Optimized for 1,000,000+ concurrent users
-- ============================================================================
-- This migration consolidates:
-- - 01_enums_and_tables.sql (base schema)
-- - 02_indexes.sql (base indexes)
-- - 18_add_linked_user_id_to_recipients.sql (linked_user_id column + indexes)
-- - 20_production_index_optimizations.sql (additional indexes)
-- - 21_add_unique_constraint_recipients.sql (unique constraint)
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================================
-- ENUMS (must be created before tables)
-- ============================================================================

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

DO $$ BEGIN
    CREATE TYPE notification_type AS ENUM (
      'unlock_soon',
      'unlocked',
      'new_capsule',
      'disappearing_warning',
      'subscription_expiring',
      'subscription_expired'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

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

DO $$ BEGIN
    CREATE TYPE recipient_relationship AS ENUM (
      'friend',
      'family',
      'partner',
      'colleague',
      'acquaintance',
      'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- TABLES
-- ============================================================================

-- User Profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  username TEXT,
  avatar_url TEXT,
  premium_status BOOLEAN DEFAULT FALSE NOT NULL,
  premium_until TIMESTAMPTZ,
  is_admin BOOLEAN DEFAULT FALSE NOT NULL,
  country TEXT,
  device_token TEXT,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Recipients (with linked_user_id for connection-based recipients)
CREATE TABLE IF NOT EXISTS public.recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  relationship recipient_relationship DEFAULT 'friend',
  linked_user_id UUID, -- Connection user ID (NULL for email-based recipients)
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

-- Capsules (time-locked letters)
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
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  delivered BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- User Subscriptions
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
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Connection Requests
CREATE TABLE IF NOT EXISTS public.connection_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')) DEFAULT 'pending',
  message TEXT,
  declined_reason TEXT,
  acted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT connection_requests_unique_pending UNIQUE (from_user_id, to_user_id) 
    DEFERRABLE INITIALLY DEFERRED
);

-- Connections (mutual friendships)
CREATE TABLE IF NOT EXISTS public.connections (
  user_id_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  connected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (user_id_1, user_id_2),
  CONSTRAINT connections_user_order CHECK (user_id_1 < user_id_2)
);

-- Blocked Users
CREATE TABLE IF NOT EXISTS public.blocked_users (
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT blocked_users_no_self_block CHECK (blocker_id != blocked_id)
);

-- ============================================================================
-- INDEXES - Production Optimized for 1M+ Users
-- ============================================================================

-- User Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_premium ON public.user_profiles(premium_status, premium_until);
CREATE INDEX IF NOT EXISTS idx_user_profiles_country ON public.user_profiles(country);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_admin ON public.user_profiles(is_admin) WHERE is_admin = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username) WHERE username IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_login ON public.user_profiles(last_login) WHERE last_login IS NOT NULL;

-- Recipients Indexes (CRITICAL for performance)
-- Base indexes
CREATE INDEX IF NOT EXISTS idx_recipients_owner ON public.recipients(owner_id);
CREATE INDEX IF NOT EXISTS idx_recipients_owner_created ON public.recipients(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipients_relationship ON public.recipients(owner_id, relationship);
CREATE INDEX IF NOT EXISTS idx_recipients_email ON public.recipients(owner_id, email) WHERE email IS NOT NULL;

-- Connection-based recipient indexes (linked_user_id)
-- CRITICAL: These support letter counting and recipient lookups by connection user
CREATE INDEX IF NOT EXISTS idx_recipients_owner_linked_user 
  ON public.recipients(owner_id, linked_user_id) 
  WHERE linked_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_recipients_linked_user_owner 
  ON public.recipients(linked_user_id, owner_id) 
  WHERE linked_user_id IS NOT NULL;

-- Unique constraint to prevent duplicate connection-based recipients
-- CRITICAL: Prevents race conditions from creating duplicate recipients
CREATE UNIQUE INDEX IF NOT EXISTS idx_recipients_owner_linked_user_unique
  ON public.recipients(owner_id, linked_user_id)
  WHERE linked_user_id IS NOT NULL;

-- Email-based recipient lookup (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_recipients_email_lower
  ON public.recipients(owner_id, LOWER(email))
  WHERE email IS NOT NULL;

-- Name-based lookup (for connection-based matching)
CREATE INDEX IF NOT EXISTS idx_recipients_name_lower
  ON public.recipients(owner_id, LOWER(TRIM(name)))
  WHERE email IS NULL;

-- Capsule recipient index (for inbox queries joining capsules with recipients)
CREATE INDEX IF NOT EXISTS idx_capsules_recipient_deleted_created 
  ON public.capsules(recipient_id, deleted_at, created_at DESC) 
  WHERE deleted_at IS NULL;

-- Themes Indexes
CREATE INDEX IF NOT EXISTS idx_themes_premium ON public.themes(premium_only);
CREATE INDEX IF NOT EXISTS idx_themes_name ON public.themes(name);

-- Animations Indexes
CREATE INDEX IF NOT EXISTS idx_animations_premium ON public.animations(premium_only);
CREATE INDEX IF NOT EXISTS idx_animations_name ON public.animations(name);

-- Capsules Indexes (CRITICAL for 1M+ users)
-- Base indexes with deleted_at filtering
CREATE INDEX IF NOT EXISTS idx_capsules_sender_deleted_created
  ON public.capsules(sender_id, deleted_at, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_recipient_deleted_created
  ON public.capsules(recipient_id, deleted_at, created_at DESC)
  WHERE deleted_at IS NULL;

-- Status filtering
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules(status);

-- Cron job indexes (partial for efficiency)
CREATE INDEX IF NOT EXISTS idx_capsules_unlocks_at
  ON public.capsules(unlocks_at)
  WHERE status = 'sealed' AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_opened_at
  ON public.capsules(opened_at)
  WHERE is_disappearing = TRUE AND deleted_at IS NULL;

-- Composite indexes for filtered queries
CREATE INDEX IF NOT EXISTS idx_capsules_recipient_status_deleted_created
  ON public.capsules(recipient_id, status, deleted_at, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_sender_status_deleted_created
  ON public.capsules(sender_id, status, deleted_at, created_at DESC)
  WHERE deleted_at IS NULL;

-- Letter count indexes (CRITICAL for connection detail page)
-- These support queries like: COUNT(*) WHERE sender_id = X AND recipient_id = Y
CREATE INDEX IF NOT EXISTS idx_capsules_sender_recipient_deleted
  ON public.capsules(sender_id, recipient_id, deleted_at)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_recipient_sender_deleted
  ON public.capsules(recipient_id, sender_id, deleted_at)
  WHERE deleted_at IS NULL;

-- Foreign key indexes (for JOINs)
CREATE INDEX IF NOT EXISTS idx_capsules_theme_id 
  ON public.capsules(theme_id) 
  WHERE theme_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_animation_id 
  ON public.capsules(animation_id) 
  WHERE animation_id IS NOT NULL;

-- Composite indexes for cron jobs
CREATE INDEX IF NOT EXISTS idx_capsules_status_unlocks_at 
  ON public.capsules(status, unlocks_at) 
  WHERE status = 'sealed' AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_capsules_disappearing_opened 
  ON public.capsules(is_disappearing, opened_at) 
  WHERE is_disappearing = TRUE AND deleted_at IS NULL;

-- Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_capsule ON public.notifications(capsule_id);
CREATE INDEX IF NOT EXISTS idx_notifications_delivered ON public.notifications(user_id, delivered) WHERE delivered = FALSE;

-- User Subscriptions Indexes
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_stripe ON public.user_subscriptions(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;

-- Audit Logs Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_capsule ON public.audit_logs(capsule_id);

-- Connection Requests Indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_connection_requests_unique_pending 
  ON public.connection_requests(from_user_id, to_user_id) 
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_connection_requests_to_user_id 
  ON public.connection_requests(to_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_connection_requests_from_user_id 
  ON public.connection_requests(from_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_connection_requests_status 
  ON public.connection_requests(status) 
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_connection_requests_from_to_status 
  ON public.connection_requests(from_user_id, to_user_id, status);

-- Connections Indexes (optimized for UNION ALL queries)
CREATE INDEX IF NOT EXISTS idx_connections_user1 
  ON public.connections(user_id_1);

CREATE INDEX IF NOT EXISTS idx_connections_user2 
  ON public.connections(user_id_2);

CREATE INDEX IF NOT EXISTS idx_connections_user1_connected_at
  ON public.connections(user_id_1, connected_at DESC);

CREATE INDEX IF NOT EXISTS idx_connections_user2_connected_at
  ON public.connections(user_id_2, connected_at DESC);

-- Blocked Users Indexes
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker 
  ON public.blocked_users(blocker_id);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked 
  ON public.blocked_users(blocked_id);

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON COLUMN public.recipients.linked_user_id IS 
'If set, this recipient represents a connection to another user. The linked_user_id is the UUID of the connected user (from auth.users). This allows querying recipients by connection user ID for accurate letter counting.';

-- ============================================================================
-- STATISTICS UPDATE (for Query Planner)
-- ============================================================================
-- Update table statistics to help PostgreSQL query planner make better decisions
-- This is especially important for optimal query planning at scale
ANALYZE public.capsules;
ANALYZE public.recipients;
ANALYZE public.user_profiles;
ANALYZE public.connections;
ANALYZE public.connection_requests;
ANALYZE public.blocked_users;
ANALYZE public.notifications;
ANALYZE public.user_subscriptions;
ANALYZE public.audit_logs;

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- After this migration:
-- - All tables created with UUID primary keys
-- - All foreign keys reference UUIDs
-- - All indexes optimized for 1M+ users
-- - Unique constraints prevent duplicates
-- - Partial indexes reduce index size
-- - Statistics updated for optimal query planning
-- ============================================================================

