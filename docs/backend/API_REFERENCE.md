# Backend API Reference

Complete API endpoint documentation for the OpenOn backend, matching Supabase schema.

## 📋 Base URL

```
Development: http://localhost:8000
Production: https://api.openon.com
```

## 🔐 Authentication

**Important**: User signup and login are handled by Supabase Auth. This backend only provides profile management endpoints.

All endpoints require authentication via Supabase JWT Bearer token.

### Headers

```http
Authorization: Bearer <supabase_jwt_token>
Content-Type: application/json
```

### Getting a Token

1. User signs up/logs in via Supabase Auth (frontend)
2. Supabase returns JWT token
3. Include token in `Authorization` header for all API requests

## 📚 Table of Contents

1. [Authentication & Profile](#authentication--profile-endpoints)
2. [Capsules](#capsules-endpoints)
3. [Letter Invites](#letter-invites-endpoints) ⭐ NEW
4. [Letter Replies](#letter-replies-endpoints) ⭐ NEW
5. [Recipients](#recipients-endpoints)
6. [Connections](#connections-endpoints)
7. [Error Handling](#error-handling)

---

## Authentication & Profile Endpoints

### GET /auth/me

Get current authenticated user profile information.

**Headers:**
```http
Authorization: Bearer <supabase_jwt_token>
```

**Response (200):**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Alice Johnson",
  "avatar_url": "https://example.com/avatar.jpg",
  "premium_status": false,
  "premium_until": null,
  "is_admin": false,
  "country": "US",
  "device_token": null,
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /auth/me

Update current user profile.

**Request Body:**
```json
{
  "full_name": "Alice Smith",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "country": "CA",
  "device_token": "fcm-token-here"
}
```

**Response (200):**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Alice Smith",
  "avatar_url": "https://example.com/new-avatar.jpg",
  ...
}
```

**Note**: All fields are optional. Only provided fields will be updated.

**Example:**
```bash
curl -X PUT "http://localhost:8000/auth/me" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "full_name": "Alice Smith",
    "country": "CA"
  }'
```

---

## Capsules Endpoints

### POST /capsules

Create a new capsule (in sealed status with unlock time).

**Request Body:**
```json
{
  "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "body_rich_text": null,
  "is_anonymous": false,
  "reveal_delay_seconds": null,
  "unlocks_at": "2026-01-01T00:00:00Z",
  "expires_at": null,
  "theme_id": "550e8400-e29b-41d4-a716-446655440001",
  "animation_id": "550e8400-e29b-41d4-a716-446655440002"
}
```

**Anonymous Letter Fields:**
- `is_anonymous` (boolean): Whether sender identity is hidden (default: false)
- `reveal_delay_seconds` (integer, optional): Delay in seconds before revealing sender identity (0-259200, default: 21600 = 6 hours)
  - Required if `is_anonymous = true`
  - Maximum: 259200 seconds (72 hours)
  - Default: 21600 seconds (6 hours) if not provided

**Anonymous Letter Requirements:**
- Recipient must be a mutual connection (enforced at database level)
- `reveal_delay_seconds` must be between 0 and 259200 (72 hours)
- If `is_anonymous = true` and `reveal_delay_seconds` is not provided, defaults to 6 hours

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "sender_id": "your-user-id",
  "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "body_rich_text": null,
  "is_anonymous": false,
  "status": "sealed",
  "unlocks_at": "2026-01-01T00:00:00Z",
  "opened_at": null,
  "deleted_at": null,
  "expires_at": null,
  "theme_id": "550e8400-e29b-41d4-a716-446655440001",
  "animation_id": "550e8400-e29b-41d4-a716-446655440002",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Validation:**
- `recipient_id`: Required, must be a valid UUID of a recipient owned by current user
- `unlocks_at`: Required, must be in the future
- Either `body_text` OR `body_rich_text` is required (not both empty)

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Capsule",
    "body_text": "This is a time capsule!",
    "unlocks_at": "2026-01-01T00:00:00Z"
  }'
```

### GET /capsules

List capsules for the current user.

**Query Parameters:**
- `box` (optional): "inbox" or "outbox" (default: "inbox")
- `status` (optional): Filter by status (sealed, ready, opened, expired)
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 20, min: 1, max: 100)

**Response (200):**
```json
{
  "capsules": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "sender_id": "sender-id",
      "recipient_id": "recipient-id",
      "title": "Capsule Title",
      "body_text": "Capsule content...",
      "status": "ready",
      "unlocks_at": "2026-01-01T00:00:00Z",
      "opened_at": null,
      ...
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

**Note**: 
- `inbox`: Shows capsules where current user owns the recipient
- `outbox`: Shows capsules sent by current user

**Example:**
```bash
# Get inbox capsules
curl -X GET "http://localhost:8000/capsules?box=inbox" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"

# Get ready capsules only
curl -X GET "http://localhost:8000/capsules?box=inbox&status=ready" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /capsules/{capsule_id}

Get details of a specific capsule.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "sender_id": "sender-id",
  "recipient_id": "recipient-id",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "status": "ready",
  "unlocks_at": "2026-01-01T00:00:00Z",
  "opened_at": null,
  ...
}
```

**Permissions:**
- Sender: Can always view (including their own identity for anonymous letters)
- Recipient owner: Can view if status is `ready` or `opened`
- Anonymous capsules: 
  - Sender info (`sender_id`, `sender_name`, `sender_avatar_url`) hidden from recipient until reveal
  - Reveal happens automatically when `reveal_at` timestamp is reached
  - `reveal_at` is calculated as `opened_at + reveal_delay_seconds` when letter is opened
  - Recipient sees "Anonymous" as sender name until reveal

**Example:**
```bash
curl -X GET "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /capsules/{capsule_id}/current-hint ⭐ NEW

Get the current eligible hint for an anonymous letter (recipient only).

**Path Parameters:**
- `capsule_id` (UUID): The ID of the anonymous letter

**Response (200 OK):**
```json
{
  "hint_text": "We met at the coffee shop",
  "hint_index": 1
}
```

**Response (200 OK, no hint yet):**
```json
{
  "hint_text": null,
  "hint_index": null
}
```

**Errors:**
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Letter not found or not anonymous

**Business Rules:**
- Only available for anonymous letters
- Letter must be opened
- Hints appear based on elapsed time percentage:
  - 1 hint: Shows at 50% elapsed
  - 2 hints: Shows at 35% and 70% elapsed
  - 3 hints: Shows at 30%, 50%, and 85% elapsed
- Hints are no longer shown after identity is revealed

**Documentation**: See [features/ANONYMOUS_IDENTITY_HINTS.md](../features/ANONYMOUS_IDENTITY_HINTS.md) for complete feature documentation

**Example:**
```bash
curl -X GET "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003/current-hint" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /capsules/{capsule_id}

Update a capsule (only before opening).

**Request Body:**
```json
{
  "title": "Updated Title",
  "body_text": "Updated content...",
  "body_rich_text": null,
  "is_anonymous": true,
  "theme_id": "new-theme-id",
  "animation_id": "new-animation-id",
  "expires_at": "2027-01-01T00:00:00Z"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "title": "Updated Title",
  ...
}
```

**Note**: 
- Only sender can edit
- Cannot edit if status is `opened` or `expired`
- `unlocks_at` cannot be changed after creation
- Cannot modify `reveal_at`, `sender_revealed_at`, `opened_at`, or `sender_id` (protected fields)
- For anonymous letters: Cannot change `is_anonymous` or `reveal_delay_seconds` after creation (enforced at database level)
- All fields are optional (partial update)

**Example:**
```bash
curl -X PUT "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "title": "Updated Title",
    "body_text": "Updated content..."
  }'
```

### POST /capsules/{capsule_id}/open

Open a ready capsule (recipient owner only).

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "status": "opened",
  "opened_at": "2025-01-15T10:40:00Z",
  "reveal_at": "2025-01-15T16:40:00Z",
  ...
}
```

**Requirements:**
- Must be the recipient owner (user who owns the recipient)
- Capsule must be in `ready` or `sealed` status (with `unlocks_at` passed)
- Action is irreversible

**Anonymous Letter Behavior:**
- If `is_anonymous = true`:
  - `reveal_at` is calculated server-side as `opened_at + reveal_delay_seconds`
  - `reveal_at` is set automatically (cannot be manipulated by client)
  - Sender identity remains hidden in response until `reveal_at` is reached
  - Automatic reveal job updates `sender_revealed_at` and `status = 'revealed'` when `reveal_at` passes

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003/open" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### DELETE /capsules/{capsule_id}

Withdraw a capsule (soft delete, sender only, before opening).

**Purpose**: Allows senders to recall unopened letters. Once withdrawn, the letter is immediately removed from the recipient's inbox and will never be delivered, including any anonymous identity.

**Response (200):**
```json
{
  "message": "Capsule deleted successfully"
}
```

**Business Rules**: 
- ✅ Only sender can delete their own capsules
- ✅ Only available before letter is opened (once opened, the moment is final)
- ✅ Sets `deleted_at` timestamp (soft delete)
- ✅ Capsule is immediately filtered out from recipient's inbox queries
- ✅ Capsule may remain visible to sender in outbox (future: muted/archived state)
- ✅ Anonymous identity is never revealed if withdrawn
- ✅ Action is irreversible

**Security**:
- Ownership verified (only sender can delete)
- Status checked (cannot delete opened letters)
- Soft delete preserves data for audit trail

**Example:**
```bash
curl -X DELETE "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

**Frontend Implementation**:
- Withdraw button appears only for unopened letters sent by current user
- Requires explicit confirmation dialog
- Shows thoughtful messaging (calm, not destructive)
- Disabled automatically once letter is opened
- Includes race condition protection and comprehensive error handling

---

## Letter Invites Endpoints ⭐ NEW

The Letter Invites API enables sending letters to unregistered users via private, secure invite links. This feature supports user acquisition while maintaining privacy and security.

### POST /letter-invites/letters/{letter_id}

Create a letter invite for sending to an unregistered user.

**Headers:**
```http
Authorization: Bearer <supabase_jwt_token>
Content-Type: application/json
```

**Path Parameters:**
- `letter_id` (UUID) - ID of the letter to create invite for

**Response (201):**
```json
{
  "invite_id": "550e8400-e29b-41d4-a716-446655440000",
  "invite_token": "abc123xyz...",
  "invite_url": "https://openon.app/invite/abc123xyz...",
  "already_exists": false
}
```

**Response (200) - If invite already exists:**
```json
{
  "invite_id": "550e8400-e29b-41d4-a716-446655440000",
  "invite_token": "abc123xyz...",
  "invite_url": "https://openon.app/invite/abc123xyz...",
  "already_exists": true
}
```

**Business Rules:**
- Only the sender can create invites for their letters
- One active invite per letter (returns existing if one exists)
- Letter must not be deleted
- Invite token is generated automatically (32+ characters, cryptographically secure)

**Example:**
```bash
curl -X POST "http://localhost:8000/letter-invites/letters/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /letter-invites/preview/{invite_token}

Get public preview of a letter invite (no authentication required).

**Path Parameters:**
- `invite_token` (string) - Invite token from the invite URL

**Response (200):**
```json
{
  "letter_id": "550e8400-e29b-41d4-a716-446655440000",
  "unlocks_at": "2025-02-01T12:00:00Z",
  "is_claimed": false,
  "countdown_seconds": 86400,
  "can_open": false
}
```

**Response (200) - If already claimed:**
```json
{
  "letter_id": "550e8400-e29b-41d4-a716-446655440000",
  "unlocks_at": "2025-02-01T12:00:00Z",
  "is_claimed": true,
  "countdown_seconds": 0,
  "can_open": false
}
```

**Business Rules:**
- No authentication required (public endpoint)
- Returns only safe public data (no sender identity, no letter content)
- Validates token format (32+ characters, base64url safe)
- Returns error if letter is deleted or invite not found

**Example:**
```bash
curl -X GET "http://localhost:8000/letter-invites/preview/abc123xyz..."
```

### POST /letter-invites/claim/{invite_token}

Claim a letter invite when user signs up.

**Headers:**
```http
Authorization: Bearer <supabase_jwt_token>
Content-Type: application/json
```

**Path Parameters:**
- `invite_token` (string) - Invite token to claim

**Response (200):**
```json
{
  "success": true,
  "letter_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Invite claimed successfully"
}
```

**Error Responses:**

**400 Bad Request** - Invite already claimed:
```json
{
  "detail": "This letter has already been opened"
}
```

**404 Not Found** - Invite not found:
```json
{
  "detail": "Invite not found"
}
```

**404 Not Found** - Letter deleted:
```json
{
  "detail": "Letter not found"
}
```

**Business Rules:**
- Only authenticated users can claim invites
- Each invite can only be claimed once (first user wins)
- When claimed:
  - Recipient is linked to the claiming user
  - Mutual connection is created between sender and receiver
  - Recipient entries are created for both users
- Atomic operation prevents race conditions

**Example:**
```bash
curl -X POST "http://localhost:8000/letter-invites/claim/abc123xyz..." \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### Business Rules

1. **One Invite Per Letter**: Each letter can have at most one active invite
2. **Single Claim**: Only the first user to claim an invite gets access
3. **Automatic Connection**: Claiming creates mutual connection between sender and receiver
4. **Immediate Unlock**: After signup, letter unlocks immediately if open time has passed
5. **Countdown Support**: If claimed before open time, countdown continues normally
6. **Revocable**: Deleting the letter invalidates the invite link
7. **No Sender Exposure**: Invite preview does not reveal sender identity

### Security

- **Token Generation**: Uses `secrets.token_urlsafe(32)` (cryptographically secure)
- **Token Validation**: Regex validation prevents injection attacks
- **RLS Policies**: Database-level security enforced via Row Level Security
- **Race Conditions**: Handled with atomic operations (`WHERE claimed_at IS NULL`)
- **Input Sanitization**: All inputs validated and sanitized

---

## Letter Replies Endpoints ⭐ NEW

> **Base Path**: `/letter-replies`  
> **Status**: ✅ Production Ready  
> **Documentation**: See [features/LETTER_REPLIES.md](../features/LETTER_REPLIES.md) for complete feature documentation

### POST /letter-replies/letters/{letter_id}

Create a one-time reply to a letter (receiver only).

**Path Parameters:**
- `letter_id` (UUID): The ID of the letter to reply to

**Request Body:**
```json
{
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️"
}
```

**Validation:**
- `reply_text`: Required, 1-60 characters
- `reply_emoji`: Required, must be one of: ❤️ 🥹 😊 😎 😢 🤍 🙏

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "letter_id": "550e8400-e29b-41d4-a716-446655440001",
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️",
  "receiver_animation_seen_at": null,
  "sender_animation_seen_at": null,
  "created_at": "2025-12-25T19:00:00Z"
}
```

**Errors:**
- `400 Bad Request`: Letter not opened, reply already exists, invalid emoji
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Letter not found

**Business Rules:**
- Only recipients can create replies
- Letter must be opened before replying
- Maximum one reply per letter (enforced at database level)
- Replies cannot be edited or deleted

### GET /letter-replies/letters/{letter_id}

Get reply for a letter (sender or receiver can view).

**Path Parameters:**
- `letter_id` (UUID): The ID of the letter

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "letter_id": "550e8400-e29b-41d4-a716-446655440001",
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️",
  "receiver_animation_seen_at": "2025-12-25T19:01:00Z",
  "sender_animation_seen_at": null,
  "created_at": "2025-12-25T19:00:00Z"
}
```

**Response (204 No Content):** Reply doesn't exist yet (expected case)

**Errors:**
- `403 Forbidden`: User is not sender or recipient
- `404 Not Found`: Letter not found

### POST /letter-replies/letters/{letter_id}/mark-receiver-animation-seen

Mark receiver animation as seen (after sending reply).

**Path Parameters:**
- `letter_id` (UUID): The ID of the letter

**Response (200 OK):**
```json
{
  "message": "Animation marked as seen"
}
```

**Errors:**
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Reply not found

### POST /letter-replies/letters/{letter_id}/mark-sender-animation-seen

Mark sender animation as seen (when viewing reply).

**Path Parameters:**
- `letter_id` (UUID): The ID of the letter

**Response (200 OK):**
```json
{
  "message": "Animation marked as seen"
}
```

**Errors:**
- `403 Forbidden`: User is not the sender
- `404 Not Found`: Reply not found

---

## Recipients Endpoints

### POST /recipients

Add a new recipient to saved contacts.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "username": "johndoe"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "owner_id": "your-user-id",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "username": "johndoe",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Validation:**
- `name`: Required, 1-255 characters
- `email`: Optional, validated if provided
- `avatar_url`: Optional
- `username`: Optional, @username for display (populated from linked user profile for connection-based recipients)

**Example:**
```bash
curl -X POST "http://localhost:8000/recipients" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "username": "johndoe"
  }'
