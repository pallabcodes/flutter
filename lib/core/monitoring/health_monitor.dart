import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:finwise/core/config/environments.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/data/datasources/remote/api_client.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:flutter/material.dart';

/// System health monitoring service
/// Continuously monitors all system components and services
class HealthMonitor {
  static final HealthMonitor _instance = HealthMonitor._internal();
  factory HealthMonitor() => _instance;
  HealthMonitor._internal();

  final StreamController<HealthEvent> _eventController =
      StreamController<HealthEvent>.broadcast();

  Timer? _healthCheckTimer;
  final Connectivity _connectivity = Connectivity();

  // Health status for each service
  final Map<String, ServiceHealth> _serviceHealth = {};

  // Health check intervals (seconds)
  static const int _apiCheckInterval = 30;
  static const int _databaseCheckInterval = 60;
  static const int _firebaseCheckInterval = 120;
  static const int _connectivityCheckInterval = 10;

  /// Initialize health monitoring
  Future<void> initialize() async {
    // Set up initial service health status
    _initializeServiceHealth();

    // Start periodic health checks
    _startHealthChecks();

    // Monitor connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    _emitEvent(HealthEvent(
      type: 'health_monitor_started',
      message: 'Health monitoring initialized',
      status: 'healthy',
    ));
  }

  /// Get overall health status
  Map<String, dynamic> getHealthStatus() {
    final overallStatus = _calculateOverallHealth();
    final serviceStatuses = _serviceHealth.map(
      (key, health) => MapEntry(key, health.status.name),
    );

    return {
      'overall_status': overallStatus.name,
      'services': serviceStatuses,
      'last_checked': DateTime.now().toIso8601String(),
      'uptime': _calculateUptime(),
      'response_times': _getAverageResponseTimes(),
    };
  }

  /// Get health events stream
  Stream<HealthEvent> get events => _eventController.stream;

  /// Force immediate health check
  Future<void> performHealthCheck() async {
    await Future.wait([
      _checkAPIHealth(),
      _checkDatabaseHealth(),
      _checkFirebaseHealth(),
      _checkConnectivityHealth(),
    ]);
  }

  /// Get detailed service health information
  ServiceHealth? getServiceHealth(String serviceName) {
    return _serviceHealth[serviceName];
  }

  /// Get health summary
  HealthSummary getHealthSummary() {
    final totalServices = _serviceHealth.length;
    final healthyServices = _serviceHealth.values
        .where((health) => health.status == HealthStatus.healthy)
        .length;
    final degradedServices = _serviceHealth.values
        .where((health) => health.status == HealthStatus.degraded)
        .length;
    final unhealthyServices = _serviceHealth.values
        .where((health) => health.status == HealthStatus.unhealthy)
        .length;

    return HealthSummary(
      totalServices: totalServices,
      healthyServices: healthyServices,
      degradedServices: degradedServices,
      unhealthyServices: unhealthyServices,
      overallHealth: _calculateOverallHealth(),
      lastChecked: DateTime.now(),
    );
  }

  // Private methods

  void _initializeServiceHealth() {
    _serviceHealth.clear();

    // Initialize all services with unknown status
    const services = [
      'api',
      'database',
      'firebase',
      'connectivity',
      'storage',
      'analytics',
      'crash_reporting',
    ];

    for (final service in services) {
      _serviceHealth[service] = ServiceHealth(
        name: service,
        status: HealthStatus.unknown,
        lastChecked: DateTime.now(),
      );
    }
  }

  void _startHealthChecks() {
    // API health checks (every 30 seconds)
    Timer.periodic(const Duration(seconds: _apiCheckInterval), (_) {
      _checkAPIHealth();
    });

    // Database health checks (every 60 seconds)
    Timer.periodic(const Duration(seconds: _databaseCheckInterval), (_) {
      _checkDatabaseHealth();
    });

    // Firebase health checks (every 2 minutes)
    Timer.periodic(const Duration(seconds: _firebaseCheckInterval), (_) {
      _checkFirebaseHealth();
    });

    // Connectivity checks (every 10 seconds)
    Timer.periodic(const Duration(seconds: _connectivityCheckInterval), (_) {
      _checkConnectivityHealth();
    });
  }

  Future<void> _checkAPIHealth() async {
    const serviceName = 'api';
    final startTime = DateTime.now();

    try {
      // In a real implementation, you'd make a health check API call
      // For now, simulate a health check
      await Future.delayed(const Duration(milliseconds: 100));

      final responseTime = DateTime.now().difference(startTime);
      final isHealthy = responseTime.inMilliseconds < 2000; // 2 second threshold

      _updateServiceHealth(
        serviceName,
        isHealthy ? HealthStatus.healthy : HealthStatus.degraded,
        responseTime: responseTime,
      );

      if (!isHealthy) {
        _emitEvent(HealthEvent(
          type: 'api_response_slow',
          message: 'API response time: ${responseTime.inMilliseconds}ms',
          status: 'degraded',
          metadata: {'response_time_ms': responseTime.inMilliseconds},
        ));
      }
    } catch (e) {
      _updateServiceHealth(serviceName, HealthStatus.unhealthy, error: e.toString());

      _emitEvent(HealthEvent(
        type: 'api_failure',
        message: 'API health check failed: ${e.toString()}',
        status: 'unhealthy',
      ));
    }
  }

  Future<void> _checkDatabaseHealth() async {
    const serviceName = 'database';
    final startTime = DateTime.now();

    try {
      // In a real implementation, you'd perform a database query
      await Future.delayed(const Duration(milliseconds: 50));

      final responseTime = DateTime.now().difference(startTime);
      final isHealthy = responseTime.inMilliseconds < 500; // 500ms threshold

      _updateServiceHealth(
        serviceName,
        isHealthy ? HealthStatus.healthy : HealthStatus.degraded,
        responseTime: responseTime,
      );
    } catch (e) {
      _updateServiceHealth(serviceName, HealthStatus.unhealthy, error: e.toString());

      _emitEvent(HealthEvent(
        type: 'database_failure',
        message: 'Database health check failed: ${e.toString()}',
        status: 'unhealthy',
      ));
    }
  }

  Future<void> _checkFirebaseHealth() async {
    const serviceName = 'firebase';

    try {
      // In a real implementation, you'd check Firebase connectivity
      // For now, assume it's healthy
      _updateServiceHealth(serviceName, HealthStatus.healthy);
    } catch (e) {
      _updateServiceHealth(serviceName, HealthStatus.unhealthy, error: e.toString());

      _emitEvent(HealthEvent(
        type: 'firebase_failure',
        message: 'Firebase health check failed: ${e.toString()}',
        status: 'unhealthy',
      ));
    }
  }

  Future<void> _checkConnectivityHealth() async {
    const serviceName = 'connectivity';

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;

      _updateServiceHealth(
        serviceName,
        isConnected ? HealthStatus.healthy : HealthStatus.unhealthy,
      );

      if (!isConnected) {
        _emitEvent(HealthEvent(
          type: 'connectivity_lost',
          message: 'Device lost internet connectivity',
          status: 'unhealthy',
        ));
      }
    } catch (e) {
      _updateServiceHealth(serviceName, HealthStatus.unhealthy, error: e.toString());
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    final status = isConnected ? HealthStatus.healthy : HealthStatus.unhealthy;

    _updateServiceHealth('connectivity', status);

    _emitEvent(HealthEvent(
      type: isConnected ? 'connectivity_restored' : 'connectivity_lost',
      message: isConnected
          ? 'Internet connectivity restored'
          : 'Internet connectivity lost',
      status: status.name,
    ));
  }

  void _updateServiceHealth(
    String serviceName,
    HealthStatus status, {
    Duration? responseTime,
    String? error,
  }) {
    final currentHealth = _serviceHealth[serviceName];
    if (currentHealth == null) return;

    final updatedHealth = currentHealth.copyWith(
      status: status,
      lastChecked: DateTime.now(),
      responseTime: responseTime,
      lastError: error,
    );

    _serviceHealth[serviceName] = updatedHealth;

    // Emit event if status changed
    if (currentHealth.status != status) {
      _emitEvent(HealthEvent(
        type: 'service_status_changed',
        message: '$serviceName status changed to ${status.name}',
        status: status.name,
        metadata: {
          'service': serviceName,
          'previous_status': currentHealth.status.name,
          'new_status': status.name,
        },
      ));
    }
  }

  HealthStatus _calculateOverallHealth() {
    if (_serviceHealth.isEmpty) return HealthStatus.unknown;

    final statuses = _serviceHealth.values.map((health) => health.status);

    if (statuses.any((status) => status == HealthStatus.unhealthy)) {
      return HealthStatus.unhealthy;
    }

    if (statuses.any((status) => status == HealthStatus.degraded)) {
      return HealthStatus.degraded;
    }

    if (statuses.any((status) => status == HealthStatus.unknown)) {
      return HealthStatus.unknown;
    }

    return HealthStatus.healthy;
  }

  Duration _calculateUptime() {
    // In a real implementation, track actual uptime
    return const Duration(hours: 24); // Mock data
  }

  Map<String, double> _getAverageResponseTimes() {
    final responseTimes = <String, List<Duration>>{};
    final averages = <String, double>{};

    for (final health in _serviceHealth.values) {
      if (health.responseTime != null) {
        responseTimes.putIfAbsent(health.name, () => []).add(health.responseTime!);
      }
    }

    responseTimes.forEach((service, times) {
      final total = times.fold<Duration>(Duration.zero, (sum, time) => sum + time);
      final avg = total.inMilliseconds / times.length;
      averages[service] = avg.toDouble();
    });

    return averages;
  }

  void _emitEvent(HealthEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _eventController.close();
  }
}

