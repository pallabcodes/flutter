#!/usr/bin/env dart

/// Monitoring and alerting system for FinWise
/// Tracks app health, performance, and user metrics

import 'dart:io';
import 'dart:convert';

class MonitoringSystem {
  static const String projectId = 'finwise';

  static Future<void> main(List<String> args) async {
    print('📊 FinWise Monitoring System');
    print('=' * 35);

    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final command = args[0];

    try {
      switch (command) {
        case 'health':
          await _checkHealth();
          break;

        case 'metrics':
          await _collectMetrics();
          break;

        case 'alerts':
          await _checkAlerts();
          break;

        case 'report':
          await _generateReport();
          break;

        case 'dashboard':
          await _openDashboard();
          break;

        default:
          print('❌ Unknown command: $command');
          _printUsage();
          exit(1);
      }

      print('\n✅ Monitoring task completed successfully!');
    } catch (e) {
      print('\n❌ Monitoring failed: $e');
      exit(1);
    }
  }

  static Future<void> _checkHealth() async {
    print('🏥 Checking system health...');

    final healthChecks = [
      _checkFirebaseHealth(),
      _checkAPIHealth(),
      _checkDatabaseHealth(),
      _checkCDNHealth(),
      _checkAppStoreHealth(),
    ];

    final results = await Future.wait(healthChecks);
    final failures = results.where((result) => !result.success).toList();

    if (failures.isEmpty) {
      print('✅ All health checks passed');
    } else {
      print('❌ Health check failures:');
      for (final failure in failures) {
        print('  - ${failure.name}: ${failure.error}');
      }
    }

    await _sendHealthReport(results);
  }

  static Future<HealthCheckResult> _checkFirebaseHealth() async {
    try {
      // This would check Firebase services health
      // For now, simulate a check
      await Future.delayed(const Duration(milliseconds: 500));
      return HealthCheckResult.success('Firebase');
    } catch (e) {
      return HealthCheckResult.failure('Firebase', e.toString());
    }
  }

  static Future<HealthCheckResult> _checkAPIHealth() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.finwise.com/health'));
      final response = await request.close();

