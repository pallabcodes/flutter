import 'package:finwise/core/utils/sample_data_generator.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/usecases/create_expense_usecase.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for seeding sample data into the app
final sampleDataProvider = FutureProvider<void>((ref) async {
  // Check if we already have expenses
  final expensesAsync = await ref.read(expensesProvider.future);
  final expenses = expensesAsync.maybeWhen(
    data: (data) => data,
    orElse: () => <Expense>[],
  );

  // If no expenses exist, seed sample data
  if (expenses.isEmpty) {
    final sampleExpenses = SampleDataGenerator.generateSampleExpenses(count: 12);
    final createExpenseUseCase = ref.read(createExpenseUseCaseProvider);

    // Add expenses one by one
    for (final expense in sampleExpenses) {
      final result = await createExpenseUseCase(CreateExpenseParams(expense: expense));
      result.fold(
        (failure) {
          // Log error but continue with other expenses
          print('Failed to seed sample expense: ${failure.message}');
        },
        (_) {
          // Successfully added expense
        },
      );
    }

    // Refresh the expenses list
    ref.invalidate(expensesProvider);
  }
});

/// Provider to check if sample data should be seeded
final shouldSeedSampleDataProvider = FutureProvider<bool>((ref) async {
  final expensesAsync = await ref.read(expensesProvider.future);
  final expenses = expensesAsync.maybeWhen(
    data: (data) => data,
    orElse: () => <Expense>[],
  );

  return expenses.isEmpty;
});
