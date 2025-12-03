import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/credit_score.dart';
import '../../data/repositories/credit_repository.dart';

/// State for credit dashboard
class CreditDashboardState {
  final List<CreditScore> scores;
  final bool isLoading;
  final String? error;
  final Map<CreditBureau, bool> connectionStatus;
  final DateTime lastUpdated;

  const CreditDashboardState({
    required this.scores,
    required this.isLoading,
    required this.connectionStatus,
    this.error,
    required this.lastUpdated,
  });

  CreditDashboardState copyWith({
    List<CreditScore>? scores,
    bool? isLoading,
    String? error,
    Map<CreditBureau, bool>? connectionStatus,
    DateTime? lastUpdated,
  }) {
    return CreditDashboardState(
      scores: scores ?? this.scores,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  CreditScore? get primaryScore {
    if (scores.isEmpty) return null;

    // Prefer TransUnion, then Equifax, then Experian
    return scores.firstWhere(
      (score) => score.bureau == 'TransUnion',
      orElse: () => scores.firstWhere(
        (score) => score.bureau == 'Equifax',
        orElse: () => scores.first,
      ),
    );
  }

  double get averageScore {
    if (scores.isEmpty) return 0.0;
    final total = scores.fold<double>(0, (sum, score) => sum + score.score);
    return total / scores.length;
  }

  CreditScoreRange get scoreRange {
    final primary = primaryScore;
    return primary?.range ?? CreditScoreRange.fico;
  }

  bool get hasExcellentScore => primaryScore?.isExcellent ?? false;
  bool get hasGoodScore => primaryScore?.isGood ?? false;
  bool get hasFairScore => primaryScore?.isFair ?? false;
  bool get hasPoorScore => primaryScore?.isPoor ?? false;

  String get scoreLabel => primaryScore?.scoreLabel ?? 'Loading...';
}

/// Notifier for credit dashboard state
class CreditDashboardNotifier extends StateNotifier<CreditDashboardState> {
  final CreditRepository _repository;
  final String _userId;

  CreditDashboardNotifier(this._repository, this._userId)
      : super(const CreditDashboardState(
          scores: [],
          isLoading: true,
          connectionStatus: {},
          lastUpdated: DateTime.now(),
        )) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load connection status
      final connectionResult = await _repository.getConnectionStatus(userId: _userId);
      final connectionStatus = connectionResult.fold(
        (failure) => <CreditBureau, bool>{},
        (status) => status,
      );

      // Load credit scores from connected bureaus
      final scores = <CreditScore>[];
      for (final bureau in CreditBureau.values) {
        if (connectionStatus[bureau] == true) {
          final scoreResult = await _repository.getCreditScore(
            bureau: bureau,
            userId: _userId,
          );

          scoreResult.fold(
            (failure) => null, // Skip failed bureaus
            (score) => scores.add(score),
          );
        }
      }

      state = state.copyWith(
        scores: scores,
        isLoading: false,
        connectionStatus: connectionStatus,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> refreshScores() async {
    await loadDashboard();
  }

  Future<void> connectBureau(CreditBureau bureau) async {
    // This would typically open a web view or OAuth flow
    // For now, we'll just refresh the connection status
    await loadDashboard();
  }

  Future<void> disconnectBureau(CreditBureau bureau) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.disconnectCreditBureau(
      bureau: bureau,
      userId: _userId,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (_) {
        // Remove the bureau from scores and update connection status
        final updatedScores = state.scores
            .where((score) => score.bureau != bureau.name)
            .toList();

        final updatedConnections = Map<CreditBureau, bool>.from(state.connectionStatus);
        updatedConnections[bureau] = false;

        state = state.copyWith(
          scores: updatedScores,
          connectionStatus: updatedConnections,
          isLoading: false,
        );
      },
    );
  }
}

/// State for credit report details
class CreditReportState {
  final CreditReport? report;
  final bool isLoading;
  final String? error;

  const CreditReportState({
    this.report,
    required this.isLoading,
    this.error,
  });

  CreditReportState copyWith({
    CreditReport? report,
    bool? isLoading,
    String? error,
  }) {
    return CreditReportState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for credit report state
class CreditReportNotifier extends StateNotifier<CreditReportState> {
  final CreditRepository _repository;
  final String _userId;
  final CreditBureau _bureau;

  CreditReportNotifier(this._repository, this._userId, this._bureau)
      : super(const CreditReportState(isLoading: true)) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getCreditReport(
        bureau: _bureau,
        userId: _userId,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (report) {
          state = state.copyWith(
            report: report,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshReport() async {
    await loadReport();
  }
}

/// Providers
final creditDashboardProvider = StateNotifierProvider<CreditDashboardNotifier, CreditDashboardState>((ref) {
  final repository = ref.watch(creditRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CreditDashboardNotifier(repository, userId);
});

final creditReportProvider = StateNotifierProvider.family<CreditReportNotifier, CreditReportState, CreditBureau>((ref, bureau) {
  final repository = ref.watch(creditRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CreditReportNotifier(repository, userId, bureau);
});

/// Helper providers
final primaryCreditScoreProvider = Provider<CreditScore?>((ref) {
  final state = ref.watch(creditDashboardProvider);
  return state.primaryScore;
});

final creditScoreAverageProvider = Provider<double>((ref) {
  final state = ref.watch(creditDashboardProvider);
  return state.averageScore;
});

final creditConnectionStatusProvider = Provider<Map<CreditBureau, bool>>((ref) {
  final state = ref.watch(creditDashboardProvider);
  return state.connectionStatus;
});

final creditScoreRangeProvider = Provider<CreditScoreRange>((ref) {
  final state = ref.watch(creditDashboardProvider);
  return state.scoreRange;
});

/// Mock providers for development
final mockCreditDashboardProvider = StateNotifierProvider<CreditDashboardNotifier, CreditDashboardState>((ref) {
  final repository = ref.watch(mockCreditRepositoryProvider);
  return CreditDashboardNotifier(repository, 'mock-user-id');
});

final mockCreditRepositoryProvider = Provider<CreditRepository>((ref) {
  final api = ref.watch(mockCreditBureauApiProvider);
  final storage = ref.watch(secureStorageProvider);
  return CreditRepository(api, storage);
});

final mockCreditBureauApiProvider = Provider<CreditBureauApi>((ref) {
  final client = ref.watch(httpClientProvider);
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return MockCreditBureauApi(client, secureStorage);
});

/// Current user ID provider (would come from auth system)
final currentUserIdProvider = Provider<String>((ref) {
  // In a real app, this would come from the auth system
  return 'user-123';
});

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Flutter Secure Storage provider
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Secure storage service provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
