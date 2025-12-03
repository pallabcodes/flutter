#!/usr/bin/env dart
import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// Comprehensive security scanning tool for the FinWise ecosystem
/// Performs static analysis, dependency scanning, and security checks

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('app', abbr: 'a',
        allowed: ['finwise', 'creditwise', 'rentwise', 'investwise', 'all'],
        help: 'App to scan (or "all" for all apps)')
    ..addFlag('dependencies', abbr: 'd', defaultsTo: true,
        help: 'Scan dependencies for vulnerabilities')
    ..addFlag('code', abbr: 'c', defaultsTo: true,
        help: 'Perform static code analysis')
    ..addFlag('secrets', abbr: 's', defaultsTo: true,
        help: 'Check for exposed secrets')
    ..addFlag('compliance', abbr: 'p', defaultsTo: true,
        help: 'Check compliance requirements')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Verbose output')
    ..addFlag('json', abbr: 'j', defaultsTo: false,
        help: 'Output results as JSON')
    ..addFlag('help', abbr: 'h', defaultsTo: false,
        help: 'Show help');

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print('FinWise Security Scanner');
    print('========================');
    print('');
    print('Usage: dart tool/security_scan.dart [options]');
    print('');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  dart tool/security_scan.dart -a finwise          # Scan FinWise');
    print('  dart tool/security_scan.dart -a all -v           # Scan all apps verbose');
    print('  dart tool/security_scan.dart -a creditwise -j    # Scan CreditWise, JSON output');
    return;
  }

  final app = results['app'] as String? ?? 'all';
  final scanDeps = results['dependencies'] as bool;
  final scanCode = results['code'] as bool;
  final scanSecrets = results['secrets'] as bool;
  final scanCompliance = results['compliance'] as bool;
  final verbose = results['verbose'] as bool;
  final jsonOutput = results['json'] as bool;

  final apps = app == 'all'
      ? ['finwise', 'creditwise', 'rentwise', 'investwise']
      : [app];

  print('🔒 FinWise Security Scanner');
  print('===========================');
  print('Apps: ${apps.join(', ')}');
  print('Scans: ${[
    if (scanDeps) 'dependencies',
    if (scanCode) 'code',
    if (scanSecrets) 'secrets',
    if (scanCompliance) 'compliance'
  ].join(', ')}');
  print('');

  final securityResults = <String, SecurityReport>{};

  for (final appName in apps) {
    print('🔍 Scanning $appName...');
    final report = await scanApp(
      appName,
      scanDeps: scanDeps,
      scanCode: scanCode,
      scanSecrets: scanSecrets,
      scanCompliance: scanCompliance,
      verbose: verbose,
    );
    securityResults[appName] = report;
    print('');
  }

  // Generate summary report
  final summary = generateSummaryReport(securityResults);

  if (jsonOutput) {
    print(jsonEncode(summary.toJson()));
  } else {
    printSecurityReport(summary, verbose);
  }

  // Exit with appropriate code
  final hasCriticalIssues = summary.criticalIssues > 0;
  final hasHighIssues = summary.highIssues > 0;

  if (hasCriticalIssues) {
    print('❌ CRITICAL: Security issues found that must be addressed immediately');
    exit(1);
  } else if (hasHighIssues) {
    print('⚠️  WARNING: High-severity security issues found');
    exit(1);
  } else {
    print('✅ PASSED: No critical security issues found');
    exit(0);
  }
}

Future<SecurityReport> scanApp(
  String appName, {
  required bool scanDeps,
  required bool scanCode,
  required bool scanSecrets,
  required bool scanCompliance,
  required bool verbose,
}) async {
  final issues = <SecurityIssue>[];

  final appPath = 'apps/$appName';

  // Scan dependencies
  if (scanDeps) {
    issues.addAll(await scanDependencies(appPath, verbose));
  }

  // Scan code
  if (scanCode) {
    issues.addAll(await scanCodeSecurity(appPath, verbose));
  }

  // Scan secrets
  if (scanSecrets) {
    issues.addAll(await scanSecrets(appPath, verbose));
  }

  // Scan compliance
  if (scanCompliance) {
    issues.addAll(await scanCompliance(appPath, appName, verbose));
  }

  return SecurityReport(
    appName: appName,
    scanTime: DateTime.now(),
    issues: issues,
  );
}

