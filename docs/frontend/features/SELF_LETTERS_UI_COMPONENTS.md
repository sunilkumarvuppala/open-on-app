# Self Letters - UI Components Documentation

**Last Updated**: December 2025  
**Status**: ✅ Production Ready  
**Related**: [Complete Feature Documentation](../../features/SELF_LETTERS.md), [Frontend Implementation](./LETTERS_TO_SELF.md)

---

## Overview

This document provides detailed documentation for all UI components used in the Self Letters feature, with a focus on the reflection prompt card and its animated elements.

---

## Table of Contents

1. [Reflection Prompt Card](#reflection-prompt-card)
2. [Pulsing Psychology Icon](#pulsing-psychology-icon)
3. [Reflection Display](#reflection-display)
4. [Component Architecture](#component-architecture)
5. [Styling Guidelines](#styling-guidelines)
6. [Animation Details](#animation-details)

---

## Reflection Prompt Card

### Component: `_ReflectionPromptCard`

**Location**: `frontend/lib/features/self_letters/open_self_letter_screen.dart`

**Purpose**: Displays a reflection prompt after a self letter is opened, allowing users to submit a one-time reflection response.

### Layout Structure

```
Stack
├── Container (Card)
│   ├── Column
│   │   ├── Center (Question Text)
│   │   ├── SizedBox (Spacing)
│   │   ├── Row (Reflection Options)
│   │   │   ├── Expanded ("Still true")
│   │   │   └── Expanded ("Changed")
│   │   ├── SizedBox (Spacing)
│   │   └── Center (Skip Button)
├── Positioned (Psychology Icon - Left)
└── Positioned (Dismiss Button - Right)
```

### Component Details

#### 1. Question Text
- **Text**: "How does this feel to read now?"
- **Style**: 
  - Font size: 18px
  - Font weight: w600
  - Color: Primary text color (theme-aware)
  - Alignment: Center
- **Padding**: Horizontal `AppTheme.spacingXl`

#### 2. Psychology Icon (Left)
- **Widget**: `_PulsingPsychologyIcon`
- **Position**: 
  - Top: `AppTheme.spacingMd`
  - Left: `AppTheme.spacingLg + AppTheme.spacingMd`
- **Size**: 28px
- **Animation**: Continuous pulsing (see [Pulsing Psychology Icon](#pulsing-psychology-icon))

#### 3. Dismiss Button (Right)
- **Icon**: `Icons.close`
- **Position**: 
  - Top: `AppTheme.spacingMd`
  - Right: `AppTheme.spacingLg + AppTheme.spacingMd`
- **Size**: 18px
- **Color**: Secondary text color with 0.7 opacity
- **Interaction**: Material/InkWell with tap feedback
- **Action**: Calls `onDismiss` callback

#### 4. Reflection Options
- **Layout**: Horizontal `Row` with `MainAxisAlignment.spaceEvenly`
- **Options**:
  - **"Still true"** (Left):
    - Icon: `Icons.check_circle_outline` (32px)
    - Label: "Still true"
    - Action: Submits 'yes'
    - Uses `_buildReflectionOption` helper
  - **"Changed"** (Right):
    - Icon: `Icons.change_circle_outlined` (32px)
    - Label: "Changed"
    - Action: Submits 'no'
    - Uses `_buildReflectionOption` helper
- **Spacing**: `AppTheme.spacingMd` between options

#### 5. Skip Button
- **Type**: `TextButton`
- **Text**: "Skip"
- **Style**: 
  - Foreground color: Secondary text with 0.7 opacity
  - Font weight: w400
  - Font size: bodySmall
- **Action**: Submits 'skipped'
- **Position**: Centered below main options

### Styling

**Card Container**:
- Background: `DynamicTheme.getCardBackgroundColor(colorScheme)`
- Border: `DynamicTheme.getDividerColor(colorScheme)` with 0.3 opacity
- Border radius: `AppTheme.radiusXl`
- Border width: 1px
- Shadow: 
  - Color: Black with 0.1 opacity
  - Blur radius: 20px
  - Offset: (0, 4)

**Padding**:
- Left/Right/Top: `AppTheme.spacingXl`
- Bottom: `AppTheme.spacingLg`

**Margin**:
- Horizontal: `AppTheme.spacingLg`

### Props

```dart
class _ReflectionPromptCard extends ConsumerWidget {
  final SelfLetter letter;           // Letter data
  final Function(String) onSubmit;    // Callback: 'yes', 'no', or 'skipped'
  final VoidCallback onDismiss;      // Callback: Dismiss card
}
```

### Usage

```dart
_ReflectionPromptCard(
  letter: letter,
  onSubmit: (answer) => _submitReflection(answer),
  onDismiss: () => setState(() => _reflectionDismissed = true),
)
```

---

## Pulsing Psychology Icon

### Component: `_PulsingPsychologyIcon`

**Location**: `frontend/lib/features/self_letters/open_self_letter_screen.dart`

**Purpose**: Displays an animated psychology icon that provides gentle visual feedback and draws attention to the reflection prompt.

### Implementation

**Type**: Stateful widget with `SingleTickerProviderStateMixin`

**Animation Controller**:
```dart
AnimationController(
  duration: const Duration(milliseconds: 2000),  // 2 seconds
  vsync: this,
)..repeat(reverse: true);  // Continuous reverse loop
```

**Animation**:
```dart
Animation<double>(
  begin: 0.0,
  end: 1.0,
  curve: Curves.easeInOut,
)
```

### Animation Effects

1. **Scale Animation**:
   - Range: 0.92 to 1.0 (8% variation)
   - Formula: `0.92 + (_animation.value * 0.08)`
   - Applied via `Transform.scale`

2. **Opacity Animation**:
   - Range: 0.7 to 0.9 (20% variation)
   - Formula: `0.7 + (_animation.value * 0.2)`
   - Applied via `Opacity` widget

### Visual Behavior

- **Start**: Icon at 92% scale, 70% opacity
- **Middle**: Icon at 100% scale, 90% opacity
- **End**: Icon returns to 92% scale, 70% opacity
- **Loop**: Continuous reverse animation (breathing effect)

### Performance Optimization

- Uses `AnimatedBuilder` to rebuild only the icon widget
- Parent widget is not rebuilt during animation
- Controller properly disposed in `dispose()` method

### Props

```dart
class _PulsingPsychologyIcon extends StatefulWidget {
  final AppColorScheme colorScheme;  // Theme color scheme
}
```

### Usage

```dart
_PulsingPsychologyIcon(
  colorScheme: colorScheme,
)
```

---

## Reflection Display

### Component: `_buildReflectionDisplay`

**Location**: `frontend/lib/features/self_letters/open_self_letter_screen.dart`

**Purpose**: Displays the user's submitted reflection answer and date after reflection has been submitted.

### Layout Structure

```
Container
└── Column
    ├── Row (Title + Icon)
    ├── SizedBox (Spacing)
    ├── Container (Reflection Answer Badge)
    └── Text (Reflection Date)
```

### Component Details

#### 1. Title Row
- **Icon**: Dynamic based on reflection answer
  - "Still true": `Icons.check_circle` (green)
  - "Changed": `Icons.change_circle` (orange)
  - "Skipped": `Icons.skip_next` (secondary color)
- **Text**: "Your Reflection"
- **Style**: Title medium, w600, primary text color

#### 2. Reflection Answer Badge
- **Background**: Answer color with 0.1 opacity
- **Border**: Answer color with 0.3 opacity
- **Content**: Icon + text matching the answer
- **Styling**: Rounded corners (`AppTheme.radiusMd`)

#### 3. Reflection Date
- **Format**: "Reflected on MMM d, yyyy"
- **Style**: Body small, secondary text color with 0.7 opacity
- **Conditional**: Only shown if `reflectedAt` is not null

### Reflection Answer Mapping

| Answer | Text | Color | Icon |
|--------|------|-------|------|
| `'yes'` | "Still true" | Green | `Icons.check_circle` |
| `'no'` | "Changed" | Orange | `Icons.change_circle` |
| `'skipped'` | "Skipped" | Secondary | `Icons.skip_next` |

### Styling

**Container**:
- Background: `DynamicTheme.getCardBackgroundColor(colorScheme)`
- Border: Divider color with 0.3 opacity
- Border radius: `AppTheme.radiusLg`
- Padding: `AppTheme.spacingLg` (all sides)

---

## Component Architecture

### Widget Hierarchy

```
OpenSelfLetterScreen (StatefulWidget)
├── Lock Screen (if not opened)
│   └── [Lock UI components]
└── Opened Screen (if opened)
    ├── Letter Content
    ├── _ReflectionPromptCard (if not reflected)
    │   ├── _PulsingPsychologyIcon
    │   ├── Question Text
    │   ├── Reflection Options
    │   └── Dismiss Button
    └── _buildReflectionDisplay (if reflected)
```

### State Management

- **Provider**: `selfLettersProvider` (Riverpod)
- **State Updates**: 
  - After reflection submission, provider is invalidated
  - Screen rebuilds with updated letter data
  - Reflection prompt is hidden, reflection display is shown

### Lifecycle

1. **Letter Opened**: Reflection prompt card appears
2. **User Interacts**: 
   - Submits reflection → Card disappears, display appears
   - Dismisses card → Card hidden (can be shown again by refreshing)
3. **Reflection Submitted**: Display shows permanently

---

## Styling Guidelines

### Theme Integration

All components use theme-aware colors via `DynamicTheme`:
- `DynamicTheme.getCardBackgroundColor(colorScheme)`
- `DynamicTheme.getPrimaryTextColor(colorScheme)`
- `DynamicTheme.getSecondaryTextColor(colorScheme)`
- `DynamicTheme.getDividerColor(colorScheme)`

### Spacing Constants

All spacing uses `AppTheme` constants:
- `AppTheme.spacingXs` (4px)
- `AppTheme.spacingSm` (8px)
- `AppTheme.spacingMd` (16px)
- `AppTheme.spacingLg` (24px)
- `AppTheme.spacingXl` (32px)

### Border Radius

- Card: `AppTheme.radiusXl` (16px)
- Badge: `AppTheme.radiusMd` (8px)
- Button: `AppTheme.radiusSm` (4px)

### Opacity Values

- Border: 0.3 (`AppConstants.letterReplyDividerOpacity`)
- Secondary text: 0.7 (`AppConstants.letterReplySecondaryTextOpacity`)
- Shadow: 0.1
- Icon opacity animation: 0.7-0.9

---

## Animation Details

### Animation Principles

1. **Subtlety**: Animations are gentle and non-distracting
2. **Performance**: Uses efficient rebuilds with `AnimatedBuilder`
3. **Continuity**: Continuous loops for breathing effects
4. **Theme Awareness**: Colors adapt to light/dark themes

### Animation Controller Lifecycle

```dart
@override
void initState() {
  super.initState();
  _controller = AnimationController(...)..repeat(reverse: true);
  _animation = Tween(...).animate(...);
}

@override
void dispose() {
  _controller.dispose();  // Critical: Prevents memory leaks
  super.dispose();
}
```

### Performance Considerations

- **Rebuild Scope**: Only animated widget rebuilds, not parent
- **Disposal**: Controllers properly disposed to prevent leaks
- **Efficiency**: Uses `AnimatedBuilder` instead of `setState` in build

---

## Best Practices

### Component Design

1. **Separation of Concerns**: Each component has a single responsibility
2. **Reusability**: Helper methods like `_buildReflectionOption` reduce duplication
3. **Type Safety**: Strong typing with Dart's type system
4. **Theme Integration**: All colors and styles are theme-aware

### Animation Best Practices

1. **Controller Management**: Always dispose controllers in `dispose()`
2. **Efficient Rebuilds**: Use `AnimatedBuilder` for animated widgets
3. **Performance**: Minimize rebuild scope to animated elements only
4. **User Experience**: Keep animations subtle and purposeful

### Code Organization

1. **Private Components**: UI components are private (prefixed with `_`)
2. **Helper Methods**: Complex UI logic extracted to helper methods
3. **Constants**: Magic numbers extracted to named constants
4. **Documentation**: Complex logic documented with comments

---

## Troubleshooting

### Common Issues

**Issue**: Animation not working
- **Check**: Controller is properly initialized and started
- **Check**: `vsync` is provided (mixin included)
- **Check**: Controller is not disposed prematurely

**Issue**: Icon position incorrect
- **Check**: `Positioned` widget coordinates match design
- **Check**: Parent `Stack` has proper constraints
- **Check**: Padding/margin values are correct

**Issue**: Reflection card not appearing
- **Check**: `letter.hasReflection` is false
- **Check**: `_reflectionDismissed` is false
- **Check**: Letter is in opened state

---

## Related Documentation

- [Self Letters Feature Overview](../../features/SELF_LETTERS.md)
- [Frontend Implementation Guide](./LETTERS_TO_SELF.md)
- [Visual Flow Diagrams](../../features/SELF_LETTERS_VISUAL_FLOW.md)
- [Quick Reference](../../features/SELF_LETTERS_QUICK_REFERENCE.md)

---

**Last Updated**: December 2025  
**Maintained By**: Development Team