/// Health event data class
class HealthEvent {
  final String type;
  final String message;
  final String status;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  HealthEvent({
    required this.type,
    required this.message,
    required this.status,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Service health data class
class ServiceHealth {
  final String name;
  final HealthStatus status;
  final DateTime lastChecked;
  final Duration? responseTime;
  final String? lastError;

  const ServiceHealth({
    required this.name,
    required this.status,
    required this.lastChecked,
    this.responseTime,
    this.lastError,
  });

  ServiceHealth copyWith({
    String? name,
    HealthStatus? status,
    DateTime? lastChecked,
    Duration? responseTime,
    String? lastError,
  }) {
    return ServiceHealth(
      name: name ?? this.name,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      responseTime: responseTime ?? this.responseTime,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status.name,
      'last_checked': lastChecked.toIso8601String(),
      'response_time_ms': responseTime?.inMilliseconds,
      'last_error': lastError,
    };
  }
}

/// Health status enum
enum HealthStatus {
  unknown,
  healthy,
  degraded,
  unhealthy,
}

/// Health summary data class
class HealthSummary {
  final int totalServices;
  final int healthyServices;
  final int degradedServices;
  final int unhealthyServices;
  final HealthStatus overallHealth;
  final DateTime lastChecked;

  const HealthSummary({
    required this.totalServices,
    required this.healthyServices,
    required this.degradedServices,
    required this.unhealthyServices,
    required this.overallHealth,
    required this.lastChecked,
  });

  double get healthPercentage {
    if (totalServices == 0) return 100.0;
    return (healthyServices / totalServices) * 100.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_services': totalServices,
      'healthy_services': healthyServices,
      'degraded_services': degradedServices,
      'unhealthy_services': unhealthyServices,
      'overall_health': overallHealth.name,
      'health_percentage': healthPercentage,
      'last_checked': lastChecked.toIso8601String(),
    };
  }
}

/// Health status indicator widget
class HealthStatusIndicator extends StatefulWidget {
  final double size;
  final bool showDetails;

  const HealthStatusIndicator({
    super.key,
    this.size = 24.0,
    this.showDetails = false,
  });

  @override
  State<HealthStatusIndicator> createState() => _HealthStatusIndicatorState();
}

class _HealthStatusIndicatorState extends State<HealthStatusIndicator> {
  final HealthMonitor _healthMonitor = HealthMonitor();

  @override
  void initState() {
    super.initState();
    _healthMonitor.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HealthEvent>(
      stream: _healthMonitor.events,
      builder: (context, snapshot) {
        final summary = _healthMonitor.getHealthSummary();
        final color = _getHealthColor(summary.overallHealth);
        final icon = _getHealthIcon(summary.overallHealth);

        if (widget.showDetails) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: widget.size),
              const SizedBox(width: 4),
              Text(
                '${summary.healthPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: widget.size * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        return Icon(icon, color: color, size: widget.size);
      },
    );
  }

  Color _getHealthColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy: return Colors.green;
      case HealthStatus.degraded: return Colors.orange;
      case HealthStatus.unhealthy: return Colors.red;
      case HealthStatus.unknown: return Colors.grey;
    }
  }

