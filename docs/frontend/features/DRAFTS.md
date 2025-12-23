# Drafts Feature

## Overview

The Drafts feature provides local storage for unsaved letter content, allowing users to save their work in progress and resume editing later. Drafts are stored locally using SharedPreferences and persist across app restarts.

## Purpose

- Save letter content as drafts while writing
- Auto-save drafts during letter creation
- Resume editing saved drafts
- Manage and delete drafts
- Prevent data loss when navigating away

## File Structure

```
features/drafts/
├── drafts_screen.dart          # Drafts list screen
└── draft_letter_screen.dart    # Draft editing screen (if separate)

core/data/
├── draft_storage.dart          # Local storage implementation
└── repositories.dart            # DraftRepository interface
```

## Components

### DraftsScreen

**File**: `drafts_screen.dart`

**Purpose**: Displays all saved drafts for the current user.

**Key Features**:
- Lists all drafts sorted by last edited (most recent first)
- Shows recipient name, title, and last edited time
- Navigates to create capsule screen with draft data
- Delete draft functionality
- Pull-to-refresh support
- Empty state when no drafts exist

**Layout**:
- Compact card layout with avatar, recipient name, title, and timestamp
- No content preview (removed for cleaner UI)
- Delete button on each card

**State Management**:
- Uses `draftsProvider(userId)` to fetch drafts
- Uses `draftsNotifierProvider(userId)` for delete operations

### Draft Storage

**File**: `draft_storage.dart`

**Purpose**: Provides crash-safe local storage for drafts using SharedPreferences.

**Key Features**:
- Parallel draft loading for performance
- Queue-based locking to prevent race conditions
- Automatic list management
- Verification after save operations

**Storage Strategy**:
- Each draft stored as JSON: `"draft_<draftId>"`
- Draft list stored as JSON array: `"drafts_<userId>"`
- Immediate synchronous saves (crash-safe)

### DraftRepository

**File**: `repositories.dart`

**Purpose**: Repository interface for draft operations.

**Methods**:
- `createDraft()` - Create new draft
- `updateDraft()` - Update existing draft
- `getDraft()` - Get draft by ID
- `getDrafts()` - Get all drafts for user
- `deleteDraft()` - Delete a draft

## User Flow

### Creating a Draft

```
1. User starts writing in CreateCapsuleScreen
   ↓
2. Auto-save triggers after debounce (800ms)
   ↓
3. If no draftId exists:
   - Create new draft
   - Store draftId in state
   ↓
4. If draftId exists:
   - Update existing draft
   ↓
5. Draft saved locally
```

### Opening a Draft

```
1. User navigates to Drafts screen
   ↓
2. User taps on a draft card
   ↓
3. Draft data passed to CreateCapsuleScreen
   - draftId set in draftCapsuleProvider
   - Content, title, recipient restored
   ↓
4. User continues editing
   ↓
5. Auto-save updates existing draft (not creates new)
```

### Editing and Saving Draft

**Critical Implementation Detail**:

When opening an existing draft, the `draftId` must be properly initialized in `StepWriteLetter` to ensure updates instead of creating new drafts:

```dart
// In StepWriteLetter.initState()
_currentDraftId = draft.draftId; // CRITICAL: Initialize from provider

// In _saveDraft()
final draftId = _currentDraftId ?? draftCapsule.draftId; // Fallback check
if (draftId == null) {
  // Create new draft
} else {
  // Update existing draft
}
```

This ensures that when a user opens a draft and edits it, the changes update the existing draft rather than creating a duplicate.

## Integration Points

### Providers Used

- `draftsProvider(userId)`: List of drafts (FutureProvider.family)
- `draftsNotifierProvider(userId)`: Draft operations (StateNotifierProvider.family)
- `draftCapsuleProvider`: Draft state during creation
- `draftRepositoryProvider`: Draft repository instance

### Routes

- `/drafts` - Drafts list screen
- `/create-capsule` - Create capsule screen (with draft data)

### Navigation

```dart
// Navigate to drafts
context.push(Routes.drafts);

// Navigate to create capsule with draft
final draftData = DraftNavigationData(
  draftId: draft.id,
  content: draft.body,
  title: draft.title,
  recipientName: draft.recipientName,
  recipientAvatar: draft.recipientAvatar,
);
context.push(Routes.createCapsule, extra: draftData);
```

## State Management

### Draft Model

```dart
class Draft {
  final String id;
  final String userId;
  final String? title;
  final String body;
  final String? recipientName;
  final String? recipientAvatar;
  final DateTime lastEdited;
  final DateTime createdAt;
}
```

### Draft State in CreateCapsuleScreen

```dart
// DraftCapsule model includes draftId
class DraftCapsule {
  final String? draftId;  // Track draft ID if one exists
  final String? content;
  final String? label;
  final Recipient? recipient;
  // ...
}
```

## Auto-Save Implementation

### StepWriteLetter Auto-Save

**Location**: `step_write_letter.dart`

**Behavior**:
- Debounced auto-save (800ms delay)
- Saves on content changes
- Saves on title changes
- Prevents concurrent saves with `_isSaving` flag

