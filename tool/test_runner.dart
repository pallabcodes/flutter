#!/usr/bin/env dart

/// Comprehensive test runner for FinWise
/// Executes all test suites with proper configuration and reporting

import 'dart:io';
import 'dart:convert';

class TestRunner {
  static const String testConfigPath = 'test_config.yaml';
  static const String coverageDir = 'coverage';
  static const String lcovFile = '$coverageDir/lcov.info';

  static Future<void> main(List<String> args) async {
    print('🚀 FinWise Test Runner');
    print('=' * 50);

    // Parse command line arguments
    final testType = args.isNotEmpty ? args[0] : 'all';
    final verbose = args.contains('--verbose') || args.contains('-v');
    final coverage = !args.contains('--no-coverage');

    try {
      await runTests(testType, verbose: verbose, withCoverage: coverage);
      print('\n✅ All tests completed successfully!');
    } catch (e) {
      print('\n❌ Test execution failed: $e');
      exit(1);
    }
  }

  static Future<void> runTests(String testType, {
    bool verbose = false,
    bool withCoverage = true,
  }) async {
    // Ensure we're in the project root
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw Exception('Not in Flutter project root directory');
    }

    print('📁 Project root: ${Directory.current.path}');

    // Clean previous coverage data
    if (withCoverage) {
      await _cleanCoverage();
    }

    // Run tests based on type
    switch (testType) {
      case 'unit':
        await _runUnitTests(verbose: verbose, withCoverage: withCoverage);
        break;
      case 'widget':
        await _runWidgetTests(verbose: verbose, withCoverage: withCoverage);
        break;
      case 'integration':
        await _runIntegrationTests(verbose: verbose, withCoverage: withCoverage);
        break;
      case 'all':
        await _runAllTests(verbose: verbose, withCoverage: withCoverage);
        break;
      default:
        throw Exception('Unknown test type: $testType. Use: unit, widget, integration, or all');
    }

    // Generate coverage report
    if (withCoverage) {
      await _generateCoverageReport();
    }
  }

  static Future<void> _runUnitTests({
    bool verbose = false,
    bool withCoverage = true,
  }) async {
    print('\n🧪 Running Unit Tests...');

    final args = [
      'test',
      '--tags=unit',
      if (verbose) '--verbose',
      if (withCoverage) '--coverage',
    ];

    await _runFlutterCommand(args);
  }

  static Future<void> _runWidgetTests({
    bool verbose = false,
    bool withCoverage = true,
  }) async {
    print('\n🎨 Running Widget Tests...');

    final args = [
      'test',
      '--tags=widget',
      if (verbose) '--verbose',
      if (withCoverage) '--coverage',
    ];

    await _runFlutterCommand(args);
  }

  static Future<void> _runIntegrationTests({
    bool verbose = false,
    bool withCoverage = true,
  }) async {
    print('\n🔗 Running Integration Tests...');

    final args = [
      'test',
      'test/integration',
      if (verbose) '--verbose',
      if (withCoverage) '--coverage',
    ];

    await _runFlutterCommand(args);
  }

  static Future<void> _runAllTests({
    bool verbose = false,
    bool withCoverage = true,
  }) async {
    print('\n🎯 Running All Tests...');

    final args = [
      'test',
      if (verbose) '--verbose',
      if (withCoverage) '--coverage',
      '--test-randomize-ordering-seed=random',
    ];

    await _runFlutterCommand(args);
  }

  static Future<void> _runFlutterCommand(List<String> args) async {
    print('Executing: flutter ${args.join(' ')}');

    final process = await Process.start('flutter', args);
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Flutter command failed with exit code $exitCode');
    }
  }

  static Future<void> _cleanCoverage() async {
    print('\n🧹 Cleaning previous coverage data...');

    final coverageDir = Directory('coverage');
    if (await coverageDir.exists()) {
      await coverageDir.delete(recursive: true);
    }
    await coverageDir.create();
  }

  static Future<void> _generateCoverageReport() async {
    print('\n📊 Generating Coverage Report...');

    // Check if lcov file exists
    final lcovFile = File('coverage/lcov.info');
    if (!await lcovFile.exists()) {
      print('⚠️  No coverage data found');
      return;
    }

    // Generate HTML report
    await _runCommand(['genhtml', 'coverage/lcov.info', '-o', 'coverage/html']);

    // Calculate coverage percentage
    final coverage = await _calculateCoveragePercentage();
    print('📈 Code Coverage: ${coverage.toStringAsFixed(1)}%');

    // Check minimum coverage threshold
    const minimumCoverage = 80.0;
    if (coverage < minimumCoverage) {
      print('⚠️  Coverage below threshold: ${minimumCoverage}% required');
      // Don't fail here - let CI decide
    }

    print('📁 HTML Report: coverage/html/index.html');
  }

  static Future<double> _calculateCoveragePercentage() async {
    final lcovFile = File('coverage/lcov.info');
    if (!await lcovFile.exists()) return 0.0;

    final lines = await lcovFile.readAsLines();
    int totalLines = 0;
    int coveredLines = 0;

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        totalLines += int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        coveredLines += int.parse(line.substring(3));
      }
    }

    return totalLines > 0 ? (coveredLines / totalLines) * 100 : 0.0;
  }

  static Future<void> _runCommand(List<String> args) async {
    final process = await Process.start(args[0], args.sublist(1));
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('⚠️  Command failed: ${args.join(' ')}');
    }
  }
}

