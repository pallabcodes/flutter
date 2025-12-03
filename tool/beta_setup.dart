#!/usr/bin/env dart
import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';

/// Comprehensive beta testing setup for FinWise ecosystem
/// Handles TestFlight, Google Play Beta, and internal testing infrastructure

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('app', abbr: 'a',
        allowed: ['finwise', 'creditwise', 'rentwise', 'investwise'],
        help: 'App to set up for beta testing')
    ..addOption('platform', abbr: 'p',
        allowed: ['ios', 'android', 'both'],
        defaultsTo: 'both',
        help: 'Platform for beta testing')
    ..addOption('track', abbr: 't',
        allowed: ['internal', 'alpha', 'beta'],
        defaultsTo: 'beta',
        help: 'Beta testing track')
    ..addFlag('setup', abbr: 's', defaultsTo: true,
        help: 'Set up beta testing infrastructure')
    ..addFlag('deploy', abbr: 'd', defaultsTo: false,
        help: 'Deploy to beta channels')
    ..addFlag('testers', defaultsTo: false,
        help: 'Manage beta testers')
    ..addFlag('feedback', defaultsTo: false,
        help: 'Set up feedback collection')
    ..addFlag('help', abbr: 'h', defaultsTo: false,
        help: 'Show help');

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print('FinWise Beta Testing Setup');
    print('==========================');
    print('');
    print('Usage: dart tool/beta_setup.dart [options]');
    print('');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  dart tool/beta_setup.dart -a finwise -p ios -t beta     # Setup FinWise iOS beta');
    print('  dart tool/beta_setup.dart -a creditwise --deploy       # Deploy CreditWise to beta');
    print('  dart tool/beta_setup.dart -a rentwise --testers        # Manage RentWise beta testers');
    return;
  }

  final app = results['app'] as String?;
  final platform = results['platform'] as String;
  final track = results['track'] as String;
  final doSetup = results['setup'] as bool;
  final doDeploy = results['deploy'] as bool;
  final manageTesters = results['testers'] as bool;
  final setupFeedback = results['feedback'] as bool;

  if (app == null) {
    print('❌ Error: App is required');
    print('Use --help for usage information');
    exit(1);
  }

  print('🧪 FinWise Beta Testing Setup');
  print('============================');
  print('App: $app');
  print('Platform: $platform');
  print('Track: $track');
  print('');

  try {
    if (doSetup) {
      await setupBetaInfrastructure(app, platform, track);
    }

    if (manageTesters) {
      await manageBetaTesters(app, platform);
    }

    if (setupFeedback) {
      await setupFeedbackCollection(app);
    }

    if (doDeploy) {
      await deployToBeta(app, platform, track);
    }

    print('');
    print('✅ Beta testing setup completed successfully!');
  } catch (e) {
    print('');
    print('❌ Beta setup failed: $e');
    exit(1);
  }
}

Future<void> setupBetaInfrastructure(String app, String platform, String track) async {
  print('🔧 Setting up beta testing infrastructure...');

  // Create beta configuration
  await createBetaConfig(app, platform, track);

  // Setup platform-specific configurations
  if (platform == 'ios' || platform == 'both') {
    await setupIOSBeta(app, track);
  }

  if (platform == 'android' || platform == 'both') {
    await setupAndroidBeta(app, track);
  }

  // Setup analytics and crash reporting for beta
  await setupBetaAnalytics(app);

  // Create beta testing documentation
  await createBetaDocumentation(app, platform, track);

  print('✅ Beta infrastructure setup completed');
}

Future<void> setupIOSBeta(String app, String track) async {
  print('🍎 Setting up iOS beta testing...');

  final iosDir = Directory('ios');
  if (!await iosDir.exists()) {
    await iosDir.create(recursive: true);
  }

  // Create Fastlane configuration for beta
  final fastlaneDir = Directory('ios/fastlane');
  if (!await fastlaneDir.exists()) {
    await fastlaneDir.create(recursive: true);
  }

  // Create Fastfile for beta deployment
  final fastfile = File('ios/fastlane/Fastfile');
  await fastfile.writeAsString(generateIOSFastfile(app, track));

  // Create Appfile for app configuration
  final appfile = File('ios/fastlane/Appfile');
  await appfile.writeAsString(generateIOSAppfile(app));

  // Create beta-specific export options
  final exportOptions = File('ios/exportOptions-beta.plist');
  await exportOptions.writeAsString(generateIOSExportOptions(track));

  print('✅ iOS beta setup completed');
}

