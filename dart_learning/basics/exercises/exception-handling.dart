import 'dart:async';

/// Base class for all custom exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? errorCode;

  AppException(this.message, {this.errorCode});

  @override
  String toString() {
    return '${runtimeType.toString()}: $message (Error Code: $errorCode)';
  }
}

/// Specific exception for network-related errors.
class NetworkException extends AppException {
  NetworkException(String message, {int? errorCode})
      : super(message, errorCode: errorCode);
}

/// Specific exception for database-related errors.
class DatabaseException extends AppException {
  DatabaseException(String message, {int? errorCode})
      : super(message, errorCode: errorCode);
}

/// A utility class for exception handling.
class ExceptionHandler {
  /// Handles exceptions with a custom callback.
  static void handle(
    void Function() action, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onFinally,
  }) {
    try {
      action();
    } catch (error, stackTrace) {
      if (onError != null) {
        onError(error, stackTrace);
      } else {
        _logError(error, stackTrace);
      }
    } finally {
      if (onFinally != null) {
        onFinally();
      }
    }
  }

  /// Handles asynchronous exceptions with a custom callback.
  static Future<void> handleAsync(
    Future<void> Function() action, {
    Future<void> Function(Object error, StackTrace stackTrace)? onError,
    Future<void> Function()? onFinally,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      if (onError != null) {
        await onError(error, stackTrace);
      } else {
        _logError(error, stackTrace);
      }
    } finally {
      if (onFinally != null) {
        await onFinally();
      }
    }
  }

  /// Logs the error and stack trace.
  static void _logError(Object error, StackTrace stackTrace) {
    print('Unhandled Exception: $error');
    print('Stack Trace: $stackTrace');
  }
}

/// A class demonstrating advanced exception handling patterns.
class ExceptionHandlingDemo {
  /// Simulates a synchronous operation that throws an exception.
  void simulateSyncError() {
    ExceptionHandler.handle(
      () {
        throw NetworkException('A network error occurred', errorCode: 1001);
      },
      onError: (error, stackTrace) {
        print('Caught Synchronous Error: $error');
      },
      onFinally: () {
        print('Synchronous operation completed.');
      },
    );
  }

  /// Simulates an asynchronous operation that throws an exception.
  Future<void> simulateAsyncError() async {
    await ExceptionHandler.handleAsync(
      () async {
        await Future.delayed(Duration(seconds: 1));
        throw DatabaseException('A database error occurred', errorCode: 2001);
      },
      onError: (error, stackTrace) async {
        print('Caught Asynchronous Error: $error');
      },
      onFinally: () async {
        print('Asynchronous operation completed.');
      },
    );
  }

  /// Demonstrates retry logic with exponential backoff.
  Future<void> retryWithBackoff({
    required Future<void> Function() operation,
    int retries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < retries) {
      try {
        await operation();
        return; // Exit if the operation succeeds.
      } catch (error) {
        attempt++;
        if (attempt >= retries) {
          print('Operation failed after $retries attempts: $error');
          rethrow;
        }
        print('Retrying operation (Attempt $attempt/$retries)...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff.
      }
    }
  }

  /// Demonstrates global error handling setup for Dart (non-Flutter).
  void setupGlobalErrorHandling() {
    runZonedGuarded(() {
      throw NetworkException('A critical error occurred');
    }, (error, stackTrace) {
      print('Unhandled Zone Error: $error');
      print('Stack Trace: $stackTrace');
    });
  }
}

/// Example usage of exception handling.
void main() async {
  final demo = ExceptionHandlingDemo();

  // Simulate a synchronous error.
  demo.simulateSyncError();

  // Simulate an asynchronous error.
  await demo.simulateAsyncError();

  // Retry logic with exponential backoff.
  await demo.retryWithBackoff(
    operation: () async {
      print('Attempting operation...');
      throw NetworkException('Transient network error');
    },
    retries: 3,
    initialDelay: Duration(seconds: 2),
  );

  // Setup global error handling.
  demo.setupGlobalErrorHandling();
}
