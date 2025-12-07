import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:finwise/core/config/environments.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Advanced analytics and user behavior tracking service
/// Enterprise-grade analytics with privacy compliance
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  bool _firebaseAvailable = false;

  /// Initialize Firebase analytics (optional)
  void _initFirebase() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _firebaseAvailable = true;
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        print('Firebase Analytics not available: $e');
      }
    }
  }

  final Map<String, dynamic> _userProperties = {};
  final Map<String, Experiment> _activeExperiments = {};
  final StreamController<AnalyticsEvent> _eventController =
      StreamController<AnalyticsEvent>.broadcast();

  bool _isEnabled = true;
  bool _hasConsent = false;

  /// Initialize analytics service
  Future<void> initialize() async {
    _initFirebase();
    
    // Check user consent
    _hasConsent = await _checkAnalyticsConsent();

    if (_hasConsent && _isEnabled && _firebaseAvailable) {
      await _configureAnalytics();
      await _loadUserProperties();
      await _startSessionTracking();

      _recordEvent(AnalyticsEvent(
        name: 'analytics_initialized',
        parameters: {'consent_given': true},
      ));
    } else if (kDebugMode) {
      print('Analytics disabled or Firebase not available');
    }
  }

  /// Update analytics consent
  Future<void> updateConsent(bool hasConsent) async {
    _hasConsent = hasConsent;
    await SecureStorage.storeEncryptedData('analytics_consent', hasConsent.toString());

    if (hasConsent) {
      await _configureAnalytics();
      _recordEvent(AnalyticsEvent(
        name: 'analytics_consent_granted',
        parameters: {},
      ));
    } else if (_firebaseAvailable) {
      await _analytics?.setAnalyticsCollectionEnabled(false);
      _recordEvent(AnalyticsEvent(
        name: 'analytics_consent_revoked',
        parameters: {},
      ));
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    if (!_canTrack || !_firebaseAvailable) {
      _recordEvent(AnalyticsEvent(
        name: 'screen_view',
        parameters: {'screen_name': screenName, ...?parameters},
      ));
      return;
    }

    await _analytics?.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        'screen_class': screenName,
        ...?parameters,
      },
    );

    _recordEvent(AnalyticsEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName, ...?parameters},
    ));
  }

  /// Track user action
  Future<void> trackUserAction(String action, {
    String? category,
    String? label,
    int? value,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_canTrack) return;

    final eventParams = {
      'action': action,
      'category': category ?? 'general',
      'label': label,
      if (value != null) 'value': value,
      ...?parameters,
    };

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'user_action',
        parameters: eventParams,
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'user_action',
      parameters: eventParams,
    ));
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName, {
    String? action = 'used',
    Map<String, dynamic>? metadata,
  }) async {
    if (!_canTrack) return;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'feature_usage',
        parameters: {
          'feature_name': featureName,
          'action': action,
          ...?metadata,
        },
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'feature_usage',
      parameters: {
        'feature_name': featureName,
        'action': action,
        ...?metadata,
      },
    ));
  }

  /// Track expense-related events
  Future<void> trackExpenseEvent(String eventType, {
    required double amount,
    required String category,
    String? currency = 'USD',
    Map<String, dynamic>? metadata,
  }) async {
    if (!_canTrack) return;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'expense_event',
        parameters: {
          'event_type': eventType,
          'amount': amount,
          'category': category,
          'currency': currency,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?metadata,
        },
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'expense_event',
      parameters: {
        'event_type': eventType,
        'amount': amount,
        'category': category,
        'currency': currency,
        ...?metadata,
      },
    ));
  }

  /// Track conversion events
  Future<void> trackConversion(String conversionType, {
    double? value,
    String? currency = 'USD',
    Map<String, dynamic>? metadata,
  }) async {
    if (!_canTrack) return;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'conversion',
        parameters: {
          'conversion_type': conversionType,
          'value': value,
          if (currency != null) 'currency': currency,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?metadata,
        },
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'conversion',
      parameters: {
        'conversion_type': conversionType,
        'value': value,
        'currency': currency,
        ...?metadata,
      },
    ));
  }

  /// Set user properties
  Future<void> setUserProperty(String name, dynamic value) async {
    if (!_canTrack) return;

    _userProperties[name] = value;

    if (_firebaseAvailable) {
      await _analytics?.setUserProperty(
        name: name,
        value: value?.toString(),
      );
    }

    // Persist user properties
    await _saveUserProperties();
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    if (!_canTrack) return;

    if (_firebaseAvailable) {
      await _analytics?.setUserId(id: userId);
    }
    await SecureStorage.storeEncryptedData('analytics_user_id', userId);
  }

  /// Track error events
  Future<void> trackError(String errorType, {
    String? message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_canTrack) return;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_type': errorType,
          'message': message,
          'has_stack_trace': stackTrace != null,
          ...?metadata,
        },
      );

      // Also send to Crashlytics for error tracking
      await _crashlytics?.recordError(
        Exception(message ?? errorType),
        StackTrace.fromString(stackTrace ?? ''),
        reason: metadata,
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'message': message,
        ...?metadata,
      },
    ));
  }

  /// Start A/B test
  Future<void> startExperiment(String experimentId, String variant) async {
    if (!_canTrack) return;

    final experiment = Experiment(
      id: experimentId,
      variant: variant,
      startTime: DateTime.now(),
    );

    _activeExperiments[experimentId] = experiment;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'experiment_started',
        parameters: {
          'experiment_id': experimentId,
          'variant': variant,
        },
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'experiment_started',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant,
      },
    ));
  }

  /// Track experiment goal completion
  Future<void> trackExperimentGoal(String experimentId, String goalName) async {
    if (!_canTrack || !_activeExperiments.containsKey(experimentId)) return;

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'experiment_goal',
        parameters: {
          'experiment_id': experimentId,
          'goal_name': goalName,
          'variant': _activeExperiments[experimentId]!.variant,
        },
      );
    }

    _recordEvent(AnalyticsEvent(
      name: 'experiment_goal',
      parameters: {
        'experiment_id': experimentId,
        'goal_name': goalName,
        'variant': _activeExperiments[experimentId]!.variant,
      },
    ));
  }

  /// End experiment
  Future<void> endExperiment(String experimentId) async {
    if (!_activeExperiments.containsKey(experimentId)) return;

    final experiment = _activeExperiments[experimentId]!;
    final duration = DateTime.now().difference(experiment.startTime);

    if (_firebaseAvailable) {
      await _analytics?.logEvent(
        name: 'experiment_ended',
        parameters: {
          'experiment_id': experimentId,
          'variant': experiment.variant,
          'duration_seconds': duration.inSeconds,
        },
      );
    }

    _activeExperiments.remove(experimentId);

    _recordEvent(AnalyticsEvent(
      name: 'experiment_ended',
      parameters: {
        'experiment_id': experimentId,
        'variant': experiment.variant,
        'duration_seconds': duration.inSeconds,
      },
    ));
  }

  /// Get analytics events stream
  Stream<AnalyticsEvent> get events => _eventController.stream;

  /// Get current user properties
  Map<String, dynamic> get userProperties => Map.from(_userProperties);

  /// Get active experiments
  Map<String, Experiment> get activeExperiments => Map.from(_activeExperiments);

  /// Get analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    if (!_canTrack) {
      return AnalyticsSummary.empty();
    }

    // In a real implementation, you'd fetch this from analytics service
    return AnalyticsSummary(
      totalEvents: 0,
      uniqueUsers: 0,
      sessionDuration: Duration.zero,
      topEvents: [],
      conversionRate: 0.0,
      retentionRate: 0.0,
    );
  }

  /// Export user data for GDPR compliance
  Future<String> exportUserData() async {
    final data = {
      'user_properties': _userProperties,
      'active_experiments': _activeExperiments.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'consent_given': _hasConsent,
      'analytics_enabled': _isEnabled,
      'export_timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  /// Delete user analytics data
  Future<void> deleteUserData() async {
    if (!_canTrack) return;

    // Clear local data
    _userProperties.clear();
    _activeExperiments.clear();

    // Clear stored data
    await SecureStorage.deleteData('analytics_consent');
    await SecureStorage.deleteData('analytics_user_id');
    await SecureStorage.deleteData('user_properties');

    // Reset analytics
    if (_firebaseAvailable) {
      await _analytics?.resetAnalyticsData();
    }

    _recordEvent(AnalyticsEvent(
      name: 'user_data_deleted',
      parameters: {},
    ));
  }

  // Private methods

  bool get _canTrack => _isEnabled && _hasConsent && !EnvironmentConfig.current.isDevelopment;

  Future<bool> _checkAnalyticsConsent() async {
    final storedConsent = await SecureStorage.getEncryptedData('analytics_consent');
    return storedConsent == 'true';
  }

  Future<void> _configureAnalytics() async {
    if (!_firebaseAvailable) return;
    
    await _analytics?.setAnalyticsCollectionEnabled(true);

    // Configure session timeout (30 minutes)
    await _analytics?.setSessionTimeoutDuration(const Duration(minutes: 30));

    // Set default event parameters
    await _analytics?.setDefaultEventParameters({
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
      'environment': EnvironmentConfig.current.name,
    });
  }

  Future<void> _loadUserProperties() async {
    final stored = await SecureStorage.getEncryptedData('user_properties');
    if (stored != null) {
      try {
        final properties = jsonDecode(stored) as Map<String, dynamic>;
        _userProperties.addAll(properties);
      } catch (e) {
        // Invalid stored data, ignore
      }
    }
  }

  Future<void> _saveUserProperties() async {
    final data = jsonEncode(_userProperties);
    await SecureStorage.storeEncryptedData('user_properties', data);
  }

  Future<void> _startSessionTracking() async {
    if (!_firebaseAvailable) return;
    
    // Track app open
    await _analytics?.logAppOpen();

    _recordEvent(AnalyticsEvent(
      name: 'session_started',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ));
  }

  void _recordEvent(AnalyticsEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    // Debug logging in development
    if (kDebugMode) {
      print('Analytics Event: ${event.name} - ${event.parameters}');
    }
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// Analytics event data class
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Experiment data class
class Experiment {
  final String id;
  final String variant;
  final DateTime startTime;
  final DateTime? endTime;

  Experiment({
    required this.id,
    required this.variant,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variant': variant,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['id'],
      variant: json['variant'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    );
  }
}

/// Analytics summary data class
class AnalyticsSummary {
  final int totalEvents;
  final int uniqueUsers;
  final Duration sessionDuration;
  final List<String> topEvents;
  final double conversionRate;
  final double retentionRate;

  const AnalyticsSummary({
    required this.totalEvents,
    required this.uniqueUsers,
    required this.sessionDuration,
    required this.topEvents,
    required this.conversionRate,
    required this.retentionRate,
  });

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      totalEvents: 0,
      uniqueUsers: 0,
      sessionDuration: Duration.zero,
      topEvents: [],
      conversionRate: 0.0,
      retentionRate: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_events': totalEvents,
      'unique_users': uniqueUsers,
      'session_duration_minutes': sessionDuration.inMinutes,
      'top_events': topEvents,
      'conversion_rate': conversionRate,
      'retention_rate': retentionRate,
    };
  }
}

/// Analytics dashboard widget for development
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final AnalyticsService _analytics = AnalyticsService();
  final List<AnalyticsEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _analytics.events.listen((event) {
      setState(() {
        _recentEvents.insert(0, event);
        if (_recentEvents.length > 50) {
          _recentEvents.removeLast();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: ListView.builder(
        itemCount: _recentEvents.length,
        itemBuilder: (context, index) {
          final event = _recentEvents[index];
          return ListTile(
            title: Text(event.name),
            subtitle: Text(event.parameters.toString()),
            trailing: Text(
              '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _analytics.trackUserAction('dashboard_test', category: 'debug');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Analytics-enabled widget wrapper
class AnalyticsTracker extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Map<String, dynamic>? parameters;

  const AnalyticsTracker({
    super.key,
    required this.child,
    required this.screenName,
    this.parameters,
  });

  @override
  State<AnalyticsTracker> createState() => _AnalyticsTrackerState();
}

class _AnalyticsTrackerState extends State<AnalyticsTracker> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.trackScreenView(widget.screenName, parameters: widget.parameters);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Analytics interceptor for HTTP calls
class AnalyticsInterceptor extends Interceptor {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Track API calls
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _analytics.trackFeatureUsage('api_call', metadata: {
      'endpoint': response.requestOptions.uri.path,
      'method': response.requestOptions.method,
      'status_code': response.statusCode,
    });
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    _analytics.trackError('api_error', metadata: {
      'endpoint': err.requestOptions.uri.path,
      'status_code': err.response?.statusCode,
    });
    handler.next(err);
  }
}