Future<void> setupAndroidBeta(String app, String track) async {
  print('🤖 Setting up Android beta testing...');

  final androidDir = Directory('android');
  if (!await androidDir.exists()) {
    await androidDir.create(recursive: true);
  }

  // Create Fastlane configuration for beta
  final fastlaneDir = Directory('android/fastlane');
  if (!await fastlaneDir.exists()) {
    await fastlaneDir.create(recursive: true);
  }

  // Create Fastfile for beta deployment
  final fastfile = File('android/fastlane/Fastfile');
  await fastfile.writeAsString(generateAndroidFastfile(app, track));

  // Create service account key placeholder
  final serviceAccountKey = File('android/fastlane/service-account-key.json');
  await serviceAccountKey.writeAsString('{\n  "type": "service_account",\n  "project_id": "your-project-id"\n}');

  print('✅ Android beta setup completed');
}

Future<void> setupBetaAnalytics(String app) async {
  print('📊 Setting up beta analytics and crash reporting...');

  // Create beta-specific Firebase configuration
  final betaFirebaseConfig = {
    'apiKey': 'beta_api_key_here',
    'authDomain': '$app-beta.firebaseapp.com',
    'projectId': '$app-beta',
    'storageBucket': '$app-beta.appspot.com',
    'messagingSenderId': 'beta_sender_id',
    'appId': 'beta_app_id',
    'measurementId': 'beta_measurement_id',
  };

  final configFile = File('apps/$app/lib/firebase_config_beta.dart');
  await configFile.writeAsString('''
// Beta Firebase Configuration
const betaFirebaseConfig = ${jsonEncode(betaFirebaseConfig)};
''');

  print('✅ Beta analytics setup completed');
}

Future<void> createBetaConfig(String app, String platform, String track) async {
  print('⚙️  Creating beta configuration...');

  final betaConfig = BetaConfig(
    app: app,
    platform: platform,
    track: track,
    version: '1.0.0-beta.1',
    minVersion: '1.0.0',
    maxUsers: track == 'internal' ? 100 : track == 'alpha' ? 1000 : 10000,
    feedbackEnabled: true,
    crashReportingEnabled: true,
    analyticsEnabled: true,
    createdAt: DateTime.now(),
  );

  final configFile = File('apps/$app/beta_config.json');
  await configFile.writeAsString(jsonEncode(betaConfig.toJson()));

  print('✅ Beta configuration created');
}

Future<void> manageBetaTesters(String app, String platform) async {
  print('👥 Managing beta testers...');

  // Create testers configuration
  final testersConfig = BetaTestersConfig(
    iosTesters: [
      BetaTester(
        email: 'tester1@finwise.com',
        firstName: 'John',
        lastName: 'Doe',
        groups: ['internal'],
      ),
      BetaTester(
        email: 'tester2@finwise.com',
        firstName: 'Jane',
        lastName: 'Smith',
        groups: ['beta'],
      ),
    ],
    androidTesters: [
      BetaTester(
        email: 'android-tester1@finwise.com',
        firstName: 'Android',
        lastName: 'Tester1',
        groups: ['alpha'],
      ),
    ],
    groups: [
      TesterGroup(
        name: 'internal',
        description: 'Internal team testing',
        maxUsers: 50,
      ),
      TesterGroup(
        name: 'alpha',
        description: 'Early access testing',
        maxUsers: 500,
      ),
      TesterGroup(
        name: 'beta',
        description: 'Public beta testing',
        maxUsers: 5000,
      ),
    ],
  );

  final testersFile = File('apps/$app/beta_testers.json');
  await testersFile.writeAsString(jsonEncode(testersConfig.toJson()));

  print('✅ Beta testers configuration created');
}

Future<void> setupFeedbackCollection(String app) async {
  print('💬 Setting up feedback collection...');

  // Create feedback configuration
  final feedbackConfig = BetaFeedbackConfig(
    enabled: true,
    collectionMethods: ['in_app', 'email', 'web_form'],
    categories: [
      'bugs',
      'usability',
      'performance',
      'features',
      'design',
    ],
    priorityLevels: ['low', 'medium', 'high', 'critical'],
    autoResponseEnabled: true,
    escalationThreshold: 'high',
  );

  final feedbackFile = File('apps/$app/beta_feedback_config.json');
  await feedbackFile.writeAsString(jsonEncode(feedbackConfig.toJson()));

  print('✅ Feedback collection setup completed');
}

