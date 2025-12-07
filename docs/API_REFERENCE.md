# API Reference

This document provides detailed API reference for key classes, functions, and patterns used in the OpenOn app.

## Table of Contents

1. [Constants](#constants)
2. [Models](#models)
3. [Providers](#providers)
4. [Repositories](#repositories)
5. [Exceptions](#exceptions)
6. [Utilities](#utilities)
7. [Widgets](#widgets)
8. [Animations](#animations)

## Constants

### AppConstants

**Location**: `core/constants/app_constants.dart`

Centralized constants for the entire application.

#### UI Dimensions

```dart
static const double bottomNavHeight = 60.0;
static const double fabSize = 56.0;
static const double userAvatarSize = 48.0;
static const double createButtonHeight = 56.0;
static const double tabLabelPadding = 4.0;
static const double tabSpacing = 3.0;
```

#### Animation Durations

```dart
static const Duration animationDurationShort = Duration(milliseconds: 200);
static const Duration animationDurationMedium = Duration(milliseconds: 300);
static const Duration animationDurationLong = Duration(milliseconds: 500);
static const Duration magicDustAnimationDuration = Duration(seconds: 8);
static const Duration sparkleAnimationDuration = Duration(seconds: 3);
```

#### Thresholds

```dart
static const int unlockingSoonDaysThreshold = 7;
static const int maxContentLength = 10000;
static const int maxTitleLength = 200;
static const int minPasswordLength = 8;
```

## Models

### Capsule

**Location**: `core/models/models.dart`

Represents a time-locked letter.

```dart
class Capsule {
  final String id;
  final String label;
  final String content;
  final String recipientId;
  final String recipientName;
  final DateTime unlockTime;
  final DateTime? openedAt;
  final String? reaction;
  final CapsuleStatus status;
  
  // Computed properties
  bool get isOpened => status == CapsuleStatus.opened;
  bool get isUnlocked => DateTime.now().isAfter(unlockTime);
  bool get isUnlockingSoon => timeUntilUnlock.inDays <= 7;
  Duration get timeUntilUnlock => unlockTime.difference(DateTime.now());
}
```

### Recipient

```dart
class Recipient {
  final String id;
  final String name;
  final String? email;
  final String? relationship;
  final String? avatarUrl;
}
```

### User

```dart
class User {
  final String id;
  final String name;  // Full name (computed from first_name + last_name from backend)
  final String email;
  final String username;  // Unique username for searching
  final String avatar;  // URL or asset path
  
  // Computed properties
  String get firstName;  // Extracted from name
  String? get avatarUrl;  // If avatar is HTTP URL
  String? get localAvatarPath;  // If avatar is local path
}
```

**Note**: The frontend `User` model uses `name` (full name) which is computed from `first_name` and `last_name` received from the backend. The backend API returns `first_name`, `last_name`, and `username` separately.

## Providers

### User Providers

**Location**: `core/providers/providers.dart`

```dart
// Current authenticated user
final currentUserProvider = FutureProvider<User?>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getCurrentUser();
});

// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value != null;
});
```

### Capsule Providers

```dart
// All capsules for a user
final capsulesProvider = FutureProvider.family<List<Capsule>, String>(
  (ref, userId) async {
    final repo = ref.watch(capsuleRepositoryProvider);
    return repo.getCapsules(userId: userId, asSender: true);
  }
);

// Upcoming capsules (unlocking later)
final upcomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>(
  (ref, userId) async {
    final capsulesAsync = ref.watch(capsulesProvider(userId));
    return capsulesAsync.when(
      data: (capsules) => capsules
          .where((c) => c.status == CapsuleStatus.locked && 
                       c.timeUntilUnlock.inDays > 7)
          .toList(),
      loading: () => <Capsule>[],
      error: (_, __) => <Capsule>[],
    );
  }
);

// Unlocking soon (within 7 days)
final unlockingSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>(
  (ref, userId) async {
    final capsulesAsync = ref.watch(capsulesProvider(userId));
    return capsulesAsync.when(
      data: (capsules) => capsules
          .where((c) => c.status == CapsuleStatus.unlockingSoon)
          .toList(),
      loading: () => <Capsule>[],
      error: (_, __) => <Capsule>[],
    );
  }
);

// Opened capsules
final openedCapsulesProvider = FutureProvider.family<List<Capsule>, String>(
  (ref, userId) async {
    final capsulesAsync = ref.watch(capsulesProvider(userId));
    return capsulesAsync.when(
      data: (capsules) => capsules
          .where((c) => c.status == CapsuleStatus.opened)
          .toList(),
      loading: () => <Capsule>[],
      error: (_, __) => <Capsule>[],
    );
  }
);
```

### Theme Provider

```dart
final selectedColorSchemeProvider = StateProvider<AppColorScheme>((ref) {
  return AppColorScheme.defaultScheme;
});
```

## Repositories

### CapsuleRepository

**Location**: `core/data/repositories.dart`

```dart
abstract class CapsuleRepository {
  Future<List<Capsule>> getCapsules({
    required String userId,
    bool asSender = true,
  });
  
  Future<Capsule> getCapsule(String id);
  Future<Capsule> createCapsule(Capsule capsule);
  Future<Capsule> updateCapsule(Capsule capsule);
  Future<void> deleteCapsule(String capsuleId);
  Future<void> markAsOpened(String capsuleId);
  Future<void> addReaction(String capsuleId, String reaction);
}
```

**Usage**:
```dart
final repo = ref.watch(capsuleRepositoryProvider);
final capsules = await repo.getCapsules(userId: userId);
```

### RecipientRepository

```dart
abstract class RecipientRepository {
  Future<List<Recipient>> getRecipients(String userId);
  Future<Recipient> getRecipient(String id);
  Future<Recipient> createRecipient(Recipient recipient);
  Future<Recipient> updateRecipient(Recipient recipient);
  Future<void> deleteRecipient(String id);
}
```

### UserRepository

```dart
abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User> updateUser(User user);
  Future<void> signOut();
}
```

## Exceptions

### AppException

**Location**: `core/errors/app_exceptions.dart`

Base exception class.

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});
}
```

### NotFoundException

```dart
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code});
}
```

**Usage**:
```dart
throw NotFoundException('Capsule not found: $id');
```

### ValidationException

```dart
class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}
```

**Usage**:
```dart
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}
```

### AuthenticationException

```dart
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code});
}
```

### NetworkException

```dart
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}
```

## Utilities

### Logger

**Location**: `core/utils/logger.dart`

Centralized logging system.

```dart
class Logger {
  static void debug(String message, {
    Object? error,
    StackTrace? stackTrace,
  });
  
