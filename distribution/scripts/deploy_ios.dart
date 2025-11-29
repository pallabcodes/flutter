#!/usr/bin/env dart

/// iOS deployment script for FinWise
/// Handles TestFlight and App Store uploads

import 'dart:io';
import 'dart:convert';

class IOSDeployer {
  static const String bundleId = 'com.finwise.app';

  static Future<void> main(List<String> args) async {
    print('🍎 FinWise iOS Deployment');
    print('=' * 35);

    final destination = args.isNotEmpty ? args[0] : 'testflight';
    final version = args.length > 1 ? args[1] : await _getVersionFromPubspec();

    try {
      await _validateEnvironment();
      await _uploadToAppStore(destination, version);
      await _createRelease(version, destination);
      await _notifySlack(destination, version, 'success');

      final destinationName = destination == 'appstore' ? 'App Store' : 'TestFlight';
      print('\n✅ iOS deployment completed successfully!');
      print('📱 App submitted to $destinationName');

    } catch (e) {
      print('\n❌ iOS deployment failed: $e');
      await _notifySlack(destination, version, 'failure');
      exit(1);
    }
  }

  static Future<void> _validateEnvironment() async {
    print('🔍 Validating environment...');

    // Check for required files
    final ipaFile = File('build/ios/ipa/finwise.ipa');
    if (!await ipaFile.exists()) {
      throw Exception('IPA file not found. Run build first: dart tool/build.dart build ios production');
    }

    // Check for export options
    final exportOptionsFile = File('ios/exportOptions.plist');
    if (!await exportOptionsFile.exists()) {
      throw Exception('Export options plist not found at ios/exportOptions.plist');
    }

    // Check for App Store credentials
    final username = Platform.environment['APP_STORE_USERNAME'];
    final password = Platform.environment['APP_STORE_PASSWORD'];

    if (username == null || password == null) {
      throw Exception('App Store credentials not found in environment variables');
    }

    print('✅ Environment validation passed');
  }

  static Future<String> _getVersionFromPubspec() async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final versionRegex = RegExp(r'version:\s*(\d+\.\d+\.\d+)\+');
    final match = versionRegex.firstMatch(content);

    if (match == null) {
      throw Exception('Could not find version in pubspec.yaml');
    }

    return match.group(1)!;
  }

  static Future<void> _uploadToAppStore(String destination, String version) async {
    print('📤 Uploading to App Store Connect...');

    final destinationFlag = destination == 'appstore' ? '--type ios' : '--type ios --beta';

    final process = await Process.start('xcrun', [
      'altool',
      '--upload-app',
      destinationFlag,
      '--file', 'build/ios/ipa/finwise.ipa',
      '--username', Platform.environment['APP_STORE_USERNAME']!,
      '--password', Platform.environment['APP_STORE_PASSWORD']!,
    ]);

    // Capture output for progress tracking
    final output = StringBuffer();
    process.stdout.listen((data) => output.write(String.fromCharCodes(data)));
    process.stderr.listen((data) => output.write(String.fromCharCodes(data)));

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      print('Upload output: ${output.toString()}');
      throw Exception('Upload to App Store failed with exit code $exitCode');
    }

    print('✅ Upload completed successfully');
  }

  static Future<void> _createRelease(String version, String destination) async {
    print('🏷️  Creating release $version...');

    // Create git tag if not exists
    final tagExists = await _runCommand(['git', 'tag', '--list', 'v$version']);
    if (tagExists.trim().isEmpty) {
      await _runCommand(['git', 'tag', 'v$version']);
      await _runCommand(['git', 'push', 'origin', 'v$version']);
    }

    // Create GitHub release
    await _createGitHubRelease(version, destination);

    print('✅ Release $version created');
  }

  static Future<void> _createGitHubRelease(String version, String destination) async {
    final releaseNotes = await _getReleaseNotes(destination);

    final process = await Process.start('gh', [
      'release',
      'create',
      'v$version',
      '--title=FinWise v$version (${destination.toUpperCase()})',
      '--notes=$releaseNotes',
      '--target=main',
      'build/ios/ipa/finwise.ipa#finwise-ios-v$version.ipa',
    ]);

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('⚠️  GitHub release creation failed, but continuing...');
    }
  }

  static Future<String> _getReleaseNotes(String destination) async {
    final releaseNotesFile = File('distribution/ios/app-store/release-notes.txt');
    if (await releaseNotesFile.exists()) {
      return await releaseNotesFile.readAsString();
    }

    final destinationName = destination == 'appstore' ? 'App Store' : 'TestFlight';

    return '''
## FinWise v${await _getVersionFromPubspec()} - $destinationName Release

### 🚀 New Features
- AI-powered receipt scanning with Google ML Kit
- Smart expense categorization and budget tracking
- Real-time synchronization across devices
- Enhanced user interface with Material Design 3

### 📈 Improvements
- Improved performance and stability
- Better accessibility support
- Enhanced error handling and user feedback
- Optimized app size and battery usage

### 🐛 Bug Fixes
- Fixed various UI crashes and edge cases
- Improved data synchronization reliability
- Enhanced offline functionality
- Fixed memory leaks and performance issues

### 📋 Compatibility
- iOS 12.0 or later
- Supports all iPhone and iPad models
- Optimized for iOS 16+

### 🏷️ Build Information
- Version: ${await _getVersionFromPubspec()}
- Build: ${await _getBuildNumber()}
- Environment: ${destination.toUpperCase()}
- Bundle ID: $bundleId
''';
  }

  static Future<String> _getBuildNumber() async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final buildRegex = RegExp(r'version:\s*\d+\.\d+\.\d+\+(\d+)');
    final match = buildRegex.firstMatch(content);

    return match?.group(1) ?? '1';
  }

  static Future<String> _runCommand(List<String> args) async {
    final process = await Process.start(args[0], args.sublist(1));
    final output = StringBuffer();

    process.stdout.listen((data) => output.write(String.fromCharCodes(data)));
    process.stderr.listen((data) => output.write(String.fromCharCodes(data)));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Command failed: ${args.join(' ')}');
    }

    return output.toString();
  }

  static Future<void> _notifySlack(String destination, String version, String status) async {
    final webhookUrl = Platform.environment['SLACK_WEBHOOK_URL'];
    if (webhookUrl == null) return;

    final emoji = status == 'success' ? '✅' : '❌';
    final destinationName = destination == 'appstore' ? 'App Store' : 'TestFlight';

    final message = {
      'text': '$emoji FinWise iOS Deployment $status\n'
          'Version: v$version\n'
          'Destination: $destinationName\n'
          'Platform: iOS',
    };

    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(webhookUrl));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(message));

    final response = await request.close();
    await response.drain();

    client.close();
  }
}
