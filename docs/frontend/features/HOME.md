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
- Drafts button with count (subtle, near tabs)
- Three tabs: **Unfolding**, **Future Me**, **Opened** ⭐ UPDATED
- **Name filter** - On-demand inline search to filter by recipient name ⭐ NEW
- Floating Action Button (FAB) for creating letters
- Magic dust background animation
- Tab animations with sparkle effects

**Tabs**:

1. **Unfolding Tab** (`_UnlockingSoonTab`)
   - Label: "Unfolding" (with sparkles icon)
   - **Content**: Only regular capsules (letters to others)
   - Shows capsules unlocking within 7 days (unlocking soon)
   - Shows capsules unlocking later than 7 days (upcoming)
   - Uses `unlockingSoonCapsulesProvider` and `upcomingCapsulesProvider`
   - Displays countdown timers
   - Animated "Unlocking Soon" badges
   - **Sorting**: Sorted by time remaining to unlock (ascending - shortest time first)
   - **Note**: Self letters are NOT shown here (they appear in "Future Me" tab)

2. **Future Me Tab** (`_ForYouTab`) ⭐ NEW
   - Label: "Future Me" (with person icon)
   - **Content**: All sealed self letters (not yet opened)
   - Shows self letters that are:
     - Sealed (not yet openable - `scheduled_open_at > now()`)
     - Ready to open (openable but not opened - `scheduled_open_at <= now() && opened_at IS NULL`)
   - Uses `selfLettersProvider` (filters for `!isOpened`)
   - Displays countdown timers and status badges
   - **Sorting**: Sorted by scheduled open date (descending - most recent first)
   - **Note**: This tab is dedicated to self letters only

3. **Opened Tab** (`_OpenedTab`)
   - Label: "Opened" (with heart icon)
   - **Content**: Opened self letters AND opened capsules (combined)
   - Shows already opened letters (both self letters and regular capsules)
   - Uses `openedCapsulesProvider` and `selfLettersProvider` (filters for `isOpened`)
   - Displays open date and reactions
   - **Sorting**: Sorted by opened date (descending - most recently opened first)

**Layout Structure**:
```
HomeScreen
├── MagicDustBackground
│   └── Container (gradient)
│       └── SafeArea
│           └── Column
│               ├── Header (avatar + greeting + search icon)
│               ├── Header Separator
│               ├── InlineNameFilterBar (expandable, hidden by default) ⭐ NEW
│               ├── Drafts Button (subtle, near tabs)
│               ├── TabBar (with animations)
│               └── TabBarView (tab content)
└── FloatingActionButton (Create Letter - pencil + mail icons)
```

**Name Filter Integration**:
- Search icon in header (next to notifications icon)
- Filter bar expands below header separator when search icon is tapped
- Filters all three tabs by recipient name ("To <name>")
- Filter query persists when switching tabs
- See **[NAME_FILTER.md](./NAME_FILTER.md)** for complete documentation

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

1. User taps Floating Action Button (FAB) with pencil and mail icons
2. Navigates to `Routes.createCapsule`
3. Multi-step creation flow begins
4. For users with zero letters: Empty state shows "Write your first letter" CTA

### Accessing Drafts

1. User taps "Drafts (X)" button (subtle text button near tabs)
2. Navigates to `Routes.drafts`
3. Drafts screen displays saved drafts

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
// Navigate to create letter (via FAB)
context.push(Routes.createCapsule);

// Navigate to drafts
context.push(Routes.drafts);

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

### Drafts Button

- Subtle text button with background and border
- Shows draft count: "Drafts (X)"
- Positioned near tabs (top-right alignment)
- Uses primary text color for visibility
- Navigates to drafts screen

### Tab Bar

- Three tabs with icons
- Animated selection indicator
- Sparkle micro-animations
- Gradient background for selected tab
- Glow ring effect

### Floating Action Button

- Custom positioned above bottom nav
- Pencil icon (edit_outlined) + mail icon (mail_outline)
- Theme-colored background (primary2)
- Tooltip: "Create new letter"
- Navigates to create capsule flow
- Only visible on Outbox/Send screen

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
      // Check if user has zero letters total
      final hasAnyLetters = allCapsulesAsync.maybeWhen(
        data: (allCapsules) => allCapsules.isNotEmpty,
        orElse: () => false,
      );
      
      if (!hasAnyLetters) {
        // Special empty state with CTA for first-time users
        return EmptyState(
          icon: Icons.mail_outline,
          title: 'No letters yet',
          message: 'Start your journey by writing your first letter',
          action: ElevatedButton(
            onPressed: () => context.push(Routes.createCapsule),
            child: const Text('Write your first letter'),
          ),
        );
      }
      
      // Normal empty state (FAB is the creation affordance)
      return EmptyState(
        icon: Icons.mail_outline,
        title: 'No upcoming letters',
        message: 'Letters scheduled to unlock will appear here',
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

## Production Optimizations

### Performance
- ✅ Optimized empty state check (uses `whenData` for safer async handling)
- ✅ Efficient provider invalidation
- ✅ FAB positioned with safe area handling
- ✅ Drafts count updates reactively

### Error Handling
- ✅ Comprehensive error handling in empty states
- ✅ Graceful fallbacks for loading/error states
- ✅ User-friendly error messages

### Accessibility
- ✅ Semantic labels for FAB and drafts button
- ✅ Proper tooltips and ARIA labels
- ✅ Keyboard navigation support

### UX Improvements
- ✅ Empty state with CTA for first-time users
- ✅ FAB as primary creation affordance (less visual dominance)
- ✅ Subtle drafts button (secondary affordance)
- ✅ More letters visible above the fold

## Future Enhancements

- [ ] Search functionality
- [ ] Filter options
- [ ] Sort options
- [ ] Swipe actions on cards
- [ ] Withdrawn letters section (muted/archived state)

## Related Documentation

- [Receiver Screen](./RECEIVER.md) - For receiver home screen
- [Capsule Viewing](./CAPSULE.md) - For capsule detail screens
- [Create Capsule](./CREATE_CAPSULE.md) - For letter creation
- [Drafts](./DRAFTS.md) - For draft management
- [Performance Optimizations](../../development/PERFORMANCE_OPTIMIZATIONS.md) - For performance details

---

**Last Updated**: January 2025

**Production Status**: ✅ Ready for 100,000+ users
- Race condition protection
- Memory leak prevention
- Comprehensive error handling
- Performance optimizations
- Accessibility support

