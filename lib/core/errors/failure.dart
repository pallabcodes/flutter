import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Implements Equatable for proper comparison in tests
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic data;

  const Failure({
    required this.message,
    this.code,
    this.data,
  });

  @override
  List<Object?> get props => [message, code, data];

  @override
  String toString() {
    return 'Failure{message: $message, code: $code}';
  }
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory NetworkFailure.noInternet() {
    return const NetworkFailure(
      message: 'No internet connection available',
      code: 'NO_INTERNET',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Request timeout',
      code: 'TIMEOUT',
    );
  }

  factory NetworkFailure.serverError(int statusCode) {
    return NetworkFailure(
      message: 'Server error occurred',
      code: 'SERVER_ERROR',
      data: statusCode,
    );
  }
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory DatabaseFailure.connectionError() {
    return const DatabaseFailure(
      message: 'Database connection failed',
      code: 'DB_CONNECTION_ERROR',
    );
  }

  factory DatabaseFailure.insertError() {
    return const DatabaseFailure(
      message: 'Failed to insert data',
      code: 'DB_INSERT_ERROR',
    );
  }

  factory DatabaseFailure.queryError() {
    return const DatabaseFailure(
      message: 'Database query failed',
      code: 'DB_QUERY_ERROR',
    );
  }

  factory DatabaseFailure.notFound(String item) {
    return DatabaseFailure(
      message: '$item not found',
      code: 'DB_NOT_FOUND',
      data: item,
    );
  }
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Invalid email or password',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthFailure.userNotFound() {
    return const AuthFailure(
      message: 'User not found',
      code: 'USER_NOT_FOUND',
    );
  }

  factory AuthFailure.userDisabled() {
    return const AuthFailure(
      message: 'User account is disabled',
      code: 'USER_DISABLED',
    );
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Authentication token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }

  factory AuthFailure.unauthorized() {
    return const AuthFailure(
      message: 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory ValidationFailure.required(String field) {
    return ValidationFailure(
      message: '$field is required',
      code: 'REQUIRED_FIELD',
      data: field,
    );
  }

  factory ValidationFailure.invalidFormat(String field, String expectedFormat) {
    return ValidationFailure(
      message: '$field has invalid format. Expected: $expectedFormat',
      code: 'INVALID_FORMAT',
      data: {'field': field, 'expected': expectedFormat},
    );
  }

  factory ValidationFailure.outOfRange(String field, num min, num max) {
    return ValidationFailure(
      message: '$field must be between $min and $max',
      code: 'OUT_OF_RANGE',
      data: {'field': field, 'min': min, 'max': max},
    );
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory CacheFailure.readError() {
    return const CacheFailure(
      message: 'Failed to read from cache',
      code: 'CACHE_READ_ERROR',
    );
  }

  factory CacheFailure.writeError() {
    return const CacheFailure(
      message: 'Failed to write to cache',
      code: 'CACHE_WRITE_ERROR',
    );
  }

  factory CacheFailure.clearError() {
    return const CacheFailure(
      message: 'Failed to clear cache',
      code: 'CACHE_CLEAR_ERROR',
    );
  }
}

/// File system failures
class FileFailure extends Failure {
  const FileFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory FileFailure.notFound(String path) {
    return FileFailure(
      message: 'File not found: $path',
      code: 'FILE_NOT_FOUND',
      data: path,
    );
  }

  factory FileFailure.permissionDenied(String path) {
    return FileFailure(
      message: 'Permission denied: $path',
      code: 'PERMISSION_DENIED',
      data: path,
    );
  }

  factory FileFailure.readError(String path) {
    return FileFailure(
      message: 'Failed to read file: $path',
      code: 'FILE_READ_ERROR',
      data: path,
    );
  }

  factory FileFailure.writeError(String path) {
    return FileFailure(
      message: 'Failed to write file: $path',
      code: 'FILE_WRITE_ERROR',
      data: path,
    );
  }
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory PermissionFailure.cameraDenied() {
    return const PermissionFailure(
      message: 'Camera permission is required for receipt scanning',
      code: 'CAMERA_DENIED',
    );
  }

  factory PermissionFailure.storageDenied() {
    return const PermissionFailure(
      message: 'Storage permission is required for file operations',
      code: 'STORAGE_DENIED',
    );
  }

  factory PermissionFailure.locationDenied() {
    return const PermissionFailure(
      message: 'Location permission is required for location-based features',
      code: 'LOCATION_DENIED',
    );
  }
}

/// Sync-related failures
class SyncFailure extends Failure {
  const SyncFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory SyncFailure.conflict(String itemId) {
    return SyncFailure(
      message: 'Sync conflict detected for item: $itemId',
      code: 'SYNC_CONFLICT',
      data: itemId,
    );
  }

  factory SyncFailure.networkUnavailable() {
    return const SyncFailure(
      message: 'Cannot sync while offline',
      code: 'SYNC_OFFLINE',
    );
  }

  factory SyncFailure.serverUnavailable() {
    return const SyncFailure(
      message: 'Sync server is currently unavailable',
      code: 'SYNC_SERVER_UNAVAILABLE',
    );
  }
}

/// Unexpected failures for unhandled errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required String message,
    String? code,
    dynamic data,
  }) : super(message: message, code: code, data: data);

  factory UnexpectedFailure.unknown() {
    return const UnexpectedFailure(
      message: 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }

  factory UnexpectedFailure.withMessage(String message) {
    return UnexpectedFailure(
      message: message,
      code: 'UNEXPECTED_ERROR',
    );
  }
}
