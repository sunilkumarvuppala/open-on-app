# Self Letters Feature - Complete Documentation

**Last Updated**: January 2025  
**Status**: ✅ Production Ready  
**Version**: 1.0.0

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Feature Principles](#feature-principles)
3. [User Flows](#user-flows)
4. [Database Schema](#database-schema)
5. [Backend Implementation](#backend-implementation)
6. [Frontend Implementation](#frontend-implementation)
7. [UI Components](#ui-components) ⭐ NEW
8. [API Reference](#api-reference)
9. [Security & Performance](#security--performance)
10. [Testing](#testing)
11. [Troubleshooting](#troubleshooting)

---

## Overview

**Self Letters** is a first-class, isolated feature that allows users to write sealed, irreversible, time-delayed messages to their future selves for self-reflection. These are **NOT** journaling, reminders, or editable notes—they are sealed time capsules that can only be opened after a scheduled time.

### Key Characteristics

- ✅ **Isolated**: Completely separate from regular capsules (letters to others)
- ✅ **Private**: Never visible to other users
- ✅ **Irreversible**: Cannot be edited or deleted after creation
- ✅ **Time-Locked**: Content only visible after scheduled open time
- ✅ **Reflective**: One-time reflection prompt after opening

### Use Cases

- Writing to your future self on important dates (birthdays, anniversaries)
- Capturing current thoughts and feelings for later reflection
- Setting intentions and goals for future review
- Processing emotions and experiences over time

---

## Feature Principles

### Core Rules (Non-Negotiable)

1. **Self letters are never visible to other users**
   - No sharing, forwarding, or reactions
   - No anticipation signals or reply counts
   - No social UI elements

2. **No interference with existing features**
   - Regular capsules (letters to others) must behave exactly as before
   - No changes to existing database tables
   - No changes to existing APIs

3. **Immutability after creation**
   - Cannot be edited after creation
   - Cannot be deleted after creation
   - Content sealed immediately

4. **Time-based access control**
   - Content hidden until `scheduled_open_at`
   - Cannot open before scheduled time
   - Reflection only available after opening

---

## User Flows

### Flow 1: Create Self Letter (Dedicated Screen)

```
User → Home Screen → "Write to myself" CTA
  → CreateSelfLetterScreen
    → Enter content (20-500 characters)
    → Select scheduled open date (presets: 1m, 3m, 6m, 1y, Custom)
    → [Optional] Select mood (searchable dropdown)
    → [Optional] Select life area (self, work, family, money, health)
    → [Optional] Enter city
    → Preview → Submit
  → Letter sealed → Appears in "Sealed" tab
```

### Flow 2: Create Self Letter (Regular Flow)

```
User → Home Screen → FAB → Create Letter
  → Step 1: Choose Recipient → Select "myself"
  → Step 2: Write Letter
  → Step 3: Choose Time
    → [Shows] Self Letter Metadata Section (mood, life area, city)
  → Step 4: Anonymous Settings (skipped for self)
  → Step 5: Preview → Submit
  → Letter sealed → Appears in "Sealed" tab
```

### Flow 3: View Sealed Self Letter

```
User → Home Screen → "Future Me" tab
  → See self letter card
    → Title (user-provided or extracted from content)
    → "To myself" label
    → Countdown pill
    → Lock icon with animation
    → Status badge (Locked / Unlocking Soon / Ready to Open)
  → Tap to view lock screen
```

### Flow 4: Open Self Letter

```
User → Tap sealed self letter
  → Lock Screen (if not yet openable)
    → Title
    → "Written by you" subtitle
    → Context: "Written on a 😊 happy Friday evening"
    → Animated lock/envelope icon
    → Countdown or "Ready to open!" message
    → Tap to open (if ready)
  → Opened Screen
    → Envelope icon
    → Opened date
    → Title (large, centered)
    → "Written by you" subtitle
    → Context strip: "City · Date · 😊 happy"
    → Letter body (read-only)
    → [Optional] Reflection prompt
      → "How does this feel to read now?"
      → Options: Still true / Changed / Skip
      → Submit reflection (one-time)
```

### Flow 5: View Opened Self Letter

```
User → Home Screen → "Opened" tab
  → See opened self letter card
    → Title
    → "To myself" label
    → Opened badge
    → [If reflected] Reflection indicator
  → Tap to view
    → Full letter content
    → Reflection answer (if submitted)
    → Reflection date
```

---

## Database Schema

### Table: `public.self_letters`

**Migration Files**:
- `supabase/migrations/14_letters_to_self.sql` - Initial table creation
- `supabase/migrations/22_fix_open_self_letter_ambiguous_column.sql` - Function fixes
- `supabase/migrations/23_add_title_to_self_letters.sql` - Title field addition
- `supabase/migrations/24_update_open_self_letter_for_title.sql` - Function update for title

#### Schema Definition

```sql
CREATE TABLE public.self_letters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Content (immutable after seal)
  content TEXT NOT NULL,
  char_count INTEGER NOT NULL,
  title TEXT, -- Optional title (added in migration 23)
  
  -- Time-locking
  scheduled_open_at TIMESTAMPTZ NOT NULL,
  opened_at TIMESTAMPTZ,
  
  -- Context captured at write time
  mood TEXT,                    -- Emoji (e.g., "😊", "😔", "😌")
  life_area TEXT,               -- "self" | "work" | "family" | "money" | "health"
  city TEXT,
  
  -- Reflection
  reflection_answer TEXT,       -- "yes" | "no" | "skipped"
  reflected_at TIMESTAMPTZ,
  
  -- Immutability flag
  sealed BOOLEAN DEFAULT TRUE NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT self_letters_char_count_check CHECK (char_count >= 0),
  CONSTRAINT self_letters_scheduled_open_future CHECK (scheduled_open_at > created_at),
  CONSTRAINT self_letters_reflection_answer_check CHECK (
    reflection_answer IS NULL OR reflection_answer IN ('yes', 'no', 'skipped')
  ),
  CONSTRAINT self_letters_life_area_check CHECK (
    life_area IS NULL OR life_area IN ('self', 'work', 'family', 'money', 'health')
  ),
  CONSTRAINT self_letters_immutable_after_seal CHECK (sealed = TRUE)
);
```

#### Indexes

```sql
-- User lookups
CREATE INDEX idx_self_letters_user_id ON public.self_letters(user_id);

-- List queries (user + scheduled time)
CREATE INDEX idx_self_letters_user_scheduled_open 
  ON public.self_letters(user_id, scheduled_open_at);

-- Opened letters queries
CREATE INDEX idx_self_letters_user_opened_at 
  ON public.self_letters(user_id, opened_at) 
  WHERE opened_at IS NOT NULL;

-- Openable letters queries
CREATE INDEX idx_self_letters_scheduled_open_at 
  ON public.self_letters(scheduled_open_at) 
  WHERE opened_at IS NULL;
```

#### Row Level Security (RLS)

**INSERT Policy**: Users can only create their own letters
```sql
CREATE POLICY "Users can create their own self letters"
  ON public.self_letters FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND sealed = TRUE
    AND char_count >= 0
    AND scheduled_open_at > created_at
  );
```

**SELECT Policy**: Users can only read their own letters
```sql
CREATE POLICY "Users can read their own self letters"
  ON public.self_letters FOR SELECT
  USING (
    auth.uid() = user_id
    AND (
      opened_at IS NOT NULL
      OR now() >= scheduled_open_at
    )
  );
```

**UPDATE Policy**: NONE (immutable after creation)

**DELETE Policy**: NONE (irreversible)

#### Database Functions

**`open_self_letter(letter_id UUID, p_user_id UUID)`**
- Opens a self letter atomically
- Validates ownership via `p_user_id`
- Only allowed if `now() >= scheduled_open_at`
- Sets `opened_at = now()` (only once, idempotent)
- Returns letter data with full content and title

**`submit_self_letter_reflection(letter_id UUID, p_user_id UUID, answer TEXT)`**
- Records reflection answer (one-time only)
- Validates ownership via `p_user_id`
- Only allowed after letter is opened
- Validates answer: "yes", "no", or "skipped"
- Prevents duplicate submissions

---

## Backend Implementation

### Architecture

**Location**: `backend/app/api/self_letters.py`

**Service Layer**: `backend/app/services/self_letter_service.py`

**Repository Layer**: `backend/app/db/repositories.py` → `SelfLetterRepository`

**Models**: `backend/app/db/models.py` → `SelfLetter`

**Schemas**: `backend/app/models/schemas.py` → `SelfLetterCreate`, `SelfLetterResponse`

### Service Layer

**Class**: `SelfLetterService`

**Responsibilities**:
- Content validation (20-500 characters, configurable)
- Scheduled time validation (must be future)
- Life area enum validation
- Opening validation (ownership, time check)
- Reflection submission validation

**Configuration**:
- `MIN_CONTENT_LENGTH`: 20 (from `settings.self_letter_min_content_length`)
- `MAX_CONTENT_LENGTH`: 500 (from `settings.self_letter_max_content_length`)

### Repository Layer

**Class**: `SelfLetterRepository`

**Methods**:
- `create()` - Create new self letter
- `get_by_id()` - Get letter by ID
- `get_by_user()` - List letters for user (with pagination)
- `count_by_user()` - Count letters for user (optimized)

### API Endpoints

See [API Reference](#api-reference) section below.

---

## Frontend Implementation

### Architecture

**State Management**: Riverpod (`FutureProvider`)

**Key Files**:
- `frontend/lib/features/self_letters/create_self_letter_screen.dart` - Dedicated creation screen
- `frontend/lib/features/self_letters/open_self_letter_screen.dart` - Open/view screen
- `frontend/lib/core/models/models.dart` - `SelfLetter` model
- `frontend/lib/core/data/api_repositories.dart` - API repository
- `frontend/lib/core/providers/providers.dart` - `selfLettersProvider`

### Models

**Class**: `SelfLetter`

**Key Properties**:
- `id`, `userId`, `content`, `title`
- `scheduledOpenAt`, `openedAt`, `createdAt`
- `mood`, `lifeArea`, `city`
- `reflectionAnswer`, `reflectedAt`
- `sealed`, `charCount`

**Key Getters**:
- `canOpen` - Can letter be opened now?
- `isOpened` - Has letter been opened?
- `isSealed` - Is letter sealed?
- `contextText` - Formatted context string ("Written on a 😊 happy Friday evening")
- `hasReflection` - Has reflection been submitted?

### Providers

**`selfLettersProvider`**: `FutureProvider<List<SelfLetter>>`
- Fetches all self letters for current user
- Automatically refreshes on invalidation
- Handles authentication state

### Screens

**`CreateSelfLetterScreen`**:
- Multi-step form (content, date, optional metadata)
- Searchable mood dropdown (20 options with emoji + text)
- City input with auto-detection
- Life area selection
- Validation (20-500 characters)

**`OpenSelfLetterScreen`**:
- Lock screen (if not yet openable)
  - Animated lock/envelope icon
  - Countdown display
  - Context text with mood
- Opened screen
  - Letter content (read-only)
  - Reflection prompt (one-time)
  - Reflection display (if submitted)

### Integration Points

**Home Screen** (`frontend/lib/features/home/home_screen.dart`):
- **Tab Structure**: 3 tabs - "Unfolding", "Future Me", "Opened"
- **"Unfolding" Tab**: Only regular capsules (unlocking soon and upcoming), sorted by time remaining
- **"Future Me" Tab**: All sealed self letters (not yet opened), sorted by scheduled open date (most recent first)
- **"Opened" Tab**: Opened self letters and opened capsules (combined), sorted by opened date
- Uses union type `_SealedItem` for type safety in "Unfolding" tab
- Separate cards: `_SelfLetterCard` vs `_CapsuleCard`

**Create Capsule Flow** (`frontend/lib/features/create_capsule/create_capsule_screen.dart`):
- Detects self-send (`isSelfLetter` check)
- Routes to self letter creation API
- Shows self letter metadata fields conditionally

---

## API Reference

### POST `/self-letters`

**Create a new self letter**

**Request Body**:
```json
{
  "content": "string (20-500 characters)",
  "scheduled_open_at": "ISO 8601 datetime (must be future)",
  "title": "string (optional, max 255)",
  "mood": "string (optional, emoji)",
  "life_area": "string (optional: 'self' | 'work' | 'family' | 'money' | 'health')",
  "city": "string (optional)"
}
```

**Response**: `201 Created`
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "title": "string | null",
  "content": "string | null", // null if not yet openable
  "char_count": 123,
  "scheduled_open_at": "ISO 8601 datetime",
  "opened_at": "ISO 8601 datetime | null",
  "mood": "string | null",
  "life_area": "string | null",
  "city": "string | null",
  "reflection_answer": "string | null",
  "reflected_at": "ISO 8601 datetime | null",
  "sealed": true,
  "created_at": "ISO 8601 datetime"
}
```

**Errors**:
- `400 Bad Request`: Invalid content length, past scheduled time, invalid life area
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Database error

### GET `/self-letters`

**List all self letters for current user**

**Query Parameters**:
- `skip` (int, default: 0): Number of records to skip
- `limit` (int, default: 20, min: 1, max: 100): Maximum records to return

**Response**: `200 OK`
```json
{
  "letters": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "title": "string | null",
      "content": "string | null", // null if not yet openable
      "char_count": 123,
      "scheduled_open_at": "ISO 8601 datetime",
      "opened_at": "ISO 8601 datetime | null",
      "mood": "string | null",
      "life_area": "string | null",
      "city": "string | null",
      "reflection_answer": "string | null",
      "reflected_at": "ISO 8601 datetime | null",
      "sealed": true,
      "created_at": "ISO 8601 datetime"
    }
  ],
  "total": 10
}
```

**Content Visibility**:
- Content is `null` if letter is sealed AND `now() < scheduled_open_at`
- Content is included if `opened_at IS NOT NULL` OR `now() >= scheduled_open_at`

### POST `/self-letters/{letter_id}/open`

**Open a self letter (only allowed after scheduled time)**

**Response**: `200 OK`
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "title": "string | null",
  "content": "string", // Always included after opening
  "char_count": 123,
  "scheduled_open_at": "ISO 8601 datetime",
  "opened_at": "ISO 8601 datetime", // Set to now()
  "mood": "string | null",
  "life_area": "string | null",
  "city": "string | null",
  "reflection_answer": "string | null",
  "reflected_at": "ISO 8601 datetime | null",
  "sealed": true,
  "created_at": "ISO 8601 datetime"
}
```

**Errors**:
- `400 Bad Request`: Letter cannot be opened before scheduled time
- `403 Forbidden`: Not the owner
- `404 Not Found`: Letter not found
- `500 Internal Server Error`: Database error

### POST `/self-letters/{letter_id}/reflection`

**Submit reflection for an opened self letter (one-time only)**

**Request Body**:
```json
{
  "answer": "string" // "yes" | "no" | "skipped"
}
```

**Response**: `200 OK`
```json
{
  "message": "Reflection submitted successfully"
}
```

**Errors**:
- `400 Bad Request`: Letter not opened, reflection already submitted, invalid answer
- `403 Forbidden`: Not the owner
- `404 Not Found`: Letter not found
- `500 Internal Server Error`: Database error

---

## Security & Performance

### Security

✅ **Row Level Security (RLS)**: Users can only access their own letters  
✅ **Ownership Verification**: All operations verify `user_id`  
✅ **Input Validation**: Content length, scheduled time, enums validated  
✅ **SQL Injection Prevention**: All queries use parameterized statements  
✅ **Time-Based Access Control**: Content hidden until scheduled time  

**See**: [docs/reviews/SELF_LETTERS_SECURITY_AND_PERFORMANCE_REVIEW.md](../reviews/SELF_LETTERS_SECURITY_AND_PERFORMANCE_REVIEW.md)

### Performance

✅ **Database Indexes**: Optimized for common queries  
✅ **Pagination**: Efficient list queries  
✅ **Query Optimization**: Separate COUNT queries  
✅ **State Management**: Proper caching and invalidation  

**Estimated Performance** (500k+ users):
- List query: ~10ms
- Open query: ~15ms
- Create query: ~20ms

---

## Testing

### Manual Testing Checklist

**Creation**:
- [ ] Create self letter via dedicated screen
- [ ] Create self letter via regular flow (select "myself")
- [ ] Validate content length (20-500 characters)
- [ ] Validate scheduled time (must be future)
- [ ] Test optional fields (mood, life area, city)
- [ ] Verify letter appears in "Sealed" tab

**Viewing**:
- [ ] View sealed self letter (lock screen)
- [ ] Verify countdown display
- [ ] Verify context text with mood
- [ ] Verify animations and badges

**Opening**:
- [ ] Open self letter (after scheduled time)
- [ ] Verify content is visible
- [ ] Verify reflection prompt appears
- [ ] Submit reflection (all three options)
- [ ] Verify reflection cannot be changed
- [ ] Verify opened letter appears in "Opened" tab

**Security**:
- [ ] Verify users cannot access other users' letters
- [ ] Verify content hidden before scheduled time
- [ ] Verify cannot open before scheduled time
- [ ] Verify cannot edit/delete after creation

**Integration**:
- [ ] Verify self letters don't appear in regular capsule lists
- [ ] Verify regular capsules unaffected
- [ ] Verify no interference with existing features

### Automated Testing

**Backend**:
- Unit tests for service layer validation
- Integration tests for API endpoints
- Database function tests

**Frontend**:
- Widget tests for screens
- Provider tests for state management
- Integration tests for user flows

---

## Troubleshooting

### Common Issues

**Issue**: "Letter not found or access denied"
- **Cause**: Ownership verification failed
- **Solution**: Verify `user_id` matches letter owner

**Issue**: "Letter cannot be opened before scheduled time"
- **Cause**: Attempting to open before `scheduled_open_at`
- **Solution**: Wait until scheduled time or verify timezone

**Issue**: "Content is null in list response"
- **Cause**: Letter is sealed and scheduled time hasn't passed
- **Solution**: This is expected behavior. Content will be available after opening or when scheduled time passes.

**Issue**: "Reflection already submitted"
- **Cause**: Reflection can only be submitted once
- **Solution**: This is expected behavior. Reflection is immutable.

**Issue**: Backend error "column reference 'id' is ambiguous"
- **Cause**: Database function column references not qualified
- **Solution**: Apply migration `22_fix_open_self_letter_ambiguous_column.sql`

**Issue**: Backend error "column 'title' does not exist"
- **Cause**: Migration 23 not applied
- **Solution**: Apply migration `23_add_title_to_self_letters.sql`

---

## Related Documentation

- **[Frontend Feature Doc](../frontend/features/LETTERS_TO_SELF.md)** - Frontend-specific implementation details
- **[Security Review](../reviews/SELF_LETTERS_SECURITY_AND_PERFORMANCE_REVIEW.md)** - Complete security and performance analysis
- **[Existing Features Verification](../reviews/EXISTING_FEATURES_VERIFICATION.md)** - Verification that regular capsules are unaffected
- **[Backend API Reference](../backend/API_REFERENCE.md)** - Complete backend API documentation
- **[Database Schema](../supabase/DATABASE_SCHEMA.md)** - Complete database schema documentation

---

**Document Status**: ✅ Production Ready  
**Last Reviewed**: January 2025  
**Maintainer**: Development Team

