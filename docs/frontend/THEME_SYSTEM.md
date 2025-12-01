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

#### 1. Galaxy Aurora (Default)
- **Primary**: Deep purple to violet gradient
- **Secondary**: Soft lavender tones
- **Accent**: Golden yellow
- **Mood**: Mystical, dreamy

#### 2. Royal Amethyst
- **Primary**: Rich purple tones
- **Secondary**: Light purple
- **Accent**: Amber gold
- **Mood**: Regal, elegant

#### 3. Dream Lilac
- **Primary**: Soft lilac
- **Secondary**: Pink tones
- **Accent**: Mint green
- **Mood**: Gentle, romantic

#### 4. Velvet Nights
- **Primary**: Deep dark blue/black
- **Secondary**: Light gray
- **Accent**: Purple
- **Mood**: Sophisticated, mysterious

#### 5. Emerald Elegance
- **Primary**: Deep green
- **Secondary**: Light green
- **Accent**: Bright green
- **Mood**: Natural, fresh

#### 6. Midnight Blue
- **Primary**: Dark blue-gray
- **Secondary**: Light gray
- **Accent**: Blue
- **Mood**: Calm, professional

#### 7. Forest Green
- **Primary**: Deep forest green
- **Secondary**: Light beige
- **Accent**: Amber
- **Mood**: Earthy, warm

#### 8. Sunset Dreams
- **Primary**: Orange to pink gradient
- **Secondary**: Peach tones
- **Accent**: Coral
- **Mood**: Warm, vibrant

#### 9. Ocean Breeze
- **Primary**: Blue to cyan gradient
- **Secondary**: Light blue
- **Accent**: Turquoise
- **Mood**: Fresh, calming

#### 10. Rose Gold
- **Primary**: Rose pink
- **Secondary**: Gold tones
- **Accent**: Peach
- **Mood**: Elegant, luxurious

*... and 5 more schemes*

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

Builds a complete `ThemeData` object from a color scheme, applying colors consistently across all Material components.

### Method Signature

```dart
static ThemeData buildTheme(AppColorScheme scheme)
```

### Theme Configuration

The builder configures:

1. **Color Scheme**: Material 3 color scheme
2. **App Bar**: Transparent with theme colors
3. **Buttons**: Elevated and text button themes
4. **Input Fields**: Text field decoration
5. **Cards**: Card theme with elevation
6. **Text Theme**: Typography with theme colors

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
  
  return AppColorScheme.galaxyAurora; // Default
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
    final initialScheme = currentSchemeAsync.asData?.value ?? AppColorScheme.galaxyAurora;
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

Add to `core/theme/color_scheme.dart`:

```dart
static const myNewTheme = AppColorScheme(
  id: 'my_new_theme',
  name: 'My New Theme',
  primary1: Color(0xFF123456),
  primary2: Color(0xFF0A2B3C),
  secondary1: Color(0xFFE8F4F1),
  secondary2: Color(0xFFF0F8F6),
  accent: Color(0xFF2ECC71),
);
```

### Step 2: Add to All Schemes List

```dart
static List<AppColorScheme> get allSchemes => [
  galaxyAurora,
  royalAmethyst,
  // ... existing schemes
  myNewTheme,  // Add here
];
```

### Step 3: Test Theme

1. Run the app
2. Go to Profile → Color Theme
3. Select your new theme
4. Verify all screens look correct

### Color Selection Tips

1. **Contrast**: Ensure text is readable on backgrounds
2. **Harmony**: Colors should work well together
3. **Accessibility**: Check WCAG contrast ratios
4. **Mood**: Match color psychology to intended mood
5. **Gradients**: Test gradients look smooth

---

## Best Practices

### 1. Always Use Theme Colors

```dart
// ✅ Good
Container(color: colorScheme.primary1)

// ❌ Bad
Container(color: Colors.blue)
```

### 2. Use Gradients from DynamicTheme

```dart
// ✅ Good
final gradient = DynamicTheme.dreamyGradient(colorScheme);

// ❌ Bad
final gradient = LinearGradient(colors: [Colors.purple, Colors.blue]);
```

### 3. Watch Theme Provider

```dart
// ✅ Good - Reactive
final colorScheme = ref.watch(selectedColorSchemeProvider);

// ❌ Bad - Not reactive
final colorScheme = AppColorScheme.galaxyAurora;
```

### 4. Test All Themes

When adding new UI, test with multiple color schemes to ensure consistency.

### 5. Use Theme-Aware Text Colors

```dart
// ✅ Good
Text(
  'Hello',
  style: TextStyle(
    color: Theme.of(context).textTheme.bodyLarge?.color,
  ),
)

// ❌ Bad
Text('Hello', style: TextStyle(color: Colors.black))
```

### 6. Gradient Consistency

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
- [Architecture](../ARCHITECTURE.md#theming-system)
- [Profile Feature](./features/PROFILE.md)

---

**Last Updated**: 2025

