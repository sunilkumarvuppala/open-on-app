# Letter Replies Feature - Complete Documentation

> **Production-Ready Documentation for Letter Replies Feature**  
> Last Updated: December 2025  
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
10. [Troubleshooting](#troubleshooting)
11. [Future Enhancements](#future-enhancements)

---

## Overview

The **Letter Replies** feature allows recipients to send a one-time acknowledgment reply to letter senders. This feature enables emotional closure and feedback while maintaining strict one-reply-per-letter enforcement.

### Key Features

- ✅ **One-Time Only**: Maximum one reply per letter (enforced at database level)
- ✅ **Receiver Only**: Only recipients can create replies
- ✅ **Opened Letters Only**: Letter must be opened before replying
- ✅ **Emotional Animation**: Beautiful emoji shower animation when reply is sent/viewed
- ✅ **Separate Tracking**: Animation seen timestamps tracked separately for receiver and sender
- ✅ **Immutable**: Replies cannot be edited or deleted once created
- ✅ **Secure**: Full RLS enforcement, permission checks at all layers

### Use Cases

1. **Emotional Closure**: Recipients can acknowledge and respond to letters
2. **Feedback Loop**: Senders receive confirmation that their letter was meaningful
3. **Relationship Building**: Encourages continued engagement between users
4. **One-Time Response**: Prevents spam while allowing meaningful acknowledgment

### Business Rules

- **One Reply Per Letter**: Enforced by UNIQUE constraint on `letter_id`
- **Receiver Only**: Only the recipient can create a reply
- **Opened Letters Only**: Letter must have `opened_at` timestamp
- **No Edits/Deletes**: Replies are permanent once created
- **Animation Tracking**: Separate timestamps for receiver and sender animation views

---

## Architecture

### System Components

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
│                  │
│  - Reply Composer│
│  - Animation     │
│  - Reply Display │
└────────┬─────────┘
         │
         │ 1. Create Reply
         ▼
┌─────────────────┐
│  FastAPI Backend │
│  /letter-replies │
└────────┬─────────┘
         │
         │ 2. Validate & Store
         ▼
┌─────────────────┐
│   PostgreSQL     │
│ letter_replies   │
│     Table        │
└─────────────────┘
```

### Data Flow

1. **Receiver Opens Letter** → Letter `opened_at` is set
2. **Reply Composer Appears** → Receiver can compose reply
3. **Reply Created** → Stored in `letter_replies` table
4. **Animation Shown** → Receiver sees emoji shower animation
5. **Sender Sees Reply** → "See how it was received" button appears
6. **Sender Views Reply** → Sender sees emoji shower animation
7. **Animation Tracking** → Separate timestamps for receiver and sender

---

## User Flow & UI Implementation

### Receiver Flow

1. **Letter Opened**
   - Letter is opened by recipient
   - `opened_at` timestamp is set
   - Reply composer appears below letter content

2. **Compose Reply**
   - Select emoji from fixed set: ❤️ 🥹 😊 😎 😢 🤍 🙏
   - Enter text (max 60 characters)
   - Click "Send" or "Skip"

3. **Reply Sent**
   - Reply is created in database
   - Emoji shower animation plays
   - Composer disappears
   - Reply is permanent

### Sender Flow

1. **Reply Notification**
   - Sender opens letter
   - "See how it was received" button appears
   - Button shows: "They've left a short response."

2. **View Reply**
   - Sender clicks "See how it was received"
   - Full-screen emoji shower animation plays
   - Reply text and emoji are revealed
   - Animation timestamp is recorded

### UI Components

#### LetterReplyComposer
- **Location**: `frontend/lib/features/capsule/letter_reply_composer.dart`
- **Purpose**: Allows receiver to compose reply
- **Features**:
  - Single-line text input (max 60 chars)
  - Horizontal scrolling emoji picker
  - Send and Skip buttons
  - Auto-hides if reply already exists
  - Safety check: Hides if user is sender

#### EmotionalReplyRevealScreen
- **Location**: `frontend/lib/features/capsule/emotional_reply_reveal_screen.dart`
- **Purpose**: Full-screen animation when reply is sent/viewed
- **Features**:
  - Emoji shower animation (3.5 seconds)
  - Text fade-in reveal
  - Skippable by tap
  - Respects "Reduce Motion" accessibility setting

#### OpenedLetterScreen Integration
- **Location**: `frontend/lib/features/capsule/opened_letter_screen.dart`
- **Features**:
  - Shows reply composer for receivers
  - Shows "See how it was received" button for senders
  - Fade-in animation for reply section
  - Real-time reply loading via Supabase Realtime

---

## Database Schema

### Table: `letter_replies`

```sql
CREATE TABLE public.letter_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
  
  -- Reply content
  reply_text VARCHAR(60) NOT NULL,
  reply_emoji VARCHAR(4) NOT NULL,
  
  -- Animation tracking (separate for receiver and sender)
  receiver_animation_seen_at TIMESTAMPTZ,
  sender_animation_seen_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT letter_replies_text_length CHECK (char_length(reply_text) <= 60),
  CONSTRAINT letter_replies_emoji_check CHECK (
    reply_emoji IN ('❤️', '🥹', '😊', '😎', '😢', '🤍', '🙏')
  ),
  CONSTRAINT letter_replies_one_per_letter UNIQUE (letter_id)
);
```

### Indexes

```sql
CREATE INDEX idx_letter_replies_letter_id ON public.letter_replies(letter_id);
CREATE INDEX idx_letter_replies_created_at ON public.letter_replies(created_at);
```

### Row-Level Security (RLS)

#### SELECT Policy
- Receivers can view their own replies
- Senders can view replies to their letters

#### INSERT Policy
- Only recipients can create replies
- Letter must be opened (`opened_at IS NOT NULL`)
- Only one reply per letter (enforced by UNIQUE constraint)

#### UPDATE Policy
- Receivers can update their animation timestamp
- Senders can update their animation timestamp
- No other fields can be updated

#### DELETE Policy
- No deletes allowed (replies are permanent)

### Helper Function: `create_letter_reply`

```sql
CREATE OR REPLACE FUNCTION public.create_letter_reply(
  p_letter_id UUID,
  p_reply_text VARCHAR(60),
  p_reply_emoji VARCHAR(4)
)
RETURNS public.letter_replies
```

**Validations**:
- User must be authenticated
- User must be the recipient
- Letter must exist and be opened
- Reply must not already exist
- Emoji must be from allowed set
- Text must be ≤ 60 characters

---

## API Reference

### Base Path
```
/letter-replies
```

### Endpoints

#### 1. Create Reply
```http
POST /letter-replies/letters/{letter_id}
```

**Request Body**:
```json
{
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️"
}
```

**Response** (201 Created):
```json
{
  "id": "uuid",
  "letter_id": "uuid",
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️",
  "receiver_animation_seen_at": null,
  "sender_animation_seen_at": null,
  "created_at": "2025-12-25T19:00:00Z"
}
```

**Errors**:
- `400 Bad Request`: Letter not opened, reply already exists, invalid emoji
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Letter not found

#### 2. Get Reply
```http
GET /letter-replies/letters/{letter_id}
```

**Response** (200 OK):
```json
{
  "id": "uuid",
  "letter_id": "uuid",
  "reply_text": "Thank you so much!",
  "reply_emoji": "❤️",
  "receiver_animation_seen_at": "2025-12-25T19:01:00Z",
  "sender_animation_seen_at": null,
  "created_at": "2025-12-25T19:00:00Z"
}
```

**Response** (204 No Content): Reply doesn't exist yet (expected case)

**Errors**:
- `403 Forbidden`: User is not sender or recipient
- `404 Not Found`: Letter not found

#### 3. Mark Receiver Animation Seen
```http
POST /letter-replies/letters/{letter_id}/mark-receiver-animation-seen
```

**Response** (200 OK):
```json
{
  "message": "Animation marked as seen"
}
```

**Errors**:
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Reply not found

#### 4. Mark Sender Animation Seen
```http
POST /letter-replies/letters/{letter_id}/mark-sender-animation-seen
```

**Response** (200 OK):
```json
{
  "message": "Animation marked as seen"
}
```

**Errors**:
- `403 Forbidden`: User is not the sender
- `404 Not Found`: Reply not found

---

## Security & Privacy

### Authentication & Authorization

1. **JWT Token Required**: All endpoints require valid authentication
2. **Recipient Verification**: `verify_capsule_recipient()` checks user is recipient
3. **Sender Verification**: `verify_capsule_sender()` checks user is sender
4. **RLS Enforcement**: Database-level access control via Row-Level Security

### Input Validation

1. **Text Length**: Maximum 60 characters (enforced at database level)
2. **Emoji Validation**: Must be from allowed set (enforced at database level)
3. **UUID Validation**: All IDs validated as UUIDs
4. **Content Sanitization**: Text is sanitized before storage

### Data Protection

1. **One Reply Per Letter**: UNIQUE constraint prevents duplicates
2. **Immutable Replies**: No updates or deletes allowed
3. **Cascade Delete**: Reply deleted if letter is deleted
4. **No Personal Data**: Replies contain no sensitive information

### Security Best Practices

- ✅ All queries use parameterized statements (SQL injection safe)
- ✅ Permission checks at API, repository, and database levels
- ✅ Error messages don't expose sensitive information
- ✅ Rate limiting via existing infrastructure
- ✅ Audit logging for all reply operations

---

## Performance Optimizations

### Frontend

1. **Caching**: Reply data cached in state, only reloaded when needed
2. **Realtime Updates**: Supabase Realtime subscription for instant updates
3. **Debouncing**: Share creation debounced to prevent rapid requests
4. **Lazy Loading**: Animation screen only loaded when needed
5. **Memory Management**: All timers and subscriptions properly disposed

### Backend

1. **Indexed Queries**: `letter_id` and `created_at` indexed
2. **Efficient Joins**: Optimized queries for recipient verification
3. **Connection Pooling**: Database connection pooling via SQLAlchemy
4. **Error Handling**: Fast-fail validation to reduce database load

### Database

1. **Indexes**: 
   - `idx_letter_replies_letter_id` for fast lookups
   - `idx_letter_replies_created_at` for sorting
2. **Constraints**: Database-level constraints prevent invalid data
3. **RLS Performance**: RLS policies optimized for common access patterns

---

## Code Structure

### Frontend

```
frontend/lib/
├── features/capsule/
│   ├── letter_reply_composer.dart      # Reply composer widget
│   ├── emotional_reply_reveal_screen.dart  # Animation screen
│   └── opened_letter_screen.dart       # Integration point
├── core/
│   ├── data/
│   │   └── repositories.dart           # LetterReplyRepository
│   └── models/
│       └── models.dart                 # LetterReply model
└── core/constants/
    └── app_constants.dart              # Constants (opacity, durations)
```

### Backend

```
backend/app/
├── api/
│   └── letter_replies.py               # API endpoints
├── db/
│   ├── models.py                       # LetterReply ORM model
│   └── repositories.py                 # LetterReplyRepository
└── models/
    └── schemas.py                      # Pydantic schemas
```

### Database

```
supabase/migrations/
└── 17_letter_replies_feature.sql      # Complete migration
```

---

## Configuration

### Constants

**Frontend** (`app_constants.dart`):
```dart
// Reply composer dimensions
static const double letterReplyEmojiSize = 32.0;
static const double letterReplyEmojiContainerSize = 56.0;
static const Duration letterReplyEmojiAnimationDuration = Duration(milliseconds: 200);

// Opened letter screen
static const Duration openedLetterReplyFadeDuration = Duration(milliseconds: 600);
static const Duration openedLetterReplyFadeDelay = Duration(milliseconds: 1000);
static const double openedLetterSeeReplyButtonOpacity = 0.85;
```

**Backend**: No special configuration required (uses existing settings)

**Database**: All constraints and limits defined in migration

---

## Troubleshooting

### Common Issues

#### Issue: Reply composer not showing
**Solution**: 
- Verify user is the recipient (not sender)
- Check letter is opened (`opened_at IS NOT NULL`)
- Verify reply doesn't already exist

#### Issue: "Reply already exists" error
**Solution**: 
- Check database for existing reply
- Verify UNIQUE constraint is working
- Check for race conditions in frontend

#### Issue: Animation not playing
**Solution**:
- Check "Reduce Motion" accessibility setting
- Verify animation controllers are properly initialized
- Check for errors in console

#### Issue: "See how it was received" button not visible
**Solution**:
- Verify reply exists in database
- Check fade animation is at full opacity
- Verify user is the sender

### Debugging

**Frontend Logging**:
```dart
Logger.debug('Reply UI check - isSender: $isSender, hasReply: ${_reply != null}');
```

**Backend Logging**:
```python
logger.info(f"Reply created for letter {letter_id} by user {current_user.user_id}")
```

**Database Queries**:
```sql
-- Check if reply exists
SELECT * FROM letter_replies WHERE letter_id = 'uuid';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'letter_replies';
```

---

## Future Enhancements

### Potential Features

- [ ] Reply reactions (emoji reactions to replies)
- [ ] Reply editing (with time limit)
- [ ] Reply notifications (push notifications when reply received)
- [ ] Reply analytics (track reply rates)
- [ ] Multiple reply options (different reply types)

### Performance Improvements

- [ ] Reply caching strategy optimization
- [ ] Batch reply loading for multiple letters
- [ ] Animation performance improvements

---

## Related Documentation

- [Capsule Feature](./frontend/features/CAPSULE.md) - Letter viewing and opening
- [Anonymous Letters](./frontend/features/ANONYMOUS_LETTERS.md) - Anonymous letter feature
- [Backend API Reference](../backend/API_REFERENCE.md) - Complete API documentation
- [Database Schema](../supabase/DATABASE_SCHEMA.md) - Complete database schema

---

**Last Updated**: December 2025  
**Maintained By**: Engineering Team  
**Status**: ✅ Production Ready & Acquisition Ready

