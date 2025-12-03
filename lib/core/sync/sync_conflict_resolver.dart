import 'package:finwise/core/sync/sync_models.dart';

/// Conflict resolver for handling data synchronization conflicts
abstract class SyncConflictResolver {
  /// Resolve a single conflict
  Future<ConflictResolution> resolveConflict(SyncConflict conflict);

  /// Resolve multiple conflicts in batch
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts);

  /// Get conflict resolution strategy for a given conflict type
  ConflictAction getResolutionStrategy(SyncConflictType type);
}

/// Automatic conflict resolver implementation
class AutomaticConflictResolver implements SyncConflictResolver {
  final ConflictAction defaultAction;

  const AutomaticConflictResolver({
    this.defaultAction = ConflictAction.keepLocal,
  });

  @override
  Future<ConflictResolution> resolveConflict(SyncConflict conflict) async {
    final action = getResolutionStrategy(conflict.type);

    switch (action) {
      case ConflictAction.keepLocal:
        return ConflictResolution(
          action: ConflictAction.keepLocal,
          resolutionNote: 'Automatically kept local version',
        );

      case ConflictAction.keepRemote:
        return ConflictResolution(
          action: ConflictAction.keepRemote,
          resolutionNote: 'Automatically kept remote version',
        );

      case ConflictAction.merge:
        final mergedData = await _mergeData(conflict);
        return ConflictResolution(
          action: ConflictAction.merge,
          mergedData: mergedData,
          resolutionNote: 'Automatically merged versions',
        );

      case ConflictAction.manual:
        // For automatic resolver, fallback to keepLocal
        return ConflictResolution(
          action: ConflictAction.keepLocal,
          resolutionNote: 'Manual resolution required, kept local version',
        );
    }
  }

  @override
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts) async {
    final resolutions = <ConflictResolution>[];

    for (final conflict in conflicts) {
      final resolution = await resolveConflict(conflict);
      resolutions.add(resolution);
    }

    return resolutions;
  }

  @override
  ConflictAction getResolutionStrategy(SyncConflictType type) {
    // Different strategies for different data types
    switch (type) {
      case SyncConflictType.expense:
        return ConflictAction.merge; // Expenses can be merged
      case SyncConflictType.budget:
        return defaultAction; // Budgets usually keep one version
    }
  }

  /// Merge conflicting data automatically
  Future<dynamic> _mergeData(SyncConflict conflict) async {
    if (conflict.type == SyncConflictType.expense) {
      return _mergeExpenses(conflict.localData, conflict.remoteData);
    } else if (conflict.type == SyncConflictType.budget) {
      return _mergeBudgets(conflict.localData, conflict.remoteData);
    }

    return conflict.localData; // Fallback
  }

  /// Merge conflicting expenses
  dynamic _mergeExpenses(dynamic local, dynamic remote) {
    if (local is! Expense || remote is! Expense) return local;

    // Keep the most recently updated fields
    final localTime = local.updatedAt;
    final remoteTime = remote.updatedAt;

    return Expense(
      id: local.id,
      userId: local.userId,
      amount: localTime.isAfter(remoteTime) ? local.amount : remote.amount,
      currency: local.currency,
      description: localTime.isAfter(remoteTime) ? local.description : remote.description,
      category: localTime.isAfter(remoteTime) ? local.category : remote.category,
      date: localTime.isAfter(remoteTime) ? local.date : remote.date,
      createdAt: local.createdAt.isBefore(remote.createdAt) ? local.createdAt : remote.createdAt,
      updatedAt: DateTime.now(),
      isSynced: true,
      note: localTime.isAfter(remoteTime) ? local.note : remote.note,
    );
  }

  /// Merge conflicting budgets
  dynamic _mergeBudgets(dynamic local, dynamic remote) {
    if (local is! Budget || remote is! Budget) return local;

    // For budgets, keep the most recently updated version
    // Budgets are usually not merged due to complexity
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }
}