Future<List<SecurityIssue>> scanDependencies(String appPath, bool verbose) async {
  final issues = <SecurityIssue>[];

  try {
    // Check pubspec.yaml for dependencies
    final pubspecFile = File('$appPath/pubspec.yaml');
    if (!await pubspecFile.exists()) {
      issues.add(SecurityIssue(
        severity: Severity.medium,
        category: 'dependencies',
        title: 'Missing pubspec.yaml',
        description: 'No dependency file found',
        file: '$appPath/pubspec.yaml',
        line: 0,
        recommendation: 'Ensure pubspec.yaml exists and is properly configured',
      ));
      return issues;
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent) as Map;

    final dependencies = pubspec['dependencies'] as Map? ?? {};

    // Check for known vulnerable packages (simplified check)
    final vulnerablePackages = [
      'old_package_name', // Add real vulnerable packages
    ];

    for (final package in vulnerablePackages) {
      if (dependencies.containsKey(package)) {
        issues.add(SecurityIssue(
          severity: Severity.high,
          category: 'dependencies',
          title: 'Vulnerable package detected',
          description: 'Package $package has known security vulnerabilities',
          file: '$appPath/pubspec.yaml',
          line: 0,
          recommendation: 'Update to a secure version of $package',
        ));
      }
    }

    if (verbose) {
      print('  ✅ Scanned ${dependencies.length} dependencies');
    }

  } catch (e) {
    issues.add(SecurityIssue(
      severity: Severity.medium,
      category: 'dependencies',
      title: 'Dependency scan failed',
      description: 'Could not analyze dependencies: $e',
      file: '$appPath/pubspec.yaml',
      line: 0,
      recommendation: 'Fix dependency analysis and re-run scan',
    ));
  }

  return issues;
}

Future<List<SecurityIssue>> scanCodeSecurity(String appPath, bool verbose) async {
  final issues = <SecurityIssue>[];

  try {
    // Find all Dart files
    final dartFiles = await Directory(appPath)
        .list(recursive: true)
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.contains('.dart_tool') &&
            !entity.path.contains('build'))
        .toList();

    for (final file in dartFiles) {
      final content = await (file as File).readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Check for hardcoded secrets
        if (_containsHardcodedSecret(line)) {
          issues.add(SecurityIssue(
            severity: Severity.critical,
            category: 'code',
            title: 'Hardcoded secret detected',
            description: 'Potential hardcoded API key, password, or token found',
            file: file.path,
            line: i + 1,
            recommendation: 'Move secrets to environment variables or secure storage',
          ));
        }

        // Check for unsafe network calls
        if (_containsUnsafeHttpCall(line)) {
          issues.add(SecurityIssue(
            severity: Severity.medium,
            category: 'code',
            title: 'Potentially unsafe HTTP call',
            description: 'HTTP call without certificate pinning or validation',
            file: file.path,
            line: i + 1,
            recommendation: 'Implement certificate pinning or use HTTPS with validation',
          ));
        }

        // Check for weak encryption
        if (_containsWeakEncryption(line)) {
          issues.add(SecurityIssue(
            severity: Severity.high,
            category: 'code',
            title: 'Weak encryption detected',
            description: 'Using outdated or weak encryption methods',
            file: file.path,
            line: i + 1,
            recommendation: 'Use AES-256-GCM or stronger encryption methods',
          ));
        }

        // Check for debug code in production
        if (_containsDebugCode(line)) {
          issues.add(SecurityIssue(
            severity: Severity.low,
            category: 'code',
            title: 'Debug code in production',
            description: 'Debug print statements or development code found',
            file: file.path,
            line: i + 1,
            recommendation: 'Remove debug code before production deployment',
          ));
        }
      }
    }

    if (verbose) {
      print('  ✅ Scanned ${dartFiles.length} Dart files');
    }

  } catch (e) {
    issues.add(SecurityIssue(
      severity: Severity.medium,
      category: 'code',
      title: 'Code security scan failed',
      description: 'Could not analyze code: $e',
      file: appPath,
      line: 0,
      recommendation: 'Fix code analysis and re-run scan',
    ));
  }

  return issues;
}

