import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/core/monitoring/monitoring_dashboard.dart';
import 'package:finwise/core/localization/localization_service.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:finwise/presentation/providers/theme_providers.dart';
import 'package:finwise/presentation/screens/debug/oauth_debug_screen.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/error_boundary.dart';
import 'package:finwise/presentation/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comprehensive settings screen for FinWise
/// Includes app settings, user preferences, and account management
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final userPreferences = ref.watch(userPreferencesProvider);

    return ScreenErrorBoundary(
      screenName: 'Settings',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            // Connectivity indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: connectionStatus.displayName,
                child: Icon(
                  connectionStatus.icon,
                  color: connectionStatus.isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
            ),
            // Sync status indicator
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SyncStatusIndicator(),
            ),
          ],
        ),
      body: ListView(
        children: [
          // User Profile Section
          _buildUserProfileSection(currentUser),

          const Divider(),

          // App Preferences
          _buildAppPreferencesSection(),

          const Divider(),

          // Account Management
          _buildAccountManagementSection(),

          const Divider(),

          // Support & About
          _buildSupportSection(),

          // Debug Section (only in debug mode)
          if (const bool.fromEnvironment('dart.vm.product') == false) ...[
            const Divider(),
            _buildDebugSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(dynamic user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: user?.photoUrl != null
            ? null // Would load network image
            : Text(
                user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
      ),
      title: Text(user?.displayName ?? 'Anonymous User'),
      subtitle: Text(user?.email ?? 'No email'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('App Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        // Language Settings
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(LocalizationService().currentLanguageCode.toUpperCase()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show language selector
            _showLanguageSelector();
          },
        ),

        // Theme Settings
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: const Text('System default'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeSelector(),
        ),

        // Notifications
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('Push Notifications'),
          value: userPreferences.enableNotifications,
          onChanged: (value) async {
            await ref.read(userPreferencesProvider.notifier).updateNotificationSettings(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
            );
          },
        ),

        // Biometric Authentication
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('Biometric Authentication'),
          value: userPreferences.enableBiometrics,
          onChanged: (value) async {
            await ref.read(userPreferencesProvider.notifier).updateBiometricSettings(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Biometric auth ${value ? 'enabled' : 'disabled'}')),
            );
          },
        ),

        // Auto Sync
        SwitchListTile(
          secondary: const Icon(Icons.sync),
          title: const Text('Auto Sync'),
          subtitle: const Text('Automatically sync data when online'),
          value: userPreferences.autoSync,
          onChanged: (value) async {
            await ref.read(userPreferencesProvider.notifier).updateAutoSyncSettings(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auto sync ${value ? 'enabled' : 'disabled'}')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountManagementSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup & Restore'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to backup screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup & Restore coming soon!')),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataExportScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                  'Are you sure you want to delete your account? '
                  'This action cannot be undone.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                await ref.read(authNotifierProvider.notifier).signOut();
                // TODO: Call delete account API
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deletion initiated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            }
          },
        ),

        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await ref.read(authNotifierProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Support & About', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help & FAQ'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.contact_support),
          title: const Text('Contact Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // For now, show contact dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Contact Support'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle: Text('support@finwise.app'),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat),
                      title: Text('Live Chat'),
                      subtitle: Text('Available 9 AM - 6 PM EST'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About FinWise'),
          subtitle: const Text('Version 1.0.0'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog();
          },
        ),
      ],
    );
  }

  Widget _buildDebugSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Debug (Development Only)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('OAuth Debug'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OAuthDebugScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.monitor),
          title: const Text('Monitoring Dashboard'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonitoringDashboard()),
            );
          },
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    final localization = LocalizationService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: localization.supportedLocaleInfo.map((locale) {
              return ListTile(
                leading: Text(locale['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(locale['nativeName']!),
                subtitle: Text(locale['name']!),
                trailing: locale['isCurrent'] == true ? const Icon(Icons.check) : null,
                onTap: () async {
                  await localization.changeLocale(locale['code']!);
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() {}); // Rebuild to show new language
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme set to System Default')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_high),
              title: const Text('Light Theme'),
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme set to Light')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_2),
              title: const Text('Dark Theme'),
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme set to Dark')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'FinWise',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          size: 32,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Smart Expense Management with AI-powered receipt scanning. '
          'Take control of your finances with intelligent budgeting and spending insights.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• AI Receipt Scanning\n'
          '• Smart Budgeting\n'
          '• Expense Analytics\n'
          '• Multi-platform Sync\n'
          '• Offline Support',
        ),
      ],
    );
  }
}
