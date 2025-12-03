import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';

/// Service for persisting application state across app restarts
/// Handles critical state recovery and offline operation continuity
class StatePersistenceService {
  static const String _pendingOperationsKey = 'pending_operations';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _appStateKey = 'app_state';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _offlineQueueKey = 'offline_queue';

  final SharedPreferences _prefs;

  StatePersistenceService(this._prefs);

  /// Initialize the persistence service
  static Future<StatePersistenceService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StatePersistenceService(prefs);
  }

  /// Save pending operations that need to be completed
  Future<void> savePendingOperations(List<PendingOperation> operations) async {
    final operationsJson = operations.map((op) => op.toJson()).toList();
    await _prefs.setString(_pendingOperationsKey, jsonEncode(operationsJson));
  }

  /// Load pending operations on app startup
  Future<List<PendingOperation>> loadPendingOperations() async {
    final operationsJson = _prefs.getString(_pendingOperationsKey);
    if (operationsJson == null) return [];

    try {
      final operationsList = jsonDecode(operationsJson) as List;
      return operationsList.map((json) => PendingOperation.fromJson(json)).toList();
    } catch (e) {
      // If parsing fails, clear corrupted data
      await _prefs.remove(_pendingOperationsKey);
      return [];
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await _prefs.setString(_userPreferencesKey, jsonEncode(preferences.toJson()));
  }

  /// Load user preferences
  Future<UserPreferences> loadUserPreferences() async {
    final preferencesJson = _prefs.getString(_userPreferencesKey);
    if (preferencesJson == null) return UserPreferences.defaults();

    try {
      final preferencesMap = jsonDecode(preferencesJson) as Map<String, dynamic>;
      return UserPreferences.fromJson(preferencesMap);
    } catch (e) {
      return UserPreferences.defaults();
    }
  }

  /// Save general app state
  Future<void> saveAppState(AppStateSnapshot state) async {
    await _prefs.setString(_appStateKey, jsonEncode(state.toJson()));
  }

  /// Load app state
  Future<AppStateSnapshot?> loadAppState() async {
    final stateJson = _prefs.getString(_appStateKey);
    if (stateJson == null) return null;

    try {
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      return AppStateSnapshot.fromJson(stateMap);
    } catch (e) {
      return null;
    }
  }

  /// Save last successful sync time
  Future<void> saveLastSyncTime(DateTime syncTime) async {
    await _prefs.setString(_lastSyncTimeKey, syncTime.toIso8601String());
  }

  /// Load last sync time
  DateTime? loadLastSyncTime() {
    final syncTimeString = _prefs.getString(_lastSyncTimeKey);
    if (syncTimeString == null) return null;

    try {
      return DateTime.parse(syncTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Save offline operation queue
  Future<void> saveOfflineQueue(List<OfflineOperation> operations) async {
    final operationsJson = operations.map((op) => op.toJson()).toList();
    await _prefs.setString(_offlineQueueKey, jsonEncode(operationsJson));
  }

  /// Load offline operation queue
  Future<List<OfflineOperation>> loadOfflineQueue() async {
    final operationsJson = _prefs.getString(_offlineQueueKey);
    if (operationsJson == null) return [];

    try {
      final operationsList = jsonDecode(operationsJson) as List;
      return operationsList.map((json) => OfflineOperation.fromJson(json)).toList();
    } catch (e) {
      await _prefs.remove(_offlineQueueKey);
      return [];
    }
  }

  /// Clear all persisted state (useful for logout or reset)
  Future<void> clearAllState() async {
    await _prefs.remove(_pendingOperationsKey);
    await _prefs.remove(_userPreferencesKey);
    await _prefs.remove(_appStateKey);
    await _prefs.remove(_lastSyncTimeKey);
    await _prefs.remove(_offlineQueueKey);
  }

  /// Get storage usage information
  Future<Map<String, int>> getStorageUsage() async {
    final allKeys = _prefs.getKeys();
    final usage = <String, int>{};

    for (final key in allKeys) {
      final value = _prefs.getString(key);
      if (value != null) {
        usage[key] = utf8.encode(value).length;
      }
    }

    return usage;
  }

  /// Clean up old/expired data
  Future<void> cleanupExpiredData() async {
    final pendingOps = await loadPendingOperations();
    final validOps = pendingOps.where((op) => !op.isExpired).toList();

    if (validOps.length != pendingOps.length) {
      await savePendingOperations(validOps);
    }

    // Clean up offline queue - remove operations older than 7 days
    final offlineOps = await loadOfflineQueue();
    final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
    final validOfflineOps = offlineOps.where((op) => op.timestamp.isAfter(cutoffTime)).toList();

    if (validOfflineOps.length != offlineOps.length) {
      await saveOfflineQueue(validOfflineOps);
    }
  }
}

/// Represents a pending operation that needs to be completed
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration ttl; // Time to live

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.ttl = const Duration(hours: 24), // Default 24 hours
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttlHours': ttl.inHours,
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
    id: json['id'] as String,
    type: json['type'] as String,
    data: json['data'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
    ttl: Duration(hours: json['ttlHours'] as int? ?? 24),
  );
}

/// User preferences that should persist across sessions
class UserPreferences {
  final bool enableNotifications;
  final bool enableBiometrics;
  final bool autoSync;
  final String defaultCurrency;
  final int itemsPerPage;
  final bool showWelcomeScreen;
  final Map<String, dynamic> customSettings;

  UserPreferences({
    required this.enableNotifications,
    required this.enableBiometrics,
    required this.autoSync,
    required this.defaultCurrency,
    required this.itemsPerPage,
    required this.showWelcomeScreen,
    required this.customSettings,
  });

  factory UserPreferences.defaults() => UserPreferences(
    enableNotifications: true,
    enableBiometrics: false,
    autoSync: true,
    defaultCurrency: 'USD',
    itemsPerPage: 20,
    showWelcomeScreen: true,
    customSettings: {},
  );

  Map<String, dynamic> toJson() => {
    'enableNotifications': enableNotifications,
    'enableBiometrics': enableBiometrics,
    'autoSync': autoSync,
    'defaultCurrency': defaultCurrency,
    'itemsPerPage': itemsPerPage,
    'showWelcomeScreen': showWelcomeScreen,
    'customSettings': customSettings,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
    enableNotifications: json['enableNotifications'] as bool? ?? true,
    enableBiometrics: json['enableBiometrics'] as bool? ?? false,
    autoSync: json['autoSync'] as bool? ?? true,
    defaultCurrency: json['defaultCurrency'] as String? ?? 'USD',
    itemsPerPage: json['itemsPerPage'] as int? ?? 20,
    showWelcomeScreen: json['showWelcomeScreen'] as bool? ?? true,
    customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
  );
}

/// Snapshot of app state for recovery
class AppStateSnapshot {
  final String lastScreen;
  final Map<String, dynamic> navigationState;
  final Map<String, dynamic> formState;
  final DateTime timestamp;

  AppStateSnapshot({
    required this.lastScreen,
    required this.navigationState,
    required this.formState,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'lastScreen': lastScreen,
    'navigationState': navigationState,
    'formState': formState,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AppStateSnapshot.fromJson(Map<String, dynamic> json) => AppStateSnapshot(
    lastScreen: json['lastScreen'] as String,
    navigationState: json['navigationState'] as Map<String, dynamic>,
    formState: json['formState'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Offline operation that can be queued for later execution
enum OfflineOperationType {
  createExpense,
  updateExpense,
  deleteExpense,
  createBudget,
  updateBudget,
  deleteBudget,
}

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int retryCount;
  final Duration maxRetryDelay;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.payload,
    DateTime? timestamp,
    this.retryCount = 0,
    this.maxRetryDelay = const Duration(minutes: 30),
  }) : timestamp = timestamp ?? DateTime.now();

  OfflineOperation copyWith({
    int? retryCount,
    Duration? maxRetryDelay,
  }) => OfflineOperation(
    id: id,
    type: type,
    payload: payload,
    timestamp: timestamp,
    retryCount: retryCount ?? this.retryCount,
    maxRetryDelay: maxRetryDelay ?? this.maxRetryDelay,
  );

  Duration get nextRetryDelay {
    // Exponential backoff: 1min, 2min, 4min, 8min, 16min, then maxRetryDelay
    final delayMinutes = 1 << retryCount.clamp(0, 5);
    return Duration(minutes: delayMinutes).clamp(const Duration(minutes: 1), maxRetryDelay);
  }

  bool get canRetry => retryCount < 10; // Max 10 retries

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'maxRetryDelayMinutes': maxRetryDelay.inMinutes,
  };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) => OfflineOperation(
    id: json['id'] as String,
    type: OfflineOperationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OfflineOperationType.createExpense,
    ),
    payload: json['payload'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    maxRetryDelay: Duration(minutes: json['maxRetryDelayMinutes'] as int? ?? 30),
  );
}

/// State persistence provider
final statePersistenceProvider = Provider<StatePersistenceService>((ref) {
  throw UnimplementedError('StatePersistenceService must be initialized in main.dart');
});

/// User preferences provider with persistence
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final persistence = ref.watch(statePersistenceProvider);
  return UserPreferencesNotifier(persistence);
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final StatePersistenceService _persistence;

  UserPreferencesNotifier(this._persistence) : super(UserPreferences.defaults()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _persistence.loadUserPreferences();
    state = preferences;
  }

  Future<void> updatePreferences(UserPreferences newPreferences) async {
    state = newPreferences;
    await _persistence.saveUserPreferences(newPreferences);
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    await updatePreferences(state.copyWith(enableNotifications: enabled));
  }

  Future<void> updateBiometricSettings(bool enabled) async {
    await updatePreferences(state.copyWith(enableBiometrics: enabled));
  }

  Future<void> updateAutoSyncSettings(bool enabled) async {
    await updatePreferences(state.copyWith(autoSync: enabled));
  }
}

extension UserPreferencesCopyWith on UserPreferences {
  UserPreferences copyWith({
    bool? enableNotifications,
    bool? enableBiometrics,
    bool? autoSync,
    String? defaultCurrency,
    int? itemsPerPage,
    bool? showWelcomeScreen,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      autoSync: autoSync ?? this.autoSync,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      showWelcomeScreen: showWelcomeScreen ?? this.showWelcomeScreen,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

