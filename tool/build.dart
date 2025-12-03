#!/usr/bin/env dart
import 'dart:io';
import 'package:args/args.dart';

/// Unified build system for the FinWise ecosystem
/// Supports building all apps across all platforms with proper configuration

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('app', abbr: 'a',
        allowed: ['finwise', 'creditwise', 'rentwise', 'investwise', 'all'],
        help: 'App to build (or "all" for all apps)')
    ..addOption('platform', abbr: 'p',
        allowed: ['ios', 'android', 'web', 'all'],
        help: 'Platform to build for (or "all" for all platforms)')
    ..addOption('environment', abbr: 'e',
        allowed: ['development', 'staging', 'production'],
        defaultsTo: 'development',
        help: 'Build environment')
    ..addFlag('release', abbr: 'r', defaultsTo: false,
        help: 'Create release build')
    ..addFlag('test', abbr: 't', defaultsTo: false,
        help: 'Run tests before building')
    ..addFlag('analyze', abbr: 'l', defaultsTo: false,
        help: 'Run static analysis')
    ..addFlag('clean', abbr: 'c', defaultsTo: false,
        help: 'Clean build artifacts first')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Verbose output')
    ..addFlag('help', abbr: 'h', defaultsTo: false,
        help: 'Show this help');

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print('FinWise Ecosystem Build System');
    print('==============================');
    print('');
    print('Usage: dart tool/build.dart [options]');
    print('');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  dart tool/build.dart -a finwise -p ios -r          # Build FinWise iOS release');
    print('  dart tool/build.dart -a all -p android -e staging  # Build all apps Android staging');
    print('  dart tool/build.dart -a creditwise -p all -t -r    # Test & build CreditWise all platforms release');
    return;
  }

  final app = results['app'] as String?;
  final platform = results['platform'] as String?;
  final environment = results['environment'] as String;
  final isRelease = results['release'] as bool;
  final runTests = results['test'] as bool;
  final runAnalysis = results['analyze'] as bool;
  final cleanFirst = results['clean'] as bool;
  final verbose = results['verbose'] as bool;

  if (app == null || platform == null) {
    print('❌ Error: App and platform are required');
    print('Use --help for usage information');
    exit(1);
  }

  final apps = app == 'all'
      ? ['finwise', 'creditwise', 'rentwise', 'investwise']
      : [app];

  final platforms = platform == 'all'
      ? ['ios', 'android', 'web']
      : [platform];

  print('🚀 FinWise Ecosystem Build System');
  print('==================================');
  print('Apps: ${apps.join(', ')}');
  print('Platforms: ${platforms.join(', ')}');
  print('Environment: $environment');
  print('Release build: $isRelease');
  print('Run tests: $runTests');
  print('Run analysis: $runAnalysis');
  print('Clean first: $cleanFirst');
  print('');

  final buildConfig = BuildConfig(
    apps: apps,
    platforms: platforms,
    environment: environment,
    isRelease: isRelease,
    runTests: runTests,
    runAnalysis: runAnalysis,
    cleanFirst: cleanFirst,
    verbose: verbose,
  );

  try {
    await runBuild(buildConfig);
    print('');
    print('🎉 Build completed successfully!');
  } catch (e) {
    print('');
    print('❌ Build failed: $e');
    exit(1);
  }
}

class BuildConfig {
  final List<String> apps;
  final List<String> platforms;
  final String environment;
  final bool isRelease;
  final bool runTests;
  final bool runAnalysis;
  final bool cleanFirst;
  final bool verbose;

  const BuildConfig({
    required this.apps,
    required this.platforms,
    required this.environment,
    required this.isRelease,
    required this.runTests,
    required this.runAnalysis,
    required this.cleanFirst,
    required this.verbose,
  });
}

Future<void> runBuild(BuildConfig config) async {
  final totalBuilds = config.apps.length * config.platforms.length;
  var completedBuilds = 0;

  for (final app in config.apps) {
    for (final platform in config.platforms) {
      print('📦 Building $app for $platform (${config.environment})...');

      try {
        await buildApp(app, platform, config);
        completedBuilds++;
        print('✅ $app ($platform) completed');
      } catch (e) {
        print('❌ $app ($platform) failed: $e');
        rethrow;
      }

      print('Progress: $completedBuilds/$totalBuilds builds completed');
      print('');
    }
  }
}

