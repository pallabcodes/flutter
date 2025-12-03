import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:finwise/core/analytics/analytics_service.dart';
import 'package:finwise/core/security/secure_storage.dart';

/// Enhanced push notification service with rich media, analytics, and smart scheduling
class EnhancedNotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;
  final AnalyticsService _analytics;

  // Notification channels for different types
  static const String _financialChannel = 'financial_alerts';
  static const String _socialChannel = 'social_notifications';
  static const String _systemChannel = 'system_notifications';
  static const String _marketingChannel = 'marketing_notifications';

  final StreamController<NotificationEvent> _notificationController =
      StreamController<NotificationEvent>.broadcast();

  Timer? _smartScheduleTimer;
  Map<String, NotificationAnalytics> _notificationAnalytics = {};

  EnhancedNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseMessaging? firebaseMessaging,
    AnalyticsService? analytics,
  })  : _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _analytics = analytics ?? AnalyticsService();

  /// Initialize the enhanced notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _loadNotificationAnalytics();
    _startSmartScheduling();
  }

  /// Send rich media notification with images
  Future<void> sendRichMediaNotification({
    required String title,
    required String body,
    required String imageUrl,
    required String userId,
    String? deepLink,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Download and save image
      final imageFile = await _downloadAndSaveImage(imageUrl);

      if (imageFile == null) {
        // Fallback to regular notification if image download fails
        return sendBasicNotification(
          title: title,
          body: body,
          userId: userId,
          deepLink: deepLink,
          priority: priority,
          data: data,
        );
      }

      // Create rich notification
      final bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(imageFile.path),
        contentTitle: title,
        summaryText: body,
        largeIcon: FilePathAndroidBitmap(imageFile.path),
      );

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _financialChannel,
          'Financial Alerts',
          channelDescription: 'Important financial notifications',
          styleInformation: bigPictureStyle,
          importance: _mapPriorityToImportance(priority),
          priority: _mapPriorityToAndroidPriority(priority),
          color: const Color(0xFF2196F3),
          ledColor: const Color(0xFF2196F3),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableLights: true,
          enableVibration: true,
          fullScreenIntent: priority == NotificationPriority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          attachments: [
            DarwinNotificationAttachment(imageFile.path),
          ],
          interruptionLevel: _mapPriorityToInterruptionLevel(priority),
        ),
      );

      final notificationId = await _generateNotificationId('rich_media', userId);

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: _createPayload(deepLink, data),
      );

      // Track analytics
      await _trackNotificationSent(notificationId, 'rich_media', userId, priority);

    } catch (e) {
      // Fallback to basic notification
      await sendBasicNotification(
        title: title,
        body: body,
        userId: userId,
        deepLink: deepLink,
        priority: priority,
        data: data,
      );
    }
  }

  /// Send location-based notification
  Future<void> sendLocationBasedNotification({
    required String userId,
    required String locationName,
    required String locationType, // 'bank', 'atm', 'grocery', etc.
    required double distance,
    String? specialOffer,
    Map<String, dynamic>? locationData,
  }) async {
    final title = 'Nearby ${locationType == 'bank' ? 'Bank' : locationType == 'atm' ? 'ATM' : 'Location'}';
    final body = '${locationName} is ${distance.toStringAsFixed(1)} miles away'
        '${specialOffer != null ? '. $specialOffer' : ''}';

    final data = {
      'type': 'location_based',
      'locationName': locationName,
      'locationType': locationType,
      'distance': distance,
      'coordinates': locationData?['coordinates'],
      ...?locationData,
    };

    await sendRichMediaNotification(
      title: title,
      body: body,
      imageUrl: await _getLocationImageUrl(locationType),
      userId: userId,
      deepLink: 'finwise://location/${locationName.toLowerCase().replaceAll(' ', '_')}',
      data: data,
      priority: NotificationPriority.normal,
    );
  }

  /// Send smart financial insight notification
  Future<void> sendFinancialInsight({
    required String userId,
    required String insightType, // 'saving_opportunity', 'spending_alert', 'goal_progress'
    required String title,
    required String insight,
    required double impact, // potential savings or impact
    String? recommendation,
    Map<String, dynamic>? insightData,
  }) async {
    final body = '${insight}${recommendation != null ? '. $recommendation' : ''}';

    final data = {
      'type': 'financial_insight',
      'insightType': insightType,
      'impact': impact,
      'insightData': insightData,
    };

    final imageUrl = await _getInsightImageUrl(insightType);

    await sendRichMediaNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      userId: userId,
      deepLink: 'finwise://insights/${insightType}',
      data: data,
      priority: impact > 100 ? NotificationPriority.high : NotificationPriority.normal,
    );
  }

  /// Schedule smart notifications based on user behavior
  Future<void> scheduleSmartNotifications(String userId) async {
    // Analyze user behavior patterns
    final behaviorPatterns = await _analytics.getUserBehaviorPatterns(userId);
    final optimalTimes = await _calculateOptimalNotificationTimes(userId, behaviorPatterns);

    // Cancel existing smart notifications
    await cancelSmartNotifications(userId);

    for (final timeSlot in optimalTimes) {
      await _scheduleNotificationForTimeSlot(userId, timeSlot);
    }
  }

  /// Send A/B test notifications
  Future<void> sendABTestNotification({
    required String userId,
    required String experimentId,
    required String variant,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final testData = {
      ...?data,
      'experimentId': experimentId,
      'variant': variant,
      'ab_test': true,
    };

    if (imageUrl != null) {
      await sendRichMediaNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
        userId: userId,
        data: testData,
      );
    } else {
      await sendBasicNotification(
        title: title,
        body: body,
        userId: userId,
        data: testData,
      );
    }
  }

  /// Send personalized recommendation notification
  Future<void> sendPersonalizedRecommendation({
    required String userId,
    required String category, // 'investment', 'saving', 'budget', 'credit'
    required String recommendation,
    required double confidence, // 0-1
    String? imageUrl,
    Map<String, dynamic>? recommendationData,
  }) async {
    final title = _getRecommendationTitle(category);
    final body = '$recommendation (${(confidence * 100).toInt()}% confidence)';

    final data = {
      'type': 'personalized_recommendation',
      'category': category,
      'confidence': confidence,
      'recommendationData': recommendationData,
    };

    final finalImageUrl = imageUrl ?? await _getRecommendationImageUrl(category);

    await sendRichMediaNotification(
      title: title,
      body: body,
      imageUrl: finalImageUrl,
      userId: userId,
      deepLink: 'finwise://recommendations/${category}',
      data: data,
      priority: confidence > 0.8 ? NotificationPriority.high : NotificationPriority.normal,
    );
  }

  /// Track notification interaction for analytics
  Future<void> trackNotificationInteraction({
    required String notificationId,
    required NotificationAction action,
    required String userId,
    Map<String, dynamic>? additionalData,
  }) async {
    // Update local analytics
    final analytics = _notificationAnalytics[notificationId];
    if (analytics != null) {
      final updatedAnalytics = analytics.copyWith(
        interactions: [...analytics.interactions, NotificationInteraction(
          action: action,
          timestamp: DateTime.now(),
          data: additionalData,
        )],
      );
      _notificationAnalytics[notificationId] = updatedAnalytics;
      await _saveNotificationAnalytics();
    }

    // Send to analytics service
    await _analytics.trackNotificationInteraction(
      notificationId: notificationId,
      action: action.name,
      userId: userId,
      additionalData: additionalData,
    );

    // Emit event
    _notificationController.add(NotificationEvent.interaction(
      notificationId: notificationId,
      action: action,
      userId: userId,
      data: additionalData,
    ));
  }

  /// Get notification analytics
  NotificationAnalytics? getNotificationAnalytics(String notificationId) {
    return _notificationAnalytics[notificationId];
  }

  /// Get notification performance metrics
  Future<NotificationPerformanceMetrics> getPerformanceMetrics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final analytics = _notificationAnalytics.values.where((a) =>
      a.userId == userId &&
      (startDate == null || a.sentAt.isAfter(startDate)) &&
      (endDate == null || a.sentAt.isBefore(endDate))
    );

    final totalSent = analytics.length;
    final totalInteractions = analytics.fold<int>(0, (sum, a) => sum + a.interactions.length);
    final openRate = totalSent > 0 ? totalInteractions / totalSent : 0.0;

    final interactionTypes = <NotificationAction, int>{};
    for (final analytic in analytics) {
      for (final interaction in analytic.interactions) {
        interactionTypes[interaction.action] = (interactionTypes[interaction.action] ?? 0) + 1;
      }
    }

    return NotificationPerformanceMetrics(
      totalSent: totalSent,
      totalInteractions: totalInteractions,
      openRate: openRate,
      interactionBreakdown: interactionTypes,
      timeRange: DateTimeRange(start: startDate ?? DateTime.now().subtract(const Duration(days: 30)), end: endDate ?? DateTime.now()),
    );
  }

  /// Cancel smart notifications for user
  Future<void> cancelSmartNotifications(String userId) async {
    // Cancel all scheduled notifications for this user
    final scheduledIds = await _getScheduledNotificationIds(userId);
    for (final id in scheduledIds) {
      await _localNotifications.cancel(id);
    }
  }

  /// Request notification permissions with detailed handling
  Future<NotificationPermissionResult> requestDetailedPermissions() async {
    final androidResult = await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    final iosResult = await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
          provisional: false,
          carPlay: false,
        );

    final granted = (androidResult ?? false) || ((iosResult?.alert ?? false) || (iosResult?.sound ?? false));

    return NotificationPermissionResult(
      granted: granted,
      androidGranted: androidResult ?? false,
      iosAlertGranted: iosResult?.alert ?? false,
      iosBadgeGranted: iosResult?.badge ?? false,
      iosSoundGranted: iosResult?.sound ?? false,
      iosCriticalGranted: iosResult?.critical ?? false,
    );
  }

  // Private methods
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    await _createNotificationChannels();
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      critical: true,
      provisional: false,
      carPlay: false,
    );

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await SecureStorage.storeFCMToken(fcmToken);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      SecureStorage.storeFCMToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _createNotificationChannels() async {
    const financialChannel = AndroidNotificationChannel(
      _financialChannel,
      'Financial Alerts',
      description: 'Important financial notifications and insights',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF2196F3),
    );

    const socialChannel = AndroidNotificationChannel(
      _socialChannel,
      'Social Notifications',
      description: 'Friend activities and social features',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: true,
    );

    const systemChannel = AndroidNotificationChannel(
      _systemChannel,
      'System Notifications',
      description: 'App updates and system messages',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    const marketingChannel = AndroidNotificationChannel(
      _marketingChannel,
      'Marketing & Offers',
      description: 'Promotional offers and marketing messages',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(financialChannel);
    await androidPlugin?.createNotificationChannel(socialChannel);
    await androidPlugin?.createNotificationChannel(systemChannel);
    await androidPlugin?.createNotificationChannel(marketingChannel);
  }

  Future<File?> _downloadAndSaveImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final directory = await getTemporaryDirectory();
      final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadNotificationAnalytics() async {
    final stored = await SecureStorage.getNotificationAnalytics();
    if (stored != null) {
      _notificationAnalytics = Map<String, NotificationAnalytics>.fromEntries(
        stored.map((key, value) => MapEntry(key, NotificationAnalytics.fromJson(value))),
      );
    }
  }

  Future<void> _saveNotificationAnalytics() async {
    final data = _notificationAnalytics.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await SecureStorage.storeNotificationAnalytics(data);
  }

  void _startSmartScheduling() {
    _smartScheduleTimer = Timer.periodic(const Duration(hours: 1), (_) {
      // Refresh smart notifications for all active users
      // This would be implemented based on user activity
    });
  }

  // Helper methods for content generation
  Future<String> _getLocationImageUrl(String locationType) async {
    // Return appropriate image URL based on location type
    switch (locationType) {
      case 'bank': return 'https://example.com/bank_icon.png';
      case 'atm': return 'https://example.com/atm_icon.png';
      case 'grocery': return 'https://example.com/grocery_icon.png';
      default: return 'https://example.com/location_icon.png';
    }
  }

  Future<String> _getInsightImageUrl(String insightType) async {
    switch (insightType) {
      case 'saving_opportunity': return 'https://example.com/saving_icon.png';
      case 'spending_alert': return 'https://example.com/spending_icon.png';
      case 'goal_progress': return 'https://example.com/goal_icon.png';
      default: return 'https://example.com/insight_icon.png';
    }
  }

  String _getRecommendationTitle(String category) {
    switch (category) {
      case 'investment': return 'Investment Opportunity';
      case 'saving': return 'Saving Tip';
      case 'budget': return 'Budget Insight';
      case 'credit': return 'Credit Recommendation';
      default: return 'Personalized Recommendation';
    }
  }

  Future<String> _getRecommendationImageUrl(String category) async {
    switch (category) {
      case 'investment': return 'https://example.com/investment_icon.png';
      case 'saving': return 'https://example.com/saving_icon.png';
      case 'budget': return 'https://example.com/budget_icon.png';
      case 'credit': return 'https://example.com/credit_icon.png';
      default: return 'https://example.com/recommendation_icon.png';
    }
  }

  // Event handlers
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    // Handle iOS local notification
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload, response.actionId);
    }
  }

  void _onBackgroundNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload, response.actionId);
    }
  }

  void _handleNotificationPayload(String payload, String? actionId) {
    try {
      final data = jsonDecode(payload);
      final notificationId = data['notificationId'];

      final action = actionId == 'dismiss' ? NotificationAction.dismissed :
                   actionId == 'snooze' ? NotificationAction.snoozed :
                   NotificationAction.opened;

      trackNotificationInteraction(
        notificationId: notificationId,
        action: action,
        userId: data['userId'] ?? 'unknown',
        additionalData: {'actionId': actionId},
      );
    } catch (e) {
      // Handle parse error
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _financialChannel,
            'Financial Alerts',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message processing
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _handleNotificationPayload(jsonEncode(message.data), null);
  }

  // Priority mapping methods
  Importance _mapPriorityToImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min: return Importance.min;
      case NotificationPriority.low: return Importance.low;
      case NotificationPriority.normal: return Importance.defaultImportance;
      case NotificationPriority.high: return Importance.high;
      case NotificationPriority.max: return Importance.max;
    }
  }

  Priority _mapPriorityToAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min: return Priority.min;
      case NotificationPriority.low: return Priority.low;
      case NotificationPriority.normal: return Priority.defaultPriority;
      case NotificationPriority.high: return Priority.high;
      case NotificationPriority.max: return Priority.max;
    }
  }

  InterruptionLevel _mapPriorityToInterruptionLevel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min: return InterruptionLevel.passive;
      case NotificationPriority.low: return InterruptionLevel.passive;
      case NotificationPriority.normal: return InterruptionLevel.active;
      case NotificationPriority.high: return InterruptionLevel.timeSensitive;
      case NotificationPriority.max: return InterruptionLevel.critical;
    }
  }

  // Utility methods
  Future<int> _generateNotificationId(String type, String userId) async {
    return '$type$userId${DateTime.now().millisecondsSinceEpoch}'.hashCode.abs();
  }

  String _createPayload(String? deepLink, Map<String, dynamic>? data) {
    return jsonEncode({
      'deepLink': deepLink,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _trackNotificationSent(
    int notificationId,
    String type,
    String userId,
    NotificationPriority priority,
  ) async {
    final analytics = NotificationAnalytics(
      notificationId: notificationId.toString(),
      type: type,
      userId: userId,
      priority: priority,
      sentAt: DateTime.now(),
      interactions: [],
    );

    _notificationAnalytics[notificationId.toString()] = analytics;
    await _saveNotificationAnalytics();
  }

  // Placeholder methods (would be implemented based on real analytics)
  Future<List<DateTime>> _calculateOptimalNotificationTimes(String userId, dynamic behaviorPatterns) async {
    // Return some default optimal times
    return [
      DateTime.now().add(const Duration(hours: 2)), // Evening
      DateTime.now().add(const Duration(hours: 8)), // Next morning
    ];
  }

  Future<void> _scheduleNotificationForTimeSlot(String userId, DateTime timeSlot) async {
    // Implementation would schedule actual notifications
  }

  Future<List<int>> _getScheduledNotificationIds(String userId) async {
    // Return list of scheduled notification IDs for user
    return [];
  }

  Future<void> sendBasicNotification({
    required String title,
    required String body,
    required String userId,
    String? deepLink,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    final notificationId = await _generateNotificationId('basic', userId);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _financialChannel,
          'Financial Alerts',
          importance: _mapPriorityToImportance(priority),
          priority: _mapPriorityToAndroidPriority(priority),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _createPayload(deepLink, data),
    );

    await _trackNotificationSent(notificationId, 'basic', userId, priority);
  }

  // Stream access
  Stream<NotificationEvent> get notificationEvents => _notificationController.stream;

  void dispose() {
    _smartScheduleTimer?.cancel();
    _notificationController.close();
  }
}

// Supporting classes and enums
enum NotificationPriority { min, low, normal, high, max }

enum NotificationAction { opened, dismissed, snoozed, interacted }

class NotificationEvent {
  final String type;
  final Map<String, dynamic> data;

  NotificationEvent(this.type, this.data);

  factory NotificationEvent.interaction({
    required String notificationId,
    required NotificationAction action,
    required String userId,
    Map<String, dynamic>? data,
  }) {
    return NotificationEvent('interaction', {
      'notificationId': notificationId,
      'action': action.name,
      'userId': userId,
      'data': data,
    });
  }
}

class NotificationAnalytics {
  final String notificationId;
  final String type;
  final String userId;
  final NotificationPriority priority;
  final DateTime sentAt;
  final List<NotificationInteraction> interactions;

  const NotificationAnalytics({
    required this.notificationId,
    required this.type,
    required this.userId,
    required this.priority,
    required this.sentAt,
    required this.interactions,
  });

  NotificationAnalytics copyWith({
    List<NotificationInteraction>? interactions,
  }) {
    return NotificationAnalytics(
      notificationId: notificationId,
      type: type,
      userId: userId,
      priority: priority,
      sentAt: sentAt,
      interactions: interactions ?? this.interactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type,
      'userId': userId,
      'priority': priority.name,
      'sentAt': sentAt.toIso8601String(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
    };
  }

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      notificationId: json['notificationId'],
      type: json['type'],
      userId: json['userId'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      sentAt: DateTime.parse(json['sentAt']),
      interactions: (json['interactions'] as List<dynamic>?)
          ?.map((i) => NotificationInteraction.fromJson(i))
          .toList() ?? [],
    );
  }
}

class NotificationInteraction {
  final NotificationAction action;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const NotificationInteraction({
    required this.action,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationInteraction.fromJson(Map<String, dynamic> json) {
    return NotificationInteraction(
      action: NotificationAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => NotificationAction.opened,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
    );
  }
}

class NotificationPerformanceMetrics {
  final int totalSent;
  final int totalInteractions;
  final double openRate;
  final Map<NotificationAction, int> interactionBreakdown;
  final DateTimeRange timeRange;

  const NotificationPerformanceMetrics({
    required this.totalSent,
    required this.totalInteractions,
    required this.openRate,
    required this.interactionBreakdown,
    required this.timeRange,
  });
}

class NotificationPermissionResult {
  final bool granted;
  final bool androidGranted;
  final bool iosAlertGranted;
  final bool iosBadgeGranted;
  final bool iosSoundGranted;
  final bool iosCriticalGranted;

  const NotificationPermissionResult({
    required this.granted,
    required this.androidGranted,
    required this.iosAlertGranted,
    required this.iosBadgeGranted,
    required this.iosSoundGranted,
    required this.iosCriticalGranted,
  });
}
