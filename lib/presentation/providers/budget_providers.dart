import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/usecases/budget_usecases.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Use Case Providers
final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return getIt<CreateBudgetUseCase>();
});

final getBudgetsUseCaseProvider = Provider<GetBudgetsUseCase>((ref) {
  return getIt<GetBudgetsUseCase>();
});

final getActiveBudgetsWithProgressUseCaseProvider = Provider<GetActiveBudgetsWithProgressUseCase>((ref) {
  return getIt<GetActiveBudgetsWithProgressUseCase>();
});

final updateBudgetProgressUseCaseProvider = Provider<UpdateBudgetProgressUseCase>((ref) {
  return getIt<UpdateBudgetProgressUseCase>();
});

final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return getIt<UpdateBudgetUseCase>();
});

final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>((ref) {
  return getIt<DeleteBudgetUseCase>();
});

// Budget State Providers
final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<Budget>>>((ref) {
  final getBudgetsUseCase = ref.watch(getBudgetsUseCaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  return BudgetsNotifier(getBudgetsUseCase, currentUser?.id);
});

final activeBudgetsWithProgressProvider = FutureProvider<List<BudgetProgress>>((ref) {
  final getActiveBudgetsUseCase = ref.watch(getActiveBudgetsWithProgressUseCaseProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return Future.value([]);

  return getActiveBudgetsUseCase(GetActiveBudgetsParams(userId: currentUser.id))
      .then((result) => result.fold(
            (failure) => throw Exception(failure.message),
            (progress) => progress,
          ));
});

final budgetAlertsProvider = FutureProvider<List<BudgetAlert>>((ref) {
  // TODO: Implement budget alerts
  return Future.value([]);
});

// Budget Creation Provider
final createBudgetProvider = FutureProvider.family<void, Budget>((ref, budget) async {
  final createBudgetUseCase = ref.watch(createBudgetUseCaseProvider);

  final result = await createBudgetUseCase(CreateBudgetParams(budget: budget));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

// Budget Update Provider
final updateBudgetProvider = FutureProvider.family<void, Budget>((ref, updatedBudget) async {
  final updateBudgetUseCase = ref.watch(updateBudgetUseCaseProvider);

  final result = await updateBudgetUseCase(UpdateBudgetParams(updatedBudget: updatedBudget));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

// Budget Deletion Provider
final deleteBudgetProvider = FutureProvider.family<void, String>((ref, budgetId) async {
  final deleteBudgetUseCase = ref.watch(deleteBudgetUseCaseProvider);

  final result = await deleteBudgetUseCase(DeleteBudgetParams(budgetId: budgetId));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

// Budget Progress Update Provider (called when expenses change)
final updateBudgetProgressProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final budgetId = params['budgetId'] as String;
  final spentAmount = params['spentAmount'] as int;

  final updateProgressUseCase = ref.watch(updateBudgetProgressUseCaseProvider);

  final result = await updateProgressUseCase(UpdateBudgetProgressParams(
    budgetId: budgetId,
    spentAmount: spentAmount,
  ));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

// Budget Summary Provider
final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final activeProgressAsync = ref.watch(activeBudgetsWithProgressProvider);

  return budgetsAsync.maybeWhen(
    data: (budgets) {
      final activeProgress = activeProgressAsync.maybeWhen(
        data: (progress) => progress,
        orElse: () => <BudgetProgress>[],
      );

      final totalBudgets = budgets.length;
      final activeBudgets = budgets.where((b) => b.isActive).length;
      final totalBudgeted = budgets.fold<int>(0, (sum, b) => sum + b.targetAmount);
      final totalSpent = activeProgress.fold<int>(0, (sum, p) => sum + p.budget.spentAmount);

      final onTrack = activeProgress.where((p) => p.status == BudgetStatus.onTrack).length;
      final warning = activeProgress.where((p) => p.status == BudgetStatus.warning).length;
      final overBudget = activeProgress.where((p) => p.status == BudgetStatus.overBudget).length;

      return BudgetSummary(
        totalBudgets: totalBudgets,
        activeBudgets: activeBudgets,
        totalBudgeted: totalBudgeted,
        totalSpent: totalSpent,
        onTrack: onTrack,
        warning: warning,
        overBudget: overBudget,
      );
    },
    orElse: () => BudgetSummary.empty(),
  );
});

// Notifiers
class BudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final GetBudgetsUseCase _getBudgetsUseCase;
  final String? _userId;

  BudgetsNotifier(this._getBudgetsUseCase, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadBudgets();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadBudgets() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    final result = await _getBudgetsUseCase(GetBudgetsParams(userId: _userId!));

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (budgets) => AsyncValue.data(budgets),
    );
  }

  Future<void> refreshBudgets() async {
    await loadBudgets();
  }
}

// Data Classes
class BudgetSummary {
  final int totalBudgets;
  final int activeBudgets;
  final int totalBudgeted;
  final int totalSpent;
  final int onTrack;
  final int warning;
  final int overBudget;

  const BudgetSummary({
    required this.totalBudgets,
    required this.activeBudgets,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.onTrack,
    required this.warning,
    required this.overBudget,
  });

  factory BudgetSummary.empty() {
    return const BudgetSummary(
      totalBudgets: 0,
      activeBudgets: 0,
      totalBudgeted: 0,
      totalSpent: 0,
      onTrack: 0,
      warning: 0,
      overBudget: 0,
    );
  }

  double get utilizationPercentage {
    if (totalBudgeted == 0) return 0.0;
    return (totalSpent / totalBudgeted) * 100;
  }

  String get formattedTotalBudgeted {
    final amountInDollars = totalBudgeted / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  String get formattedTotalSpent {
    final amountInDollars = totalSpent / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }
}

// Computed Providers for Budget Analysis
final budgetPerformanceProvider = Provider.family<BudgetPerformance?, String>((ref, budgetId) {
  final budgetsAsync = ref.watch(budgetsProvider);

  return budgetsAsync.maybeWhen(
    data: (budgets) {
      final budget = budgets.firstWhere((b) => b.id == budgetId);
      final progress = ref.watch(activeBudgetsWithProgressProvider).maybeWhen(
        data: (progressList) => progressList.firstWhere(
          (p) => p.budget.id == budgetId,
          orElse: () => BudgetProgress.fromBudget(budget),
        ),
        orElse: () => BudgetProgress.fromBudget(budget),
      );

      // Calculate performance metrics
      final adherenceRate = budget.targetAmount > 0
          ? ((budget.targetAmount - budget.spentAmount) / budget.targetAmount) * 100
          : 0.0;

      return BudgetPerformance(
        budget: budget,
        adherenceRate: adherenceRate.clamp(0.0, 100.0),
        checkpoints: [], // TODO: Implement checkpoints
        insights: BudgetInsights(
          recommendations: _generateRecommendations(budget, progress),
          warnings: _generateWarnings(budget, progress),
          projectedOverspend: _calculateProjectedOverspend(budget),
          overspendingCategories: [], // TODO: Implement category analysis
          savingsPotential: _calculateSavingsPotential(budget),
        ),
      );
    },
    orElse: () => null,
  );
});

List<String> _generateRecommendations(Budget budget, BudgetProgress progress) {
  final recommendations = <String>[];

  if (progress.percentage > 80) {
    recommendations.add('Consider reducing spending in the remaining days');
  }

  if (budget.categories.length > 3) {
    recommendations.add('Try consolidating similar budget categories');
  }

  if (budget.period == BudgetPeriod.monthly && budget.targetAmount > 500000) { // $5000
    recommendations.add('Consider breaking large monthly budgets into weekly targets');
  }

  return recommendations;
}

List<String> _generateWarnings(Budget budget, BudgetProgress progress) {
  final warnings = <String>[];

  if (progress.status == BudgetStatus.overBudget) {
    warnings.add('You have exceeded your budget limit');
  } else if (progress.status == BudgetStatus.warning) {
    warnings.add('You are approaching your budget limit');
  }

  if (budget.daysRemaining < 3 && progress.percentage > 90) {
    warnings.add('Budget period ending soon - monitor spending closely');
  }

  return warnings;
}

double _calculateProjectedOverspend(Budget budget) {
  if (budget.daysRemaining == 0) return 0.0;

  final daysPassed = budget.period == BudgetPeriod.monthly ? 15 : 7; // Estimate
  final dailySpendingRate = budget.spentAmount / daysPassed;
  final projectedTotal = dailySpendingRate * (daysPassed + budget.daysRemaining);

  return (projectedTotal - budget.targetAmount).clamp(0.0, double.infinity);
}

double _calculateSavingsPotential(Budget budget) {
  // Estimate potential savings based on category averages
  final category = budget.categories.isNotEmpty ? budget.categories.first : ExpenseCategory.other;

  // Simplified calculation - in real app, use historical data
  final averageSavings = {
    ExpenseCategory.food: 0.15, // 15% potential savings
    ExpenseCategory.transportation: 0.20,
    ExpenseCategory.entertainment: 0.25,
    ExpenseCategory.shopping: 0.10,
  };

  final savingsRate = averageSavings[category] ?? 0.10;
  return budget.targetAmount * savingsRate;
}
