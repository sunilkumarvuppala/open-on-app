# Anonymous Identity Hints Feature - Complete Documentation

> **Production-Ready Documentation for Anonymous Identity Hints Feature**  
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

The **Anonymous Identity Hints** feature allows senders to add optional progressive hints that reveal over time before the anonymous sender's identity is fully revealed. This feature enhances the mystery and anticipation of anonymous letters while providing clues that build excitement.

### Key Features

- ✅ **Progressive Revelation**: Hints reveal at specific time intervals before identity reveal
- ✅ **Maximum 3 Hints**: Senders can add up to 3 hints (optional)
- ✅ **Time-Based Display**: Hints appear based on elapsed time percentage
- ✅ **Anonymous Letters Only**: Only available for anonymous letters
- ✅ **Immutable**: Hints cannot be modified after letter creation
- ✅ **Secure**: Backend determines hint eligibility, RLS enforcement

### Use Cases

1. **Build Anticipation**: Gradual revelation increases excitement
2. **Provide Clues**: Senders can give hints about their identity
3. **Enhance Mystery**: Progressive hints maintain suspense
4. **Personal Touch**: Allows senders to add creative clues

### Business Rules

- **Anonymous Letters Only**: Hints only available for `is_anonymous = true` letters
- **Maximum 3 Hints**: Senders can provide 1, 2, or 3 hints
- **60 Character Limit**: Each hint is maximum 60 characters
- **Time-Based Display**: Hints appear at specific elapsed time percentages
- **Immutable**: Hints cannot be edited or deleted after creation
- **Recipient Only**: Only recipients can view hints (senders can view their own)

### Hint Display Rules

Based on number of hints provided:

- **1 hint**: Shows at 50% elapsed time
- **2 hints**: Shows at 35% and 70% elapsed time
- **3 hints**: Shows at 30%, 50%, and 85% elapsed time

**Example**: If reveal delay is 6 hours (21,600 seconds):
- **1 hint**: Shows after 3 hours (50% of 6 hours)
- **2 hints**: Shows after 2.1 hours (35%) and 4.2 hours (70%)
- **3 hints**: Shows after 1.8 hours (30%), 3 hours (50%), and 5.1 hours (85%)

---

## Architecture

### System Components

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
│                  │
│  - Hint Display │
│  - Hint Polling │
└────────┬─────────┘
         │
         │ 1. Get Current Hint
         ▼
┌─────────────────┐
│  FastAPI Backend │
│  /capsules/{id} │
│  /current-hint  │
└────────┬─────────┘
         │
         │ 2. Calculate Eligibility
         ▼
┌─────────────────┐
│   PostgreSQL     │
│  RPC Function    │
│ get_current_    │
│ anonymous_hint  │
└────────┬─────────┘
         │
         │ 3. Return Hint
         ▼
┌─────────────────┐
│  Flutter App    │
│  Display Hint   │
└─────────────────┘
```

### Data Flow

1. **Sender Creates Anonymous Letter** → Optionally adds hints (1-3)
2. **Hints Stored** → Saved in `anonymous_identity_hints` table
3. **Letter Opened** → Recipient opens letter, `opened_at` is set
4. **Time Elapses** → System calculates elapsed time percentage
5. **Hint Eligibility** → Backend determines which hint (if any) should be shown
6. **Hint Displayed** → Recipient sees hint on lock screen
7. **Identity Revealed** → After reveal delay, sender identity is shown

---

## User Flow & UI Implementation

### Sender Flow

1. **Create Anonymous Letter**
   - Toggle "Anonymous" option (only for mutual connections)
   - Set reveal delay (0h-72h, default 6h)
   - Optionally add hints (1-3 hints, max 60 chars each)

2. **Hint Entry**
   - Three optional hint fields
   - Character counter (60 max)
   - Preview of hint timing

### Receiver Flow

1. **Letter Locked**
   - Lock screen shows countdown
   - No hints visible yet

2. **Letter Opened**
   - Letter is opened
   - `opened_at` timestamp is set
   - Hint polling begins (every 30 seconds)

3. **Hint Appears**
   - When elapsed time reaches threshold, hint appears
   - Hint displayed with "Hint 1:", "Hint 2:", or "Hint 3:" prefix
   - Hint shown in styled container on lock screen

4. **Identity Revealed**
   - After reveal delay, sender identity is shown
   - Hints are no longer displayed

### UI Components

#### IdentityLockCard
- **Location**: `frontend/lib/features/capsule/identity_lock_card.dart`
- **Purpose**: Displays anonymous letter lock screen with hints
- **Features**:
  - Hint display with styled container
  - Hint polling (every 30 seconds)
  - Hint prefix ("Hint 1:", "Hint 2:", "Hint 3:")
  - Fade-in animation for hints
  - Hint result caching to prevent unnecessary API calls

#### Hint Display
- **Styling**: 
  - Subtle background container
  - Border with opacity
  - Italic text with shadow
  - Centered alignment
  - Fade-in animation

---

## Database Schema

### Table: `anonymous_identity_hints`

```sql
CREATE TABLE public.anonymous_identity_hints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id UUID NOT NULL UNIQUE REFERENCES public.capsules(id) ON DELETE CASCADE,
  hint_1 TEXT,
  hint_2 TEXT,
  hint_3 TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT anonymous_identity_hints_hint_1_length CHECK (
    hint_1 IS NULL OR LENGTH(hint_1) <= 60
  ),
  CONSTRAINT anonymous_identity_hints_hint_2_length CHECK (
    hint_2 IS NULL OR LENGTH(hint_2) <= 60
  ),
  CONSTRAINT anonymous_identity_hints_hint_3_length CHECK (
    hint_3 IS NULL OR LENGTH(hint_3) <= 60
  )
);
```

### Indexes

```sql
CREATE INDEX idx_anonymous_identity_hints_letter_id 
  ON public.anonymous_identity_hints(letter_id);
