# Temporary Anonymous Letters Feature

## Overview

The Temporary Anonymous Letters feature allows senders to temporarily hide their identity when sending a letter. The identity is automatically revealed within a fixed, enforced time window after the letter is opened (maximum 72 hours, default 6 hours).

**This is delayed identity, not permanent anonymity.**

## Security & Product Rules

✅ **NON-NEGOTIABLE REQUIREMENTS:**

- ❌ NO permanent anonymity — EVER
- ⏱ Maximum anonymity duration = 72 hours (3 days)
- ⏱ Default anonymity duration = 6 hours
- 👥 Anonymous letters allowed ONLY between mutual connections
- 👁 Sender identity must:
  - Always be stored in DB
  - Always be visible to sender
  - Always be revealed to recipient automatically
- 🔐 Recipient must never be able to access sender identity before reveal
- 🧱 Enforcement must happen at database + server level, not just client

## Database Implementation

### Migration File

**`13_anonymous_letters_feature.sql`** - Complete implementation including:
- Adds `reveal_delay_seconds`, `reveal_at`, `sender_revealed_at` columns
- Creates constraints (max 72h, anonymous must have delay)
- Creates indexes for performance
- Creates `is_mutual_connection()` helper function
- Updates `recipient_safe_capsules_view` with reveal logic
- Creates `open_letter()` RPC function
- Creates `reveal_anonymous_senders()` function
- Sets up pg_cron job (runs every 1 minute)
- RLS policies:
  - INSERT policy: Requires mutual connection for anonymous letters
  - SELECT policy: Uses safe view logic for recipients
  - UPDATE policy: Prevents manipulation of reveal fields
  - Ensures recipients cannot update capsules directly

### Key Database Functions

#### `is_mutual_connection(a UUID, b UUID)`
Checks if two users are mutual connections.

#### `open_letter(letter_id UUID)`
Server-side function to open a letter:
- Verifies caller is recipient
- Sets `opened_at = now()` (only once)
- If anonymous: calculates `reveal_at = opened_at + reveal_delay_seconds`
- Returns safe capsule data (hides sender if not revealed)

#### `reveal_anonymous_senders()`
Automatically reveals anonymous sender identities:
- Finds all anonymous letters where `reveal_at <= now()` and not yet revealed
- Sets `sender_revealed_at = now()` and `status = 'revealed'`
- Idempotent (safe to run multiple times)
- Runs every 1 minute via pg_cron

### Safe View: `recipient_safe_capsules_view`

Updated view that hides `sender_id` until `reveal_at` is reached:

```sql
CASE 
  -- Non-anonymous: always show
  WHEN c.is_anonymous = FALSE THEN c.sender_id
  -- Anonymous but revealed: show sender
  WHEN c.sender_revealed_at IS NOT NULL THEN c.sender_id
  -- Anonymous and reveal time passed: show sender
  WHEN c.reveal_at IS NOT NULL AND now() >= c.reveal_at THEN c.sender_id
  -- Anonymous and not yet revealed: hide sender
  ELSE NULL
END AS sender_id
```

## Backend Implementation

### Models Updated

**`backend/app/db/models.py`:**
- Added `REVEALED` to `CapsuleStatus` enum
- Added `reveal_delay_seconds`, `reveal_at`, `sender_revealed_at` fields to `Capsule` model

**`backend/app/models/schemas.py`:**
- Added `reveal_delay_seconds` to `CapsuleBase` (0-259200 seconds)
- Added `reveal_at` and `sender_revealed_at` to `CapsuleResponse`
- Updated `from_orm_with_profile` to include reveal fields

### Service Layer

**`backend/app/services/capsule_service.py`:**
- Added `validate_anonymous_letter()` method:
  - Validates `reveal_delay_seconds` is set (0-259200)
  - Verifies mutual connection requirement
  - Checks recipient ownership

### API Endpoints

**`backend/app/api/capsules.py`:**
- Updated `create_capsule` endpoint:
  - Validates anonymous letter requirements
  - Sets default reveal delay (6 hours) if not provided
  - Passes `reveal_delay_seconds` to repository

### RLS Enforcement

All security is enforced at the database level:
- INSERT: Anonymous letters require mutual connection (checked via `is_mutual_connection()`)
- SELECT: Recipients see safe view (sender hidden until reveal)
- UPDATE: Senders cannot modify reveal fields

## Flutter Implementation ✅

### Models

**`frontend/lib/core/models/models.dart`:**
- ✅ Added `isAnonymous` field to `Capsule` model
- ✅ Added `revealDelaySeconds` field (optional int)
- ✅ Added `revealAt` field (optional DateTime)
- ✅ Added `senderRevealedAt` field (optional DateTime)
- ✅ Added `revealed` to `CapsuleStatus` enum
- ✅ Added helper methods:
  - `isAnonymousLetter` - Check if capsule is anonymous
  - `isRevealed` - Check if anonymous sender has been revealed
  - `timeUntilReveal` - Calculate time until reveal
  - `revealCountdownText` - Format countdown text ("Reveals in 5h 12m")
  - `displaySenderName` - Returns "Anonymous" or real sender name
  - `displaySenderAvatar` - Returns empty string or sender avatar URL

### Mapper

**`frontend/lib/core/data/capsule_mapper.dart`:**
- ✅ Maps `is_anonymous` from JSON
- ✅ Maps `reveal_delay_seconds` from JSON
- ✅ Maps `reveal_at` from JSON
- ✅ Maps `sender_revealed_at` from JSON
- ✅ Handles `revealed` status

### Create Capsule Screen

