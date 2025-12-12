# Centralized Styling System Guide

This guide explains how to use the centralized styling system for consistent UI across the app.

## Overview

The styling system consists of three main components:
1. **AppTextStyles** - Centralized text styles
2. **AppContainerStyles** - Centralized container/background styles
3. **AppDialogBuilder** - Centralized dialog/popup builders

All styles are theme-aware and use constants for consistency.

## Text Styles

### Primary Text Styles

Use these for main content, headings, and titles:

```dart
// Large display text (32px) - For hero text
Text('Welcome', style: AppTextStyles.displayLarge(colorScheme))

// Medium display text (28px) - For section headings
Text('Section Title', style: AppTextStyles.displayMedium(colorScheme))

// Small display text (24px) - For page titles
Text('Page Title', style: AppTextStyles.displaySmall(colorScheme))

// Headline (20px) - For card titles
Text('Card Title', style: AppTextStyles.headlineMedium(colorScheme))

// Title large (18px) - For subsection headings
Text('Subsection', style: AppTextStyles.titleLarge(colorScheme))

// Title medium (16px) - For item titles
Text('Item Title', style: AppTextStyles.titleMedium(colorScheme))

// Body large (16px) - For main body text
Text('Body text', style: AppTextStyles.bodyLarge(colorScheme))

// Body medium (14px) - For secondary body text
Text('Secondary text', style: AppTextStyles.bodyMedium(colorScheme))

// Body small (12px) - For captions
Text('Caption', style: AppTextStyles.bodySmall(colorScheme))
```

### Secondary Text Styles

```dart
// Secondary text - For descriptions
Text('Description', style: AppTextStyles.secondary(colorScheme))

// Label text - For form labels
Text('Label', style: AppTextStyles.label(colorScheme))

// Disabled text - For disabled content
Text('Disabled', style: AppTextStyles.disabled(colorScheme))
```

### Dialog Text Styles

```dart
// Dialog title
Text('Dialog Title', style: AppTextStyles.dialogTitle(colorScheme))

// Dialog content
Text('Dialog message', style: AppTextStyles.dialogContent(colorScheme))

// Dialog button
Text('Button', style: AppTextStyles.dialogButton(colorScheme))
```

### Button Text Styles

```dart
// Button text
Text('Submit', style: AppTextStyles.buttonText(colorScheme))

// Small button text
Text('Cancel', style: AppTextStyles.buttonTextSmall(colorScheme))
```

### Input Text Styles

```dart
// Input text
Text('Input value', style: AppTextStyles.inputText(colorScheme))

// Input hint
Text('Placeholder', style: AppTextStyles.inputHint(colorScheme))

// Input label
Text('Field Label', style: AppTextStyles.inputLabel(colorScheme))
```

### Utility Methods

```dart
// Apply custom color
AppTextStyles.withColor(AppTextStyles.bodyLarge(colorScheme), Colors.red)

// Apply custom size
AppTextStyles.withSize(AppTextStyles.bodyLarge(colorScheme), 18)

// Apply custom weight
AppTextStyles.withWeight(AppTextStyles.bodyLarge(colorScheme), FontWeight.bold)
```

## Container Styles

### Card Container

```dart
Container(
  decoration: AppContainerStyles.card(colorScheme),
  child: YourContent(),
)
```

### Dialog Container

```dart
Container(
  decoration: AppContainerStyles.dialog(colorScheme),
  child: YourContent(),
)
```

### Info Container

```dart
Container(
  decoration: AppContainerStyles.info(colorScheme),
  child: YourContent(),
)
```

### Input Container

```dart
Container(
  decoration: AppContainerStyles.input(colorScheme, isFocused: true),
  child: YourContent(),
)
```

### Button Container

```dart
Container(
  decoration: AppContainerStyles.button(colorScheme, isPressed: false),
  child: YourContent(),
)
```

## Dialog Builder

### Standard Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialogBuilder.buildDialog(
    context: context,
    colorScheme: colorScheme,
    title: 'Dialog Title',
    content: Text('Dialog content'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Close', style: AppTextStyles.dialogButton(colorScheme)),
      ),
    ],
  ),
);
```

### Confirmation Dialog

```dart
final confirmed = await AppDialogBuilder.showConfirmationDialog(
  context: context,
  colorScheme: colorScheme,
  title: 'Confirm Action',
  message: 'Are you sure?',
  confirmText: 'Yes',
  cancelText: 'No',
);
```

### Info Dialog

```dart
await AppDialogBuilder.showInfoDialog(
  context: context,
  colorScheme: colorScheme,
  title: 'Information',
  message: 'This is an info message',
  buttonText: 'OK',
);
```

## Best Practices

1. **Always use AppTextStyles** instead of creating custom TextStyle
2. **Always use AppContainerStyles** for containers and backgrounds
3. **Always use AppDialogBuilder** for dialogs and popups
4. **Never hardcode colors** - use DynamicTheme methods
5. **Never hardcode font sizes** - use AppTextStyles
6. **Always pass colorScheme** to styling methods

## Migration Guide

### Before (Inconsistent)
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.black, // Hardcoded!
  ),
)
```

### After (Consistent)
```dart
Text(
  'Title',
  style: AppTextStyles.displaySmall(colorScheme),
)
```

## Constants

All styling constants are defined in:
- `AppConstants` - For dialog colors, dimensions, etc.
- `AppTheme` - For spacing, radius, opacity, etc.

These ensure consistency across the entire app.
