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
- Two main tabs: Home and Inbox
- Smooth tab switching animation
- Theme-aware styling
- Gradient tint on selected tab

**Navigation Tabs**:
1. **Home** (Tab 0)
   - Icon: `Icons.home_outlined`
   - Label: "Home"
   - Route: `/home`
   - Shows sender's home screen

2. **Inbox** (Tab 1)
   - Icon: `Icons.inbox_outlined`
   - Label: "Inbox"
   - Route: `/inbox`
   - Shows receiver's home screen

**Layout Structure**:
```
MainNavigation
├── Body (child widget)
└── BottomNavigationBar
    ├── Home Tab
    └── Inbox Tab
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
  ├── Home Tab (/home)
  │   └── HomeScreen
  │
  └── Inbox Tab (/inbox)
      └── ReceiverHomeScreen
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

- `/home` - Home tab (sender)
- `/inbox` - Inbox tab (receiver)

## State Management

### Current Tab Index

```dart
class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  
  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.receiverHome);
        break;
    }
  }
}
```

### Location Tracking

```dart
int _getCurrentIndex(String location) {
  if (location == Routes.home) return 0;
  if (location == Routes.receiverHome) return 1;
  return 0; // Default to home
}
```

## UI Components

### Bottom Navigation Bar

**Features**:
- Two tabs (Home, Inbox)
- Outline icons
- Selected tab with gradient tint
- Smooth animation
- Theme-aware colors
- Reduced height (60px)

**Styling**:
- White background
- Subtle shadow
- Rounded corners
- Icon size: 24px
- Label font size: 12px

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
  setState(() => _currentIndex = index);
  
  switch (index) {
    case 0:
      context.go(Routes.home);
      break;
    case 1:
      context.go(Routes.receiverHome);
      break;
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
- [Architecture](../ARCHITECTURE.md) - For navigation architecture

---

**Last Updated**: 2024

