# Create Capsule Feature

## Overview

The Create Capsule feature provides a multi-step flow for users to create time-locked letters. It guides users through recipient selection, letter writing, time selection, and preview before sending.

## Purpose

- Create new time-locked letters
- Select recipients
- Write letter content
- Set unlock date and time
- Preview before sending
- Save as draft

## File Structure

```
features/create_capsule/
├── create_capsule_screen.dart      # Main flow controller
├── step_choose_recipient.dart      # Step 1: Select recipient
├── step_write_letter.dart          # Step 2: Write letter
├── step_choose_time.dart           # Step 3: Set unlock time
├── step_anonymous_settings.dart    # Step 4: Anonymous settings (optional)
└── step_preview.dart               # Step 5: Preview and send
```

## Components

### CreateCapsuleScreen

**File**: `create_capsule_screen.dart`

**Purpose**: Main controller for the multi-step creation flow.

**Key Features**:
- Manages step navigation
- Maintains form state
- Validates before proceeding
- Handles submission
- Saves as draft

**Flow Steps**:
1. Choose Recipient
2. Write Letter
3. Choose Time
4. Anonymous Settings (optional, only for mutual connections)
5. Preview

**State Management**:
- Uses `PageController` for step navigation
- Maintains capsule data through steps
- Validates each step before proceeding

### StepChooseRecipient

**File**: `step_choose_recipient.dart`

**Purpose**: First step - select recipient for the letter.

**Key Features**:
- Display list of recipients
- Search/filter recipients
- Select recipient
- Add new recipient option
- Validation: Recipient must be selected

**User Flow**:
1. Display recipients list
2. User selects recipient
3. Validate selection
4. Navigate to next step

**Integration**:
- Uses `recipientsProvider` to fetch recipients
- Navigates to `Routes.addRecipient` if needed

### StepWriteLetter

**File**: `step_write_letter.dart`

**Purpose**: Second step - write the letter content.

**Key Features**:
- Title/Subject input
- Letter content text area
- Character count
- Input validation
- Auto-save as draft (debounced, 800ms)
- AI writing assistance (future enhancement)

**Validation**:
- Title: Required, max 200 characters
- Content: Required, max 10,000 characters
- Uses `Validation` utilities

**User Flow**:
1. Enter letter title
2. Write letter content
3. Validate inputs
4. Navigate to next step

### StepChooseTime

**File**: `step_choose_time.dart`

**Purpose**: Third step - set unlock date and time.

**Key Features**:
- Date picker for unlock date
- Time picker for unlock time
- Validation: Date must be in future
- Preview of selected date/time
- Time zone handling

**Validation**:
- Date must be in the future
- Time must be valid
- Minimum time in future (e.g., 1 hour)

**User Flow**:
1. Select unlock date
2. Select unlock time
3. Validate selection
4. Navigate to preview

### StepAnonymousSettings

**File**: `step_anonymous_settings.dart`

**Purpose**: Fourth step - configure anonymous letter settings (only shown for mutual connections).

**Key Features**:
- Anonymous toggle (only shown if recipient is mutual connection)
- Reveal delay selector (0h, 1h, 6h default, 12h, 24h, 48h, 72h max)
- Helper text explaining anonymous feature
- Mutual connection validation
- Saves anonymous settings to draft

**Validation**:
- Checks if recipient is mutual connection before showing toggle
- Defaults to 6 hours if anonymous enabled but no delay selected
- Maximum delay is 72 hours (enforced at database level)

**User Flow**:
1. Check if recipient is mutual connection
2. If yes: Show anonymous toggle and delay options
3. If no: Show message that anonymous letters require mutual connection
4. User selects delay (or leaves default 6 hours)
5. Navigate to preview

**Security**: 
- Client-side check is for UX only
- Server enforces mutual connection requirement
- Database RLS policies prevent bypass

### StepPreview

**File**: `step_preview.dart`

**Purpose**: Final step - preview and send the letter.

**Key Features**:
- Display recipient information
- Show letter title and content
- Display unlock date/time
- Show anonymous status and reveal delay (if anonymous)
- Edit option (go back to previous steps)
- Send button
- Save as draft option