  IconData _getHealthIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy: return Icons.check_circle;
      case HealthStatus.degraded: return Icons.warning;
      case HealthStatus.unhealthy: return Icons.error;
      case HealthStatus.unknown: return Icons.help;
    }
  }

  @override
  void dispose() {
    _healthMonitor.dispose();
    super.dispose();
  }
}

/// Health monitoring interceptor for Dio
class HealthMonitoringInterceptor extends Interceptor {
  final HealthMonitor _healthMonitor = HealthMonitor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Track API request
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Update API health status
    _healthMonitor._updateServiceHealth('api', HealthStatus.healthy);
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // Update API health status
    _healthMonitor._updateServiceHealth('api', HealthStatus.degraded);
    handler.next(err);
  }
}

/// Automatic health report generator
class HealthReportGenerator {
  static Future<String> generateHealthReport() async {
    final healthMonitor = HealthMonitor();
    await healthMonitor.initialize();

    final summary = healthMonitor.getHealthSummary();
    final serviceHealth = healthMonitor._serviceHealth;

    final report = '''
FINWISE HEALTH REPORT
Generated: ${DateTime.now().toIso8601String()}

OVERALL HEALTH: ${summary.overallHealth.name.toUpperCase()}
Health Score: ${summary.healthPercentage.toStringAsFixed(1)}%

SERVICE STATUS:
${serviceHealth.entries.map((entry) {
      final health = entry.value;
      return '- ${entry.key}: ${health.status.name.toUpperCase()} '
          '(Last checked: ${health.lastChecked})';
    }).join('\n')}

RECOMMENDATIONS:
${_generateRecommendations(summary)}

DETAILED METRICS:
${serviceHealth.entries.map((entry) {
      final health = entry.value;
      final details = [];
      if (health.responseTime != null) {
        details.add('Response time: ${health.responseTime!.inMilliseconds}ms');
      }
      if (health.lastError != null) {
        details.add('Last error: ${health.lastError}');
      }
      return '- ${entry.key}: ${details.join(', ')}';
    }).join('\n')}
''';

    return report;
  }

