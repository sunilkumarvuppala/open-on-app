-- ============================================================================
-- Initial Database Schema Migration
-- Creates all tables, enums, and basic structure
-- Requires: Supabase Auth (auth.users table)
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================================
-- ENUMS (must be created before tables)
-- ============================================================================

-- ============================================================================
-- ENUM: capsule_status
-- ============================================================================
-- WHAT: Status values for time-locked capsules (letters)
-- WHY: Ensures data integrity by restricting status to valid values only.
--      Prevents invalid states like 'pending' or 'draft' that don't exist.
--      Used by triggers to automatically update status based on time.
-- EXAMPLES:
--   - 'sealed': Capsule created, unlocks_at is in the future
--     Example: User sends letter to unlock on their birthday (next month)
--   - 'ready': unlocks_at has passed, recipient can now open it
--     Example: Birthday arrived, letter is now ready to open
--   - 'opened': Recipient has opened and read the letter
--     Example: User clicked "Open Letter" and viewed the content
--   - 'expired': Letter expired (expires_at passed) or was soft-deleted
--     Example: Letter had 30-day expiration and time ran out
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

-- ============================================================================
-- ENUM: notification_type
-- ============================================================================
-- WHAT: Types of notifications sent to users
-- WHY: Categorizes notifications for filtering, routing, and user preferences.
--      Allows different notification handling (push, email, in-app) based on type.
-- EXAMPLES:
--   - 'unlock_soon': Sent 24h before capsule unlocks
--     Example: "You have a letter from John that will unlock tomorrow"
--   - 'unlocked': Capsule is now ready to open
--     Example: "A letter from Sarah is now ready to open"
--   - 'new_capsule': New capsule received (for future use)
--     Example: "You received a new letter from Mike"
--   - 'disappearing_warning': Disappearing message will delete soon
--     Example: "Your disappearing message will be deleted in 1 hour"
--   - 'subscription_expiring': Premium subscription expiring soon
--     Example: "Your premium subscription expires in 7 days"
--   - 'subscription_expired': Premium subscription has expired
--     Example: "Your premium subscription has expired"
-- ============================================================================
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

-- ============================================================================
-- ENUM: subscription_status
-- ============================================================================
-- WHAT: Subscription status values compatible with Stripe payment system
-- WHY: Matches Stripe's subscription statuses for seamless webhook integration.
--      Ensures consistent status tracking across payment provider and database.
-- EXAMPLES:
--   - 'active': User has active premium subscription
--     Example: User paid $9.99/month, subscription is active
--   - 'canceled': Subscription was canceled but still valid until period end
--     Example: User canceled but can use premium until Dec 31
--   - 'past_due': Payment failed, subscription in grace period
--     Example: Credit card expired, 3 days to update payment
--   - 'trialing': User in free trial period
--     Example: New user gets 7-day free trial
--   - 'incomplete': Initial payment attempt failed
--     Example: User tried to subscribe but payment declined
--   - 'incomplete_expired': Payment attempt expired
--     Example: User never completed payment after 3 days
-- ============================================================================
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
-- ENUM: recipient_relationship
-- ============================================================================
-- WHAT: Relationship types for recipients (contacts)
-- WHY: Allows users to categorize contacts for better organization and filtering.
--      Enables features like "Send to all family members" or relationship-based themes.
-- EXAMPLES:
--   - 'friend': Close friend
--     Example: "Send birthday letter to my friend Sarah"
--   - 'family': Family member
--     Example: "Send anniversary letter to my mom"
--   - 'partner': Romantic partner
--     Example: "Send love letter to my girlfriend"
--   - 'colleague': Work colleague
--     Example: "Send thank you letter to my coworker"
--   - 'acquaintance': Casual acquaintance
--     Example: "Send letter to someone I met at a party"
--   - 'other': Other relationship type
--     Example: "Send letter to my neighbor"
-- ============================================================================
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

