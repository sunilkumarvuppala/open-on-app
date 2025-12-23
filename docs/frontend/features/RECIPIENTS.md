# Recipients Feature

## Overview

The Recipients feature allows users to manage their letter recipients. Users can view, add, edit, and delete recipients.

## Purpose

- Manage letter recipients
- Add new recipients
- Edit recipient information
- Delete recipients
- View recipient list

## File Structure

```
features/recipients/
├── recipients_screen.dart      # List of recipients
└── add_recipient_screen.dart    # Add/edit recipient form
```

## Components

### RecipientsScreen

**File**: `recipients_screen.dart`

**Purpose**: Display list of all recipients.

**Key Features**:
- List of recipients
- Recipient cards with avatar
- Add new recipient button
- Edit recipient option
- Delete recipient option
- Empty state
- Search functionality (future)

**Layout Structure**:
```
RecipientsScreen
├── AppBar (title: "Recipients")
├── Body
│   ├── Recipients List (or Empty State)
│   └── FAB (add new recipient)
```

### AddRecipientScreen

**File**: `add_recipient_screen.dart`

**Purpose**: Add new recipient or edit existing one.

**Key Features**:
- Name input (required)
- Email input (optional)
- User search (to link to registered users)
- Username display (@username) - from backend
- Photo picker (future)
- Validation
- Save/Cancel buttons

**User Flow**:
1. User enters recipient information
2. Validation checks inputs
3. Save recipient
4. Navigate back to list

## User Flows

### Viewing Recipients

1. User navigates to recipients screen
2. List of recipients displays
3. Each recipient shows:
   - Avatar/initial
   - Name
   - Email (if available)
   - Username (@username) - from backend
4. User can tap to edit or delete

### Adding Recipient

1. User taps "Add Recipient" or FAB
2. AddRecipientScreen displays
3. User enters information:
   - Name (required)
   - Email (optional)
   - Search and select registered user (optional, links recipient to user account)
   - Username (@username) - from backend
4. User saves
5. Navigate back to list

### Editing Recipient

1. User taps on recipient
2. AddRecipientScreen displays with pre-filled data
3. User edits information
4. User saves
5. Navigate back to list

### Deleting Recipient

1. User long-presses or taps delete
2. Confirmation dialog
3. User confirms
4. Recipient deleted
5. List updates

## Integration Points

### Providers Used

- `recipientsProvider`: List of recipients
- `recipientRepositoryProvider`: Recipient operations

### Routes

- `/recipients` - Recipients list
- `/recipients/add` - Add/edit recipient

### Navigation

```dart
// Navigate to recipients
context.push(Routes.recipients);

// Navigate to add recipient
context.push(Routes.addRecipient);

// Navigate to edit recipient
context.push(
  Routes.addRecipient,
  extra: recipient, // Pass recipient to edit
);
```

## State Management

### Recipients List

```dart
final recipientsAsync = ref.watch(recipientsProvider(userId));

return recipientsAsync.when(
  data: (recipients) {
    if (recipients.isEmpty) {
      return EmptyState(...);
    }
    return ListView.builder(
      itemCount: recipients.length,
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        return RecipientCard(
          recipient: recipient,
          onTap: () => _editRecipient(recipient),
          onDelete: () => _deleteRecipient(recipient),
        );
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorDisplay(...),
);
```

## Validation

### Recipient Validation

```dart
bool _validateRecipient() {
  if (_nameController.text.isEmpty) {
    throw ValidationException('Name is required');
  }
  
  if (_nameController.text.length > AppConstants.maxRecipientNameLength) {
    throw ValidationException('Name too long');
  }
  
  if (_emailController.text.isNotEmpty) {
    if (!Validation.isValidEmail(_emailController.text)) {
      throw ValidationException('Invalid email format');
    }
    if (_emailController.text.length > AppConstants.maxEmailLength) {
      throw ValidationException('Email too long');
    }
  }
  
  // Username is handled by backend, no frontend validation needed
  
  return true;
}
```

## UI Components

### Recipient Card

**Features**:
- Avatar (initial or photo)
- Name
- Email (if available)
- Username (@username) - from backend
- Edit/Delete options

**Layout**:
```
RecipientCard
├── Avatar (CircleAvatar)
├── Column
│   ├── Name
│   ├── Email (if available)
│   └── Username (@username) - from backend
└── Actions (edit/delete)
```

### Add/Edit Form

**Features**:
- Name input (required)
- Email input (optional, validated)
- User search (to link recipient to registered user account)
- Username display (@username) - populated from backend
- Photo picker button (future)
- Save/Cancel buttons

## Best Practices

### Validation

✅ **DO**:
- Validate all inputs
- Show clear error messages
- Use Validation utilities
- Check length limits

### Error Handling

✅ **DO**:
- Handle validation errors
- Handle network errors
- Show user-friendly messages
- Allow retry

### User Experience

✅ **DO**:
- Show empty state
- Provide clear CTAs
- Easy navigation
- Confirmation for delete

## Code Examples

### Adding Recipient

```dart
Future<void> _saveRecipient() async {
  try {
    // Validate
    if (!_validateRecipient()) return;
    
    final recipient = Recipient(
      id: widget.recipient?.id ?? uuid.v4(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty 
        ? null 
        : _emailController.text.trim(),
      // Username is populated from backend, not set manually
    );
    
    final repo = ref.read(recipientRepositoryProvider);
    
    if (widget.recipient == null) {
      await repo.createRecipient(recipient);
    } else {
      await repo.updateRecipient(recipient);
    }
    
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.recipient == null 
              ? 'Recipient added' 
              : 'Recipient updated'
          ),
        ),
      );
    }
  } on ValidationException catch (e) {
    Logger.error('Validation error', error: e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    Logger.error('Failed to save recipient', error: e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save recipient')),
    );
  }
}
```

## Future Enhancements

- [ ] Photo picker for avatars
- [ ] Search recipients
- [ ] Filter recipients
- [ ] Recipient groups
- [ ] Import contacts
- [ ] Recipient statistics
- [ ] Favorite recipients

## Related Documentation

- [Create Capsule](./CREATE_CAPSULE.md) - For recipient selection
- [Home Screen](./HOME.md) - For FAB navigation
- [API Reference](../../reference/API_REFERENCE.md) - For recipient repository API

---

**Last Updated**: 2025

