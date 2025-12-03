#!/usr/bin/env dart
import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

/// Comprehensive monitoring dashboard for the FinWise ecosystem
/// Aggregates metrics from all apps and provides health insights

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('command', abbr: 'c',
        allowed: ['generate', 'update', 'check', 'alert'],
        defaultsTo: 'generate',
        help: 'Command to execute')
    ..addOption('app', abbr: 'a',
        allowed: ['finwise', 'creditwise', 'rentwise', 'investwise', 'all'],
        defaultsTo: 'all',
        help: 'App to monitor (or "all")')
    ..addFlag('json', abbr: 'j', defaultsTo: false,
        help: 'Output as JSON')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Verbose output')
    ..addFlag('help', abbr: 'h', defaultsTo: false,
        help: 'Show help');

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print('FinWise Monitoring Dashboard');
    print('===========================');
    print('');
    print('Usage: dart tool/monitoring_dashboard.dart [options]');
    print('');
    print(parser.usage);
    print('');
    print('Commands:');
    print('  generate  Generate comprehensive monitoring dashboard');
    print('  update    Update dashboard with latest metrics');
    print('  check     Check system health and alert if issues found');
    print('  alert     Send alerts for critical issues');
    print('');
    print('Examples:');
    print('  dart tool/monitoring_dashboard.dart -c generate    # Generate full dashboard');
    print('  dart tool/monitoring_dashboard.dart -c check -a finwise  # Check FinWise health');
    return;
  }

  final command = results['command'] as String;
  final app = results['app'] as String;
  final jsonOutput = results['json'] as bool;
  final verbose = results['verbose'] as bool;

  switch (command) {
    case 'generate':
      await generateDashboard(app, jsonOutput, verbose);
      break;
    case 'update':
      await updateDashboard(app, verbose);
      break;
    case 'check':
      await checkHealth(app, jsonOutput, verbose);
      break;
    case 'alert':
      await sendAlerts(app, verbose);
      break;
    default:
      print('Unknown command: $command');
      exit(1);
  }
}

Future<void> generateDashboard(String app, bool jsonOutput, bool verbose) async {
  print('📊 Generating FinWise Ecosystem Monitoring Dashboard...');

  final dashboard = await collectAllMetrics(app, verbose);

  if (jsonOutput) {
    print(jsonEncode(dashboard.toJson()));
  } else {
    printDashboard(dashboard);
  }

  // Save dashboard to file
  final dashboardFile = File('monitoring-dashboard.md');
  await dashboardFile.writeAsString(generateMarkdownDashboard(dashboard));

  print('💾 Dashboard saved to monitoring-dashboard.md');
}

Future<void> updateDashboard(String app, bool verbose) async {
  print('🔄 Updating monitoring dashboard...');

  final dashboard = await collectAllMetrics(app, verbose);

  // Update existing dashboard file
  final dashboardFile = File('monitoring-dashboard.md');
  if (await dashboardFile.exists()) {
    await dashboardFile.writeAsString(generateMarkdownDashboard(dashboard));
    print('✅ Dashboard updated');
  } else {
    print('❌ Dashboard file not found. Run generate first.');
  }
}

Future<void> checkHealth(String app, bool jsonOutput, bool verbose) async {
  print('🏥 Checking system health...');

  final dashboard = await collectAllMetrics(app, verbose);
  final healthCheck = performHealthCheck(dashboard);

  if (jsonOutput) {
    print(jsonEncode(healthCheck.toJson()));
  } else {
    printHealthCheck(healthCheck);
  }

  // Exit with appropriate code based on health
  if (healthCheck.hasCriticalIssues) {
    print('❌ CRITICAL: System health issues require immediate attention');
    exit(1);
  } else if (healthCheck.hasWarnings) {
    print('⚠️  WARNING: System health issues should be addressed');
    exit(1);
  } else {
    print('✅ HEALTHY: All systems operating normally');
    exit(0);
  }
}

Future<void> sendAlerts(String app, bool verbose) async {
  print('🚨 Sending alerts for critical issues...');

  final dashboard = await collectAllMetrics(app, verbose);
  final alerts = generateAlerts(dashboard);

  if (alerts.isEmpty) {
    print('✅ No alerts to send - system is healthy');
    return;
  }

  // Send alerts via configured channels (email, Slack, etc.)
  for (final alert in alerts) {
    await sendAlert(alert, verbose);
  }

  print('📤 Sent ${alerts.length} alerts');
}

