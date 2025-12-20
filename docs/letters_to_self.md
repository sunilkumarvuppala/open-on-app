# Letters to Self Feature

## Overview

The Letters to Self feature allows users to write sealed, irreversible, time-delayed messages to their future selves for self-reflection. These are **NOT** journaling, reminders, or editable notes—they are sealed time capsules that can only be opened after a scheduled time.

## Key Principles

✅ **NON-NEGOTIABLE REQUIREMENTS:**

- 🔒 **Irreversibility**: No edit, recall, or delete after creation
- ⏰ **Time-Locked Content**: No previews before scheduled open time
- 🎯 **Reflection Focus**: One-time reflection prompt after opening
- 👤 **Self-Only**: Applies ONLY to letters to self (sender = recipient)

## Database Implementation

### Migration File

**`14_letters_to_self.sql`** - Complete implementation including:
- `self_letters` table with all required fields
- RLS policies (user can only insert/read their own letters)
- Content visibility based on `scheduled_open_at`
- `open_self_letter()` RPC function (atomic opening)
- `submit_self_letter_reflection()` RPC function (one-time reflection)
- Proper indexes for performance
- Constraints for immutability

### Database Schema

**Table**: `public.self_letters`

**Key Fields**:
- `id` (UUID, PRIMARY KEY)
- `user_id` (UUID, FK → `auth.users.id`)
- `content` (TEXT, NOT NULL) - Letter content (hidden until scheduled time)
- `char_count` (INTEGER, NOT NULL) - Character count (280-500)
- `scheduled_open_at` (TIMESTAMPTZ, NOT NULL) - When letter can be opened
- `opened_at` (TIMESTAMPTZ) - When letter was opened
- `mood` (TEXT) - Optional context: "calm", "anxious", "tired", etc.
- `life_area` (TEXT) - Optional context: "self", "work", "family", "money", "health"
- `city` (TEXT) - Optional context
- `reflection_answer` (TEXT) - One-time: "yes", "no", or "skipped"
- `reflected_at` (TIMESTAMPTZ) - When reflection was submitted
- `sealed` (BOOLEAN, DEFAULT TRUE) - Always TRUE (immutable)
- `created_at` (TIMESTAMPTZ, NOT NULL)

**Constraints**:
- `char_count >= 0`
- `scheduled_open_at > created_at` (must be future)
- `reflection_answer IN ('yes', 'no', 'skipped')` if provided
- `life_area IN ('self', 'work', 'family', 'money', 'health')` if provided
- `sealed = TRUE` (always sealed, immutable)

**Indexes**:
- `idx_self_letters_user_id` on `(user_id)`
- `idx_self_letters_user_scheduled_open` on `(user_id, scheduled_open_at)`
- `idx_self_letters_user_opened_at` on `(user_id, opened_at)` WHERE `opened_at IS NOT NULL`
- `idx_self_letters_scheduled_open_at` on `(scheduled_open_at)` WHERE `opened_at IS NULL`

### Row Level Security (RLS)

**INSERT Policy**: Users can only create their own letters
- `auth.uid() = user_id`
- `sealed = TRUE` (always sealed immediately)

**SELECT Policy**: Users can only read their own letters
- `auth.uid() = user_id`
- Content only visible if `opened_at IS NOT NULL` OR `now() >= scheduled_open_at`

**UPDATE Policy**: NONE (immutable after creation)

**DELETE Policy**: NONE (irreversible)

### Database Functions

#### `open_self_letter(letter_id UUID)`
- Opens a self letter atomically
- Only allowed if `now() >= scheduled_open_at`
- Sets `opened_at = now()` (only once, idempotent)
- Returns letter data with full content

#### `submit_self_letter_reflection(letter_id UUID, answer TEXT)`
- Records reflection answer (one-time only)
- Only allowed after letter is opened
- Validates answer: "yes", "no", or "skipped"
- Prevents duplicate submissions

## Backend Implementation

### API Endpoints

**POST `/self-letters`** - Create a new self letter
- Validates content (280-500 characters)
- Validates scheduled time (must be future)
- Validates life area enum
- Creates letter with `sealed = TRUE`
- Returns letter (content hidden if not yet openable)

**GET `/self-letters`** - List all self letters for user
- Pagination support (`skip`, `limit`)
- Returns metadata for all letters
- Content only included if `opened_at IS NOT NULL` OR `now() >= scheduled_open_at`
- Optimized COUNT query for total

**POST `/self-letters/{letter_id}/open`** - Open a self letter
- Validates scheduled time has passed
- Uses `open_self_letter()` RPC function
- Returns full letter content
- Triggers reflection prompt in frontend