Future<void> deployToBeta(String app, String platform, String track) async {
  print('🚀 Deploying to beta channels...');

  // Build the app for beta
  await runCommand('dart', ['tool/build.dart', '-a', app, '-p', platform, '-e', 'staging', '-r']);

  // Deploy to respective stores
  if (platform == 'ios' || platform == 'both') {
    await deployIOSBeta(app, track);
  }

  if (platform == 'android' || platform == 'both') {
    await deployAndroidBeta(app, track);
  }

  // Update beta status
  await updateBetaStatus(app, platform, track, 'deployed');

  print('✅ Beta deployment completed');
}

Future<void> deployIOSBeta(String app, String track) async {
  print('📱 Deploying iOS beta to TestFlight...');

  // Run Fastlane beta deployment
  await runCommand('bundle', ['exec', 'fastlane', 'beta'], workingDirectory: 'ios');

  print('✅ iOS beta deployed to TestFlight');
}

Future<void> deployAndroidBeta(String app, String track) async {
  print('🤖 Deploying Android beta to Google Play...');

  // Run Fastlane beta deployment
  await runCommand('bundle', ['exec', 'fastlane', 'beta'], workingDirectory: 'android');

  print('✅ Android beta deployed to Google Play');
}

Future<void> updateBetaStatus(String app, String platform, String track, String status) async {
  final statusUpdate = {
    'app': app,
    'platform': platform,
    'track': track,
    'status': status,
    'updatedAt': DateTime.now().toIso8601String(),
    'version': '1.0.0-beta.1',
  };

  final statusFile = File('apps/$app/beta_status.json');
  await statusFile.writeAsString(jsonEncode(statusUpdate));
}

Future<void> createBetaDocumentation(String app, String platform, String track) async {
  print('📚 Creating beta testing documentation...');

  final documentation = '''
# 🧪 $app Beta Testing Guide

## Overview
Welcome to the $app beta testing program! This guide will help you get started with testing and providing feedback.

## Getting Started

### Installation
${platform == 'ios' || platform == 'both' ? '''
#### iOS (TestFlight)
1. Open the TestFlight app on your iOS device
2. Tap "Redeem Code" or accept the invitation email
3. Install the $app beta version
''' : ''}

${platform == 'android' || platform == 'both' ? '''
#### Android (Google Play Beta)
1. Open the Google Play Store app
2. Search for "$app Beta" or use the beta testing link
3. Join the beta program and install the app
''' : ''}

## Testing Guidelines

### What to Test
- [ ] App launch and basic functionality
- [ ] Core features and user flows
- [ ] Performance and stability
- [ ] User interface and experience
- [ ] Data synchronization
- [ ] Offline functionality

### Reporting Issues
Please report any issues you encounter through:
1. **In-App Feedback**: Use the feedback button within the app
2. **Email**: Send detailed reports to beta@finwise.com
3. **Issue Tracker**: Use the beta testing portal

### Issue Report Template
```
Platform: iOS/Android
Device: [Device model]
OS Version: [iOS/Android version]
App Version: [Beta version]
Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Expected result vs Actual result]

Description: [Detailed description of the issue]
Severity: Low/Medium/High/Critical
```

## Beta Program Information

### Track: $track
${track == 'internal' ? '- Internal team and trusted partners only' : ''}
${track == 'alpha' ? '- Early access for select users' : ''}
${track == 'beta' ? '- Public beta testing phase' : ''}

### Duration
This beta testing phase will run for approximately 4-6 weeks, depending on feedback and stability.

### Support
- **Beta Support**: beta-support@finwise.com
- **Response Time**: Within 24 hours for critical issues
- **Updates**: Weekly beta releases with fixes and improvements

## Privacy & Data
- Beta testing data is kept separate from production
- All feedback and crash reports are anonymized
- Personal data is handled according to our privacy policy

## Thank You!
Your participation in beta testing is crucial for making $app the best financial app possible. Thank you for your time and valuable feedback!

---
*Generated on: ${DateTime.now()}*
''';

  final docFile = File('apps/$app/BETA_README.md');
  await docFile.writeAsString(documentation);

  print('✅ Beta documentation created');
}

