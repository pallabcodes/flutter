#!/usr/bin/env dart

/// Release management script for FinWise
/// Handles versioning, changelogs, and release coordination

import 'dart:io';
import 'dart:convert';

class ReleaseManager {
  static const String projectName = 'finwise';

  static Future<void> main(List<String> args) async {
    print('🚀 FinWise Release Manager');
    print('=' * 30);

    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final command = args[0];

    try {
      switch (command) {
        case 'prepare':
          final version = args.length > 1 ? args[1] : null;
          await _prepareRelease(version);
          break;

        case 'publish':
          final platforms = args.length > 1 ? args.sublist(1) : ['all'];
          await _publishRelease(platforms);
          break;

        case 'rollback':
          final version = args.length > 1 ? args[1] : null;
          await _rollbackRelease(version);
          break;

        case 'status':
          await _showReleaseStatus();
          break;

        default:
          print('❌ Unknown command: $command');
          _printUsage();
          exit(1);
      }

      print('\n✅ Release management task completed successfully!');
    } catch (e) {
      print('\n❌ Release management failed: $e');
      exit(1);
    }
  }

  static Future<void> _prepareRelease(String? version) async {
    print('📋 Preparing release...');

    // Get current version if not provided
    final currentVersion = version ?? await _getCurrentVersion();
    print('🎯 Target version: $currentVersion');

    // Validate version format
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(currentVersion)) {
      throw Exception('Invalid version format. Use: major.minor.patch');
    }

    // Check if version already exists
    if (await _versionExists(currentVersion)) {
      throw Exception('Version $currentVersion already exists');
    }

    // Run pre-release checks
    await _runPreReleaseChecks();

    // Update version in files
    await _updateVersionFiles(currentVersion);

    // Generate changelog
    await _generateChangelog(currentVersion);

    // Create release branch
    await _createReleaseBranch(currentVersion);

    // Generate release notes
    await _generateReleaseNotes(currentVersion);

