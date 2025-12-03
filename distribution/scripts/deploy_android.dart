#!/usr/bin/env dart

/// Android deployment script for FinWise
/// Handles Google Play Store uploads and releases

import 'dart:io';
import 'dart:convert';

class AndroidDeployer {
  static const String packageName = 'com.finwise.app';

  static Future<void> main(List<String> args) async {
    print('🤖 FinWise Android Deployment');
    print('=' * 40);

    final track = args.isNotEmpty ? args[0] : 'beta';
    final version = args.length > 1 ? args[1] : await _getVersionFromPubspec();

    try {
      await _validateEnvironment();
      await _uploadToPlayStore(track, version);
      await _createRelease(track, version);
      await _notifySlack(track, version, 'success');

      print('\n✅ Android deployment completed successfully!');
      print('📱 App will be available on Google Play Store within a few hours');

    } catch (e) {
      print('\n❌ Android deployment failed: $e');
      await _notifySlack(track, version, 'failure');
      exit(1);
    }
  }

  static Future<void> _validateEnvironment() async {
    print('🔍 Validating environment...');

    // Check for required files
    final aabFile = File('build/app/outputs/bundle/release/app-release.aab');
    if (!await aabFile.exists()) {
      throw Exception('AAB file not found. Run build first: dart tool/build.dart build android production');
    }

    // Check for service account key
    final serviceAccountFile = File('android/play-store/service-account.json');
    if (!await serviceAccountFile.exists()) {
      throw Exception('Service account JSON not found at android/play-store/service-account.json');
    }

    // Check for release notes
    final whatsNewDir = Directory('distribution/android/whatsnew');
    if (!await whatsNewDir.exists()) {
      print('⚠️  Release notes directory not found, creating...');
      await whatsNewDir.create(recursive: true);
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

  static Future<void> _uploadToPlayStore(String track, String version) async {
    print('📤 Uploading to Google Play Store ($track track)...');

    final process = await Process.start('flutter', [
      'pub', 'run', 'flutter_app_publisher',
      'publish',
      '--package-name=$packageName',
      '--bundle=build/app/outputs/bundle/release/app-release.aab',
      '--track=$track',
      '--release-notes=distribution/android/whatsnew/en-US.txt',
      '--service-account-json=android/play-store/service-account.json',
    ]);

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Upload to Play Store failed with exit code $exitCode');
    }

    print('✅ Upload completed successfully');
  }

  static Future<void> _createRelease(String track, String version) async {
    print('🏷️  Creating release $version...');

    // Create git tag if not exists
    final tagExists = await _runCommand(['git', 'tag', '--list', 'v$version']);
    if (tagExists.trim().isEmpty) {
      await _runCommand(['git', 'tag', 'v$version']);
      await _runCommand(['git', 'push', 'origin', 'v$version']);
    }

    // Create GitHub release
    await _createGitHubRelease(version, track);

    print('✅ Release $version created');
  }

  static Future<void> _createGitHubRelease(String version, String track) async {
    final releaseNotes = await _getReleaseNotes();

    final process = await Process.start('gh', [
      'release',
      'create',
      'v$version',
      '--title=FinWise v$version',
      '--notes=$releaseNotes',
      '--target=main',
      'build/app/outputs/bundle/release/app-release.aab#finwise-android-v$version.aab',
    ]);

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('⚠️  GitHub release creation failed, but continuing...');
    }
  }

  static Future<String> _getReleaseNotes() async {
    final releaseNotesFile = File('distribution/android/whatsnew/en-US.txt');
    if (await releaseNotesFile.exists()) {
      return await releaseNotesFile.readAsString();
    }

    return '''
## What's New in FinWise v${await _getVersionFromPubspec()}

### Features
- AI-powered receipt scanning
- Smart expense categorization
- Real-time budget tracking
- Multi-device synchronization

### Improvements
- Enhanced user interface
- Better performance
- Improved accessibility

### Bug Fixes
- Fixed various UI issues
- Improved error handling
- Enhanced stability
''';
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

  static Future<void> _notifySlack(String track, String version, String status) async {
    final webhookUrl = Platform.environment['SLACK_WEBHOOK_URL'];
    if (webhookUrl == null) return;

    final emoji = status == 'success' ? '✅' : '❌';
    final message = {
      'text': '$emoji FinWise Android Deployment $status\n'
          'Version: v$version\n'
          'Track: $track\n'
          'Platform: Android',
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