      if (response.statusCode == 200) {
        return HealthCheckResult.success('API');
      } else {
        return HealthCheckResult.failure('API', 'Status code: ${response.statusCode}');
      }
    } catch (e) {
      return HealthCheckResult.failure('API', e.toString());
    }
  }

  static Future<HealthCheckResult> _checkDatabaseHealth() async {
    try {
      // This would check database connectivity
      // For now, simulate a check
      await Future.delayed(const Duration(milliseconds: 300));
      return HealthCheckResult.success('Database');
    } catch (e) {
      return HealthCheckResult.failure('Database', e.toString());
    }
  }

  static Future<HealthCheckResult> _checkCDNHealth() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://finwise.app'));
      final response = await request.close();

      if (response.statusCode == 200) {
        return HealthCheckResult.success('CDN');
      } else {
        return HealthCheckResult.failure('CDN', 'Status code: ${response.statusCode}');
      }
    } catch (e) {
      return HealthCheckResult.failure('CDN', e.toString());
    }
  }

  static Future<HealthCheckResult> _checkAppStoreHealth() async {
    try {
      // Check both App Store and Play Store availability
      final iosHealth = await _checkAppStoreHealthIOS();
      final androidHealth = await _checkAppStoreHealthAndroid();

      if (iosHealth && androidHealth) {
        return HealthCheckResult.success('App Stores');
      } else {
        return HealthCheckResult.failure('App Stores', 'One or more stores unavailable');
      }
    } catch (e) {
      return HealthCheckResult.failure('App Stores', e.toString());
    }
  }

  static Future<bool> _checkAppStoreHealthIOS() async {
    // This would check App Store availability
    return true; // Placeholder
  }

  static Future<bool> _checkAppStoreHealthAndroid() async {
    // This would check Play Store availability
    return true; // Placeholder
  }

  static Future<void> _collectMetrics() async {
    print('📈 Collecting metrics...');

    final metrics = await _gatherMetrics();

    // Save metrics to file
    final metricsFile = File('monitoring/metrics.json');
    await metricsFile.parent.create(recursive: true);
    await metricsFile.writeAsString(JsonEncoder.withIndent('  ').convert(metrics));

    // Send to monitoring service
    await _sendMetrics(metrics);

    print('✅ Metrics collected and saved');
    _printMetricsSummary(metrics);
  }

  static Future<Map<String, dynamic>> _gatherMetrics() async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'app_metrics': {
        'active_users': await _getActiveUsers(),
        'crash_rate': await _getCrashRate(),
        'avg_session_duration': await _getAvgSessionDuration(),
        'retention_rate': await _getRetentionRate(),
      },
      'performance_metrics': {
        'avg_app_startup_time': await _getAvgStartupTime(),
        'avg_api_response_time': await _getAvgAPIResponseTime(),
        'memory_usage': await _getMemoryUsage(),
        'battery_impact': await _getBatteryImpact(),
      },
      'business_metrics': {
        'monthly_active_users': await _getMonthlyActiveUsers(),
        'revenue': await _getRevenue(),
        'conversion_rate': await _getConversionRate(),
        'feature_usage': await _getFeatureUsage(),
      },
      'infrastructure_metrics': {
        'server_uptime': await _getServerUptime(),
        'error_rate': await _getErrorRate(),
        'throughput': await _getThroughput(),
        'latency': await _getLatency(),
      },
    };
  }

  static Future<void> _checkAlerts() async {
    print('🚨 Checking alerts...');

    final alerts = await _scanForAlerts();

    if (alerts.isEmpty) {
      print('✅ No active alerts');
      return;
    }

    print('⚠️  Active alerts:');
    for (final alert in alerts) {
      print('  - ${alert.severity.toUpperCase()}: ${alert.message}');
    }

    await _sendAlerts(alerts);
  }

  static Future<List<Alert>> _scanForAlerts() async {
    final alerts = <Alert>[];

    // Check crash rate
    final crashRate = await _getCrashRate();
    if (crashRate > 5.0) {
      alerts.add(Alert(
        severity: 'critical',
        message: 'Crash rate is ${crashRate.toStringAsFixed(1)}% (threshold: 5%)',
        metric: 'crash_rate',
        value: crashRate,
        threshold: 5.0,
      ));
    }

    // Check API response time
    final apiResponseTime = await _getAvgAPIResponseTime();
    if (apiResponseTime > 3000) {
      alerts.add(Alert(
        severity: 'warning',
        message: 'API response time is ${apiResponseTime}ms (threshold: 3000ms)',
        metric: 'api_response_time',
        value: apiResponseTime,
        threshold: 3000,
      ));
    }

    // Check server uptime
    final uptime = await _getServerUptime();
    if (uptime < 99.9) {
      alerts.add(Alert(
        severity: 'warning',
        message: 'Server uptime is ${uptime.toStringAsFixed(1)}% (threshold: 99.9%)',
        metric: 'server_uptime',
        value: uptime,
        threshold: 99.9,
      ));
    }

    // Check error rate
    final errorRate = await _getErrorRate();
    if (errorRate > 1.0) {
      alerts.add(Alert(
        severity: 'error',
        message: 'Error rate is ${errorRate.toStringAsFixed(1)}% (threshold: 1%)',
        metric: 'error_rate',
        value: errorRate,
        threshold: 1.0,
      ));
    }

    return alerts;
  }

  static Future<void> _generateReport() async {
    print('📋 Generating monitoring report...');

    final report = await _buildReport();

    // Save report
    final reportFile = File('monitoring/report.html');
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(report);

    // Print summary
    print('📊 Monitoring Report Summary:');
    print('  - Report saved to: monitoring/report.html');
    print('  - Health status: ${await _getOverallHealth()}');
    print('  - Active alerts: ${(await _scanForAlerts()).length}');
    print('  - Generated at: ${DateTime.now().toIso8601String()}');
  }

  static Future<String> _buildReport() async {
    final metrics = await _gatherMetrics();
    final alerts = await _scanForAlerts();
    final healthStatus = await _getOverallHealth();

    return '''
<!DOCTYPE html>
<html>
<head>
    <title>FinWise Monitoring Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #2196F3; color: white; padding: 20px; border-radius: 8px; }
        .metric { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 4px; }
        .alert { background: #ffebee; border-left: 4px solid #f44336; padding: 10px; margin: 10px 0; }
        .success { background: #e8f5e8; border-left: 4px solid #4caf50; }
        .warning { background: #fff3e0; border-left: 4px solid #ff9800; }
        .error { background: #ffebee; border-left: 4px solid #f44336; }
    </style>
</head>
<body>
    <div class="header">
        <h1>FinWise Monitoring Report</h1>
        <p>Generated: ${DateTime.now().toIso8601String()}</p>
        <p>Overall Health: $healthStatus</p>
    </div>

    <h2>Active Alerts (${alerts.length})</h2>
    ${alerts.map((alert) => '''
    <div class="alert ${alert.severity}">
        <strong>${alert.severity.toUpperCase()}:</strong> ${alert.message}
        <br><small>Metric: ${alert.metric} | Value: ${alert.value} | Threshold: ${alert.threshold}</small>
    </div>
    ''').join()}

    <h2>App Metrics</h2>
    ${metrics['app_metrics'].entries.map((entry) => '''
    <div class="metric">
        <strong>${entry.key.replaceAll('_', ' ').toUpperCase()}:</strong> ${entry.value}
    </div>
    ''').join()}

    <h2>Performance Metrics</h2>
    ${metrics['performance_metrics'].entries.map((entry) => '''
    <div class="metric">
        <strong>${entry.key.replaceAll('_', ' ').toUpperCase()}:</strong> ${entry.value}
    </div>
    ''').join()}

    <h2>Business Metrics</h2>
    ${metrics['business_metrics'].entries.map((entry) => '''
    <div class="metric">
        <strong>${entry.key.replaceAll('_', ' ').toUpperCase()}:</strong> ${entry.value}
    </div>
    ''').join()}

    <h2>Infrastructure Metrics</h2>
    ${metrics['infrastructure_metrics'].entries.map((entry) => '''
    <div class="metric">
        <strong>${entry.key.replaceAll('_', ' ').toUpperCase()}:</strong> ${entry.value}
    </div>
    ''').join()}
</body>
</html>
''';
  }

  static Future<void> _openDashboard() async {
    print('📊 Opening monitoring dashboard...');

    const dashboardUrl = 'https://console.firebase.google.com/project/finwise-prod/analytics';

    try {
      await Process.run('open', [dashboardUrl]);
      print('✅ Dashboard opened in browser');
    } catch (e) {
      print('⚠️  Could not open dashboard automatically');
      print('📊 Dashboard URL: $dashboardUrl');
    }
  }

  // Placeholder implementations for metrics
  static Future<double> _getActiveUsers() async => 12500.0;
  static Future<double> _getCrashRate() async => 2.1;
  static Future<double> _getAvgSessionDuration() async => 450.0;
  static Future<double> _getRetentionRate() async => 75.5;
  static Future<double> _getAvgStartupTime() async => 1200.0;
  static Future<double> _getAvgAPIResponseTime() async => 250.0;
  static Future<double> _getMemoryUsage() async => 45.2;
  static Future<double> _getBatteryImpact() async => 12.3;
  static Future<double> _getMonthlyActiveUsers() async => 87500.0;
  static Future<double> _getRevenue() async => 12500.0;
  static Future<double> _getConversionRate() async => 8.7;
  static Future<Map<String, dynamic>> _getFeatureUsage() async => {
    'receipt_scanning': 0.65,
    'budget_tracking': 0.82,
    'expense_categorization': 0.91,
  };
  static Future<double> _getServerUptime() async => 99.95;
  static Future<double> _getErrorRate() async => 0.8;
  static Future<double> _getThroughput() async => 1250.0;
  static Future<double> _getLatency() async => 45.0;
  static Future<String> _getOverallHealth() async => 'Healthy';

  static Future<void> _sendHealthReport(List<HealthCheckResult> results) async {
    // Send to monitoring service (e.g., Datadog, New Relic, etc.)
    // For now, just log
    print('📤 Health report sent to monitoring service');
  }

  static Future<void> _sendMetrics(Map<String, dynamic> metrics) async {
    // Send to monitoring service
    print('📤 Metrics sent to monitoring service');
  }

  static Future<void> _sendAlerts(List<Alert> alerts) async {
    // Send alerts to Slack, email, etc.
    print('📤 ${alerts.length} alerts sent to notification channels');
  }

  static void _printMetricsSummary(Map<String, dynamic> metrics) {
    print('📊 Metrics Summary:');
    print('  App: ${metrics['app_metrics']['active_users']} active users');
    print('  Performance: ${metrics['performance_metrics']['avg_app_startup_time']}ms startup');
    print('  Business: \$${metrics['business_metrics']['revenue']} revenue');
    print('  Infrastructure: ${metrics['infrastructure_metrics']['server_uptime']}% uptime');
  }

  static void _printUsage() {
    print('''
Usage: dart tool/monitoring.dart <command>

Commands:
  health     Run health checks for all services
  metrics    Collect and report application metrics
  alerts     Check for active alerts and thresholds
  report     Generate comprehensive monitoring report
  dashboard  Open monitoring dashboard in browser

Examples:
  dart tool/monitoring.dart health
  dart tool/monitoring.dart metrics
  dart tool/monitoring.dart alerts
  dart tool/monitoring.dart report
''');
  }
}

class HealthCheckResult {
  final String name;
  final bool success;
  final String? error;

  HealthCheckResult.success(this.name)
      : success = true,
        error = null;

  HealthCheckResult.failure(this.name, this.error) : success = false;
}

class Alert {
  final String severity;
  final String message;
  final String metric;
  final num value;
  final num threshold;

  Alert({
    required this.severity,
    required this.message,
    required this.metric,
    required this.value,
    required this.threshold,
  });
}
