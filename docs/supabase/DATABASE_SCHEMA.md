# OpenOn Database Schema Documentation

Complete reference for all database tables, enums, relationships, and resources.

## 📋 Table of Contents

1. [Enums](#enums)
2. [Tables](#tables)
3. [Views](#views)
4. [Indexes](#indexes)
5. [Functions](#functions)
6. [Triggers](#triggers)
7. [RLS Policies](#rls-policies)
8. [Storage Buckets](#storage-buckets)
9. [Relationships](#relationships)

---

## Enums

### `capsule_status`
Status values for time-locked capsules.

**Values:**
- `sealed` - Locked, not yet ready to open
- `ready` - Unlocked and ready to open
- `opened` - Has been opened by recipient
- `expired` - Past expiration date or deleted

**Used in:** `capsules.status`

---

### `notification_type`
Types of user notifications.

**Values:**
- `unlock_soon` - Capsule will unlock soon (24h before)
- `unlocked` - Capsule is now ready to open
- `new_capsule` - New capsule received
- `disappearing_warning` - Disappearing message will delete soon
- `subscription_expiring` - Premium subscription expiring
- `subscription_expired` - Premium subscription expired

**Used in:** `notifications.type`

---

### `subscription_status`
Subscription status values (Stripe-compatible).

**Values:**
- `active`
- `canceled`
- `past_due`
- `trialing`
- `incomplete`
- `incomplete_expired`

**Used in:** `user_subscriptions.status`

---

### `recipient_relationship`
Relationship types for recipients.

**Values:**
- `friend`
- `family`
- `partner`
- `colleague`
- `acquaintance`
- `other`

**Status**: ⚠️ **DEPRECATED** - This enum has been removed. The `recipients` table now uses `username` (TEXT) instead.

**Replaced by**: `recipients.username` - @username for display, populated from linked user profile for connection-based recipients.

---

## Tables

### `user_profiles`

Extends Supabase Auth users with application-specific profile data.

**Columns:**
- `user_id` (UUID, PK, FK → `auth.users.id`) - References Supabase Auth user
- `full_name` (TEXT) - User's full name
- `avatar_url` (TEXT) - URL to user's avatar image
- `premium_status` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Whether user has premium subscription
- `premium_until` (TIMESTAMPTZ) - Premium subscription expiration date
- `is_admin` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Admin flag for system administration
- `country` (TEXT) - User's country
- `device_token` (TEXT) - Push notification device token
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Relationships:**
- `user_id` → `auth.users(id)` ON DELETE CASCADE

**RLS:** Users can only access their own profile

**Indexes:**
- `idx_user_profiles_premium` on `(premium_status, premium_until)`
- `idx_user_profiles_country` on `(country)`
- `idx_user_profiles_is_admin` on `(is_admin)` WHERE `is_admin = TRUE`

---

### `recipients`

User's contact list (people they can send letters to).

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `owner_id` (UUID, NOT NULL, FK → `auth.users.id`) - Owner of this recipient
- `name` (TEXT, NOT NULL) - Recipient name
- `email` (TEXT) - Recipient email (optional, NULL for connection-based recipients)
- `avatar_url` (TEXT) - URL to recipient's avatar
- `username` (TEXT) - @username for display (optional, populated from linked user profile)
- `linked_user_id` (UUID) - ID of linked user if recipient represents a connection (optional)
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Constraints:**
- `recipients_name_not_empty`: Name cannot be empty (after trim)
- `recipients_email_format`: Email must be valid format if provided

**Relationships:**
- `owner_id` → `auth.users(id)` ON DELETE CASCADE

**RLS:** Users can only access their own recipients

**Indexes:**
- `idx_recipients_owner` on `(owner_id)`
- `idx_recipients_owner_created` on `(owner_id, created_at DESC)`
- `idx_recipients_owner_linked_user` on `(owner_id, linked_user_id)` WHERE `linked_user_id IS NOT NULL`
- `idx_recipients_username` on `(username)` WHERE `username IS NOT NULL`

---

### `capsules`

Time-locked letters (core entity of the application).

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `sender_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who sent the capsule
- `recipient_id` (UUID, NOT NULL, FK → `recipients.id`) - Recipient of the capsule
- `is_anonymous` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Hide sender identity from recipient
- `is_disappearing` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Delete after opening
- `disappearing_after_open_seconds` (INTEGER) - Seconds before deletion (required if `is_disappearing = TRUE`)
- `unlocks_at` (TIMESTAMPTZ, NOT NULL) - When capsule becomes available to open
- `opened_at` (TIMESTAMPTZ) - When capsule was opened (NULL if not opened)
- `expires_at` (TIMESTAMPTZ) - When capsule expires (optional)
- `title` (TEXT) - Capsule title (optional)
- `body_text` (TEXT) - Plain text content
- `body_rich_text` (JSONB) - Rich text content (JSON format)
- `theme_id` (UUID, FK → `themes.id`) - Visual theme for letter
- `animation_id` (UUID, FK → `animations.id`) - Reveal animation
- `status` (`capsule_status`, NOT NULL, DEFAULT 'sealed') - Current status
- `deleted_at` (TIMESTAMPTZ) - Soft delete timestamp (NULL if active)
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Constraints:**
- `capsules_unlocks_future`: `unlocks_at` must be after `created_at`
- `capsules_disappearing_seconds`: If `is_disappearing = TRUE`, `disappearing_after_open_seconds` must be > 0
- `capsules_body_content`: Must have either `body_text` OR `body_rich_text`

**Relationships:**
- `sender_id` → `auth.users(id)` ON DELETE CASCADE
- `recipient_id` → `recipients(id)` ON DELETE CASCADE
- `theme_id` → `themes(id)` ON DELETE SET NULL
- `animation_id` → `animations(id)` ON DELETE SET NULL

**RLS:** 
- Senders can view sent capsules (outbox)
- Recipients can view received capsules (inbox)
- Anonymous capsules hide sender information

**Indexes:**
- `idx_capsules_sender` on `(sender_id, created_at DESC)` - Outbox queries
- `idx_capsules_recipient` on `(recipient_id, created_at DESC)` - Inbox queries
- `idx_capsules_status` on `(status)` - Filter by status
- `idx_capsules_unlocks_at` on `(unlocks_at)` WHERE `status = 'sealed'` - Find ready-to-unlock
- `idx_capsules_opened_at` on `(opened_at)` WHERE `is_disappearing = TRUE` - Find expired disappearing
- `idx_capsules_deleted_at` on `(deleted_at)` WHERE `deleted_at IS NOT NULL` - Exclude soft-deleted
- `idx_capsules_recipient_status` on `(recipient_id, status, created_at DESC)` - Inbox with status
- `idx_capsules_sender_status` on `(sender_id, status, created_at DESC)` - Outbox with status

**Status Logic:**
- `sealed`: `unlocks_at > NOW()` - Not yet ready
- `ready`: `unlocks_at <= NOW()` AND `opened_at IS NULL` - Ready to open
- `opened`: `opened_at IS NOT NULL` - Has been opened
- `expired`: `expires_at < NOW()` OR `deleted_at IS NOT NULL` - Expired or deleted

---

### `themes`

Visual themes for letter presentation.

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `name` (TEXT, NOT NULL, UNIQUE) - Theme name
- `description` (TEXT) - Theme description
- `gradient_start` (TEXT, NOT NULL) - Start color (hex)
- `gradient_end` (TEXT, NOT NULL) - End color (hex)
- `preview_url` (TEXT) - Preview image URL
- `premium_only` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Premium feature flag
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**RLS:** All users can read, only admins can write

**Indexes:**
- `idx_themes_premium` on `(premium_only)`
- `idx_themes_name` on `(name)`

---

### `animations`

Reveal animations for letter opening.

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `name` (TEXT, NOT NULL, UNIQUE) - Animation name
- `description` (TEXT) - Animation description
- `preview_url` (TEXT) - Preview video URL
- `premium_only` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Premium feature flag
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**RLS:** All users can read, only admins can write

**Indexes:**
- `idx_animations_premium` on `(premium_only)`
- `idx_animations_name` on `(name)`

---

### `notifications`

User notifications (unlock alerts, new capsules, etc.).

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `user_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who receives notification
- `type` (`notification_type`, NOT NULL) - Notification type
- `capsule_id` (UUID, FK → `capsules.id`) - Related capsule (if applicable)
- `title` (TEXT, NOT NULL) - Notification title
- `body` (TEXT, NOT NULL) - Notification body text
- `delivered` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Whether notification was delivered
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Relationships:**
- `user_id` → `auth.users(id)` ON DELETE CASCADE
- `capsule_id` → `capsules(id)` ON DELETE CASCADE

**RLS:** Users can only access their own notifications. Inserts via SECURITY DEFINER functions only.

**Indexes:**
- `idx_notifications_user` on `(user_id, created_at DESC)` - Get user's notifications
- `idx_notifications_delivered` on `(user_id, delivered)` WHERE `delivered = FALSE` - Undelivered queue
- `idx_notifications_capsule` on `(capsule_id)` - Find by capsule

---

### `user_subscriptions`

Premium subscription tracking (Stripe integration).

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `user_id` (UUID, NOT NULL, FK → `auth.users.id`, UNIQUE) - One subscription per user
- `status` (`subscription_status`, NOT NULL) - Subscription status
- `provider` (TEXT, NOT NULL, DEFAULT 'stripe') - Payment provider
- `plan_id` (TEXT, NOT NULL) - Subscription plan ID
- `stripe_subscription_id` (TEXT, UNIQUE) - Stripe subscription ID
- `started_at` (TIMESTAMPTZ, NOT NULL) - Subscription start date
- `ends_at` (TIMESTAMPTZ, NOT NULL) - Subscription end date
- `cancel_at_period_end` (BOOLEAN, NOT NULL, DEFAULT FALSE) - Cancel at period end flag
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Constraints:**
- `subscriptions_ends_after_start`: `ends_at` must be after `started_at`

**Relationships:**
- `user_id` → `auth.users(id)` ON DELETE CASCADE

**RLS:** Users can read own, system can write (Stripe webhooks)

**Indexes:**
- `idx_subscriptions_user` on `(user_id)` - Get user's subscription
- `idx_subscriptions_status` on `(status)` - Filter by status
- `idx_subscriptions_ends_at` on `(ends_at)` WHERE `status = 'active'` - Find expiring
- `idx_subscriptions_stripe` on `(stripe_subscription_id)` WHERE `stripe_subscription_id IS NOT NULL` - Stripe lookups

---

### `connection_requests`

Friend/connection requests between users.

**Columns:**
- `id` (UUID, PK, DEFAULT gen_random_uuid())
- `from_user_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who sent the request
- `to_user_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who received the request
- `status` (TEXT, NOT NULL, CHECK IN ('pending', 'accepted', 'declined'), DEFAULT 'pending') - Request status
- `message` (TEXT) - Optional message from sender
- `declined_reason` (TEXT) - Optional reason for decline
- `acted_at` (TIMESTAMPTZ) - When request was accepted/declined
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Relationships:**
- `from_user_id` → `auth.users(id)` ON DELETE CASCADE
- `to_user_id` → `auth.users(id)` ON DELETE CASCADE

**Constraints:**
- `connection_requests_unique_pending` - Unique constraint on (from_user_id, to_user_id) prevents duplicate pending requests

**RLS:** Users can see requests where they are sender or receiver. Only receiver can respond.

**Indexes:**
- `idx_connection_requests_unique_pending` on `(from_user_id, to_user_id)` WHERE `status = 'pending'` - Prevents duplicates
- `idx_connection_requests_to_user_id` on `(to_user_id, created_at DESC)` - Incoming requests lookup
- `idx_connection_requests_from_user_id` on `(from_user_id, created_at DESC)` - Outgoing requests lookup
- `idx_connection_requests_status` on `(status)` WHERE `status = 'pending'` - Status filtering

**Migration:** `supabase/migrations/08_connections.sql`

---

### `connections`

Mutual connections (friendships) between users.

**Columns:**
- `user_id_1` (UUID, NOT NULL, FK → `auth.users.id`) - First user (always smaller UUID)
- `user_id_2` (UUID, NOT NULL, FK → `auth.users.id`) - Second user (always larger UUID)
- `connected_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW()) - When connection was established

**Relationships:**
- `user_id_1` → `auth.users(id)` ON DELETE CASCADE
- `user_id_2` → `auth.users(id)` ON DELETE CASCADE

**Constraints:**
- Primary key on `(user_id_1, user_id_2)` ensures uniqueness
- `connections_user_order` CHECK ensures `user_id_1 < user_id_2` for consistency

**RLS:** Users can view connections where they are user_id_1 or user_id_2. Only service role can create connections.

**Indexes:**
- `idx_connections_user1` on `(user_id_1)` - User1 lookups
- `idx_connections_user2` on `(user_id_2)` - User2 lookups

**Migration:** `supabase/migrations/08_connections.sql`

---

### `blocked_users`

Abuse prevention - tracks blocked users.

**Columns:**
- `blocker_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who blocked
- `blocked_id` (UUID, NOT NULL, FK → `auth.users.id`) - User who is blocked
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW()) - When block was created

**Relationships:**
- `blocker_id` → `auth.users(id)` ON DELETE CASCADE
- `blocked_id` → `auth.users(id)` ON DELETE CASCADE

**Constraints:**
- Primary key on `(blocker_id, blocked_id)` ensures uniqueness
- Prevents self-blocking (enforced in application logic)

**RLS:** Users can view and manage their own blocks.

**Migration:** `supabase/migrations/08_connections.sql`

---

### `audit_logs`

Action logging for security and compliance.

**Columns:**
- `id` (UUID, PK, DEFAULT uuid_generate_v4())
- `user_id` (UUID, FK → `auth.users.id`) - User who performed action (NULL if system)
- `action` (TEXT, NOT NULL) - Action type (INSERT, UPDATE, DELETE)
- `capsule_id` (UUID, FK → `capsules.id`) - Related capsule (if applicable)
- `metadata` (JSONB) - Additional action metadata
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

**Relationships:**
- `user_id` → `auth.users(id)` ON DELETE SET NULL
- `capsule_id` → `capsules(id)` ON DELETE SET NULL

**RLS:** Users see own, admins see all. Inserts via SECURITY DEFINER triggers only.

**Indexes:**
- `idx_audit_logs_user` on `(user_id, created_at DESC)` - Get user's logs
- `idx_audit_logs_capsule` on `(capsule_id)` - Find by capsule
- `idx_audit_logs_action` on `(action, created_at DESC)` - Filter by action
- `idx_audit_logs_created` on `(created_at DESC)` - Time-based queries

---

## Views

### `recipient_safe_capsules_view`

Hides sender information for anonymous messages. Recipients should query this view instead of `capsules` table directly.

**Columns:** Same as `capsules`, but:
- `sender_id` is NULL if `is_anonymous = TRUE`
- `sender_name` is 'Anonymous' if `is_anonymous = TRUE`
- `sender_avatar_url` is NULL if `is_anonymous = TRUE`

**Security:** Inherits RLS from underlying `capsules` table

**Usage:** Query this view for recipient inbox to ensure anonymous sender protection

---

### `inbox_view`

Capsules received by current user (inbox).

**Columns:** All columns from `recipient_safe_capsules_view` plus `current_user_id`

**Security:** Uses `auth.uid()` to filter by logged-in user

**Usage:** Query this view for the inbox screen

**Query Pattern:**
```sql
SELECT * FROM inbox_view 
WHERE current_user_id = auth.uid()
ORDER BY created_at DESC;
```

---

### `outbox_view`

Capsules sent by current user (outbox).

**Columns:** All columns from `capsules` table

**Security:** Uses `auth.uid()` to filter by logged-in user

**Usage:** Query this view for the outbox screen

**Query Pattern:**
```sql
SELECT * FROM outbox_view 
WHERE sender_id = auth.uid()
ORDER BY created_at DESC;
```

---

## Indexes

### Performance Indexes

All indexes are optimized for common query patterns:

**User Profiles:**
- Premium status filtering
- Country-based queries
- Admin operations

**Recipients:**
- Owner-based lookups (most common)
- Sorted by creation date
- Relationship filtering

**Capsules:**
- Sender queries (outbox)
- Recipient queries (inbox)
- Status filtering
- Time-based queries (unlock, expiration)
- Soft-delete exclusion

**Connections:**
- Connection requests lookups (incoming/outgoing)
- Status filtering (pending requests)
- User-based queries
- Connections lookups (bidirectional)

**Notifications:**
- User notifications (sorted by date)
- Undelivered notification queue
- Capsule-based lookups

**Subscriptions:**
- User subscription lookup
- Status filtering
- Expiration tracking
- Stripe webhook lookups

**Audit Logs:**
- User-based queries
- Capsule-based queries
- Action type filtering
- Time-based queries

**Themes & Animations:**
- Premium filtering
- Name lookups

---

## Functions

### `update_capsule_status()`

Automatically updates capsule status based on unlock time.

**Type:** Trigger function  
**Security:** Regular (runs in user context)  
**Usage:** Called by trigger before INSERT/UPDATE on `capsules`

**Logic:**
- Sets `status = 'ready'` if `unlocks_at <= NOW()` and `status = 'sealed'`
- Sets `status = 'expired'` if `expires_at < NOW()`

---

### `handle_capsule_opened()`

Handles capsule opening event (sets status, creates notification, schedules deletion).

**Type:** Trigger function  
**Security:** SECURITY DEFINER (bypasses RLS)  
**Usage:** Called by trigger when `opened_at` is set for the first time

**Actions:**
- Sets `status = 'opened'`
- Creates notification for sender
- Schedules deletion for disappearing messages

---

### `notify_capsule_unlocked()`

Creates notification when capsule becomes ready to open.

**Type:** Trigger function  
**Security:** SECURITY DEFINER (bypasses RLS)  
**Usage:** Called by trigger when capsule status changes from 'sealed' to 'ready'

**Actions:**
- Creates notification for recipient
- Handles anonymous sender display

---

### `create_audit_log()`

Creates audit log entry for capsule/recipient changes.

**Type:** Trigger function  
**Security:** SECURITY DEFINER (bypasses RLS)  
**Usage:** Called by triggers on INSERT/UPDATE/DELETE

**Metadata:** Includes old/new row data, table name, action type

---

### `update_updated_at()`

Automatically updates `updated_at` timestamp on row modification.

**Type:** Trigger function  
**Security:** Regular (runs in user context)  
**Usage:** Called by triggers before UPDATE on tables with `updated_at` column

**Tables:** `user_profiles`, `recipients`, `capsules`, `connection_requests`, `user_subscriptions`

---

### `delete_expired_disappearing_messages()`

Soft-deletes disappearing messages that have expired.

**Type:** Regular function  
**Security:** Regular (called by cron with service role)  
**Usage:** Called by pg_cron job every minute

**Logic:** Sets `deleted_at = NOW()` for messages where `opened_at + disappearing_after_open_seconds <= NOW()`

---

### `send_unlock_soon_notifications()`

Sends notifications for capsules unlocking in next 24 hours.

**Type:** Regular function  
**Security:** SECURITY DEFINER (bypasses RLS)  
**Usage:** Called by pg_cron job every hour

**Logic:** Creates `unlock_soon` notifications for capsules where `unlocks_at BETWEEN NOW() AND NOW() + 24 hours`

**Idempotency:** Checks for existing notifications to prevent duplicates

---

## Triggers

### `trigger_update_capsule_status`

**Table:** `capsules`  
**When:** BEFORE INSERT OR UPDATE  
**Function:** `update_capsule_status()`

Automatically sets capsule status based on time.

---

### `trigger_handle_capsule_opened`

**Table:** `capsules`  
**When:** BEFORE UPDATE  
**Condition:** `OLD.opened_at IS NULL AND NEW.opened_at IS NOT NULL`  
**Function:** `handle_capsule_opened()`

Handles first-time capsule opening.

---

### `trigger_notify_capsule_unlocked`

**Table:** `capsules`  
**When:** AFTER UPDATE  
**Condition:** `OLD.status = 'sealed' AND NEW.status = 'ready'`  
**Function:** `notify_capsule_unlocked()`

Notifies recipient when capsule unlocks.

---

### `trigger_update_*_updated_at`

**Tables:** `user_profiles`, `recipients`, `capsules`, `connection_requests`, `user_subscriptions`  
**When:** BEFORE UPDATE  
**Function:** `update_updated_at()`

Maintains `updated_at` timestamps.

---

### `trigger_audit_*`

**Tables:** `capsules`, `recipients`  
**When:** AFTER INSERT OR UPDATE OR DELETE  
**Function:** `create_audit_log()`

Logs all changes for audit trail.

---

## RLS Policies

### User Profiles

- **SELECT:** Users can read own profile
- **INSERT:** Users can insert own profile
- **UPDATE:** Users can update own profile
- **DELETE:** Users can delete own profile

---

### Recipients

- **SELECT:** Users can read own recipients
- **INSERT:** Users can insert own recipients
- **UPDATE:** Users can update own recipients
- **DELETE:** Users can delete own recipients

---

### Capsules

- **SELECT (Sender):** Senders can view own sent capsules (excludes soft-deleted)
- **SELECT (Recipient):** Recipients can view received capsules (excludes soft-deleted)
- **INSERT:** Users can create capsules (must be sender)
- **UPDATE:** Senders can update unopened capsules (excludes soft-deleted)
- **DELETE:** Users can delete own unopened capsules (excludes soft-deleted)

---

### Notifications

- **SELECT:** Users can read own notifications
- **INSERT:** System only (via SECURITY DEFINER functions)
- **UPDATE:** Users can update own notifications
- **DELETE:** Users can delete own notifications

---

### User Subscriptions

- **SELECT:** Users can read own subscriptions
- **INSERT:** System only (via service role - Stripe webhooks)
- **UPDATE:** System only (via service role - Stripe webhooks)

---

### Themes

- **SELECT:** All authenticated users can read
- **INSERT:** Admins only (`is_admin = TRUE`)
- **UPDATE:** Admins only
- **DELETE:** Admins only

---

### Animations

- **SELECT:** All authenticated users can read
- **INSERT:** Admins only (`is_admin = TRUE`)
- **UPDATE:** Admins only
- **DELETE:** Admins only

---

### Connection Requests

- **SELECT:** Users can view requests where they are sender or receiver
- **INSERT:** Users can send requests (must be sender)
- **UPDATE:** Only receiver can respond (accept/decline)
- **DELETE:** System only (service role)

**Migration:** `supabase/migrations/09_connections_rls.sql`

---

### Connections

- **SELECT:** Users can view connections where they are user_id_1 or user_id_2
- **INSERT:** System only (service role - via RPC function)
- **DELETE:** Users can delete own connections (unfriend)

**Migration:** `supabase/migrations/09_connections_rls.sql`

---

### Blocked Users

- **SELECT:** Users can view own blocks
- **INSERT:** Users can create blocks (must be blocker)
- **DELETE:** Users can unblock (delete own blocks)

**Migration:** `supabase/migrations/09_connections_rls.sql`

---

### Audit Logs

- **SELECT (Own):** Users can read own audit logs
- **SELECT (All):** Admins can read all audit logs
- **INSERT:** System only (via SECURITY DEFINER triggers)

---

## Storage Buckets

### `avatars`

**Purpose:** User profile avatars  
**Public:** Yes  
**Max Size:** 5MB  
**Allowed Types:** `image/*`  
**Folder Structure:** `{user_id}/avatar.{ext}`

**RLS:**
- Users can upload/update own avatar
- All users can view avatars (public)

---

### `capsule_assets`

**Purpose:** Media files attached to capsules (images, videos, audio)  
**Public:** No (private, access controlled by RLS)  
**Max Size:** 50MB  
**Allowed Types:** `image/*`, `video/*`, `audio/*`  
**Folder Structure:** `{sender_id}/{capsule_id}/{filename}`

**RLS:**
- Senders can upload assets for own capsules
- Recipients can view assets for received capsules
- Senders can delete assets for own capsules

---

### `animations`

**Purpose:** Animation files for letter reveals  
**Public:** Yes  
**Max Size:** 100MB  
**Allowed Types:** `video/*`, `application/json`  
**Folder Structure:** `{animation_id}/{filename}`

**RLS:**
- All users can view animations
- Admins can upload/update/delete animations

---

### `themes`

**Purpose:** Theme preview images and assets  
**Public:** Yes  
**Max Size:** 10MB  
**Allowed Types:** `image/*`  
**Folder Structure:** `{theme_id}/{filename}`

**RLS:**
- All users can view theme assets
- Admins can upload/update/delete theme assets

---

## Relationships

### Foreign Key Relationships

```
auth.users
  ├── user_profiles.user_id (CASCADE)
  ├── recipients.owner_id (CASCADE)
  ├── capsules.sender_id (CASCADE)
  ├── connection_requests.from_user_id (CASCADE)
  ├── connection_requests.to_user_id (CASCADE)
  ├── connections.user_id_1 (CASCADE)
  ├── connections.user_id_2 (CASCADE)
  ├── blocked_users.blocker_id (CASCADE)
  ├── blocked_users.blocked_id (CASCADE)
  ├── notifications.user_id (CASCADE)
  ├── user_subscriptions.user_id (CASCADE)
  └── audit_logs.user_id (SET NULL)

recipients
  └── capsules.recipient_id (CASCADE)

themes
  └── capsules.theme_id (SET NULL)

animations
  └── capsules.animation_id (SET NULL)

capsules
  ├── notifications.capsule_id (CASCADE)
  └── audit_logs.capsule_id (SET NULL)
```

### ON DELETE Behavior

- **CASCADE:** Deleting parent deletes children (e.g., deleting user deletes their profiles, recipients, capsules)
- **SET NULL:** Deleting parent sets foreign key to NULL (e.g., deleting theme doesn't delete capsules, just removes theme reference)
- **RESTRICT:** Prevents deletion if children exist (not used in current schema)

---

## Scheduled Jobs (pg_cron)

### Delete Expired Disappearing Messages

**Schedule:** Every minute (`* * * * *`)  
**Function:** `delete_expired_disappearing_messages()`  
**Purpose:** Soft-delete disappearing messages after expiration

---

### Send Unlock Soon Notifications

**Schedule:** Every hour (`0 * * * *`)  
**Function:** `send_unlock_soon_notifications()`  
**Purpose:** Notify recipients when capsules unlock in next 24 hours

---

### Update Premium Status

**Schedule:** Daily at midnight (`0 0 * * *`)  
**SQL:** Updates `user_profiles.premium_status` based on active subscriptions  
**Purpose:** Sync premium status with subscription data

---

## Query Patterns

### Get User's Inbox

```sql
SELECT * FROM inbox_view 
WHERE current_user_id = auth.uid()
  AND deleted_at IS NULL
ORDER BY created_at DESC;
```

### Get User's Outbox

```sql
SELECT * FROM outbox_view 
WHERE sender_id = auth.uid()
  AND deleted_at IS NULL
ORDER BY created_at DESC;
```

### Get User's Recipients

```sql
SELECT * FROM recipients 
WHERE owner_id = auth.uid()
ORDER BY created_at DESC;
```

### Get User's Notifications

```sql
SELECT * FROM notifications 
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

### Get User's Connections

```sql
SELECT * FROM connections 
WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
ORDER BY connected_at DESC;
```

### Get Incoming Connection Requests

```sql
SELECT * FROM connection_requests 
WHERE to_user_id = auth.uid() 
  AND status = 'pending'
ORDER BY created_at DESC;
```

### Get Outgoing Connection Requests

```sql
SELECT * FROM connection_requests 
WHERE from_user_id = auth.uid() 
  AND status = 'pending'
ORDER BY created_at DESC;
```

### Check if Users are Connected

```sql
SELECT 1 FROM connections 
WHERE (user_id_1 = :user1 AND user_id_2 = :user2)
   OR (user_id_1 = :user2 AND user_id_2 = :user1)
LIMIT 1;
```

### Get Available Themes

```sql
SELECT * FROM themes 
WHERE premium_only = FALSE 
   OR EXISTS (
     SELECT 1 FROM user_profiles 
     WHERE user_id = auth.uid() 
       AND premium_status = TRUE
   )
ORDER BY name;
```

---

## Security Notes

1. **RLS is enabled on all tables** - Database-level security
2. **SECURITY DEFINER functions** - System functions bypass RLS for notifications and audit logs
3. **Service role** - Required for Stripe webhooks and system operations
4. **Anonymous capsules** - Sender information hidden via `recipient_safe_capsules_view`
5. **Soft deletes** - All policies exclude `deleted_at IS NOT NULL` records
6. **Admin checks** - Use `is_admin = TRUE` from `user_profiles` table

---

## Migration Files

All schema changes are in numbered migration files:

1. `01_enums_and_tables.sql` - Enums and table definitions
2. `02_indexes.sql` - Performance indexes
3. `03_views.sql` - Safe views for data access
4. `04_functions.sql` - Database functions
5. `05_triggers.sql` - Automated triggers
6. `06_rls_policies.sql` - Row-level security policies
7. `07_storage.sql` - Storage bucket configuration
8. `08_connections.sql` - Connection tables and indexes ⭐ NEW
9. `09_connections_rls.sql` - Connection RLS policies ⭐ NEW
10. `10_connections_functions.sql` - Connection RPC functions ⭐ NEW
11. `11_connections_notifications.sql` - Connection notification triggers ⭐ NEW
12. `12_search_users_function.sql` - User search function
13. `13_user_profiles_search_policy.sql` - User search RLS policy
14. `14_scheduled_jobs.sql` - pg_cron jobs
15. `15_search_users_with_user_id.sql` - Enhanced user search
16. `16_remove_recipients_table.sql` - Migration for recipients table removal (pending)

**To apply:** Run `supabase db reset` to apply all migrations.