**User Flow**:
1. Review all information
2. Option to edit any step
3. Send letter or save as draft
4. Navigate to home on success

## User Flow

### Complete Creation Flow

```
1. User taps "Create a New Letter"
   ↓
2. Step 1: Choose Recipient
   - Select from list or add new
   ↓
3. Step 2: Write Letter
   - Enter title and content
   ↓
4. Step 3: Choose Time
   - Select unlock date and time
   ↓
5. Step 4: Anonymous Settings (optional)
   - If mutual connection: Show anonymous toggle
   - Select reveal delay (default: 6 hours)
   - If not mutual connection: Show info message
   ↓
6. Step 5: Preview
   - Review all information (including anonymous status)
   - Send or save as draft
   ↓
7. Success → Navigate to home
```

### Draft Flow

```
1. User writes letter content
   ↓
2. Auto-save triggers after 800ms debounce
   ↓
3. If no draftId exists: Create new draft
   If draftId exists: Update existing draft
   ↓
4. Draft saved locally (SharedPreferences)
   ↓
5. User can resume from drafts screen
   ↓
6. Opening draft restores content and continues editing
   ↓
7. Subsequent saves update existing draft (not create new)
```

## Integration Points

### Providers Used

- `recipientsProvider`: List of recipients
- `capsuleRepositoryProvider`: Create capsule
- `draftRepositoryProvider`: Save draft
- `draftCapsuleProvider`: Multi-step form state

### Utilities Used

- `RecipientResolver`: Resolves recipient UUIDs (handles validation and lookup)
- `UuidUtils`: Validates UUIDs throughout the flow
- `Validation`: Validates form inputs (content, label, unlock date)

### Routes

- `/create-capsule` - Main creation screen
- `/recipients/add` - Add new recipient

### Navigation

```dart
// Navigate to create capsule
context.push(Routes.createCapsule);

// Navigate to add recipient
context.push(Routes.addRecipient);

// Navigate back to home
context.pop(); // After successful creation
```

## State Management

### Form State

```dart
class _CreateCapsuleScreenState extends ConsumerState<CreateCapsuleScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form data
  Recipient? _selectedRecipient;
  String _title = '';
  String _content = '';
  DateTime? _unlockTime;
}
```

### Step Navigation

```dart
void _nextStep() {
  if (_validateCurrentStep()) {
    _pageController.nextPage(
      duration: AppConstants.animationDurationMedium,
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }
}

void _previousStep() {
  _pageController.previousPage(
    duration: AppConstants.animationDurationMedium,
    curve: Curves.easeInOut,
  );
  setState(() => _currentStep--);
}
```

## Validation

### Step-by-Step Validation

**Step 1 - Recipient**:
- Recipient must be selected from the list
- Validation happens automatically when recipient is selected
- UUID validation and resolution handled by `RecipientResolver` during capsule creation

**Step 2 - Letter Content**:
```dart
bool _validateContent() {
  if (_title.isEmpty) {
    throw ValidationException('Title is required');
  }
  if (_title.length > AppConstants.maxTitleLength) {
    throw ValidationException('Title too long');
  }
  if (_content.isEmpty) {
    throw ValidationException('Letter content is required');
  }
  if (_content.length > AppConstants.maxContentLength) {
    throw ValidationException('Content too long');
  }
  return true;
}
```

**Step 3 - Time**:
```dart
bool _validateTime() {
  if (_unlockTime == null) {
    throw ValidationException('Please select unlock time');
  }
  if (_unlockTime!.isBefore(DateTime.now())) {
    throw ValidationException('Unlock time must be in the future');
  }
  return true;
}
```

## Best Practices

### Form Validation

✅ **DO**:
- Validate on each step
- Show clear error messages
- Prevent navigation if invalid
- Use Validation utilities

### Error Handling

✅ **DO**:
- Handle validation errors
- Handle network errors
- Show user-friendly messages
- Allow retry

### User Experience

✅ **DO**:
- Show progress indicator
- Allow going back to edit
- Auto-save drafts
- Provide clear CTAs

