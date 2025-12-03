import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacingLG),
            _buildLastUpdated(),
            const SizedBox(height: AppTheme.spacingLG),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip,
            color: Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How we collect, use, and protect your data',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Text(
      'Last updated: January 15, 2025',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '1. Information We Collect',
          'We collect information you provide directly to us, such as when you create an account, add expenses, or contact support. This includes your email address, expense data, and any receipts you upload.',
        ),

        _buildSection(
          '2. How We Use Your Information',
          'We use your information to:\n\n'
          '• Provide and maintain the FinWise service\n'
          '• Process and analyze your expense data\n'
          '• Send you important updates and notifications\n'
          '• Improve our services and develop new features\n'
          '• Ensure security and prevent fraud',
        ),

        _buildSection(
          '3. Data Storage and Security',
          'Your data is encrypted both in transit and at rest using industry-standard AES-256 encryption. We use secure cloud infrastructure and implement multiple layers of security to protect your information.',
        ),

        _buildSection(
          '4. Data Sharing',
          'We do not sell or share your personal data with third parties for marketing purposes. We may share anonymized, aggregated data for analytics and service improvement. We only share personal data when required by law or with your explicit consent.',
        ),

        _buildSection(
          '5. Your Rights',
          'You have the right to:\n\n'
          '• Access your personal data\n'
          '• Correct inaccurate information\n'
          '• Delete your account and data\n'
          '• Export your data\n'
          '• Object to certain data processing\n'
          '• Withdraw consent at any time',
        ),

        _buildSection(
          '6. Cookies and Analytics',
          'We use analytics tools to understand how our app is used and to improve the user experience. You can opt out of analytics tracking in the app settings.',
        ),

        _buildSection(
          '7. Third-Party Services',
          'FinWise integrates with Firebase for authentication and cloud services, and Google ML Kit for receipt scanning. These services have their own privacy policies, which we encourage you to review.',
        ),

        _buildSection(
          '8. Data Retention',
          'We retain your data for as long as your account is active or as needed to provide services. You can request deletion of your data at any time.',
        ),

        _buildSection(
          '9. International Data Transfers',
          'Your data may be processed and stored in different countries. We ensure appropriate safeguards are in place for international data transfers.',
        ),

        _buildSection(
          '10. Changes to This Policy',
          'We may update this privacy policy from time to time. We will notify you of any material changes via email or in-app notification.',
        ),

        _buildSection(
          '11. Contact Us',
          'If you have any questions about this privacy policy or our data practices, please contact us at:\n\n'
          'Email: privacy@finwise.app\n'
          'Address: FinWise Privacy Team',
        ),

        const SizedBox(height: AppTheme.spacingXXL),

        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'By using FinWise, you acknowledge that you have read and understood this Privacy Policy.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