Future<MonitoringDashboard> collectAllMetrics(String app, bool verbose) async {
  final apps = app == 'all'
      ? ['finwise', 'creditwise', 'rentwise', 'investwise']
      : [app];

  final appMetrics = <String, AppMetrics>{};

  for (final appName in apps) {
    if (verbose) print('  📱 Collecting metrics for $appName...');

    final metrics = await collectAppMetrics(appName, verbose);
    appMetrics[appName] = metrics;
  }

  // Collect infrastructure metrics
  final infrastructure = await collectInfrastructureMetrics(verbose);

  return MonitoringDashboard(
    generatedAt: DateTime.now(),
    apps: appMetrics,
    infrastructure: infrastructure,
  );
}

Future<AppMetrics> collectAppMetrics(String appName, bool verbose) async {
  try {
    // Firebase Analytics metrics (mock data for now)
    final analytics = await collectAnalyticsMetrics(appName, verbose);

    // Crash reporting metrics
    final crashes = await collectCrashMetrics(appName, verbose);

    // Performance metrics
    final performance = await collectPerformanceMetrics(appName, verbose);

    // User engagement metrics
    final engagement = await collectEngagementMetrics(appName, verbose);

    // Revenue metrics
    final revenue = await collectRevenueMetrics(appName, verbose);

    return AppMetrics(
      appName: appName,
      analytics: analytics,
      crashes: crashes,
      performance: performance,
      engagement: engagement,
      revenue: revenue,
      lastUpdated: DateTime.now(),
    );
  } catch (e) {
    if (verbose) print('    ❌ Failed to collect metrics for $appName: $e');

    // Return empty metrics on failure
    return AppMetrics.empty(appName);
  }
}

Future<AnalyticsMetrics> collectAnalyticsMetrics(String appName, bool verbose) async {
  // In production, this would fetch from Firebase Analytics API
  // For now, return mock data
  return AnalyticsMetrics(
    dailyActiveUsers: _mockDailyActiveUsers(appName),
    monthlyActiveUsers: _mockMonthlyActiveUsers(appName),
    totalUsers: _mockTotalUsers(appName),
    sessionDuration: _mockSessionDuration(appName),
    retentionRate: _mockRetentionRate(appName),
    topScreens: _mockTopScreens(appName),
  );
}

Future<CrashMetrics> collectCrashMetrics(String appName, bool verbose) async {
  // In production, this would fetch from Firebase Crashlytics API
  return CrashMetrics(
    crashFreeUsers: _mockCrashFreeUsers(appName),
    totalCrashes: _mockTotalCrashes(appName),
    crashRate: _mockCrashRate(appName),
    topCrashTypes: _mockTopCrashTypes(appName),
  );
}

Future<PerformanceMetrics> collectPerformanceMetrics(String appName, bool verbose) async {
  // In production, this would fetch from Firebase Performance Monitoring
  return PerformanceMetrics(
    averageAppLaunchTime: _mockAppLaunchTime(appName),
    averageScreenLoadTime: _mockScreenLoadTime(appName),
    networkRequestSuccess: _mockNetworkSuccess(appName),
    memoryUsage: _mockMemoryUsage(appName),
    batteryImpact: _mockBatteryImpact(appName),
  );
}

Future<EngagementMetrics> collectEngagementMetrics(String appName, bool verbose) async {
  return EngagementMetrics(
    dailySessions: _mockDailySessions(appName),
    averageSessionDuration: _mockSessionDuration(appName),
    screenViewsPerSession: _mockScreenViewsPerSession(appName),
    featureUsage: _mockFeatureUsage(appName),
    userRetention: _mockUserRetention(appName),
  );
}

Future<RevenueMetrics> collectRevenueMetrics(String appName, bool verbose) async {
  return RevenueMetrics(
    dailyRevenue: _mockDailyRevenue(appName),
    monthlyRevenue: _mockMonthlyRevenue(appName),
    averageRevenuePerUser: _mockRevenuePerUser(appName),
    conversionRate: _mockConversionRate(appName),
    topRevenueSources: _mockTopRevenueSources(appName),
  );
}