Future<List<SecurityIssue>> scanSecrets(String appPath, bool verbose) async {
  final issues = <SecurityIssue>[];

  try {
    // Check for common secret files
    final secretFiles = [
      '.env',
      'secrets.json',
      'config/secrets.yaml',
      '.git/config', // Check for exposed git config
    ];

    for (final secretFile in secretFiles) {
      final file = File('$appPath/$secretFile');
      if (await file.exists()) {
        final content = await file.readAsString();

        // Check for actual secrets in files
        if (_containsActualSecrets(content)) {
          issues.add(SecurityIssue(
            severity: Severity.critical,
            category: 'secrets',
            title: 'Exposed secrets detected',
            description: 'Sensitive credentials found in $secretFile',
            file: '$appPath/$secretFile',
            line: 0,
            recommendation: 'Move secrets to secure environment variables or vault',
          ));
        }
      }
    }

    // Check git history for exposed secrets (simplified)
    final gitLog = await runCommand('git', ['log', '--oneline', '-10'], appPath);
    if (gitLog.contains('password') || gitLog.contains('secret') || gitLog.contains('key')) {
      issues.add(SecurityIssue(
        severity: Severity.medium,
        category: 'secrets',
        title: 'Potential secrets in git history',
        description: 'Git history may contain exposed secrets',
        file: '$appPath/.git',
        line: 0,
        recommendation: 'Audit git history and remove any exposed secrets',
      ));
    }

    if (verbose) {
      print('  ✅ Scanned for exposed secrets');
    }

  } catch (e) {
    issues.add(SecurityIssue(
      severity: Severity.medium,
      category: 'secrets',
      title: 'Secrets scan failed',
      description: 'Could not scan for secrets: $e',
      file: appPath,
      line: 0,
      recommendation: 'Fix secrets scanning and re-run scan',
    ));
  }

  return issues;
}

Future<List<SecurityIssue>> scanCompliance(String appPath, String appName, bool verbose) async {
  final issues = <SecurityIssue>[];

  try {
    // Check for required compliance files
    final requiredFiles = {
      'privacy_policy.md': 'Privacy policy required for GDPR/CCPA',
      'terms_of_service.md': 'Terms of service required',
      'data_processing_agreement.md': appName == 'creditwise' ? 'Required for credit data processing' : null,
    };

    requiredFiles.forEach((file, description) {
      if (description != null) {
        final filePath = '$appPath/$file';
        if (!File(filePath).existsSync()) {
          issues.add(SecurityIssue(
            severity: Severity.medium,
            category: 'compliance',
            title: 'Missing compliance document',
            description: description,
            file: filePath,
            line: 0,
            recommendation: 'Create and include $file',
          ));
        }
      }
    });

    // Check for data handling compliance
    final pubspecFile = File('$appPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();

      // Check for required permissions based on app type
      if (appName == 'creditwise' && !content.contains('camera')) {
        issues.add(SecurityIssue(
          severity: Severity.low,
          category: 'compliance',
          title: 'Missing camera permission',
          description: 'CreditWise may need camera permission for document scanning',
          file: '$appPath/pubspec.yaml',
          line: 0,
          recommendation: 'Add camera permission if document scanning is implemented',
        ));
      }
    }

    if (verbose) {
      print('  ✅ Checked compliance requirements');
    }

  } catch (e) {
    issues.add(SecurityIssue(
      severity: Severity.medium,
      category: 'compliance',
      title: 'Compliance scan failed',
      description: 'Could not check compliance: $e',
      file: appPath,
      line: 0,
      recommendation: 'Fix compliance checking and re-run scan',
    ));
  }

  return issues;
}

