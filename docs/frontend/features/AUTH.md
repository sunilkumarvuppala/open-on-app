# Authentication Feature

## Overview

The Authentication feature handles user onboarding, login, and registration flows. It provides a smooth entry point for users to access the OpenOn app.

## Purpose

- Welcome new users with an onboarding experience
- Authenticate existing users
- Register new users
- Manage authentication state

## File Structure

```
features/auth/
├── welcome_screen.dart    # Welcome/onboarding screen
├── login_screen.dart      # User login screen
└── signup_screen.dart     # User registration screen
```

## Components

### WelcomeScreen

**File**: `welcome_screen.dart`

**Purpose**: First screen users see when opening the app. Provides onboarding experience.

**Key Features**:
- Welcome message and app introduction
- Navigation to login or signup
- Beautiful UI with theme support

**Navigation**:
- Routes to `Routes.login` or `Routes.signup`

**Usage**:
```dart
GoRoute(
  path: Routes.welcome,
  builder: (context, state) => const WelcomeScreen(),
)
```

### LoginScreen

**File**: `login_screen.dart`

**Purpose**: Authenticate existing users.

**Key Features**:
- Email and password input
- Input validation
- Error handling
- Navigation to home on success
- Link to signup screen

**User Flow**:
1. User enters email and password
2. Validation checks input format
3. Authentication attempt
4. On success: Navigate to home
5. On failure: Show error message

**Validation**:
- Email format validation
- Password length validation
- Uses `Validation.isValidEmail()`

**Error Handling**:
- `AuthenticationException` for invalid credentials
- `ValidationException` for invalid input
- Network errors handled gracefully

**Usage**:
```dart
GoRoute(
  path: Routes.login,
  builder: (context, state) => const LoginScreen(),
)
```

### SignupScreen

**File**: `signup_screen.dart`

**Purpose**: Register new users.

**Key Features**:
- User registration form
- Name, email, password inputs
- Input validation
- Error handling
- Navigation to home on success
- Link to login screen

**User Flow**:
1. User enters name, email, and password
2. Validation checks all inputs
3. Registration attempt
4. On success: Navigate to home
5. On failure: Show error message

**Validation**:
- Name: Required, max length
- Email: Valid format, max length
- Password: Min 8 characters, max 128 characters

**Error Handling**:
- `ValidationException` for invalid input
- `AuthenticationException` for registration failures
- Network errors handled

**Usage**:
```dart
GoRoute(
  path: Routes.signup,
  builder: (context, state) => const SignupScreen(),
)
```

## Integration Points

### Providers Used

- `currentUserProvider`: Current authenticated user
- `isAuthenticatedProvider`: Authentication status

### Routes

- `/` - Welcome screen
- `/login` - Login screen
- `/signup` - Signup screen

### Navigation

All auth screens use `context.push()` for navigation:
```dart
context.push(Routes.login);
context.push(Routes.signup);
// After successful auth, redirects automatically to Routes.receiverHome (Inbox)
```

## State Management

### Authentication State

Managed through Riverpod providers:
```dart
final currentUserProvider = FutureProvider<User?>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getCurrentUser();
});
```

### Route Guards

Authentication guards in `app_router.dart`:
```dart
redirect: (context, state) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  if (!isAuthenticated && state.matchedLocation != Routes.login) {
    return Routes.welcome;
  }
  return null;
}
```

## Best Practices

### Input Validation

✅ **DO**:
- Validate all inputs before submission
- Show clear error messages
- Use `Validation` utilities

```dart
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}
```

### Error Handling

✅ **DO**:
- Handle authentication errors gracefully
- Show user-friendly error messages
- Log errors with `Logger`

```dart
try {
  await authenticate(email, password);
} on AuthenticationException catch (e) {
  Logger.error('Authentication failed', error: e);
  // Show error to user
}
```

### Security

✅ **DO**:
- Never log passwords
- Sanitize user input
- Use secure authentication methods
- Validate on both client and server

## Future Enhancements

- [ ] Forgot password flow
- [ ] Social authentication (Google, Apple)
- [ ] Email verification
- [ ] Biometric authentication
- [ ] Remember me functionality

## Related Documentation

- [API Reference](../API_REFERENCE.md) - For provider and repository APIs
- [Architecture](../../ARCHITECTURE.md) - For overall architecture
- [Navigation Feature](./NAVIGATION.md) - For navigation patterns

---

**Last Updated**: 2025

