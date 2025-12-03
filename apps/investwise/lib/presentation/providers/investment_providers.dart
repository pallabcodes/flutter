import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/models/investment_models.dart';
import '../../data/repositories/investment_repository.dart';

/// State for investment portfolio
class InvestmentPortfolioState {
  final InvestmentPortfolio? portfolio;
  final bool isLoading;
  final String? error;
  final bool needsRefresh;

  const InvestmentPortfolioState({
    this.portfolio,
    required this.isLoading,
    this.error,
    required this.needsRefresh,
  });

  InvestmentPortfolioState copyWith({
    InvestmentPortfolio? portfolio,
    bool? isLoading,
    String? error,
    bool? needsRefresh,
  }) {
    return InvestmentPortfolioState(
      portfolio: portfolio ?? this.portfolio,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      needsRefresh: needsRefresh ?? this.needsRefresh,
    );
  }

  double get totalValue => portfolio?.totalValue ?? 0.0;
  double get totalGainLoss => portfolio?.totalGainLoss ?? 0.0;
  double get totalGainLossPercent => portfolio?.totalGainLossPercent ?? 0.0;
  double get diversificationScore => portfolio?.diversificationScore ?? 0.0;
  double get riskScore => portfolio?.riskScore ?? 0.0;
}

/// Notifier for investment portfolio state
class InvestmentPortfolioNotifier extends StateNotifier<InvestmentPortfolioState> {
  final InvestmentRepository _repository;
  final String _userId;

