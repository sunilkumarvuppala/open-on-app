import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';

/// Input validation utilities
class Validation {
  Validation._();

  /// Validates email format
  static void validateEmail(String email) {
    if (email.isEmpty) {
      throw const ValidationException('Email cannot be empty');
    }
    if (email.length > AppConstants.maxEmailLength) {
      throw ValidationException(
        'Email must be at most ${AppConstants.maxEmailLength} characters',
      );
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      throw const ValidationException('Invalid email format');
    }
  }

  /// Validates password
  static void validatePassword(String password) {
    if (password.isEmpty) {
      throw const ValidationException('Password cannot be empty');
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw ValidationException(
        'Password must be at least ${AppConstants.minPasswordLength} characters',
      );
    }
    if (password.length > AppConstants.maxPasswordLength) {
      throw ValidationException(
        'Password must be at most ${AppConstants.maxPasswordLength} characters',
      );
    }
  }

  /// Validates name
  static void validateName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException('Name cannot be empty');
    }
    if (name.length > AppConstants.maxNameLength) {
      throw ValidationException(
        'Name must be at most ${AppConstants.maxNameLength} characters',
      );
    }
  }

  /// Validates capsule content
  static void validateContent(String content) {
    if (content.trim().isEmpty) {
      throw const ValidationException('Content cannot be empty');
    }
    if (content.length < AppConstants.minContentLength) {
      throw const ValidationException('Content is too short');
    }
    if (content.length > AppConstants.maxContentLength) {
      throw ValidationException(
        'Content must be at most ${AppConstants.maxContentLength} characters',
      );
    }
  }

  /// Validates capsule title/label
  static void validateLabel(String label) {
    if (label.trim().isEmpty) {
      throw const ValidationException('Label cannot be empty');
    }
    if (label.length > AppConstants.maxLabelLength) {
      throw ValidationException(
        'Label must be at most ${AppConstants.maxLabelLength} characters',
      );
    }
  }

  /// Validates recipient name
  static void validateRecipientName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException('Recipient name cannot be empty');
    }
    if (name.length > AppConstants.maxRecipientNameLength) {
      throw ValidationException(
        'Recipient name must be at most ${AppConstants.maxRecipientNameLength} characters',
      );
    }
  }

  /// Validates relationship
  static void validateRelationship(String relationship) {
    if (relationship.trim().isEmpty) {
      throw const ValidationException('Relationship cannot be empty');
    }
    if (relationship.length > AppConstants.maxRelationshipLength) {
      throw ValidationException(
        'Relationship must be at most ${AppConstants.maxRelationshipLength} characters',
      );
    }
  }

  /// Validates unlock date is in the future
  static void validateUnlockDate(DateTime unlockAt) {
    final now = DateTime.now();
    if (unlockAt.isBefore(now) || unlockAt.isAtSameMomentAs(now)) {
      throw const ValidationException('Unlock date must be in the future');
    }
  }

  /// Sanitizes string input (removes leading/trailing whitespace)
  static String sanitizeString(String input) {
    return input.trim();
  }

  /// Sanitizes email (lowercase, trim)
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Validates username format
  /// Rules: lowercase letters and numbers only, must start with a letter, 3-100 characters
  static void validateUsername(String username) {
    if (username.trim().isEmpty) {
      throw const ValidationException('Username cannot be empty');
    }
    if (username.length < AppConstants.minUsernameLength) {
      throw ValidationException(
        'Username must be at least ${AppConstants.minUsernameLength} characters',
      );
    }
    if (username.length > AppConstants.maxUsernameLength) {
      throw ValidationException(
        'Username must be at most ${AppConstants.maxUsernameLength} characters',
      );
    }
    // Only lowercase letters and numbers, must start with a letter
    final usernameRegex = RegExp(r'^[a-z][a-z0-9]*$');
    if (!usernameRegex.hasMatch(username)) {
      if (username.isEmpty) {
        throw const ValidationException('Username cannot be empty');
      }
      final firstChar = username[0];
      if (!RegExp(r'^[a-z]$').hasMatch(firstChar)) {
        throw const ValidationException('Username must start with a lowercase letter');
      }
      if (username != username.toLowerCase()) {
        throw const ValidationException('Username must contain only lowercase letters and numbers');
      }
      if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
        throw const ValidationException('Username can only contain lowercase letters and numbers');
      }
      throw const ValidationException('Username must start with a letter and contain only lowercase letters and numbers');
    }
  }

  /// Sanitizes username (lowercase, trim)
  static String sanitizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  /// Validates UUID format (for user IDs, connection IDs, etc.)
  /// Returns true if valid UUID format, false otherwise
  static bool isValidUUID(String id) {
    if (id.isEmpty) return false;
    // UUID v4 format: 8-4-4-4-12 hexadecimal characters
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  /// Validates and sanitizes connection ID
  /// Throws ValidationException if invalid
  static String validateConnectionId(String connectionId) {
    final sanitized = connectionId.trim();
    if (sanitized.isEmpty) {
      throw const ValidationException('Connection ID cannot be empty');
    }
    if (!isValidUUID(sanitized)) {
      throw const ValidationException('Invalid connection ID format');
    }
    return sanitized;
  }

  /// Validates and sanitizes user ID
  /// Throws ValidationException if invalid
  static String validateUserId(String userId) {
    final sanitized = userId.trim();
    if (sanitized.isEmpty) {
      throw const ValidationException('User ID cannot be empty');
    }
    if (!isValidUUID(sanitized)) {
      throw const ValidationException('Invalid user ID format');
    }
    return sanitized;
  }

  /// Sanitizes SharedPreferences key to prevent security issues
  /// Removes dangerous characters and limits length
  /// Keys should only contain alphanumeric characters, underscores, and hyphens
  static String sanitizeSharedPreferencesKey(String key) {
    if (key.isEmpty) {
      throw const ValidationException('SharedPreferences key cannot be empty');
    }
    // Remove any characters that could be dangerous in storage keys
    // Only allow alphanumeric, underscore, hyphen, and dot
    final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '');
    if (sanitized.isEmpty) {
      throw const ValidationException('SharedPreferences key contains only invalid characters');
    }
    // Limit key length to prevent abuse
    const maxKeyLength = 200;
    if (sanitized.length > maxKeyLength) {
      return sanitized.substring(0, maxKeyLength);
    }
    return sanitized;
  }

  /// Validates and sanitizes capsule/letter ID for use in SharedPreferences keys
  /// Ensures the ID is a valid UUID and sanitizes it for safe use in storage keys
  static String validateAndSanitizeCapsuleId(String capsuleId) {
    final sanitized = sanitizeString(capsuleId);
    if (sanitized.isEmpty) {
      throw const ValidationException('Capsule ID cannot be empty');
    }
    if (!isValidUUID(sanitized)) {
      throw const ValidationException('Invalid capsule ID format');
    }
    return sanitized;
  }
}

