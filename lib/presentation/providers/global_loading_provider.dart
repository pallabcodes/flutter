import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global loading state management
/// Provides centralized loading state across the entire app
class GlobalLoadingNotifier extends StateNotifier<bool> {
  GlobalLoadingNotifier() : super(false);

  static const Duration _minLoadingDuration = Duration(milliseconds: 300);

  /// Show global loading state
  void showLoading() {
    state = true;
  }

  /// Hide global loading state
  void hideLoading() {
    state = false;
  }

  /// Execute an async operation with global loading
  Future<T> executeWithLoading<T>(Future<T> Function() operation) async {
    final startTime = DateTime.now();
    showLoading();

    try {
      final result = await operation();

      // Ensure minimum loading duration for better UX
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < _minLoadingDuration) {
        await Future.delayed(_minLoadingDuration - elapsed);
      }

      return result;
    } finally {
      hideLoading();
    }
  }

  /// Execute multiple operations with loading state
  Future<List<T>> executeAllWithLoading<T>(List<Future<T> Function()> operations) async {
    final startTime = DateTime.now();
    showLoading();

    try {
      final results = await Future.wait(operations.map((op) => op()));

      // Ensure minimum loading duration
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < _minLoadingDuration) {
        await Future.delayed(_minLoadingDuration - elapsed);
      }

      return results;
    } finally {
      hideLoading();
    }
  }
}

/// Global loading provider
final globalLoadingProvider = StateNotifierProvider<GlobalLoadingNotifier, bool>((ref) {
  return GlobalLoadingNotifier();
});

/// Loading operations tracker for multiple concurrent operations
class LoadingOperationsNotifier extends StateNotifier<Set<String>> {
  LoadingOperationsNotifier() : super({});

  /// Start a loading operation
  void startOperation(String operationId) {
    state = {...state, operationId};
  }

  /// Complete a loading operation
  void completeOperation(String operationId) {
    state = {...state}..remove(operationId);
  }

  /// Check if any operations are loading
  bool get hasActiveOperations => state.isNotEmpty;

  /// Check if specific operation is loading
  bool isOperationLoading(String operationId) => state.contains(operationId);

  /// Clear all operations
  void clearAll() {
    state = {};
  }
}

/// Loading operations provider for tracking multiple concurrent operations
final loadingOperationsProvider = StateNotifierProvider<LoadingOperationsNotifier, Set<String>>((ref) {
  return LoadingOperationsNotifier();
});

/// Computed provider for overall loading state
final isAnyLoadingProvider = Provider<bool>((ref) {
  final globalLoading = ref.watch(globalLoadingProvider);
  final operationsLoading = ref.watch(loadingOperationsProvider).isNotEmpty;
  return globalLoading || operationsLoading;
});

/// Loading overlay widget that can be placed at the root of the app
class LoadingOverlay extends ConsumerWidget {
  final Widget child;
  final bool showPerformanceMetrics;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.showPerformanceMetrics = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(globalLoadingProvider);
    final activeOperations = ref.watch(loadingOperationsProvider);

    return Stack(
      children: [
        child,
        if (isLoading || activeOperations.isNotEmpty)
          _buildLoadingOverlay(context, activeOperations, showPerformanceMetrics),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, Set<String> activeOperations, bool showMetrics) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (activeOperations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...activeOperations.map((operation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      operation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
                if (showMetrics) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Active operations: ${activeOperations.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension methods for easy loading state management
extension LoadingExtensions on WidgetRef {
  /// Execute operation with global loading
  Future<T> executeWithGlobalLoading<T>(Future<T> Function() operation) {
    return read(globalLoadingProvider.notifier).executeWithLoading(operation);
  }

  /// Start a tracked loading operation
  void startLoadingOperation(String operationId) {
    read(loadingOperationsProvider.notifier).startOperation(operationId);
  }

  /// Complete a tracked loading operation
  void completeLoadingOperation(String operationId) {
    read(loadingOperationsProvider.notifier).completeOperation(operationId);
  }

  /// Execute operation with tracked loading
  Future<T> executeWithTrackedLoading<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    startLoadingOperation(operationId);
    try {
      return await operation();
    } finally {
      completeLoadingOperation(operationId);
    }
  }
}

/// Loading button that automatically shows loading state
class LoadingButton extends ConsumerWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showSuccessFeedback;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.showSuccessFeedback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGlobalLoading = ref.watch(globalLoadingProvider);

    return ElevatedButton(
      onPressed: (onPressed != null && !isGlobalLoading) ? () async {
        try {
          await onPressed!();
        } catch (e) {
          // Error handling is done by error boundaries
          rethrow;
        }
      } : null,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGlobalLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          child,
        ],
      ),
    );
  }
}

/// Loading-aware FutureBuilder
class LoadingFutureBuilder<T> extends ConsumerWidget {
  final Future<T>? future;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget Function(Object?, StackTrace?)? errorBuilder;
  final T? initialData;

  const LoadingFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.initialData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGlobalLoading = ref.watch(globalLoadingProvider);

    if (future == null) {
      return builder(context, initialData as T);
    }

    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || isGlobalLoading) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error, snapshot.stackTrace) ??
                 Center(child: Text('Error: ${snapshot.error}'));
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}