```

### Row-Level Security (RLS)

#### SELECT Policy
- **Recipients**: Can view hints for received anonymous letters
- **Senders**: Can view hints for their own letters

#### INSERT Policy
- **Senders Only**: Can insert hints for their own anonymous letters
- **Anonymous Only**: Letter must have `is_anonymous = true`

#### UPDATE/DELETE Policy
- **No Updates/Deletes**: Hints are immutable once created

### RPC Function: `get_current_anonymous_hint`

```sql
CREATE OR REPLACE FUNCTION public.get_current_anonymous_hint(
  letter_id_param UUID
)
RETURNS TABLE (
  hint_text TEXT,
  hint_index INTEGER
)
```

**Logic**:
1. Verify letter exists, is anonymous, is opened, not yet revealed
2. Calculate elapsed time percentage
3. Determine which hint (if any) should be shown based on:
   - Number of hints provided (1, 2, or 3)
   - Elapsed time percentage
   - Hint display rules (30%, 35%, 50%, 70%, 85%)
4. Return hint text and index (1, 2, or 3)

**Hint Display Thresholds**:
- **1 hint**: 50% elapsed
- **2 hints**: 35% and 70% elapsed
- **3 hints**: 30%, 50%, and 85% elapsed

---

## API Reference

### Base Path
```
/capsules
```

### Endpoints

#### 1. Get Current Hint
```http
GET /capsules/{capsule_id}/current-hint
```

**Response** (200 OK):
```json
{
  "hint_text": "We met at the coffee shop",
  "hint_index": 1
}
```

**Response** (200 OK, no hint yet):
```json
{
  "hint_text": null,
  "hint_index": null
}
```

**Errors**:
- `403 Forbidden`: User is not the recipient
- `404 Not Found`: Letter not found or not anonymous

#### 2. Create Capsule with Hints
```http
POST /capsules
```

**Request Body** (includes hints):
```json
{
  "recipient_id": "uuid",
  "title": "A letter for you",
  "body_text": "Hello...",
  "is_anonymous": true,
  "reveal_delay_seconds": 21600,
  "hint_1": "We met at the coffee shop",
  "hint_2": "You were wearing a blue jacket",
  "hint_3": "It was a rainy day"
}
```

**Note**: Hints are optional. Sender can provide 1, 2, or 3 hints.

---

## Security & Privacy

### Authentication & Authorization

1. **JWT Token Required**: All endpoints require valid authentication
2. **Recipient Verification**: Only recipients can view hints
3. **Sender Verification**: Only senders can create hints for their letters
4. **RLS Enforcement**: Database-level access control via Row-Level Security

### Input Validation

1. **Text Length**: Maximum 60 characters per hint (enforced at database level)
2. **Anonymous Only**: Hints only allowed for anonymous letters
3. **UUID Validation**: All IDs validated as UUIDs
4. **Content Sanitization**: Hint text is sanitized before storage

### Data Protection

1. **Immutable Hints**: No updates or deletes allowed
2. **Cascade Delete**: Hints deleted if letter is deleted
3. **No Personal Data**: Hints contain no sensitive information (optional clues only)
4. **Time-Based Access**: Hints only visible at specific time intervals

### Security Best Practices

- ✅ All queries use parameterized statements (SQL injection safe)
- ✅ Permission checks at API, repository, and database levels
- ✅ RLS policies enforce recipient-only access
- ✅ Backend determines hint eligibility (frontend cannot bypass)
- ✅ Error messages don't expose sensitive information

---

## Performance Optimizations

### Frontend

1. **Polling Optimization**: 
   - Poll interval: 30 seconds (`AppConstants.hintPollInterval`)
   - Only polls when letter is opened and not yet revealed
   - Stops polling when identity is revealed

2. **Result Caching**:
   - Caches hint result to prevent unnecessary API calls
   - Only refetches if hint text or index changes
   - Compares previous result before updating UI

3. **Memory Management**:
   - Timer properly cancelled in `dispose()`
   - No memory leaks from polling

### Backend

1. **Indexed Queries**: `letter_id` indexed for fast lookups
2. **Efficient Calculations**: Time calculations done at database level
3. **Cached Results**: RPC function optimized for performance

### Database

1. **Indexes**: 
   - `idx_anonymous_identity_hints_letter_id` for fast lookups
2. **Constraints**: Database-level constraints prevent invalid data
3. **RLS Performance**: RLS policies optimized for common access patterns

---

## Code Structure

### Frontend

```
frontend/lib/
├── features/capsule/
│   └── identity_lock_card.dart       # Hint display and polling
├── core/
│   ├── data/
│   │   └── api_repositories.dart      # Hint API calls
│   └── constants/
│       └── app_constants.dart         # hintPollInterval constant
└── core/models/
    └── models.dart                     # AnonymousHintResponse model
