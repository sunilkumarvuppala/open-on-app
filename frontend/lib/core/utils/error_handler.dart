/// Centralized error handling utilities
/// Provides consistent error message extraction and formatting
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/utils/logger.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Extract user-friendly error message from exception
  /// Handles all exception types and provides consistent error messages
  static String getErrorMessage(
    dynamic error, {
    String? defaultMessage,
  }) {
    // Handle specific exception types first
    if (error is ValidationException) {
      return _cleanErrorMessage(error.message);
    }
    if (error is AuthenticationException) {
      return _cleanErrorMessage(error.message);
    }
    if (error is NetworkException) {
      return _cleanErrorMessage(error.message);
    }
    if (error is NotFoundException) {
      return _cleanErrorMessage(error.message);
    }
    if (error is RepositoryException) {
      return _cleanErrorMessage(error.message);
    }
    if (error is ConflictException) {
      // Provide user-friendly message for email already registered
      if (error.message.contains('Email already registered') || 
          (error.message.toLowerCase().contains('email') && 
           error.message.toLowerCase().contains('already'))) {
        return 'This email is already registered. Please use a different email or log in.';
      }
      // Provide user-friendly message for username already taken
      if (error.message.contains('Username is already taken') || 
          (error.message.toLowerCase().contains('username') && 
           error.message.toLowerCase().contains('already'))) {
        return 'This username is already taken. Please choose a different username.';
      }
      return _cleanErrorMessage(error.message);
    }
    if (error is AppException) {
      return _cleanErrorMessage(error.message);
    }

    // Try to extract meaningful message from string representation
    final errorStr = error.toString();

    // Check for common error patterns
    if (errorStr.contains('Email already registered')) {
      return 'This email is already registered. Please use a different email or log in.';
    }
    if (errorStr.contains('Username already taken')) {
      return 'This username is already taken. Please choose a different username.';
    }
    if (_isNetworkError(errorStr)) {
      return 'Network error. Please check your internet connection and ensure the backend server is running at ${ApiConfig.baseUrl}.';
    }

    // Try to extract from structured error messages
    final extracted = _extractFromStructuredError(errorStr);
    if (extracted != null) {
      return extracted;
    }

    // Log unexpected errors for debugging
    Logger.error('Unexpected error format', error: error);

    // Return default or generic message
    return defaultMessage ?? 'An unexpected error occurred. Please try again.';
  }

  /// Check if error string indicates a network error
  static bool _isNetworkError(String errorStr) {
    final networkKeywords = [
      'Network',
      'Connection',
      'Failed host lookup',
      'SocketException',
      'Connection refused',
      'Timeout',
      'No Internet',
    ];
    return networkKeywords.any((keyword) => errorStr.contains(keyword));
  }

  /// Extract error message from structured error strings
  static String? _extractFromStructuredError(String errorStr) {
    // Try ValidationException format
    if (errorStr.contains('ValidationException:')) {
      return _cleanErrorMessage(errorStr.split('ValidationException:').last.trim());
    }

    // Try AuthenticationException format
    if (errorStr.contains('AuthenticationException:')) {
      return _cleanErrorMessage(errorStr.split('AuthenticationException:').last.trim());
    }

    // Try detail: format (common in API responses)
    if (errorStr.contains('detail:')) {
      var detail = errorStr.split('detail:').last.trim();
      // Remove quotes if present
      if (detail.startsWith('"') || detail.startsWith("'")) {
        detail = detail.substring(1);
      }
      if (detail.endsWith('"') || detail.endsWith("'")) {
        detail = detail.substring(0, detail.length - 1);
      }
      if (detail.isNotEmpty && detail.length < 200) {
        return _cleanErrorMessage(detail);
      }
    }

    // Try message: format
    if (errorStr.contains('message:')) {
      var message = errorStr.split('message:').last.trim();
      if (message.startsWith('"') || message.startsWith("'")) {
        message = message.substring(1);
      }
      if (message.endsWith('"') || message.endsWith("'")) {
        message = message.substring(0, message.length - 1);
      }
      if (message.isNotEmpty && message.length < 200) {
        return _cleanErrorMessage(message);
      }
    }

    // Try error: format
    if (errorStr.contains('error:')) {
      var errorMsg = errorStr.split('error:').last.trim();
      if (errorMsg.startsWith('"') || errorMsg.startsWith("'")) {
        errorMsg = errorMsg.substring(1);
      }
      if (errorMsg.endsWith('"') || errorMsg.endsWith("'")) {
        errorMsg = errorMsg.substring(0, errorMsg.length - 1);
      }
      if (errorMsg.isNotEmpty && errorMsg.length < 200) {
        return _cleanErrorMessage(errorMsg);
      }
    }

    return null;
  }

  /// Clean error message to make it user-friendly
  /// Removes HTTP codes, technical details, and error codes
  static String _cleanErrorMessage(String message) {
    if (message.isEmpty) {
      return 'An error occurred. Please try again.';
    }

    // Remove HTTP status codes (e.g., "HTTP 422", "400:", "422 Unprocessable Entity")
    message = message.replaceAll(RegExp(r'HTTP\s+\d+[:\s]*', caseSensitive: false), '');
    message = message.replaceAll(RegExp(r'\b\d{3}\s+(?:Bad Request|Unauthorized|Forbidden|Not Found|Conflict|Unprocessable Entity|Internal Server Error)\b', caseSensitive: false), '');
    message = message.replaceAll(RegExp(r'\b\d{3}:\s*', caseSensitive: false), '');

    // Remove common technical prefixes
    message = message.replaceAll(RegExp(r'^(Error|Exception|Failed|Invalid):\s*', caseSensitive: false), '');

    // Remove file paths and line numbers
    message = message.replaceAll(RegExp(r'\([^)]*\.dart[^)]*\)', caseSensitive: false), '');
    message = message.replaceAll(RegExp(r'at\s+[^\s]+\s+line\s+\d+', caseSensitive: false), '');

    // Clean up whitespace
    message = message.trim();
    message = message.replaceAll(RegExp(r'\s+'), ' ');

    // Capitalize first letter
    if (message.isNotEmpty) {
      message = message[0].toUpperCase() + (message.length > 1 ? message.substring(1) : '');
    }

    // If message is empty or too short, provide a generic one
    if (message.isEmpty || message.length < 3) {
      return 'An error occurred. Please check your input and try again.';
    }

    return message;
  }

  /// Get default error message for common operations
  static String getDefaultErrorMessage(String operation) {
    return 'Failed to $operation. Please try again.';
  }
}

