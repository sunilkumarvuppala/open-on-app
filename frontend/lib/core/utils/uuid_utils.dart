import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';

/// UUID utility functions for consistent UUID handling across the app
class UuidUtils {
  UuidUtils._();

  /// Validates that a string is a valid UUID v4 format
  /// Returns true if valid, false otherwise
  static bool isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    return Validation.isValidUUID(id);
  }

  /// Validates and returns a UUID string, throwing if invalid
  /// Throws ValidationException if the UUID is invalid
  static String validateUuid(String id, {String fieldName = 'ID'}) {
    if (!isValidUuid(id)) {
      throw ValidationException('Invalid $fieldName format: must be a valid UUID');
    }
    return id.trim();
  }

  /// Validates recipient ID (must be valid UUID)
  static String validateRecipientId(String recipientId) {
    return validateUuid(recipientId, fieldName: 'Recipient ID');
  }

  /// Validates user ID (must be valid UUID)
  static String validateUserId(String userId) {
    return validateUuid(userId, fieldName: 'User ID');
  }

  /// Validates capsule ID (must be valid UUID)
  static String validateCapsuleId(String capsuleId) {
    return validateUuid(capsuleId, fieldName: 'Capsule ID');
  }

  /// Validates draft ID (must be valid UUID)
  static String validateDraftId(String draftId) {
    return validateUuid(draftId, fieldName: 'Draft ID');
  }

  /// Checks if a string looks like a UUID (basic format check)
  /// This is a quick check, use isValidUuid for proper validation
  static bool looksLikeUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    return id.length == 36 && id.contains('-');
  }
}

