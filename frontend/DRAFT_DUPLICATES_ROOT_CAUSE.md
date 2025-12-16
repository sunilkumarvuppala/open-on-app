# Root Cause: Multiple Draft Saves Creating Duplicates

## Problem
Drafts are being saved multiple times, creating duplicate entries in the draft list.

## Root Causes

### 1. **Race Condition in StepWriteLetter** ⚠️ PRIMARY ISSUE

**Location**: `frontend/lib/features/create_capsule/step_write_letter.dart`

**Problem**:
```dart
if (_currentDraftId == null) {
  // Create new draft
  final draft = await repo.createDraft(...);
  _currentDraftId = draft.id;  // ⚠️ RACE CONDITION HERE
}
```

**Scenario**:
1. User types → debounce timer fires → `_saveDraft()` called
2. `_currentDraftId` is `null`, so `createDraft()` is called
3. **Before** `_currentDraftId = draft.id` executes, another save happens:
   - User types more → another debounce fires
   - App lifecycle event (pause/background)
   - Navigation event triggers immediate save
4. Second save also sees `_currentDraftId` as `null`
5. Second `createDraft()` is called
6. **Result**: Two drafts with same content

**Why it happens**:
- `_currentDraftId` is local state, not synchronized
- `createDraft()` is async, takes time
- Between async call and state update, another save can occur
- No locking mechanism to prevent concurrent saves

### 2. **Multiple Save Systems Without Coordination**

**Three independent save systems**:

1. **StepWriteLetter** (`step_write_letter.dart`)
   - Own debounce timer
   - Own `_currentDraftId` state
   - Saves to `draftRepositoryProvider`

2. **DraftLetterNotifier** (`providers.dart`)
   - Own debounce timer  
   - Own `state.draftId` state
   - Saves to `draftRepositoryProvider`
   - Used by `DraftLetterScreen`

3. **CreateCapsuleScreen** (`create_capsule_screen.dart`)
   - Manual save on exit
   - No state tracking
   - Always calls `createDraft()`

**Problem**: These systems don't know about each other and can all save simultaneously.

### 3. **No Deduplication in Draft List Update**

**Location**: `frontend/lib/core/data/draft_storage.dart` → `_updateDraftList()`

**Previous Problem** (now fixed):
- When adding draft ID to list, check was: `if (!draftIds.contains(draftId))`
- But if two saves happen simultaneously:
  - Both read the list (both see draft ID not present)
  - Both add the draft ID
  - Result: Duplicate in list

**Current Fix**: Now deduplicates before adding, but race condition still exists.

### 4. **Async Gap in State Updates**

**The Critical Window**:
```
Time 0ms:  Save #1 starts, _currentDraftId = null
Time 10ms: Save #1 calls createDraft() (async)
Time 20ms: Save #2 starts, _currentDraftId still null!
Time 30ms: Save #2 calls createDraft() (async)
Time 50ms: Save #1 completes, sets _currentDraftId = "id1"
Time 60ms: Save #2 completes, sets _currentDraftId = "id2" (overwrites!)
```

**Result**: 
- Two drafts created (id1 and id2)
- `_currentDraftId` ends up as id2
- id1 is orphaned (never updated, just sits in list)

## Solutions Implemented

### ✅ Fix 1: Deduplication in Storage Layer
- `getAllDrafts()` now deduplicates draft IDs
- Cleans up duplicate IDs in storage
- Prevents loading same draft multiple times

### ✅ Fix 2: Deduplication in UI Layer  
- `DraftsScreen` deduplicates before display
- Final safety check

### ⚠️ Still Needed: Prevent Race Conditions

**Recommended Fix**: Add save locking mechanism

```dart
bool _isSaving = false;

Future<void> _saveDraft() async {
  // Prevent concurrent saves
  if (_isSaving) {
    Logger.debug('Save already in progress, skipping');
    return;
  }
  
  _isSaving = true;
  try {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _isSaving = false;
      return;
    }
    
    // ... save logic ...
    
    if (_currentDraftId == null) {
      final draft = await repo.createDraft(...);
      _currentDraftId = draft.id;  // Set immediately after creation
    } else {
      await repo.updateDraft(_currentDraftId!, content);
    }
  } finally {
    _isSaving = false;
  }
}
```

## Why Multiple Saves Can Happen

### Scenario 1: Rapid Typing
- User types quickly
- Each keystroke resets debounce timer
- If user pauses exactly at debounce interval, multiple saves can queue

### Scenario 2: App Lifecycle Events
- User types → debounce timer running
- App goes to background → immediate save triggered
- Debounce timer also fires
- Both try to save simultaneously

### Scenario 3: Navigation Events
- User types → debounce timer running  
- User navigates away → immediate save triggered
- Debounce timer also fires
- Both try to save simultaneously

### Scenario 4: Multiple Save Systems
- `StepWriteLetter` saves (creates draft)
- `CreateCapsuleScreen` exit handler also saves (creates another draft)
- Both don't know about each other

## Prevention Strategy

1. ✅ **Storage-level deduplication** (implemented)
2. ✅ **UI-level deduplication** (implemented)  
3. ⚠️ **Save locking** (recommended)
4. ⚠️ **Unified save system** (recommended - use one system, not three)

## Current Status

- **Duplicates are now filtered out** when loading/displaying
- **Root cause still exists** (race conditions can still create duplicates)
- **Storage is cleaned up** automatically when duplicates are detected
- **User experience**: No duplicates visible, but storage may have temporary duplicates

