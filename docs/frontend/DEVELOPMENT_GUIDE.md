# Development Guide

Complete guide for developers working on the OpenOn app. This document covers setup, development workflow, coding standards, and best practices.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment](#development-environment)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing](#testing)
7. [Debugging](#debugging)
8. [Common Tasks](#common-tasks)
9. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **IDE**: VS Code or Android Studio with Flutter extensions
- **Git**: For version control
- **Device/Emulator**: iOS Simulator or Android Emulator

### Initial Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd openon
   ```

2. **Navigate to Frontend**
   ```bash
   cd frontend
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Verify Setup**
   ```bash
   flutter doctor
   ```

5. **Run App**
   ```bash
   flutter run
   ```

### First Time Setup Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] Dependencies installed (`flutter pub get`)
- [ ] IDE configured with Flutter extensions
- [ ] Device/emulator available
- [ ] App runs successfully
- [ ] Can navigate through app screens

---

## Development Environment

### Recommended IDE Setup

#### VS Code

**Extensions**:
- Flutter
- Dart
- Flutter Widget Snippets
- Error Lens

**Settings** (`settings.json`):
```json
{
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

#### Android Studio

**Plugins**:
- Flutter
- Dart

**Settings**:
- Enable format on save
- Enable auto-import
- Set line length to 100

### Code Formatting

The project uses `dart format` with default settings:

```bash
# Format all files
dart format .

# Format specific file
dart format lib/features/home/home_screen.dart
```

### Linting

Linting rules are defined in `analysis_options.yaml`. Run:

```bash
flutter analyze
```

---

## Project Structure

### Directory Layout

```
frontend/lib/
├── animations/          # Animation widgets and effects
│   ├── effects/        # Animation effects
│   ├── painters/       # Custom painters
│   ├── theme/          # Animation themes
│   └── widgets/        # Animation widgets
│
├── core/                # Core application layer
│   ├── constants/      # App constants
│   ├── data/           # Repositories
│   ├── errors/         # Custom exceptions
│   ├── models/         # Data models
│   ├── providers/      # Riverpod providers
│   ├── router/         # Navigation
│   ├── theme/          # Theming system
│   ├── utils/          # Utilities
│   └── widgets/        # Reusable widgets
│
├── features/           # Feature modules
│   ├── auth/           # Authentication
│   ├── capsule/        # Capsule viewing
│   ├── create_capsule/ # Letter creation
│   ├── drafts/         # Draft management
│   ├── home/           # Sender home
│   ├── navigation/     # Main navigation
│   ├── profile/        # User profile
│   ├── receiver/       # Receiver inbox
│   └── recipients/     # Recipient management
│
└── main.dart           # App entry point
```

### File Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `camelCase` (or `SCREAMING_SNAKE_CASE` for global)

### Import Organization

1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Relative imports

Example:
```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';

import 'home_screen.dart';
```

---

## Development Workflow

### Feature Development

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Implement Feature**
   - Follow coding standards
   - Write clean, documented code
   - Test thoroughly

3. **Format and Lint**
   ```bash
   dart format .
   flutter analyze
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/my-feature
   ```

### Code Review Checklist

- [ ] Code follows style guide
- [ ] No linting errors
- [ ] Properly formatted
- [ ] Documentation added
- [ ] Tests pass
- [ ] No hardcoded values
- [ ] Error handling implemented
- [ ] Theme-aware colors used

### Git Commit Messages

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Tests
- `chore:` Maintenance

Example:
```
feat: add dark theme support

- Add ThemeMode provider
- Update DynamicTheme builder
- Add theme toggle in profile
```

---

## Coding Standards

### General Principles

1. **DRY**: Don't Repeat Yourself
2. **KISS**: Keep It Simple, Stupid
3. **SOLID**: Follow SOLID principles
4. **YAGNI**: You Aren't Gonna Need It

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

#### Naming

```dart
// ✅ Good
class UserProfile extends StatelessWidget {}
final userName = 'John';
const maxRetries = 3;

// ❌ Bad
class user_profile {}
final UserName = 'John';
const MAX_RETRIES = 3;
```

#### Code Organization

```dart
class MyWidget extends StatelessWidget {
  // 1. Constants
  static const double padding = 16.0;
  
  // 2. Fields
  final String title;
  
  // 3. Constructor
  const MyWidget({super.key, required this.title});
  
  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 5. Helper methods
  void _handleTap() {}
}
```

### Widget Guidelines

#### Stateless vs Stateful

- Use `StatelessWidget` when possible
- Use `StatefulWidget` only when state changes
- Prefer `ConsumerWidget` for Riverpod state

#### Widget Composition

```dart
// ✅ Good - Composed
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildContent(),
      _buildFooter(),
    ],
  );
}