Future<InfrastructureMetrics> collectInfrastructureMetrics(bool verbose) async {
  return InfrastructureMetrics(
    apiUptime: 99.9,
    databaseConnections: 150,
    serverResponseTime: 45,
    errorRate: 0.1,
    bandwidthUsage: 2.5,
    storageUsage: 75.0,
  );
}

HealthCheck performHealthCheck(MonitoringDashboard dashboard) {
  final issues = <HealthIssue>[];

  // Check app-specific health
  for (final appEntry in dashboard.apps.entries) {
    final appName = appEntry.key;
    final metrics = appEntry.value;

    // Crash rate check
    if (metrics.crashes.crashRate > 1.0) {
      issues.add(HealthIssue(
        severity: Severity.critical,
        app: appName,
        component: 'crashes',
        message: 'Crash rate too high: ${metrics.crashes.crashRate}%',
        recommendation: 'Investigate and fix top crash causes immediately',
      ));
    }

    // Performance checks
    if (metrics.performance.averageAppLaunchTime > 3000) {
      issues.add(HealthIssue(
        severity: Severity.high,
        app: appName,
        component: 'performance',
        message: 'App launch time too slow: ${metrics.performance.averageAppLaunchTime}ms',
        recommendation: 'Optimize app initialization and reduce launch time',
      ));
    }

    // User engagement checks
    if (metrics.engagement.userRetention.day1 < 0.6) {
      issues.add(HealthIssue(
        severity: Severity.medium,
        app: appName,
        component: 'engagement',
        message: 'User retention too low: ${(metrics.engagement.userRetention.day1 * 100).toFixed(1)}%',
        recommendation: 'Improve onboarding and user experience',
      ));
    }

    // Revenue checks
    if (metrics.revenue.conversionRate < 0.05) {
      issues.add(HealthIssue(
        severity: Severity.low,
        app: appName,
        component: 'revenue',
        message: 'Conversion rate low: ${(metrics.revenue.conversionRate * 100).toFixed(1)}%',
        recommendation: 'Optimize monetization strategy and pricing',
      ));
    }
  }

  // Check infrastructure health
  final infra = dashboard.infrastructure;

  if (infra.apiUptime < 99.5) {
    issues.add(HealthIssue(
      severity: Severity.critical,
      app: 'infrastructure',
      component: 'api',
      message: 'API uptime too low: ${infra.apiUptime}%',
      recommendation: 'Investigate API issues and improve reliability',
    ));
  }

  if (infra.errorRate > 1.0) {
    issues.add(HealthIssue(
      severity: Severity.high,
      app: 'infrastructure',
      component: 'errors',
      message: 'Error rate too high: ${infra.errorRate}%',
      recommendation: 'Fix error sources and improve error handling',
    ));
  }

  return HealthCheck(
    checkedAt: DateTime.now(),
    issues: issues,
  );
}

List<Alert> generateAlerts(MonitoringDashboard dashboard) {
  final healthCheck = performHealthCheck(dashboard);
  final alerts = <Alert>[];

  for (final issue in healthCheck.issues) {
    if (issue.severity == Severity.critical || issue.severity == Severity.high) {
      alerts.add(Alert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        type: issue.severity == Severity.critical ? AlertType.critical : AlertType.warning,
        title: '${issue.app}: ${issue.component} issue',
        message: issue.message,
        recommendation: issue.recommendation,
        timestamp: DateTime.now(),
      ));
    }
  }

  return alerts;
}

Future<void> sendAlert(Alert alert, bool verbose) async {
  // In production, this would send alerts via:
  // - Email (SMTP)
  // - Slack webhooks
  // - SMS (Twilio)
  // - PagerDuty
  // - OpsGenie

  if (verbose) {
    print('📤 Sending ${alert.type.name} alert: ${alert.title}');
  }

  // Mock alert sending - replace with real implementation
  print('🚨 ALERT: ${alert.title}');
  print('   ${alert.message}');
  print('   💡 ${alert.recommendation}');
  print('');
}

