# OpenOn Architecture Documentation

## Overview

OpenOn follows a **clean, feature-first architecture** with clear separation of concerns and a focus on maintainability and testability.

## Core Principles

1. **Separation of Concerns**: UI, business logic, and data layers are clearly separated
2. **Dependency Injection**: Using Riverpod providers for dependency management
3. **Single Responsibility**: Each class/widget has one clear purpose
4. **Testability**: Pure functions and dependency injection enable easy testing
5. **Scalability**: Feature-first structure allows easy addition of new features

## Layer Architecture

```
┌─────────────────────────────────────┐
│        Presentation Layer           │
│  (Screens, Widgets, ViewModels)     │
├─────────────────────────────────────┤
│         Business Logic              │
│   (Providers, State Management)     │
├─────────────────────────────────────┤
│          Data Layer                 │
│  (Repositories, Models, APIs)       │
└─────────────────────────────────────┘
```

## Directory Structure Explained

### `/lib/core/`
**Shared application infrastructure**

- `theme/` - Design system (colors, typography, theme)
- `models/` - Domain models (Capsule, User, Recipient, etc.)
- `data/` - Repository interfaces and implementations
- `providers/` - Riverpod providers for state management
- `router/` - Navigation configuration

### `/lib/features/`
**Feature modules** - Each feature is self-contained

Each feature follows this structure:
```
feature_name/
├── screens/         # Full-screen views
├── widgets/         # Reusable components specific to this feature
└── providers/       # Feature-specific providers (optional)
```

### Current Features

1. **auth** - Authentication (login, signup, welcome)
2. **home** - Dashboard, capsule lists
3. **recipients** - Recipient CRUD operations
4. **create_capsule** - Multi-step capsule creation
5. **capsule** - Capsule viewing, animations
6. **profile** - User profile, settings

## State Management Strategy

### Provider Types

**1. Repository Providers**
```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository(); // Replace with real implementation
});
```

**2. Data Providers**
```dart
final capsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final repo = ref.watch(capsuleRepositoryProvider);
  return repo.getCapsules(userId: userId);
});
```

**3. Computed Providers**
```dart
final upcomingCapsulesProvider = Provider.family<List<Capsule>, String>((ref, userId) {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  return capsulesAsync.when(
    data: (capsules) => capsules.where((c) => c.status == CapsuleStatus.locked).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
```

**4. State Notifiers**
```dart
class DraftCapsuleNotifier extends StateNotifier<DraftCapsule> {
  DraftCapsuleNotifier() : super(const DraftCapsule());
  
  void setRecipient(Recipient recipient) {
    state = state.copyWith(recipient: recipient);
  }
}
```

### When to Use Each

- **Provider**: For dependencies and computed values
- **FutureProvider**: For async data fetching
- **StreamProvider**: For real-time data streams
- **StateNotifierProvider**: For mutable state with methods

## Navigation Architecture

### Route Organization

Routes defined in `app_router.dart` with:
- Type-safe route parameters
- Auth-aware redirects
- Deep linking support

### Navigation Flow

```
Welcome Screen
    ↓
Login/Signup
    ↓
Home Dashboard ←→ Create Capsule → Preview → Confirm
    ↓                                              ↓
Recipients Screen                          (Save to DB)
    ↓
Profile/Settings
```

### Passing Data Between Screens

**Method 1: Route Parameters**
```dart
context.push('/capsule/:id', extra: capsule);
```

**Method 2: Shared State (Providers)**
```dart
// Write
ref.read(draftCapsuleProvider.notifier).setRecipient(recipient);

// Read
final draft = ref.watch(draftCapsuleProvider);
```

## Data Flow

### Creating a Capsule

```
1. User Input (UI Layer)
   └→ StepChooseRecipient updates draft state
   └→ StepWriteLetter updates draft state
   └→ StepChooseTime updates draft state
   └→ StepPreview shows summary

2. Validation (Business Logic)
   └→ DraftCapsule.isValid checks all required fields

3. Persistence (Data Layer)
   └→ CapsuleRepository.createCapsule()
   └→ Mock: Adds to in-memory list
   └→ Real: POSTs to backend API

4. State Update (Presentation Layer)
   └→ ref.invalidate(capsulesProvider)
   └→ UI automatically rebuilds with new data
```

### Opening a Capsule