/// Interactive conflict resolver for manual resolution
class InteractiveConflictResolver implements SyncConflictResolver {
  final Future<ConflictResolution> Function(SyncConflict) onConflict;

  const InteractiveConflictResolver({
    required this.onConflict,
  });

  @override
  Future<ConflictResolution> resolveConflict(SyncConflict conflict) async {
    return await onConflict(conflict);
  }

  @override
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts) async {
    final resolutions = <ConflictResolution>[];

    for (final conflict in conflicts) {
      final resolution = await resolveConflict(conflict);
      resolutions.add(resolution);
    }

    return resolutions;
  }

  @override
  ConflictAction getResolutionStrategy(SyncConflictType type) {
    return ConflictAction.manual;
  }
}

/// Conflict resolver factory
class ConflictResolverFactory {
  static SyncConflictResolver createAutomaticResolver({
    ConflictAction defaultAction = ConflictAction.keepLocal,
  }) {
    return AutomaticConflictResolver(defaultAction: defaultAction);
  }

  static SyncConflictResolver createInteractiveResolver({
    required Future<ConflictResolution> Function(SyncConflict) onConflict,
  }) {
    return InteractiveConflictResolver(onConflict: onConflict);
  }

  static SyncConflictResolver createHybridResolver({
    ConflictAction defaultAction = ConflictAction.keepLocal,
    required Future<ConflictResolution> Function(SyncConflict) onConflict,
    List<SyncConflictType> interactiveTypes = const [],
  }) {
    return HybridConflictResolver(
      defaultAction: defaultAction,
      onConflict: onConflict,
      interactiveTypes: interactiveTypes,
    );
  }
}

/// Hybrid conflict resolver (automatic + manual for specific types)
class HybridConflictResolver implements SyncConflictResolver {
  final ConflictAction defaultAction;
  final Future<ConflictResolution> Function(SyncConflict) onConflict;
  final List<SyncConflictType> interactiveTypes;

  const HybridConflictResolver({
    required this.defaultAction,
    required this.onConflict,
    required this.interactiveTypes,
  });

  @override
  Future<ConflictResolution> resolveConflict(SyncConflict conflict) async {
    if (interactiveTypes.contains(conflict.type)) {
      // Use interactive resolution for specified types
      return await onConflict(conflict);
    } else {
      // Use automatic resolution for other types
      final automaticResolver = AutomaticConflictResolver(defaultAction: defaultAction);
      return await automaticResolver.resolveConflict(conflict);
    }
  }

  @override
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts) async {
    final resolutions = <ConflictResolution>[];

    for (final conflict in conflicts) {
      final resolution = await resolveConflict(conflict);
      resolutions.add(resolution);
    }

    return resolutions;
  }

  @override
  ConflictAction getResolutionStrategy(SyncConflictType type) {
    return interactiveTypes.contains(type)
        ? ConflictAction.manual
        : defaultAction;
  }
}

/// Conflict resolution utilities
class ConflictResolutionUtils {
  /// Suggest resolution based on data analysis
  static ConflictResolution suggestResolution(SyncConflict conflict) {
    if (conflict.type == SyncConflictType.expense) {
      return _suggestExpenseResolution(conflict);
    } else if (conflict.type == SyncConflictType.budget) {
      return _suggestBudgetResolution(conflict);
    }

    return ConflictResolution(
      action: ConflictAction.manual,
      resolutionNote: 'Unable to suggest automatic resolution',
    );
  }

  static ConflictResolution _suggestExpenseResolution(SyncConflict conflict) {
    final local = conflict.localData as Expense;
    final remote = conflict.remoteData as Expense;

    // If amounts differ significantly, require manual resolution
    final amountDiff = (local.amount - remote.amount).abs();
    if (amountDiff > 1000) { // More than $10 difference
      return ConflictResolution(
        action: ConflictAction.manual,
        resolutionNote: 'Large amount difference requires manual review',
      );
    }

    // If categories differ, merge with most recent update
    if (local.category != remote.category) {
      return ConflictResolution(
        action: ConflictAction.merge,
        mergedData: local.updatedAt.isAfter(remote.updatedAt) ? local : remote,
        resolutionNote: 'Merged with most recent category update',
      );
    }

    // Default to keeping most recently updated
    return ConflictResolution(
      action: local.updatedAt.isAfter(remote.updatedAt)
          ? ConflictAction.keepLocal
          : ConflictAction.keepRemote,
      resolutionNote: 'Kept most recently updated version',
    );
  }