**Key Logic**:
```dart
// Initialize draftId when opening existing draft
_currentDraftId = draft.draftId;

// Check both local variable and provider state
final draftId = _currentDraftId ?? draftCapsule.draftId;

if (draftId == null) {
  // Create new draft
  final draft = await repo.createDraft(...);
  _currentDraftId = draft.id;
  ref.read(draftCapsuleProvider.notifier).setDraftId(draft.id);
} else {
  // Update existing draft
  await repo.updateDraft(draftId, content, ...);
  _currentDraftId = draftId;
  ref.read(draftCapsuleProvider.notifier).setDraftId(draftId);
}
```

### DraftLetterNotifier Auto-Save

**Location**: `providers.dart`

**Behavior**:
- Used for dedicated draft editing screen
- Similar debounced auto-save
- Updates state immediately after save

## Performance Optimizations

### 1. Parallel Draft Loading

Drafts are loaded in parallel using `Future.wait()` instead of sequentially:

```dart
final List<Future<Draft?>> draftFutures = draftIds
    .map((draftId) => getDraft(draftId))
    .toList();
final List<Draft?> loadedDrafts = await Future.wait(draftFutures);
```

**Result**: 10x faster loading (from ~500ms to ~50ms for 10 drafts)

### 2. No Duplicate Checking on Auto-Save

Removed expensive duplicate checking that loaded all drafts on every save:

**Before**:
```dart
final existingDrafts = await repo.getDrafts(user.id);
final matchingDraft = existingDrafts.firstWhere(...);
```

**After**:
```dart
// Direct create/update based on draftId
if (_currentDraftId == null) {
  await repo.createDraft(...);
} else {
  await repo.updateDraft(_currentDraftId, ...);
}
```

### 3. Selective Provider Invalidation

Only invalidate drafts provider on creation, not on every update:

```dart
if (_currentDraftId == null) {
  await repo.createDraft(...);
  ref.invalidate(draftsProvider(user.id)); // Only on creation
} else {
  await repo.updateDraft(_currentDraftId, ...);
  // No invalidation on update
}
```

### 4. Instant Navigation

Use already-loaded draft data for navigation instead of reloading:

```dart
// Instant navigation using already-loaded draft data
final draftData = DraftNavigationData(
  draftId: draft.id,
  content: draft.body,
  title: draft.title,
  recipientName: draft.recipientName,
  recipientAvatar: draft.recipientAvatar,
);
context.push(Routes.createCapsule, extra: draftData);
```

## Best Practices

### Draft ID Management

✅ **DO**:
- Always initialize `_currentDraftId` from `draftCapsuleProvider.draftId` when opening existing draft
- Check both local variable and provider state before creating new draft
- Update both local variable and provider state after draft creation
- Use `draftId` as single source of truth

❌ **DON'T**:
- Create new draft if `draftId` exists
- Forget to sync `_currentDraftId` with provider state
- Check for duplicates by loading all drafts

### Error Handling

✅ **DO**:
- Handle storage errors gracefully
- Show user-friendly error messages
- Log errors for debugging
- Verify saves after operations

### Performance

✅ **DO**:
- Load drafts in parallel
- Avoid unnecessary provider invalidations
- Use debouncing for auto-save
- Prevent concurrent saves with flags

## Code Examples

### Creating a Draft

```dart
final repo = ref.read(draftRepositoryProvider);
final draft = await repo.createDraft(
  userId: user.id,
  title: 'My Letter',
  content: 'Letter content...',
  recipientName: 'John Doe',
  recipientAvatar: 'avatar_url',
);
```

### Updating a Draft

```dart
final repo = ref.read(draftRepositoryProvider);
await repo.updateDraft(
  draftId,
  'Updated content...',
  title: 'Updated Title',
  recipientName: 'John Doe',
  recipientAvatar: 'avatar_url',
);
```

### Opening a Draft

```dart
// In CreateCapsuleScreen.initState()
if (widget.draftData != null) {
  ref.read(draftCapsuleProvider.notifier).setContent(draftData.content);
  ref.read(draftCapsuleProvider.notifier).setLabel(draftData.title);
  ref.read(draftCapsuleProvider.notifier).setDraftId(draftData.draftId);
  
  // Restore recipient if available
  if (draftData.recipientName != null) {
    // ... restore recipient
  }
}
```

### Deleting a Draft

```dart
final notifier = ref.read(draftsNotifierProvider(userId).notifier);
await notifier.deleteDraft(draft.id);
ref.invalidate(draftsProvider(userId));
```

## Future Enhancements

- [ ] Remote sync for drafts
- [ ] Draft templates
- [ ] Draft search/filter
- [ ] Draft expiration/cleanup
- [ ] Draft sharing
- [ ] Rich text editor for drafts

## Related Documentation

- [Create Capsule Feature](./CREATE_CAPSULE.md) - Letter creation flow
- [Home Screen](./HOME.md) - Access to drafts
- [Performance Optimizations](../../development/PERFORMANCE_OPTIMIZATIONS.md) - Draft performance improvements

---

**Last Updated**: January 2025



