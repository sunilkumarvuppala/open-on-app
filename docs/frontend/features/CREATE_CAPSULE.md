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
└── step_preview.dart               # Step 4: Preview and send
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
4. Preview

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
- Auto-save as draft (future enhancement)
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

### StepPreview

**File**: `step_preview.dart`

**Purpose**: Final step - preview and send the letter.

**Key Features**:
- Display recipient information
- Show letter title and content
- Display unlock date/time
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
5. Step 4: Preview
   - Review all information
   - Send or save as draft
   ↓
6. Success → Navigate to home
```

### Draft Flow

```
1. User writes letter content
   ↓
2. User navigates away or closes
   ↓
3. Letter saved as draft automatically
   ↓
4. User can resume from drafts screen
```

## Integration Points

### Providers Used

- `recipientsProvider`: List of recipients
- `capsuleRepositoryProvider`: Create capsule
- `draftRepositoryProvider`: Save draft

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
```dart
bool _validateRecipient() {
  if (_selectedRecipient == null) {
    throw ValidationException('Please select a recipient');
  }
  return true;
}
```

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

```dart
Future<void> _createCapsule() async {
  try {
    // Validate all steps
    if (!_validateAllSteps()) return;
    
    // Create capsule object
    final capsule = Capsule(
      id: uuid.v4(),
      label: _title,
      content: _content,
      recipientId: _selectedRecipient!.id,
      recipientName: _selectedRecipient!.name,
      unlockTime: _unlockTime!,
      status: CapsuleStatus.locked,
    );
    
    // Save to repository
    final repo = ref.read(capsuleRepositoryProvider);
    await repo.createCapsule(capsule);
    
    // Navigate to home
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter created successfully!')),
      );
    }
  } on ValidationException catch (e) {
    Logger.error('Validation error', error: e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    Logger.error('Failed to create capsule', error: e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create letter')),
    );
  }
}
```

### Saving as Draft

```dart
Future<void> _saveDraft() async {
  try {
    final draft = Draft(
      id: uuid.v4(),
      title: _title.isEmpty ? AppConstants.untitledDraftTitle : _title,
      body: _content,
      lastEdited: DateTime.now(),
    );
    
    final repo = ref.read(draftRepositoryProvider);
    await repo.saveDraft(draft);
    
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
    }
  } catch (e) {
    Logger.error('Failed to save draft', error: e);
  }
}
```

## Future Enhancements

- [ ] Auto-save drafts while writing
- [ ] AI writing assistance
- [ ] Rich text editor
- [ ] Image attachments
- [ ] Voice messages
- [ ] Templates
- [ ] Scheduled sending
- [ ] Recurring letters

## Related Documentation

- [Recipients Feature](./RECIPIENTS.md) - For recipient selection
- [Drafts Feature](./DRAFTS.md) - For draft management
- [Home Screen](./HOME.md) - For navigation after creation
- [API Reference](../API_REFERENCE.md) - For repository APIs

---

**Last Updated**: 2025