```
1. User taps locked capsule
   └→ Checks if can open (time >= unlock time)

2. Opening Animation
   └→ Sequence of animations
   └→ Marks capsule as opened
   └→ Sends notification to sender (TODO)

3. Display Opened Letter
   └→ Shows content, photo
   └→ Reaction bar appears

4. User reacts
   └→ Saves reaction to capsule
   └→ Sends notification to sender (TODO)
```

## Model Design

### Capsule Model

```dart
class Capsule {
  // Identity
  final String id;
  final String senderId;
  final String receiverId;
  
  // Content
  final String label;
  final String content;
  final String? photoUrl;
  
  // Timing
  final DateTime unlockAt;
  final DateTime createdAt;
  final DateTime? openedAt;
  
  // Computed properties
  CapsuleStatus get status { /* ... */ }
  bool get isLocked { /* ... */ }
  String get countdownText { /* ... */ }
}
```

**Key Design Decisions:**
- Immutable (final fields)
- Computed properties for derived state
- `copyWith` for updates
- Nullable fields where appropriate

## Testing Strategy

### Unit Tests
- Model validation logic
- Countdown calculations
- Status determination

### Widget Tests
- Individual widgets render correctly
- User interactions work as expected
- Error states display properly

### Integration Tests
- Complete user flows
- Navigation between screens
- State persistence

## Performance Optimizations

### List Performance
- Use `ListView.builder` for large lists
- Implement pagination if needed
- Cache network images

### State Management
- Use `.family` modifiers for parameterized providers
- Strategic use of `ref.invalidate()` vs `ref.refresh()`
- Avoid unnecessary rebuilds with `select`

### Animation Performance
- Target 60fps on mid-range devices
- Provide skip options for accessibility
- Use `const` constructors where possible

## Security Considerations

### Data Protection
- No PII in logs
- Sensitive data only in secure storage
- Input validation on all forms

### API Security
- No hardcoded API keys
- Use environment variables
- Implement rate limiting (backend)

## Extension Points

### Adding a New Feature

1. Create feature directory: `lib/features/new_feature/`
2. Add screens: `screens/feature_screen.dart`
3. Add widgets: `widgets/` (if needed)
4. Add providers: Update `core/providers/providers.dart`
5. Add routes: Update `core/router/app_router.dart`
6. Add navigation: Link from existing screens

### Adding a New Data Source

1. Define repository interface in `core/data/`
2. Create implementation (mock or real)
3. Provide via Riverpod provider
4. Use in relevant features

### Backend Integration Checklist

- [ ] Replace mock repositories with real implementations
- [ ] Add API client (e.g., Dio, http)
- [ ] Implement error handling and retry logic
- [ ] Add authentication token management
- [ ] Implement push notifications
- [ ] Add analytics tracking
- [ ] Set up crash reporting

## Common Patterns

### Loading States

```dart
final dataAsync = ref.watch(someProvider);

return dataAsync.when(
  data: (data) => /* Success UI */,
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

### Error Handling

```dart
try {
  await someAsyncOperation();
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Success')),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Form Validation

```dart
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Required field';
    }
    if (value.length < 2) {
      return 'Minimum 2 characters';
    }
    return null; // Valid
  },
)
```

## Future Enhancements

### Planned Features
- [ ] Capsule templates
- [ ] Video attachments
- [ ] Voice notes
- [ ] Recurring capsules
- [ ] Group letters
- [ ] Advanced sharing (story format)

### Technical Improvements
- [ ] Offline support with local database
- [ ] Real-time sync
- [ ] Advanced animations with Rive
- [ ] Internationalization (i18n)
- [ ] Dark mode
- [ ] Accessibility improvements (screen reader support)

## Troubleshooting

### Common Issues

**Issue**: Provider not found
- **Solution**: Ensure provider is defined and app is wrapped in `ProviderScope`

**Issue**: State not updating
- **Solution**: Check if using `ref.watch()` vs `ref.read()` correctly

**Issue**: Navigation not working
- **Solution**: Verify route is defined in `app_router.dart`

**Issue**: Images not displaying
- **Solution**: Check asset paths in `pubspec.yaml`

## Resources

- [Riverpod Documentation](https://riverpod.dev)
- [go_router Documentation](https://pub.dev/packages/go_router)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)

---

**Last Updated**: 2024
**Architecture Version**: 1.0