```

### Backend

```
backend/app/
├── api/
│   └── capsules.py                    # get_current_hint endpoint
├── db/
│   ├── models.py                       # AnonymousIdentityHints ORM model
│   └── repositories.py                 # Hint repository methods
└── models/
    └── schemas.py                      # AnonymousHintResponse schema
```

### Database

```
supabase/migrations/
└── 18_anonymous_identity_hints.sql   # Complete migration
```

---

## Configuration

### Constants

**Frontend** (`app_constants.dart`):
```dart
// Hint polling interval (optimized for performance)
static const Duration hintPollInterval = Duration(seconds: 30);
```

**Backend**: No special configuration required (uses existing settings)

**Database**: All constraints and limits defined in migration

---

## Troubleshooting

### Common Issues

#### Issue: Hints not appearing
**Solution**: 
- Verify letter is anonymous (`is_anonymous = true`)
- Check letter is opened (`opened_at IS NOT NULL`)
- Verify elapsed time has reached threshold
- Check hint polling is running (every 30 seconds)

#### Issue: Wrong hint appearing
**Solution**:
- Verify number of hints provided (1, 2, or 3)
- Check elapsed time percentage calculation
- Verify RPC function logic

#### Issue: Hints appearing too early/late
**Solution**:
- Check reveal delay is correct
- Verify `opened_at` timestamp
- Check time calculation in RPC function

#### Issue: Polling not working
**Solution**:
- Verify timer is started when letter is opened
- Check timer is not cancelled prematurely
- Verify `mounted` checks are in place

### Debugging

**Frontend Logging**:
```dart
Logger.debug('Hint polling - letterId: $letterId, currentHint: $_currentHintText');
```

**Backend Logging**:
```python
logger.info(f"Getting current hint for letter {capsule_id}")
```

**Database Queries**:
```sql
-- Check hints for a letter
SELECT * FROM anonymous_identity_hints WHERE letter_id = 'uuid';

-- Test RPC function
SELECT * FROM get_current_anonymous_hint('uuid');

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'anonymous_identity_hints';
```

---

## Future Enhancements

### Potential Features

- [ ] Custom hint timing (sender chooses when hints appear)
- [ ] Hint reactions (recipient can react to hints)
- [ ] Hint notifications (notify when new hint available)
- [ ] Hint analytics (track hint engagement)
- [ ] Multiple hint types (text, image, audio)

### Performance Improvements

- [ ] WebSocket for real-time hint updates (instead of polling)
- [ ] Hint result caching optimization
- [ ] Batch hint loading for multiple letters

---

## Related Documentation

- [Anonymous Letters](./frontend/features/ANONYMOUS_LETTERS.md) - Complete anonymous letters feature
- [Capsule Feature](./frontend/features/CAPSULE.md) - Letter viewing and opening
- [Backend API Reference](../backend/API_REFERENCE.md) - Complete API documentation
- [Database Schema](../supabase/DATABASE_SCHEMA.md) - Complete database schema

---

**Last Updated**: December 2025  
**Maintained By**: Engineering Team  
**Status**: ✅ Production Ready & Acquisition Ready

