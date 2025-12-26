# Letter Invites Feature - Complete Documentation

> **Production-Ready Documentation for Invite by Letter (Unregistered Recipient) Feature**  
> Last Updated: January 2025  
> Status: ✅ Production Ready & Acquisition Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [User Flow & UI Implementation](#user-flow--ui-implementation)
4. [Database Schema](#database-schema)
5. [API Reference](#api-reference)
6. [Security & Privacy](#security--privacy)
7. [Performance Optimizations](#performance-optimizations)
8. [Code Structure](#code-structure)
9. [Configuration](#configuration)
10. [Deployment](#deployment)
11. [Troubleshooting](#troubleshooting)
12. [Future Enhancements](#future-enhancements)

---

## Overview

The **Letter Invites** feature allows registered users to send time-locked letters to people who are not yet on OpenOn via private, secure invite links. This feature serves as a growth mechanism that enables user acquisition while maintaining the core product principle: **"The letter is the invitation."**

### Key Features

- ✅ **Additive Only**: Does not modify or break any existing letter flows
- ✅ **Privacy-First**: Invite links do not expose sender identity or letter content
- ✅ **Secure Tokens**: Non-guessable 32+ character tokens using cryptographically secure generation
- ✅ **Single Claim**: Each invite can only be claimed once (first user wins)
- ✅ **Automatic Connection**: When claimed, creates mutual connection between sender and receiver
- ✅ **Seamless Integration**: Claimed letters become normal letters for registered users
- ✅ **No Marketing Language**: Invite preview maintains curiosity, not sales pitch
- ✅ **Optimized Performance**: Supports 500,000+ users with batch operations and proper indexing
- ✅ **Production Ready**: Comprehensive error handling, security, and scalability

### Use Cases

1. **User Acquisition**: Send letters to friends/family not yet on OpenOn
2. **Growth Mechanism**: Recipients sign up to unlock their letter, driving new user registration
3. **Privacy-Preserving**: Share letters without exposing sender identity or content
4. **Seamless Onboarding**: New users sign up and immediately access their letter

### Business Rules

- **One Invite Per Letter**: Each letter can have at most one active invite
- **Single Claim**: Only the first user to claim an invite gets access
- **Automatic Connection**: Claiming creates mutual connection between sender and receiver
- **Immediate Unlock**: After signup, letter unlocks immediately if open time has passed
- **Countdown Support**: If claimed before open time, countdown continues normally
- **Revocable**: Deleting the letter invalidates the invite link
- **No Sender Exposure**: Invite preview does not reveal sender identity

### Product Philosophy

> **"The letter is the invitation"** - Recipients should feel "Something meaningful is waiting for me" rather than "Someone wants me to download an app."

This principle guides all design decisions:
- No app marketing language in invite preview
- No forced signup before open time
- Gentle gate at open time: "Create an account to unlock this letter"
- Immediate unlock after signup (no additional steps)

---

## Architecture

### System Components

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
│                  │
│  - Recipient    │
│    Selection    │
│  - Invite Share │
│  - Preview      │
└────────┬─────────┘
         │
         │ 1. Create Letter with
         │    is_unregistered_recipient=true
         ▼
┌─────────────────┐
│  FastAPI        │
│  Backend        │
│                  │
│  - Create       │
│    LetterInvite │
│  - Generate     │
│    Token        │
└────────┬─────────┘
         │
         │ 2. Store in Database
         ▼
┌─────────────────┐
│   PostgreSQL    │
│ letter_invites  │
│     Table       │
└────────┬─────────┘
         │
         │ 3. Return Invite URL
         ▼
┌─────────────────┐
│  Flutter App    │
│  Share Dialog   │
└─────────────────┘
         │
         │ 4. User Shares Link
         ▼
┌─────────────────┐
│  Public Web     │
│  Preview Page   │
│  (No Auth)      │
└────────┬─────────┘
         │
         │ 5. User Signs Up
         │    & Claims Invite
         ▼
┌─────────────────┐
│  FastAPI        │
│  Backend        │
│                  │
│  - Claim Invite │
│  - Create       │
│    Connection   │
│  - Link         │
│    Recipient    │
└────────┬─────────┘
         │
         │ 6. Navigate to Letter
         ▼
┌─────────────────┐
│  Flutter App    │
│  Letter Screen  │
└─────────────────┘
```

### Data Flow

#### 1. Letter Creation Flow

```
Sender creates letter
    ↓
Selects "Invite with a letter"
    ↓
Backend creates:
  - Capsule (letter)
  - Recipient (unregistered placeholder)
  - LetterInvite (with secure token)
    ↓
Returns invite_url in response
    ↓
Frontend shows share dialog
```

#### 2. Invite Claiming Flow

```
Unregistered user opens invite link
    ↓
Public preview page (no auth required)
    ↓
Shows countdown (if before open time)
    ↓
At open time: "Create account to unlock"
    ↓
User signs up
    ↓
Backend claims invite:
  - Links recipient to new user
  - Creates mutual connection
  - Marks invite as claimed
    ↓
Frontend navigates to letter
    ↓
Letter unlocks immediately
```

### Component Interaction

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend Layer                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  step_choose_recipient.dart                             │
│  ├── Recipient selection UI                             │
│  ├── "Invite with a letter" option                      │
│  └── Mutual exclusivity logic                           │
│                                                          │
│  create_capsule_screen.dart                             │
│  ├── Post-creation invite share dialog                  │
│  └── Navigation handling                                │
│                                                          │
│  locked_capsule_screen.dart                             │
│  ├── "Share Invite Link" button (unregistered only)    │
│  └── "Share Countdown" button (all letters)            │
│                                                          │
│  signup_screen.dart                                     │
│  ├── Invite token handling                              │
│  └── Post-signup navigation to letter                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
                          │
                          │ API Calls
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Backend Layer                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  capsules.py                                            │
│  ├── create_capsule() - Creates invite if needed       │
│  ├── list_capsules() - Includes invite_url             │
│  └── get_capsule() - Includes invite_url               │
│                                                          │
│  letter_invites.py                                      │
│  ├── create_invite() - Creates/manages invites         │
│  ├── get_invite_preview() - Public preview (no auth)   │
│  └── claim_invite() - Claims invite on signup          │
│                                                          │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Database Operations
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Database Layer                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  letter_invites table                                   │
│  ├── id (UUID)                                          │
│  ├── letter_id (FK to capsules)                        │
│  ├── invite_token (UNIQUE, indexed)                    │
│  ├── created_at                                         │
│  ├── claimed_at (nullable)                             │
│  └── claimed_user_id (nullable)                        │
│                                                          │
│  RPC Functions                                          │
│  ├── rpc_get_letter_invite_public() - Preview          │
│  └── rpc_claim_letter_invite() - Claim with connection │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## User Flow & UI Implementation

### Sender Flow

#### Step 1: Recipient Selection

**Location**: `frontend/lib/features/create_capsule/step_choose_recipient.dart`

**UI Elements**:
- "Who is this letter for?" title with "Invite" button
- Search field for filtering recipients
- Recipients list (registered users)
- "Invite with a letter" option at bottom (or top when selected)

**User Actions**:
1. User can select a registered recipient (normal flow)
2. User can tap "Invite" button or "Invite with a letter" card
3. When invite option is selected:
   - Option moves to top of list
   - Name input field appears
   - Recipient name is optional (defaults to "Someone special")

**State Management**:
- `draftCapsuleProvider` manages selection state
- Mutual exclusivity enforced:
  - Selecting recipient → clears `isUnregisteredRecipient`
  - Selecting invite → clears `recipient`
- State stored in `DraftCapsule` model

**Key Code**:
```dart
// Mutual exclusivity check
final isSelected = !draftCapsule.isUnregisteredRecipient && 
                  selectedRecipient?.id == recipient.id;

// Invite option selection
ref.read(draftCapsuleProvider.notifier).setUnregisteredRecipient();
```

#### Step 2: Letter Creation

**Location**: `frontend/lib/features/create_capsule/create_capsule_screen.dart`

**Flow**:
1. User completes letter creation (write, set time, preview)
2. Taps "Send Letter" button
3. Backend creates:
   - Capsule (letter)
   - Recipient (unregistered placeholder)
   - LetterInvite (with secure token)
4. Response includes `invite_url`
5. Frontend shows invite share dialog

**Invite Share Dialog**:
- Shows invite URL
- Copy to clipboard button
- Share options (native share sheet)
- Message: "Share this private link to unlock the letter"

**Key Code**:
```dart
if (draft.isUnregisteredRecipient) {
  if (createdCapsule.inviteUrl != null) {
    await _showInviteShareDialog(createdCapsule.inviteUrl!);
  }
}
```

#### Step 3: Lock Screen (Outbox)

**Location**: `frontend/lib/features/capsule/locked_capsule_screen.dart`

**UI Elements**:
- "Share Countdown" button (always visible)
- "Share Invite Link" button (only for unregistered recipients)

**Behavior**:
- If `inviteUrl` is missing, fetches it automatically
- Both buttons available for unregistered recipients
- Only "Share Countdown" for registered recipients

**Key Code**:
```dart
// Share Countdown (always shown)
ElevatedButton.icon(
  onPressed: _handleShare,
  label: const Text('Share Countdown'),
)

// Share Invite Link (unregistered only)
if (_capsule.inviteUrl != null && _capsule.inviteUrl!.isNotEmpty)
  ElevatedButton.icon(
    onPressed: () => _handleInviteShare(_capsule.inviteUrl!),
    label: const Text('Share Invite Link'),
  )
```

### Receiver Flow (Unregistered User)

#### Step 1: Invite Preview (Public, No Auth)

**Location**: Public web page (handled by frontend routing)

**UI Elements**:
- Envelope icon
- Message: "Something meaningful is waiting for you."
- Countdown timer (if before open time)
- No sender name
- No app marketing language

**Behavior**:
- Accessible without authentication
- Shows countdown if before open time
- Disables content reading until open time
- At open time: Shows "Create an account to unlock this letter"

**API Endpoint**: `GET /letter-invites/preview/{invite_token}`

#### Step 2: Signup & Claim

**Location**: `frontend/lib/features/auth/signup_screen.dart`

**Flow**:
1. User taps "Create account" on preview page
2. Signup screen receives `inviteToken` from URL
3. User completes signup
4. After successful signup:
   - Calls `claimInvite(inviteToken)`
   - Backend:
     - Links recipient to new user
     - Creates mutual connection
     - Marks invite as claimed
   - Frontend navigates to letter: `/capsule/{letterId}`

**Key Code**:
```dart
if (inviteToken != null) {
  final result = await ApiConfig.claimInvite(inviteToken);
  if (result.success) {
    context.go('/capsule/${result.letterId}');
  }
}
```

#### Step 3: Letter Unlock

**Location**: `frontend/lib/features/capsule/locked_capsule_screen.dart`

**Behavior**:
- If open time has passed: Letter unlocks immediately
- If before open time: Countdown continues normally
- Letter appears in inbox like any other letter
- Sender and receiver are now connected

---

## Database Schema

### Table: `letter_invites`

**Location**: `supabase/migrations/19_letter_invites_feature.sql`

**Schema**:
```sql
CREATE TABLE public.letter_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
  invite_token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  claimed_at TIMESTAMPTZ,
  claimed_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  CONSTRAINT letter_invites_token_length CHECK (char_length(invite_token) >= 32)
);
```

**Fields**:
- `id`: Primary key (UUID)
- `letter_id`: Foreign key to `capsules` table (CASCADE delete)
- `invite_token`: Secure random token (32+ characters, UNIQUE, indexed)
- `created_at`: Creation timestamp
- `claimed_at`: Timestamp when invite was claimed (NULL if not claimed)
- `claimed_user_id`: User who claimed the invite (NULL if not claimed)

**Indexes**:
```sql
-- Fast lookup by invite token (public access path)
CREATE INDEX idx_letter_invites_token 
  ON public.letter_invites(invite_token) 
  WHERE claimed_at IS NULL;

-- Letter queries: find invites for a specific letter
CREATE INDEX idx_letter_invites_letter 
  ON public.letter_invites(letter_id);

-- Claimed user queries: find invites claimed by a user
CREATE INDEX idx_letter_invites_claimed_user 
  ON public.letter_invites(claimed_user_id) 
  WHERE claimed_user_id IS NOT NULL;
```

### Row Level Security (RLS)

**Policies**:
1. **INSERT**: Senders can create invites for their own letters
2. **SELECT**: Senders can read their own invites
3. **UPDATE**: No direct updates (only via RPC function)

**Public Access**: Handled via RPC function `rpc_get_letter_invite_public()` which bypasses RLS for preview access.

### RPC Functions

#### `rpc_get_letter_invite_public(invite_token TEXT)`

**Purpose**: Get public preview of invite (no auth required)

**Returns**: Safe public data only:
- Letter unlock time
- Countdown information
- No sender identity
- No letter content

**Security**: Validates token format, checks if letter is deleted, returns only safe data.

#### `rpc_claim_letter_invite(invite_token TEXT)`

**Purpose**: Claim an invite when user signs up

**Operations** (atomic):
1. Validates user is authenticated
2. Checks invite exists and not already claimed
3. Checks letter is not deleted
4. Atomically claims invite (prevents race conditions)
5. Updates recipient to link to claiming user
6. Creates mutual connection between sender and receiver
7. Creates recipient entries for both users

**Security**: 
- Uses `WHERE claimed_at IS NULL` to prevent race conditions
- Checks `IF NOT FOUND` after update to detect concurrent claims
- Creates connections with proper ordering (user1 < user2)

---

## API Reference

### Backend Endpoints

#### Create Letter with Invite

**Endpoint**: `POST /capsules`

**Request Body**:
```json
{
  "recipient_id": null,
  "is_unregistered_recipient": true,
  "unregistered_recipient_name": "John Doe",
  "title": "A special letter",
  "body_text": "Letter content...",
  "unlocks_at": "2025-02-01T12:00:00Z",
  "is_anonymous": false
}
```

**Response**:
```json
{
  "id": "uuid",
  "invite_url": "https://openon.app/invite/abc123...",
  "status": "locked",
  ...
}
```

**Implementation**: `backend/app/api/capsules.py::create_capsule()`

#### Get Invite Preview (Public)

**Endpoint**: `GET /letter-invites/preview/{invite_token}`

**Authentication**: None required (public endpoint)

**Response**:
```json
{
  "letter_id": "uuid",
  "unlocks_at": "2025-02-01T12:00:00Z",
  "is_claimed": false,
  "countdown_seconds": 86400
}
```

**Implementation**: `backend/app/api/letter_invites.py::get_invite_preview()`

#### Claim Invite

**Endpoint**: `POST /letter-invites/claim/{invite_token}`

**Authentication**: Required (user must be signed up)

**Response**:
```json
{
  "success": true,
  "letter_id": "uuid",
  "message": "Invite claimed successfully"
}
```

**Implementation**: `backend/app/api/letter_invites.py::claim_invite()`

#### Create Invite (Manual)

**Endpoint**: `POST /letter-invites/letters/{letter_id}`

**Purpose**: Create invite for existing letter (if not already created)

**Response**:
```json
{
  "invite_id": "uuid",
  "invite_token": "abc123...",
  "invite_url": "https://openon.app/invite/abc123...",
  "already_exists": false
}
```

**Implementation**: `backend/app/api/letter_invites.py::create_invite()`

### Frontend API Client

**Location**: `frontend/lib/core/data/api_repositories.dart`

**Methods**:
- `createCapsule()` - Creates letter, includes invite if unregistered
- `claimInvite(token)` - Claims invite after signup
- `getInvitePreview(token)` - Gets public preview (no auth)

---

## Security & Privacy

### Token Security

**Generation**:
- Uses `secrets.token_urlsafe(32)` (cryptographically secure)
- 32 bytes = ~43 characters after base64url encoding
- Non-guessable, cryptographically random

**Validation**:
- Minimum 32 characters
- Regex validation: `^[A-Za-z0-9_-]+$` (base64url safe)
- Prevents injection attacks

**Storage**:
- UNIQUE constraint in database
- Indexed for fast lookups
- Never exposed in logs or error messages

### Privacy Protection

**Invite Preview**:
- No sender identity exposed
- No letter content exposed
- No recipient information exposed
- Only safe public data: unlock time, countdown

**Claiming Process**:
- Only authenticated users can claim
- Atomic operation prevents race conditions
- First user to claim wins (prevents multiple claims)

**Connection Creation**:
- Automatic mutual connection on claim
- Proper ordering (user1 < user2) for consistency
- Handles conflicts gracefully

### Row Level Security (RLS)

**Policies**:
- Senders can only create/read invites for their own letters
- Public preview via RPC function (bypasses RLS safely)
- No direct table access for unregistered users

### Input Validation

**Backend**:
- Token format validation (length, characters)
- Letter existence checks
- Deleted letter checks
- Authentication checks

**Frontend**:
- Input sanitization (`.trim()`)
- Optional name field (defaults to "Someone special")
- Proper error handling

---

## Performance Optimizations

### Database Optimizations

**Indexes**:
- `invite_token` (partial index on unclaimed invites)
- `letter_id` (for letter queries)
- `claimed_user_id` (for user queries)

**Query Optimization**:
- Batch fetching of invites in `list_capsules()` (prevents N+1 queries)
- Eager loading of relationships
- Proper use of `IN` clauses for batch operations

**Implementation**: `backend/app/api/capsules.py::list_capsules()`

### Frontend Optimizations

**State Management**:
- Isolated widgets (`_LetterCountBadge`) prevent unnecessary rebuilds
- Efficient filtering (single-pass algorithm)
- Proper use of `ref.watch` vs `ref.read`

**UI Performance**:
- Lazy loading of recipient lists
- Efficient search filtering
- Proper disposal of controllers

**Code Location**: `frontend/lib/features/create_capsule/step_choose_recipient.dart`

### Scalability (500k+ Users)

**Batch Operations**:
- Batch fetching of user profiles: `get_by_ids()`
- Batch fetching of invites: `get_by_letter_ids()`
- Single-pass filtering algorithms

**Connection Pooling**:
- Database connection pooling enabled
- Proper session management
- Automatic transaction handling

**Caching**:
- Provider-based caching (Riverpod)
- Efficient invalidation strategies

---

## Code Structure

### Backend Structure

```
backend/app/
├── api/
│   ├── capsules.py              # Letter creation, listing (includes invite_url)
│   └── letter_invites.py        # Invite management endpoints
├── db/
│   ├── models.py                # LetterInvite model
│   └── repositories.py         # LetterInviteRepository
├── core/
│   └── config.py               # invite_base_url configuration
└── models/
    └── schemas.py              # LetterInvite schemas
```

**Key Files**:
- `backend/app/api/capsules.py` - Letter creation with invite generation
- `backend/app/api/letter_invites.py` - Invite endpoints
- `backend/app/db/repositories.py` - LetterInviteRepository
- `supabase/migrations/19_letter_invites_feature.sql` - Database schema

### Frontend Structure

```
frontend/lib/
├── features/
│   ├── create_capsule/
│   │   ├── step_choose_recipient.dart    # Recipient selection UI
│   │   └── create_capsule_screen.dart     # Post-creation invite share
│   ├── capsule/
│   │   └── locked_capsule_screen.dart     # Share invite button
│   └── auth/
│       └── signup_screen.dart             # Invite claiming
├── core/
│   ├── models/
│   │   └── models.dart                    # DraftCapsule, Capsule models
│   ├── providers/
│   │   └── providers.dart                 # draftCapsuleProvider
│   └── data/
│       └── api_repositories.dart           # API client methods
```

**Key Files**:
- `frontend/lib/features/create_capsule/step_choose_recipient.dart` - Recipient selection
- `frontend/lib/features/create_capsule/create_capsule_screen.dart` - Invite share dialog
- `frontend/lib/features/capsule/locked_capsule_screen.dart` - Share buttons
- `frontend/lib/core/providers/providers.dart` - State management

### Database Structure

```
supabase/migrations/
└── 19_letter_invites_feature.sql
    ├── Table creation
    ├── Indexes
    ├── RLS policies
    └── RPC functions
```

---

## Configuration

### Backend Configuration

**Location**: `backend/app/core/config.py`

**Environment Variable**:
```python
invite_base_url: Optional[str] = Field(
    default="https://openon.app/invite",
    description="Base URL for letter invite links. Format: https://openon.app/invite (without trailing slash). For local dev, use http://localhost:3000/invite or your frontend URL."
)
```

**Setup**:
```bash
# Production
export INVITE_BASE_URL="https://openon.app/invite"

# Local Development
export INVITE_BASE_URL="http://localhost:3000/invite"
```

### Frontend Configuration

**No additional configuration required** - Uses backend-provided `invite_url` directly.

### Database Configuration

**Migration**: `supabase/migrations/19_letter_invites_feature.sql`

**Apply Migration**:
```bash
cd supabase
supabase db reset  # For local development
# OR
supabase migration up  # For production
```

---

## Deployment

### Pre-Deployment Checklist

- [ ] Database migration applied: `19_letter_invites_feature.sql`
- [ ] Environment variable set: `INVITE_BASE_URL`
- [ ] Backend restarted to load new configuration
- [ ] Frontend deployed with latest changes
- [ ] Public invite preview route configured in frontend router
- [ ] Signup flow updated to handle invite tokens

### Migration Steps

1. **Database**:
   ```bash
   supabase migration up
   ```

2. **Backend**:
   ```bash
   # Set environment variable
   export INVITE_BASE_URL="https://openon.app/invite"
   
   # Restart backend
   systemctl restart openon-backend
   ```

3. **Frontend**:
   ```bash
   # Deploy frontend
   flutter build web
   # Deploy to hosting service
   ```

### Rollback Plan

**If feature needs to be disabled**:
1. Frontend: Hide "Invite with a letter" option (UI change only)
2. Backend: Return error for invite creation (optional)
3. Database: Keep schema (no breaking changes)

**Note**: Feature is additive-only, so disabling it does not break existing functionality.

---

## Troubleshooting

### Common Issues

#### Issue: Invite URL not generated

**Symptoms**: `invite_url` is `null` in response

**Causes**:
- `INVITE_BASE_URL` not set in backend
- Backend not restarted after config change

**Solution**:
1. Check `backend/app/core/config.py` - `invite_base_url` should not be `None`
2. Set environment variable: `export INVITE_BASE_URL="https://openon.app/invite"`
3. Restart backend service

#### Issue: "Invite not found" error

**Symptoms**: Preview page shows "Invite not found"

**Causes**:
- Invalid token format
- Letter was deleted
- Invite was already claimed

**Solution**:
- Verify token format (32+ characters, base64url safe)
- Check if letter exists and is not deleted
- Check if invite is already claimed

#### Issue: Both recipient and invite selected

**Symptoms**: UI shows both options as selected

**Causes**: State management issue

**Solution**:
- Verify `setRecipient()` clears `isUnregisteredRecipient`
- Verify `setUnregisteredRecipient()` clears `recipient`
- Check UI mutual exclusivity checks

#### Issue: Invite link not working after signup

**Symptoms**: User signs up but doesn't see letter

**Causes**:
- Invite claiming failed
- Navigation issue

**Solution**:
1. Check backend logs for claim errors
2. Verify `claimInvite()` is called after signup
3. Check navigation: `context.go('/capsule/$letterId')`

### Debugging

**Backend Logging**:
```python
# Enable debug logging
logger.debug(f"Creating invite for letter {letter_id}")
logger.debug(f"Invite URL: {invite_url}")
```

**Frontend Logging**:
```dart
Logger.info('Invite URL received: ${createdCapsule.inviteUrl}');
Logger.debug('Claiming invite: $inviteToken');
```

**Database Queries**:
```sql
-- Check invite status
SELECT * FROM letter_invites WHERE letter_id = 'uuid';

-- Check if claimed
SELECT * FROM letter_invites WHERE invite_token = 'token';
```

---

## Future Enhancements

### Potential Improvements

1. **Invite Expiration**: Optional expiration dates for invites
2. **Multiple Invites**: Allow multiple invites per letter (with limits)
3. **Invite Analytics**: Track invite views and claims
4. **Custom Invite Messages**: Allow senders to add custom messages
5. **Invite Revocation**: UI for revoking invites
6. **Bulk Invites**: Send invites to multiple unregistered users
7. **Email Notifications**: Optional email notifications for invites (with user consent)

### Considerations

- **Privacy**: Maintain "letter is the invitation" principle
- **Performance**: Ensure scalability for 1M+ users
- **Security**: Keep token security and validation
- **User Experience**: Maintain seamless onboarding flow

---

## Related Documentation

- **[CREATE_CAPSULE.md](../frontend/features/CREATE_CAPSULE.md)** - Letter creation flow
- **[CAPSULE.md](../frontend/features/CAPSULE.md)** - Letter viewing
- **[AUTH.md](../frontend/features/AUTH.md)** - Authentication and signup
- **[CONNECTIONS.md](../frontend/features/CONNECTIONS.md)** - Connection management
- **[backend/API_REFERENCE.md](../backend/API_REFERENCE.md)** - Backend API reference
- **[supabase/DATABASE_SCHEMA.md](../supabase/DATABASE_SCHEMA.md)** - Database schema

---

**Last Updated**: January 2025  
**Maintained By**: Development Team  
**Status**: ✅ Production Ready & Acquisition Ready