// Mock data generators (replace with real API calls)
double _mockDailyActiveUsers(String app) => {'finwise': 5000, 'creditwise': 3000, 'rentwise': 2000, 'investwise': 1500}[app] ?? 1000.0;
double _mockMonthlyActiveUsers(String app) => _mockDailyActiveUsers(app) * 25;
double _mockTotalUsers(String app) => _mockMonthlyActiveUsers(app) * 3;
double _mockSessionDuration(String app) => {'finwise': 480, 'creditwise': 600, 'rentwise': 420, 'investwise': 720}[app] ?? 300.0;
double _mockRetentionRate(String app) => {'finwise': 0.75, 'creditwise': 0.70, 'rentwise': 0.80, 'investwise': 0.65}[app] ?? 0.7;
List<String> _mockTopScreens(String app) => ['Dashboard', 'Transactions', 'Settings'];

double _mockCrashFreeUsers(String app) => {'finwise': 98.5, 'creditwise': 97.8, 'rentwise': 99.2, 'investwise': 96.5}[app] ?? 98.0;
int _mockTotalCrashes(String app) => (_mockDailyActiveUsers(app) * (100 - _mockCrashFreeUsers(app)) / 100).round();
double _mockCrashRate(String app) => 100 - _mockCrashFreeUsers(app);
List<String> _mockTopCrashTypes(String app) => ['Network Error', 'UI Freeze', 'Memory Leak'];

double _mockAppLaunchTime(String app) => {'finwise': 1800, 'creditwise': 2200, 'rentwise': 1600, 'investwise': 2400}[app] ?? 2000.0;
double _mockScreenLoadTime(String app) => {'finwise': 800, 'creditwise': 1200, 'rentwise': 600, 'investwise': 1500}[app] ?? 1000.0;
double _mockNetworkSuccess(String app) => {'finwise': 99.5, 'creditwise': 98.8, 'rentwise': 99.7, 'investwise': 97.5}[app] ?? 99.0;
double _mockMemoryUsage(String app) => {'finwise': 45, 'creditwise': 55, 'rentwise': 40, 'investwise': 65}[app] ?? 50.0;
double _mockBatteryImpact(String app) => {'finwise': 2.5, 'creditwise': 3.2, 'rentwise': 2.1, 'investwise': 4.0}[app] ?? 3.0;

double _mockDailySessions(String app) => _mockDailyActiveUsers(app) * 1.5;
double _mockScreenViewsPerSession(String app) => {'finwise': 8.5, 'creditwise': 12.0, 'rentwise': 6.5, 'investwise': 15.0}[app] ?? 10.0;
Map<String, double> _mockFeatureUsage(String app) => {'dashboard': 0.9, 'transactions': 0.7, 'settings': 0.5};
Map<String, double> _mockUserRetention(String app) => {'day1': 0.75, 'day7': 0.45, 'day30': 0.25};

double _mockDailyRevenue(String app) => {'finwise': 250, 'creditwise': 120, 'rentwise': 75, 'investwise': 60}[app] ?? 100.0;
double _mockMonthlyRevenue(String app) => _mockDailyRevenue(app) * 30;
double _mockRevenuePerUser(String app) => _mockMonthlyRevenue(app) / _mockMonthlyActiveUsers(app);
double _mockConversionRate(String app) => {'finwise': 0.15, 'creditwise': 0.12, 'rentwise': 0.18, 'investwise': 0.10}[app] ?? 0.15;
List<String> _mockTopRevenueSources(String app) => ['Subscriptions', 'In-app purchases', 'Ads'];

// Data models
class MonitoringDashboard {
  final DateTime generatedAt;
  final Map<String, AppMetrics> apps;
  final InfrastructureMetrics infrastructure;

  const MonitoringDashboard({
    required this.generatedAt,
    required this.apps,
    required this.infrastructure,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'apps': apps.map((key, value) => MapEntry(key, value.toJson())),
      'infrastructure': infrastructure.toJson(),
    };
  }
}

class AppMetrics {
  final String appName;
  final AnalyticsMetrics analytics;
  final CrashMetrics crashes;
  final PerformanceMetrics performance;
  final EngagementMetrics engagement;
  final RevenueMetrics revenue;
  final DateTime lastUpdated;

