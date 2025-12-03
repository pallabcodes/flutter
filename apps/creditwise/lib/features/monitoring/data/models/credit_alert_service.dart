import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../data/models/credit_score.dart';

/// Service for managing credit-related push notifications and alerts
class CreditAlertService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;

  // Notification channels for different types of alerts
  static const String _scoreChangesChannel = 'score_changes';
  static const String _utilizationAlertsChannel = 'utilization_alerts';
  static const String _paymentRemindersChannel = 'payment_reminders';
  static const String _generalAlertsChannel = 'general_alerts';

  CreditAlertService(this._localNotifications, this._firebaseMessaging) {
    _initializeNotifications();
    _setupFirebaseMessaging();
  }

  /// Initialize local notifications with proper channels
  void _initializeNotifications() {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create notification channels for Android
    _createNotificationChannels();
  }

  /// Create Android notification channels
  void _createNotificationChannels() {
    const scoreChangesChannel = AndroidNotificationChannel(
      _scoreChangesChannel,
      'Credit Score Changes',
      description: 'Notifications when your credit score changes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2196F3),
    );

    const utilizationAlertsChannel = AndroidNotificationChannel(
      _utilizationAlertsChannel,
      'Credit Utilization Alerts',
      description: 'Alerts when credit utilization is too high',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const paymentRemindersChannel = AndroidNotificationChannel(
      _paymentRemindersChannel,
      'Payment Reminders',
      description: 'Reminders for upcoming credit card payments',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: true,
    );

    const generalAlertsChannel = AndroidNotificationChannel(
      _generalAlertsChannel,
      'Credit Alerts',
      description: 'General credit monitoring alerts',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    );

    _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(scoreChangesChannel);

    _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(utilizationAlertsChannel);

    _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentRemindersChannel);

    _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalAlertsChannel);
  }

  /// Set up Firebase messaging for push notifications
  void _setupFirebaseMessaging() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Send notification for credit score changes
  Future<void> sendScoreChangeAlert({
    required int oldScore,
    required int newScore,
    required String bureau,
    required String userId,
  }) async {
    final change = newScore - oldScore;
    final isPositive = change > 0;

    final title = isPositive ? 'Credit Score Increased!' : 'Credit Score Changed';
    final body = '${bureau}: ${isPositive ? '+' : ''}$change points (${newScore})';

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _scoreChangesChannel,
        'Credit Score Changes',
        channelDescription: 'Notifications when your credit score changes',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF2196F3),
        ledColor: const Color(0xFF2196F3),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      ),
    );

    await _localNotifications.show(
      _generateNotificationId('score_change', userId),
      title,
      body,
      notificationDetails,
      payload: 'score_change:$bureau:$newScore:$oldScore',
    );
  }

  /// Send alert for high credit utilization
  Future<void> sendUtilizationAlert({
    required String accountName,
    required double utilization,
    required double limit,
    required String userId,
  }) async {
    if (utilization < 0.8) return; // Only alert for utilization above 80%

    final title = 'High Credit Utilization';
    final body = '$accountName utilization is ${utilization.toStringAsFixed(1)}%. '
        'Consider paying down balances to improve your score.';

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _utilizationAlertsChannel,
        'Credit Utilization Alerts',
        channelDescription: 'Alerts when credit utilization is too high',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFFF9800),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      _generateNotificationId('utilization', userId),
      title,
      body,
      notificationDetails,
      payload: 'utilization:$accountName:$utilization:$limit',
    );
  }

  /// Send payment reminder notifications
  Future<void> sendPaymentReminder({
    required String accountName,
    required DateTime dueDate,
    required double amount,
    required String userId,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0 || daysUntilDue > 7) return; // Only remind for upcoming week

    final title = daysUntilDue == 0
        ? 'Payment Due Today'
        : 'Payment Due Soon';

    final body = daysUntilDue == 0
        ? '\$${amount.toStringAsFixed(2)} payment for $accountName is due today.'
        : '\$${amount.toStringAsFixed(2)} payment for $accountName due in $daysUntilDue day${daysUntilDue > 1 ? 's' : ''}.';

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _paymentRemindersChannel,
        'Payment Reminders',
        channelDescription: 'Reminders for upcoming credit card payments',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF4CAF50),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );

    await _localNotifications.show(
      _generateNotificationId('payment', userId),
      title,
      body,
      notificationDetails,
      payload: 'payment:$accountName:$dueDate:$amount',
    );
  }

  /// Send general credit alerts (new recommendations, etc.)
  Future<void> sendGeneralAlert({
    required String title,
    required String body,
    required String type,
    required String userId,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _generalAlertsChannel,
        'Credit Alerts',
        channelDescription: 'General credit monitoring alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );

    await _localNotifications.show(
      _generateNotificationId('general_$type', userId),
      title,
      body,
      notificationDetails,
      payload: 'general:$type',
    );
  }

  /// Schedule recurring credit score check reminders
  Future<void> scheduleScoreCheckReminder({
    required String userId,
    required int reminderFrequencyDays,
  }) async {
    await _localNotifications.cancel(_generateNotificationId('score_check', userId));

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _generalAlertsChannel,
        'Credit Alerts',
        channelDescription: 'General credit monitoring alerts',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.periodicallyShow(
      _generateNotificationId('score_check', userId),
      'Time to Check Your Credit',
      'Monitor your credit score and get new recommendations.',
      RepeatInterval.everyMinute, // In production, use RepeatInterval.weekly
      notificationDetails,
      androidAllowWhileIdle: true,
      payload: 'score_check',
    );
  }

  /// Cancel all notifications for a user
  Future<void> cancelAllNotifications(String userId) async {
    // Cancel local notifications
    await _localNotifications.cancelAll();

    // In a real implementation, you might also want to unsubscribe
    // from Firebase topics or server-side notifications
  }

  /// Handle foreground push messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        _generateNotificationId('firebase', message.messageId ?? 'unknown'),
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _generalAlertsChannel,
            'Credit Alerts',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
    _handleNotificationNavigation(message.data);
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message processing
    // This could include updating cached data, etc.
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationNavigation(_parsePayload(payload));
    }
  }

  /// Handle background notification tap
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle navigation when app is launched from background
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? data['payload']?.split(':')[0];

    switch (type) {
      case 'score_change':
        // Navigate to dashboard
        break;
      case 'utilization':
        // Navigate to accounts screen
        break;
      case 'payment':
        // Navigate to payments screen
        break;
      case 'recommendations':
        // Navigate to recommendations screen
        break;
      case 'score_check':
        // Navigate to score check flow
        break;
    }
  }

  /// Parse notification payload
  Map<String, dynamic> _parsePayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return {'type': payload};

    return {
      'type': parts[0],
      'data': parts.sublist(1),
    };
  }

  /// Generate unique notification ID
  int _generateNotificationId(String type, String userId) {
    return '${type}_$userId'.hashCode.abs();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final androidResult = await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    final iosResult = await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return (androidResult ?? false) || (iosResult ?? false);
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidResult = await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    final iosResult = await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();

    return (androidResult ?? false) || ((iosResult?.alert ?? false) || (iosResult?.sound ?? false));
  }
}

