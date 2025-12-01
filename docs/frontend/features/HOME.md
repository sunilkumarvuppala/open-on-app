# Home Screen Feature

## Overview

The Home Screen is the main screen for users who send letters (senders). It displays all sent capsules organized into three tabs based on their unlock status.

## Purpose

- Display sent capsules in organized tabs
- Show capsule status (unlocking soon, upcoming, opened)
- Quick access to create new letters
- Access to drafts
- Navigate to recipients

## File Structure

```
features/home/
├── home_screen.dart      # Main home screen with tabs
└── capsule_card.dart     # Reusable capsule card widget
```

## Components

### HomeScreen

**File**: `home_screen.dart`

**Purpose**: Main screen displaying sender's capsules in three tabs.

**Key Features**:
- User greeting with avatar
- "Create a New Letter" button
- Drafts button with count
- Three tabs: Unfolding, Sealed, Revealed
- Floating Action Button (FAB) for recipients
- Magic dust background animation
- Tab animations with sparkle effects

**Tabs**:

1. **Unfolding Tab** (`_UnlockingSoonTab`)
   - Label: "Unfolding" (with sparkles icon)
   - Shows capsules unlocking within 7 days
   - Uses `unlockingSoonCapsulesProvider`
   - Displays countdown timers
   - Animated "Unlocking Soon" badges

2. **Sealed Tab** (`_UpcomingTab`)
   - Label: "Sealed" (with lock icon)
   - Shows capsules unlocking later than 7 days
   - Uses `upcomingCapsulesProvider`
   - Shows unlock dates

3. **Revealed Tab** (`_OpenedTab`)
   - Label: "Revealed" (with heart icon)
   - Shows already opened capsules
   - Uses `openedCapsulesProvider`
   - Displays open date and reactions

**Layout Structure**:
```
HomeScreen
├── MagicDustBackground
│   └── Container (gradient)
│       └── SafeArea
│           └── Column
│               ├── Header (avatar + greeting)
│               ├── Header Separator
│               ├── Create Letter Button
│               ├── Drafts Button
│               ├── TabBar (with animations)
│               └── TabBarView (tab content)
└── FloatingActionButton (Recipients)
```

### CapsuleCard

**File**: `capsule_card.dart` (in home directory)

**Purpose**: Reusable widget for displaying capsule information.

**Key Features**:
- Envelope icon with gradient
- Recipient name
- Capsule title/label
- Status badge (locked, unlocking soon, opened)
- Unlock date/time
- Countdown display
- Reaction display (if any)
- Tap to navigate to capsule detail

**Status Badges**:
- `StatusPill.lockedDynamic()` - For locked capsules
- `AnimatedUnlockingSoonBadge()` - For unlocking soon
- `StatusPill.readyToOpen()` - For ready to open
- `StatusPill.opened()` - For opened capsules

## User Flows

### Viewing Capsules

1. User opens app → Home screen loads
2. Tabs display capsules based on status
3. User can switch between tabs
4. Tapping a capsule navigates to detail screen

### Creating a Letter

1. User taps "Create a New Letter" button
2. Navigates to `Routes.createCapsule`
3. Multi-step creation flow begins

### Accessing Drafts

1. User taps "Drafts (X)" button
2. Navigates to `Routes.drafts`
3. Drafts screen displays saved drafts

### Managing Recipients

1. User taps FAB (people icon + "+")
2. Navigates to `Routes.recipients`
3. Recipients screen displays

## Integration Points

### Providers Used

- `currentUserProvider`: Current user data
- `selectedColorSchemeProvider`: Theme colors
- `upcomingCapsulesProvider(userId)`: Upcoming capsules
- `unlockingSoonCapsulesProvider(userId)`: Unlocking soon capsules
- `openedCapsulesProvider(userId)`: Opened capsules
- `draftsCountProvider`: Draft count

### Routes

- `/home` - Home screen
- `/create-capsule` - Create letter
- `/drafts` - Drafts screen
- `/recipients` - Recipients screen
- `/capsule/:id` - Capsule detail

### Navigation

```dart
// Navigate to create letter
context.push(Routes.createCapsule);

// Navigate to drafts
context.push(Routes.drafts);

// Navigate to recipients
context.push(Routes.recipients);

// Navigate to capsule detail
context.push('/capsule/${capsule.id}', extra: capsule);
```

## Performance Optimizations

### ListView Optimization

- **Keys**: All ListView items have `ValueKey` for efficient recycling
- **PageStorageKey**: Scroll position preserved on tab switches
- **RepaintBoundary**: Capsule cards wrapped for performance

```dart
ListView.builder(
  key: const PageStorageKey('upcoming_capsules'),
  itemBuilder: (context, index) {
    return Padding(
      key: ValueKey('upcoming_${capsule.id}'),
      child: CapsuleCard(capsule: capsule),
    );
  },
)
```

### Animation Optimization

- Tab bar wrapped in `RepaintBoundary`
- Sparkle animations optimized (3 sparkles instead of 4)
- Magic dust background uses reusable Paint objects

### DateFormat Caching

```dart
// Cached to avoid recreation
static final _dateFormat = DateFormat('MMM dd, yyyy');
static final _timeFormat = DateFormat('h:mm a');
```

## UI Components

### Create Letter Button

- Gradient background using theme colors
- Full width, centered
- Icon + text layout
- Shadow for depth

### Drafts Button

- Subtle secondary button
- Shows draft count
- Tap glow effect
- Positioned below create button

### Tab Bar

- Three tabs with icons
- Animated selection indicator
- Sparkle micro-animations
- Gradient background for selected tab
- Glow ring effect

### Floating Action Button

- Custom positioned above bottom nav
- People icon + "+" text
- Theme-colored background
- Navigates to recipients

## State Management

### Tab Controller

```dart
class _HomeScreenState extends ConsumerState<HomeScreen>
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
final capsulesAsync = ref.watch(upcomingCapsulesProvider(userId));

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
- Show empty states
- Provide clear CTAs
- Use consistent spacing
- Follow theme colors

## Code Examples

### Displaying Capsules

```dart
final capsulesAsync = ref.watch(upcomingCapsulesProvider(userId));

return capsulesAsync.when(
  data: (capsules) {
    if (capsules.isEmpty) {
      return EmptyState(
        icon: Icons.mail_outline,
        title: 'No upcoming letters',
        message: 'Create a new letter to get started',
      );
    }
    
    return ListView.builder(
      key: const PageStorageKey('upcoming_capsules'),
      itemCount: capsules.length,
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        return Padding(
          key: ValueKey('upcoming_${capsule.id}'),
          child: InkWell(
            onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
            child: _CapsuleCard(capsule: capsule),
          ),
        );
      },
    );
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => ErrorDisplay(
    message: 'Failed to load capsules',
    onRetry: () => ref.invalidate(upcomingCapsulesProvider(userId)),
  ),
);
```

## Future Enhancements

- [ ] Search functionality
- [ ] Filter options
- [ ] Sort options
- [ ] Pull to refresh
- [ ] Swipe actions on cards

## Related Documentation

- [Receiver Screen](./RECEIVER.md) - For receiver home screen
- [Capsule Viewing](./CAPSULE.md) - For capsule detail screens
- [Create Capsule](./CREATE_CAPSULE.md) - For letter creation
- [Drafts](./DRAFTS.md) - For draft management
- [Performance Optimizations](../PERFORMANCE_OPTIMIZATIONS.md) - For performance details

---

**Last Updated**: 2025