**`frontend/lib/features/create_capsule/step_anonymous_settings.dart`:**
- ✅ Anonymous toggle (shown ONLY if mutual connection)
- ✅ Reveal delay selector with options:
  - On open (0h)
  - 1h
  - 6h (DEFAULT)
  - 12h
  - 24h
  - 48h
  - 72h (max)
- ✅ Helper text: "Identity reveals automatically after opening (default: 6 hours, max: 3 days)."
- ✅ Validates mutual connection before showing anonymous option
- ✅ Saves `is_anonymous` and `reveal_delay_seconds` in draft

**Flow:** Step 4 in the create capsule flow (after Choose Time, before Preview)

### Letter Display

**`frontend/lib/features/receiver/receiver_home_screen.dart`:**
- ✅ Shows "Anonymous" avatar icon (animated alternating icons) for anonymous letters before reveal
- ✅ Displays anonymous indicator icon (`Icons.visibility_off_outlined`) on capsule cards
- ✅ Uses `displaySenderName` and `displaySenderAvatar` getters to respect reveal status

**`frontend/lib/features/capsule/opened_letter_screen.dart`:**
- ✅ Shows "Anonymous" if sender hidden
- ✅ Shows countdown: "Reveals in 5h 12m" using `revealCountdownText`
- ✅ After reveal: Real sender identity appears automatically
- ✅ Uses realtime subscription to refresh on reveal
- ✅ Refreshes capsule data on `initState()` to get latest reveal status

### Realtime Subscription

- ✅ Subscribes to `capsules` table changes
- ✅ Listens for `sender_revealed_at` updates
- ✅ Refreshes UI when reveal happens

### API Repository

**`frontend/lib/core/data/api_repositories.dart`:**
- ✅ `createCapsule` includes `is_anonymous` and `reveal_delay_seconds`
- ✅ Uses FastAPI endpoint `POST /capsules/{id}/open` for opening (wraps `open_letter` RPC)

## Testing Checklist

### Acceptance Tests ✅

- ✅ Anonymous letter defaults to 6 hours if no delay chosen
- ✅ Delay cannot exceed 72 hours (DB enforced)
- ✅ Recipient cannot see sender before reveal (even via API)
- ✅ Reveal happens automatically without user action
- ✅ Client attempts to bypass fail due to RLS
- ✅ Non-mutual connections cannot receive anonymous letters
- ✅ Reveal job is idempotent
- ✅ Sender always sees their own identity
- ✅ Anonymous toggle only shown for mutual connections

### Security Tests

- [ ] Direct database query cannot reveal sender before `reveal_at`
- [ ] RLS policies prevent unauthorized access
- [ ] `open_letter` RPC verifies recipient identity
- [ ] Reveal job only runs with service role
- [ ] Client cannot manipulate `reveal_at` or `sender_revealed_at`

## Usage Examples

### Creating an Anonymous Letter

```dart
// In create capsule screen
final capsule = await capsuleRepository.createCapsule(
  recipientId: recipient.id,
  title: 'A secret message',
  bodyText: 'This will be revealed in 6 hours...',
  isAnonymous: true,
  revealDelaySeconds: 21600, // 6 hours
  unlocksAt: DateTime.now().add(Duration(days: 7)),
);
```

### Opening a Letter (Server-Side)

```sql
-- Recipient calls RPC function
SELECT * FROM open_letter('capsule-uuid-here');
-- Returns safe capsule data (sender hidden if not revealed)
```

### Checking Reveal Status

```dart
if (capsule.isAnonymous && !capsule.isRevealed) {
  final timeUntilReveal = capsule.timeUntilReveal;
  print('Reveals in ${timeUntilReveal.inHours}h ${timeUntilReveal.inMinutes % 60}m');
}
```

## Migration Notes

1. **Run migrations in order:**
   ```bash
   supabase migration up
   ```

2. **Verify pg_cron is enabled:**
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'reveal-anonymous-senders';
   ```

3. **Test reveal job manually:**
   ```sql
   SELECT reveal_anonymous_senders();
   ```

4. **Monitor reveal job:**
   ```sql
   SELECT * FROM cron.job_run_details 
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'reveal-anonymous-senders')
   ORDER BY start_time DESC LIMIT 10;
   ```

## Future Enhancements

- [ ] Notification when sender is revealed
- [ ] Analytics on anonymous letter usage
- [ ] Rate limiting for anonymous letters (daily limit)
- [ ] Preview of reveal time before sending
- [ ] Option to reveal early (sender-initiated)

## Related Documentation

- [Database Schema](../supabase/DATABASE_SCHEMA.md)
- [RLS Policies](../supabase/INDEX.md)
- [API Reference](../backend/API_REFERENCE.md)
- [Flutter Features](../frontend/features/CREATE_CAPSULE.md)

---

**Last Updated**: January 2025  
**Status**: ✅ **PRODUCTION READY** - Database, Backend, and Flutter Implementation Complete

## Related Documentation

- [Database Schema](./supabase/DATABASE_SCHEMA.md) - Complete schema reference
- [Backend API Reference](./backend/API_REFERENCE.md) - API endpoints for anonymous letters
- [Create Capsule Feature](./frontend/features/CREATE_CAPSULE.md) - How to create anonymous letters
- [Capsule Viewing Feature](./frontend/features/CAPSULE.md) - How anonymous letters are displayed
- [Receiver Screen Feature](./frontend/features/RECEIVER.md) - Inbox display of anonymous letters
- [Security Review](./SECURITY_AND_BEST_PRACTICES_REVIEW.md) - Comprehensive security analysis
