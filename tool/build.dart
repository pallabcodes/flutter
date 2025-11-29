#!/usr/bin/env dart

/// Automated build script for FinWise
/// Supports multiple platforms and environments

import 'dart:io';
import 'package:finwise/core/config/environments.dart';

class BuildScript {
  static const String projectName = 'finwise';

  static Future<void> main(List<String> args) async {
    print('🚀 FinWise Build Script');
    print('=' * 50);

    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final command = args[0];
    final platform = args.length > 1 ? args[1] : null;
    final environment = args.length > 2 ? args[2] : 'development';

    // Set environment
    _setEnvironment(environment);

    try {
      switch (command) {
        case 'clean':
          await _clean();
          break;

        case 'build':
          if (platform == null) {
            print('❌ Platform required for build command');
            _printUsage();
            exit(1);
          }
          await _build(platform, environment);
          break;

        case 'test':
          await _runTests();
          break;

        case 'analyze':
          await _runAnalysis();
          break;

        case 'all':
          await _buildAll(environment);
          break;

        default:
          print('❌ Unknown command: $command');
          _printUsage();
          exit(1);
      }

      print('\n✅ Build completed successfully!');
    } catch (e) {
      print('\n❌ Build failed: $e');
      exit(1);
    }
  }

  static void _setEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
      case 'dev':
        EnvironmentConfig.setEnvironment(Environment.development);
        break;
      case 'staging':
      case 'stage':
        EnvironmentConfig.setEnvironment(Environment.staging);
        break;
      case 'production':
      case 'prod':
        EnvironmentConfig.setEnvironment(Environment.production);
        break;
      default:
        print('⚠️  Unknown environment: $environment, using development');
        EnvironmentConfig.setEnvironment(Environment.development);
    }

    print('🌍 Environment: ${EnvironmentConfig.current.name}');
    if (EnvironmentConfig.enableDebugLogging) {
      EnvironmentConfig.printConfiguration();
    }
  }

  static Future<void> _clean() async {
    print('🧹 Cleaning project...');

    await _runCommand(['flutter', 'clean']);
    await _runCommand(['flutter', 'pub', 'get']);

    // Clean build artifacts
    final buildDir = Directory('build');
    if (await buildDir.exists()) {
      await buildDir.delete(recursive: true);
    }

    // Clean platform-specific files
    final androidBuild = Directory('android/app/build');
    if (await androidBuild.exists()) {
      await androidBuild.delete(recursive: true);
    }

    final iosBuild = Directory('ios/build');
    if (await iosBuild.exists()) {
      await iosBuild.delete(recursive: true);
    }
  }

  static Future<void> _build(String platform, String environment) async {
    print('🔨 Building for $platform ($environment)...');

    // Generate code first
    await _generateCode();

    switch (platform.toLowerCase()) {
      case 'android':
        await _buildAndroid(environment);
        break;

      case 'ios':
        await _buildIOS(environment);
        break;

      case 'web':
        await _buildWeb(environment);
        break;

      case 'windows':
        await _buildWindows(environment);
        break;

      case 'macos':
        await _buildMacOS(environment);
        break;

      case 'linux':
        await _buildLinux(environment);
        break;

      default:
        throw Exception('Unsupported platform: $platform');
    }
  }

  static Future<void> _buildAndroid(String environment) async {
    print('🤖 Building Android APK...');

    final buildType = environment == 'production' ? 'release' : 'debug';
    await _runCommand([
      'flutter',
      'build',
      'apk',
      '--$buildType',
      '--split-per-abi',
      if (environment != 'development') '--obfuscate',
      if (environment != 'development') '--split-debug-info=build/debug-info',
    ]);

    print('📦 APK built successfully!');
    print('📁 Location: build/app/outputs/flutter-apk/');
  }

  static Future<void> _buildIOS(String environment) async {
    print('🍎 Building iOS...');

    final buildType = environment == 'production' ? 'release' : 'debug';
    await _runCommand([
      'flutter',
      'build',
      'ios',
      '--$buildType',
      '--no-codesign', // Disable codesign for CI builds
    ]);

    print('📦 iOS build completed!');
    print('📁 Location: build/ios/iphoneos/');
  }

  static Future<void> _buildWeb(String environment) async {
    print('🌐 Building Web...');

    await _runCommand([
      'flutter',
      'build',
      'web',
      '--release',
      '--web-renderer',
      'canvaskit', // Better performance
    ]);

    print('📦 Web build completed!');
    print('📁 Location: build/web/');
  }

  static Future<void> _buildWindows(String environment) async {
    print('🪟 Building Windows...');

    await _runCommand([
      'flutter',
      'build',
      'windows',
      '--release',
    ]);

    print('📦 Windows build completed!');
    print('📁 Location: build/windows/runner/Release/');
  }

  static Future<void> _buildMacOS(String environment) async {
    print('💻 Building macOS...');

    await _runCommand([
      'flutter',
      'build',
      'macos',
      '--release',
    ]);

    print('📦 macOS build completed!');
    print('📁 Location: build/macos/Build/Products/Release/');
  }

  static Future<void> _buildLinux(String environment) async {
    print('🐧 Building Linux...');

    await _runCommand([
      'flutter',
      'build',
      'linux',
      '--release',
    ]);

    print('📦 Linux build completed!');
    print('📁 Location: build/linux/release/bundle/');
  }

  static Future<void> _buildAll(String environment) async {
    print('🔨 Building all platforms...');

    await _clean();

    final platforms = ['android', 'ios', 'web', 'windows', 'macos', 'linux'];

    for (final platform in platforms) {
      try {
        await _build(platform, environment);
      } catch (e) {
        print('⚠️  Failed to build $platform: $e');
        // Continue with other platforms
      }
    }
  }

  static Future<void> _runTests() async {
    print('🧪 Running tests...');

    await _runCommand([
      'flutter',
      'test',
      '--coverage',
      '--test-randomize-ordering-seed=random',
    ]);

    print('📊 Test results available in coverage/ directory');
  }

  static Future<void> _runAnalysis() async {
    print('🔍 Running static analysis...');

    await _runCommand(['flutter', 'analyze', '--fatal-infos']);
    await _runCommand(['flutter', 'format', '--dry-run', '--set-exit-if-changed', '.']);

    print('✅ Analysis completed!');
  }

  static Future<void> _generateCode() async {
    print('⚙️  Generating code...');

    await _runCommand(['flutter', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs']);
    await _runCommand(['flutter', 'pub', 'run', 'flutter_launcher_icons']);

    print('✅ Code generation completed!');
  }

  static Future<void> _runCommand(List<String> args) async {
    print('Executing: ${args.join(' ')}');

    final process = await Process.start(args[0], args.sublist(1));
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Command failed with exit code $exitCode: ${args.join(' ')}');
    }
  }

  static void _printUsage() {
    print('''
Usage: dart tool/build.dart <command> [platform] [environment]

Commands:
  clean                 Clean build artifacts
  build <platform>      Build for specific platform
  test                  Run test suite
  analyze               Run static analysis
  all                   Build all platforms

Platforms:
  android, ios, web, windows, macos, linux

Environments:
  development (default), staging, production

Examples:
  dart tool/build.dart clean
  dart tool/build.dart build android production
  dart tool/build.dart test
  dart tool/build.dart all staging
''');
  }
}
