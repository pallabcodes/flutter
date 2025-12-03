import 'package:finwise/core/config/injection.dart';
import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Error boundary widget that catches and handles errors in the widget tree
/// Prevents entire app crashes by isolating widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final bool showRetryButton;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.showRetryButton = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void didCatchError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);

    // Log error to analytics/monitoring service
    try {
      final analyticsService = getIt<AnalyticsService>();
      analyticsService.trackError(error, stackTrace);
    } catch (e) {
      // Fallback logging if analytics service is not available
      debugPrint('ErrorBoundary caught error: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Use custom error builder if provided
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      // Default error UI
      return ErrorFallbackWidget(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: widget.showRetryButton ? _retry : null,
      );
    }

    return widget.child;
  }
}

/// Default error fallback widget
class ErrorFallbackWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const ErrorFallbackWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              _getErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingLG),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG,
                    vertical: AppTheme.spacingMD,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is String) return error;

    // Handle common error types with user-friendly messages
    if (error.toString().contains('Network')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (error.toString().contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (error.toString().contains('Permission')) {
      return 'Permission denied. Please check app permissions.';
    }
    if (error.toString().contains('Database')) {
      return 'Database error. Please restart the app.';
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Screen-level error boundary with full screen layout
class ScreenErrorBoundary extends StatelessWidget {
  final Widget child;
  final String screenName;

  const ScreenErrorBoundary({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // Log screen-specific errors
        debugPrint('Error in screen $screenName: $error');
      },
      errorBuilder: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: Text('$screenName - Error'),
          automaticallyImplyLeading: true,
        ),
        body: ErrorFallbackWidget(
          error: error,
          stackTrace: stackTrace,
          onRetry: () {
            // Navigate back to previous screen
            Navigator.of(context).pop();
          },
        ),
      ),
      child: child,
    );
  }
}

/// Scoped error boundary for specific sections of UI
class ScopedErrorBoundary extends StatelessWidget {
  final Widget child;
  final String scopeName;
  final Widget? fallback;

  const ScopedErrorBoundary({
    super.key,
    required this.child,
    required this.scopeName,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        debugPrint('Error in scope $scopeName: $error');
      },
      errorBuilder: (error, stackTrace) {
        if (fallback != null) return fallback!;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  'Error in $scopeName section',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Extension to easily wrap widgets with error boundaries
extension ErrorBoundaryExtension on Widget {
  /// Wrap with error boundary
  Widget withErrorBoundary({
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    void Function(Object error, StackTrace? stackTrace)? onError,
    bool showRetryButton = true,
  }) {
    return ErrorBoundary(
      errorBuilder: errorBuilder,
      onError: onError,
      showRetryButton: showRetryButton,
      child: this,
    );
  }

  /// Wrap with screen error boundary
  Widget withScreenErrorBoundary(String screenName) {
    return ScreenErrorBoundary(
      screenName: screenName,
      child: this,
    );
  }

  /// Wrap with scoped error boundary
  Widget withScopedErrorBoundary(String scopeName, {Widget? fallback}) {
    return ScopedErrorBoundary(
      scopeName: scopeName,
      fallback: fallback,
      child: this,
    );
  }
}

