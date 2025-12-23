# Theme System Documentation

Comprehensive guide to the OpenOn app's theming system, including color schemes, dynamic gradients, and theme management.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Color Schemes](#color-schemes)
4. [Dynamic Theme Builder](#dynamic-theme-builder)
5. [Gradient System](#gradient-system)
6. [Theme Persistence](#theme-persistence)
7. [Usage Examples](#usage-examples)
8. [Adding New Themes](#adding-new-themes)
9. [Best Practices](#best-practices)

---

## Overview

The OpenOn app features a sophisticated theming system that allows users to customize their experience with multiple color schemes. The system supports:

- **Multiple Color Schemes**: 15+ predefined color schemes
- **Dynamic Gradients**: Automatically generated gradients from color schemes
- **Theme Persistence**: User preferences saved and restored
- **Reactive Updates**: Theme changes apply instantly across the app

### Key Components

```
core/theme/
├── app_theme.dart           # Base theme constants
├── color_scheme.dart        # Color scheme definitions
├── dynamic_theme.dart       # Theme builder and gradients
└── color_scheme_service.dart # Theme persistence
```

---

## Architecture

### Theme Flow

```
User Selects Theme
    ↓
ColorSchemeService.saveSchemeId()
    ↓
selectedColorSchemeProvider updates
    ↓
DynamicTheme.buildTheme() called
    ↓
MaterialApp theme updated
    ↓
All widgets rebuild with new theme
```

### Component Relationships

```
┌─────────────────────────────────┐
│   ColorSchemeService            │
│   (Persistence Layer)           │
└──────────────┬──────────────────┘
               │
               ↓
┌─────────────────────────────────┐
│   selectedColorSchemeProvider    │
│   (State Management)            │
└──────────────┬──────────────────┘
               │
               ↓
┌─────────────────────────────────┐
│   DynamicTheme.buildTheme()      │
│   (Theme Builder)               │
└──────────────┬──────────────────┘
               │
               ↓
┌─────────────────────────────────┐
│   MaterialApp                   │
│   (Theme Application)            │
└─────────────────────────────────┘
```

---

## Color Schemes

### Structure

Each color scheme consists of 6 colors:

```dart
class AppColorScheme {
  final String id;           // Unique identifier
  final String name;         // Display name
  final Color primary1;      // Main primary color
  final Color primary2;      // Secondary primary color
  final Color secondary1;   // Main secondary color
  final Color secondary2;   // Light secondary color
  final Color accent;       // Accent color
}
```

### Available Color Schemes

The app includes 10 vibrant dark themes optimized for a modern, immersive experience:

#### 1. Deep Blue (Default)
- **Primary**: Deep purple-blue gradient
- **Secondary**: Dark blue-purple tones
- **Accent**: Vibrant purple glow
- **Mood**: Modern, professional
- **Type**: Dark theme

#### 2. Galaxy Aurora
- **Primary**: Deep purple-blue
- **Secondary**: Dark blue-purple
- **Accent**: Bright cyan (aurora effect)
- **Mood**: Mystical, cosmic
- **Type**: Dark theme

#### 3. Galaxy Aurora Classic
- **Primary**: Deep purple-blue
- **Secondary**: Light cyan-blue and soft blue-aqua
- **Accent**: Golden/peachy
- **Mood**: Dreamy, aurora-inspired
- **Type**: Light theme variant

#### 4. Cosmic Void
- **Primary**: Deep purple-black
- **Secondary**: Almost black to dark navy
- **Accent**: Vibrant purple
- **Mood**: Deep, mysterious
- **Type**: Dark theme

#### 5. Nebula Dreams
- **Primary**: Rich purple
- **Secondary**: Very dark purple tones
- **Accent**: Vibrant pink
- **Mood**: Dreamy, ethereal
- **Type**: Dark theme

#### 6. Stellar Night
- **Primary**: Deep navy
- **Secondary**: Almost black blue
- **Accent**: Gold (stars)
- **Mood**: Celestial, elegant
- **Type**: Dark theme

#### 7. Abyssal Depths
- **Primary**: Deep teal-blue
- **Secondary**: Very dark blue-green
- **Accent**: Bright teal
- **Mood**: Oceanic, deep
- **Type**: Dark theme

#### 8. Midnight Storm
- **Primary**: Dark grey-blue
- **Secondary**: Almost black
- **Accent**: Electric blue
- **Mood**: Stormy, dynamic
- **Type**: Dark theme

#### 9. Celestial Purple
- **Primary**: Deep purple
- **Secondary**: Very dark purple
- **Accent**: Magenta
- **Mood**: Cosmic, vibrant
- **Type**: Dark theme

#### 10. Mystic Shadows
- **Primary**: Deep indigo
- **Secondary**: Very dark indigo
- **Accent**: Blue-violet
- **Mood**: Mystical, shadowy
- **Type**: Dark theme

### Color Scheme Properties

Each color has a specific purpose:

- **primary1**: Main brand color, used for buttons, highlights
- **primary2**: Darker variant, used for gradients
- **secondary1**: Light accent, used for backgrounds
- **secondary2**: Lightest variant, used for scaffold background
- **accent**: Pop color, used for special highlights

---

## Dynamic Theme Builder

**File**: `core/theme/dynamic_theme.dart`

### Purpose

Builds a complete `ThemeData` object from a color scheme, applying colors consistently across all Material components. Also provides helper methods for theme-aware colors and styles.

### Method Signature

```dart
static ThemeData buildTheme(AppColorScheme scheme)
```

### Theme Configuration

The builder configures:

1. **Color Scheme**: Material 3 color scheme
2. **App Bar**: Transparent with theme colors
3. **Buttons**: Elevated and text button themes (with borders)
4. **Input Fields**: Text field decoration
5. **Cards**: Card theme with elevation
6. **Text Theme**: Typography with theme colors
7. **Bottom Navigation**: Theme-aware navigation bar

### Helper Methods

`DynamicTheme` provides numerous helper methods for consistent theming:

#### Text Colors
- `getPrimaryTextColor()` - Headings, titles
- `getSecondaryTextColor()` - Body text, descriptions
- `getDisabledTextColor()` - Placeholder text
- `getLabelTextColor()` - Form labels, small text

#### Icon Colors
- `getPrimaryIconColor()` - Main icons
- `getSecondaryIconColor()` - Chevrons, less important icons

#### Background Colors
- `getCardBackgroundColor()` - Cards, containers
- `getInfoBackgroundColor()` - Info/alert containers
- `getInputBackgroundColor()` - Input fields

#### Border Colors
- `getBorderColor()` - Cards/containers
- `getInfoBorderColor()` - Info/alert borders
- `getInputBorderColor()` - Input field borders
- `getButtonBorderColor()` - Button borders
- `getButtonBorderSide()` - Complete BorderSide for buttons
- `getSubtleButtonBorderSide()` - Subtle border for special cases
- `getTabContainerBorder()` - Tab container borders

#### Button Helpers
- `getButtonBackgroundColor()` - Custom button backgrounds
- `getButtonTextColor()` - Button text/icon color
- `getButtonGlowColor()` - Pressed/tapped state glow
- `getButtonGlowShadows()` - Complete glow shadow list

#### Navigation Bar
- `getNavBarBackgroundColor()` - Navigation bar background
- `getNavBarShadowColor()` - Navigation bar shadow
- `getNavBarSelectedIconColor()` - Selected icon color
- `getNavBarUnselectedIconColor()` - Unselected icon color
- `getNavBarGlowColor()` - Selected item glow

All helpers use `AppTheme` constants and automatically adapt to dark/light themes.

### Example Output

```dart
ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: scheme.primary1,
    secondary: scheme.secondary1,
    surface: Colors.white,
    background: scheme.secondary2,
    // ...
  ),
  scaffoldBackgroundColor: scheme.secondary2,
  // ... more theme properties
)
```

---

## Gradient System

### Gradient Types

The system provides three types of gradients:

#### 1. Dreamy Gradient
Primary color gradient for main elements:

```dart
LinearGradient dreamyGradient(AppColorScheme scheme) {
  return LinearGradient(
    colors: [scheme.primary1, scheme.primary2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

**Usage**: Buttons, tab indicators, main highlights

#### 2. Soft Gradient
Secondary to accent gradient:

```dart
LinearGradient softGradient(AppColorScheme scheme) {
  return LinearGradient(
    colors: [scheme.secondary1, scheme.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

**Usage**: Opened capsules, soft highlights

#### 3. Warm Gradient
Secondary color gradient:

```dart
LinearGradient warmGradient(AppColorScheme scheme) {
  return LinearGradient(
    colors: [scheme.secondary1, scheme.secondary2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

**Usage**: Backgrounds, subtle elements

### Using Gradients

```dart
final colorScheme = ref.watch(selectedColorSchemeProvider);

// Get gradients
final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);
final softGradient = DynamicTheme.softGradient(colorScheme);
final warmGradient = DynamicTheme.warmGradient(colorScheme);

// Apply to widget
Container(
  decoration: BoxDecoration(
    gradient: dreamyGradient,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text('Gradient Button'),
)
```

---

## Theme Persistence

**File**: `core/theme/color_scheme_service.dart`

### Purpose

Saves and restores user's color scheme preference using SharedPreferences.

### Methods

#### Save Theme
```dart
static Future<void> saveSchemeId(String schemeId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selected_color_scheme_id', schemeId);
}
```

#### Load Theme
```dart
static Future<AppColorScheme> getCurrentScheme() async {
  final prefs = await SharedPreferences.getInstance();
  final schemeId = prefs.getString('selected_color_scheme_id');
  
  if (schemeId != null) {
    final scheme = AppColorScheme.fromId(schemeId);
    if (scheme != null) return scheme;
  }
  
  return AppColorScheme.deepBlue; // Default
}
```

### Provider Integration

```dart
// Load saved scheme
final colorSchemeProvider = FutureProvider<AppColorScheme>((ref) async {
  return await ColorSchemeService.getCurrentScheme();
});

// Reactive scheme provider
final selectedColorSchemeProvider = StateNotifierProvider<ColorSchemeNotifier, AppColorScheme>(
  (ref) {
    final currentSchemeAsync = ref.watch(colorSchemeProvider);
    final initialScheme = currentSchemeAsync.asData?.value ?? AppColorScheme.deepBlue;
    return ColorSchemeNotifier(initialScheme);
  },
);
```

---

## Usage Examples

### Getting Current Theme

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Container(
      color: colorScheme.primary1,
      child: Text('Themed Text'),
    );
  }
}
```

### Applying Gradients

```dart
final colorScheme = ref.watch(selectedColorSchemeProvider);
final gradient = DynamicTheme.dreamyGradient(colorScheme);

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary1,
  ),
  child: Container(
    decoration: BoxDecoration(gradient: gradient),
    child: Text('Gradient Button'),
  ),
  onPressed: () {},
)
```

### Changing Theme

```dart
// In ColorSchemeScreen or similar
ref.read(selectedColorSchemeProvider.notifier).setScheme(
  AppColorScheme.royalAmethyst,
);
```

### Using Theme Colors in Widgets

```dart
// Direct color access
colorScheme.primary1
colorScheme.accent

// Through Material theme
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Text colors
Theme.of(context).textTheme.bodyLarge?.color
```

---

## Adding New Themes

### Step 1: Define Color Scheme

Add to `core/theme/color_scheme.dart` using consistent hex format:

```dart
// ⭐ MY NEW THEME - Description
static const myNewTheme = AppColorScheme(
  id: 'my_new_theme',
  name: 'My New Theme',
  primary1: Color(0xFF1C164E),      // Main primary color
  primary2: Color(0xFF2A1D6F),       // Darker primary variant
  secondary1: Color(0xFF8EC5FF),    // Main secondary color
  secondary2: Color(0xFFD4E8F5),     // Light secondary (background)
  accent: Color(0xFFF8D57E),        // Accent color
);
```

**Important**: 
- Use hex format `Color(0xFF...)` consistently
- `secondary2` determines if theme is dark/light (luminance < 0.5 = dark)
- Ensure colors work well together in gradients

### Step 2: Add to All Schemes List

```dart
static const List<AppColorScheme> allSchemes = [
  deepBlue,        // Default theme - placed first
  galaxyAurora,
  galaxyAuroraClassic,
  // ... existing schemes
  myNewTheme,  // Add here
];
```

### Step 3: Test Theme

1. Run the app
2. Go to Profile → Color Theme
3. Select your new theme
4. Verify all screens look correct
5. Test with both dark and light variants if applicable

### Color Selection Tips

1. **Contrast**: Ensure text is readable on backgrounds (use `DynamicTheme` helpers)
2. **Harmony**: Colors should work well together in gradients
3. **Accessibility**: Check WCAG contrast ratios
4. **Mood**: Match color psychology to intended mood
5. **Dark/Light Detection**: `secondary2` luminance determines theme type automatically
6. **Format Consistency**: Always use hex format `Color(0xFF...)`

---

## Production Optimizations

### Constants System

All spacing, opacity, border widths, and other design values are centralized in `AppTheme` for consistency:

```dart
// Spacing
AppTheme.spacingXs    // 4.0
AppTheme.spacingSm    // 8.0
AppTheme.spacingMd    // 16.0
AppTheme.spacingLg    // 24.0
AppTheme.spacingXl    // 32.0

// Opacity
AppTheme.opacityLow           // 0.1
AppTheme.opacityMedium        // 0.15
AppTheme.opacityMediumHigh    // 0.2
AppTheme.opacityHigh          // 0.3
AppTheme.opacityVeryHigh      // 0.6
AppTheme.opacityFull          // 0.9

// Border Widths
AppTheme.borderWidthThin      // 0.5
AppTheme.borderWidthStandard  // 1.0
AppTheme.borderWidthThick     // 2.0
```

**Never use hardcoded values** - always use `AppTheme` constants.

### DynamicTheme Helper Methods

Use `DynamicTheme` helper methods instead of hardcoded color logic:

```dart
// ✅ Good - Theme-aware helpers
DynamicTheme.getPrimaryTextColor(colorScheme)
DynamicTheme.getSecondaryTextColor(colorScheme)
DynamicTheme.getButtonBorderSide(colorScheme)
DynamicTheme.getCardBackgroundColor(colorScheme)
DynamicTheme.getTabContainerBorder(colorScheme)

// ❌ Bad - Hardcoded logic
colorScheme.isDarkTheme ? Colors.white : Colors.black
```

### Color Format Standards

All colors use consistent hex format:

```dart
// ✅ Good
Color(0xFF1C164E)

// ❌ Bad - Inconsistent
Color.fromARGB(255, 28, 22, 78)
```

### JSON Serialization

Uses non-deprecated APIs:

```dart
// ✅ Good
primary1.toARGB32()

// ❌ Bad - Deprecated
primary1.value
```

## Best Practices

### 1. Always Use Theme Colors

```dart
// ✅ Good
Container(color: colorScheme.primary1)

// ❌ Bad
Container(color: Colors.blue)
```

### 2. Use DynamicTheme Helpers

```dart
// ✅ Good - Theme-aware, no hardcoded logic
Text(
  'Hello',
  style: TextStyle(
    color: DynamicTheme.getPrimaryTextColor(colorScheme),
  ),
)

// ❌ Bad - Hardcoded theme checks
Text(
  'Hello',
  style: TextStyle(
    color: colorScheme.isDarkTheme ? Colors.white : Colors.black,
  ),
)
```

### 3. Use Constants, Not Magic Numbers

```dart
// ✅ Good
padding: EdgeInsets.all(AppTheme.spacingMd)
borderRadius: BorderRadius.circular(AppTheme.radiusLg)
opacity: AppTheme.opacityHigh

// ❌ Bad
padding: EdgeInsets.all(16.0)
borderRadius: BorderRadius.circular(16.0)
opacity: 0.3
```

### 4. Use Gradients from DynamicTheme

```dart
// ✅ Good
final gradient = DynamicTheme.dreamyGradient(colorScheme);

// ❌ Bad
final gradient = LinearGradient(colors: [Colors.purple, Colors.blue]);
```

### 5. Watch Theme Provider

```dart
// ✅ Good - Reactive
final colorScheme = ref.watch(selectedColorSchemeProvider);

// ❌ Bad - Not reactive
final colorScheme = AppColorScheme.deepBlue;
```

### 6. Use Helper Methods for Borders

```dart
// ✅ Good
side: DynamicTheme.getButtonBorderSide(colorScheme)
border: DynamicTheme.getTabContainerBorder(colorScheme)

// ❌ Bad
side: BorderSide(
  color: colorScheme.isDarkTheme 
    ? Colors.white.withOpacity(0.3) 
    : colorScheme.primary1.withOpacity(0.2),
  width: 1,
)
```

### 7. Test All Themes

When adding new UI, test with multiple color schemes to ensure consistency and visibility.

### 8. Gradient Consistency

Use the same gradient type for similar elements:
- Buttons: `dreamyGradient`
- Opened capsules: `softGradient`
- Backgrounds: `warmGradient`

---

## Troubleshooting

### Theme Not Updating

**Problem**: Theme changes don't apply immediately.

**Solution**: Ensure you're watching `selectedColorSchemeProvider`:

```dart
final colorScheme = ref.watch(selectedColorSchemeProvider);
```

### Colors Look Wrong

**Problem**: Colors don't match expected appearance.

**Solution**: Check that you're using `DynamicTheme.buildTheme()` in MaterialApp.

### Theme Not Persisting

**Problem**: Theme resets on app restart.

**Solution**: Verify `ColorSchemeService` is saving correctly and `colorSchemeProvider` loads on startup.

---

## Related Documentation

- [Core Components](./CORE_COMPONENTS.md#theme-system)
- [Architecture](../architecture/ARCHITECTURE.md#theming-system)
- [Profile Feature](./features/PROFILE.md)

---

---

## Recent Updates (2025)

### Production Optimizations
- **Constants System**: All spacing, opacity, and border values centralized in `AppTheme`
- **Helper Methods**: Comprehensive `DynamicTheme` helpers replace hardcoded theme logic
- **Color Format**: Standardized to hex format `Color(0xFF...)` throughout
- **API Updates**: Replaced deprecated `Color.value` with `Color.toARGB32()`
- **No Hardcoded Values**: All theme logic uses constants and helpers

### Theme Updates
- **Galaxy Aurora Classic**: Updated `secondary2` to light blue-aqua (`#D4E8F5`) for better visual appeal
- **Theme Detection**: Automatic dark/light detection based on `secondary2` luminance
- **Button Borders**: Global button border styling via `ElevatedButtonThemeData`

---

**Last Updated**: January 2025

