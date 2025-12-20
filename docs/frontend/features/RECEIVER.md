# Receiver Screen Feature

## Overview

The Receiver Screen (Inbox) is the main screen for users receiving letters. It displays all incoming capsules organized into three tabs based on their unlock status.

## Purpose

- Display incoming capsules in organized tabs
- Show sender information
- Display unlock countdowns
- Provide empty state with share link CTA
- Navigate to capsule detail screens

## File Structure

```
features/receiver/
└── receiver_home_screen.dart    # Receiver's inbox screen
```

## Components

### ReceiverHomeScreen

**File**: `receiver_home_screen.dart`

**Purpose**: Main screen displaying receiver's incoming capsules in three tabs.

**Key Features**:
- User greeting with avatar
- "Your incoming capsules" subtitle
- Three tabs: Sealed, Ready, Opened
- Empty state with share link CTA
- Magic dust background animation
- Tab animations matching home screen style

**Tabs**:

1. **Sealed Tab** (`_OpeningSoonTab`)
   - Label: "Sealed" (with lock icon)
   - Shows capsules unlocking within 7 days
   - Uses `incomingOpeningSoonCapsulesProvider`
   - Displays countdown timers
   - Animated "Unlocking Soon" badges

2. **Ready Tab** (`_LockedTab`)
   - Label: "Ready" (with sparkles icon)
   - Shows capsules locked for more than 7 days
   - Uses `incomingLockedCapsulesProvider`
   - Displays lock badges
   - Shows unlock dates

3. **Opened Tab** (`_OpenedTab`)
   - Label: "Opened" (with heart icon)
   - Shows already opened incoming capsules
   - Uses `incomingOpenedCapsulesProvider`
   - Displays open date
   - Shows sender information

**Layout Structure**:
```
ReceiverHomeScreen
├── MagicDustBackground
│   └── Container (gradient)
│       └── SafeArea
│           └── Column
│               ├── Header (avatar + greeting)
│               ├── Header Separator
│               ├── TabBar (with animations)
│               └── TabBarView (tab content)
```

### ReceiverCapsuleCard

**File**: `receiver_home_screen.dart` (internal widget)

**Purpose**: Widget for displaying incoming capsule information.

**Key Features**:
- Envelope icon with incoming indicator badge
- Sender name with heart emoji ("From Priya ❤️") or "Anonymous" for anonymous letters
- Anonymous indicator icon (`Icons.visibility_off_outlined`) for anonymous letters
- Animated anonymous avatar icon (alternating icons) before reveal
- Capsule title/label
- Status badge (locked, unlocking soon, opened)
- Unlock date/time
- Countdown display
- Reveal countdown for anonymous letters ("Reveals in 5h 12m")
- Tap to navigate to capsule detail

**Visual Differences from Sender Card**:
- Shows "From [Sender Name] ❤️" instead of "To [Recipient Name]"
- Shows "Anonymous" for anonymous letters before reveal
- Anonymous indicator icon appears before status icon
- Animated anonymous avatar icon (alternating `Icons.account_circle` and `Icons.help_outline`)
- Envelope icon has incoming indicator badge (small white circle)
- Uses same status badges and styling

## User Flows

### Viewing Incoming Capsules

1. User opens inbox tab
2. Tabs display incoming capsules based on status
3. User can switch between tabs
4. Tapping a capsule navigates to detail screen

### Empty State

1. User has no incoming capsules
2. Empty state displays
3. Shows "Share your link to receive capsules" message
4. CTA button to share link (feature to be implemented)

### Opening a Capsule

1. User taps on an unlocked capsule
2. Navigates to opening animation screen
3. Animation plays
4. Letter content revealed

## Integration Points

### Providers Used

- `currentUserProvider`: Current user data
- `selectedColorSchemeProvider`: Theme colors
- `incomingLockedCapsulesProvider(userId)`: Locked incoming capsules
- `incomingOpeningSoonCapsulesProvider(userId)`: Opening soon capsules
- `incomingOpenedCapsulesProvider(userId)`: Opened incoming capsules

### Routes

- `/inbox` - Receiver home screen
- `/capsule/:id` - Locked capsule view
- `/capsule/:id/opening` - Opening animation
- `/capsule/:id/opened` - Opened letter view

### Navigation

```dart
// Navigate to locked capsule
context.push('/capsule/${capsule.id}', extra: capsule);

// Navigate to opened letter
context.push('/capsule/${capsule.id}/opened', extra: capsule);
```

## Performance Optimizations

### ListView Optimization