// Fastlane configuration generators
String generateIOSFastfile(String app, String track) {
  return '''
# iOS Fastlane Configuration for $app Beta

platform :ios do
  desc "Build and deploy $app to TestFlight"
  lane :beta do
    # Setup certificates and provisioning
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)

    # Build the app
    gym(
      scheme: "Runner",
      export_method: "app-store",
      configuration: "Release",
      clean: true,
      xcargs: "-allowProvisioningUpdates"
    )

    # Upload to TestFlight
    pilot(
      skip_waiting_for_build_processing: true,
      distribute_external: true,
      groups: ["$track-testers"],
      changelog: "Beta release for $app - $track track",
      beta_app_description: "$app beta testing - $track track",
      beta_app_feedback_email: "beta-feedback@finwise.com"
    )
  end

  desc "Build and deploy $app to App Store"
  lane :release do
    # Build and submit to App Store
    deliver(
      submit_for_review: true,
      automatic_release: true,
      force: true,
      skip_metadata: false,
      skip_screenshots: false,
      submission_information: {
        add_id_info_uses_idfa: false,
        export_compliance_encryption_updated: false,
        export_compliance_uses_encryption: true
      }
    )
  end
end
''';
}

String generateIOSAppfile(String app) {
  return '''
# iOS App Configuration for $app

app_identifier("com.finwise.$app")
apple_id(ENV["APPLE_ID"])
team_id(ENV["ITC_TEAM_ID"])

itc_team_id(ENV["ITC_TEAM_ID"])
''';
}

String generateIOSExportOptions(String track) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>\${teamID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
''';
}

String generateAndroidFastfile(String app, String track) {
  final trackName = track == 'internal' ? 'internal' : 'beta';

  return '''
# Android Fastlane Configuration for $app Beta

platform :android do
  desc "Deploy $app to Google Play $track"
  lane :beta do
    # Build AAB
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/"
    )

    # Upload to Google Play
    upload_to_play_store(
      track: "$trackName",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Deploy $app to Google Play Production"
  lane :release do
    upload_to_play_store(
      track: "production",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      rollout: "0.1" # Gradual rollout
    )
  end
end
''';
}

// Data models
class BetaConfig {
  final String app;
  final String platform;
  final String track;
  final String version;
  final String minVersion;
  final int maxUsers;
  final bool feedbackEnabled;
  final bool crashReportingEnabled;
  final bool analyticsEnabled;
  final DateTime createdAt;

  const BetaConfig({
    required this.app,
    required this.platform,
    required this.track,
    required this.version,
    required this.minVersion,
    required this.maxUsers,
    required this.feedbackEnabled,
    required this.crashReportingEnabled,
    required this.analyticsEnabled,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'app': app,
      'platform': platform,
      'track': track,
      'version': version,
      'minVersion': minVersion,
      'maxUsers': maxUsers,
      'feedbackEnabled': feedbackEnabled,
      'crashReportingEnabled': crashReportingEnabled,
      'analyticsEnabled': analyticsEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class BetaTester {
  final String email;
  final String firstName;
  final String lastName;
  final List<String> groups;

  const BetaTester({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.groups,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'groups': groups,
    };
  }
}

class TesterGroup {
  final String name;
  final String description;
  final int maxUsers;

  const TesterGroup({
    required this.name,
    required this.description,
    required this.maxUsers,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'maxUsers': maxUsers,
    };
  }
}

class BetaTestersConfig {
  final List<BetaTester> iosTesters;
  final List<BetaTester> androidTesters;
  final List<TesterGroup> groups;

  const BetaTestersConfig({
    required this.iosTesters,
    required this.androidTesters,
    required this.groups,
  });

  Map<String, dynamic> toJson() {
    return {
      'iosTesters': iosTesters.map((t) => t.toJson()).toList(),
      'androidTesters': androidTesters.map((t) => t.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }
}

class BetaFeedbackConfig {
  final bool enabled;
  final List<String> collectionMethods;
  final List<String> categories;
  final List<String> priorityLevels;
  final bool autoResponseEnabled;
  final String escalationThreshold;

  const BetaFeedbackConfig({
    required this.enabled,
    required this.collectionMethods,
    required this.categories,
    required this.priorityLevels,
    required this.autoResponseEnabled,
    required this.escalationThreshold,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'collectionMethods': collectionMethods,
      'categories': categories,
      'priorityLevels': priorityLevels,
      'autoResponseEnabled': autoResponseEnabled,
      'escalationThreshold': escalationThreshold,
    };
  }
}

// Utility function
Future<String> runCommand(String command, List<String> args, {String? workingDirectory}) async {
  final result = await Process.run(command, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw Exception('Command failed: $command ${args.join(' ')}\n${result.stderr}');
  }
  return result.stdout as String;
}
''