```

### GET /recipients

List all recipients for the current user.

**Query Parameters:**
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 20, min: 1, max: 100)

**Response (200):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440004",
    "owner_id": "your-user-id",
    "name": "John Doe",
    "email": "john@example.com",
    "avatar_url": "https://example.com/avatar.jpg",
    "username": "johndoe",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
]
```

**Example:**
```bash
curl -X GET "http://localhost:8000/recipients" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /recipients/{recipient_id}

Get details of a specific recipient.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "owner_id": "your-user-id",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "username": "johndoe",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /recipients/{recipient_id}

Update a recipient.

**Request Body:**
```json
{
  "name": "John Smith",
  "email": "john.smith@example.com",
  "avatar_url": "https://example.com/new-avatar.jpg"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "name": "John Smith",
  ...
}
```

**Note**: All fields are optional. Only provided fields will be updated.

**Example:**
```bash
curl -X PUT "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "name": "John Smith",
    "email": "john.smith@example.com"
  }'
```

### DELETE /recipients/{recipient_id}

Delete a recipient.

**Response (200):**
```json
{
  "message": "Recipient deleted successfully"
}
```

**Example:**
```bash
curl -X DELETE "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

---

## Connections Endpoints

The Connections API enables users to send friend requests, establish mutual connections, and manage their social network. All connection endpoints require authentication.

