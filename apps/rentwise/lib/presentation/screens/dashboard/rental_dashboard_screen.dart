import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import '../../../data/models/rental_models.dart';
import '../../providers/rental_providers.dart';

class RentalDashboardScreen extends ConsumerStatefulWidget {
  const RentalDashboardScreen({super.key});

  @override
  ConsumerState<RentalDashboardScreen> createState() => _RentalDashboardScreenState();
}

class _RentalDashboardScreenState extends ConsumerState<RentalDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(rentalDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RentWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(rentalDashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          dashboardState.isLoading
              ? const _LoadingView()
              : dashboardState.error != null
                  ? _ErrorView(error: dashboardState.error!)
                  : _DashboardContent(state: dashboardState),
          // Show attention pulses for important rental notifications
          if (dashboardState.properties.isNotEmpty)
            _buildAttentionNotifications(context, dashboardState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAttentionNotifications(BuildContext context, RentalDashboardState state) {
    final notifications = <Widget>[];

    // Check for upcoming payments due soon
    final upcomingPayments = state.properties
        .where((property) => property.daysUntilRentDue <= 3)
        .toList();

    if (upcomingPayments.isNotEmpty) {
      notifications.add(
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: MeaningfulInteractions().createAttentionPulse(
            child: Container(),
            type: AttentionType.action,
            message: 'Rent payment due in ${upcomingPayments.first.daysUntilRentDue} days for ${upcomingPayments.first.name}',
            onAcknowledged: () => Navigator.pushNamed(context, '/payments'),
          ),
        ),
      );
    }

    // Check for lease expiration warnings
    final expiringLeases = state.properties
        .where((property) => property.isLeaseExpiringSoon)
        .toList();

    if (expiringLeases.isNotEmpty) {
      notifications.add(
        Positioned(
          top: expiringLeases.isNotEmpty && upcomingPayments.isNotEmpty ? 100 : 20,
          left: 20,
          right: 20,
          child: MeaningfulInteractions().createAttentionPulse(
            child: Container(),
            type: AttentionType.warning,
            message: 'Lease expires in ${expiringLeases.first.daysUntilLeaseExpires} days - time to plan ahead!',
            onAcknowledged: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lease renewal planning initiated')),
            ),
          ),
        ),
      );
    }

    // Show habit streak for consistent rent payments
    final currentStreak = 12; // Mock streak data
    final bestStreak = 15;
    final isTodayComplete = true;

    notifications.add(
      Positioned(
        bottom: 100,
        right: 20,
        child: MeaningfulInteractions().createHabitStreak(
          habit: 'Timely Rent Payments',
          streakDays: currentStreak,
          bestStreak: bestStreak,
          isTodayComplete: isTodayComplete,
          onMaintainStreak: () => Navigator.pushNamed(context, '/payments'),
        ),
      ),
    );

    return Stack(children: notifications);
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Add Property'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to add property
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pay Rent'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Report Maintenance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/maintenance');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Contact Landlord'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/communication');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePropertySwipeAction(RentalProperty property) {
    // Handle different swipe actions for properties
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action triggered for ${property.name}')),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your rental dashboard...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load rental data',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry logic would be handled by parent
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.state});

  final RentalDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rentalDashboardProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.properties.isEmpty)
              _buildEmptyState(context)
            else ...[
              _buildRentOverview(context, ref),
              const SizedBox(height: 24),
              _buildPropertiesList(context, state.properties),
              const SizedBox(height: 24),
              _buildUpcomingPayments(context, ref),
              const SizedBox(height: 24),
              _buildMaintenanceAlerts(context, ref),
              const SizedBox(height: 24),
              _buildRecentActivity(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_work,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to RentWise!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Add your first rental property to start managing your rent payments, maintenance, and communication with landlords.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add property
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Property'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentOverview(BuildContext context, WidgetRef ref) {
    final totalMonthlyRent = state.properties.fold<double>(
      0,
      (sum, property) => sum + property.monthlyRent,
    );

    final activeProperties = state.properties.where((p) => p.status == 'active').length;
    final expiringLeases = state.properties.where((p) => p.isLeaseExpiringSoon).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.blue.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Rent Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${totalMonthlyRent.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const Text(
            'Monthly rent total',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                '$activeProperties',
                'Active Properties',
                Colors.green,
              ),
              if (expiringLeases > 0) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  '$expiringLeases',
                  'Leases Expiring',
                  Colors.orange,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Show savings impact for good rental habits
          MeaningfulInteractions().createSavingsImpact(
            action: 'Maintaining on-time payments',
            dailySavings: 0.0, // This would be calculated based on potential late fees
            timeframeDays: 365,
            onStartSaving: () => Navigator.pushNamed(context, '/payments'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(BuildContext context, List<RentalProperty> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Properties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to properties screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...properties.take(2).map((property) {
          final propertyCard = Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPropertyIcon(property.propertyType),
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${property.address}, ${property.unit}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          property.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPropertyMetric(
                          '\$${property.monthlyRent.toStringAsFixed(0)}',
                          'Monthly Rent',
                        ),
                      ),
                      Expanded(
                        child: _buildPropertyMetric(
                          property.leaseStatusDescription,
                          'Lease Status',
                        ),
                      ),
                    ],
                  ),
                  if (property.isLeaseExpiringSoon) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Lease expires in ${property.daysUntilLeaseExpires} days',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

          return MeaningfulInteractions().createSwipeAction(
            child: propertyCard,
            actions: [
              SwipeAction(
                SwipeActionType.pay,
                'Pay Rent',
                Icons.payment,
                Colors.green,
                'Make your rent payment for ${property.name}',
              ),
              SwipeAction(
                SwipeActionType.analyze,
                'View Details',
                Icons.visibility,
                Colors.blue,
                'See detailed information about this property',
              ),
              SwipeAction(
                SwipeActionType.save,
                'Save Receipt',
                Icons.bookmark,
                Colors.purple,
                'Save this property information for quick access',
              ),
            ],
            primaryAction: SwipeActionType.pay,
            onActionTriggered: () => _handlePropertySwipeAction(property),
          );
        }),
      ],
    );
  }

  Widget _buildPropertyMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getPropertyIcon(String propertyType) {
    switch (propertyType) {
      case 'apartment':
        return Icons.apartment;
      case 'house':
        return Icons.house;
      case 'condo':
        return Icons.business;
      default:
        return Icons.home;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUpcomingPayments(BuildContext context, WidgetRef ref) {
    final upcomingPayments = ref.watch(upcomingPaymentsProvider);

    return upcomingPayments.when(
      data: (payments) {
        if (payments.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Payments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/payments'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...payments.take(3).map((payment) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: payment.isDueSoon
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: payment.isDueSoon ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Due ${payment.dueDate.toString().split(' ')[0]}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (payment.isDueSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Due Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to payment screen
                        },
                        child: const Text('Pay Now'),
                      ),
                  ],
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMaintenanceAlerts(BuildContext context, WidgetRef ref) {
    // Mock maintenance alerts for now
    final alerts = <MaintenanceRequest>[];

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maintenance Updates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Maintenance alerts would go here
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwipeableActivity(
          'Rent payment processed',
          'Springfield Apartments - \$1,200.00',
          Icons.payment,
          Colors.green,
          '2h ago',
          [
            SwipeAction(
              SwipeActionType.save,
              'Save Receipt',
              Icons.bookmark,
              Colors.green,
              'Save this payment receipt for records',
            ),
            SwipeAction(
              SwipeActionType.analyze,
              'View Details',
              Icons.visibility,
              Colors.blue,
              'See detailed payment information',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSwipeableActivity(
          'Lease agreement uploaded',
          'Oakwood Heights',
          Icons.description,
          Colors.blue,
          '1d ago',
          [
            SwipeAction(
              SwipeActionType.analyze,
              'Review Document',
              Icons.visibility,
              Colors.blue,
              'Review your lease agreement details',
            ),
            SwipeAction(
              SwipeActionType.save,
              'Download',
              Icons.download,
              Colors.purple,
              'Download a copy of your lease',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSwipeableActivity(
          'Message sent to landlord',
          'Maintenance request follow-up',
          Icons.message,
          Colors.orange,
          '2d ago',
          [
            SwipeAction(
              SwipeActionType.analyze,
              'View Conversation',
              Icons.chat,
              Colors.orange,
              'See the full conversation thread',
            ),
            SwipeAction(
              SwipeActionType.pay,
              'Schedule Follow-up',
              Icons.schedule,
              Colors.red,
              'Set a reminder for follow-up',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwipeableActivity(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String timeAgo,
    List<SwipeAction> actions,
  ) {
    final activityCard = Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(timeAgo, style: TextStyle(color: Colors.grey[500])),
      ),
    );

    return MeaningfulInteractions().createSwipeAction(
      child: activityCard,
      actions: actions,
      primaryAction: actions.first.type,
      onActionTriggered: () => _handleActivitySwipeAction(actions.first),
    );
  }

  void _handleActivitySwipeAction(SwipeAction action) {
    // Handle different swipe actions for activities
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${action.label} action triggered')),
    );
  }
}
