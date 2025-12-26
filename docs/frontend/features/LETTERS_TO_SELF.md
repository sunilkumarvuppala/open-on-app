# Self Letters Feature - Frontend Implementation

**Last Updated**: January 2025  
**Status**: ✅ Production Ready  
**Related**: [Complete Feature Documentation](../../features/SELF_LETTERS.md)

---

## Overview

The Self Letters feature allows users to write sealed, irreversible, time-delayed messages to their future selves for self-reflection. These are **NOT** journaling, reminders, or editable notes—they are sealed time capsules that can only be opened after a scheduled time.

> **Note**: This document covers **frontend-specific** implementation details.  
> For complete feature documentation, see [features/SELF_LETTERS.md](../../features/SELF_LETTERS.md).  
> For backend implementation, see [backend/API_REFERENCE.md](../../backend/API_REFERENCE.md).

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
- Validates content (20-500 characters, configurable)
- Validates scheduled time (must be future)
- Validates life area enum
- Accepts optional title field
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
- `validate_content()` - Content length (20-500 chars, from settings)
- `validate_scheduled_time()` - Must be future
- `validate_life_area()` - Enum validation
- `validate_letter_for_opening()` - Ownership and time checks
- `validate_letter_for_reflection()` - Opened and not already reflected
- `open_letter()` - Uses database function (includes title in return)
- `submit_reflection()` - Uses database function

**Configuration**:
- Content length limits: `settings.self_letter_min_content_length` (default: 20)
- Content length limits: `settings.self_letter_max_content_length` (default: 500)
- Pagination: `settings.default_page_size` (default: 20)

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

**`CreateSelfLetterScreen`** - Dedicated letter creation:
- Content editor (20-500 characters)
- Character counter
- Date/time picker (presets: 1m, 3m, 6m, 1y, Custom)
- Searchable mood dropdown (20 options with emoji + text)
- Life area selection (self, work, family, money, health)
- City input (with auto-detection support)
- Invalidation of provider after creation

**Integration with Regular Flow** (`create_capsule_screen.dart`):
- Detects self-send when recipient is "myself"
- Shows self letter metadata fields conditionally
- Routes to self letter API instead of capsule API
- Passes title from draft label

**`OpenSelfLetterScreen`** - Letter opening and reflection:
- **Lock Screen** (if not yet openable):
  - Gradient background with animated lock/envelope icon
  - Title display (user-provided or "Letter to myself")
  - "Written by you" subtitle
  - Context text: "Written on a 😊 happy Friday evening"
  - Countdown display or "Ready to open!" message
  - Tap to open functionality
- **Opened Screen**:
  - Envelope icon
  - Opened date (friendly timestamp)
  - Large, centered title (Google Fonts Tangerine)
  - "Written by you" subtitle
  - Context strip: "City · Date · 😊 happy"
  - Letter body (read-only, paper-like card)
  - Reflection prompt: "How does this feel to read now?"
  - Reflection options: "Still true", "Changed", "Skipped"
  - Reflection display (if submitted)
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
- `contextText` - Formatted context ("Written on a 😊 happy Friday evening")
  - Includes mood emoji + descriptive text (e.g., "happy", "sad", "peaceful")
  - Includes weekday and time of day
  - Includes city if provided
- `hasReflection` - `reflection_answer != null`
- `canReflect` - `isOpened && !hasReflection`
- `title` - Optional title field (user-provided or extracted from content)

## User Flow

### Creation Flow (Dedicated Screen)

1. User taps "Write to myself" CTA (from Home screen or dedicated entry point)
2. Enters letter content (20-500 characters)
3. Selects scheduled open date/time (presets: 1m, 3m, 6m, 1y, Custom)
4. Optionally selects mood (searchable dropdown with 20 options)
5. Optionally selects life area (self, work, family, money, health)
6. Optionally enters city (with auto-detection support)
7. Taps "Seal Letter"
8. Letter is created and sealed immediately
9. Returns to Home screen (letter appears in "Sealed" tab)

### Creation Flow (Regular Flow)

1. User taps FAB → Create Letter
2. Step 1: Selects "myself" as recipient
3. Step 2: Writes letter content
4. Step 3: Chooses time
   - Self letter metadata section appears (mood, life area, city)
5. Step 4: Anonymous settings (skipped for self)
6. Step 5: Preview → Submit
7. Letter is created via self letter API (not capsule API)
8. Returns to Home screen (letter appears in "Sealed" tab)

### Opening Flow

1. User sees letter in "Sealed" tab (Home screen)
2. Letter shows countdown or "Ready to open" badge
3. User taps letter → Opens `OpenSelfLetterScreen`
4. **Lock Screen** (if not yet openable):
   - Shows animated lock/envelope icon
   - Displays context: "Written on a 😊 happy Friday evening"
   - Shows countdown or "Ready to open!" message
   - User taps to open (if ready)
5. **Opened Screen**:
   - Letter content is revealed
   - Title displayed prominently
   - Context strip: "City · Date · 😊 happy"
   - Reflection prompt appears: "How does this feel to read now?"
   - User selects: "Still true", "Changed", or "Skipped"
   - Reflection is saved (one-time only)
6. Returns to Home screen (letter now in "Opened" tab)

## Security

### Database Level
- ✅ RLS policies enforce user ownership
- ✅ No UPDATE/DELETE policies (immutability)
- ✅ Content visibility based on `scheduled_open_at`
- ✅ Database functions use `SECURITY DEFINER` with proper checks
- ✅ `auth.uid()` validation in all functions

### Backend Level
- ✅ Content length validation (20-500 chars, configurable)
- ✅ Scheduled time validation (must be future)
- ✅ User ownership verification (explicit checks)
- ✅ Life area enum validation
- ✅ Reflection answer validation
- ✅ SQL injection prevention (parameterized queries)
- ✅ Input sanitization

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

- **[Complete Feature Documentation](../../features/SELF_LETTERS.md)** - Comprehensive feature documentation (start here)
- **[Backend API Reference](../backend/API_REFERENCE.md#self-letters-endpoints)** - Complete API endpoint documentation
- **[Security Review](../../reviews/SELF_LETTERS_SECURITY_AND_PERFORMANCE_REVIEW.md)** - Security and performance analysis
- **[Existing Features Verification](../../reviews/EXISTING_FEATURES_VERIFICATION.md)** - Verification that regular capsules are unaffected
- **[Database Schema](../supabase/DATABASE_SCHEMA.md)** - Complete database schema reference
- **[Frontend Features](../frontend/FEATURES.md)** - Frontend features overview
- **[Features List](../../reference/FEATURES_LIST.md)** - Complete features list

---

**Last Updated**: January 2025  
**Status**: ✅ **Production Ready**