-- ============================================================================
-- TABLE: user_profiles
-- ============================================================================
-- WHAT: Extends Supabase Auth users with application-specific profile data
-- WHY: Supabase Auth only provides basic user info (email, password).
--      This table stores app-specific data like premium status, avatar, country.
--      Separates authentication (auth.users) from application data (user_profiles).
-- USAGE EXAMPLES:
--   - Get user profile: SELECT * FROM user_profiles WHERE user_id = auth.uid()
--   - Check premium: SELECT premium_status FROM user_profiles WHERE user_id = '...'
--   - Update avatar: UPDATE user_profiles SET avatar_url = '...' WHERE user_id = '...'
-- COLUMNS:
--   - user_id: Links to Supabase Auth user (CASCADE delete removes profile if user deleted)
--   - first_name: User's first name (e.g., "John")
--   - last_name: User's last name (e.g., "Doe")
--   - username: User's username for searching and display
--   - avatar_url: URL to user's profile picture (e.g., "https://storage.../avatar.jpg")
--   - premium_status: Whether user has active premium subscription
--   - premium_until: When premium subscription expires (NULL if not premium)
--   - is_admin: Admin flag for system administration (can manage themes/animations)
--   - country: User's country for analytics/localization (e.g., "US", "GB")
--   - device_token: Push notification device token (e.g., FCM token for Android)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  username TEXT, -- Username for searching and display
  avatar_url TEXT,
  premium_status BOOLEAN DEFAULT FALSE NOT NULL,
  premium_until TIMESTAMPTZ,
  is_admin BOOLEAN DEFAULT FALSE NOT NULL, -- Admin flag for system administration
  country TEXT,
  device_token TEXT,
  last_login TIMESTAMPTZ, -- Last login timestamp for analytics and security
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- TABLE: recipients
-- ============================================================================
-- WHAT: User's contact list (people they can send letters to)
-- WHY: Users need to store recipient information separately from capsules.
--      Allows reusing contacts across multiple letters and organizing by relationship.
--      Email is optional because users might send to people not in the system.
-- USAGE EXAMPLES:
--   - Get all recipients: SELECT * FROM recipients WHERE owner_id = auth.uid()
--   - Add recipient: INSERT INTO recipients (owner_id, name, email, relationship)
--                    VALUES (auth.uid(), 'Sarah', 'sarah@example.com', 'friend')
--   - Filter by relationship: SELECT * FROM recipients WHERE relationship = 'family'
-- COLUMNS:
--   - id: Unique identifier for recipient
--   - owner_id: User who owns this recipient (CASCADE: deleting user deletes their contacts)
--   - name: Recipient's name (required, cannot be empty after trim)
--   - email: Recipient's email (optional, validated format if provided)
--   - avatar_url: URL to recipient's avatar image
--   - relationship: Relationship type (defaults to 'friend')
-- CONSTRAINTS:
--   - recipients_name_not_empty: Name must have at least 1 non-whitespace character
--   - recipients_email_format: Email must be valid format (regex) if provided
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  relationship recipient_relationship DEFAULT 'friend',
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  CONSTRAINT recipients_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT recipients_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- ============================================================================
-- TABLE: themes
-- ============================================================================
-- WHAT: Visual themes for letter presentation (background gradients, colors)
-- WHY: Allows users to customize letter appearance with different color schemes.
--      Premium themes provide monetization opportunity.
--      Centralized theme management allows admins to add/update themes without app updates.
-- USAGE EXAMPLES:
--   - Get all free themes: SELECT * FROM themes WHERE premium_only = FALSE
--   - Get premium themes: SELECT * FROM themes WHERE premium_only = TRUE
--   - Create theme: INSERT INTO themes (name, gradient_start, gradient_end, premium_only)
--                   VALUES ('Sunset', '#FF6B6B', '#4ECDC4', FALSE)
-- COLUMNS:
--   - id: Unique theme identifier
--   - name: Theme name (unique, e.g., "Deep Blue", "Galaxy Aurora")
--   - description: Theme description for UI display
--   - gradient_start: Start color hex code (e.g., "#1D094B")
--   - gradient_end: End color hex code (e.g., "#3406CA")
--   - preview_url: URL to preview image showing theme appearance
--   - premium_only: Whether theme requires premium subscription
-- ============================================================================
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