  const AppMetrics({
    required this.appName,
    required this.analytics,
    required this.crashes,
    required this.performance,
    required this.engagement,
    required this.revenue,
    required this.lastUpdated,
  });

  factory AppMetrics.empty(String appName) {
    return AppMetrics(
      appName: appName,
      analytics: AnalyticsMetrics.empty(),
      crashes: CrashMetrics.empty(),
      performance: PerformanceMetrics.empty(),
      engagement: EngagementMetrics.empty(),
      revenue: RevenueMetrics.empty(),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'analytics': analytics.toJson(),
      'crashes': crashes.toJson(),
      'performance': performance.toJson(),
      'engagement': engagement.toJson(),
      'revenue': revenue.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

// Metric data classes (simplified)
class AnalyticsMetrics {
  final double dailyActiveUsers;
  final double monthlyActiveUsers;
  final double totalUsers;
  final double sessionDuration;
  final double retentionRate;
  final List<String> topScreens;

  const AnalyticsMetrics({
    required this.dailyActiveUsers,
    required this.monthlyActiveUsers,
    required this.totalUsers,
    required this.sessionDuration,
    required this.retentionRate,
    required this.topScreens,
  });

  factory AnalyticsMetrics.empty() => const AnalyticsMetrics(
    dailyActiveUsers: 0,
    monthlyActiveUsers: 0,
    totalUsers: 0,
    sessionDuration: 0,
    retentionRate: 0,
    topScreens: [],
  );

  Map<String, dynamic> toJson() => {
    'dailyActiveUsers': dailyActiveUsers,
    'monthlyActiveUsers': monthlyActiveUsers,
    'totalUsers': totalUsers,
    'sessionDuration': sessionDuration,
    'retentionRate': retentionRate,
    'topScreens': topScreens,
  };
}

class CrashMetrics {
  final double crashFreeUsers;
  final int totalCrashes;
  final double crashRate;
  final List<String> topCrashTypes;

  const CrashMetrics({
    required this.crashFreeUsers,
    required this.totalCrashes,
    required this.crashRate,
    required this.topCrashTypes,
  });

  factory CrashMetrics.empty() => const CrashMetrics(
    crashFreeUsers: 0,
    totalCrashes: 0,
    crashRate: 0,
    topCrashTypes: [],
  );

  Map<String, dynamic> toJson() => {
    'crashFreeUsers': crashFreeUsers,
    'totalCrashes': totalCrashes,
    'crashRate': crashRate,
    'topCrashTypes': topCrashTypes,
  };
}

class PerformanceMetrics {
  final double averageAppLaunchTime;
  final double averageScreenLoadTime;
  final double networkRequestSuccess;
  final double memoryUsage;
  final double batteryImpact;

  const PerformanceMetrics({
    required this.averageAppLaunchTime,
    required this.averageScreenLoadTime,
    required this.networkRequestSuccess,
    required this.memoryUsage,
    required this.batteryImpact,
  });

  factory PerformanceMetrics.empty() => const PerformanceMetrics(
    averageAppLaunchTime: 0,
    averageScreenLoadTime: 0,
    networkRequestSuccess: 0,
    memoryUsage: 0,
    batteryImpact: 0,
  );

  Map<String, dynamic> toJson() => {
    'averageAppLaunchTime': averageAppLaunchTime,
    'averageScreenLoadTime': averageScreenLoadTime,
    'networkRequestSuccess': networkRequestSuccess,
    'memoryUsage': memoryUsage,
    'batteryImpact': batteryImpact,
  };
}

class EngagementMetrics {
  final double dailySessions;
  final double averageSessionDuration;
  final double screenViewsPerSession;
  final Map<String, double> featureUsage;
  final Map<String, double> userRetention;

  const EngagementMetrics({
    required this.dailySessions,
    required this.averageSessionDuration,
    required this.screenViewsPerSession,
    required this.featureUsage,
    required this.userRetention,
  });

  factory EngagementMetrics.empty() => const EngagementMetrics(
    dailySessions: 0,
    averageSessionDuration: 0,
    screenViewsPerSession: 0,
    featureUsage: {},
    userRetention: {},
  );

  Map<String, dynamic> toJson() => {
    'dailySessions': dailySessions,
    'averageSessionDuration': averageSessionDuration,
    'screenViewsPerSession': screenViewsPerSession,
    'featureUsage': featureUsage,
    'userRetention': userRetention,
  };
}

class RevenueMetrics {
  final double dailyRevenue;
  final double monthlyRevenue;
  final double averageRevenuePerUser;
  final double conversionRate;
  final List<String> topRevenueSources;

  const RevenueMetrics({
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.averageRevenuePerUser,
    required this.conversionRate,
    required this.topRevenueSources,
  });

  factory RevenueMetrics.empty() => const RevenueMetrics(
    dailyRevenue: 0,
    monthlyRevenue: 0,
    averageRevenuePerUser: 0,
    conversionRate: 0,
    topRevenueSources: [],
  );

  Map<String, dynamic> toJson() => {
    'dailyRevenue': dailyRevenue,
    'monthlyRevenue': monthlyRevenue,
    'averageRevenuePerUser': averageRevenuePerUser,
    'conversionRate': conversionRate,
    'topRevenueSources': topRevenueSources,
  };
}

class InfrastructureMetrics {
  final double apiUptime;
  final int databaseConnections;
  final double serverResponseTime;
  final double errorRate;
  final double bandwidthUsage;
  final double storageUsage;

  const InfrastructureMetrics({
    required this.apiUptime,
    required this.databaseConnections,
    required this.serverResponseTime,
    required this.errorRate,
    required this.bandwidthUsage,
    required this.storageUsage,
  });

  Map<String, dynamic> toJson() => {
    'apiUptime': apiUptime,
    'databaseConnections': databaseConnections,
    'serverResponseTime': serverResponseTime,
    'errorRate': errorRate,
    'bandwidthUsage': bandwidthUsage,
    'storageUsage': storageUsage,
  };
}

enum Severity { critical, high, medium, low, info }

class HealthIssue {
  final Severity severity;
  final String app;
  final String component;
  final String message;
  final String recommendation;

  const HealthIssue({
    required this.severity,
    required this.app,
    required this.component,
    required this.message,
    required this.recommendation,
  });
}

class HealthCheck {
  final DateTime checkedAt;
  final List<HealthIssue> issues;

  const HealthCheck({
    required this.checkedAt,
    required this.issues,
  });

  bool get hasCriticalIssues => issues.any((i) => i.severity == Severity.critical);
  bool get hasWarnings => issues.any((i) => i.severity == Severity.high);
  bool get isHealthy => !hasCriticalIssues && !hasWarnings;

  Map<String, dynamic> toJson() {
    return {
      'checkedAt': checkedAt.toIso8601String(),
      'issues': issues.map((i) => {
        'severity': i.severity.name,
        'app': i.app,
        'component': i.component,
        'message': i.message,
        'recommendation': i.recommendation,
      }).toList(),
      'hasCriticalIssues': hasCriticalIssues,
      'hasWarnings': hasWarnings,
      'isHealthy': isHealthy,
    };
  }
}

enum AlertType { critical, warning, info }

class Alert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final String recommendation;
  final DateTime timestamp;

  const Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.timestamp,
  });
}