  static ConflictResolution _suggestBudgetResolution(SyncConflict conflict) {
    final local = conflict.localData as Budget;
    final remote = conflict.remoteData as Budget;

    // Budget conflicts usually require manual resolution
    // as they affect spending limits and tracking
    return ConflictResolution(
      action: ConflictAction.manual,
      resolutionNote: 'Budget conflicts require manual review to ensure accurate tracking',
    );
  }

  /// Validate conflict resolution
  static bool isValidResolution(SyncConflict conflict, ConflictResolution resolution) {
    switch (resolution.action) {
      case ConflictAction.keepLocal:
      case ConflictAction.keepRemote:
        return true; // Always valid

      case ConflictAction.merge:
        return resolution.mergedData != null;

      case ConflictAction.manual:
        return true; // Manual resolution is always valid
    }
  }

  /// Get conflict severity level
  static ConflictSeverity getConflictSeverity(SyncConflict conflict) {
    if (conflict.type == SyncConflictType.expense) {
      final local = conflict.localData as Expense;
      final remote = conflict.remoteData as Expense;

      final amountDiff = (local.amount - remote.amount).abs();
      if (amountDiff > 5000) return ConflictSeverity.high; // Over $50 difference
      if (amountDiff > 1000) return ConflictSeverity.medium; // Over $10 difference
      return ConflictSeverity.low;
    }

    // Budget conflicts are generally high severity
    return ConflictSeverity.high;
  }
}

/// Conflict severity levels
enum ConflictSeverity {
  low,
  medium,
  high,
}

/// Conflict analysis utilities
class ConflictAnalysis {
  /// Analyze conflict patterns
  static Map<String, dynamic> analyzeConflicts(List<SyncConflict> conflicts) {
    final analysis = {
      'total_conflicts': conflicts.length,
      'by_type': <String, int>{},
      'by_severity': <String, int>{},
      'most_conflicted_fields': <String, int>{},
      'time_distribution': <String, int>{},
    };

    for (final conflict in conflicts) {
      // Count by type
      analysis['by_type'][conflict.type.name] =
          (analysis['by_type'][conflict.type.name] ?? 0) + 1;

      // Count by severity
      final severity = ConflictResolutionUtils.getConflictSeverity(conflict);
      analysis['by_severity'][severity.name] =
          (analysis['by_severity'][severity.name] ?? 0) + 1;

      // Analyze time patterns
      final hour = conflict.timestamp.hour;
      final timeSlot = '${hour ~/ 6 * 6}-${(hour ~/ 6 + 1) * 6}'; // 6-hour slots
      analysis['time_distribution'][timeSlot] =
          (analysis['time_distribution'][timeSlot] ?? 0) + 1;
    }

    return analysis;
  }

  /// Get conflict resolution recommendations
  static List<String> getRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <String>[];

    final totalConflicts = analysis['total_conflicts'] as int;
    if (totalConflicts > 10) {
      recommendations.add('High conflict rate detected. Consider adjusting sync frequency.');
    }

    final highSeverity = analysis['by_severity']['high'] ?? 0;
    if (highSeverity > totalConflicts * 0.3) {
      recommendations.add('Many high-severity conflicts. Review data validation rules.');
    }

    final expenseConflicts = analysis['by_type']['expense'] ?? 0;
    if (expenseConflicts > totalConflicts * 0.8) {
      recommendations.add('Most conflicts are expense-related. Consider expense-specific resolution rules.');
    }

    return recommendations;
  }
}
