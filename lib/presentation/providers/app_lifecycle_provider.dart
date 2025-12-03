import 'dart:async';
import 'dart:ui';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App lifecycle state management
/// Handles app lifecycle events and coordinates responses across the app
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  final StatePersistenceService _persistence;
  final PerformanceMonitor _performanceMonitor;

  DateTime? _backgroundTime;
  Timer? _backgroundTimer;
  Timer? _cleanupTimer;

  // Lifecycle event streams for other parts of the app to listen to
  final StreamController<AppLifecycleEvent> _lifecycleEvents =
      StreamController<AppLifecycleEvent>.broadcast();

  // Configuration
  static const Duration _maxBackgroundTime = Duration(minutes: 30); // Auto-logout after 30min
  static const Duration _cleanupInterval = Duration(minutes: 10); // Periodic cleanup
  static const Duration _stateSaveDelay = Duration(seconds: 5); // Debounced state saving

  AppLifecycleNotifier(this._persistence, this._performanceMonitor)
      : super(AppLifecycleState.resumed) {
    _initializeLifecycleObserver();
    _startPeriodicCleanup();
  }

  void _initializeLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final previousState = state;
    state = lifecycleState;

    // Emit lifecycle event
    _lifecycleEvents.add(AppLifecycleEvent(
      fromState: previousState,
      toState: lifecycleState,
      timestamp: DateTime.now(),
    ));

    // Handle state transitions
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() {
    _performanceMonitor.recordAppResumed();

    // Cancel background timer if it was running
    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    // Check if we were in background too long
    if (_backgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      if (backgroundDuration > _maxBackgroundTime) {
        _handleExtendedBackgroundReturn(backgroundDuration);
      }
    }

    _backgroundTime = null;

    // Refresh data if needed
    _refreshAppData();

    // Emit resumed event for other components
    _lifecycleEvents.add(AppLifecycleEvent.resumed());
  }

  void _handleAppPaused() {
    _backgroundTime = DateTime.now();
    _performanceMonitor.recordAppPaused();

    // Schedule auto-logout timer
    _backgroundTimer = Timer(_maxBackgroundTime, _handleBackgroundTimeout);

    // Save app state for recovery
    _scheduleStateSave();

    // Emit paused event
    _lifecycleEvents.add(AppLifecycleEvent.paused());
  }

  void _handleAppInactive() {
    // App is partially visible (e.g., during phone call)
    _lifecycleEvents.add(AppLifecycleEvent.inactive());
  }

  void _handleAppDetached() {
    // App is being terminated
    _cleanupResources();
    _lifecycleEvents.add(AppLifecycleEvent.detached());
  }

  void _handleAppHidden() {
    // App is hidden but still running
    _lifecycleEvents.add(AppLifecycleEvent.hidden());
  }

  void _handleBackgroundTimeout() {
    // App was in background too long - could trigger auto-logout
    _lifecycleEvents.add(AppLifecycleEvent.backgroundTimeout());
  }

  void _handleExtendedBackgroundReturn(Duration backgroundDuration) {
    // Handle return after extended background time
    _lifecycleEvents.add(AppLifecycleEvent.extendedBackgroundReturn(backgroundDuration));
  }

  void _refreshAppData() {
    // Trigger data refresh for components that need it
    _lifecycleEvents.add(AppLifecycleEvent.dataRefreshRequested());
  }

  void _scheduleStateSave() {
    // Debounced state saving to avoid excessive I/O
    Timer(_stateSaveDelay, _saveCurrentState);
  }

  Future<void> _saveCurrentState() async {
    try {
      // Save minimal state snapshot for recovery
      final stateSnapshot = AppStateSnapshot(
        lastScreen: 'unknown', // Would be provided by navigation state
        navigationState: {},
        formState: {},
      );
      await _persistence.saveAppState(stateSnapshot);
    } catch (e) {
      // Log error but don't crash
      debugPrint('Failed to save app state: $e');
    }
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _performCleanup());
  }

  void _performCleanup() {
    // Perform periodic cleanup tasks
    _persistence.cleanupExpiredData();

    // Emit cleanup event for other components
    _lifecycleEvents.add(AppLifecycleEvent.cleanupPerformed());
  }

  void _cleanupResources() {
    // Clean up resources before app termination
    _backgroundTimer?.cancel();
    _cleanupTimer?.cancel();
    _lifecycleEvents.close();
  }

  /// Get stream of lifecycle events for other components to listen to
  Stream<AppLifecycleEvent> get lifecycleEvents => _lifecycleEvents.stream;

  /// Check if app is currently in foreground
  bool get isInForeground => state == AppLifecycleState.resumed;

  /// Check if app is currently in background
  bool get isInBackground => state == AppLifecycleState.paused;

  /// Get time spent in background (if currently in background)
  Duration? get backgroundTime {
    if (_backgroundTime == null) return null;
    return DateTime.now().difference(_backgroundTime!);
  }

  /// Manually trigger data refresh
  void triggerDataRefresh() {
    _refreshAppData();
  }

  /// Manually save current state
  Future<void> saveStateNow() async {
    await _saveCurrentState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }
}