  static void info(String message, {
    Object? error,
    StackTrace? stackTrace,
  });
  
  static void warning(String message, {
    Object? error,
    StackTrace? stackTrace,
  });
  
  static void error(String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
```

**Usage**:
```dart
Logger.info('User logged in');
Logger.error('Failed to fetch data', error: e);
```

### Validation

**Location**: `core/utils/validation.dart`

Input validation utilities.

```dart
class Validation {
  static bool isValidEmail(String email);
  static bool isValidPassword(String password);
  static String sanitizeString(String input);
  static bool isWithinLength(String input, int maxLength);
}
```

**Usage**:
```dart
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email');
}

final sanitized = Validation.sanitizeString(userInput);
```

## Widgets

### Common Widgets

**Location**: `core/widgets/common_widgets.dart`

#### GradientButton

```dart
GradientButton(
  text: 'Create Letter',
  onPressed: () => context.push(Routes.createCapsule),
  isLoading: false,
  gradient: DynamicTheme.dreamyGradient(colorScheme),
)
```

#### UserAvatar

```dart
UserAvatar(
  name: user.name,
  imageUrl: user.avatarUrl,
  imagePath: user.localAvatarPath,
  size: AppConstants.userAvatarSize,
)
```

#### StatusPill

```dart
StatusPill.opened()
StatusPill.readyToOpen()
StatusPill.lockedDynamic(colorScheme.primary1)
```

#### CountdownDisplay

```dart
CountdownDisplay(
  duration: capsule.timeUntilUnlock,
  style: Theme.of(context).textTheme.bodySmall,
)
```

#### AnimatedUnlockingSoonBadge

```dart
AnimatedUnlockingSoonBadge()
```

### Magic Dust Background

**Location**: `core/widgets/magic_dust_background.dart`

```dart
MagicDustBackground(
  baseColor: colorScheme.primary1,
  child: YourWidget(),
)
```

## Animations

### Sealed Card Animation

**Location**: `animations/widgets/sealed_card_animation.dart`

```dart
SealedCardAnimation(
  isLocked: true,
  onTap: () => context.push(Routes.capsule),
  child: CapsuleCard(capsule: capsule),
)
```

### Unfolding Card Animation

**Location**: `animations/widgets/unfolding_card_animation.dart`

```dart
UnfoldingCardAnimation(
  isUnfolding: true,
  onTap: () => context.push(Routes.capsule),
  child: CapsuleCard(capsule: capsule),
)
```

### Revealed Card Animation

**Location**: `animations/widgets/revealed_card_animation.dart`

```dart
RevealedCardAnimation(
  autoReveal: false,
  onRevealComplete: () => print('Revealed!'),
  child: LetterContent(),
)
```

### Sparkle Particle Engine

**Location**: `animations/widgets/sparkle_particle_engine.dart`

```dart
SparkleParticleEngine(
  isActive: true,
  mode: SparkleMode.drift,
  particleCount: 20,
  primaryColor: Colors.gold,
  child: YourWidget(),
)
```

**Modes**:
- `SparkleMode.drift`: Gentle upward drift
- `SparkleMode.orbit`: Circular orbit
- `SparkleMode.burst`: Explosive burst
- `SparkleMode.rain`: Falling sparkles

## Navigation

### Routes

**Location**: `core/router/app_router.dart`

```dart
class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const receiverHome = '/inbox';
  static const recipients = '/recipients';
  static const createCapsule = '/create-capsule';
  static const profile = '/profile';
}
```

### Navigation Methods

```dart
// Push route
context.push(Routes.home);

// Push with data
context.push('/capsule/${capsule.id}', extra: capsule);

// Pop route
context.pop();
```

## Theme

### Color Scheme

**Location**: `core/theme/color_scheme.dart`

```dart
class AppColorScheme {
  final Color primary1;
  final Color primary2;
  final Color secondary1;
  final Color secondary2;
  final Color accent;
}
```

### Dynamic Theme

**Location**: `core/theme/dynamic_theme.dart`

```dart
// Generate gradients
final softGradient = DynamicTheme.softGradient(colorScheme);
final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);
```

## Best Practices

### Using Providers

```dart
// Watch provider (rebuilds on change)
final userAsync = ref.watch(currentUserProvider);

// Read provider (no rebuild)
final user = ref.read(currentUserProvider);

// Handle async state
userAsync.when(
  data: (user) => UserWidget(user: user),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

### Error Handling

```dart
try {
  final capsule = await repository.getCapsule(id);
} on NotFoundException catch (e) {
  // Handle not found
} on ValidationException catch (e) {
  // Handle validation error
} catch (e) {
  // Handle unexpected error
}
```

### Validation

```dart
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}
```

## Next Steps

- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for architecture
- Check [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md) for performance
- Read [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md) for refactoring details

---

**Last Updated**: 2025

