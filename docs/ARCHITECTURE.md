# Architecture Documentation

This document describes the architecture, design patterns, and code organization of the OpenOn app.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Structure](#layer-structure)
3. [Core Layer](#core-layer)
4. [Features Layer](#features-layer)
5. [Animations Layer](#animations-layer)
6. [State Management](#state-management)
7. [Navigation](#navigation)
8. [Theming System](#theming-system)
9. [Error Handling](#error-handling)
10. [Data Flow](#data-flow)

## Architecture Overview

OpenOn follows a **feature-based modular architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │
│  (Features: Screens, Widgets)            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│            Business Logic                │
│  (Providers, Repositories)              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│            Data Layer                    │
│  (Models, Repositories)                  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│            Core Layer                    │
│  (Constants, Utils, Theme)               │
└─────────────────────────────────────────┘
```

## Layer Structure

### 1. Core Layer (`lib/core/`)

The core layer contains shared functionality used across the entire application.

#### Constants (`core/constants/`)

**File**: `app_constants.dart`

Centralized location for all magic numbers, thresholds, and configuration values.

```dart
// Example usage
AppConstants.userAvatarSize
AppConstants.unlockingSoonDaysThreshold
AppConstants.animationDurationShort
```

**Key Constants**:
- UI dimensions (heights, widths, padding)
- Animation durations
- Particle counts
- Validation limits
- Default values

#### Models (`core/models/`)

**File**: `models.dart`

Data models representing business entities:
- `Capsule`: Time-locked letter
- `Recipient`: Letter recipient
- `User`: Application user

#### Providers (`core/providers/`)

**File**: `providers.dart`

Riverpod providers for state management:
- `currentUserProvider`: Current authenticated user
- `capsulesProvider`: User's capsules
- `upcomingCapsulesProvider`: Capsules unlocking later
- `unlockingSoonCapsulesProvider`: Capsules unlocking within 7 days
- `openedCapsulesProvider`: Already opened capsules
- `selectedColorSchemeProvider`: Current theme

#### Repositories (`core/data/`)

**File**: `repositories.dart`

Data access layer with repository pattern:
- `CapsuleRepository`: Capsule CRUD operations
- `RecipientRepository`: Recipient management
- `UserRepository`: User operations

**Note**: Currently uses mock implementations. Replace with actual backend when ready.

#### Errors (`core/errors/`)

**File**: `app_exceptions.dart`

Custom exception hierarchy:
- `AppException`: Base exception
- `NotFoundException`: Resource not found
- `ValidationException`: Input validation errors
- `AuthenticationException`: Auth-related errors
- `NetworkException`: Network/API errors

#### Router (`core/router/`)

**File**: `app_router.dart`

Navigation configuration using GoRouter:
- Route definitions
- Route guards
- Deep linking support

#### Theme (`core/theme/`)

**Files**:
- `app_theme.dart`: Base theme configuration
- `color_scheme.dart`: Color scheme definitions
- `dynamic_theme.dart`: Dynamic gradient generation
- `color_scheme_service.dart`: Theme management service

#### Utils (`core/utils/`)

**Files**:
- `logger.dart`: Centralized logging (replaces print statements)
- `validation.dart`: Input validation and sanitization

#### Widgets (`core/widgets/`)

**Files**:
- `common_widgets.dart`: Reusable UI components
- `magic_dust_background.dart`: Background animation effect

### 2. Features Layer (`lib/features/`)

Feature modules organized by functionality. Each feature is self-contained.

#### Authentication (`features/auth/`)

- `welcome_screen.dart`: Welcome/onboarding screen
- `login_screen.dart`: User login
- `signup_screen.dart`: User registration

#### Home (`features/home/`)

- `home_screen.dart`: Sender's home screen with tabs
- `capsule_card.dart`: Capsule card widget

**Tabs**:
- Unfolding: Capsules unlocking within 7 days (Tab 0)
- Sealed: Capsules unlocking later (Tab 1)
- Revealed: Already opened capsules (Tab 2)

#### Receiver (`features/receiver/`)

- `receiver_home_screen.dart`: Receiver's inbox screen

**Tabs**:
- Sealed: Capsules unlocking within 7 days (Tab 0)
- Ready: Locked incoming capsules (Tab 1)
- Opened: Opened incoming capsules (Tab 2)

#### Capsule (`features/capsule/`)

- `locked_capsule_screen.dart`: View locked capsule
- `opening_animation_screen.dart`: Unlocking animation
- `opened_letter_screen.dart`: Read opened letter

#### Create Capsule (`features/create_capsule/`)

Multi-step letter creation flow:
- `create_capsule_screen.dart`: Main flow controller
- `step_choose_recipient.dart`: Select recipient
- `step_write_letter.dart`: Write letter content
- `step_choose_time.dart`: Set unlock time
- `step_preview.dart`: Preview before sending

#### Recipients (`features/recipients/`)

- `recipients_screen.dart`: List recipients
- `add_recipient_screen.dart`: Add/edit recipient

#### Profile (`features/profile/`)

- `profile_screen.dart`: User profile
- `color_scheme_screen.dart`: Theme customization

#### Navigation (`features/navigation/`)

- `main_navigation.dart`: Bottom navigation wrapper

### 3. Animations Layer (`lib/animations/`)

Premium animation system for magical user experience.

#### Widgets (`animations/widgets/`)

- `sealed_card_animation.dart`: Locked capsule animation
- `unfolding_card_animation.dart`: Unlocking soon animation
- `revealed_card_animation.dart`: Opened letter animation
- `sparkle_particle_engine.dart`: Particle system
- `countdown_ring.dart`: Countdown timer animation

#### Effects (`animations/effects/`)

- `confetti_burst.dart`: Confetti celebration effect
- `glow_effect.dart`: Glowing animation effect

#### Painters (`animations/painters/`)

- `mist_painter.dart`: Mist/fog effect painter
- `shimmer_painter.dart`: Shimmer effect painter

#### Theme (`animations/theme/`)

- `animation_theme.dart`: Animation constants and colors

## State Management

### Riverpod Pattern

The app uses Riverpod for state management with the following patterns:

#### Provider Types

1. **FutureProvider**: For async data
   ```dart
   final capsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
     final repo = ref.watch(capsuleRepositoryProvider);
     return repo.getCapsules(userId: userId);
   });
   ```

2. **StateProvider**: For simple state
   ```dart
   final selectedColorSchemeProvider = StateProvider<AppColorScheme>((ref) {
     return AppColorScheme.defaultScheme;
   });
   ```

3. **Provider**: For dependencies
   ```dart
   final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
     return MockCapsuleRepository();
   });
   ```

#### Usage in Widgets

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(capsulesProvider(userId));
    
    return capsulesAsync.when(
      data: (capsules) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

## Navigation

### GoRouter Configuration

Navigation is handled by GoRouter with the following structure:

```dart
GoRouter(
  initialLocation: Routes.welcome,
  redirect: (context, state) {
    // Auth guard logic
  },
  routes: [
    // Auth routes
    GoRoute(path: Routes.login, ...),
    
    // Main app with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainNavigation(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(path: Routes.receiverHome, ...), // Inbox (Tab 0 - PRIMARY)
        GoRoute(path: Routes.home, ...),         // Outbox (Tab 1 - SECONDARY)
      ],
    ),
    
    // Feature routes
    GoRoute(path: Routes.createCapsule, ...),
    ...
  ],
)
```

### Navigation Patterns

```dart
// Push new route
context.push(Routes.createCapsule);

// Push with data
context.push('/capsule/${capsule.id}', extra: capsule);

// Pop route
context.pop();
```

## Theming System

### Color Schemes

Color schemes are defined in `core/theme/color_scheme.dart`:

```dart
class AppColorScheme {
  final Color primary1;
  final Color primary2;
  final Color secondary1;
  final Color secondary2;
  final Color accent;
  ...
}
```

### Dynamic Themes

Gradients are generated dynamically based on the selected color scheme:

```dart
final gradient = DynamicTheme.dreamyGradient(colorScheme);
```

### Theme Selection

Users can select themes via `color_scheme_screen.dart`. The selection is stored in `selectedColorSchemeProvider`.

## Error Handling

### Exception Hierarchy

```
AppException (base)
├── NotFoundException
├── ValidationException
├── AuthenticationException
└── NetworkException
```

### Error Handling Pattern

```dart
try {
  final capsule = await repository.getCapsule(id);
  return capsule;
} on NotFoundException catch (e) {
  Logger.error('Capsule not found', error: e);
  throw NotFoundException('Capsule not found: $id');
} on NetworkException catch (e) {
  Logger.error('Network error', error: e);
  throw NetworkException('Failed to fetch capsule');
} catch (e) {
  Logger.error('Unexpected error', error: e);
  throw AppException('An unexpected error occurred');
}
```

## Data Flow

### Reading Data

```
Widget
  ↓ watch()
Provider
  ↓
Repository
  ↓
Data Source (Mock/API)
```

### Writing Data

```
Widget
  ↓ user action
Provider/Repository
  ↓
Data Source (Mock/API)
  ↓
State Update
  ↓
Widget Rebuild
```

## Best Practices

### 1. Constants

Always use `AppConstants` instead of magic numbers:
```dart
// ❌ Bad
Container(height: 56)

// ✅ Good
Container(height: AppConstants.createButtonHeight)
```

### 2. Error Handling

Always handle errors properly:
```dart
// ❌ Bad
final data = await fetchData();

// ✅ Good
try {
  final data = await fetchData();
} on NetworkException catch (e) {
  // Handle error
}
```

### 3. Logging

Use `Logger` instead of `print`:
```dart
// ❌ Bad
print('Error occurred');

// ✅ Good
Logger.error('Error occurred', error: e);
```

### 4. Validation

Always validate user input:
```dart
// ✅ Good
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}
```

### 5. Performance

- Use `RepaintBoundary` for animations
- Reuse Paint objects in CustomPainters
- Add keys to ListView items
- Cache expensive computations

## Next Steps

- Review [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md) for performance details
- Check [API_REFERENCE.md](./API_REFERENCE.md) for API documentation
- Read [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md) for code quality guidelines

---

**Last Updated**: 2025