Future<void> buildApp(String app, String platform, BuildConfig config) async {
  final appPath = 'apps/$app';

  // Clean if requested
  if (config.cleanFirst) {
    await runCommand('flutter', ['clean'], workingDirectory: appPath, verbose: config.verbose);
  }

  // Run analysis if requested
  if (config.runAnalysis) {
    await runCommand('flutter', ['analyze'], workingDirectory: appPath, verbose: config.verbose);
  }

  // Run tests if requested
  if (config.runTests) {
    await runCommand('flutter', ['test'], workingDirectory: appPath, verbose: config.verbose);
  }

  // Get dependencies
  await runCommand('flutter', ['pub', 'get'], workingDirectory: appPath, verbose: config.verbose);

  // Build the app
  final buildArgs = <String>[];

  // Add environment configuration
  buildArgs.addAll(['--dart-define=ENVIRONMENT=${config.environment}']);

  // Add platform-specific arguments
  switch (platform) {
    case 'ios':
      buildArgs.addAll(['build', 'ios']);
      if (config.isRelease) {
        buildArgs.add('--release');
        // Add code signing for release builds
        buildArgs.addAll(['--obfuscate', '--split-debug-info=build/ios/symbols']);
      } else {
        buildArgs.add('--debug');
      }
      break;

    case 'android':
      if (config.isRelease) {
        buildArgs.addAll(['build', 'appbundle', '--release']);
        // Add code signing and optimization for release builds
        buildArgs.addAll(['--obfuscate', '--split-debug-info=build/android/symbols']);
      } else {
        buildArgs.addAll(['build', 'apk', '--debug']);
      }
      break;

    case 'web':
      buildArgs.addAll(['build', 'web', '--release']);
      break;
  }

  await runCommand('flutter', buildArgs, workingDirectory: appPath, verbose: config.verbose);

  // Run platform-specific post-build steps
  await postBuildSteps(app, platform, config);
}

Future<void> postBuildSteps(String app, String platform, BuildConfig config) async {
  if (!config.isRelease) return;

  switch (platform) {
    case 'ios':
      // Validate iOS build
      await validateIosBuild(app);
      break;

    case 'android':
      // Validate Android build
      await validateAndroidBuild(app);
      break;

    case 'web':
      // Validate web build
      await validateWebBuild(app);
      break;
  }
}

Future<void> validateIosBuild(String app) async {
  final appPath = 'apps/$app';
  final buildPath = '$appPath/build/ios/iphoneos';

  if (!await Directory(buildPath).exists()) {
    throw Exception('iOS build not found at $buildPath');
  }

  // Check for .app file
  final appFiles = await Directory(buildPath).list().where((entity) =>
    entity.path.endsWith('.app')).toList();

  if (appFiles.isEmpty) {
    throw Exception('No .app file found in iOS build');
  }

  print('✅ iOS build validated');
}

Future<void> validateAndroidBuild(String app) async {
  final appPath = 'apps/$app';

  if (!await File('$appPath/build/app/outputs/flutter-apk/app-debug.apk').exists() &&
      !await File('$appPath/build/app/outputs/bundle/release/app-release.aab').exists()) {
    throw Exception('Android build artifacts not found');
  }

  print('✅ Android build validated');
}

Future<void> validateWebBuild(String app) async {
  final appPath = 'apps/$app';
  final buildPath = '$appPath/build/web';

  if (!await Directory(buildPath).exists()) {
    throw Exception('Web build not found at $buildPath');
  }

  if (!await File('$buildPath/index.html').exists()) {
    throw Exception('Web build index.html not found');
  }

  print('✅ Web build validated');
}

Future<void> runCommand(String command, List<String> args, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  if (verbose) {
    print('Running: $command ${args.join(' ')} ${workingDirectory != null ? '(in $workingDirectory)' : ''}');
  }

  final result = await Process.run(
    command,
    args,
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    print('Command failed: $command ${args.join(' ')}');
    print('Exit code: ${result.exitCode}');
    print('Stdout: ${result.stdout}');
    print('Stderr: ${result.stderr}');
    throw Exception('Command failed with exit code ${result.exitCode}');
  }

  if (verbose && result.stdout.toString().isNotEmpty) {
    print('Output: ${result.stdout}');
  }
}