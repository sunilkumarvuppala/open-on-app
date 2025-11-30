import 'dart:developer' as developer;

/// Centralized logging utility
/// Replaces print statements throughout the codebase
class Logger {
  Logger._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'OpenOn',
      level: 800, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'OpenOn',
      level: 700, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'OpenOn',
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'OpenOn',
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
}

