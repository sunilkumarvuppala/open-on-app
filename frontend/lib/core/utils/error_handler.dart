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
      return error.message;
    }
    if (error is AuthenticationException) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    if (error is NotFoundException) {
      return error.message;
    }
    if (error is RepositoryException) {
      return error.message;
    }
    if (error is AppException) {
      return error.message;
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
      return errorStr.split('ValidationException:').last.trim();
    }

    // Try AuthenticationException format
    if (errorStr.contains('AuthenticationException:')) {
      return errorStr.split('AuthenticationException:').last.trim();
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
        return detail;
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
        return message;
      }
    }

    // Try error: format
    if (errorStr.contains('error:')) {
      var error = errorStr.split('error:').last.trim();
      if (error.startsWith('"') || error.startsWith("'")) {
        error = error.substring(1);
      }
      if (error.endsWith('"') || error.endsWith("'")) {
        error = error.substring(0, error.length - 1);
      }
      if (error.isNotEmpty && error.length < 200) {
        return error;
      }
    }

    return null;
  }

  /// Get default error message for common operations
  static String getDefaultErrorMessage(String operation) {
    return 'Failed to $operation. Please try again.';
  }
}

