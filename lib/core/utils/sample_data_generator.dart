import 'package:finwise/domain/entities/expense.dart';
import 'package:uuid/uuid.dart';

/// Utility class for generating sample data for development and testing
/// Creates realistic expense data to demonstrate app functionality
class SampleDataGenerator {
  static const String _sampleUserId = 'sample_user_123';
  static final _uuid = Uuid();

  /// Generate a list of sample expenses
  static List<Expense> generateSampleExpenses({int count = 10}) {
    final expenses = <Expense>[];
    final now = DateTime.now();

    // Sample expense data
    final sampleData = [
      {'description': 'Grocery shopping at Whole Foods', 'amount': 87.50, 'category': ExpenseCategory.food, 'daysAgo': 0},
      {'description': 'Gas station fill-up', 'amount': 45.20, 'category': ExpenseCategory.transportation, 'daysAgo': 1},
      {'description': 'Movie tickets and popcorn', 'amount': 28.75, 'category': ExpenseCategory.entertainment, 'daysAgo': 2},
      {'description': 'Coffee and breakfast', 'amount': 12.99, 'category': ExpenseCategory.food, 'daysAgo': 3},
      {'description': 'New running shoes', 'amount': 129.99, 'category': ExpenseCategory.shopping, 'daysAgo': 4},
      {'description': 'Electricity bill', 'amount': 89.45, 'category': ExpenseCategory.bills, 'daysAgo': 5},
      {'description': 'Uber ride to airport', 'amount': 23.50, 'category': ExpenseCategory.transportation, 'daysAgo': 6},
      {'description': 'Doctor visit co-pay', 'amount': 25.00, 'category': ExpenseCategory.healthcare, 'daysAgo': 7},
      {'description': 'Online course subscription', 'amount': 29.99, 'category': ExpenseCategory.education, 'daysAgo': 8},
      {'description': 'Weekend brunch', 'amount': 42.30, 'category': ExpenseCategory.food, 'daysAgo': 9},
      {'description': 'Bus pass renewal', 'amount': 75.00, 'category': ExpenseCategory.transportation, 'daysAgo': 10},
      {'description': 'Streaming service subscription', 'amount': 15.99, 'category': ExpenseCategory.entertainment, 'daysAgo': 11},
      {'description': 'Haircut and styling', 'amount': 65.00, 'category': ExpenseCategory.personal, 'daysAgo': 12},
      {'description': 'Phone bill', 'amount': 52.30, 'category': ExpenseCategory.bills, 'daysAgo': 13},
      {'description': 'Gifts for birthday party', 'amount': 78.45, 'category': ExpenseCategory.shopping, 'daysAgo': 14},
    ];

    // Generate expenses from sample data
    for (var i = 0; i < count && i < sampleData.length; i++) {
      final data = sampleData[i];
      final expenseDate = now.subtract(Duration(days: data['daysAgo'] as int));

      expenses.add(Expense(
        id: _uuid.v4(),
        userId: _sampleUserId,
        amount: ((data['amount'] as double) * 100).round(), // Convert to cents
        currency: 'USD',
        description: data['description'] as String,
        category: data['category'] as ExpenseCategory,
        date: expenseDate,
        createdAt: expenseDate,
        updatedAt: expenseDate,
        isSynced: true,
      ));
    }

    return expenses;
  }

  /// Generate sample expenses for specific categories
  static List<Expense> generateExpensesByCategory(ExpenseCategory category, {int count = 5}) {
    final baseDescriptions = _getCategoryDescriptions(category);
    final expenses = <Expense>[];
    final now = DateTime.now();

    for (var i = 0; i < count && i < baseDescriptions.length; i++) {
      final amount = _getRandomAmountForCategory(category);
      final expenseDate = now.subtract(Duration(days: i * 2));

      expenses.add(Expense(
        id: _uuid.v4(),
        userId: _sampleUserId,
        amount: (amount * 100).round(),
        currency: 'USD',
        description: baseDescriptions[i],
        category: category,
        date: expenseDate,
        createdAt: expenseDate,
        updatedAt: expenseDate,
        isSynced: true,
      ));
    }

    return expenses;
  }