/// Extension methods for credit monitoring
extension CreditMonitoringExtensions on CreditAlertService {
  /// Monitor credit score changes and send alerts
  Future<void> monitorScoreChanges({
    required CreditScore previousScore,
    required CreditScore currentScore,
    required String userId,
  }) async {
    if (previousScore.score != currentScore.score) {
      await sendScoreChangeAlert(
        oldScore: previousScore.score,
        newScore: currentScore.score,
        bureau: currentScore.bureau,
        userId: userId,
      );
    }
  }

  /// Monitor credit utilization across all accounts
  Future<void> monitorCreditUtilization({
    required List<CreditAccount> accounts,
    required String userId,
  }) async {
    for (final account in accounts) {
      if (account.utilization > 0.8) {
        await sendUtilizationAlert(
          accountName: account.name,
          utilization: account.utilization,
          limit: account.creditLimit,
          userId: userId,
        );
      }
    }
  }

  /// Schedule payment reminders for upcoming due dates
  Future<void> schedulePaymentReminders({
    required List<CreditAccount> accounts,
    required String userId,
  }) async {
    final now = DateTime.now();

    for (final account in accounts) {
      final dueDate = account.lastPaymentDate.add(const Duration(days: 25)); // Approximate monthly cycle

      if (dueDate.isAfter(now)) {
        await sendPaymentReminder(
          accountName: account.name,
          dueDate: dueDate,
          amount: account.minimumPayment,
          userId: userId,
        );
      }
    }
  }

  /// Send weekly credit health summary
  Future<void> sendWeeklySummary({
    required CreditScore currentScore,
    required int recommendationCount,
    required String userId,
  }) async {
    final title = 'Weekly Credit Summary';
    final body = 'Your ${currentScore.bureau} score is ${currentScore.score}. '
        'You have $recommendationCount active recommendations.';

    await sendGeneralAlert(
      title: title,
      body: body,
      type: 'weekly_summary',
      userId: userId,
    );
  }
}
