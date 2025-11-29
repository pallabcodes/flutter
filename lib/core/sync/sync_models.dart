import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';

/// Sync operation types
enum SyncOperationType {
  createExpense,
  updateExpense,
  deleteExpense,
  createBudget,
  updateBudget,
  deleteBudget,
}

/// Sync operation data class
class SyncOperation {
  final String id;
  final String userId;
  final SyncOperationType type;
  final String entityId;
  final String data; // JSON string of the entity
  final DateTime timestamp;
  final int retryCount;
  final bool isCompleted;
  final String? errorMessage;

  SyncOperation({
    required this.id,
    required this.userId,
    required this.type,
    required this.entityId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.isCompleted = false,
    this.errorMessage,
  });

  SyncOperation copyWith({
    String? id,
    String? userId,
    SyncOperationType? type,
    String? entityId,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'entity_id': entityId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'is_completed': isCompleted,
      'error_message': errorMessage,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      userId: json['user_id'],
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.createExpense,
      ),
      entityId: json['entity_id'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retry_count'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      errorMessage: json['error_message'],
    );
  }
}

/// Sync conflict types
enum SyncConflictType {
  expense,
  budget,
}

/// Sync conflict data class
class SyncConflict {
  final String id;
  final SyncConflictType type;
  final dynamic localData; // Expense or Budget
  final dynamic remoteData; // Expense or Budget
  final DateTime timestamp;
  final ConflictResolution? resolution;

  SyncConflict({
    required this.id,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
    this.resolution,
  });

  SyncConflict copyWith({
    String? id,
    SyncConflictType? type,
    dynamic localData,
    dynamic remoteData,
    DateTime? timestamp,
    ConflictResolution? resolution,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      type: type ?? this.type,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      timestamp: timestamp ?? this.timestamp,
      resolution: resolution ?? this.resolution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'local_data': _serializeData(localData),
      'remote_data': _serializeData(remoteData),
      'timestamp': timestamp.toIso8601String(),
      'resolution': resolution?.toJson(),
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      type: SyncConflictType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncConflictType.expense,
      ),
      localData: _deserializeData(json['type'], json['local_data']),
      remoteData: _deserializeData(json['type'], json['remote_data']),
      timestamp: DateTime.parse(json['timestamp']),
      resolution: json['resolution'] != null
          ? ConflictResolution.fromJson(json['resolution'])
          : null,
    );
  }

  static Map<String, dynamic> _serializeData(dynamic data) {
    if (data is Expense) return data.toJson();
    if (data is Budget) return data.toJson();
    return {};
  }

  static dynamic _deserializeData(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'expense':
        return Expense.fromJson(data);
      case 'budget':
        return Budget.fromJson(data);
      default:
        return null;
    }
  }
}

/// Conflict resolution actions
enum ConflictAction {
  keepLocal,    // Keep local version
  keepRemote,   // Keep remote version
  merge,        // Merge both versions
  manual,       // Require manual resolution
}

/// Conflict resolution data class
class ConflictResolution {
  final ConflictAction action;
  final dynamic mergedData; // For merge action
  final String? resolutionNote;
  final DateTime resolvedAt;

  ConflictResolution({
    required this.action,
    this.mergedData,
    this.resolutionNote,
    DateTime? resolvedAt,
  }) : resolvedAt = resolvedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'merged_data': mergedData != null ? _serializeData(mergedData) : null,
      'resolution_note': resolutionNote,
      'resolved_at': resolvedAt.toIso8601String(),
    };
  }

  factory ConflictResolution.fromJson(Map<String, dynamic> json) {
    return ConflictResolution(
      action: ConflictAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ConflictAction.manual,
      ),
      mergedData: json['merged_data'] != null
          ? _deserializeData(json['merged_data'])
          : null,
      resolutionNote: json['resolution_note'],
      resolvedAt: DateTime.parse(json['resolved_at']),
    );
  }

  static Map<String, dynamic> _serializeData(dynamic data) {
    if (data is Expense) return data.toJson();
    if (data is Budget) return data.toJson();
    return {};
  }

  static dynamic _deserializeData(Map<String, dynamic> data) {
    // Try to determine type from data structure
    if (data.containsKey('amount') && data.containsKey('currency')) {
      return Expense.fromJson(data);
    } else if (data.containsKey('target_amount') && data.containsKey('period')) {
      return Budget.fromJson(data);
    }
    return null;
  }
}

