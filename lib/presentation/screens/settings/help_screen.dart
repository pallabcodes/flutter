import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: ListView(
        children: [
          _buildSearchBar(),
          _buildQuickActions(),
          _buildFAQSection(),
          _buildTutorialsSection(),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search help articles...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spacingMD,
            crossAxisSpacing: AppTheme.spacingMD,
            children: [
              _buildQuickActionCard(
                'Getting Started',
                'Learn the basics of FinWise',
                Icons.play_circle,
                Colors.blue,
              ),
              _buildQuickActionCard(
                'Add Expenses',
                'How to track your spending',
                Icons.add_circle,
                Colors.green,
              ),
              _buildQuickActionCard(
                'Budget Setup',
                'Create and manage budgets',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
              _buildQuickActionCard(
                'Receipt Scanning',
                'Use AI to scan receipts',
                Icons.document_scanner,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to specific help article
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'How do I add a new expense?',
        'answer': 'Tap the + button on the home screen, fill in the expense details, and optionally scan a receipt.',
      },
      {
        'question': 'How does receipt scanning work?',
        'answer': 'Take a photo of your receipt. FinWise uses AI to automatically extract the amount, merchant, and date.',
      },
      {
        'question': 'Can I edit or delete expenses?',
        'answer': 'Yes, tap on any expense in the list to view details, then use the edit or delete options.',
      },
      {
        'question': 'How do budgets work?',
        'answer': 'Create budgets for different categories and time periods. FinWise will track your spending and alert you when approaching limits.',
      },
      {
        'question': 'Is my data secure?',
        'answer': 'Yes, all data is encrypted and stored securely. We use industry-standard security measures.',
      },
      {
        'question': 'Can I export my data?',
        'answer': 'Yes, go to Settings > Export Data to download your expenses in CSV or PDF format.',
      },
    ];

    return ExpansionPanelList(
      expansionCallback: (index, isExpanded) {
        // TODO: Handle expansion state
      },
      children: faqs.map((faq) {
        return ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text(faq['question']!),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Text(faq['answer']!),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTutorialsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Tutorials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildTutorialCard(
            'Welcome to FinWise',
            '2:30',
            'Get started with your expense tracking journey',
          ),
          _buildTutorialCard(
            'Advanced Budgeting',
            '4:15',
            'Master budget creation and spending analysis',
          ),
          _buildTutorialCard(
            'Receipt Scanning Tips',
            '1:45',
            'Get the most out of AI receipt scanning',
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(String title, String duration, String description) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.play_arrow, color: Colors.grey),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              'Duration: $duration',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Play tutorial video
        },
      ),
    );
  }

  Widget _buildContactSupport() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          const Text(
            'Still need help? Our support team is here to assist you.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email Support'),
                    subtitle: const Text('support@finwise.app'),
                    onTap: () {
                      // TODO: Open email client
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Live Chat'),
                    subtitle: const Text('Available 9 AM - 6 PM EST'),
                    onTap: () {
                      // TODO: Open live chat
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_center),
                    title: const Text('Community Forum'),
                    subtitle: const Text('Get help from other users'),
                    onTap: () {
                      // TODO: Open community forum
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