// ❌ Bad - Monolithic
Widget build(BuildContext context) {
  return Column(
    children: [
      // 100 lines of inline widgets
    ],
  );
}
```

### State Management

#### Riverpod Patterns

```dart
// ✅ Good - Watch for reactive updates
final user = ref.watch(currentUserProvider);

// ✅ Good - Read for one-time access
final repo = ref.read(authRepositoryProvider);

// ✅ Good - Family providers for parameters
final capsules = ref.watch(capsulesProvider(userId));
```

### Error Handling

```dart
// ✅ Good
try {
  await repository.createCapsule(capsule);
} on ValidationException catch (e) {
  showErrorSnackBar(e.message);
} on NetworkException catch (e) {
  showErrorSnackBar('Network error: ${e.message}');
} catch (e, stackTrace) {
  Logger.error('Unexpected error', error: e, stackTrace: stackTrace);
  showErrorSnackBar('An unexpected error occurred');
}
```

### Constants

```dart
// ✅ Good - Use AppConstants
SizedBox(height: AppConstants.defaultPadding)

// ❌ Bad - Magic numbers
SizedBox(height: 16.0)
```

---

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/home/home_screen_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

```dart
void main() {
  group('Capsule Model', () {
    test('should calculate status correctly', () {
      final capsule = Capsule(
        senderId: '1',
        senderName: 'John',
        receiverId: '2',
        receiverName: 'Jane',
        receiverAvatar: '',
        label: 'Test',
        content: 'Content',
        unlockAt: DateTime.now().add(Duration(days: 1)),
      );
      
      expect(capsule.status, CapsuleStatus.locked);
    });
  });
}
```

---

## Debugging

### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Print Debugging

Use `Logger` instead of `print`:

```dart
Logger.debug('Debug message');
Logger.info('Info message');
Logger.error('Error', error: e, stackTrace: stack);
```

### Hot Reload vs Hot Restart

- **Hot Reload** (`r`): Fast, preserves state
- **Hot Restart** (`R`): Slower, resets state
- **Full Restart**: Stop and run again

### Common Debugging Scenarios

#### Widget Not Updating

```dart
// Check if provider is being watched
final data = ref.watch(myProvider); // ✅ Watches
final data = ref.read(myProvider);   // ❌ Doesn't watch
```

#### Navigation Issues

```dart
// Check route exists
context.push('/route'); // ✅
context.go('/route');   // ✅

// Check authentication
final isAuth = ref.watch(isAuthenticatedProvider);
```

---

## Common Tasks

### Adding a New Screen

1. Create screen file in appropriate feature folder
2. Add route to `app_router.dart`
3. Add navigation call
4. Test navigation

### Adding a New Feature

1. Create feature folder in `features/`
2. Create screen files
3. Add routes
4. Update navigation
5. Add to documentation

### Modifying Theme

1. Edit `color_scheme.dart` or `dynamic_theme.dart`
2. Test with multiple color schemes
3. Update documentation

### Adding a New Provider

1. Add provider to `providers.dart`
2. Use in widgets with `ref.watch()` or `ref.read()`
3. Handle loading/error states

---

## Troubleshooting

### Build Issues

**Problem**: `flutter pub get` fails

**Solution**:
```bash
flutter clean
flutter pub get
```

**Problem**: Build errors

**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### Runtime Issues

**Problem**: App crashes on startup

**Solution**:
- Check `main.dart` for errors
- Verify providers are set up correctly
- Check router configuration

**Problem**: Navigation not working

**Solution**:
- Verify route exists in `app_router.dart`
- Check authentication guards
- Verify route parameters

### Performance Issues

**Problem**: Slow animations

**Solution**:
- Check `RepaintBoundary` usage
- Reduce particle counts
- Optimize rebuilds

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## Next Steps

- [Quick Start Guide](./QUICK_START.md)
- [Architecture Documentation](./ARCHITECTURE.md)
- [Core Components](./CORE_COMPONENTS.md)
- [Feature Documentation](./features/)

---

**Last Updated**: 2024

