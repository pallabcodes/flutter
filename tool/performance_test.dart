#!/usr/bin/env dart

/// Performance testing script for FinWise
/// Measures app performance metrics and identifies bottlenecks

import 'dart:io';
import 'dart:convert';

class PerformanceTester {
  static Future<void> main(List<String> args) async {
    print('⚡ FinWise Performance Tester');
    print('=' * 40);

    final testType = args.isNotEmpty ? args[0] : 'all';

    try {
      switch (testType) {
        case 'build':
          await _testBuildPerformance();
          break;
        case 'bundle':
          await _testBundleSize();
          break;
        case 'startup':
          await _testStartupTime();
          break;
        case 'memory':
          await _testMemoryUsage();
          break;
        case 'all':
          await _runAllTests();
          break;
        default:
          _printUsage();
          exit(1);
      }

      print('\n✅ Performance tests completed successfully!');
    } catch (e) {
      print('\n❌ Performance tests failed: $e');
      exit(1);
    }
  }

  static void _printUsage() {
    print('''
Usage: dart tool/performance_test.dart [test_type]

Test Types:
  build      Test build performance and times
  bundle     Analyze bundle sizes and optimization
  startup    Measure app startup time
  memory     Check memory usage patterns
  all        Run all performance tests

Examples:
  dart tool/performance_test.dart build
  dart tool/performance_test.dart all
    ''');
  }

  static Future<void> _runAllTests() async {
    print('🏃 Running all performance tests...');

    await _testBuildPerformance();
    await _testBundleSize();
    await _testStartupTime();
    await _testMemoryUsage();

    print('✅ All performance tests completed');
  }

  static Future<void> _testBuildPerformance() async {
    print('🔨 Testing build performance...');

    final results = <String, Duration>{};

    // Test Android APK build time
    final apkStart = DateTime.now();
    await _runCommand('flutter', ['build', 'apk', '--debug']);
    final apkTime = DateTime.now().difference(apkStart);
    results['Android APK Debug'] = apkTime;

    // Test iOS build time (if on macOS)
    if (Platform.isMacOS) {
      final iosStart = DateTime.now();
      await _runCommand('flutter', ['build', 'ios', '--debug', '--no-codesign']);
      final iosTime = DateTime.now().difference(iosStart);
      results['iOS Debug'] = iosTime;
    }

    // Test Web build time
    final webStart = DateTime.now();
    await _runCommand('flutter', ['build', 'web', '--release']);
    final webTime = DateTime.now().difference(webStart);
    results['Web Release'] = webTime;

    // Display results
    print('Build Performance Results:');
    results.forEach((platform, time) {
      final status = time.inSeconds > 300 ? '🐌 Slow' : time.inSeconds > 120 ? '⚠️  Moderate' : '✅ Fast';
      print('  $platform: ${time.inSeconds}s $status');
    });

    // Save results to file
    await _saveResults('build_performance.json', results);
  }

  static Future<void> _testBundleSize() async {
    print('📦 Analyzing bundle sizes...');

    final sizes = <String, int>{};

    // Android APK size
    final apkFile = File('build/app/outputs/apk/debug/app-debug.apk');
    if (await apkFile.exists()) {
      final apkSize = await apkFile.length();
      sizes['Android APK'] = apkSize;
    }

    // Android AAB size
    final aabFile = File('build/app/outputs/bundle/release/app-release.aab');
    if (await aabFile.exists()) {
      final aabSize = await aabFile.length();
      sizes['Android AAB'] = aabSize;
    }

    // iOS IPA size
    final ipaFile = File('build/ios/iphoneos/Runner.app');
    if (await ipaFile.exists()) {
      final ipaSize = await _getDirectorySize(ipaFile);
      sizes['iOS App'] = ipaSize;
    }

    // Web build size
    final webDir = Directory('build/web');
    if (await webDir.exists()) {
      final webSize = await _getDirectorySize(webDir);
      sizes['Web Build'] = webSize;
    }

    // Display results
    print('Bundle Size Analysis:');
    sizes.forEach((platform, bytes) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      final status = bytes > 100 * 1024 * 1024 ? '📦 Large' : bytes > 50 * 1024 * 1024 ? '⚠️  Moderate' : '✅ Optimal';
      print('  $platform: ${mb}MB $status');
    });

    // Analyze web build composition
    if (await webDir.exists()) {
      await _analyzeWebBuild(webDir);
    }

