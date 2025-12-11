/// Base exception class for application errors
abstract class AppException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Exception thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when authorization fails
class AuthorizationException extends AppException {
  const AuthorizationException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when a network operation fails
class NetworkException extends AppException {
  const NetworkException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when a repository operation fails
class RepositoryException extends AppException {
  const RepositoryException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when a resource conflict occurs (e.g., email already registered)
class ConflictException extends AppException {
  const ConflictException(super.message, {super.originalError, super.stackTrace});
}

