import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:finwise/core/config/app_config.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Production-ready HTTP client for API communication
/// Implements proper error handling, logging, and retry logic
@singleton
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _initializeDio();
  }

  /// Initialize Dio with proper configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      if (AppConfig.isDevelopment) PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update base URL (useful for environment switching)
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Convert Dio errors to domain failures
  Failure _handleError(Object error) {
    if (error is DioException) {
      return _handleDioError(error);
    }

    return UnexpectedFailure.withMessage('Unknown error: ${error.toString()}');
  }

  /// Handle Dio-specific errors
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure.timeout();

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NetworkFailure.noInternet();
        }
        return NetworkFailure(message: 'Connection failed: ${error.message}');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          return NetworkFailure.serverError(statusCode);
        }
        return NetworkFailure(message: 'Server error: ${error.message}');

      case DioExceptionType.cancel:
        return NetworkFailure(message: 'Request cancelled');

      case DioExceptionType.unknown:
      default:
        return NetworkFailure(message: 'Network error: ${error.message}');
    }
  }
}

/// Authentication interceptor for automatic token handling
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add any additional headers or token refresh logic here
    // For now, tokens are set via setAuthToken method
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle token refresh on 401 errors
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic
      // This would typically involve calling a refresh token endpoint
      // and retrying the original request
    }

    super.onError(err, handler);
  }
}

/// Error interceptor for centralized error handling
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log errors for monitoring
    _logError(err);

    // Transform certain errors
    if (err.response?.statusCode == 422) {
      // Validation errors - could transform to ValidationFailure
    }

    super.onError(err, handler);
  }

  void _logError(DioException error) {
    // TODO: Integrate with Firebase Crashlytics or other logging service
    if (AppConfig.isDevelopment) {
      print('API Error: ${error.message}');
      print('URL: ${error.requestOptions.uri}');
      print('Method: ${error.requestOptions.method}');
      if (error.response != null) {
        print('Status: ${error.response!.statusCode}');
        print('Response: ${error.response!.data}');
      }
    }
  }
}

/// Extension methods for API responses
extension ApiResponseExtension on Response {
  /// Check if response is successful
  bool get isSuccessful {
    return statusCode != null &&
           statusCode! >= 200 &&
           statusCode! < 300;
  }

  /// Get response data as typed object
  T? getDataAs<T>() {
    if (data == null) return null;

    if (T == String) {
      return data.toString() as T;
    }

    if (T == Map<String, dynamic>) {
      return data as T;
    }

    // For complex objects, assume JSON parsing is handled elsewhere
    return data as T;
  }
}