**POST `/self-letters/{letter_id}/reflection`** - Submit reflection
- Validates letter is opened
- Validates reflection not already submitted
- Uses `submit_self_letter_reflection()` RPC function
- One-time submission (cannot be changed)

### Service Layer

**`SelfLetterService`** - Business logic and validation:
- `validate_content()` - Content length (280-500 chars)
- `validate_scheduled_time()` - Must be future
- `validate_life_area()` - Enum validation
- `validate_letter_for_opening()` - Ownership and time checks
- `validate_letter_for_reflection()` - Opened and not already reflected
- `open_letter()` - Uses database function
- `submit_reflection()` - Uses database function

## Frontend Implementation

### Provider

**`selfLettersProvider`** - `FutureProvider<List<SelfLetter>>`
- Fetches all self letters for authenticated user
- Handles authentication errors gracefully
- Auto-disposes when not in use

### Screens

**`SelfLettersScreen`** - Main screen with tabs:
- **Waiting Tab**: Letters not yet opened (scheduled time not reached or not opened)
- **Archive Tab**: Opened letters
- Efficient single-pass filtering
- Pull-to-refresh support

**`CreateSelfLetterScreen`** - Letter creation:
- Content editor (280-500 characters)
- Character counter
- Date/time picker (future dates only)
- Optional context (mood, life area, city)
- "Seal Confirmation Modal" before creation
- Invalidation of provider after creation

**`OpenSelfLetterScreen`** - Letter opening and reflection:
- Shows letter if scheduled time passed
- "Open Letter" button if not yet opened
- Full content display after opening
- Reflection prompt: "Does this still feel true?"
- Reflection options: "Yes", "Not anymore", "Skip"
- One-time reflection submission
- Invalidation of provider after reflection

### Models

**`SelfLetter`** - Model with computed properties:
- `canOpen` - `scheduled_open_at <= now()`
- `isOpenable` - `canOpen && opened_at == null`
- `isOpened` - `opened_at != null`
- `isSealed` - `scheduled_open_at > now()`
- `timeUntilOpen` - Duration until open time
- `timeUntilOpenText` - Formatted text ("Opens in 3 days")
- `contextText` - Formatted context (mood, life area, city)
- `hasReflection` - `reflection_answer != null`
- `canReflect` - `isOpened && !hasReflection`

## User Flow

### Creation Flow

1. User taps "Write to Future Me" button
2. Enters letter content (280-500 characters)
3. Selects scheduled open date/time (future only)
4. Optionally adds context (mood, life area, city)
5. Taps "Seal Letter"
6. Confirmation modal appears: "Once sealed, this message cannot be changed"
7. User confirms → Letter is created and sealed immediately
8. Returns to list screen

### Opening Flow

1. User sees letter in "Waiting" tab
2. When scheduled time arrives, letter shows "Ready to open"
3. User taps letter → Opens `OpenSelfLetterScreen`
4. Shows context and "Open Letter" button
5. User taps "Open Letter"
6. Letter content is revealed
7. Reflection prompt appears: "Does this still feel true?"
8. User selects: "Yes", "Not anymore", or "Skip"
9. Reflection is saved (one-time only)
10. Returns to list screen (letter now in "Archive" tab)

## Security

### Database Level
- ✅ RLS policies enforce user ownership
- ✅ No UPDATE/DELETE policies (immutability)
- ✅ Content visibility based on `scheduled_open_at`
- ✅ Database functions use `SECURITY DEFINER` with proper checks
- ✅ `auth.uid()` validation in all functions

### Backend Level
- ✅ Content length validation (280-500 chars)
- ✅ Scheduled time validation (must be future)
- ✅ User ownership verification
- ✅ Life area enum validation
- ✅ Reflection answer validation

### Frontend Level
- ✅ User authentication checks
- ✅ Proper error handling
- ✅ No data leakage

## Performance

### Optimizations
- ✅ Optimized COUNT query (`count_by_user`) instead of `len()`
- ✅ Proper pagination with `skip` and `limit`
- ✅ Efficient single-pass filtering in UI
- ✅ Indexes on `user_id`, `scheduled_open_at`, `opened_at`
- ✅ Provider auto-disposal
- ✅ Cache invalidation after create/reflection

## Related Documentation

- [Database Schema](../supabase/DATABASE_SCHEMA.md) - Complete schema reference
- [Backend API Reference](../backend/API_REFERENCE.md) - API endpoints
- [Frontend Features](../frontend/FEATURES.md) - Frontend features overview
- [Features List](../FEATURES_LIST.md) - Complete features list

---

**Last Updated**: January 2025  
**Status**: ✅ **Production Ready**