// Helper functions for pattern detection
bool _containsHardcodedSecret(String line) {
  final secretPatterns = [
    RegExp(r'api[_-]?key\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
    RegExp(r'password\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
    RegExp(r'secret\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
    RegExp(r'token\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
  ];

  return secretPatterns.any((pattern) => pattern.hasMatch(line));
}

bool _containsUnsafeHttpCall(String line) {
  return line.contains('http://') && !line.contains('localhost');
}

bool _containsWeakEncryption(String line) {
  return line.contains('DES') ||
         line.contains('RC4') ||
         (line.contains('AES') && !line.contains('256'));
}

bool _containsDebugCode(String line) {
  return line.contains('print(') ||
         line.contains('debugPrint(') ||
         line.contains('TODO:') ||
         line.contains('FIXME:');
}

bool _containsActualSecrets(String content) {
  return content.contains('sk_live_') ||
         content.contains('sk_test_') ||
         content.contains('AIza') ||
         content.contains('-----BEGIN') ||
         content.contains('private_key');
}

Future<String> runCommand(String command, List<String> args, [String? workingDirectory]) async {
  final result = await Process.run(command, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw Exception('Command failed: $result.stderr');
  }
  return result.stdout as String;
}

// Data models
enum Severity { critical, high, medium, low, info }

class SecurityIssue {
  final Severity severity;
  final String category;
  final String title;
  final String description;
  final String file;
  final int line;
  final String recommendation;

  const SecurityIssue({
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    required this.file,
    required this.line,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.name,
      'category': category,
      'title': title,
      'description': description,
      'file': file,
      'line': line,
      'recommendation': recommendation,
    };
  }
}

class SecurityReport {
  final String appName;
  final DateTime scanTime;
  final List<SecurityIssue> issues;

  const SecurityReport({
    required this.appName,
    required this.scanTime,
    required this.issues,
  });

  int get criticalIssues => issues.where((i) => i.severity == Severity.critical).length;
  int get highIssues => issues.where((i) => i.severity == Severity.high).length;
  int get mediumIssues => issues.where((i) => i.severity == Severity.medium).length;
  int get lowIssues => issues.where((i) => i.severity == Severity.low).length;
  int get totalIssues => issues.length;

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'scanTime': scanTime.toIso8601String(),
      'issues': issues.map((i) => i.toJson()).toList(),
      'summary': {
        'critical': criticalIssues,
        'high': highIssues,
        'medium': mediumIssues,
        'low': lowIssues,
        'total': totalIssues,
      },
    };
  }
}

class SecuritySummaryReport {
  final Map<String, SecurityReport> reports;
  final DateTime generatedAt;

  const SecuritySummaryReport({
    required this.reports,
    required this.generatedAt,
  });

  int get criticalIssues => reports.values.fold(0, (sum, r) => sum + r.criticalIssues);
  int get highIssues => reports.values.fold(0, (sum, r) => sum + r.highIssues);
  int get mediumIssues => reports.values.fold(0, (sum, r) => sum + r.mediumIssues);
  int get lowIssues => reports.values.fold(0, (sum, r) => sum + r.lowIssues);
  int get totalIssues => reports.values.fold(0, (sum, r) => sum + r.totalIssues);
  int get appsScanned => reports.length;

  bool get passed => criticalIssues == 0 && highIssues == 0;

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'summary': {
        'appsScanned': appsScanned,
        'criticalIssues': criticalIssues,
        'highIssues': highIssues,
        'mediumIssues': mediumIssues,
        'lowIssues': lowIssues,
        'totalIssues': totalIssues,
        'passed': passed,
      },
      'reports': reports.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

SecuritySummaryReport generateSummaryReport(Map<String, SecurityReport> reports) {
  return SecuritySummaryReport(
    reports: reports,
    generatedAt: DateTime.now(),
  );
}

void printSecurityReport(SecuritySummaryReport summary, bool verbose) {
  print('🔒 Security Scan Summary');
  print('=======================');
  print('Generated: ${summary.generatedAt}');
  print('Apps Scanned: ${summary.appsScanned}');
  print('');

  print('📊 Issue Summary:');
  print('  Critical: ${summary.criticalIssues}');
  print('  High: ${summary.highIssues}');
  print('  Medium: ${summary.mediumIssues}');
  print('  Low: ${summary.lowIssues}');
  print('  Total: ${summary.totalIssues}');
  print('');

  if (summary.passed) {
    print('✅ PASSED: No critical or high-severity issues found');
  } else {
    print('❌ ISSUES FOUND: Critical and/or high-severity issues require attention');
  }

  print('');

  if (verbose) {
    for (final entry in summary.reports.entries) {
      final appName = entry.key;
      final report = entry.value;

      print('📱 $appName:');
      print('  Critical: ${report.criticalIssues}, High: ${report.highIssues}, Medium: ${report.mediumIssues}, Low: ${report.lowIssues}');

      for (final issue in report.issues) {
        final severityIcon = {
          Severity.critical: '🔴',
          Severity.high: '🟠',
          Severity.medium: '🟡',
          Severity.low: '🔵',
          Severity.info: 'ℹ️',
        }[issue.severity];

        print('    $severityIcon ${issue.category}: ${issue.title}');
        print('      📄 ${issue.file}:${issue.line}');
        print('      💡 ${issue.recommendation}');
        print('');
      }
    }
  }
}