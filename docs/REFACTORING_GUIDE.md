# Refactoring Guide

> **Note**: This guide covers refactoring patterns and best practices. For information about the 2025 refactoring, see [REFACTORING_2025.md](./REFACTORING_2025.md).

This document describes refactoring patterns and best practices to follow when making changes to the codebase.

## Table of Contents

1. [Overview](#overview)
2. [Constants Centralization](#constants-centralization)
3. [Error Handling System](#error-handling-system)
4. [Input Validation](#input-validation)
5. [Logging System](#logging-system)
6. [Repository Pattern](#repository-pattern)
7. [Code Quality Improvements](#code-quality-improvements)
8. [Security Enhancements](#security-enhancements)
9. [Refactoring Checklist](#refactoring-checklist)

## Overview

The codebase underwent extensive refactoring to achieve:

- ✅ **Production-ready code quality**
- ✅ **Comprehensive error handling**
- ✅ **Input validation and security**
- ✅ **Consistent code patterns**
- ✅ **Maintainable architecture**
- ✅ **Best practices compliance**

## Constants Centralization

### Problem

Magic numbers and hardcoded values scattered throughout the codebase made it difficult to maintain and update.

### Solution

Created `AppConstants` class in `core/constants/app_constants.dart` to centralize all constants.

### Categories

#### 1. UI Dimensions
```dart
static const double bottomNavHeight = 60.0;
static const double fabSize = 56.0;
static const double userAvatarSize = 48.0;
static const double createButtonHeight = 56.0;
```

#### 2. Animation Durations
```dart
static const Duration animationDurationShort = Duration(milliseconds: 200);
static const Duration magicDustAnimationDuration = Duration(seconds: 8);
static const Duration sparkleAnimationDuration = Duration(seconds: 3);
```

#### 3. Particle Counts
```dart
static const int magicDustParticleCount = 20;
static const int magicDustSparkleCount = 10;
```

#### 4. Validation Limits
```dart
static const int maxContentLength = 10000;
static const int maxTitleLength = 200;
static const int minPasswordLength = 8;
```

#### 5. Thresholds
```dart
static const int unlockingSoonDaysThreshold = 7;
```

### Usage

**Before**:
```dart
Container(height: 56)
Duration(milliseconds: 200)
if (days <= 7) { ... }
```

**After**:
```dart
Container(height: AppConstants.createButtonHeight)
AppConstants.animationDurationShort
if (days <= AppConstants.unlockingSoonDaysThreshold) { ... }
```

### Benefits

- Single source of truth
- Easy to update values
- Better maintainability
- Self-documenting code

## Error Handling System

### Problem

Inconsistent error handling, no custom exceptions, and poor error messages.

### Solution

Created comprehensive error handling system with custom exceptions.

### Exception Hierarchy

```
AppException (base)
├── NotFoundException
├── ValidationException
├── AuthenticationException
└── NetworkException
```

### Implementation

**File**: `core/errors/app_exceptions.dart`

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});
}

class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}
```

### Usage Pattern

```dart
try {
  final capsule = await repository.getCapsule(id);
  if (capsule == null) {
    throw NotFoundException('Capsule not found: $id');
  }
  return capsule;
} on NotFoundException catch (e) {
  Logger.error('Capsule not found', error: e);
  // Handle error
} on NetworkException catch (e) {
  Logger.error('Network error', error: e);
  // Handle error
} catch (e) {
  Logger.error('Unexpected error', error: e);
  throw AppException('An unexpected error occurred');
}
```

### Benefits

- Consistent error handling
- Better error messages
- Easier debugging
- Type-safe error handling

## Input Validation

### Problem

No input validation, potential security issues, and poor user experience.

### Solution

Created validation utilities in `core/utils/validation.dart`.

### Validation Functions

```dart
class Validation {
  static bool isValidEmail(String email) { ... }
  static bool isValidPassword(String password) { ... }
  static String sanitizeString(String input) { ... }
  static bool isWithinLength(String input, int maxLength) { ... }
}
```

### Usage

```dart
// Email validation
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}

// Password validation
if (!Validation.isValidPassword(password)) {
  throw ValidationException('Password must be at least 8 characters');
}

// String sanitization
final sanitized = Validation.sanitizeString(userInput);
```

### Validation Rules

- **Email**: Valid email format, max 254 characters
- **Password**: 8-128 characters
- **Name**: Max 100 characters, sanitized
- **Content**: Max 10,000 characters
- **Title**: Max 200 characters

### Benefits

- Security improvements
- Better user experience
- Consistent validation
- Prevents invalid data

## Logging System

### Problem

`print()` statements scattered throughout code, no centralized logging, and no log levels.

### Solution

Created centralized logging system in `core/utils/logger.dart`.

### Implementation

Use `Logger` from `core/utils/logger.dart` instead of `print()` statements.

### Log Levels

- **Debug**: Development debugging
- **Info**: General information
- **Warning**: Warning messages
- **Error**: Error messages with stack traces

### Benefits

- Centralized logging
- Log levels
- Better debugging
- Production-ready

## Repository Pattern

### Problem

Duplicate repository code, inconsistent error handling, and no input validation.

### Solution

Refactored repositories with proper error handling and validation.

### Improvements

1. **Error Handling**: All methods use try-catch with custom exceptions
2. **Input Validation**: Validate all inputs before processing
3. **Logging**: Use Logger instead of print
4. **Constants**: Use AppConstants (frontend) or settings (backend) for thresholds
5. **Consistency**: Unified error handling patterns

> **See [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for error handling patterns**

## Code Quality Improvements

### 1. Removed Duplicate Code

- Consolidated duplicate repository files
- Unified error handling patterns
- Standardized validation logic

### 2. Consistent Naming

- Followed Dart naming conventions
- Consistent file naming
- Clear, descriptive names

### 3. Proper Documentation

- Converted TODOs to proper feature documentation
- Added inline comments where needed
- Clear code structure

### 4. Const Constructors

- Used const constructors where possible
- Improved performance
- Better widget tree optimization

### 5. Proper Imports

- Organized imports
- Removed unused imports
- Consistent import ordering

## Security Enhancements

### 1. Input Sanitization

All user inputs are sanitized before processing:

```dart
final sanitized = Validation.sanitizeString(userInput);
```

### 2. Input Validation

All inputs are validated before use:

```dart
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email');
}
```

### 3. Error Message Security

Error messages don't expose sensitive information:

```dart
// ❌ Bad
throw Exception('User ${userId} with password ${password} failed');

// ✅ Good
throw AuthenticationException('Invalid credentials');
```

### 4. Removed Print Statements

All `print()` statements removed and replaced with Logger:

```dart
// ❌ Bad
print('User data: $userData');

// ✅ Good
Logger.debug('User data retrieved');
```

## Refactoring Checklist

When refactoring code, ensure:

- [ ] All constants are in `AppConstants`
- [ ] Error handling uses custom exceptions
- [ ] Input validation is implemented
- [ ] Logger is used instead of print
- [ ] Repositories have proper error handling
- [ ] No duplicate code
- [ ] Proper documentation
- [ ] Security best practices followed
- [ ] Performance optimizations applied
- [ ] Code follows Dart conventions

## Migration Guide

### Updating Constants

1. Find magic number in code
2. Add constant to `AppConstants`
3. Replace usage with constant
4. Test thoroughly

### Adding Error Handling

1. Identify operation that can fail
2. Wrap in try-catch
3. Use appropriate custom exception
4. Log error with Logger
5. Handle error in UI

### Adding Validation

1. Identify user input
2. Add validation function if needed
3. Validate before processing
4. Throw ValidationException on failure
5. Show user-friendly error message

## Best Practices

### 1. Constants

✅ **DO**:
- Use `AppConstants` for all magic numbers
- Group related constants
- Use descriptive names

❌ **DON'T**:
- Use magic numbers in code
- Duplicate constant values
- Use unclear names

### 2. Error Handling

✅ **DO**:
- Use custom exceptions
- Handle errors properly
- Log errors with Logger
- Provide user-friendly messages

❌ **DON'T**:
- Ignore errors
- Use generic Exception
- Expose sensitive information
- Use print for errors

### 3. Validation

✅ **DO**:
- Validate all inputs
- Sanitize user input
- Use Validation utilities
- Show clear error messages

❌ **DON'T**:
- Trust user input
- Skip validation
- Expose validation details
- Use inconsistent validation

## Next Steps

- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for architecture
- Check [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md) for performance
- Read [API_REFERENCE.md](./API_REFERENCE.md) for API details

---

**Last Updated**: 2025