/// Sync preferences and settings
class SyncPreferences {
  final bool enableAutoSync;
  final Duration syncInterval;
  final bool syncOnWifiOnly;
  final bool syncImages;
  final ConflictAction defaultConflictAction;
  final int maxRetryAttempts;
  final Duration retryDelay;

  const SyncPreferences({
    this.enableAutoSync = true,
    this.syncInterval = const Duration(minutes: 15),
    this.syncOnWifiOnly = false,
    this.syncImages = true,
    this.defaultConflictAction = ConflictAction.keepLocal,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
  });

  Map<String, dynamic> toJson() {
    return {
      'enable_auto_sync': enableAutoSync,
      'sync_interval_minutes': syncInterval.inMinutes,
      'sync_on_wifi_only': syncOnWifiOnly,
      'sync_images': syncImages,
      'default_conflict_action': defaultConflictAction.name,
      'max_retry_attempts': maxRetryAttempts,
      'retry_delay_seconds': retryDelay.inSeconds,
    };
  }

  factory SyncPreferences.fromJson(Map<String, dynamic> json) {
    return SyncPreferences(
      enableAutoSync: json['enable_auto_sync'] ?? true,
      syncInterval: Duration(minutes: json['sync_interval_minutes'] ?? 15),
      syncOnWifiOnly: json['sync_on_wifi_only'] ?? false,
      syncImages: json['sync_images'] ?? true,
      defaultConflictAction: ConflictAction.values.firstWhere(
        (e) => e.name == json['default_conflict_action'],
        orElse: () => ConflictAction.keepLocal,
      ),
      maxRetryAttempts: json['max_retry_attempts'] ?? 3,
      retryDelay: Duration(seconds: json['retry_delay_seconds'] ?? 30),
    );
  }

  SyncPreferences copyWith({
    bool? enableAutoSync,
    Duration? syncInterval,
    bool? syncOnWifiOnly,
    bool? syncImages,
    ConflictAction? defaultConflictAction,
    int? maxRetryAttempts,
    Duration? retryDelay,
  }) {
    return SyncPreferences(
      enableAutoSync: enableAutoSync ?? this.enableAutoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      syncImages: syncImages ?? this.syncImages,
      defaultConflictAction: defaultConflictAction ?? this.defaultConflictAction,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

/// Sync statistics and metrics
class SyncStatistics {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final int conflictsResolved;
  final int pendingOperations;
  final DateTime lastSyncTime;
  final Duration averageSyncDuration;
  final Map<String, int> syncErrors;

  const SyncStatistics({
    this.totalSyncs = 0,
    this.successfulSyncs = 0,
    this.failedSyncs = 0,
    this.conflictsResolved = 0,
    this.pendingOperations = 0,
    required this.lastSyncTime,
    this.averageSyncDuration = Duration.zero,
    this.syncErrors = const {},
  });

  double get successRate => totalSyncs > 0 ? successfulSyncs / totalSyncs : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'total_syncs': totalSyncs,
      'successful_syncs': successfulSyncs,
      'failed_syncs': failedSyncs,
      'conflicts_resolved': conflictsResolved,
      'pending_operations': pendingOperations,
      'last_sync_time': lastSyncTime.toIso8601String(),
      'average_sync_duration_ms': averageSyncDuration.inMilliseconds,
      'sync_errors': syncErrors,
      'success_rate': successRate,
    };
  }

  factory SyncStatistics.fromJson(Map<String, dynamic> json) {
    return SyncStatistics(
      totalSyncs: json['total_syncs'] ?? 0,
      successfulSyncs: json['successful_syncs'] ?? 0,
      failedSyncs: json['failed_syncs'] ?? 0,
      conflictsResolved: json['conflicts_resolved'] ?? 0,
      pendingOperations: json['pending_operations'] ?? 0,
      lastSyncTime: DateTime.parse(json['last_sync_time'] ?? DateTime.now().toIso8601String()),
      averageSyncDuration: Duration(milliseconds: json['average_sync_duration_ms'] ?? 0),
      syncErrors: Map<String, int>.from(json['sync_errors'] ?? {}),
    );
  }
}