/// App lifecycle event for inter-component communication
class AppLifecycleEvent {
  final AppLifecycleState fromState;
  final AppLifecycleState toState;
  final DateTime timestamp;
  final AppLifecycleEventType type;
  final dynamic data;

  AppLifecycleEvent({
    required this.fromState,
    required this.toState,
    DateTime? timestamp,
    this.data,
  })  : timestamp = timestamp ?? DateTime.now(),
        type = _determineEventType(fromState, toState);

  AppLifecycleEvent.resumed()
      : fromState = AppLifecycleState.paused,
        toState = AppLifecycleState.resumed,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.resumed,
        data = null;

  AppLifecycleEvent.paused()
      : fromState = AppLifecycleState.resumed,
        toState = AppLifecycleState.paused,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.paused,
        data = null;

  AppLifecycleEvent.inactive()
      : fromState = AppLifecycleState.resumed,
        toState = AppLifecycleState.inactive,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.inactive,
        data = null;

  AppLifecycleEvent.detached()
      : fromState = AppLifecycleState.paused,
        toState = AppLifecycleState.detached,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.detached,
        data = null;

  AppLifecycleEvent.hidden()
      : fromState = AppLifecycleState.resumed,
        toState = AppLifecycleState.hidden,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.hidden,
        data = null;

  AppLifecycleEvent.backgroundTimeout()
      : fromState = AppLifecycleState.paused,
        toState = AppLifecycleState.paused,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.backgroundTimeout,
        data = null;

  AppLifecycleEvent.extendedBackgroundReturn(Duration duration)
      : fromState = AppLifecycleState.paused,
        toState = AppLifecycleState.resumed,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.extendedBackgroundReturn,
        data = duration;

  AppLifecycleEvent.dataRefreshRequested()
      : fromState = AppLifecycleState.resumed,
        toState = AppLifecycleState.resumed,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.dataRefreshRequested,
        data = null;

  AppLifecycleEvent.cleanupPerformed()
      : fromState = AppLifecycleState.resumed,
        toState = AppLifecycleState.resumed,
        timestamp = DateTime.now(),
        type = AppLifecycleEventType.cleanupPerformed,
        data = null;

  static AppLifecycleEventType _determineEventType(
    AppLifecycleState from,
    AppLifecycleState to,
  ) {
    if (from == AppLifecycleState.paused && to == AppLifecycleState.resumed) {
      return AppLifecycleEventType.resumed;
    }
    if (from == AppLifecycleState.resumed && to == AppLifecycleState.paused) {
      return AppLifecycleEventType.paused;
    }
    if (from == AppLifecycleState.resumed && to == AppLifecycleState.inactive) {
      return AppLifecycleEventType.inactive;
    }
    if (from == AppLifecycleState.paused && to == AppLifecycleState.detached) {
      return AppLifecycleEventType.detached;
    }
    if (from == AppLifecycleState.resumed && to == AppLifecycleState.hidden) {
      return AppLifecycleEventType.hidden;
    }
    return AppLifecycleEventType.stateChanged;
  }
}

