import 'package:finwise/core/config/oauth_config.dart';
import 'package:finwise/core/config/oauth_test_utils.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// OAuth Debug Screen for developers
/// Provides comprehensive OAuth testing and debugging tools
class OAuthDebugScreen extends StatefulWidget {
  const OAuthDebugScreen({super.key});

  @override
  State<OAuthDebugScreen> createState() => _OAuthDebugScreenState();
}

class _OAuthDebugScreenState extends State<OAuthDebugScreen> {
  OAuthTestResult? _testResult;
  bool _isTesting = false;
  String? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllTests,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Summary
            _buildConfigurationSummary(),

            const SizedBox(height: 24),

            // Test Controls
            _buildTestControls(),

            const SizedBox(height: 24),

            // Test Results
            if (_testResult != null) _buildTestResults(),

            const SizedBox(height: 24),

            // Debug Information
            _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSummary() {
    final summary = OAuthTestUtils.getConfigurationSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Google Configuration
            _buildProviderSummary('Google', summary['google']),

            const SizedBox(height: 12),

            // Facebook Configuration
            _buildProviderSummary('Facebook', summary['facebook']),

            const SizedBox(height: 16),

            // Overall Status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: summary['all_configured'] ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: summary['all_configured'] ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    summary['all_configured'] ? Icons.check_circle : Icons.error,
                    color: summary['all_configured'] ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    summary['all_configured']
                        ? 'All OAuth providers configured'
                        : 'Some OAuth providers not configured',
                    style: TextStyle(
                      color: summary['all_configured'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSummary(String providerName, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              providerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              config['configured'] ? Icons.check_circle : Icons.cancel,
              color: config['configured'] ? Colors.green : Colors.red,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...config.entries.where((e) => e.key != 'configured').map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check : Icons.close,
                  size: 14,
                  color: entry.value ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OAuth Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Run All Tests Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _runAllTests,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isTesting ? 'Running Tests...' : 'Run All Tests'),
              ),
            ),

            const SizedBox(height: 16),

            // Individual Provider Tests
            const Text(
              'Test Individual Providers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : () => _testProvider('google'),
                    child: const Text('Test Google'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : () => _testProvider('facebook'),
                    child: const Text('Test Facebook'),
                  ),
                ),
              ],
            ),

            if (_selectedProvider != null) ...[
              const SizedBox(height: 16),
              Text(
                'Testing: $_selectedProvider',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _testResult!.overallSuccess ? Icons.check_circle : Icons.error,
                  color: _testResult!.overallSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Results (${_testResult!.timestamp})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Individual Provider Results
            ..._testResult!.providerResults.entries.map(
              (entry) => _buildProviderTestResult(entry.key, entry.value),
            ),

            const SizedBox(height: 16),

            // Copy Results Button
            OutlinedButton.icon(
              onPressed: _copyTestResults,
              icon: const Icon(Icons.copy),
              label: const Text('Copy Results'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTestResult(String providerName, OAuthProviderTestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? Colors.green : Colors.red,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                providerName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.message,
            style: const TextStyle(fontSize: 12),
          ),
          if (result.metadata.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.metadata.entries.map(
              (entry) => Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
          if (result.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: ${result.error}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    final debugInfo = OAuthConfig.getDebugInfo();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Environment Variables
            const Text(
              'Environment Variables:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...debugInfo.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Configuration Files Status
            const Text(
              'Configuration Files:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildConfigFileStatus('Android Manifest', 'android/app/src/main/AndroidManifest.xml'),
            _buildConfigFileStatus('Android Strings', 'android/app/src/main/res/values/strings_oauth.xml'),
            _buildConfigFileStatus('iOS Info.plist', 'ios/Runner/Info.plist'),
            _buildConfigFileStatus('iOS OAuth Config', 'ios/Runner/Info-OAuth.plist'),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Setup Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Follow the OAuth setup guide in docs/oauth/OAUTH_SETUP.md\n'
                    '2. Configure environment variables for production builds\n'
                    '3. Test OAuth integration using the buttons above\n'
                    '4. Verify Firebase Authentication console settings',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigFileStatus(String name, String path) {
    // In a real implementation, you'd check if the file exists
    // For now, just show the expected path
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.description, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name: $path',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isTesting = true;
      _selectedProvider = null;
    });

    try {
      final result = await OAuthTestUtils.testAllConfigurations();
      OAuthTestUtils.logTestResults(result);

      setState(() {
        _testResult = result;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testProvider(String provider) async {
    setState(() {
      _isTesting = true;
      _selectedProvider = provider;
    });

    try {
      final result = await OAuthTestUtils.testEndToEndOAuth(provider);

      setState(() {
        _testResult = OAuthTestResult(
          overallSuccess: result.success,
          providerResults: {
            provider: OAuthProviderTestResult._(
              success: result.success,
              message: result.message,
              metadata: {'provider': provider},
              error: result.error?.name,
            ),
          },
          timestamp: DateTime.now(),
        );
      });
    } finally {
      setState(() {
        _isTesting = false;
        _selectedProvider = null;
      });
    }
  }

  Future<void> _copyTestResults() async {
    if (_testResult == null) return;

    // In a real implementation, you'd copy to clipboard
    // For now, just show a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test results logged to console')),
      );
    }
  }
}
