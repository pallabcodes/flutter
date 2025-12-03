import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/models/rental_models.dart';
import '../../data/repositories/rental_repository.dart';

/// State for rental dashboard
class RentalDashboardState {
  final List<RentalProperty> properties;
  final bool isLoading;
  final String? error;

  const RentalDashboardState({
    required this.properties,
    required this.isLoading,
    this.error,
  });

  RentalDashboardState copyWith({
    List<RentalProperty>? properties,
    bool? isLoading,
    String? error,
  }) {
    return RentalDashboardState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalMonthlyRent {
    return properties.fold<double>(
      0,
      (sum, property) => sum + property.monthlyRent,
    );
  }

  int get activePropertiesCount {
    return properties.where((p) => p.status == 'active').length;
  }

  int get expiringLeasesCount {
    return properties.where((p) => p.isLeaseExpiringSoon).length;
  }
}

/// Notifier for rental dashboard state
class RentalDashboardNotifier extends StateNotifier<RentalDashboardState> {
  final RentalRepository _repository;
  final String _userId;

  RentalDashboardNotifier(this._repository, this._userId)
      : super(const RentalDashboardState(
          properties: [],
          isLoading: true,
        )) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getRentalProperties(userId: _userId);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (properties) {
          state = state.copyWith(
            properties: properties,
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

  Future<void> addProperty(RentalProperty property) async {
    final result = await _repository.addRentalProperty(property: property);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (newProperty) {
        final updatedProperties = [...state.properties, newProperty];
        state = state.copyWith(properties: updatedProperties);
      },
    );
  }

  Future<void> updateProperty(RentalProperty property) async {
    final result = await _repository.updateRentalProperty(property: property);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updatedProperty) {
        final updatedProperties = state.properties.map((p) =>
          p.id == updatedProperty.id ? updatedProperty : p
        ).toList();
        state = state.copyWith(properties: updatedProperties);
      },
    );
  }

  Future<void> deleteProperty(String propertyId) async {
    final result = await _repository.deleteRentalProperty(propertyId: propertyId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedProperties = state.properties
            .where((p) => p.id != propertyId)
            .toList();
        state = state.copyWith(properties: updatedProperties);
      },
    );
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }
}

/// State for rental payments
class RentalPaymentsState {
  final List<RentPayment> paymentHistory;
  final List<RentPayment> upcomingPayments;
  final bool isLoading;
  final String? error;

  const RentalPaymentsState({
    required this.paymentHistory,
    required this.upcomingPayments,
    required this.isLoading,
    this.error,
  });

  RentalPaymentsState copyWith({
    List<RentPayment>? paymentHistory,
    List<RentPayment>? upcomingPayments,
    bool? isLoading,
    String? error,
  }) {
    return RentalPaymentsState(
      paymentHistory: paymentHistory ?? this.paymentHistory,
      upcomingPayments: upcomingPayments ?? this.upcomingPayments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalPaidThisYear {
    final thisYear = DateTime.now().year;
    return paymentHistory
        .where((p) => p.paidDate?.year == thisYear && p.status == 'paid')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  int get onTimePaymentsCount {
    return paymentHistory.where((p) {
      if (p.paidDate == null) return false;
      return !p.paidDate!.isAfter(p.dueDate.add(const Duration(days: 1)));
    }).length;
  }

  double get onTimePaymentRate {
    if (paymentHistory.isEmpty) return 0.0;
    return onTimePaymentsCount / paymentHistory.length;
  }
}

/// Notifier for rental payments state
class RentalPaymentsNotifier extends StateNotifier<RentalPaymentsState> {
  final RentalRepository _repository;
  final String _userId;

  RentalPaymentsNotifier(this._repository, this._userId)
      : super(const RentalPaymentsState(
          paymentHistory: [],
          upcomingPayments: [],
          isLoading: true,
        )) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load payment history
      final historyResult = await _repository.getPaymentHistory(
        propertyId: '', // Would need to aggregate across properties
        limit: 24,
      );

      // Load upcoming payments
      final upcomingResult = await _repository.getUpcomingPayments(
        userId: _userId,
        daysAhead: 90,
      );

      final paymentHistory = historyResult.fold(
        (failure) => <RentPayment>[],
        (payments) => payments,
      );

      final upcomingPayments = upcomingResult.fold(
        (failure) => <RentPayment>[],
        (payments) => payments,
      );

      state = state.copyWith(
        paymentHistory: paymentHistory,
        upcomingPayments: upcomingPayments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> processPayment({
    required RentalProperty property,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    final result = await _repository.processRentPayment(
      property: property,
      amount: amount,
      method: method,
      notes: notes,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (paymentResult) {
        // Refresh payments to show the new payment
        loadPayments();
      },
    );
  }

  Future<void> scheduleRecurringPayment({
    required RentalProperty property,
    required PaymentMethod method,
    required DateTime startDate,
  }) async {
    final result = await _repository.scheduleRecurringPayments(
      property: property,
      method: method,
      startDate: startDate,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => loadPayments(), // Refresh to show scheduled payments
    );
  }
}

/// Providers
final rentalDashboardProvider = StateNotifierProvider<RentalDashboardNotifier, RentalDashboardState>((ref) {
  final repository = ref.watch(rentalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return RentalDashboardNotifier(repository, userId);
});

final rentalPaymentsProvider = StateNotifierProvider<RentalPaymentsNotifier, RentalPaymentsState>((ref) {
  final repository = ref.watch(rentalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return RentalPaymentsNotifier(repository, userId);
});

/// Helper providers
final upcomingPaymentsProvider = FutureProvider<List<RentPayment>>((ref) async {
  final repository = ref.watch(rentalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  final result = await repository.getUpcomingPayments(userId: userId);
  return result.fold(
    (failure) => [],
    (payments) => payments,
  );
});

final monthlyHousingExpensesProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(rentalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  final result = await repository.calculateMonthlyHousingExpenses(
    userId: userId,
    month: DateTime.now(),
  );
  return result.fold(
    (failure) => 0.0,
    (expenses) => expenses,
  );
});

/// Current user ID provider (would come from auth system)
final currentUserIdProvider = Provider<String>((ref) {
  // In a real app, this would come from the auth system
  return 'user_123';
});

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Mock providers for development
final mockRentalDashboardProvider = StateNotifierProvider<RentalDashboardNotifier, RentalDashboardState>((ref) {
  final repository = ref.watch(mockRentalRepositoryProvider);
  return RentalDashboardNotifier(repository, 'mock-user-id');
});

final mockRentalPaymentsProvider = StateNotifierProvider<RentalPaymentsNotifier, RentalPaymentsState>((ref) {
  final repository = ref.watch(mockRentalRepositoryProvider);
  return RentalPaymentsNotifier(repository, 'mock-user-id');
});
