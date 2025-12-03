import 'dart:async';
import 'dart:convert';
import 'package:finwise/core/realtime/websocket_service.dart';
import 'package:finwise/core/sync/sync_repository.dart';
import 'package:finwise/core/notifications/enhanced_notification_service.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';

/// Real-time synchronization service using WebSocket connections
class LiveSyncService {
  final WebSocketService _webSocket;
  final SyncRepository _syncRepository;
  final EnhancedNotificationService _notifications;

  final StreamController<LiveSyncEvent> _syncController =
      StreamController<LiveSyncEvent>.broadcast();

  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _heartbeatTimers = {};

  String? _currentUserId;
  bool _isInitialized = false;

  LiveSyncService({
    required WebSocketService webSocket,
    required SyncRepository syncRepository,
    required EnhancedNotificationService notifications,
  })  : _webSocket = webSocket,
        _syncRepository = syncRepository,
        _notifications = notifications;

  /// Initialize real-time sync
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;
    _isInitialized = true;

    // Connect to WebSocket
    await _webSocket.connect(userId);

    // Subscribe to real-time events
    await _subscribeToRealTimeEvents();

    // Listen for WebSocket events
    _webSocket.events.listen(_handleRealTimeEvent);

    // Listen for connection status changes
    _webSocket.connectionStatus.listen(_handleConnectionStatusChange);