### POST /connections/requests

Send a connection request to another user.

**Request Body:**
```json
{
  "to_user_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Hey, let's connect!"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "from_user_id": "your-user-id",
  "to_user_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending",
  "message": "Hey, let's connect!",
  "declined_reason": null,
  "acted_at": null,
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z",
  "from_user_first_name": "Alice",
  "from_user_last_name": "Johnson",
  "from_user_username": "alice",
  "from_user_avatar_url": "https://example.com/avatar.jpg"
}
```

**Validations:**
- Cannot send to yourself
- Cannot send if already connected
- Cannot send if pending request exists
- Must wait 7 days after decline (cooldown period)
- Maximum 5 requests per day (rate limit)
- Message is optional, max 500 characters

**Error Responses:**
- `400`: Already connected, pending request exists, or self-request
- `429`: Rate limit exceeded or cooldown period active

**Example:**
```bash
curl -X POST "http://localhost:8000/connections/requests" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "to_user_id": "550e8400-e29b-41d4-a716-446655440000",
    "message": "Hey, let'\''s connect!"
  }'
```

### PATCH /connections/requests/{request_id}

Respond to a connection request (accept or decline).

**Request Body:**
```json
{
  "status": "accepted"
}
```

Or for decline:
```json
{
  "status": "declined",
  "declined_reason": "Not interested"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "from_user_id": "sender-id",
  "to_user_id": "your-user-id",
  "status": "accepted",
  "message": "Hey, let's connect!",
  "declined_reason": null,
  "acted_at": "2025-01-15T10:35:00Z",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:35:00Z",
  "from_user_first_name": "Alice",
  "from_user_last_name": "Johnson",
  "from_user_username": "alice",
  "from_user_avatar_url": "https://example.com/avatar.jpg"
}
```