// Output formatting functions
void printDashboard(MonitoringDashboard dashboard) {
  print('📊 FinWise Ecosystem Monitoring Dashboard');
  print('=========================================');
  print('Generated: ${dashboard.generatedAt}');
  print('');

  print('🏗️  Infrastructure:');
  final infra = dashboard.infrastructure;
  print('  API Uptime: ${infra.apiUptime}%');
  print('  Error Rate: ${infra.errorRate}%');
  print('  Response Time: ${infra.serverResponseTime}ms');
  print('');

  for (final entry in dashboard.apps.entries) {
    final appName = entry.key;
    final metrics = entry.value;

    print('📱 $appName:');
    print('  👥 Users: ${metrics.analytics.dailyActiveUsers.toInt()} DAU, ${metrics.analytics.totalUsers.toInt()} total');
    print('  💥 Crashes: ${metrics.crashes.crashRate}% rate, ${metrics.crashes.crashFreeUsers}% crash-free');
    print('  ⚡ Performance: ${metrics.performance.averageAppLaunchTime.toInt()}ms launch');
    print('  💰 Revenue: \$${metrics.revenue.dailyRevenue.toStringAsFixed(0)}/day');
    print('');
  }
}

void printHealthCheck(HealthCheck check) {
  print('🏥 System Health Check');
  print('====================');
  print('Checked: ${check.checkedAt}');
  print('');

  if (check.isHealthy) {
    print('✅ ALL SYSTEMS HEALTHY');
    return;
  }

  final critical = check.issues.where((i) => i.severity == Severity.critical).length;
  final high = check.issues.where((i) => i.severity == Severity.high).length;
  final medium = check.issues.where((i) => i.severity == Severity.medium).length;
  final low = check.issues.where((i) => i.severity == Severity.low).length;

  print('📊 Issues Found:');
  print('  🔴 Critical: $critical');
  print('  🟠 High: $high');
  print('  🟡 Medium: $medium');
  print('  🔵 Low: $low');
  print('');

  for (final issue in check.issues) {
    final icon = issue.severity == Severity.critical ? '🔴' :
                issue.severity == Severity.high ? '🟠' :
                issue.severity == Severity.medium ? '🟡' : '🔵';
    print('$icon ${issue.app} - ${issue.component}: ${issue.message}');
    print('   💡 ${issue.recommendation}');
    print('');
  }
}

