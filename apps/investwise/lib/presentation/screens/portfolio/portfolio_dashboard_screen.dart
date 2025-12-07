import 'package:flutter/material.dart';

class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InvestWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _heroCard(context),
            const SizedBox(height: 16),
            _statRow(context),
            const SizedBox(height: 16),
            _placeholderCard(
              context,
              title: 'Portfolio performance',
              subtitle: 'Charts and insights coming soon.',
              icon: Icons.show_chart,
            ),
            const SizedBox(height: 12),
            _placeholderCard(
              context,
              title: 'Holdings',
              subtitle: 'Your assets will appear here.',
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _placeholderCard(
              context,
              title: 'Goals',
              subtitle: 'Track your investment goals.',
              icon: Icons.flag,
            ),
            const SizedBox(height: 12),
            _placeholderCard(
              context,
              title: 'Recent activity',
              subtitle: 'Transactions and updates will show here.',
              icon: Icons.history,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Invest'),
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total balance',
                style: textTheme.labelLarge?.copyWith(color: Colors.grey[700]),
              ),
              const Icon(Icons.trending_up, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$0.00',
            style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '+0.0% today',
            style: textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_circle),
            label: const Text('Start investing'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            context,
            label: 'Auto-invest',
            value: 'Off',
            icon: Icons.savings,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            context,
            label: 'Risk level',
            value: 'Moderate',
            icon: Icons.insights,
          ),
        ),
      ],
    );
  }

  Widget _statTile(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Icon(icon, color: Colors.green[700], size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderCard(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withOpacity(0.08),
            child: Icon(icon, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