## Code Examples

### Creating a Capsule

The capsule creation process uses `RecipientResolver` to ensure proper UUID validation and resolution:

```dart
Future<void> _handleSubmit() async {
  final draft = ref.read(draftCapsuleProvider);
  final user = ref.read(currentUserProvider).asData?.value;
  
  if (user == null || !draft.isValid) {
    // Show validation error
    return;
  }
  
  try {
    // Convert draft to capsule
    final capsule = draft.toCapsule(
      senderId: user.id,
      senderName: user.name,
    );
    
    // Create capsule (RecipientResolver handles UUID validation internally)
    final repo = ref.read(capsuleRepositoryProvider);
    await repo.createCapsule(capsule);
    
    // Navigate to home
    if (mounted) {
      context.go(Routes.home);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter created successfully! 💌')),
      );
    }
  } catch (e) {
    Logger.error('Failed to create capsule', error: e);
    // Error handling...
  }
}
```

**Key Points**:
- `DraftCapsule.toCapsule()` creates a `Capsule` with `recipient.id` as `receiverId`
- `createCapsule()` uses `RecipientResolver.resolveRecipientId()` to:
  - Validate UUID format
  - Find recipient by ID or `linkedUserId`
  - Fallback to name matching if needed
  - Return validated recipient UUID
- All UUID validation uses `UuidUtils` for consistency

### Saving as Draft

**Auto-Save (in StepWriteLetter)**:
```dart
// Auto-save is handled automatically in StepWriteLetter
// It checks if draftId exists to decide between create/update
final draftId = _currentDraftId ?? draftCapsule.draftId;

if (draftId == null) {
  // Create new draft
  final draft = await repo.createDraft(
    userId: user.id,
    title: draftCapsule.label,
    content: content,
    recipientName: draftCapsule.recipient?.name,
    recipientAvatar: draftCapsule.recipient?.avatar,
  );
  _currentDraftId = draft.id;
  ref.read(draftCapsuleProvider.notifier).setDraftId(draft.id);
} else {
  // Update existing draft
  await repo.updateDraft(
    draftId,
    content,
    title: draftCapsule.label,
    recipientName: draftCapsule.recipient?.name,
    recipientAvatar: draftCapsule.recipient?.avatar,
  );
}
```

**Manual Save (from CreateCapsuleScreen)**:
```dart
Future<void> _saveAsDraft() async {
  final draft = ref.read(draftCapsuleProvider);
  final content = draft.content?.trim() ?? '';
  
  if (content.isEmpty) return;
  
  final repo = ref.read(draftRepositoryProvider);
  
  // Check if draft ID already exists (from auto-save)
  if (draft.draftId != null) {
    // Update existing draft
    await repo.updateDraft(
      draft.draftId!,
      content,
      title: draft.label,
      recipientName: draft.recipient?.name,
      recipientAvatar: draft.recipient?.avatar,
    );
  } else {
    // Create new draft
    final newDraft = await repo.createDraft(
      userId: user.id,
      title: draft.label,
      content: content,
      recipientName: draft.recipient?.name,
      recipientAvatar: draft.recipient?.avatar,
    );
    ref.read(draftCapsuleProvider.notifier).setDraftId(newDraft.id);
  }
}
```

## Future Enhancements

- [x] Auto-save drafts while writing ✅ (Implemented)
- [x] Anonymous letters ✅ (Implemented)
- [ ] AI writing assistance
- [ ] Rich text editor
- [ ] Image attachments
- [ ] Voice messages
- [ ] Templates
- [ ] Scheduled sending
- [ ] Recurring letters

## Related Documentation

- [Recipients Feature](./RECIPIENTS.md) - For recipient selection
- [Drafts Feature](./DRAFTS.md) - For draft management and auto-save
- [Home Screen](./HOME.md) - For navigation after creation
- [Anonymous Letters Feature](../../anonymous_letters.md) - Complete anonymous letters documentation
- [API Reference](../API_REFERENCE.md) - For repository APIs

---

**Last Updated**: 2025