    await _saveResults('bundle_sizes.json', sizes);
  }

  static Future<void> _testStartupTime() async {
    print('🚀 Testing app startup time...');

    // This would require integration testing or device testing
    // For now, we'll analyze the build for potential startup issues

    final issues = <String>[];

    // Check for large assets that could slow startup
    final assetsDir = Directory('assets');
    if (await assetsDir.exists()) {
      final largeAssets = <String>[];
      await for (final entity in assetsDir.list(recursive: true)) {
        if (entity is File) {
          final size = await entity.length();
          if (size > 5 * 1024 * 1024) { // 5MB
            largeAssets.add('${entity.path}: ${(size / (1024 * 1024)).toStringAsFixed(2)}MB');
          }
        }
      }

      if (largeAssets.isNotEmpty) {
        issues.add('Large assets that may slow startup:');
        issues.addAll(largeAssets);
      }
    }

    // Check for synchronous operations in main.dart
    final mainFile = File('lib/main.dart');
    if (await mainFile.exists()) {
      final content = await mainFile.readAsString();
      if (content.contains('await') && content.contains('runApp')) {
        issues.add('Synchronous operations in main.dart may slow startup');
      }
    }

    if (issues.isEmpty) {
      print('✅ No startup performance issues detected');
    } else {
      print('⚠️  Potential startup performance issues:');
      issues.forEach((issue) => print('  $issue'));
    }
  }

  static Future<void> _testMemoryUsage() async {
    print('🧠 Analyzing memory usage patterns...');

    // Analyze code for potential memory leaks
    final files = await _getDartFiles();
    final issues = <String>[];

    for (final file in files) {
      final content = await File(file).readAsString();

      // Check for potential memory leaks
      if (content.contains('StreamController') && !content.contains('close()')) {
        issues.add('$file: StreamController may not be closed');
      }

      if (content.contains('Timer') && !content.contains('cancel()')) {
        issues.add('$file: Timer may not be cancelled');
      }

      if (content.contains('AnimationController') && !content.contains('dispose()')) {
        issues.add('$file: AnimationController may not be disposed');
      }
    }

    // Check for large lists or collections
    final largeCollections = <String>[];
    for (final file in files) {
      final content = await File(file).readAsString();
      final lines = content.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('List<') && line.length > 200) {
          largeCollections.add('$file:${i + 1}: Large list declaration');
        }
      }
    }

    if (issues.isEmpty && largeCollections.isEmpty) {
      print('✅ No memory usage issues detected');
    } else {
      print('⚠️  Potential memory usage issues:');
      [...issues, ...largeCollections].forEach((issue) => print('  $issue'));
    }
  }

  static Future<void> _analyzeWebBuild(Directory webDir) async {
    print('🔍 Analyzing web build composition...');

    final files = <String, int>{};
    await for (final entity in webDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst('${webDir.path}/', '');
        final size = await entity.length();
        files[relativePath] = size;
      }
    }

    // Sort by size
    final sortedFiles = files.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    print('Top 10 largest files in web build:');
    for (final entry in sortedFiles.take(10)) {
      final size = (entry.value / 1024).toStringAsFixed(2);
      print('  ${entry.key}: ${size}KB');
    }

    // Check for uncompressed assets
    final uncompressedAssets = sortedFiles.where((entry) =>
      entry.key.endsWith('.png') ||
      entry.key.endsWith('.jpg') ||
      entry.key.endsWith('.jpeg')
    ).toList();

    if (uncompressedAssets.isNotEmpty) {
      print('⚠️  Consider optimizing these images:');
      for (final asset in uncompressedAssets.take(5)) {
        print('  ${asset.key}: ${(asset.value / 1024).toStringAsFixed(2)}KB');
      }
    }
  }

  static Future<int> _getDirectorySize(FileSystemEntity entity) async {
    if (entity is File) {
      return await entity.length();
    } else if (entity is Directory) {
      int total = 0;
      await for (final child in entity.list(recursive: true)) {
        if (child is File) {
          total += await child.length();
        }
      }
      return total;
    }
    return 0;
  }

  static Future<List<String>> _getDartFiles() async {
    final files = <String>[];

    await _collectDartFiles(Directory('lib'), files);
    await _collectDartFiles(Directory('test'), files);

    return files;
  }

  static Future<void> _collectDartFiles(Directory dir, List<String> files) async {
    if (!await dir.exists()) return;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity.path);
      }
    }
  }

  static Future<void> _runCommand(String command, List<String> args) async {
    final result = await Process.run(command, args);
    if (result.exitCode != 0) {
      print('Command output: ${result.stdout}');
      print('Command error: ${result.stderr}');
      throw Exception('Command failed: $command ${args.join(' ')}');
    }
  }

  static Future<void> _saveResults(String filename, dynamic results) async {
    final resultsDir = Directory('performance_results');
    if (!await resultsDir.exists()) {
      await resultsDir.create();
    }

    final file = File('performance_results/$filename');
    await file.writeAsString(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'results': results,
    }));
  }
}
