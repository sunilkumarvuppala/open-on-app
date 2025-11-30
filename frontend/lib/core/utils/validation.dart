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
}

