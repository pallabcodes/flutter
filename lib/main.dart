import 'package:finwise/core/accessibility/localized_app.dart';
import 'package:finwise/core/config/app_config.dart';
import 'package:finwise/core/config/injection.dart';
import 'package:finwise/core/monitoring/monitoring_dashboard.dart';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/core/navigation/route_guard.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:finwise/presentation/providers/app_lifecycle_provider.dart';
import 'package:finwise/presentation/providers/app_startup_provider.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/providers/background_sync_provider.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/providers/global_loading_provider.dart';
import 'package:finwise/presentation/providers/theme_providers.dart';
import 'package:finwise/presentation/providers/undo_redo_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Production-ready main entry point for FinWise
/// Implements enterprise-grade error handling, logging, and initialization
void main() async {
  final appStartTime = DateTime.now(); // value assigned once during runtime (during execution) & its type can be inferred/explicit
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for localization
  await initializeDateFormatting();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure Crashlytics for error reporting
  await _configureCrashlytics();

  // Initialize dependency injection
  await configureDependencies();

  // Initialize state persistence service
  final statePersistenceService = await StatePersistenceService.initialize();
  getIt.registerSingleton<StatePersistenceService>(statePersistenceService);

  // Initialize monitoring services
  final performanceMonitor = getIt<PerformanceMonitor>();
  final analyticsService = getIt<AnalyticsService>();
  final healthMonitor = getIt<HealthMonitor>();

  await Future.wait([
    performanceMonitor.initialize(),
    analyticsService.initialize(),
    healthMonitor.initialize(),
  ]);

  // Record app startup time
  final startupTime = DateTime.now().difference(appStartTime);
  performanceMonitor.recordAppStartup(startupTime);

  // Track app open event
  analyticsService.trackUserAction('app_open', category: 'lifecycle');

  runApp(
    ProviderScope(
      observers: kDebugMode ? [AppProviderObserver()] : null,
      child: MonitoringOverlay(
        showPerformance: kDebugMode,
        showAnalytics: kDebugMode,
        child: LoadingOverlay(
          showPerformanceMetrics: kDebugMode,
          child: const LifecycleAwareApp(), // Wrap with lifecycle awareness
        ),
      ),
    ),
  );
}

/// Configure Firebase Crashlytics for production error reporting (used _ to indicate this is a private method)
Future<void> _configureCrashlytics() async {
  // kDebugMode is a Flutter constant that's true during development/debug builds, false in release builds
  if (kDebugMode) {
    // Disable Crashlytics in debug mode to avoid spam (singleton instance)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    // Enable Crashlytics in production (the same singleton instance is now enabled)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors to Crashlytics
    // FlutterError.onError is Flutter's global error handler for synchronous errors (like uncaught exceptions in Java/C++)
    // We're assigning a callback function that forwards errors to Crashlytics
    // recordFlutterFatalError is Crashlytics' method to record fatal Flutter errors
    // Similar to: process.on('uncaughtException') in Node.js or global exception handlers in Java/C++

    // Synchronous errors: Catches main-thread Flutter errors during widget building/rendering
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // Asynchronous errors: Catches errors in background tasks, isolates, or platform-level operations
  PlatformDispatcher.instance.onError = (error, stack) {
    // Record async errors:
    // Forwards the async error to Crashlytics with fatal: true flag
    // recordError method takes error, stack trace, and metadata
    // Why fatal: true? Async errors outside main thread are usually critical system-level issues
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    // Why return true:
    // Returning true tells the platform dispatcher that the error has been handled
    // Prevents the error from propagating further or causing app crashes
    // In Flutter's error handling, true means "error consumed", false means "let it bubble up"
    return true;
  };
}

// Main application widget with Riverpod integration
// extends ConsumerWidget means it can read Riverpod state (like a React component with useSelector or a class with dependency injection)
// ConsumerWidget is Riverpod's equivalent of StatelessWidget but with state reading capabilities
class FinWiseApp extends ConsumerWidget {
  const FinWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);
    final themeMode = ref.watch(themeProvider);

    return appStartupState.maybeWhen(
      data: (_) => LocalizedAccessibleApp(
        lightTheme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        child: Builder(
          builder: (context) => MaterialApp(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.initialRoute, // "/"
            // Add navigation observer for auth monitoring
            navigatorObservers: [
              AuthNavigationObserver(RouteGuard()),
            ],
            builder: (context, child) {
              // Wrap with additional providers if needed
              return child!;
            },
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Retry app startup
                    ref.invalidate(appStartupProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      orElse: () => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

// Lifecycle-aware main application widget
class LifecycleAwareApp extends ConsumerWidget {
  const LifecycleAwareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);
    final themeMode = ref.watch(themeProvider);

    return appStartupState.maybeWhen(
      data: (_) => LocalizedAccessibleApp(
        lightTheme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        child: Builder(
          builder: (context) => Stack(
            children: [
              MaterialApp(
                title: AppConfig.appName,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                navigatorKey: AppRouter.navigatorKey,
                onGenerateRoute: AppRouter.onGenerateRoute,
                initialRoute: AppRouter.initialRoute,
                navigatorObservers: [
                  AuthNavigationObserver(RouteGuard()),
                ],
                builder: (context, child) {
                  return child!;
                },
              ),
              // Debug overlay in development
              if (kDebugMode) const LifecycleDebugOverlay(),
            ],
          ),
        ),
      ).lifecycleAware(
        onResumed: () {
          // Trigger data refresh when app resumes
          ref.read(appLifecycleProvider.notifier).triggerDataRefresh();
        },
        onPaused: () {
          // Save state when app goes to background
          ref.read(appLifecycleProvider.notifier).saveStateNow();
        },
      ),
      error: (error, stack) => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(appStartupProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      orElse: () => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

/// Provider observer for debugging in development
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode && previousValue != newValue) {
      debugPrint('''
Provider ${provider.name ?? provider.runtimeType} updated:
  Previous: $previousValue
  New: $newValue
''');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('Provider ${provider.name ?? provider.runtimeType} disposed');
    }
  }
}
