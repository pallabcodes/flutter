import 'dart:async';
import 'dart:developer';
import 'package:finwise/core/errors/failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Advanced performance monitoring system
/// Tracks app performance, user experience, and detects regressions
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  final StreamController<PerformanceEvent> _eventController =
      StreamController<PerformanceEvent>.broadcast();

  Timer? _reportingTimer;
  bool _isEnabled = true;

  // Performance thresholds
  static const Duration _appStartThreshold = Duration(seconds: 3);
  static const Duration _frameBuildThreshold = Duration(milliseconds: 16); // 60 FPS
  static const Duration _apiCallThreshold = Duration(seconds: 2);

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (!_isEnabled) return;

    // Start periodic reporting
    _reportingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _reportMetrics();
    });

    // Set up frame callback monitoring
    WidgetsBinding.instance.addPostFrameCallback(_onFrameBuilt);

    // Set up memory monitoring
    _startMemoryMonitoring();

    _recordEvent(PerformanceEvent(
      type: 'monitor_initialized',
      message: 'Performance monitoring initialized',
      timestamp: DateTime.now(),
    ));
  }

  /// Enable/disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _reportingTimer?.cancel();
    }
  }

  /// Record app startup time
  void recordAppStartup(Duration startupTime) {
    final metric = PerformanceMetric(
      name: 'app_startup',
      value: startupTime.inMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
      metadata: {'threshold': _appStartThreshold.inMilliseconds},
    );

    _recordMetric(metric);

    // Check for performance regression
    if (startupTime > _appStartThreshold) {
      _recordEvent(PerformanceEvent(
        type: 'performance_regression',
        message: 'App startup time exceeded threshold: ${startupTime.inMilliseconds}ms',
        severity: PerformanceSeverity.warning,
        timestamp: DateTime.now(),
        metadata: {
          'actual': startupTime.inMilliseconds,
          'threshold': _appStartThreshold.inMilliseconds,
        },
      ));
    }
  }

  /// Record screen build time
  void recordScreenBuild(String screenName, Duration buildTime) {
    final metric = PerformanceMetric(
      name: 'screen_build_$screenName',
      value: buildTime.inMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
      metadata: {'screen': screenName},
    );

    _recordMetric(metric);
  }

  /// Record API call performance
  void recordApiCall(String endpoint, Duration duration, int statusCode) {
    final metric = PerformanceMetric(
      name: 'api_call',
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'threshold': _apiCallThreshold.inMilliseconds,
      },
    );

    _recordMetric(metric);

    // Check for slow API calls
    if (duration > _apiCallThreshold) {
      _recordEvent(PerformanceEvent(
        type: 'slow_api_call',
        message: 'API call to $endpoint exceeded threshold: ${duration.inMilliseconds}ms',
        severity: PerformanceSeverity.info,
        timestamp: DateTime.now(),
        metadata: {
          'endpoint': endpoint,
          'duration': duration.inMilliseconds,
          'status_code': statusCode,
        },
      ));
    }
  }

  /// Record user interaction
  void recordUserInteraction(String interactionType, String elementId, Duration responseTime) {
    final metric = PerformanceMetric(
      name: 'user_interaction',
      value: responseTime.inMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
      metadata: {
        'type': interactionType,
        'element': elementId,
      },
    );

    _recordMetric(metric);
  }

  /// Record memory usage
  void recordMemoryUsage(int usedMemory, int totalMemory) {
    final usagePercent = (usedMemory / totalMemory) * 100;

    final metric = PerformanceMetric(
      name: 'memory_usage',
      value: usagePercent,
      unit: '%',
      timestamp: DateTime.now(),
      metadata: {
        'used_mb': (usedMemory / 1024 / 1024).round(),
        'total_mb': (totalMemory / 1024 / 1024).round(),
      },
    );

    _recordMetric(metric);

    // Check for high memory usage
    if (usagePercent > 80) {
      _recordEvent(PerformanceEvent(
        type: 'high_memory_usage',
        message: 'Memory usage is high: ${usagePercent.toStringAsFixed(1)}%',
        severity: PerformanceSeverity.warning,
        timestamp: DateTime.now(),
        metadata: {
          'usage_percent': usagePercent,
          'used_mb': usedMemory ~/ (1024 * 1024),
          'total_mb': totalMemory ~/ (1024 * 1024),
        },
      ));
    }
  }

  /// Record frame drop
  void recordFrameDrop(int droppedFrames, double fps) {
    final metric = PerformanceMetric(
      name: 'frame_drop',
      value: droppedFrames.toDouble(),
      unit: 'frames',
      timestamp: DateTime.now(),
      metadata: {'fps': fps},
    );

    _recordMetric(metric);

    // Check for poor frame rate
    if (fps < 50) {
      _recordEvent(PerformanceEvent(
        type: 'poor_frame_rate',
        message: 'Frame rate dropped to ${fps.toStringAsFixed(1)} FPS',
        severity: PerformanceSeverity.warning,
        timestamp: DateTime.now(),
        metadata: {
          'fps': fps,
          'dropped_frames': droppedFrames,
        },
      ));
    }
  }

  /// Get performance metrics stream
  Stream<PerformanceEvent> get events => _eventController.stream;

  /// Get current performance metrics
  Map<String, PerformanceMetric> getCurrentMetrics() => Map.from(_metrics);

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    final recentMetrics = _metrics.values
        .where((metric) => metric.timestamp.isAfter(
          DateTime.now().subtract(const Duration(hours: 1)),
        ))
        .toList();

    final avgAppStartup = _calculateAverageMetric(recentMetrics, 'app_startup');
    final avgApiCall = _calculateAverageMetric(recentMetrics, 'api_call');
    final memoryUsage = _getLatestMetric(recentMetrics, 'memory_usage');

    return PerformanceSummary(
      averageAppStartupTime: avgAppStartup != null
          ? Duration(milliseconds: avgAppStartup.toInt())
          : null,
      averageApiCallTime: avgApiCall != null
          ? Duration(milliseconds: avgApiCall.toInt())
          : null,
      currentMemoryUsage: memoryUsage?.value,
      totalMetrics: _metrics.length,
      recentEvents: _getRecentEvents().length,
      healthScore: _calculateHealthScore(),
    );
  }

  /// Export performance data
  Future<String> exportPerformanceData() async {
    final data = {
      'metrics': _metrics.map((key, value) => MapEntry(key, value.toJson())),
      'events': _getRecentEvents().map((event) => event.toJson()).toList(),
      'summary': getPerformanceSummary().toJson(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };

    return data.toString(); // In real app, would use JSON encoding
  }

  // Private methods

  void _recordMetric(PerformanceMetric metric) {
    _metrics[metric.name] = metric;

    // Keep only recent metrics (last 24 hours)
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _metrics.removeWhere((key, metric) => metric.timestamp.isBefore(cutoff));

    // Send to analytics if severe
    if (_isSevereMetric(metric)) {
      _sendToAnalytics(metric);
    }
  }

  void _recordEvent(PerformanceEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    // Send critical events immediately
    if (event.severity == PerformanceSeverity.error ||
        event.severity == PerformanceSeverity.critical) {
      _sendCriticalAlert(event);
    }
  }

  void _onFrameBuilt(Duration timestamp) {
    // This would be called after each frame build
    // In a real implementation, you'd measure actual frame build times
    WidgetsBinding.instance.addPostFrameCallback(_onFrameBuilt);
  }

  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      // In a real implementation, you'd get actual memory usage
      // This is a placeholder for the concept
      _recordMemoryUsage(100 * 1024 * 1024, 500 * 1024 * 1024); // Mock data
    });
  }

  void _reportMetrics() {
    final summary = getPerformanceSummary();

    // Send periodic reports to monitoring service
    if (kDebugMode) {
      print('Performance Report: ${summary.toJson()}');
    }
  }

  bool _isSevereMetric(PerformanceMetric metric) {
    // Define criteria for severe metrics
    switch (metric.name) {
      case 'app_startup':
        return metric.value > _appStartThreshold.inMilliseconds * 1.5;
      case 'memory_usage':
        return metric.value > 90; // 90% memory usage
      case 'frame_drop':
        return metric.value > 10; // More than 10 dropped frames
      default:
        return false;
    }
  }

  double? _calculateAverageMetric(List<PerformanceMetric> metrics, String metricName) {
    final relevantMetrics = metrics.where((m) => m.name.contains(metricName));
    if (relevantMetrics.isEmpty) return null;

    final sum = relevantMetrics.fold<double>(0, (sum, metric) => sum + metric.value);
    return sum / relevantMetrics.length;
  }

  PerformanceMetric? _getLatestMetric(List<PerformanceMetric> metrics, String metricName) {
    final relevantMetrics = metrics.where((m) => m.name == metricName);
    if (relevantMetrics.isEmpty) return null;

    return relevantMetrics.reduce((a, b) =>
      a.timestamp.isAfter(b.timestamp) ? a : b);
  }

  List<PerformanceEvent> _getRecentEvents() {
    // In a real implementation, you'd maintain a list of recent events
    return [];
  }

  double _calculateHealthScore() {
    // Calculate overall health score based on metrics
    final summary = getPerformanceSummary();
    double score = 100.0;

    // Deduct points for poor performance
    if (summary.averageAppStartupTime != null &&
        summary.averageAppStartupTime! > _appStartThreshold) {
      score -= 20;
    }

    if (summary.averageApiCallTime != null &&
        summary.averageApiCallTime! > _apiCallThreshold) {
      score -= 15;
    }

    if (summary.currentMemoryUsage != null &&
        summary.currentMemoryUsage! > 80) {
      score -= 10;
    }

    return score.clamp(0.0, 100.0);
  }

  void _sendToAnalytics(PerformanceMetric metric) {
    // Send to Firebase Analytics, DataDog, etc.
    if (kDebugMode) {
      print('Sending metric to analytics: ${metric.toJson()}');
    }
  }

  void _sendCriticalAlert(PerformanceEvent event) {
    // Send critical alerts via Slack, email, etc.
    if (kDebugMode) {
      print('CRITICAL ALERT: ${event.toJson()}');
    }
  }

  /// Dispose of resources
  void dispose() {
    _reportingTimer?.cancel();
    _eventController.close();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      name: json['name'],
      value: json['value'],
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Performance event data class
class PerformanceEvent {
  final String type;
  final String message;
  final PerformanceSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceEvent({
    required this.type,
    required this.message,
    this.severity = PerformanceSeverity.info,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance severity levels
enum PerformanceSeverity {
  info,
  warning,
  error,
  critical,
}

/// Performance summary data class
class PerformanceSummary {
  final Duration? averageAppStartupTime;
  final Duration? averageApiCallTime;
  final double? currentMemoryUsage;
  final int totalMetrics;
  final int recentEvents;
  final double healthScore;

  const PerformanceSummary({
    this.averageAppStartupTime,
    this.averageApiCallTime,
    this.currentMemoryUsage,
    required this.totalMetrics,
    required this.recentEvents,
    required this.healthScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'average_app_startup_time_ms': averageAppStartupTime?.inMilliseconds,
      'average_api_call_time_ms': averageApiCallTime?.inMilliseconds,
      'current_memory_usage_percent': currentMemoryUsage,
      'total_metrics': totalMetrics,
      'recent_events': recentEvents,
      'health_score': healthScore,
    };
  }
}

/// Performance monitor widget for debugging
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;

  const PerformanceMonitorWidget({super.key, required this.child});

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void initState() {
    super.initState();
    _monitor.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (kDebugMode) _buildPerformanceOverlay(),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverlay() {
    return StreamBuilder<PerformanceEvent>(
      stream: _monitor.events,
      builder: (context, snapshot) {
        final summary = _monitor.getPerformanceSummary();

        return Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Monitor',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Health: ${summary.healthScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: summary.healthScore > 80 ? Colors.green : Colors.red,
                    fontSize: 10,
                  ),
                ),
                if (summary.averageAppStartupTime != null)
                  Text(
                    'Startup: ${summary.averageAppStartupTime!.inMilliseconds}ms',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }
}

/// Performance monitoring interceptor for HTTP calls
class PerformanceMonitoringInterceptor extends Interceptor {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['start_time'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _monitor.recordApiCall(
        response.requestOptions.uri.toString(),
        duration,
        response.statusCode ?? 0,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _monitor.recordApiCall(
        err.requestOptions.uri.toString(),
        duration,
        err.response?.statusCode ?? 0,
      );
    }
    handler.next(err);
  }
}