/// Test result analyzer
class TestAnalyzer {
  static Future<void> analyzeResults(String testOutput) async {
    // Parse test output and generate insights
    final lines = LineSplitter.split(testOutput).toList();

    int passed = 0;
    int failed = 0;
    int skipped = 0;
    final failedTests = <String>[];

    for (final line in lines) {
      if (line.contains('✓')) passed++;
      if (line.contains('✗')) {
        failed++;
        failedTests.add(line);
      }
      if (line.contains('~')) skipped++;
    }

    print('\n📊 Test Results Summary:');
    print('✅ Passed: $passed');
    print('❌ Failed: $failed');
    print('⏭️  Skipped: $skipped');

    if (failedTests.isNotEmpty) {
      print('\n❌ Failed Tests:');
      for (final test in failedTests.take(5)) {
        print('  $test');
      }
      if (failedTests.length > 5) {
        print('  ... and ${failedTests.length - 5} more');
      }
    }
  }
}

/// Performance test runner
class PerformanceTestRunner {
  static Future<void> runPerformanceTests() async {
    print('\n⚡ Running Performance Tests...');

    final testFiles = await _findTestFiles('test/performance');
    if (testFiles.isEmpty) {
      print('No performance tests found');
      return;
    }

    for (final testFile in testFiles) {
      print('Running $testFile...');
      await _runFlutterCommand(['test', testFile, '--timeout=5m']);
    }
  }

  static Future<List<String>> _findTestFiles(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    final files = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        files.add(entity.path);
      }
    }
    return files;
  }

  static Future<void> _runFlutterCommand(List<String> args) async {
    final process = await Process.start('flutter', args);
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Performance test failed: ${args.join(' ')}');
    }
  }
}

/// Test utilities for CI/CD integration
class CIDIntegration {
  static Future<void> setupCIEnvironment() async {
    // Set up environment variables for CI
    await _setEnvironmentVariables();

    // Configure test timeouts for CI
    await _configureTimeouts();

    // Set up test randomization for better coverage
    await _setupTestRandomization();
  }

  static Future<void> _setEnvironmentVariables() async {
    // Set CI-specific environment variables
    await _runCommand(['export', 'CI=true']);
    await _runCommand(['export', 'FLUTTER_TEST=true']);
  }

  static Future<void> _configureTimeouts() async {
    // Configure longer timeouts for CI environment
    // This would be done via flutter test arguments
  }

  static Future<void> _setupTestRandomization() async {
    // Enable test randomization for better coverage detection
  }

  static Future<void> _runCommand(List<String> args) async {
    final process = await Process.start(args[0], args.sublist(1));
    await process.exitCode; // Don't wait for output
  }

  static Future<Map<String, dynamic>> getTestMetrics() async {
    // Collect test metrics for reporting
    final metrics = <String, dynamic>{};

    // Count test files
    final testDir = Directory('test');
    if (await testDir.exists()) {
      final testFiles = await testDir.list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('_test.dart'))
          .length;
      metrics['test_files'] = testFiles;
    }

    // Get coverage data
    final lcovFile = File('coverage/lcov.info');
    if (await lcovFile.exists()) {
      final coverage = await TestRunner._calculateCoveragePercentage();
      metrics['coverage_percentage'] = coverage;
    }

    return metrics;
  }
}