String generateMarkdownDashboard(MonitoringDashboard dashboard) {
  final buffer = StringBuffer();

  buffer.writeln('# 📊 FinWise Ecosystem Monitoring Dashboard');
  buffer.writeln('');
  buffer.writeln('Generated: ${dashboard.generatedAt}');
  buffer.writeln('');

  buffer.writeln('## 🏗️ Infrastructure');
  buffer.writeln('');
  final infra = dashboard.infrastructure;
  buffer.writeln('- **API Uptime**: ${infra.apiUptime}%');
  buffer.writeln('- **Error Rate**: ${infra.errorRate}%');
  buffer.writeln('- **Response Time**: ${infra.serverResponseTime}ms');
  buffer.writeln('- **Storage Usage**: ${infra.storageUsage}%');
  buffer.writeln('');

  for (final entry in dashboard.apps.entries) {
    final appName = entry.key;
    final metrics = entry.value;

    buffer.writeln('## 📱 $appName');
    buffer.writeln('');

    buffer.writeln('### 👥 User Metrics');
    buffer.writeln('- **Daily Active Users**: ${metrics.analytics.dailyActiveUsers.toInt()}');
    buffer.writeln('- **Monthly Active Users**: ${metrics.analytics.monthlyActiveUsers.toInt()}');
    buffer.writeln('- **Total Users**: ${metrics.analytics.totalUsers.toInt()}');
    buffer.writeln('- **Retention Rate**: ${(metrics.analytics.retentionRate * 100).toFixed(1)}%');
    buffer.writeln('');

    buffer.writeln('### 💥 Reliability');
    buffer.writeln('- **Crash Rate**: ${metrics.crashes.crashRate.toStringAsFixed(2)}%');
    buffer.writeln('- **Crash-Free Users**: ${metrics.crashes.crashFreeUsers.toStringAsFixed(1)}%');
    buffer.writeln('');

    buffer.writeln('### ⚡ Performance');
    buffer.writeln('- **App Launch Time**: ${metrics.performance.averageAppLaunchTime.toInt()}ms');
    buffer.writeln('- **Screen Load Time**: ${metrics.performance.averageScreenLoadTime.toInt()}ms');
    buffer.writeln('- **Network Success**: ${metrics.performance.networkRequestSuccess.toStringAsFixed(1)}%');
    buffer.writeln('');

    buffer.writeln('### 💰 Revenue');
    buffer.writeln('- **Daily Revenue**: \$${metrics.revenue.dailyRevenue.toStringAsFixed(2)}');
    buffer.writeln('- **Monthly Revenue**: \$${metrics.revenue.monthlyRevenue.toStringAsFixed(2)}');
    buffer.writeln('- **ARPU**: \$${metrics.revenue.averageRevenuePerUser.toStringAsFixed(2)}');
    buffer.writeln('- **Conversion Rate**: ${(metrics.revenue.conversionRate * 100).toFixed(1)}%');
    buffer.writeln('');
  }

  return buffer.toString();
}