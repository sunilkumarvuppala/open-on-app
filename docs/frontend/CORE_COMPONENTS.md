# Core Components Documentation

This document provides detailed documentation for all core components in the OpenOn app. These components form the foundation of the application and are used throughout the codebase.

## Table of Contents

1. [Overview](#overview)
2. [Constants](#constants)
3. [Models](#models)
4. [Providers](#providers)
5. [Repositories](#repositories)
6. [Router](#router)
7. [Theme System](#theme-system)
8. [Widgets](#widgets)
9. [Utilities](#utilities)
10. [Error Handling](#error-handling)

---

## Overview

The core layer (`lib/core/`) contains shared functionality used across the entire application. It follows the principle of separation of concerns, with each module having a specific responsibility.

```
core/
├── constants/      # App-wide constants and configuration
├── data/          # Data access layer (repositories)
├── errors/        # Custom exception classes
├── models/        # Data models and entities
├── providers/     # Riverpod state management
├── router/        # Navigation and routing
├── theme/         # Theming and styling system
├── utils/         # Utility functions and helpers
└── widgets/       # Reusable UI components
```

---

## Constants

**Location**: `core/constants/app_constants.dart`

### Purpose

Centralized location for all magic numbers, hardcoded values, and configuration constants used throughout the app.

### Key Constants

#### Time Durations
```dart
static const Duration networkDelaySimulation = Duration(milliseconds: 500);
static const Duration createCapsuleDelay = Duration(milliseconds: 800);
static const Duration animationDurationShort = Duration(milliseconds: 200);
static const Duration animationDurationMedium = Duration(milliseconds: 300);
static const Duration animationDurationLong = Duration(milliseconds: 500);
```

#### UI Dimensions
```dart
static const double bottomNavHeight = 60.0;
static const double fabSize = 56.0;
static const double defaultPadding = 16.0;
static const double tabSpacing = 3.0;
```

#### Business Logic
```dart
static const int unlockingSoonDaysThreshold = 7;  // Days before unlock
static const int maxContentLength = 10000;
static const int maxTitleLength = 200;
static const int minPasswordLength = 8;
```

#### Animation Settings
```dart
static const int magicDustParticleCount = 20;
static const int magicDustSparkleCount = 10;
static const int targetFPS = 60;
```

### Usage

Always use constants from `AppConstants` instead of hardcoded values:

```dart
// ✅ Good
SizedBox(height: AppConstants.defaultPadding)

// ❌ Bad
SizedBox(height: 16.0)
```

### Benefits

- **Maintainability**: Change values in one place
- **Consistency**: Same values used everywhere
- **Documentation**: Constants serve as documentation
- **Type Safety**: Compile-time checking

---

## Models

**Location**: `core/models/models.dart`

### Purpose

Data models represent the core entities in the application. All models are immutable and include validation logic.

### Core Models

#### 1. Capsule

Represents a time-locked letter.

```dart
class Capsule {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String label;
  final String content;
  final String? photoUrl;
  final DateTime unlockAt;
  final DateTime createdAt;
  final DateTime? openedAt;
  final String? reaction;
}
```

**Key Properties**:
- `status`: Computed status (locked, unlockingSoon, opened)
- `isLocked`: Whether capsule is still locked
- `isUnlocked`: Whether capsule can be opened
- `isOpened`: Whether capsule has been opened
- `timeUntilUnlock`: Duration until unlock
- `countdownText`: Human-readable countdown

**Status Logic**:
```dart
CapsuleStatus get status {
  if (openedAt != null) return CapsuleStatus.opened;
  if (unlockAt.isBefore(DateTime.now())) return CapsuleStatus.opened;
  if (daysUntilUnlock <= 7) return CapsuleStatus.unlockingSoon;
  return CapsuleStatus.locked;
}
```

#### 2. Recipient

Represents a person who can receive capsules.

```dart
class Recipient {
  final String id;
  final String userId;
  final String name;
  final String? username; // @username for display
  final String? avatarUrl;
  final DateTime createdAt;
}
```

#### 3. User

Represents the current authenticated user.

```dart
class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
}
```

#### 4. Draft

Represents an unsaved letter draft.

```dart
class Draft {
  final String id;
  final String userId;
  final String? recipientId;
  final String? label;
  final String? content;
  final String? photoUrl;
  final DateTime? unlockAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Model Best Practices

1. **Immutability**: All models are immutable (final fields)
2. **Copy Methods**: Use `copyWith()` for updates
3. **Validation**: Include validation in constructors
4. **Computed Properties**: Use getters for derived data
5. **Equality**: Implement `==` and `hashCode` for comparison

---

## Providers

**Location**: `core/providers/providers.dart`

### Purpose

Riverpod providers manage application state. They provide reactive state management with dependency injection.

### Provider Types

#### 1. Repository Providers

Provide repository instances:

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
  return MockCapsuleRepository();
});
```

#### 2. Data Providers

Provide reactive data streams:

```dart
final currentUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

final capsulesProvider = FutureProvider<List<Capsule>>((ref) {
  final repo = ref.watch(capsuleRepositoryProvider);
  final userId = ref.watch(currentUserProvider).asData?.value?.id ?? '';
  return repo.getCapsules(userId);
});
```

#### 3. Filtered Providers

Provide filtered/transformed data:

```dart
final upcomingCapsulesProvider = Provider.family<Future<List<Capsule>>, String>(
  (ref, userId) async {
    final capsules = await ref.watch(capsulesProvider.future);
    return capsules.where((c) => c.status == CapsuleStatus.locked).toList();
  },
);
```

#### 4. Name Filter Providers

Provide filtered letter lists based on name queries:

**State Providers**:
- `receiveFilterExpandedProvider: StateProvider<bool>` - Receive screen filter visibility
- `receiveFilterQueryProvider: StateProvider<String>` - Receive screen filter query
- `sendFilterExpandedProvider: StateProvider<bool>` - Send screen filter visibility
- `sendFilterQueryProvider: StateProvider<String>` - Send screen filter query

**Filtered List Providers** (Receive Screen):
- `receiveFilteredOpeningSoonCapsulesProvider(userId)` - Filtered "Sealed" tab
- `receiveFilteredReadyCapsulesProvider(userId)` - Filtered "Ready" tab
- `receiveFilteredOpenedCapsulesProvider(userId)` - Filtered "Opened" tab

**Filtered List Providers** (Send Screen):
- `sendFilteredUnlockingSoonCapsulesProvider(userId)` - Filtered "Unfolding" tab
- `sendFilteredUpcomingCapsulesProvider(userId)` - Filtered "Sealed" tab
- `sendFilteredOpenedCapsulesProvider(userId)` - Filtered "Opened" tab

**Usage**:
```dart
// In tab widget
final capsulesAsync = ref.watch(receiveFilteredOpeningSoonCapsulesProvider(userId));
final filterQuery = ref.watch(receiveFilterQueryProvider);

// Filtered list automatically updates when query changes
// Returns full list when query is empty
```

**Performance**: Early returns for empty queries, efficient filtering, reuses cached data from base providers.

**Related Documentation**: **[NAME_FILTER.md](./features/NAME_FILTER.md)**

#### 5. Theme Providers

Manage theme state:

```dart
final selectedColorSchemeProvider = StateNotifierProvider<ColorSchemeNotifier, AppColorScheme>(
  (ref) {
    final currentSchemeAsync = ref.watch(colorSchemeProvider);
    final initialScheme = currentSchemeAsync.asData?.value ?? AppColorScheme.galaxyAurora;
    return ColorSchemeNotifier(initialScheme);
  },
);
```

### Provider Usage

**Watching Providers**:
```dart
final user = ref.watch(currentUserProvider);
final capsules = ref.watch(capsulesProvider);
```

**Reading Providers**:
```dart
final repo = ref.read(authRepositoryProvider);
```

**Invalidating Providers**:
```dart
ref.invalidate(capsulesProvider);
```

### Provider Best Practices

1. **Watch vs Read**: Use `watch` for reactive updates, `read` for one-time access
2. **Family Providers**: Use for parameterized providers
3. **Async Handling**: Use `when()` for loading/error states
4. **Dependencies**: Watch dependencies, read services
5. **Invalidation**: Invalidate when data changes

---

## Repositories

**Location**: `core/data/repositories.dart`

### Purpose

Repositories abstract data access. They provide a clean interface for data operations, hiding implementation details.

### Repository Pattern

```dart
abstract class CapsuleRepository {
  Future<List<Capsule>> getCapsules(String userId);
  Future<Capsule> getCapsule(String id);
  Future<Capsule> createCapsule(Capsule capsule);
  Future<Capsule> updateCapsule(Capsule capsule);
  Future<void> deleteCapsule(String id);
  Future<void> markAsOpened(String id);
}
```

### Current Implementation

The app uses **Mock Repositories** for development:

- `MockAuthRepository`: Simulates authentication
- `MockCapsuleRepository`: Simulates capsule storage
- `MockRecipientRepository`: Simulates recipient storage
- `MockDraftRepository`: Simulates draft storage

### Repository Methods

#### Authentication
```dart
Future<User> signUp(String email, String password, String name);
Future<User> signIn(String email, String password);
Future<void> signOut();
Stream<User?> getCurrentUser();
Future<User> updateProfile(User user);
```

#### Capsules
```dart
Future<List<Capsule>> getCapsules(String userId);
Future<Capsule> createCapsule(Capsule capsule);
Future<void> markAsOpened(String id);
Future<void> addReaction(String id, String reaction);
```

### Future Backend Integration

When integrating with a real backend:

1. Create new repository implementations
2. Replace mock repositories in providers
3. Add network error handling
4. Implement caching strategies
5. Add retry logic

---

## Router

**Location**: `core/router/app_router.dart`

### Purpose

GoRouter configuration for app navigation. Handles routing, deep linking, and navigation guards.

### Route Structure

```
/ (root)
├── /welcome          # Welcome screen
├── /login            # Login screen
├── /signup           # Signup screen
└── /inbox (shell)    # Main app shell (PRIMARY)
    ├── /inbox        # Receiver inbox (Tab 0 - PRIMARY, default after auth)
    ├── /home         # Sender home/Outbox (Tab 1 - SECONDARY)
    ├── /create-capsule # Create capsule
    ├── /drafts       # Drafts list
    ├── /recipients   # Recipients list
    │   └── /recipients/add # Add recipient
    ├── /profile      # User profile
    │   └── /profile/color-scheme # Theme selection
    └── /capsule/:id  # View capsule
        ├── /capsule/:id/opening # Opening animation
        └── /capsule/:id/opened  # Opened letter
```

### Route Configuration

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    initialLocation: Routes.welcome,
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final isGoingToAuth = state.matchedLocation == Routes.welcome ||
          state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.signup;
      
      // Redirect to inbox (primary home) if authenticated and trying to access auth screens
      if (isAuth && isGoingToAuth) {
        return Routes.receiverHome;
      }
      
      // Redirect to welcome if not authenticated and trying to access protected screens
      final isProtectedRoute = !isGoingToAuth;
      if (!isAuth && isProtectedRoute) {
        return Routes.welcome;
      }
      
      return null;
    },
    routes: [
      // Routes...
    ],
  );
});
```

### Navigation Methods

**Push Route** (adds to navigation stack):
```dart
context.push('/capsule/$id', extra: capsule);
context.push(Routes.profile);
context.push(Routes.createCapsule);
```

**Go Route** (replaces current route, used for tab switching):
```dart
context.go(Routes.receiverHome); // Navigate to Inbox (Tab 0 - PRIMARY)
context.go(Routes.home);          // Navigate to Outbox (Tab 1 - SECONDARY)
```

**Pop Route** (goes back):
```dart
context.pop();
```

### Route Guards

Authentication guard automatically:
- **Redirects authenticated users** from auth screens to **Inbox** (`Routes.receiverHome`) - PRIMARY, default after auth
- **Redirects unauthenticated users** from protected screens to **Welcome** (`Routes.welcome`)
- **Default after authentication**: Inbox (Tab 0 - PRIMARY)

---

## Theme System

**Location**: `core/theme/`

### Purpose

Comprehensive theming system supporting multiple color schemes with dynamic gradient generation.

### Theme Files

1. **`app_theme.dart`**: Base theme constants and colors
2. **`color_scheme.dart`**: Color scheme definitions
3. **`dynamic_theme.dart`**: Dynamic theme builder
4. **`color_scheme_service.dart`**: Theme persistence

### Color Schemes

The app supports multiple predefined color schemes:

- **Galaxy Aurora**: Purple/blue gradient (default)
- **Forest Green**: Green/nature theme
- **Sunset Dreams**: Orange/pink gradient
- **Ocean Breeze**: Blue/cyan gradient
- **Rose Gold**: Pink/gold gradient

### Using Themes

**Get Current Scheme**:
```dart
final colorScheme = ref.watch(selectedColorSchemeProvider);
```

**Get Gradients**:
```dart
final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);
final softGradient = DynamicTheme.softGradient(colorScheme);
final warmGradient = DynamicTheme.warmGradient(colorScheme);
```

**Apply Theme**:
```dart
MaterialApp(
  theme: DynamicTheme.buildTheme(colorScheme),
)
```

### Theme Persistence

User's color scheme preference is saved to SharedPreferences and restored on app launch.

---

## Widgets

**Location**: `core/widgets/`

### Common Widgets

**File**: `common_widgets.dart`

Reusable UI components used throughout the app.

#### 1. GradientButton

Button with gradient background:

```dart
GradientButton(
  text: 'Create Letter',
  onPressed: () {},
  gradient: DynamicTheme.dreamyGradient(colorScheme),
  isLoading: false,
)
```

#### 2. UserAvatar

Avatar with fallback to initials:

```dart
UserAvatar(
  imageUrl: user.avatarUrl,
  name: user.name,
  size: 48,
)
```

#### 3. EmptyState

Empty state display:

```dart
EmptyState(
  icon: Icons.mail_outline,
  title: 'No letters yet',
  message: 'Create your first letter',
  action: ElevatedButton(...),
)
```

#### 4. ErrorDisplay

Error state display:

```dart
ErrorDisplay(
  message: 'Failed to load',
  onRetry: () {},
)
```

### Magic Dust Background

**File**: `magic_dust_background.dart`

Animated background effect with particles and sparkles.

```dart
MagicDustBackground(
  colorScheme: colorScheme,
  child: YourContent(),
)
```

### InlineNameFilterBar

**File**: `inline_name_filter_bar.dart`

Reusable inline search bar that expands/collapses on demand. Used for filtering letter lists by name.

**Purpose**: Provides on-demand name filtering with smooth animations and debounced input.

**Key Features**:
- Hidden by default, expands when search icon is tapped
- Auto-focuses text field when expanded
- Shows clear button (×) when text is entered
- Smooth expand/collapse animation (250ms)
- 200ms debounced input to prevent excessive filtering
- Input length limit (100 characters) for security
- Post-frame callbacks to avoid layout conflicts

**Props**:
- `expanded: bool` - Whether the filter bar is expanded
- `query: String` - Current filter query text
- `onChanged: ValueChanged<String>` - Callback when query changes (debounced)
- `onClear: VoidCallback` - Callback when clear button is tapped
- `onToggleExpand: VoidCallback` - Callback to toggle expansion
- `placeholder: String` - Placeholder text (default: "Filter by name…")

**Usage Example**:
```dart
InlineNameFilterBar(
  expanded: ref.watch(receiveFilterExpandedProvider),
  query: ref.watch(receiveFilterQueryProvider),
  onChanged: (value) {
    ref.read(receiveFilterQueryProvider.notifier).state = value;
  },
  onClear: () {
    ref.read(receiveFilterQueryProvider.notifier).state = '';
  },
  onToggleExpand: () {
    final isExpanded = ref.read(receiveFilterExpandedProvider);
    ref.read(receiveFilterExpandedProvider.notifier).state = !isExpanded;
  },
  placeholder: 'Filter by sender name…',
)
```

**Performance Optimizations**:
- Fixed height (48px) to prevent expansion when typing
- Debounced state updates (200ms)
- Post-frame callbacks to avoid "Build scheduled during frame" errors
- Proper disposal of controllers, timers, and focus nodes

**Security**:
- Input length validation (max 100 characters)
- Input sanitization in business logic layer

**Related Documentation**:
- **[NAME_FILTER.md](./features/NAME_FILTER.md)** - Complete name filter feature documentation
- **[UTILITIES.md](./UTILITIES.md)** - Name filter utilities

---

## Utilities

**Location**: `core/utils/`

### Logger

**File**: `logger.dart`

Centralized logging system replacing print statements.

```dart
Logger.debug('Debug message');
Logger.info('Info message');
Logger.warning('Warning message');
Logger.error('Error message', error: e, stackTrace: stack);
```

### Validation

**File**: `validation.dart`

Input validation and sanitization utilities.

```dart
ValidationResult validateEmail(String email);
ValidationResult validatePassword(String password);
String sanitizeInput(String input);
```

---

## Error Handling

**Location**: `core/errors/app_exceptions.dart`

### Custom Exceptions

```dart
class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}
```

### Error Handling Pattern

```dart
try {
  await repository.createCapsule(capsule);
} on ValidationException catch (e) {
  // Handle validation error
} on NetworkException catch (e) {
  // Handle network error
} catch (e, stackTrace) {
  Logger.error('Unexpected error', error: e, stackTrace: stackTrace);
}
```

---

## Best Practices

### 1. Use Constants
Always use `AppConstants` instead of magic numbers.

### 2. Immutable Models
Keep models immutable, use `copyWith()` for updates.

### 3. Provider Patterns
- Watch for reactive updates
- Read for one-time access
- Use family providers for parameters

### 4. Error Handling
Always handle errors gracefully with user-friendly messages.

### 5. Theme Consistency
Use theme colors and gradients from `DynamicTheme`.

### 6. Widget Reusability
Use common widgets instead of duplicating code.

---

## Next Steps

- [Architecture Documentation](./ARCHITECTURE.md)
- [Feature Documentation](./features/)
- [API Reference](./API_REFERENCE.md)

---

**Last Updated**: 2025

