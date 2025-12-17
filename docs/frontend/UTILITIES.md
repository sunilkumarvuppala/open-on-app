# Frontend Utilities

This document describes the utility classes and functions available in the frontend codebase.

## UUID Utilities (`core/utils/uuid_utils.dart`)

### Purpose
Provides consistent UUID validation and type-safe UUID handling across the application.

### Key Methods

#### `isValidUuid(String? id) -> bool`
Validates that a string is a valid UUID v4 format.

```dart
if (UuidUtils.isValidUuid(recipientId)) {
  // Valid UUID
}
```

#### `validateUuid(String id, {String fieldName = 'ID'}) -> String`
Validates and returns a UUID string, throwing `ValidationException` if invalid.

```dart
try {
  final uuid = UuidUtils.validateUuid(id, fieldName: 'Recipient ID');
} on ValidationException catch (e) {
  // Handle invalid UUID
}
```

#### Type-Specific Validators
- `validateRecipientId(String recipientId) -> String`
- `validateUserId(String userId) -> String`
- `validateCapsuleId(String capsuleId) -> String`
- `validateDraftId(String draftId) -> String`

#### `looksLikeUuid(String? id) -> bool`
Quick format check (basic validation, use `isValidUuid` for proper validation).

### Usage Example

```dart
import 'package:openon_app/core/utils/uuid_utils.dart';

// Validate before use
final recipientId = UuidUtils.validateRecipientId(capsule.receiverId);

// Check if valid
if (UuidUtils.isValidUuid(someId)) {
  // Proceed with valid UUID
}
```

### Best Practices
- ✅ Always use `UuidUtils.validate*()` methods before sending IDs to backend
- ✅ Use type-specific validators (`validateRecipientId`, `validateUserId`, etc.)
- ✅ Don't use string length checks (`id.length == 36`) - use proper validation
- ✅ Handle `ValidationException` when validation fails

---

## Recipient Resolver (`core/data/recipient_resolver.dart`)

### Purpose
Centralized utility for resolving recipient UUIDs from various sources. Handles UUID validation, lookup by ID or `linkedUserId`, and fallback to name matching.

### Key Method

#### `resolveRecipientId({...}) -> Future<String>`
Resolves the correct recipient UUID from the provided recipient ID.

**Parameters**:
- `recipientId` (String): The recipient ID to resolve (may be UUID, linkedUserId, or invalid)
- `currentUserId` (String): Current user's ID for fetching recipients list
- `recipientRepo` (RecipientRepository): Repository for fetching recipients
- `recipientName` (String?, optional): Recipient name for fallback matching

**Returns**: Validated recipient UUID (String)

**Throws**: `RepositoryException` if recipient cannot be found

### Resolution Strategy

1. **UUID Format Validation**: Checks if `recipientId` is a valid UUID format
2. **Recipients List Lookup**: Fetches recipients list for current user
3. **Primary Lookup**: Tries to find recipient by:
   - Exact ID match (`r.id == recipientId`)
   - Linked user ID match (`r.linkedUserId == recipientId`)
4. **Fallback Lookup**: If not found by ID, tries name matching (case-insensitive)
5. **Validation**: Validates resolved ID is a proper UUID
6. **Error Handling**: Throws clear error if recipient not found

### Usage Example

```dart
import 'package:openon_app/core/data/recipient_resolver.dart';

// In createCapsule method
final recipientId = await RecipientResolver.resolveRecipientId(
  recipientId: capsule.receiverId,
  currentUserId: currentUser.id,
  recipientRepo: recipientRepo,
  recipientName: capsule.receiverName,
);

// recipientId is now a validated UUID ready for backend
```

### Benefits
- ✅ Single source of truth for recipient resolution
- ✅ Handles all edge cases (stale IDs, name matching, etc.)
- ✅ Proper UUID validation
- ✅ Clear error messages
- ✅ No duplicate code

---

## Validation Utilities (`core/utils/validation.dart`)

### Purpose
Input validation utilities for forms and user input.

### Key Methods

- `validateEmail(String email) -> void`
- `validatePassword(String password) -> void`
- `validateName(String name) -> void`
- `validateContent(String content) -> void`
- `validateLabel(String label) -> void`
- `validateUnlockDate(DateTime date) -> void`
- `isValidUUID(String id) -> bool`

### Usage

```dart
import 'package:openon_app/core/utils/validation.dart';

try {
  Validation.validateEmail(email);
  Validation.validatePassword(password);
} on ValidationException catch (e) {
  // Handle validation error
}
```

---

## Logger (`core/utils/logger.dart`)

### Purpose
Centralized logging system using Dart's `developer.log`.

### Log Levels

- `Logger.debug()` - Debug information (level 800)
- `Logger.info()` - Informational messages (level 700)
- `Logger.warning()` - Warning messages (level 900)
- `Logger.error()` - Error messages (level 1000)

### Usage

```dart
import 'package:openon_app/core/utils/logger.dart';

Logger.info('User signed in: $email');
Logger.warning('Network request slow', error: e);
Logger.error('Failed to create capsule', error: e, stackTrace: stackTrace);
```

### Best Practices
- ✅ Use appropriate log levels
- ✅ Include error and stackTrace for errors
- ✅ Don't log sensitive information (passwords, tokens)
- ✅ Use structured messages for easier searching
- ❌ Don't use `print()` - use `Logger` instead

---

## Best Practices Summary

### UUID Handling
- ✅ Always validate UUIDs using `UuidUtils`
- ✅ Use type-specific validators (`validateRecipientId`, etc.)
- ✅ Use `RecipientResolver` for recipient UUID resolution
- ❌ Don't use string length checks for UUID validation
- ❌ Don't manually construct UUIDs

### Error Handling
- ✅ Use specific exception types (`ValidationException`, `RepositoryException`)
- ✅ Provide clear error messages
- ✅ Log errors with context
- ✅ Handle errors at appropriate levels

### Code Organization
- ✅ Use utilities for common operations
- ✅ Keep business logic in services/resolvers
- ✅ Separate concerns (validation, resolution, API calls)
- ✅ Follow single responsibility principle

---

**Last Updated**: December 2025