-- ============================================================================
-- TABLE: animations
-- ============================================================================
-- WHAT: Reveal animations for letter opening (sparkles, aurora, etc.)
-- WHY: Enhances user experience with engaging animations when letters are opened.
--      Premium animations provide monetization opportunity.
--      Centralized animation management allows admins to add/update without app updates.
-- USAGE EXAMPLES:
--   - Get all animations: SELECT * FROM animations ORDER BY name
--   - Get free animations: SELECT * FROM animations WHERE premium_only = FALSE
--   - Create animation: INSERT INTO animations (name, description, premium_only)
--                       VALUES ('Sparkle Unfold', 'Gentle sparkles', FALSE)
-- COLUMNS:
--   - id: Unique animation identifier
--   - name: Animation name (unique, e.g., "Sparkle Unfold", "Aurora Reveal")
--   - description: Animation description for UI display
--   - preview_url: URL to preview video showing animation
--   - premium_only: Whether animation requires premium subscription
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.animations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  preview_url TEXT,
  premium_only BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- TABLE: capsules
-- ============================================================================
-- WHAT: Time-locked letters (core entity of the application)
-- WHY: This is the main feature - letters that unlock at a specific time.
--      Supports anonymous messages, disappearing messages, and time-based unlocking.
--      Soft deletes (deleted_at) preserve data for audit while hiding from users.
-- USAGE EXAMPLES:
--   - Create capsule: INSERT INTO capsules (sender_id, recipient_id, unlocks_at, body_text)
--                     VALUES (auth.uid(), 'recipient-uuid', '2025-12-25 00:00:00', 'Merry Christmas!')
--   - Get inbox: SELECT * FROM inbox_view WHERE current_user_id = auth.uid()
--   - Get outbox: SELECT * FROM outbox_view WHERE sender_id = auth.uid()
--   - Open capsule: UPDATE capsules SET opened_at = NOW() WHERE id = '...' AND opened_at IS NULL
-- COLUMNS:
--   - id: Unique capsule identifier
--   - sender_id: User who sent the capsule (CASCADE: deleting user deletes their sent capsules)
--   - recipient_id: Recipient of the capsule (CASCADE: deleting recipient deletes capsules)
--   - is_anonymous: Hide sender identity from recipient (for secret admirer letters)
--   - is_disappearing: Delete message after opening (like Snapchat)
--   - disappearing_after_open_seconds: Seconds before deletion (required if is_disappearing = TRUE)
--   - unlocks_at: When capsule becomes available to open (required, must be future)
--   - opened_at: When capsule was opened (NULL if not opened yet)
--   - expires_at: When capsule expires (optional, for time-limited letters)
--   - title: Letter title (optional, e.g., "Happy Birthday!")
--   - body_text: Plain text content (required if body_rich_text is NULL)
--   - body_rich_text: Rich text content as JSONB (required if body_text is NULL)
--   - theme_id: Visual theme (SET NULL: deleting theme doesn't delete capsule, just removes theme)
--   - animation_id: Reveal animation (SET NULL: deleting animation doesn't delete capsule)
--   - status: Current status (auto-updated by trigger based on time)
--   - deleted_at: Soft delete timestamp (NULL if active, set by disappearing message logic)
-- CONSTRAINTS:
--   - capsules_unlocks_future: unlocks_at must be after created_at (can't unlock in past)
--   - capsules_disappearing_seconds: If disappearing, must specify seconds > 0
--   - capsules_body_content: Must have either body_text OR body_rich_text (not both empty)
-- ============================================================================
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

-- ============================================================================
-- TABLE: notifications
-- ============================================================================
-- WHAT: User notifications (unlock alerts, new capsules, subscription reminders)
-- WHY: Centralized notification system for push notifications, in-app alerts, and emails.
--      Tracks delivery status to prevent duplicate notifications.
--      Inserts via SECURITY DEFINER functions (triggers/system) to bypass RLS.
-- USAGE EXAMPLES:
--   - Get user notifications: SELECT * FROM notifications WHERE user_id = auth.uid() ORDER BY created_at DESC
--   - Get undelivered: SELECT * FROM notifications WHERE user_id = auth.uid() AND delivered = FALSE
--   - Mark delivered: UPDATE notifications SET delivered = TRUE WHERE id = '...'
--   - Create notification (via function): INSERT via handle_capsule_opened() or notify_capsule_unlocked()
-- COLUMNS:
--   - id: Unique notification identifier
--   - user_id: User who receives notification (CASCADE: deleting user deletes notifications)
--   - type: Notification type (unlock_soon, unlocked, new_capsule, etc.)
--   - capsule_id: Related capsule (if applicable, CASCADE: deleting capsule deletes notification)
--   - title: Notification title (e.g., "A letter is ready to open")
--   - body: Notification body text (e.g., "You have a letter from John")
--   - delivered: Whether notification was delivered (for push notification queue)
-- ============================================================================
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

-- ============================================================================
-- TABLE: user_subscriptions
-- ============================================================================
-- WHAT: Premium subscription tracking (Stripe integration)
-- WHY: Tracks subscription status for premium features (themes, animations).
--      Syncs with Stripe webhooks to keep database in sync with payment provider.
--      Users can read own subscriptions, system (service role) can write via webhooks.
-- USAGE EXAMPLES:
--   - Get user subscription: SELECT * FROM user_subscriptions WHERE user_id = auth.uid()
--   - Check if active: SELECT * FROM user_subscriptions WHERE user_id = '...' AND status = 'active'
--   - Update from webhook: UPDATE user_subscriptions SET status = 'canceled' WHERE stripe_subscription_id = '...'
--   - Find expiring: SELECT * FROM user_subscriptions WHERE status = 'active' AND ends_at < NOW() + INTERVAL '7 days'
-- COLUMNS:
--   - id: Unique subscription identifier
--   - user_id: User who has subscription (CASCADE: deleting user deletes subscription)
--   - status: Subscription status (active, canceled, past_due, etc.)
--   - provider: Payment provider (default 'stripe', allows future multi-provider support)
--   - plan_id: Subscription plan ID (e.g., 'premium_monthly', 'premium_yearly')
--   - stripe_subscription_id: Stripe subscription ID (unique, for webhook lookups)
--   - started_at: When subscription started
--   - ends_at: When subscription ends (must be after started_at)
--   - cancel_at_period_end: Whether subscription will cancel at period end (user canceled but still active)
-- CONSTRAINTS:
--   - subscriptions_ends_after_start: ends_at must be after started_at
-- ============================================================================
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

-- ============================================================================
-- TABLE: audit_logs
-- ============================================================================
-- WHAT: Action logging for security and compliance
-- WHY: Tracks all changes to critical tables (capsules, recipients) for security auditing.
--      Helps with debugging, compliance (GDPR), and security incident investigation.
--      Users see own logs, admins see all logs.
--      Inserts via SECURITY DEFINER triggers to bypass RLS.
-- USAGE EXAMPLES:
--   - Get user's audit logs: SELECT * FROM audit_logs WHERE user_id = auth.uid() ORDER BY created_at DESC
--   - Get capsule history: SELECT * FROM audit_logs WHERE capsule_id = '...' ORDER BY created_at
--   - Get all deletions: SELECT * FROM audit_logs WHERE action = 'DELETE'
--   - Admin view all: SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 100
-- COLUMNS:
--   - id: Unique audit log identifier
--   - user_id: User who performed action (SET NULL: deleting user preserves log but removes user link)
--   - action: Action type (INSERT, UPDATE, DELETE)
--   - capsule_id: Related capsule (if applicable, SET NULL: deleting capsule preserves log)
--   - metadata: JSONB with table name, old row data, new row data (full change history)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

