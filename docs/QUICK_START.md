# Quick Start Guide

This guide will help you get started with the OpenOn app codebase quickly.

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator (for testing)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd openon
   ```

2. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure Overview

```
frontend/lib/
├── core/                    # Core application layer
│   ├── constants/          # App-wide constants
│   ├── data/               # Data repositories
│   ├── errors/             # Custom exceptions
│   ├── models/             # Data models
│   ├── providers/          # Riverpod providers
│   ├── router/             # Navigation routing
│   ├── theme/              # Theming system
│   ├── utils/               # Utility functions
│   └── widgets/            # Reusable widgets
│
├── features/               # Feature modules
│   ├── auth/               # Authentication screens
│   ├── capsule/            # Capsule viewing screens
│   ├── create_capsule/     # Letter creation flow
│   ├── drafts/             # Draft management
│   ├── home/               # Home screen (sender view)
│   ├── navigation/         # Main navigation
│   ├── profile/            # User profile
│   ├── receiver/           # Receiver home screen
│   └── recipients/         # Recipient management
│
└── animations/             # Animation system
    ├── effects/            # Animation effects
    ├── painters/           # Custom painters
    ├── theme/              # Animation themes
    └── widgets/            # Animated widgets
```

## Key Concepts

### 1. State Management (Riverpod)

The app uses Riverpod for state management. Providers are defined in `core/providers/providers.dart`.

```dart
// Example: Watching a provider
final userAsync = ref.watch(currentUserProvider);
```

### 2. Navigation (GoRouter)

Navigation is handled by GoRouter. Routes are defined in `core/router/app_router.dart`.

```dart
// Example: Navigating to a route
context.push(Routes.home);
```

### 3. Constants

All magic numbers and hardcoded values are in `core/constants/app_constants.dart`.

```dart
// Example: Using constants
AppConstants.userAvatarSize
AppConstants.animationDurationShort
```

### 4. Error Handling

Custom exceptions are in `core/errors/app_exceptions.dart`. Always use try-catch with proper error handling.

```dart
try {
  // Your code
} on NotFoundException catch (e) {
  // Handle not found
} on ValidationException catch (e) {
  // Handle validation error
}
```

## Common Tasks

### Adding a New Screen

1. Create a new file in the appropriate `features/` directory
2. Add the route to `core/router/app_router.dart`
3. Add route constant to `Routes` class
4. Implement the screen widget

### Adding a New Provider

1. Add provider to `core/providers/providers.dart`
2. Use `ref.watch()` or `ref.read()` in your widgets
3. Handle loading/error states properly

### Adding a New Animation

1. Create widget in `animations/widgets/`
2. Use `RepaintBoundary` for performance
3. Reuse Paint objects (don't create new ones in paint methods)
4. Dispose animation controllers properly

### Modifying Theme

1. Update color schemes in `core/theme/color_scheme.dart`
2. Use `DynamicTheme` for gradient generation
3. Watch `selectedColorSchemeProvider` for theme changes

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the architecture patterns
   - Use constants instead of magic numbers
   - Add proper error handling
   - Optimize for performance

3. **Test your changes**
   ```bash
   flutter test
   flutter run
   ```

4. **Check for linting errors**
   ```bash
   flutter analyze
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

## Code Quality Checklist

Before committing, ensure:
- ✅ No linter errors (`flutter analyze`)
- ✅ All constants are in `AppConstants`
- ✅ Error handling is implemented
- ✅ Input validation is added
- ✅ Animations use `RepaintBoundary`
- ✅ Paint objects are reused
- ✅ Controllers are properly disposed
- ✅ No `print()` statements (use `Logger`)

## Getting Help

- Check [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture
- Review [API_REFERENCE.md](./API_REFERENCE.md) for API details
- See [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md) for performance tips
- Read [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines

## Next Steps

1. Explore the codebase structure
2. Read [ARCHITECTURE.md](./ARCHITECTURE.md)
3. Review existing features to understand patterns
4. Start with small changes to get familiar

---

Happy coding! 🚀

