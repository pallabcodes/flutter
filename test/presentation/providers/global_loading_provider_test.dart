import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/presentation/providers/global_loading_provider.dart';

void main() {
  group('GlobalLoadingNotifier', () {
    late GlobalLoadingNotifier loadingNotifier;

    setUp(() {
      loadingNotifier = GlobalLoadingNotifier();
    });

    tearDown(() {
      loadingNotifier.dispose();
    });

    test('should initialize with loading false', () {
      expect(loadingNotifier.state, false);
    });

    test('should show and hide loading correctly', () {
      loadingNotifier.showLoading();
      expect(loadingNotifier.state, true);

      loadingNotifier.hideLoading();
      expect(loadingNotifier.state, false);
    });

    test('should execute operation with loading and minimum duration', () async {
      final startTime = DateTime.now();

      final result = await loadingNotifier.executeWithLoading(() async {
        await Future.delayed(const Duration(milliseconds: 50)); // Short operation
        return 'success';
      });

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(result, 'success');
      expect(loadingNotifier.state, false); // Should be false after completion
      expect(duration.inMilliseconds, greaterThanOrEqualTo(300)); // Minimum duration
    });

    test('should handle operation errors', () async {
      expect(
        () async => await loadingNotifier.executeWithLoading(() async {
          throw Exception('Test error');
        }),
        throwsException,
      );

      expect(loadingNotifier.state, false); // Should be false even on error
    });

    test('should execute multiple operations with loading', () async {
      final operations = [
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'result1';
        },
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'result2';
        },
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'result3';
        },
      ];

      final startTime = DateTime.now();
      final results = await loadingNotifier.executeAllWithLoading(operations);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(results, ['result1', 'result2', 'result3']);
      expect(loadingNotifier.state, false);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(300)); // Minimum duration
    });
  });

  group('LoadingOperationsNotifier', () {
    late LoadingOperationsNotifier operationsNotifier;

    setUp(() {
      operationsNotifier = LoadingOperationsNotifier();
    });

    test('should initialize with empty operations set', () {
      expect(operationsNotifier.state, isEmpty);
      expect(operationsNotifier.hasActiveOperations, false);
    });

    test('should start and complete operations correctly', () {
      operationsNotifier.startOperation('op1');
      expect(operationsNotifier.state, {'op1'});
      expect(operationsNotifier.hasActiveOperations, true);
      expect(operationsNotifier.isOperationLoading('op1'), true);
      expect(operationsNotifier.isOperationLoading('op2'), false);

      operationsNotifier.startOperation('op2');
      expect(operationsNotifier.state, {'op1', 'op2'});

      operationsNotifier.completeOperation('op1');
      expect(operationsNotifier.state, {'op2'});
      expect(operationsNotifier.isOperationLoading('op1'), false);
      expect(operationsNotifier.isOperationLoading('op2'), true);
    });

    test('should clear all operations', () {
      operationsNotifier.startOperation('op1');
      operationsNotifier.startOperation('op2');
      expect(operationsNotifier.hasActiveOperations, true);

      operationsNotifier.clearAll();
      expect(operationsNotifier.state, isEmpty);
      expect(operationsNotifier.hasActiveOperations, false);
    });
  });

  group('Computed Providers', () {
    test('isAnyLoadingProvider should combine global and operations loading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially no loading
      expect(container.read(isAnyLoadingProvider), false);

      // Start global loading
      container.read(globalLoadingProvider.notifier).showLoading();
      expect(container.read(isAnyLoadingProvider), true);

      // Hide global loading, start operations loading
      container.read(globalLoadingProvider.notifier).hideLoading();
      container.read(loadingOperationsProvider.notifier).startOperation('test_op');
      expect(container.read(isAnyLoadingProvider), true);

      // Clear operations loading
      container.read(loadingOperationsProvider.notifier).clearAll();
      expect(container.read(isAnyLoadingProvider), false);
    });
  });

  group('Loading Extensions', () {
    test('executeWithGlobalLoading should work with container', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(globalLoadingProvider.notifier).executeWithGlobalLoading(
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        },
      );

      expect(result, 42);
      expect(container.read(isAnyLoadingProvider), false);
    });

    test('executeWithTrackedLoading should track operation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.executeWithTrackedLoading(
        'tracked_op',
        () async {
          expect(container.read(loadingOperationsProvider)['tracked_op'], true);
          await Future.delayed(const Duration(milliseconds: 10));
          return 'tracked_result';
        },
      );

      expect(result, 'tracked_result');
      expect(container.read(loadingOperationsProvider)['tracked_op'], false);
    });
  });

  group('LoadingButton Widget', () {
    testWidgets('should show loading state', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoadingButton(
                onPressed: () async {
                  wasPressed = true;
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      // Initially not loading
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNothing);

      // Tap button to trigger loading
      await tester.tap(find.text('Test Button'));
      await tester.pump(); // Rebuild with loading state

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();

      // Should be back to normal
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(wasPressed, true);
    });

    testWidgets('should disable when global loading is active', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return LoadingButton(
                    onPressed: () {
                      // Should not be called when loading
                      fail('Button should be disabled');
                    },
                    child: const Text('Test Button'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Enable global loading
      final container = ProviderContainer();
      container.read(globalLoadingProvider.notifier).showLoading();

      // Button should be disabled
      final button = find.text('Test Button');
      expect(button, findsOneWidget);

      // Try to tap - should not trigger onPressed since button is disabled
      await tester.tap(button);
      await tester.pump();

      // Cleanup
      container.dispose();
    });
  });

  group('LoadingFutureBuilder Widget', () {
    testWidgets('should handle loading and data states', (WidgetTester tester) async {
      Future<String> future = Future.value('test data');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoadingFutureBuilder<String>(
                future: future,
                builder: (context, data) => Text('Data: $data'),
              ),
            ),
          ),
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for future to complete
      await tester.pumpAndSettle();

      // Should show data
      expect(find.text('Data: test data'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle errors', (WidgetTester tester) async {
      Future<String> future = Future.error('Test error');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoadingFutureBuilder<String>(
                future: future,
                builder: (context, data) => Text('Data: $data'),
                errorBuilder: (error, stack) => Text('Error: $error'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Error: Test error'), findsOneWidget);
    });
  });
}
