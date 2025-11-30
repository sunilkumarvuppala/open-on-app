# Code Structure Guide

This document provides a visual guide to the codebase structure and file organization.

## Directory Tree

```
frontend/lib/
│
├── core/                          # Core application layer
│   ├── constants/
│   │   └── app_constants.dart    # All constants (UI, animation, validation)
│   │
│   ├── data/
│   │   └── repositories.dart     # Data access layer (Capsule, Recipient, User, Draft)
│   │
│   ├── errors/
│   │   └── app_exceptions.dart   # Custom exception hierarchy
│   │
│   ├── models/
│   │   └── models.dart           # Data models (Capsule, Recipient, User, Draft)
│   │
│   ├── providers/
│   │   └── providers.dart        # Riverpod state providers
│   │
│   ├── router/
│   │   └── app_router.dart       # GoRouter navigation configuration
│   │
│   ├── theme/
│   │   ├── app_theme.dart        # Base theme configuration
│   │   ├── color_scheme.dart     # Color scheme definitions
│   │   ├── color_scheme_service.dart  # Theme management
│   │   └── dynamic_theme.dart    # Dynamic gradient generation
│   │
│   ├── utils/
│   │   ├── logger.dart           # Centralized logging system
│   │   └── validation.dart      # Input validation utilities
│   │
│   └── widgets/
│       ├── common_widgets.dart   # Reusable UI components
│       └── magic_dust_background.dart  # Background animation
│
├── features/                      # Feature modules
│   ├── auth/
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   │
│   ├── capsule/
│   │   ├── locked_capsule_screen.dart
│   │   ├── opening_animation_screen.dart
│   │   └── opened_letter_screen.dart
│   │
│   ├── create_capsule/
│   │   ├── create_capsule_screen.dart
│   │   ├── step_choose_recipient.dart
│   │   ├── step_write_letter.dart
│   │   ├── step_choose_time.dart
│   │   └── step_preview.dart
│   │
│   ├── drafts/
│   │   └── drafts_screen.dart
│   │
│   ├── home/
│   │   ├── home_screen.dart      # Sender home (3 tabs)
│   │   └── capsule_card.dart
│   │
│   ├── navigation/
│   │   └── main_navigation.dart  # Bottom navigation wrapper
│   │
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   └── color_scheme_screen.dart
│   │
│   ├── receiver/
│   │   └── receiver_home_screen.dart  # Receiver inbox (3 tabs)
│   │
│   └── recipients/
│       ├── recipients_screen.dart
│       └── add_recipient_screen.dart
│
├── animations/                    # Animation system
│   ├── effects/
│   │   ├── confetti_burst.dart
│   │   └── glow_effect.dart
│   │
│   ├── painters/
│   │   ├── mist_painter.dart
│   │   └── shimmer_painter.dart
│   │
│   ├── theme/
│   │   └── animation_theme.dart
│   │
│   └── widgets/
│       ├── sealed_card_animation.dart
│       ├── unfolding_card_animation.dart
│       ├── revealed_card_animation.dart
│       ├── sparkle_particle_engine.dart
│       └── countdown_ring.dart
│
└── main.dart                      # Application entry point
```

## File Responsibilities

### Core Layer

#### Constants (`core/constants/`)
- **Purpose**: Centralized constants
- **Key File**: `app_constants.dart`
- **Contains**: UI dimensions, animation durations, thresholds, validation limits

#### Data (`core/data/`)
- **Purpose**: Data access abstraction
- **Key File**: `repositories.dart`
- **Contains**: Repository interfaces and mock implementations

#### Errors (`core/errors/`)
- **Purpose**: Error handling
- **Key File**: `app_exceptions.dart`
- **Contains**: Custom exception classes

#### Models (`core/models/`)
- **Purpose**: Data models
- **Key File**: `models.dart`
- **Contains**: Capsule, Recipient, User, Draft models

#### Providers (`core/providers/`)
- **Purpose**: State management
- **Key File**: `providers.dart`
- **Contains**: Riverpod providers for state

#### Router (`core/router/`)
- **Purpose**: Navigation
- **Key File**: `app_router.dart`
- **Contains**: GoRouter configuration and routes

#### Theme (`core/theme/`)
- **Purpose**: Theming system
- **Key Files**: 
  - `app_theme.dart`: Base theme
  - `color_scheme.dart`: Color schemes
  - `dynamic_theme.dart`: Gradient generation

#### Utils (`core/utils/`)
- **Purpose**: Utility functions
- **Key Files**:
  - `logger.dart`: Logging system
  - `validation.dart`: Input validation

#### Widgets (`core/widgets/`)
- **Purpose**: Reusable widgets
- **Key Files**:
  - `common_widgets.dart`: Common UI components
  - `magic_dust_background.dart`: Background effect

