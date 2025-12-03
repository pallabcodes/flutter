import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/core/config/injection.dart';
import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/error_boundary.dart';

class MockAnalyticsService extends AnalyticsService {
  Object? lastError;
  StackTrace? lastStackTrace;

  @override
  void trackError(Object error, StackTrace? stackTrace) {
    lastError = error;
    lastStackTrace = stackTrace;
  }
}

void main() {
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    // Mock the injection container
    getIt.registerSingleton<AnalyticsService>(mockAnalytics);
  });

  tearDown(() {
    getIt.reset();
  });

  group('ErrorBoundary', () {
    testWidgets('should display child when no error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Text('Normal content'),
            ),
          ),
        ),
      );

      expect(find.text('Normal content'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('should catch and display error with default UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  // Throw error in next frame
                  Future.microtask(() => throw Exception('Test error'));
                  return const Text('Content');
                },
              ),
            ),
          ),
        ),
      );

      // Wait for error to be caught
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should use custom error builder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              errorBuilder: (error, stackTrace) => Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red,
                child: Text('Custom error: $error'),
              ),
              child: Builder(
                builder: (context) {
                  Future.microtask(() => throw Exception('Custom test error'));
                  return const Text('Content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom error: Exception: Custom test error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('should retry on button press', (WidgetTester tester) async {
      bool shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  if (shouldThrow) {
                    Future.microtask(() => throw Exception('Retry test error'));
                  }
                  return const Text('Recovered content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Something went wrong'), findsOneWidget);

      // Set flag to not throw error on retry
      shouldThrow = false;

      // Tap retry button
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Should show recovered content
      expect(find.text('Recovered content'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('should report error to analytics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  Future.microtask(() => throw Exception('Analytics test error'));
                  return const Text('Content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that error was reported
      expect(mockAnalytics.lastError, isA<Exception>());
      expect(mockAnalytics.lastError.toString(), 'Exception: Analytics test error');
      expect(mockAnalytics.lastStackTrace, isNotNull);
    });

    testWidgets('should handle different error types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  Future.microtask(() => throw 'String error');
                  return const Text('Content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('String error'), findsOneWidget);
    });

    testWidgets('should provide user-friendly error messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  Future.microtask(() => throw Exception('Network timeout'));
                  return const Text('Content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Network connection error. Please check your internet connection.'), findsOneWidget);
    });
  });

  group('ScreenErrorBoundary', () {
    testWidgets('should wrap content in scaffold with error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenErrorBoundary(
            screenName: 'Test Screen',
            child: Builder(
              builder: (context) {
                Future.microtask(() => throw Exception('Screen error'));
                return const Text('Screen content');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have app bar with screen name
      expect(find.text('Test Screen - Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('ScopedErrorBoundary', () {
    testWidgets('should show inline error for scoped sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Normal content'),
                ScopedErrorBoundary(
                  scopeName: 'Test Section',
                  child: Builder(
                    builder: (context) {
                      Future.microtask(() => throw Exception('Scoped error'));
                      return const Text('Section content');
                    },
                  ),
                ),
                const Text('More normal content'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Normal content should still be visible
      expect(find.text('Normal content'), findsOneWidget);
      expect(find.text('More normal content'), findsOneWidget);

      // Should show scoped error
      expect(find.text('Error in Test Section section'), findsOneWidget);
    });

    testWidgets('should use custom fallback widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScopedErrorBoundary(
              scopeName: 'Custom Section',
              fallback: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue,
                child: const Text('Custom fallback'),
              ),
              child: Builder(
                builder: (context) {
                  Future.microtask(() => throw Exception('Fallback test'));
                  return const Text('Original content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom fallback'), findsOneWidget);
      expect(find.text('Error in Custom Section section'), findsNothing);
    });
  });

  group('ErrorBoundary Extensions', () {
    testWidgets('withErrorBoundary should wrap widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test content')
                .withErrorBoundary(),
          ),
        ),
      );

      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('withScreenErrorBoundary should create screen boundary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Text('Screen content')
              .withScreenErrorBoundary('Test Screen'),
        ),
      );

      expect(find.text('Screen content'), findsOneWidget);
    });

    testWidgets('withScopedErrorBoundary should create scoped boundary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Scoped content')
                .withScopedErrorBoundary('Test Scope'),
          ),
        ),
      );

      expect(find.text('Scoped content'), findsOneWidget);
    });
  });

  group('ErrorFallbackWidget', () {
    testWidgets('should display error with retry button', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorFallbackWidget(
              error: Exception('Test error'),
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryPressed, true);
    });

    testWidgets('should hide retry button when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorFallbackWidget(
              error: Exception('No retry error'),
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('should handle string errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorFallbackWidget(
              error: 'String error message',
            ),
          ),
        ),
      );

      expect(find.text('String error message'), findsOneWidget);
    });
  });
}