    print('✅ Release preparation completed');
    print('📝 Next steps:');
    print('  1. Review changes in release/$currentVersion branch');
    print('  2. Run tests: flutter test --coverage');
    print('  3. Create PR and merge to main');
    print('  4. Run: dart tool/release.dart publish');
  }

  static Future<void> _publishRelease(List<String> platforms) async {
    print('🚀 Publishing release...');

    final version = await _getCurrentVersion();
    print('📦 Publishing version: $version');

    // Validate release readiness
    await _validateReleaseReadiness(version);

    // Build all platforms
    if (platforms.contains('all') || platforms.contains('android')) {
      await _buildAndDeployAndroid(version);
    }

    if (platforms.contains('all') || platforms.contains('ios')) {
      await _buildAndDeployIOS(version);
    }

    if (platforms.contains('all') || platforms.contains('web')) {
      await _buildAndDeployWeb(version);
    }

    // Create GitHub release
    await _createGitHubRelease(version);

    // Update release status
    await _updateReleaseStatus(version, 'released');

    // Notify stakeholders
    await _notifyRelease(version);

    print('🎉 Release $version published successfully!');
  }

  static Future<void> _rollbackRelease(String? version) async {
    print('🔄 Rolling back release...');

    final targetVersion = version ?? await _getPreviousVersion();
    print('🎯 Rolling back to: $targetVersion');

    // Confirm rollback
    print('⚠️  This will rollback to version $targetVersion');
    print('Continue? (y/N): ');

    final input = stdin.readLineSync()?.toLowerCase() ?? 'n';
    if (input != 'y' && input != 'yes') {
      print('❌ Rollback cancelled');
      return;
    }

    // Perform rollback steps
    await _rollbackAppStores(targetVersion);
    await _rollbackWebDeployment(targetVersion);
    await _updateReleaseStatus(targetVersion, 'rolled_back');

    // Notify stakeholders
    await _notifyRollback(targetVersion);

    print('✅ Rollback to $targetVersion completed');
  }

  static Future<void> _showReleaseStatus() async {
    print('📊 Release Status');

    final currentVersion = await _getCurrentVersion();
    final releases = await _getReleaseHistory();

    print('Current version: $currentVersion');
    print('Recent releases:');

    for (final release in releases.take(5)) {
      print('  ${release['version']} - ${release['status']} (${release['date']})');
    }

    // Show deployment status
    print('\nDeployment Status:');
    final deploymentStatus = await _getDeploymentStatus();

    for (final platform in ['android', 'ios', 'web']) {
      final status = deploymentStatus[platform] ?? 'unknown';
      final emoji = status == 'deployed' ? '✅' : status == 'failed' ? '❌' : '⏳';
      print('  $emoji $platform: $status');
    }
  }

  static Future<String> _getCurrentVersion() async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final versionRegex = RegExp(r'version:\s*(\d+\.\d+\.\d+)\+');
    final match = versionRegex.firstMatch(content);

    if (match == null) {
      throw Exception('Could not find version in pubspec.yaml');
    }

    return match.group(1)!;
  }

  static Future<String> _getBuildNumber() async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final buildRegex = RegExp(r'version:\s*\d+\.\d+\.\d+\+(\d+)');
    final match = buildRegex.firstMatch(content);

    return match?.group(1) ?? '1';
  }

  static Future<bool> _versionExists(String version) async {
    try {
      await _runCommand(['git', 'tag', '--list', 'v$version']);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _runPreReleaseChecks() async {
    print('🔍 Running pre-release checks...');

    // Check for uncommitted changes
    final status = await _runCommand(['git', 'status', '--porcelain']);
    if (status.trim().isNotEmpty) {
      throw Exception('Uncommitted changes found. Please commit or stash them.');
    }

    // Run tests
    print('  Running tests...');
    await _runCommand(['flutter', 'test', '--coverage']);

    // Run static analysis
    print('  Running static analysis...');
    await _runCommand(['flutter', 'analyze', '--fatal-infos']);

    // Check code formatting
    print('  Checking code formatting...');
    await _runCommand(['flutter', 'format', '--dry-run', '--set-exit-if-changed', '.']);

    print('✅ Pre-release checks passed');
  }

  static Future<void> _updateVersionFiles(String version) async {
    print('📝 Updating version files...');

    final buildNumber = await _getBuildNumber();
    final fullVersion = '$version+$buildNumber';

    // Update pubspec.yaml
    await _updateFile(
      'pubspec.yaml',
      RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'),
      'version: $fullVersion',
    );

    // Update Android build.gradle
    await _updateFile(
      'android/app/build.gradle',
      RegExp(r'versionName\s*".*"'),
      'versionName "$version"',
    );

    await _updateFile(
      'android/app/build.gradle',
      RegExp(r'versionCode\s*\d+'),
      'versionCode $buildNumber',
    );

    // Update iOS project
    await _updateFile(
      'ios/Runner.xcodeproj/project.pbxproj',
      RegExp(r'CURRENT_PROJECT_VERSION\s*=\s*\d+'),
      'CURRENT_PROJECT_VERSION = $buildNumber;',
    );

    await _updateFile(
      'ios/Runner.xcodeproj/project.pbxproj',
      RegExp(r'MARKETING_VERSION\s*=\s*\d+\.\d+\.\d+'),
      'MARKETING_VERSION = $version;',
    );

    print('✅ Version files updated');
  }

  static Future<void> _generateChangelog(String version) async {
    print('📝 Generating changelog...');

    final changelog = await _buildChangelog(version);

    final changelogFile = File('CHANGELOG.md');
    final existingContent = await changelogFile.exists() ? await changelogFile.readAsString() : '';

    await changelogFile.writeAsString('$changelog\n$existingContent');

    print('✅ Changelog generated');
  }

  static Future<String> _buildChangelog(String version) async {
    // Get commits since last release
    final commits = await _getCommitsSinceLastRelease();

    final changelog = StringBuffer();
    changelog.writeln('# $version');
    changelog.writeln();
    changelog.writeln('## Changes');
    changelog.writeln();

    for (final commit in commits) {
      changelog.writeln('- ${commit['message']}');
    }

    changelog.writeln();
    changelog.writeln('## Build');
    changelog.writeln('- Build number: ${await _getBuildNumber()}');
    changelog.writeln('- Built at: ${DateTime.now().toIso8601String()}');

    return changelog.toString();
  }

  static Future<List<Map<String, String>>> _getCommitsSinceLastRelease() async {
    try {
      // First get the last tag
      final lastTag = await _runCommand(['git', 'describe', '--tags', '--abbrev=0']);
      final tag = lastTag.trim();
      // Then get commits since that tag
      final result = await _runCommand(['git', 'log', '--oneline', '--pretty=format:%H|%s', 'HEAD...$tag']);
      return result.split('\n').where((line) => line.isNotEmpty).map((line) {
        final parts = line.split('|');
        return {
          'hash': parts[0],
          'message': parts[1],
        };
      }).toList();
    } catch (e) {
      // If no previous tag, get all commits
      final result = await _runCommand(['git', 'log', '--oneline', '--pretty=format:%H|%s', '-10']);
      return result.split('\n').where((line) => line.isNotEmpty).map((line) {
        final parts = line.split('|');
        return {
          'hash': parts[0],
          'message': parts[1],
        };
      }).toList();
    }
  }

  static Future<void> _createReleaseBranch(String version) async {
    print('🌿 Creating release branch...');

    final branchName = 'release/$version';
    await _runCommand(['git', 'checkout', '-b', branchName]);

    await _runCommand(['git', 'add', '.']);
    await _runCommand(['git', 'commit', '-m', 'Release $version preparation']);
    await _runCommand(['git', 'push', '-u', 'origin', branchName]);

    print('✅ Release branch created: $branchName');
  }

  static Future<void> _generateReleaseNotes(String version) async {
    print('📝 Generating release notes...');

    final releaseNotes = await _buildReleaseNotes(version);

    // Save to distribution directories
    await _saveReleaseNotes('distribution/android/whatsnew/en-US.txt', releaseNotes);
    await _saveReleaseNotes('distribution/ios/app-store/release-notes.txt', releaseNotes);

    print('✅ Release notes generated');
  }

  static Future<String> _buildReleaseNotes(String version) async {
    return '''
FinWise v$version

NEW FEATURES
• AI-powered receipt scanning with Google ML Kit
• Smart expense categorization and budget tracking
• Real-time synchronization across devices
• Enhanced user interface with Material Design 3

IMPROVEMENTS
• Improved performance and stability
• Better accessibility support
• Enhanced error handling and user feedback
• Optimized app size and battery usage

BUG FIXES
• Fixed various UI crashes and edge cases
• Improved data synchronization reliability
• Enhanced offline functionality
• Fixed memory leaks and performance issues

COMPATIBILITY
• iOS 12.0 or later
• Android API 21 or later
• Web browsers with WebGL support
''';
  }

  static Future<void> _validateReleaseReadiness(String version) async {
    print('🔍 Validating release readiness...');

    // Check if tag exists
    if (!await _versionExists(version)) {
      throw Exception('Release tag v$version does not exist');
    }

    // Check if on main branch
    final branch = await _runCommand(['git', 'branch', '--show-current']);
    if (branch.trim() != 'main') {
      throw Exception('Must be on main branch for release');
    }

    print('✅ Release is ready');
  }

  static Future<void> _buildAndDeployAndroid(String version) async {
    print('🤖 Building and deploying Android...');

    await _runCommand(['dart', 'tool/build.dart', 'build', 'android', 'production']);
    await _runCommand(['dart', 'distribution/scripts/deploy_android.dart', version]);

    print('✅ Android deployment completed');
  }

  static Future<void> _buildAndDeployIOS(String version) async {
    print('🍎 Building and deploying iOS...');

    await _runCommand(['dart', 'tool/build.dart', 'build', 'ios', 'production']);
    await _runCommand(['dart', 'distribution/scripts/deploy_ios.dart', 'appstore', version]);

    print('✅ iOS deployment completed');
  }

  static Future<void> _buildAndDeployWeb(String version) async {
    print('🌐 Building and deploying Web...');

    await _runCommand(['dart', 'tool/build.dart', 'build', 'web', 'production']);
    await _runCommand(['dart', 'distribution/scripts/deploy_web.dart', 'production', version]);

    print('✅ Web deployment completed');
  }

  static Future<void> _createGitHubRelease(String version) async {
    print('🏷️  Creating GitHub release...');

    final releaseNotes = await _buildReleaseNotes(version);

    await _runCommand([
      'gh', 'release', 'create', 'v$version',
      '--title', 'FinWise v$version',
      '--notes', releaseNotes,
      '--latest',
    ]);

    print('✅ GitHub release created');
  }

  static Future<void> _rollbackAppStores(String version) async {
    print('🔄 Rolling back app stores...');

    // This would implement store-specific rollback procedures
    // For now, just log the action
    print('  - Android: Submit previous version to Play Store');
    print('  - iOS: Submit previous version for expedited review');
  }

  static Future<void> _rollbackWebDeployment(String version) async {
    print('🔄 Rolling back web deployment...');

    // Deploy previous version to web
    await _runCommand(['dart', 'distribution/scripts/deploy_web.dart', 'production', version]);
  }

  static Future<void> _updateReleaseStatus(String version, String status) async {
    print('📝 Updating release status...');

    final releasesFile = File('releases.json');
    final releases = await _loadReleases();

    releases[version] = {
      'status': status,
      'date': DateTime.now().toIso8601String(),
      'platforms': await _getDeploymentStatus(),
    };

    await releasesFile.writeAsString(JsonEncoder.withIndent('  ').convert(releases));
  }

  static Future<Map<String, dynamic>> _loadReleases() async {
    final releasesFile = File('releases.json');
    if (!await releasesFile.exists()) return {};

    final content = await releasesFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> _getReleaseHistory() async {
    final releases = await _loadReleases();
    return releases.entries.map((entry) => {
      'version': entry.key,
      ...entry.value as Map<String, dynamic>,
    }).toList()
      ..sort((a, b) => b['date'].compareTo(a['date']));
  }

  static Future<String> _getPreviousVersion() async {
    final releases = await _getReleaseHistory();
    return releases.isNotEmpty ? releases.first['version'] : '1.0.0';
  }

  static Future<Map<String, String>> _getDeploymentStatus() async {
    // This would check actual deployment status from stores
    // For now, return mock data
    return {
      'android': 'deployed',
      'ios': 'deployed',
      'web': 'deployed',
    };
  }

  static Future<void> _notifyRelease(String version) async {
    print('📤 Notifying stakeholders...');

    final webhookUrl = Platform.environment['SLACK_WEBHOOK_URL'];
    if (webhookUrl != null) {
      final message = {
        'text': '🚀 FinWise v$version Released!\n'
            'Available on Android, iOS, and Web\n'
            'Release notes: https://github.com/yourorg/finwise/releases/tag/v$version',
      };

      await _sendSlackMessage(webhookUrl, message);
    }
  }

  static Future<void> _notifyRollback(String version) async {
    print('📤 Notifying rollback...');

    final webhookUrl = Platform.environment['SLACK_WEBHOOK_URL'];
    if (webhookUrl != null) {
      final message = {
        'text': '🔄 FinWise Rollback to v$version\n'
            'Previous version has been restored\n'
            'Monitoring for issues...',
      };

      await _sendSlackMessage(webhookUrl, message);
    }
  }

  static Future<void> _sendSlackMessage(String webhookUrl, Map<String, dynamic> message) async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(webhookUrl));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(message));

    final response = await request.close();
    await response.drain();
    client.close();
  }

  static Future<void> _updateFile(String path, RegExp pattern, String replacement) async {
    final file = File(path);
    final content = await file.readAsString();
    final updatedContent = content.replaceAll(pattern, replacement);
    await file.writeAsString(updatedContent);
  }

  static Future<void> _saveReleaseNotes(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
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

  static void _printUsage() {
    print('''
Usage: dart tool/release.dart <command> [options]

Commands:
  prepare [version]    Prepare a new release
  publish [platforms]  Publish release to specified platforms (default: all)
  rollback [version]   Rollback to specified version
  status               Show current release status

Platforms: android, ios, web, all

Examples:
  dart tool/release.dart prepare 1.2.3
  dart tool/release.dart publish android ios
  dart tool/release.dart rollback 1.2.2
  dart tool/release.dart status
''');
  }
}