  static String _generateRecommendations(HealthSummary summary) {
    final recommendations = <String>[];

    if (summary.unhealthyServices > 0) {
      recommendations.add('- CRITICAL: ${summary.unhealthyServices} services are unhealthy. Immediate attention required.');
    }

    if (summary.degradedServices > 0) {
      recommendations.add('- WARNING: ${summary.degradedServices} services are degraded. Monitor closely.');
    }

    if (summary.healthPercentage < 80) {
      recommendations.add('- Overall health is below 80%. Review system performance.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('- All systems operating normally.');
    }

    return recommendations.join('\n');
  }
}

/// Health alert system
class HealthAlertSystem {
  static final HealthAlertSystem _instance = HealthAlertSystem._internal();
  factory HealthAlertSystem() => _instance;
  HealthAlertSystem._internal();

  final StreamController<HealthAlert> _alertController =
      StreamController<HealthAlert>.broadcast();

  Stream<HealthAlert> get alerts => _alertController.stream;

  void checkAndSendAlerts(HealthSummary summary) {
    // Check for critical alerts
    if (summary.unhealthyServices > 0) {
      _sendAlert(HealthAlert(
        title: 'Critical Service Failure',
        message: '${summary.unhealthyServices} services are unhealthy',
        severity: AlertSeverity.critical,
        metadata: {'unhealthy_count': summary.unhealthyServices},
      ));
    }

    // Check for warning alerts
    if (summary.degradedServices > 0) {
      _sendAlert(HealthAlert(
        title: 'Service Degradation',
        message: '${summary.degradedServices} services are degraded',
        severity: AlertSeverity.warning,
        metadata: {'degraded_count': summary.degradedServices},
      ));
    }

    // Check for health score alerts
    if (summary.healthPercentage < 50) {
      _sendAlert(HealthAlert(
        title: 'System Health Critical',
        message: 'Overall health score: ${summary.healthPercentage.toStringAsFixed(1)}%',
        severity: AlertSeverity.critical,
        metadata: {'health_score': summary.healthPercentage},
      ));
    }
  }

  void _sendAlert(HealthAlert alert) {
    if (!_alertController.isClosed) {
      _alertController.add(alert);
    }
  }

  void dispose() {
    _alertController.close();
  }
}

/// Health alert data class
class HealthAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  HealthAlert({
    required this.title,
    required this.message,
    required this.severity,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}