### Features Layer

Each feature is self-contained with its own screens and logic.

#### Auth (`features/auth/`)
- Authentication flow
- Welcome, login, signup screens

#### Capsule (`features/capsule/`)
- Viewing capsules
- Locked, opening, opened states

#### Create Capsule (`features/create_capsule/`)
- Multi-step letter creation
- Recipient selection, writing, time selection, preview

#### Drafts (`features/drafts/`)
- Draft management
- List, edit, delete drafts

#### Home (`features/home/`)
- Sender's home screen
- Three tabs: Unfolding Soon, Upcoming, Opened

#### Receiver (`features/receiver/`)
- Receiver's inbox
- Three tabs: Locked, Opening Soon, Opened

#### Recipients (`features/recipients/`)
- Recipient management
- List, add, edit recipients

#### Profile (`features/profile/`)
- User profile
- Theme customization

### Animations Layer

Premium animation system for magical UX.

#### Widgets (`animations/widgets/`)
- Card animations (sealed, unfolding, revealed)
- Particle systems
- Countdown animations

#### Effects (`animations/effects/`)
- Confetti burst
- Glow effects

#### Painters (`animations/painters/`)
- Custom painters for visual effects
- Mist, shimmer effects

## Data Flow

### Reading Data

```
Screen Widget
    ↓ watch()
Riverpod Provider
    ↓
Repository
    ↓
Data Source (Mock/API)
    ↓
Return Data
    ↓
Update UI
```

### Writing Data

```
User Action
    ↓
Screen Widget
    ↓
Repository Method
    ↓
Data Source (Mock/API)
    ↓
State Update
    ↓
Provider Notify
    ↓
Widget Rebuild
```

## Navigation Flow

```
Welcome Screen
    ↓
Login/Signup
    ↓
Main Navigation (Bottom Nav)
    ├── Home (Sender)
    │   ├── Unfolding Soon Tab
    │   ├── Upcoming Tab
    │   └── Opened Tab
    │
    └── Inbox (Receiver)
        ├── Locked Tab
        ├── Opening Soon Tab
        └── Opened Tab
    ↓
Feature Screens
    ├── Create Capsule
    ├── Recipients
    ├── Profile
    └── Drafts
```

## Key Patterns

### 1. Provider Pattern

```dart
// Define provider
final capsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final repo = ref.watch(capsuleRepositoryProvider);
  return repo.getCapsules(userId: userId);
});

// Use in widget
final capsulesAsync = ref.watch(capsulesProvider(userId));
```

### 2. Repository Pattern

```dart
// Define repository
abstract class CapsuleRepository {
  Future<List<Capsule>> getCapsules({required String userId});
}

// Implement repository
class MockCapsuleRepository implements CapsuleRepository {
  @override
  Future<List<Capsule>> getCapsules({required String userId}) async {
    // Implementation
  }
}
```

### 3. Error Handling Pattern

```dart
try {
  final result = await repository.getData();
} on NotFoundException catch (e) {
  Logger.error('Not found', error: e);
  // Handle error
} catch (e) {
  Logger.error('Unexpected error', error: e);
  throw AppException('An error occurred');
}
```

### 4. Animation Pattern

```dart
class MyAnimatedWidget extends StatefulWidget {
  @override
  State<MyAnimatedWidget> createState() => _MyAnimatedWidgetState();
}

class _MyAnimatedWidgetState extends State<MyAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(...);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Animation logic
        },
      ),
    );
  }
}
```

## File Naming Conventions

- **Screens**: `*_screen.dart` (e.g., `home_screen.dart`)
- **Widgets**: `*_widget.dart` or descriptive name (e.g., `capsule_card.dart`)
- **Models**: `models.dart` (single file with all models)
- **Providers**: `providers.dart` (single file with all providers)
- **Repositories**: `repositories.dart` (single file with all repositories)
- **Constants**: `app_constants.dart`
- **Exceptions**: `app_exceptions.dart`

## Import Organization

1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Local imports (core)
5. Local imports (features)

Example:
```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/features/home/home_screen.dart';
```

## Code Organization Within Files

1. Imports
2. Constants (if any)
3. Classes
   - Public classes first
   - Private classes after
4. Helper functions (if any)

## Best Practices

### File Size
- Keep files focused and under 500 lines when possible
- Split large files into smaller, focused modules

### Dependencies
- Minimize dependencies between features
- Use core layer for shared functionality
- Avoid circular dependencies

### Testing
- Keep business logic testable
- Separate UI from logic
- Use dependency injection (Riverpod)

## Next Steps

- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture
- Check [API_REFERENCE.md](./API_REFERENCE.md) for API details
- Read [QUICK_START.md](./QUICK_START.md) to get started

---

**Last Updated**: 2024