  InvestmentPortfolioNotifier(this._repository, this._userId)
      : super(const InvestmentPortfolioState(
          isLoading: true,
          needsRefresh: false,
        )) {
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    state = state.copyWith(isLoading: true, error: null, needsRefresh: false);

    try {
      final result = await _repository.getPortfolio(userId: _userId);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (portfolio) {
          state = state.copyWith(
            portfolio: portfolio,
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

  Future<void> refreshPortfolio() async {
    await loadPortfolio();
  }

  Future<void> buyAsset({
    required String assetId,
    required double amount,
  }) async {
    if (state.portfolio == null) return;

    final result = await _repository.buyAsset(
      portfolioId: state.portfolio!.id,
      assetId: assetId,
      amount: amount,
      userId: _userId,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (transaction) => loadPortfolio(), // Refresh to show updated portfolio
    );
  }

  Future<void> sellAsset({
    required String assetId,
    required double shares,
  }) async {
    if (state.portfolio == null) return;

    final result = await _repository.sellAsset(
      portfolioId: state.portfolio!.id,
      assetId: assetId,
      shares: shares,
      userId: _userId,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (transaction) => loadPortfolio(), // Refresh to show updated portfolio
    );
  }

  Future<void> processMicroInvestment({
    required double amount,
    required String strategy,
  }) async {
    if (state.portfolio == null) return;

    final result = await _repository.processMicroInvestment(
      portfolioId: state.portfolio!.id,
      amount: amount,
      strategy: strategy,
      userId: _userId,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (transaction) => loadPortfolio(), // Refresh to show updated portfolio
    );
  }

  Future<void> createPortfolio({
    required String name,
  }) async {
    final portfolio = InvestmentPortfolio(
      id: 'portfolio_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId,
      name: name,
      totalValue: 0.0,
      totalCost: 0.0,
      totalGainLoss: 0.0,
      totalGainLossPercent: 0.0,
      holdings: [],
      goals: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.createPortfolio(portfolio: portfolio);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (savedPortfolio) => state = state.copyWith(portfolio: savedPortfolio),
    );
  }
}

/// State for market data
class MarketDataState {
  final Map<String, MarketData> marketData;
  final bool isLoading;
  final String? error;

  const MarketDataState({
    required this.marketData,
    required this.isLoading,
    this.error,
  });

  MarketDataState copyWith({
    Map<String, MarketData>? marketData,
    bool? isLoading,
    String? error,
  }) {
    return MarketDataState(
      marketData: marketData ?? this.marketData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  MarketData? getMarketData(String symbol) => marketData[symbol];
}

/// Notifier for market data state
class MarketDataNotifier extends StateNotifier<MarketDataState> {
  final InvestmentRepository _repository;

  MarketDataNotifier(this._repository)
      : super(const MarketDataState(
          marketData: {},
          isLoading: false,
        ));

  Future<void> loadMarketData(List<String> symbols) async {
    state = state.copyWith(isLoading: true, error: null);

    final updatedData = Map<String, MarketData>.from(state.marketData);

    for (final symbol in symbols) {
      try {
        final result = await _repository.getMarketData(symbol: symbol);
        result.fold(
          (failure) => null, // Skip failed symbols
          (data) => updatedData[symbol] = data,
        );
      } catch (e) {
        // Continue with other symbols
      }
    }

    state = state.copyWith(
      marketData: updatedData,
      isLoading: false,
    );
  }

  Future<void> refreshMarketData(String symbol) async {
    final result = await _repository.getMarketData(symbol: symbol);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (data) {
        final updatedData = Map<String, MarketData>.from(state.marketData);
        updatedData[symbol] = data;
        state = state.copyWith(marketData: updatedData);
      },
    );
  }
}

/// State for investment goals
class InvestmentGoalsState {
  final List<InvestmentGoal> goals;
  final bool isLoading;
  final String? error;

  const InvestmentGoalsState({
    required this.goals,
    required this.isLoading,
    this.error,
  });

  InvestmentGoalsState copyWith({
    List<InvestmentGoal>? goals,
    bool? isLoading,
    String? error,
  }) {
    return InvestmentGoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalSaved => goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
  double get totalTarget => goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
  double get overallProgress => totalTarget > 0 ? totalSaved / totalTarget : 0.0;

  List<InvestmentGoal> get activeGoals => goals.where((g) => !g.isExpired).toList();
  List<InvestmentGoal> get completedGoals => goals.where((g) => g.progressPercent >= 1.0).toList();
  List<InvestmentGoal> get overdueGoals => goals.where((g) => g.isExpired && g.progressPercent < 1.0).toList();
}

/// Notifier for investment goals state
class InvestmentGoalsNotifier extends StateNotifier<InvestmentGoalsState> {
  final InvestmentRepository _repository;
  final String _userId;

  InvestmentGoalsNotifier(this._repository, this._userId)
      : super(const InvestmentGoalsState(
          goals: [],
          isLoading: true,
        )) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getGoals(userId: _userId);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (goals) {
          state = state.copyWith(
            goals: goals,
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

  Future<void> createGoal(InvestmentGoal goal) async {
    final result = await _repository.createGoal(goal: goal);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (savedGoal) {
        final updatedGoals = [...state.goals, savedGoal];
        state = state.copyWith(goals: updatedGoals);
      },
    );
  }

  Future<void> updateGoalProgress({
    required String goalId,
    required double additionalAmount,
  }) async {
    final result = await _repository.updateGoalProgress(
      goalId: goalId,
      additionalAmount: additionalAmount,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updatedGoal) {
        final updatedGoals = state.goals.map((goal) =>
          goal.id == updatedGoal.id ? updatedGoal : goal
        ).toList();
        state = state.copyWith(goals: updatedGoals);
      },
    );
  }
}

/// State for micro-investment settings
class MicroInvestmentState {
  final MicroInvestmentSettings? settings;
  final bool isLoading;
  final String? error;

  const MicroInvestmentState({
    this.settings,
    required this.isLoading,
    this.error,
  });

  MicroInvestmentState copyWith({
    MicroInvestmentSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return MicroInvestmentState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isEnabled => settings?.isEnabled ?? false;
  double get dailyLimit => settings?.dailyLimit ?? 10.0;
  double get roundUpAmount => settings?.roundUpAmount ?? 1.0;
  String get investmentStrategy => settings?.investmentStrategy ?? 'balanced';
}

/// Notifier for micro-investment state
class MicroInvestmentNotifier extends StateNotifier<MicroInvestmentState> {
  final InvestmentRepository _repository;
  final String _userId;

  MicroInvestmentNotifier(this._repository, this._userId)
      : super(const MicroInvestmentState(isLoading: true)) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getMicroInvestmentSettings(userId: _userId);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (settings) {
          state = state.copyWith(
            settings: settings,
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

  Future<void> updateSettings(MicroInvestmentSettings settings) async {
    final result = await _repository.updateMicroInvestmentSettings(settings: settings);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updatedSettings) => state = state.copyWith(settings: updatedSettings),
    );
  }

  Future<void> toggleMicroInvestment(bool enabled) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(
      isEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await updateSettings(updatedSettings);
  }

  Future<void> updateStrategy(String strategy) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(
      investmentStrategy: strategy,
      updatedAt: DateTime.now(),
    );

    await updateSettings(updatedSettings);
  }

  Future<void> updateLimits({
    double? dailyLimit,
    double? roundUpAmount,
  }) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(
      dailyLimit: dailyLimit ?? state.settings!.dailyLimit,
      roundUpAmount: roundUpAmount ?? state.settings!.roundUpAmount,
      updatedAt: DateTime.now(),
    );

    await updateSettings(updatedSettings);
  }
}

/// Providers
final investmentPortfolioProvider = StateNotifierProvider<InvestmentPortfolioNotifier, InvestmentPortfolioState>((ref) {
  final repository = ref.watch(investmentRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return InvestmentPortfolioNotifier(repository, userId);
});

final marketDataProvider = StateNotifierProvider<MarketDataNotifier, MarketDataState>((ref) {
  final repository = ref.watch(investmentRepositoryProvider);
  return MarketDataNotifier(repository);
});

final investmentGoalsProvider = StateNotifierProvider<InvestmentGoalsNotifier, InvestmentGoalsState>((ref) {
  final repository = ref.watch(investmentRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return InvestmentGoalsNotifier(repository, userId);
});

final microInvestmentProvider = StateNotifierProvider<MicroInvestmentNotifier, MicroInvestmentState>((ref) {
  final repository = ref.watch(investmentRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return MicroInvestmentNotifier(repository, userId);
});

/// Helper providers
final portfolioHoldingsProvider = Provider<List<PortfolioHolding>>((ref) {
  final portfolioState = ref.watch(investmentPortfolioProvider);
  return portfolioState.portfolio?.holdings ?? [];
});

final activeGoalsProvider = Provider<List<InvestmentGoal>>((ref) {
  final goalsState = ref.watch(investmentGoalsProvider);
  return goalsState.activeGoals;
});

final portfolioPerformanceProvider = FutureProvider<PortfolioPerformance>((ref) async {
  final portfolioState = ref.watch(investmentPortfolioProvider);
  final repository = ref.watch(investmentRepositoryProvider);

  if (portfolioState.portfolio == null) {
    throw Exception('No portfolio available');
  }

  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 365));

  final result = await repository.calculatePerformance(
    portfolio: portfolioState.portfolio!,
    startDate: startDate,
    endDate: endDate,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (performance) => performance,
  );
});

final trendingInvestmentsProvider = FutureProvider<List<TrendingInvestment>>((ref) async {
  final repository = ref.watch(investmentRepositoryProvider);

  final result = await repository.getTrendingInvestments(limit: 10);
  return result.fold(
    (failure) => [],
    (trending) => trending,
  );
});

/// Current user ID provider
final currentUserIdProvider = Provider<String>((ref) {
  // In a real app, this would come from the auth system
  return 'user_123';
});

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Mock providers for development
final mockInvestmentPortfolioProvider = StateNotifierProvider<InvestmentPortfolioNotifier, InvestmentPortfolioState>((ref) {
  final repository = ref.watch(mockInvestmentRepositoryProvider);
  return InvestmentPortfolioNotifier(repository, 'mock-user-id');
});

final mockMarketDataProvider = StateNotifierProvider<MarketDataNotifier, MarketDataState>((ref) {
  final repository = ref.watch(mockInvestmentRepositoryProvider);
  return MarketDataNotifier(repository);
});
