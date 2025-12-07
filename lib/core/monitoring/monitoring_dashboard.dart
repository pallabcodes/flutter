import 'dart:async';
import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/core/monitoring/health_monitor.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Real-time monitoring dashboard for production analytics
/// Enterprise-grade monitoring with live metrics and alerts
class MonitoringDashboard extends StatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends State<MonitoringDashboard>
    with TickerProviderStateMixin {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final AnalyticsService _analyticsService = AnalyticsService();
  final HealthMonitor _healthMonitor = HealthMonitor();

  late TabController _tabController;
  final List<PerformanceEvent> _performanceEvents = [];
  final List<AnalyticsEvent> _analyticsEvents = [];
  final List<HealthEvent> _healthEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _initializeMonitoring();
  }

  Future<void> _initializeMonitoring() async {
    await _performanceMonitor.initialize();
    await _analyticsService.initialize();
    await _healthMonitor.initialize();

    // Listen to events
    _performanceMonitor.events.listen((event) {
      setState(() => _performanceEvents.insert(0, event));
    });

    _analyticsService.events.listen((event) {
      setState(() => _analyticsEvents.insert(0, event));
    });

    _healthMonitor.events.listen((event) {
      setState(() => _healthEvents.insert(0, event));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildAnalyticsTab(),
          _buildHealthTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final performanceSummary = _performanceMonitor.getPerformanceSummary();
    final analyticsSummary = _analyticsService.getAnalyticsSummary();
    final healthStatus = _healthMonitor.getHealthStatus();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          Card(
            color: _getHealthColor(performanceSummary.healthScore),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getHealthIcon(performanceSummary.healthScore),
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Health: ${performanceSummary.healthScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getHealthMessage(performanceSummary.healthScore),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                'App Startup',
                '${performanceSummary.averageAppStartupTime?.inMilliseconds ?? 0}ms',
                Icons.timer,
                Colors.blue,
              ),
              _buildMetricCard(
                'API Response',
                '${performanceSummary.averageApiCallTime?.inMilliseconds ?? 0}ms',
                Icons.network_check,
                Colors.green,
              ),
              _buildMetricCard(
                'Memory Usage',
                '${performanceSummary.currentMemoryUsage?.toStringAsFixed(1) ?? '0'}%',
                Icons.memory,
                Colors.orange,
              ),
              _buildMetricCard(
                'Total Events',
                performanceSummary.totalMetrics.toString(),
                Icons.event,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent Alerts
          const Text(
            'Recent Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._getRecentAlerts().map((alert) => Card(
            child: ListTile(
              leading: Icon(
                _getAlertIcon(alert.severity),
                color: _getAlertColor(alert.severity),
              ),
              title: Text(alert.message),
              subtitle: Text(alert.timestamp.toString()),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final metrics = _performanceMonitor.getCurrentMetrics().values.toList();

    return Column(
      children: [
        // Performance Charts
        Expanded(
          child: SfCartesianChart(
            title: ChartTitle(text: 'Performance Metrics Over Time'),
            legend: Legend(isVisible: true),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries>[
              LineSeries<PerformanceMetric, DateTime>(
                name: 'App Startup (ms)',
                dataSource: metrics.where((m) => m.name == 'app_startup').toList(),
                xValueMapper: (metric, _) => metric.timestamp,
                yValueMapper: (metric, _) => metric.value,
                color: Colors.blue,
              ),
              LineSeries<PerformanceMetric, DateTime>(
                name: 'API Calls (ms)',
                dataSource: metrics.where((m) => m.name.contains('api_call')).toList(),
                xValueMapper: (metric, _) => metric.timestamp,
                yValueMapper: (metric, _) => metric.value,
                color: Colors.green,
              ),
            ],
          ),
        ),

        // Performance Events List
        Expanded(
          child: ListView.builder(
            itemCount: _performanceEvents.length,
            itemBuilder: (context, index) {
              final event = _performanceEvents[index];
              return ListTile(
                leading: Icon(
                  _getPerformanceIcon(event.type),
                  color: _getPerformanceColor(event.severity),
                ),
                title: Text(event.message),
                subtitle: Text(event.timestamp.toString()),
                trailing: Text(event.severity.name.toUpperCase()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return FutureBuilder<AnalyticsSummary>(
      future: _analyticsService.getAnalyticsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analytics Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Events',
                      summary.totalEvents.toString(),
                      Icons.event,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Unique Users',
                      summary.uniqueUsers.toString(),
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Avg Session',
                      '${summary.sessionDuration.inMinutes}m',
                      Icons.timer,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Conversion Rate',
                      '${(summary.conversionRate * 100).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Top Events Chart
              if (summary.topEvents.isNotEmpty) ...[
                const Text(
                  'Top Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SfCartesianChart(
                  series: <CartesianSeries>[
                    BarSeries<String, String>(
                      dataSource: summary.topEvents,
                      xValueMapper: (event, _) => event,
                      yValueMapper: (event, _) => 1, // Mock data
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Analytics Events List
              const Text(
                'Recent Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._analyticsEvents.take(10).map((event) => Card(
                child: ListTile(
                  title: Text(event.name),
                  subtitle: Text(event.parameters.toString()),
                  trailing: Text(event.timestamp.toString()),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthTab() {
    final healthStatus = _healthMonitor.getHealthStatus();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Health Status
          Card(
            color: healthStatus['overall_status'] == 'healthy' ? Colors.green : Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    healthStatus['overall_status'] == 'healthy'
                        ? Icons.check_circle
                        : Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status: ${healthStatus['overall_status']?.toString().toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last checked: ${healthStatus['timestamp']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Service Health Cards
          const Text(
            'Service Health',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildServiceHealthCard('API', healthStatus['api_status']),
              _buildServiceHealthCard('Database', healthStatus['database_status']),
              _buildServiceHealthCard('Firebase', healthStatus['firebase_status']),
              _buildServiceHealthCard('Storage', healthStatus['storage_status']),
            ],
          ),

          const SizedBox(height: 16),

          // Health Events
          const Text(
            'Recent Health Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._healthEvents.take(10).map((event) => Card(
            child: ListTile(
              leading: Icon(
                _getHealthEventIcon(event.type),
                color: _getHealthEventColor(event.status),
              ),
              title: Text(event.message),
              subtitle: Text(event.timestamp.toString()),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHealthCard(String serviceName, dynamic status) {
    final isHealthy = status.toString().toLowerCase() == 'healthy';
    return Card(
      color: isHealthy ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              color: isHealthy ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              serviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              status.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isHealthy ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for styling and icons
  Color _getHealthColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getHealthIcon(double score) {
    if (score >= 90) return Icons.sentiment_very_satisfied;
    if (score >= 70) return Icons.sentiment_satisfied;
    return Icons.sentiment_dissatisfied;
  }

  String _getHealthMessage(double score) {
    if (score >= 90) return 'System performing optimally';
    if (score >= 70) return 'Minor performance issues detected';
    return 'Critical performance issues require attention';
  }

  List<PerformanceEvent> _getRecentAlerts() {
    return _performanceEvents
        .where((event) => event.severity != PerformanceSeverity.info)
        .take(5)
        .toList();
  }

  Color _getAlertColor(PerformanceSeverity severity) {
    switch (severity) {
      case PerformanceSeverity.info: return Colors.blue;
      case PerformanceSeverity.warning: return Colors.orange;
      case PerformanceSeverity.error: return Colors.red;
      case PerformanceSeverity.critical: return Colors.purple;
    }
  }

  IconData _getAlertIcon(PerformanceSeverity severity) {
    switch (severity) {
      case PerformanceSeverity.info: return Icons.info;
      case PerformanceSeverity.warning: return Icons.warning;
      case PerformanceSeverity.error: return Icons.error;
      case PerformanceSeverity.critical: return Icons.report_problem;
    }
  }

  Color _getPerformanceColor(PerformanceSeverity severity) {
    switch (severity) {
      case PerformanceSeverity.info: return Colors.blue;
      case PerformanceSeverity.warning: return Colors.orange;
      case PerformanceSeverity.error: return Colors.red;
      case PerformanceSeverity.critical: return Colors.purple;
    }
  }

  IconData _getPerformanceIcon(String type) {
    switch (type) {
      case 'app_startup': return Icons.timer;
      case 'api_call': return Icons.network_check;
      case 'memory_usage': return Icons.memory;
      case 'frame_drop': return Icons.warning;
      default: return Icons.info;
    }
  }

  Color _getHealthEventColor(String status) {
    return status.toLowerCase() == 'healthy' ? Colors.green : Colors.red;
  }

  IconData _getHealthEventIcon(String type) {
    switch (type) {
      case 'service_check': return Icons.health_and_safety;
      case 'api_failure': return Icons.network_check;
      case 'database_issue': return Icons.storage;
      default: return Icons.info;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceMonitor.dispose();
    _analyticsService.dispose();
    _healthMonitor.dispose();
    super.dispose();
  }
}

/// Monitoring overlay for development
class MonitoringOverlay extends StatelessWidget {
  final Widget child;
  final bool showPerformance;
  final bool showAnalytics;

  const MonitoringOverlay({
    super.key,
    required this.child,
    this.showPerformance = true,
    this.showAnalytics = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showPerformance) const Positioned(
          top: 100,
          right: 10,
          child: PerformanceMonitorWidget(),
        ),
        if (showAnalytics) const Positioned(
          top: 200,
          right: 10,
          child: AnalyticsDashboardWidget(),
        ),
      ],
    );
  }
}

/// Compact performance monitor widget
class PerformanceMonitorWidget extends StatefulWidget {
  const PerformanceMonitorWidget({super.key});

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
    return StreamBuilder<PerformanceEvent>(
      stream: _monitor.events,
      builder: (context, snapshot) {
        final summary = _monitor.getPerformanceSummary();

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Health: ${summary.healthScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: summary.healthScore > 80 ? Colors.green : Colors.red,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact analytics widget
class AnalyticsDashboardWidget extends StatefulWidget {
  const AnalyticsDashboardWidget({super.key});

  @override
  State<AnalyticsDashboardWidget> createState() => _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState extends State<AnalyticsDashboardWidget> {
  final AnalyticsService _analytics = AnalyticsService();
  int _eventCount = 0;

  @override
  void initState() {
    super.initState();
    _analytics.events.listen((event) {
      setState(() => _eventCount++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Events: $_eventCount',
            style: const TextStyle(color: Colors.blue, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

/// Alert notification system
class AlertSystem {
  static final AlertSystem _instance = AlertSystem._internal();
  factory AlertSystem() => _instance;
  AlertSystem._internal();

  final StreamController<Alert> _alertController = StreamController<Alert>.broadcast();

  Stream<Alert> get alerts => _alertController.stream;

  void sendAlert(Alert alert) {
    if (!_alertController.isClosed) {
      _alertController.add(alert);
    }
  }

  void dispose() {
    _alertController.close();
  }
}

/// Alert data class
class Alert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Alert({
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

/// Alert notification widget
class AlertBanner extends StatefulWidget {
  const AlertBanner({super.key});

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  final AlertSystem _alertSystem = AlertSystem();
  Alert? _currentAlert;

  @override
  void initState() {
    super.initState();
    _alertSystem.alerts.listen((alert) {
      setState(() => _currentAlert = alert);
      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _currentAlert = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAlert == null) return const SizedBox.shrink();

    return Container(
      color: _getAlertColor(_currentAlert!.severity),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(_currentAlert!.severity),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAlert!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentAlert!.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _currentAlert = null),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info: return Colors.blue;
      case AlertSeverity.warning: return Colors.orange;
      case AlertSeverity.error: return Colors.red;
      case AlertSeverity.critical: return Colors.purple;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info: return Icons.info;
      case AlertSeverity.warning: return Icons.warning;
      case AlertSeverity.error: return Icons.error;
      case AlertSeverity.critical: return Icons.report_problem;
    }
  }
}
