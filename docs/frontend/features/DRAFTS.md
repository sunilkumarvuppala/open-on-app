# Drafts Feature

## Overview

The Drafts feature allows users to save incomplete letters and resume editing them later. It provides a simple interface to manage saved drafts.

## Purpose

- Save incomplete letters as drafts
- List all saved drafts
- Resume editing drafts
- Delete drafts
- View draft details

## File Structure

```
features/drafts/
└── drafts_screen.dart    # Drafts list and management
```

## Components

### DraftsScreen

**File**: `drafts_screen.dart`

**Purpose**: Display and manage saved letter drafts.

**Key Features**:
- List of all drafts
- Draft preview (title, snippet, last edited)
- Tap to edit draft
- Delete draft option
- Empty state message
- FAB to create new letter

**Layout Structure**:
```
DraftsScreen
├── AppBar (title: "Drafts")
├── Body
│   ├── Drafts List (or Empty State)
│   └── FAB (create new letter)
```

## User Flows

### Viewing Drafts

1. User navigates to drafts screen
2. List of drafts displays
3. Each draft shows:
   - Title (or "Untitled Draft")
   - Content snippet (first 100 chars)
   - Last edited date
4. User can tap to edit or delete

### Editing Draft

1. User taps on a draft
2. Navigates to create capsule screen
3. Draft data pre-filled
4. User can continue editing
5. Save as new draft or create capsule

### Creating from Drafts

1. User taps FAB
2. Navigates to create capsule screen
3. Starts fresh letter creation

### Empty State

1. User has no drafts
2. Empty state displays:
   - Icon
   - "No drafts yet" message
   - "Start writing a letter and it will appear here" subtitle
3. FAB available to create new letter

## Integration Points

### Providers Used

- `draftsProvider`: List of all drafts
- `draftRepositoryProvider`: Draft operations

### Routes

- `/drafts` - Drafts screen
- `/create-capsule` - Create/edit letter (with draft data)

### Navigation

```dart
// Navigate to drafts
context.push(Routes.drafts);

// Navigate to edit draft
context.push(
  Routes.createCapsule,
  extra: draft, // Pass draft data
);

// Navigate to create new letter
context.push(Routes.createCapsule);
```

## State Management

### Drafts List

```dart
final draftsAsync = ref.watch(draftsProvider);

return draftsAsync.when(
  data: (drafts) {
    if (drafts.isEmpty) {
      return EmptyState(...);
    }
    return ListView.builder(
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return DraftListItem(
          draft: draft,
          onTap: () => _editDraft(draft),
          onDelete: () => _deleteDraft(draft),
        );
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorDisplay(...),
);
```

## Draft Model

```dart
class Draft {
  final String id;
  final String title;
  final String body;
  final DateTime lastEdited;
}
```

## UI Components

### Draft List Item

**Features**:
- Draft title (or "Untitled Draft")
- Content snippet (truncated to 100 chars)
- Last edited date (formatted)
- Tap to edit
- Swipe to delete (future)

**Layout**:
```
DraftListItem
├── Icon (draft/edit icon)
├── Column
│   ├── Title
│   ├── Snippet
│   └── Last edited date
└── Chevron icon
```

### Empty State

**Features**:
- Draft icon
- "No drafts yet" title
- Helpful message
- FAB for creating new letter

### Floating Action Button

**Features**:
- Letter icon + "+" text
- Navigates to create capsule
- Positioned at bottom right
- Theme-colored

## Best Practices

### Draft Management

✅ **DO**:
- Auto-save drafts while writing
- Show last edited date
- Provide clear edit option
- Allow deletion

### Performance

✅ **DO**:
- Lazy load draft content
- Cache draft list
- Optimize list rendering
- Use keys for list items

### User Experience

✅ **DO**:
- Show helpful empty state
- Display clear draft info
- Easy navigation
- Quick access to create

## Code Examples

### Displaying Drafts

```dart
class DraftsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Drafts')),
      body: draftsAsync.when(
        data: (drafts) {
          if (drafts.isEmpty) {
            return EmptyState(
              icon: Icons.edit_note_outlined,
              title: 'No drafts yet',
              message: 'Start writing a letter and it will appear here',
            );
          }
          
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                leading: Icon(Icons.edit_note_outlined),
                title: Text(
                  draft.title.isEmpty 
                    ? AppConstants.untitledDraftTitle 
                    : draft.title,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.body.length > 100
                        ? '${draft.body.substring(0, 100)}...'
                        : draft.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Last edited: ${DateFormat('MMM dd, yyyy').format(draft.lastEdited)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () => _editDraft(context, draft),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () => _deleteDraft(context, ref, draft),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: 'Failed to load drafts',
          onRetry: () => ref.invalidate(draftsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.createCapsule),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline),
            SizedBox(width: 4),
            Text('+'),
          ],
        ),
      ),
    );
  }
}
```

### Editing Draft

```dart
void _editDraft(BuildContext context, Draft draft) {
  context.push(
    Routes.createCapsule,
    extra: draft, // Pass draft to pre-fill form
  );
}
```

### Deleting Draft

```dart
Future<void> _deleteDraft(
  BuildContext context,
  WidgetRef ref,
  Draft draft,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Draft?'),
      content: Text('This action cannot be undone'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    try {
      final repo = ref.read(draftRepositoryProvider);
      await repo.deleteDraft(draft.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted')),
        );
      }
    } catch (e) {
      Logger.error('Failed to delete draft', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete draft')),
        );
      }
    }
  }
}
```

## Future Enhancements

- [ ] Auto-save while writing
- [ ] Swipe to delete
- [ ] Draft search
- [ ] Draft categories/tags
- [ ] Draft templates
- [ ] Export drafts
- [ ] Draft sharing

## Related Documentation

- [Create Capsule](./CREATE_CAPSULE.md) - For editing drafts
- [Home Screen](./HOME.md) - For drafts button
- [API Reference](../API_REFERENCE.md) - For draft repository API

---

**Last Updated**: 2025

