# Profile Feature

## Overview

The Profile feature allows users to view and manage their profile information, customize app settings, and personalize their experience through theme selection.

## Purpose

- View user profile
- Edit profile information (future)
- Customize color themes
- Manage app settings
- Access account options

## File Structure

```
features/profile/
├── profile_screen.dart          # Main profile screen
└── color_scheme_screen.dart     # Theme customization
```

## Components

### ProfileScreen

**File**: `profile_screen.dart`

**Purpose**: Display user profile and settings.

**Key Features**:
- User avatar and name
- Profile information
- Edit profile button (future)
- Settings sections:
  - Account settings
  - Theme customization
  - Notifications (future)
  - Privacy policy (future)
  - Terms of service (future)
- Sign out option

**Layout Structure**:
```
ProfileScreen
├── AppBar (title: "Profile")
├── Body
│   ├── Profile Header
│   │   ├── Avatar
│   │   ├── Name
│   │   └── Edit Button
│   ├── Settings Sections
│   │   ├── Account
│   │   ├── Theme
│   │   └── Legal
│   └── Sign Out
```

### ColorSchemeScreen

**File**: `color_scheme_screen.dart`

**Purpose**: Allow users to customize app theme colors.

**Key Features**:
- Display available color schemes
- Preview color schemes
- Select color scheme
- Apply theme immediately
- Beautiful color scheme cards

**Color Schemes**:
- Multiple predefined schemes
- Each with Primary, Secondary, and Accent colors
- Rich, elegant color combinations
- Premium feel

## User Flows

### Viewing Profile

1. User navigates to profile
2. Profile information displays
3. User can access settings
4. User can customize theme

### Customizing Theme

1. User taps "Color Theme"
2. ColorSchemeScreen displays
3. User browses color schemes
4. User selects scheme
5. Theme applies immediately
6. Navigate back

### Editing Profile

1. User taps "Edit Profile" (future)
2. Edit profile screen displays
3. User updates information
4. User saves
5. Profile updates

## Integration Points

### Providers Used

- `currentUserProvider`: Current user data
- `selectedColorSchemeProvider`: Selected theme
- `colorSchemeServiceProvider`: Theme management

### Routes

- `/profile` - Profile screen
- `/profile/color-scheme` - Theme customization

### Navigation

```dart
// Navigate to profile
context.push(Routes.profile);

// Navigate to theme customization
context.push(Routes.colorScheme);
```

## State Management

### Theme Selection

```dart
final selectedScheme = ref.watch(selectedColorSchemeProvider);

void _selectScheme(AppColorScheme scheme) {
  ref.read(selectedColorSchemeProvider.notifier).state = scheme;
  // Theme updates immediately throughout app
}
```

## UI Components

### Profile Header

**Features**:
- Large avatar
- User name
- Email (if available)
- Edit button

### Settings Tile

**Features**:
- Icon
- Title
- Subtitle (optional)
- Navigation arrow
- Tap to navigate

### Color Scheme Card

**Features**:
- Color preview
- Scheme name
- Primary, Secondary, Accent colors
- Selection indicator
- Tap to select

## Best Practices

### Theme Management

✅ **DO**:
- Apply theme immediately
- Persist theme selection
- Show preview
- Provide variety

### User Experience

✅ **DO**:
- Clear settings organization
- Easy navigation
- Immediate feedback
- Beautiful UI

## Code Examples

### Displaying Profile

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) {
          return ListView(
            children: [
              // Profile Header
              _buildProfileHeader(context, user),
              
              // Settings
              _buildSettingsSection(context, ref),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplay(...),
      ),
    );
  }
}
```

### Theme Selection

```dart
class ColorSchemeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedScheme = ref.watch(selectedColorSchemeProvider);
    final availableSchemes = AppColorScheme.allSchemes;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Color Theme')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
        itemCount: availableSchemes.length,
        itemBuilder: (context, index) {
          final scheme = availableSchemes[index];
          final isSelected = scheme == selectedScheme;
          
          return ColorSchemeCard(
            scheme: scheme,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedColorSchemeProvider.notifier).state = scheme;
            },
          );
        },
      ),
    );
  }
}
```

## Future Enhancements

- [ ] Edit profile functionality
- [ ] Profile photo upload
- [ ] Notification settings
- [ ] Privacy settings
- [ ] Account deletion
- [ ] Data export
- [ ] More color schemes
- [ ] Custom color schemes

## Related Documentation

- [Home Screen](./HOME.md) - For profile navigation
- [Navigation](./NAVIGATION.md) - For navigation patterns
- [API Reference](../API_REFERENCE.md) - For user repository API

---

**Last Updated**: 2024