/// App lifecycle event types
enum AppLifecycleEventType {
  resumed,
  paused,
  inactive,
  detached,
  hidden,
  stateChanged,
  backgroundTimeout,
  extendedBackgroundReturn,
  dataRefreshRequested,
  cleanupPerformed,
}

/// App lifecycle provider
final appLifecycleProvider = StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>((ref) {
  final persistence = ref.watch(statePersistenceProvider);
  final performanceMonitor = ref.watch(performanceMonitorProvider);
  return AppLifecycleNotifier(persistence, performanceMonitor);
});

/// Lifecycle events stream provider
final lifecycleEventsProvider = StreamProvider<AppLifecycleEvent>((ref) {
  final lifecycleNotifier = ref.watch(appLifecycleProvider.notifier);
  return lifecycleNotifier.lifecycleEvents;
});

/// Computed providers for common lifecycle states
final isAppInForegroundProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider.notifier).isInForeground;
});

final isAppInBackgroundProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider.notifier).isInBackground;
});

final backgroundTimeProvider = Provider<Duration?>((ref) {
  return ref.watch(appLifecycleProvider.notifier).backgroundTime;
});

/// Performance monitor provider (assuming it's available)
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return getIt<PerformanceMonitor>();
});

/// Lifecycle-aware widget that responds to lifecycle events
class LifecycleAwareWidget extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(AppLifecycleEvent event)? onLifecycleEvent;
  final VoidCallback? onResumed;
  final VoidCallback? onPaused;
  final VoidCallback? onInactive;
  final VoidCallback? onDetached;
  final VoidCallback? onHidden;

  const LifecycleAwareWidget({
    super.key,
    required this.child,
    this.onLifecycleEvent,
    this.onResumed,
    this.onPaused,
    this.onInactive,
    this.onDetached,
    this.onHidden,
  });

  @override
  ConsumerState<LifecycleAwareWidget> createState() => _LifecycleAwareWidgetState();
}

class _LifecycleAwareWidgetState extends ConsumerState<LifecycleAwareWidget> {
  StreamSubscription<AppLifecycleEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(lifecycleEventsProvider.stream).listen(_handleLifecycleEvent);
  }

  void _handleLifecycleEvent(AppLifecycleEvent event) {
    widget.onLifecycleEvent?.call(event);

    switch (event.type) {
      case AppLifecycleEventType.resumed:
        widget.onResumed?.call();
        break;
      case AppLifecycleEventType.paused:
        widget.onPaused?.call();
        break;
      case AppLifecycleEventType.inactive:
        widget.onInactive?.call();
        break;
      case AppLifecycleEventType.detached:
        widget.onDetached?.call();
        break;
      case AppLifecycleEventType.hidden:
        widget.onHidden?.call();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily make widgets lifecycle-aware
extension LifecycleAwareExtension on Widget {
  Widget lifecycleAware({
    void Function(AppLifecycleEvent event)? onLifecycleEvent,
    VoidCallback? onResumed,
    VoidCallback? onPaused,
    VoidCallback? onInactive,
    VoidCallback? onDetached,
    VoidCallback? onHidden,
  }) {
    return LifecycleAwareWidget(
      onLifecycleEvent: onLifecycleEvent,
      onResumed: onResumed,
      onPaused: onPaused,
      onInactive: onInactive,
      onDetached: onDetached,
      onHidden: onHidden,
      child: this,
    );
  }
}

/// App lifecycle overlay that shows current lifecycle state (for debugging)
class LifecycleDebugOverlay extends ConsumerWidget {
  const LifecycleDebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleState = ref.watch(appLifecycleProvider);
    final backgroundTime = ref.watch(backgroundTimeProvider);

    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lifecycle: ${lifecycleState.name}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (backgroundTime != null)
              Text(
                'Background: ${backgroundTime.inSeconds}s',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