**Validations:**
- Only the recipient (to_user_id) can respond
- Request must be in `pending` status
- Status must be either `accepted` or `declined`
- If accepted: Creates mutual connection and auto-creates recipients

**Actions on Accept:**
- Creates connection record in `connections` table
- Auto-creates recipient entries for both users
- Updates request status to `accepted`

**Error Responses:**
- `403`: Not the recipient of the request
- `400`: Request already responded to
- `404`: Request not found

**Example:**
```bash
# Accept request
curl -X PATCH "http://localhost:8000/connections/requests/550e8400-e29b-41d4-a716-446655440001" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{"status": "accepted"}'

# Decline request
curl -X PATCH "http://localhost:8000/connections/requests/550e8400-e29b-41d4-a716-446655440001" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "status": "declined",
    "declined_reason": "Not interested"
  }'
```

### GET /connections/requests/incoming

Get all pending incoming connection requests.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50, min: 1, max: 100)
- `offset` (optional): Pagination offset (default: 0, min: 0)

**Response (200):**
```json
{
  "requests": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "from_user_id": "sender-id",
      "to_user_id": "your-user-id",
      "status": "pending",
      "message": "Hey, let's connect!",
      "declined_reason": null,
      "acted_at": null,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "from_user_first_name": "Alice",
      "from_user_last_name": "Johnson",
      "from_user_username": "alice",
      "from_user_avatar_url": "https://example.com/avatar.jpg"
    }
  ],
  "total": 1
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/connections/requests/incoming?limit=20&offset=0" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /connections/requests/outgoing

Get all pending outgoing connection requests.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50, min: 1, max: 100)
- `offset` (optional): Pagination offset (default: 0, min: 0)

**Response (200):**
```json
{
  "requests": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "from_user_id": "your-user-id",
      "to_user_id": "recipient-id",
      "status": "pending",
      "message": "Hey, let's connect!",
      "declined_reason": null,
      "acted_at": null,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "from_user_first_name": "Bob",
      "from_user_last_name": "Smith",
      "from_user_username": "bob",
      "from_user_avatar_url": "https://example.com/avatar.jpg"
    }
  ],
  "total": 1
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/connections/requests/outgoing?limit=20&offset=0" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /connections