- **Keys**: All ListView items have `ValueKey` for efficient recycling
- **PageStorageKey**: Scroll position preserved on tab switches
- **RepaintBoundary**: Capsule cards wrapped for performance

```dart
ListView.builder(
  key: const PageStorageKey('incoming_locked_capsules'),
  itemBuilder: (context, index) {
    return Padding(
      key: ValueKey('incoming_locked_${capsule.id}'),
      child: ReceiverCapsuleCard(capsule: capsule),
    );
  },
)
```

### DateFormat Caching

```dart
// Cached to avoid recreation
static final _dateFormat = DateFormat('MMM dd, yyyy');
static final _timeFormat = DateFormat('h:mm a');
```

## UI Components

### Tab Bar

- Three tabs with icons:
  - 🔒 Locked (lock outline icon)
  - ✨ Opening Soon (sparkles icon)
  - ❤️ Opened (heart icon)
- Animated selection indicator
- Sparkle micro-animations
- Gradient background for selected tab
- Glow ring effect

### Empty State

- Icon and message
- "Share your link to receive capsules" CTA
- Centered layout
- Theme-aware styling

## State Management

### Tab Controller

```dart
class _ReceiverHomeScreenState extends ConsumerState<ReceiverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

### Async State Handling

```dart
final capsulesAsync = ref.watch(incomingLockedCapsulesProvider(userId));

return capsulesAsync.when(
  data: (capsules) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorDisplay(...),
);
```

## Best Practices

### Performance

✅ **DO**:
- Use keys for ListView items
- Cache DateFormat instances
- Use RepaintBoundary for animations
- Optimize tab animations

### Error Handling

✅ **DO**:
- Handle async states properly
- Show loading indicators
- Display error messages
- Provide retry options

### UI/UX

✅ **DO**:
- Show empty states with helpful messages
- Use consistent spacing
- Follow theme colors
- Match home screen styling

## Code Examples

### Displaying Incoming Capsules

```dart
final capsulesAsync = ref.watch(incomingLockedCapsulesProvider(userId));

return capsulesAsync.when(
  data: (capsules) {
    if (capsules.isEmpty) {
      return EmptyState(
        icon: Icons.mail_outline,
        title: 'No incoming capsules',
        message: 'Share your link to receive capsules',
        action: ElevatedButton(
          onPressed: () {
            // TODO: Implement share link functionality
          },
          child: const Text('Share Link'),
        ),
      );
    }
    
    return ListView.builder(
      key: const PageStorageKey('incoming_locked_capsules'),
      itemCount: capsules.length,
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        return Padding(
          key: ValueKey('incoming_locked_${capsule.id}'),
          child: InkWell(
            onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
            child: _ReceiverCapsuleCard(capsule: capsule),
          ),
        );
      },
    );
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => ErrorDisplay(
    message: 'Failed to load capsules',
    onRetry: () => ref.invalidate(incomingLockedCapsulesProvider(userId)),
  ),
);
```

## Differences from Home Screen

### Visual Differences

- Shows "Your incoming capsules" instead of "Your time capsules"
- Displays sender name instead of recipient name
- Envelope icon has incoming indicator badge
- No "Create Letter" button (receivers don't create)
- No FAB (different navigation needs)

### Functional Differences

- Uses incoming capsule providers
- Filters capsules by receiver (asSender: false)
- Empty state encourages sharing link
- Navigation to receiver-specific capsule views

## Anonymous Letters Display

Anonymous letters are displayed with special indicators:

- **Anonymous Avatar**: Animated icon (alternating `Icons.account_circle` and `Icons.help_outline`) with fade transitions
- **Anonymous Indicator**: `Icons.visibility_off_outlined` icon appears before status icon
- **Sender Name**: Shows "Anonymous" until reveal time
- **Reveal Countdown**: Shows "Reveals in 5h 12m" format
- **Automatic Update**: When reveal time arrives, sender identity appears automatically via realtime subscription

**Pull-to-Refresh**: All tabs support pull-to-refresh with improved visibility (thicker stroke, subtle background)

## Future Enhancements

- [x] Pull to refresh ✅ (Implemented)
- [ ] Share link functionality
- [ ] Search incoming capsules
- [ ] Filter by sender
- [ ] Sort options
- [ ] Notification badges

## Related Documentation

- [Home Screen](./HOME.md) - For sender home screen
- [Capsule Viewing](./CAPSULE.md) - For capsule detail screens
- [Anonymous Letters Feature](../../anonymous_letters.md) - Complete anonymous letters documentation
- [Performance Optimizations](../PERFORMANCE_OPTIMIZATIONS.md) - For performance details

---

**Last Updated**: 2025

