# Navigation Feature

## Overview

The Navigation feature provides the main navigation structure for the app, including bottom navigation bar and route management.

## Purpose

- Provide main app navigation
- Bottom navigation bar
- Tab switching animation
- Route management
- Navigation state

## File Structure

```
features/navigation/
└── main_navigation.dart    # Bottom navigation wrapper
```

## Components

### MainNavigation

**File**: `main_navigation.dart`

**Purpose**: Wrapper widget providing bottom navigation for main app screens.

**Key Features**:
- Bottom navigation bar
- Two main tabs: Inbox and Outbox
- Smooth tab switching animation
- Theme-aware styling
- Gradient tint on selected tab
- Rising animation on tab selection

**Navigation Tabs**:
1. **Inbox** (Tab 0) - PRIMARY
   - Icon: `Icons.inbox_outlined`
   - Label: "Inbox"
   - Route: `/inbox`
   - Shows receiver's home screen (incoming capsules)
   - Default screen after authentication

2. **Outbox** (Tab 1) - SECONDARY
   - Icon: `Icons.send_outlined`
   - Label: "Outbox"
   - Route: `/home`
   - Shows sender's home screen (sent capsules)

**Layout Structure**:
```
MainNavigation
├── Body (child widget)
└── BottomNavigationBar
    ├── Inbox Tab (Tab 0 - PRIMARY)
    └── Outbox Tab (Tab 1 - SECONDARY)
```

## User Flows

### Switching Tabs

1. User taps bottom nav tab
2. Smooth animation plays
3. Tab switches
4. New screen displays
5. Scroll position preserved

### Navigation Flow

```
App Start
  ↓
Welcome/Login
  ↓
Main Navigation (ShellRoute)
  ├── Inbox Tab (/inbox) - Tab 0 (PRIMARY)
  │   └── ReceiverHomeScreen
  │
  └── Outbox Tab (/home) - Tab 1 (SECONDARY)
      └── HomeScreen
  ↓
Feature Screens (push routes)
  ├── Create Capsule
  ├── Recipients
  ├── Profile
  └── Drafts
```

## Integration Points

### Router Configuration

**File**: `core/router/app_router.dart`

```dart
ShellRoute(
  builder: (context, state, child) {
    return MainNavigation(
      location: state.matchedLocation,
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.receiverHome,
      builder: (context, state) => const ReceiverHomeScreen(),
    ),
  ],
)
```

### Routes

- `/inbox` - Inbox tab (receiver) - Tab 0, PRIMARY, default after auth
- `/home` - Outbox tab (sender) - Tab 1, SECONDARY

## State Management

### Current Tab Index

```dart
class _MainNavigationState extends ConsumerState<MainNavigation> {
  int get _currentIndex {
    // Inbox (receiverHome) is index 0 (primary home)
    // Outbox (home) is index 1 (secondary)
    if (widget.location == Routes.receiverHome) {
      return 0;
    } else if (widget.location == Routes.home) {
      return 1;
    }
    return 0; // Default to inbox
  }
  
  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    // Trigger rising animation
    _animationController.forward(from: 0.0).then((_) {
      _animationController.reverse();
    });
    
    if (index == 0) {
      context.go(Routes.receiverHome); // Inbox (primary)
    } else if (index == 1) {
      context.go(Routes.home); // Outbox (secondary)
    }
  }
}
```

## UI Components

### Bottom Navigation Bar

**Features**:
- Two tabs (Inbox, Outbox)
- Outline icons (inbox_outlined, send_outlined)
- Selected tab with gradient tint (ShaderMask)
- Rising animation on selection (moves up 4px)
- Smooth animation transitions
- Theme-aware colors
- Height: 60px

**Styling**:
- White background
- Subtle shadow
- Rounded corners
- Icon size: 21px (reduced from 24px)
- Label font size: 11px
- Selected tab: Gradient tint with rising animation

### Tab Animation

**Features**:
- Rising animation on tab switch
- Gradient tint on selected tab
- Smooth transitions
- Theme colors

## Performance Optimizations

### Navigation Optimization

- Use `context.go()` for tab switching (preserves state)
- Use `context.push()` for feature screens
- Preserve scroll positions with PageStorageKey

## Best Practices

### Navigation

✅ **DO**:
- Use `context.go()` for tab switching
- Use `context.push()` for feature screens
- Use `context.pop()` to go back
- Handle navigation errors

### User Experience

✅ **DO**:
- Smooth animations
- Clear tab indicators
- Consistent navigation
- Preserve state

## Code Examples

### Tab Switching

```dart
void _onTabTapped(int index) {
  if (index == _currentIndex) return;
  
  // Trigger rising animation
  _animationController.forward(from: 0.0).then((_) {
    _animationController.reverse();
  });
  
  if (index == 0) {
    context.go(Routes.receiverHome); // Inbox (primary)
  } else if (index == 1) {
    context.go(Routes.home); // Outbox (secondary)
  }
}
```

### Navigation Item

```dart
Widget _buildNavItem({
  required int index,
  required IconData icon,
  required String label,
}) {
  final isSelected = index == _currentIndex;
  final colorScheme = ref.watch(selectedColorSchemeProvider);
  
  return GestureDetector(
    onTap: () => _onTabTapped(index),
    child: AnimatedContainer(
      duration: AppConstants.animationDurationMedium,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected 
              ? colorScheme.primary1 
              : AppTheme.textGrey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected 
                ? colorScheme.primary1 
                : AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## Future Enhancements

- [ ] More navigation tabs
- [ ] Badge notifications
- [ ] Tab animations
- [ ] Custom tab indicators
- [ ] Navigation history

## Related Documentation

- [Home Screen](./HOME.md) - For home tab
- [Receiver Screen](./RECEIVER.md) - For inbox tab
- [Architecture](../../architecture/ARCHITECTURE.md) - For navigation architecture

---

**Last Updated**: 2025