    // Start heartbeat monitoring
    _startHeartbeatMonitoring();
  }

  /// Subscribe to live price updates for investments
  Future<void> subscribeToLivePrices(List<String> symbols) async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'subscribe_prices',
      'symbols': symbols,
      'userId': _currentUserId,
    });

    // Set up price update handler
    final subscription = _syncController.stream
        .where((event) => event.type == LiveSyncEventType.priceUpdate)
        .listen(_handlePriceUpdate);

    _subscriptions['prices'] = subscription;
  }

  /// Subscribe to live credit score updates
  Future<void> subscribeToCreditUpdates() async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'subscribe_credit',
      'userId': _currentUserId,
    });

    final subscription = _syncController.stream
        .where((event) => event.type == LiveSyncEventType.creditUpdate)
        .listen(_handleCreditUpdate);

    _subscriptions['credit'] = subscription;
  }

  /// Subscribe to transaction alerts
  Future<void> subscribeToTransactionAlerts() async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'subscribe_transactions',
      'userId': _currentUserId,
    });

    final subscription = _syncController.stream
        .where((event) => event.type == LiveSyncEventType.transactionAlert)
        .listen(_handleTransactionAlert);

    _subscriptions['transactions'] = subscription;
  }

  /// Send expense update to other devices
  Future<void> broadcastExpenseUpdate(Expense expense, String operation) async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'broadcast_expense',
      'operation': operation,
      'expense': expense.toJson(),
      'userId': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send budget update to other devices
  Future<void> broadcastBudgetUpdate(Budget budget, String operation) async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'broadcast_budget',
      'operation': operation,
      'budget': budget.toJson(),
      'userId': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send investment transaction to other devices
  Future<void> broadcastInvestmentTransaction(Map<String, dynamic> transaction) async {
    if (!_isInitialized) return;

    await _webSocket.sendMessage({
      'action': 'broadcast_investment',
      'transaction': transaction,
      'userId': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get real-time sync events stream
  Stream<LiveSyncEvent> get syncEvents => _syncController.stream;

  /// Check if real-time sync is active
  bool get isRealTimeActive => _webSocket.isConnected;

  /// Disconnect from real-time sync
  Future<void> disconnect() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel heartbeat timers
    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();

    // Disconnect WebSocket
    await _webSocket.disconnect();

    _isInitialized = false;
  }

  // Private methods
  Future<void> _subscribeToRealTimeEvents() async {
    await _webSocket.subscribe([
      'expense_updates',
      'budget_updates',
      'investment_updates',
      'credit_updates',
      'transaction_alerts',
      'price_updates',
      'system_notifications',
    ]);
  }

  void _handleRealTimeEvent(RealTimeEvent event) {
    switch (event.type) {
      case 'expense_update':
        _handleExpenseUpdate(event.data);
        break;
      case 'budget_update':
        _handleBudgetUpdate(event.data);
        break;
      case 'investment_update':
        _handleInvestmentUpdate(event.data);
        break;
      case 'price_update':
        _handlePriceUpdateEvent(event.data);
        break;
      case 'credit_update':
        _handleCreditUpdateEvent(event.data);
        break;
      case 'transaction_alert':
        _handleTransactionAlertEvent(event.data);
        break;
      case 'system_notification':
        _handleSystemNotification(event.data);
        break;
    }
  }

  void _handleConnectionStatusChange(ConnectionStatus status) {
    _syncController.add(LiveSyncEvent.connectionStatus(status));

    if (status.hasError) {
      // Schedule reconnection
      _scheduleReconnection();
    }
  }

  void _handleExpenseUpdate(Map<String, dynamic> data) {
    final expense = Expense.fromJson(data['expense']);
    final operation = data['operation'] as String;
    final sourceUserId = data['userId'] as String;

    // Skip if this is our own update
    if (sourceUserId == _currentUserId) return;

    _syncController.add(LiveSyncEvent.expenseUpdate(expense, operation));

    // Optionally sync with local database
    _syncExpenseWithLocal(expense, operation);
  }

  void _handleBudgetUpdate(Map<String, dynamic> data) {
    final budget = Budget.fromJson(data['budget']);
    final operation = data['operation'] as String;
    final sourceUserId = data['userId'] as String;

    if (sourceUserId == _currentUserId) return;

    _syncController.add(LiveSyncEvent.budgetUpdate(budget, operation));
    _syncBudgetWithLocal(budget, operation);
  }

  void _handleInvestmentUpdate(Map<String, dynamic> data) {
    final sourceUserId = data['userId'] as String;

    if (sourceUserId == _currentUserId) return;

    _syncController.add(LiveSyncEvent.investmentUpdate(data));
  }

  void _handlePriceUpdate(LiveSyncEvent event) {
    if (event.type == LiveSyncEventType.priceUpdate) {
      _syncController.add(event);
    }
  }

  void _handlePriceUpdateEvent(Map<String, dynamic> data) {
    final symbol = data['symbol'] as String;
    final price = data['price'] as double;
    final change = data['change'] as double?;
    final changePercent = data['changePercent'] as double?;
    final volume = data['volume'] as int?;
    final timestamp = DateTime.parse(data['timestamp']);

    _syncController.add(LiveSyncEvent.priceUpdate(
      symbol: symbol,
      price: price,
      change: change,
      changePercent: changePercent,
      volume: volume,
      timestamp: timestamp,
    ));
  }

  void _handleCreditUpdate(LiveSyncEvent event) {
    if (event.type == LiveSyncEventType.creditUpdate) {
      _syncController.add(event);
    }
  }

  void _handleCreditUpdateEvent(Map<String, dynamic> data) {
    final score = data['score'] as int?;
    final bureau = data['bureau'] as String?;
    final change = data['change'] as int?;
    final factors = data['factors'] as List<dynamic>?;

    _syncController.add(LiveSyncEvent.creditUpdate(
      score: score,
      bureau: bureau,
      change: change,
      factors: factors?.cast<Map<String, dynamic>>(),
    ));
  }

  void _handleTransactionAlert(LiveSyncEvent event) {
    if (event.type == LiveSyncEventType.transactionAlert) {
      _syncController.add(event);
    }
  }

  void _handleTransactionAlertEvent(Map<String, dynamic> data) {
    final accountName = data['accountName'] as String;
    final amount = data['amount'] as double;
    final merchant = data['merchant'] as String?;
    final category = data['category'] as String?;
    final timestamp = DateTime.parse(data['timestamp']);

    _syncController.add(LiveSyncEvent.transactionAlert(
      accountName: accountName,
      amount: amount,
      merchant: merchant,
      category: category,
      timestamp: timestamp,
    ));

    // Send push notification
    _sendTransactionNotification(accountName, amount, merchant, category);
  }

  void _handleSystemNotification(Map<String, dynamic> data) {
    final title = data['title'] as String;
    final message = data['message'] as String;
    final type = data['type'] as String?;
    final priority = data['priority'] as String?;

    _syncController.add(LiveSyncEvent.systemNotification(
      title: title,
      message: message,
      type: type,
      priority: priority,
    ));

    // Send system notification
    _sendSystemNotification(title, message, type, priority);
  }

  Future<void> _syncExpenseWithLocal(Expense expense, String operation) async {
    try {
      switch (operation) {
        case 'create':
          await _syncRepository.createExpense(expense);
          break;
        case 'update':
          await _syncRepository.updateExpense(expense);
          break;
        case 'delete':
          await _syncRepository.deleteExpense(expense.id);
          break;
      }
    } catch (e) {
      // Handle sync error - could queue for retry
      _syncController.add(LiveSyncEvent.syncError('Failed to sync expense: $e'));
    }
  }

  Future<void> _syncBudgetWithLocal(Budget budget, String operation) async {
    try {
      switch (operation) {
        case 'create':
          await _syncRepository.createBudget(budget);
          break;
        case 'update':
          await _syncRepository.updateBudget(budget);
          break;
        case 'delete':
          await _syncRepository.deleteBudget(budget.id);
          break;
      }
    } catch (e) {
      _syncController.add(LiveSyncEvent.syncError('Failed to sync budget: $e'));
    }
  }

  Future<void> _sendTransactionNotification(
    String accountName,
    double amount,
    String? merchant,
    String? category,
  ) async {
    if (_currentUserId == null) return;

    final title = 'New Transaction';
    final body = '\$${amount.toStringAsFixed(2)} at ${merchant ?? 'Unknown Merchant'}';

    await _notifications.sendRichMediaNotification(
      title: title,
      body: body,
      imageUrl: 'https://example.com/transaction_icon.png',
      userId: _currentUserId!,
      deepLink: 'finwise://transactions',
      data: {
        'type': 'transaction_alert',
        'accountName': accountName,
        'amount': amount,
        'merchant': merchant,
        'category': category,
      },
      priority: NotificationPriority.normal,
    );
  }

  Future<void> _sendSystemNotification(
    String title,
    String message,
    String? type,
    String? priority,
  ) async {
    if (_currentUserId == null) return;

    final notificationPriority = priority == 'high'
        ? NotificationPriority.high
        : priority == 'low'
            ? NotificationPriority.low
            : NotificationPriority.normal;

    await _notifications.sendBasicNotification(
      title: title,
      body: message,
      userId: _currentUserId!,
      data: {
        'type': 'system_notification',
        'notificationType': type,
        'priority': priority,
      },
      priority: notificationPriority,
    );
  }

  void _startHeartbeatMonitoring() {
    const heartbeatInterval = Duration(minutes: 5);

    _heartbeatTimers['health_check'] = Timer.periodic(heartbeatInterval, (_) {
      if (_webSocket.isConnected) {
        _webSocket.sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _scheduleReconnection() {
    if (_heartbeatTimers.containsKey('reconnect')) return;

    _heartbeatTimers['reconnect'] = Timer(const Duration(seconds: 30), () {
      if (_currentUserId != null && !_webSocket.isConnected) {
        initialize(_currentUserId!);
      }
      _heartbeatTimers.remove('reconnect');
    });
  }

  void dispose() {
    disconnect();
    _syncController.close();
  }
}

/// Live sync event types and data classes
enum LiveSyncEventType {
  connectionStatus,
  expenseUpdate,
  budgetUpdate,
  investmentUpdate,
  priceUpdate,
  creditUpdate,
  transactionAlert,
  systemNotification,
  syncError,
}

class LiveSyncEvent {
  final LiveSyncEventType type;
  final dynamic data;
  final DateTime timestamp;

  LiveSyncEvent(this.type, this.data, [DateTime? timestamp])
      : timestamp = timestamp ?? DateTime.now();

  // Factory constructors for different event types
  factory LiveSyncEvent.connectionStatus(ConnectionStatus status) {
    return LiveSyncEvent(LiveSyncEventType.connectionStatus, status);
  }

  factory LiveSyncEvent.expenseUpdate(Expense expense, String operation) {
    return LiveSyncEvent(LiveSyncEventType.expenseUpdate, {
      'expense': expense,
      'operation': operation,
    });
  }

  factory LiveSyncEvent.budgetUpdate(Budget budget, String operation) {
    return LiveSyncEvent(LiveSyncEventType.budgetUpdate, {
      'budget': budget,
      'operation': operation,
    });
  }

  factory LiveSyncEvent.investmentUpdate(Map<String, dynamic> data) {
    return LiveSyncEvent(LiveSyncEventType.investmentUpdate, data);
  }

  factory LiveSyncEvent.priceUpdate({
    required String symbol,
    required double price,
    double? change,
    double? changePercent,
    int? volume,
    DateTime? timestamp,
  }) {
    return LiveSyncEvent(LiveSyncEventType.priceUpdate, {
      'symbol': symbol,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
    }, timestamp);
  }

  factory LiveSyncEvent.creditUpdate({
    int? score,
    String? bureau,
    int? change,
    List<Map<String, dynamic>>? factors,
  }) {
    return LiveSyncEvent(LiveSyncEventType.creditUpdate, {
      'score': score,
      'bureau': bureau,
      'change': change,
      'factors': factors,
    });
  }

  factory LiveSyncEvent.transactionAlert({
    required String accountName,
    required double amount,
    String? merchant,
    String? category,
    DateTime? timestamp,
  }) {
    return LiveSyncEvent(LiveSyncEventType.transactionAlert, {
      'accountName': accountName,
      'amount': amount,
      'merchant': merchant,
      'category': category,
    }, timestamp);
  }

  factory LiveSyncEvent.systemNotification({
    required String title,
    required String message,
    String? type,
    String? priority,
  }) {
    return LiveSyncEvent(LiveSyncEventType.systemNotification, {
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
    });
  }

  factory LiveSyncEvent.syncError(String error) {
    return LiveSyncEvent(LiveSyncEventType.syncError, error);
  }
}