  /// Get sample descriptions for a category
  static List<String> _getCategoryDescriptions(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return [
          'Lunch at local cafe',
          'Grocery shopping',
          'Dinner at restaurant',
          'Coffee and pastry',
          'Weekly groceries',
          'Fast food meal',
          'Farmers market produce',
        ];
      case ExpenseCategory.transportation:
        return [
          'Gas station fill-up',
          'Bus fare',
          'Uber ride',
          'Train ticket',
          'Parking fee',
          'Car maintenance',
          'Taxi ride',
        ];
      case ExpenseCategory.entertainment:
        return [
          'Movie tickets',
          'Concert tickets',
          'Streaming subscription',
          'Video game purchase',
          'Bowling night',
          'Museum admission',
          'Sports event',
        ];
      case ExpenseCategory.shopping:
        return [
          'Clothing purchase',
          'Electronics item',
          'Home goods',
          'Gift purchase',
          'Book purchase',
          'Online shopping',
          'Department store',
        ];
      case ExpenseCategory.bills:
        return [
          'Electricity bill',
          'Water bill',
          'Internet bill',
          'Phone bill',
          'Rent payment',
          'Insurance premium',
          'Cable bill',
        ];
      case ExpenseCategory.healthcare:
        return [
          'Doctor visit',
          'Pharmacy prescription',
          'Dental checkup',
          'Medical test',
          'Therapy session',
          'Health insurance',
          'Medical supplies',
        ];
      case ExpenseCategory.education:
        return [
          'Online course',
          'Textbook purchase',
          'Tutoring session',
          'Certification exam',
          'Educational software',
          'Workshop fee',
          'School supplies',
        ];
      case ExpenseCategory.travel:
        return [
          'Flight tickets',
          'Hotel booking',
          'Car rental',
          'Travel insurance',
          'Tour guide fee',
          'Airport parking',
          'Travel souvenirs',
        ];
      case ExpenseCategory.personal:
        return [
          'Haircut and styling',
          'Cosmetics purchase',
          'Spa treatment',
          'Gym membership',
          'Personal care items',
          'Clothing alteration',
          'Jewelry purchase',
        ];
      case ExpenseCategory.other:
        return [
          'Miscellaneous expense',
          'Unexpected cost',
          'One-time purchase',
          'Unspecified item',
          'Various expenses',
          'Other costs',
          'Additional expense',
        ];
    }
  }

  /// Generate random amount based on category
  static double _getRandomAmountForCategory(ExpenseCategory category) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    switch (category) {
      case ExpenseCategory.food:
        return 5.0 + (random % 50); // $5-$55
      case ExpenseCategory.transportation:
        return 2.0 + (random % 80); // $2-$82
      case ExpenseCategory.entertainment:
        return 10.0 + (random % 100); // $10-$110
      case ExpenseCategory.shopping:
        return 15.0 + (random % 200); // $15-$215
      case ExpenseCategory.bills:
        return 20.0 + (random % 300); // $20-$320
      case ExpenseCategory.healthcare:
        return 10.0 + (random % 200); // $10-$210
      case ExpenseCategory.education:
        return 25.0 + (random % 500); // $25-$525
      case ExpenseCategory.travel:
        return 50.0 + (random % 1000); // $50-$1050
      case ExpenseCategory.personal:
        return 8.0 + (random % 150); // $8-$158
      case ExpenseCategory.other:
        return 1.0 + (random % 100); // $1-$101
    }
  }

  /// Generate sample budget data
  static Map<String, dynamic> generateSampleBudgetData() {
    return {
      'monthly_budget': 3000.00, // $3,000 monthly budget
      'categories': {
        'food': 600.00,
        'transportation': 300.00,
        'entertainment': 200.00,
        'shopping': 400.00,
        'bills': 800.00,
        'healthcare': 200.00,
        'other': 500.00,
      },
      'spending_goals': {
        'save_20_percent': true,
        'reduce_eating_out': true,
        'cut_subscription_services': false,
      },
    };
  }
}