Get all mutual connections for the current user.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50, min: 1, max: 100)
- `offset` (optional): Pagination offset (default: 0, min: 0)

**Response (200):**
```json
{
  "connections": [
    {
      "user_id_1": "user1-id",
      "user_id_2": "user2-id",
      "connected_at": "2025-01-15T10:35:00Z",
      "other_user_first_name": "Alice",
      "other_user_last_name": "Johnson",
      "other_user_username": "alice",
      "other_user_avatar_url": "https://example.com/avatar.jpg"
    }
  ],
  "total": 1
}
```

**Note**: The `other_user_*` fields represent the profile of the connected user (not the current user).

**Example:**
```bash
curl -X GET "http://localhost:8000/connections?limit=20&offset=0" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### Business Rules

**Connection Request Rules:**
1. Cannot send to yourself
2. Cannot send if already connected
3. Cannot send if pending request exists
4. Cooldown: 7 days after decline before retrying
5. Rate limit: Maximum 5 requests per day

**Connection Rules:**
1. Connections are bidirectional (mutual)
2. Recipients are auto-created when connection is accepted
3. Letters can only be sent to connected users

**Status Values:**
- `pending`: Request sent, awaiting response
- `accepted`: Request accepted, connection established
- `declined`: Request declined

---

## Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

### HTTP Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Common Error Scenarios

#### 401 Unauthorized

```json
{
  "detail": "Invalid authentication credentials"
}
```

**Cause**: Missing or invalid Supabase JWT token.

**Solution**: Ensure token is included in `Authorization` header and is valid.

#### 403 Forbidden

```json
{
  "detail": "You don't have permission to view this capsule"
}
```

**Cause**: User doesn't have permission to access the resource.

**Solution**: Ensure user owns the resource or has appropriate permissions.

#### 404 Not Found

```json
{
  "detail": "Capsule not found"
}
```

**Cause**: Resource doesn't exist or user doesn't have access.

**Solution**: Verify resource ID and user permissions.

#### 400 Bad Request

```json
{
  "detail": "Either body_text or body_rich_text is required"
}
```

**Cause**: Invalid request data or validation failure.

**Solution**: Check request body against API documentation.

---

## Status Values

### Capsule Status

- `sealed`: Capsule created with unlock time set (can be edited)
- `ready`: Unlock time has passed, recipient can open
- `opened`: Recipient has opened the capsule (terminal state)
- `expired`: Soft-deleted or expired

### Username Field

- `username`: Optional TEXT field containing @username for display
- For connection-based recipients: Populated from linked user's profile
- For email-based recipients: May be manually set or NULL
- Displayed as `@username` in the UI

---

## Notes

1. **Authentication**: Signup and login are handled by Supabase Auth. This backend only provides profile management.

2. **Drafts**: Drafts feature has been removed. Capsules are created directly in 'sealed' status with `unlocks_at` set.

3. **UUIDs**: All IDs are UUIDs (not strings).

4. **Timezones**: All timestamps are in UTC and timezone-aware.

5. **Anonymous Capsules**: 
   - When `is_anonymous` is true, sender info is hidden from recipient until `reveal_at` timestamp
   - Requires mutual connection (enforced at database level via RLS)
   - `reveal_delay_seconds` must be between 0-259200 (72 hours max)
   - Default delay is 6 hours (21600 seconds) if not provided
   - `reveal_at` is calculated server-side when letter is opened: `opened_at + reveal_delay_seconds`
   - Automatic reveal job updates `sender_revealed_at` and `status = 'revealed'` when `reveal_at` passes
   - Sender always sees their own identity
   - Recipient sees "Anonymous" until reveal time

6. **Letter Withdrawal**:
   - DELETE `/capsules/{capsule_id}` allows senders to withdraw unopened letters
   - Only available before letter is opened (once opened, the moment is final and respected)
   - Performs soft delete (sets `deleted_at` timestamp)
   - Letter is immediately removed from recipient's inbox queries
   - Anonymous identity is never revealed if withdrawn
   - Action is irreversible
   - Frontend includes race condition protection and comprehensive error handling

---

**Last Updated**: December 2025

**Production Status**: ✅ Ready for 500,000+ users
