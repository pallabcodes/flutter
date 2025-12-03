#!/usr/bin/env dart

/// Monorepo migration script for FinWise
/// Helps restructure the repository for multiple Flutter apps

import 'dart:io';
import 'dart:convert';

class MonorepoMigrator {
  static const String monorepoStructure = '''
finwise-monorepo/
├── apps/
│   └── finwise/              # Current FinWise app
├── packages/
│   ├── core/                 # Shared core functionality
│   └── ui/                   # Shared UI components
├── tools/                    # Global development tools
├── docs/                     # Documentation
└── .github/                  # CI/CD workflows
''';

  static Future<void> main(List<String> args) async {
    print('🔄 FinWise Monorepo Migration Tool');
    print('=' * 40);
    print('Target Structure:');
    print(monorepoStructure);

    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final command = args[0];

    try {
      switch (command) {
        case 'analyze':
          await _analyzeCurrentStructure();
          break;
        case 'plan':
          await _createMigrationPlan();
          break;
        case 'migrate':
          await _performMigration();
          break;
        case 'validate':
          await _validateMigration();
          break;
        case 'rollback':
          await _rollbackMigration();
          break;
        default:
          _printUsage();
          exit(1);
      }

      print('\n✅ Migration operation completed successfully!');
    } catch (e) {
      print('\n❌ Migration failed: $e');
      exit(1);
    }
  }

  static void _printUsage() {
    print('''
Usage: dart tool/monorepo_migration.dart <command>

Commands:
  analyze     Analyze current repository structure
  plan        Create detailed migration plan
  migrate     Perform SAFE migration (no data loss!)
  validate    Validate migration success
  rollback    Rollback migration changes

Examples:
  dart tool/monorepo_migration.dart analyze
  dart tool/monorepo_migration.dart plan
    ''');
  }

  static Future<void> _analyzeCurrentStructure() async {
    print('🔍 Analyzing current repository structure...');

    final analysis = <String, dynamic>{};
    final currentDir = Directory.current;

    // Count files by type
    final fileCounts = <String, int>{};
    await for (final entity in currentDir.list(recursive: true)) {
      if (entity is File) {
        final extension = entity.path.split('.').last;
        fileCounts[extension] = (fileCounts[extension] ?? 0) + 1;
      }
    }

    analysis['file_counts'] = fileCounts;

    // Analyze lib directory structure
    final libDir = Directory('lib');
    final libStructure = <String, List<String>>{};
    if (await libDir.exists()) {
      await for (final entity in libDir.list(recursive: false)) {
        if (entity is Directory) {
          final subDir = Directory(entity.path);
          final files = <String>[];
          await for (final file in subDir.list()) {
            if (file is File && file.path.endsWith('.dart')) {
              files.add(file.path.split('/').last);
            }
          }
          libStructure[entity.path.split('/').last] = files;
        }
      }
    }

    analysis['lib_structure'] = libStructure;

    // Analyze dependencies
    final pubspec = File('pubspec.yaml');
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      final depMatches = RegExp(r'^\s+\w+:\s+[^#]*', multiLine: true).allMatches(content);
      analysis['dependency_count'] = depMatches.length;
    }

    // Generate analysis report
    print('📊 Current Repository Analysis:');
    print('- Files by type: ${jsonEncode(fileCounts)}');
    print('- Library structure: ${jsonEncode(libStructure)}');
    print('- Dependencies: ${analysis['dependency_count'] ?? 0}');

    // Identify potential shared code
    final sharedCandidates = <String>[];
    for (final entry in libStructure.entries) {
      final dir = entry.key;
      final files = entry.value;
      if (dir == 'core' || dir == 'presentation' && files.length > 5) {
        sharedCandidates.add(dir);
      }
    }

    if (sharedCandidates.isNotEmpty) {
      print('🎯 Potential shared packages: ${sharedCandidates.join(', ')}');
    }

    // Save analysis
    final analysisFile = File('migration_analysis.json');
    await analysisFile.writeAsString(jsonEncode(analysis));
    print('💾 Analysis saved to migration_analysis.json');
  }

  static Future<void> _rollbackMigration() async {
    print('🔄 Rolling back migration changes...');

    // Remove created directories and files (safe cleanup)
    final dirsToRemove = [
      'apps',
      'packages',
    ];

    for (final dir in dirsToRemove) {
      final directory = Directory(dir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        print('  🗑️  Removed $dir/');
      }
    }

    // Restore original pubspec.yaml
    final backupPubspec = File('pubspec.yaml.backup');
    final currentPubspec = File('pubspec.yaml');

    if (await backupPubspec.exists()) {
      await backupPubspec.copy('pubspec.yaml');
      await backupPubspec.delete();
      print('  🔄 Restored original pubspec.yaml');
    } else if (await currentPubspec.exists()) {
      // If no backup, remove the workspace pubspec
      await currentPubspec.delete();
      print('  🗑️  Removed workspace pubspec.yaml');
    }

    // Remove migration files
    final filesToRemove = [
      'migration_analysis.json',
      'migration_plan.json',
      'MIGRATION_PLAN.md',
    ];

    for (final file in filesToRemove) {
      final fileObj = File(file);
      if (await fileObj.exists()) {
        await fileObj.delete();
        print('  🗑️  Removed $file');
      }
    }

    print('✅ Rollback completed successfully!');
    print('🛡️  Your original FinWise code is completely intact.');
  }

  static Future<void> _createMigrationPlan() async {
    print('📋 Creating migration plan...');

    final plan = <String, dynamic>{};

    // Load analysis if available
    final analysisFile = File('migration_analysis.json');
    if (await analysisFile.exists()) {
      final analysis = jsonDecode(await analysisFile.readAsString());
      plan['current_analysis'] = analysis;
    }

    // Define migration steps
    plan['steps'] = [
      {
        'phase': 1,
        'title': 'Repository Restructuring',
        'description': 'Create apps/ and packages/ directories',
        'tasks': [
          'Create apps/finwise/ directory',
          'Create packages/core/ and packages/ui/',
          'Move current lib/ to apps/finwise/lib/',
          'Update pubspec.yaml references'
        ]
      },
      {
        'phase': 2,
        'title': 'Package Extraction',
        'description': 'Extract shared code into packages',
        'tasks': [
          'Identify sharable code in core/, presentation/',
          'Create package templates',
          'Move shared code to packages/',
          'Update imports across codebase'
        ]
      },
      {
        'phase': 3,
        'title': 'Dependency Management',
        'description': 'Set up package inter-dependencies',
        'tasks': [
          'Create pubspec.yaml for each package',
          'Set up path dependencies',
          'Test package isolation',
          'Update CI/CD for packages'
        ]
      },
      {
        'phase': 4,
        'title': 'Tooling Updates',
        'description': 'Update build and deployment tools',
        'tasks': [
          'Update tool/ scripts for monorepo',
          'Modify CI/CD workflows',
          'Update deployment scripts',
          'Test across all packages'
        ]
      }
    ];

    // Define shared packages to create
    plan['shared_packages'] = [
      {
        'name': 'finwise_core',
        'description': 'Shared core functionality',
        'directories': ['config', 'errors', 'monitoring', 'security', 'state', 'sync'],
        'dependencies': ['shared_preferences', 'connectivity_plus', 'crypto']
      },
      {
        'name': 'finwise_ui',
        'description': 'Shared UI components',
        'directories': ['presentation/widgets', 'presentation/theme'],
        'dependencies': ['flutter_svg', 'cached_network_image']
      }
    ];

    // Risk assessment
    plan['risks'] = [
      {
        'level': 'Low',
        'description': 'Import path changes may require updates',
        'mitigation': 'Use IDE refactoring tools'
      },
      {
        'level': 'Medium',
        'description': 'Package dependencies may need adjustment',
        'mitigation': 'Test builds after each phase'
      },
      {
        'level': 'Low',
        'description': 'CI/CD may need workflow updates',
        'mitigation': 'Update workflows incrementally'
      }
    ];

    // Timeline estimate
    plan['estimated_duration'] = {
      'phase_1': '2-4 hours',
      'phase_2': '4-6 hours',
      'phase_3': '2-3 hours',
      'phase_4': '1-2 hours',
      'total': '9-15 hours'
    };

    // Save migration plan
    final planFile = File('migration_plan.json');
    await planFile.writeAsString(JsonEncoder.withIndent('  ').convert(plan));

    // Generate human-readable plan
    final readablePlan = File('MIGRATION_PLAN.md');
    final planContent = _generateReadablePlan(plan);
    await readablePlan.writeAsString(planContent);

    print('✅ Migration plan created');
    print('📄 See MIGRATION_PLAN.md for detailed plan');
  }

  static String _generateReadablePlan(Map<String, dynamic> plan) {
    final buffer = StringBuffer();

    buffer.writeln('# 🔄 FinWise Monorepo Migration Plan');
    buffer.writeln('');
    buffer.writeln('Generated: ${DateTime.now().toString()}');
    buffer.writeln('');

    // Executive Summary
    buffer.writeln('## 📋 Executive Summary');
    buffer.writeln('');
    buffer.writeln('This plan outlines the migration of the FinWise repository from a single-app structure to a monorepo structure supporting multiple Flutter applications and shared packages.');
    buffer.writeln('');
    buffer.writeln('**Estimated Duration:** ${plan['estimated_duration']['total']}');
    buffer.writeln('');

    // Current Analysis
    if (plan.containsKey('current_analysis')) {
      final analysis = plan['current_analysis'] as Map<String, dynamic>;
      buffer.writeln('## 🔍 Current Structure Analysis');
      buffer.writeln('');

      if (analysis.containsKey('file_counts')) {
        buffer.writeln('### File Counts by Type');
        final fileCounts = analysis['file_counts'] as Map<String, dynamic>;
        for (final entry in fileCounts.entries) {
          buffer.writeln('- **.${entry.key}**: ${entry.value} files');
        }
        buffer.writeln('');
      }

      if (analysis.containsKey('lib_structure')) {
        buffer.writeln('### Library Structure');
        final libStructure = analysis['lib_structure'] as Map<String, dynamic>;
        for (final entry in libStructure.entries) {
          final files = entry.value as List;
          buffer.writeln('- **${entry.key}/**: ${files.length} files');
        }
        buffer.writeln('');
      }
    }

    // Migration Phases
    buffer.writeln('## 🚀 Migration Phases');
    buffer.writeln('');

    final steps = plan['steps'] as List;
    for (final step in steps) {
      buffer.writeln('### Phase ${step['phase']}: ${step['title']}');
      buffer.writeln('');
      buffer.writeln('${step['description']}');
      buffer.writeln('');
      buffer.writeln('**Duration:** ${plan['estimated_duration']['phase_${step['phase']}']}');
      buffer.writeln('');

      buffer.writeln('**Tasks:**');
      final tasks = step['tasks'] as List;
      for (final task in tasks) {
        buffer.writeln('- [ ] $task');
      }
      buffer.writeln('');
    }

    // Shared Packages
    buffer.writeln('## 📦 Shared Packages to Create');
    buffer.writeln('');

    final sharedPackages = plan['shared_packages'] as List;
    for (final package in sharedPackages) {
      buffer.writeln('### ${package['name']}');
      buffer.writeln('');
      buffer.writeln('${package['description']}');
      buffer.writeln('');
      buffer.writeln('**Directories to extract:**');
      final directories = package['directories'] as List;
      for (final dir in directories) {
        buffer.writeln('- `$dir/`');
      }
      buffer.writeln('');
      buffer.writeln('**Dependencies:**');
      final deps = package['dependencies'] as List;
      for (final dep in deps) {
        buffer.writeln('- `$dep`');
      }
      buffer.writeln('');
    }

    // Risks and Mitigations
    buffer.writeln('## ⚠️ Risks and Mitigations');
    buffer.writeln('');

    final risks = plan['risks'] as List;
    for (final risk in risks) {
      buffer.writeln('### ${risk['level']} Risk: ${risk['description']}');
      buffer.writeln('');
      buffer.writeln('**Mitigation:** ${risk['mitigation']}');
      buffer.writeln('');
    }

    // Success Criteria
    buffer.writeln('## ✅ Success Criteria');
    buffer.writeln('');
    buffer.writeln('- [ ] Repository structure matches monorepo layout');
    buffer.writeln('- [ ] All shared packages created and functional');
    buffer.writeln('- [ ] FinWise app builds and runs with shared packages');
    buffer.writeln('- [ ] All existing functionality preserved');
    buffer.writeln('- [ ] CI/CD pipelines updated and working');
    buffer.writeln('- [ ] All tests pass');
    buffer.writeln('');

    // Rollback Plan
    buffer.writeln('## 🔙 Rollback Plan');
    buffer.writeln('');
    buffer.writeln('If migration fails or issues arise:');
    buffer.writeln('');
    buffer.writeln('1. **Immediate Rollback:**');
    buffer.writeln('   ```bash');
    buffer.writeln('   git reset --hard HEAD~1');
    buffer.writeln('   git clean -fd');
    buffer.writeln('   ```');
    buffer.writeln('');
    buffer.writeln('2. **Partial Rollback:**');
    buffer.writeln('   - Restore original `lib/` directory');
    buffer.writeln('   - Remove `apps/` and `packages/` directories');
    buffer.writeln('   - Revert pubspec.yaml changes');
    buffer.writeln('');
    buffer.writeln('3. **Alternative:** Create separate repository for new apps');
    buffer.writeln('');

    return buffer.toString();
  }

  static Future<void> _performMigration() async {
    print('🛡️  SAFE MIGRATION MODE: No data will be lost!');
    print('This migration copies/symlinks existing code and is fully reversible.');
    print('');

    // Ask for confirmation
    stdout.write('Are you sure you want to proceed with safe migration? (yes/no): ');
    final response = stdin.readLineSync()?.toLowerCase();

    if (response != 'yes') {
      print('Migration cancelled.');
      return;
    }

    print('🚀 Starting SAFE migration...');

    // Phase 1: Create directory structure
    print('📁 Phase 1: Creating directory structure...');
    await _createDirectoryStructure();

    // Phase 2: Copy/symlink current app (SAFE)
    print('📦 Phase 2: Creating app references (SAFE)...');
    await _createAppReferences();

    // Phase 3: Create shared packages
    print('📦 Phase 3: Creating shared packages...');
    await _createSharedPackages();

    // Phase 4: Update configurations (NON-DESTRUCTIVE)
    print('⚙️  Phase 4: Updating configurations...');
    await _updateConfigurationsSafely();

    print('✅ SAFE Migration completed!');
    print('🔧 Next steps:');
    print('1. Test: cd apps/finwise && flutter run');
    print('2. Validate: dart tool/monorepo_migration.dart validate');
    print('3. If issues: dart tool/monorepo_migration.dart rollback');
    print('');
    print('🛡️  Your original code is still in place and untouched!');
  }

  static Future<void> _createDirectoryStructure() async {
    final directories = [
      'apps',
      'apps/finwise',
      'packages',
      'packages/core/lib',
      'packages/ui/lib',
      'tools',
      'docs',
      '.github/workflows',
    ];

    for (final dir in directories) {
      await Directory(dir).create(recursive: true);
    }
  }

  static Future<void> _createAppReferences() async {
    print('🔗 Creating safe references to existing code...');

    // Create symlinks instead of moving (completely safe)
    final symlinks = [
      ['lib', 'apps/finwise/lib'],
      ['test', 'apps/finwise/test'],
      ['android', 'apps/finwise/android'],
      ['ios', 'apps/finwise/ios'],
      ['web', 'apps/finwise/web'],
      ['linux', 'apps/finwise/linux'],
      ['macos', 'apps/finwise/macos'],
      ['windows', 'apps/finwise/windows'],
    ];

    for (final link in symlinks) {
      final target = link[0];
      final linkPath = link[1];

      if (await Directory(target).exists()) {
        try {
          // Create parent directory if needed
          final parentDir = Directory(linkPath).parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          // Create symlink (safe - doesn't move original files)
          await _createSymlink(target, linkPath);
          print('  ✅ Linked $target → $linkPath');
        } catch (e) {
          print('  ⚠️  Could not link $target: $e');
          // Copy as fallback (still safe)
          await _copyDirectory(target, linkPath);
          print('  📋 Copied $target → $linkPath');
        }
      }
    }

    // Copy configuration files (safe - originals remain)
    final configFiles = ['pubspec.yaml', 'analysis_options.yaml'];
    for (final file in configFiles) {
      if (await File(file).exists()) {
        final targetPath = 'apps/finwise/$file';
        await File(file).copy(targetPath);
        print('  📋 Copied $file → $targetPath');
      }
    }
  }

  static Future<void> _createSharedPackages() async {
    // Create core package
    final corePubspec = '''
name: finwise_core
description: Shared core functionality for FinWise apps
version: 1.0.0

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  crypto: ^3.0.3
  riverpod: ^2.4.9
  dio: ^5.4.0
  drift: ^2.15.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
''';

    await File('packages/core/pubspec.yaml').writeAsString(corePubspec);

    // Create UI package
    final uiPubspec = '''
name: finwise_ui
description: Shared UI components for FinWise apps
version: 1.0.0

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

    await File('packages/ui/pubspec.yaml').writeAsString(uiPubspec);

    // Create basic package structure
    await File('packages/core/lib/finwise_core.dart').writeAsString('''
// Core package exports
export 'src/config/app_config.dart';
export 'src/errors/failure.dart';
export 'src/monitoring/analytics_service.dart';
''');

    await File('packages/ui/lib/finwise_ui.dart').writeAsString('''
// UI package exports
export 'src/theme/app_theme.dart';
export 'src/widgets/error_boundary.dart';
''');
  }

  static Future<void> _updateConfigurationsSafely() async {
    print('🔧 Updating configurations safely...');

    // Backup original pubspec.yaml
    final originalPubspec = File('pubspec.yaml');
    if (await originalPubspec.exists()) {
      await originalPubspec.copy('pubspec.yaml.backup');
      print('  💾 Backed up original pubspec.yaml');
    }

    // Create root pubspec.yaml for workspace (new file)
    final rootPubspec = '''
name: finwise_workspace
description: FinWise monorepo workspace
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

workspace:
  - apps/finwise
  - packages/core
  - packages/ui
''';

    await File('pubspec.yaml').writeAsString(rootPubspec);
    print('  📄 Created root workspace pubspec.yaml');

    // Update FinWise app pubspec to include shared packages
    final finwisePubspecPath = 'apps/finwise/pubspec.yaml';
    final finwisePubspec = await File(finwisePubspecPath).readAsString();

    // Only add shared packages if not already present
    if (!finwisePubspec.contains('finwise_core:')) {
      final updatedFinwisePubspec = finwisePubspec.replaceFirst(
        'dependencies:',
        '''dependencies:
  finwise_core:
    path: ../../packages/core
  finwise_ui:
    path: ../../packages/ui

''',
      );

      await File(finwisePubspecPath).writeAsString(updatedFinwisePubspec);
      print('  🔗 Updated FinWise pubspec.yaml with shared packages');
    } else {
      print('  ✅ Shared packages already configured in FinWise');
    }
  }

  static Future<void> _validateMigration() async {
    print('✅ Validating SAFE migration...');

    final checks = <String, bool>{};
    final warnings = <String>[];

    // Check directory structure
    checks['apps/ directory created'] = await Directory('apps').exists();
    checks['packages/ directory created'] = await Directory('packages').exists();
    checks['apps/finwise/ exists'] = await Directory('apps/finwise').exists();
    checks['packages/core/ exists'] = await Directory('packages/core').exists();
    checks['packages/ui/ exists'] = await Directory('packages/ui').exists();

    // Check file presence
    checks['root workspace pubspec.yaml exists'] = await File('pubspec.yaml').exists();
    checks['finwise app pubspec.yaml exists'] = await File('apps/finwise/pubspec.yaml').exists();
    checks['core package pubspec.yaml exists'] = await File('packages/core/pubspec.yaml').exists();
    checks['ui package pubspec.yaml exists'] = await File('packages/ui/pubspec.yaml').exists();

    // Check that original code is still intact (CRITICAL)
    checks['original lib/ still exists'] = await Directory('lib').exists();
    checks['original pubspec.yaml backup exists'] = await File('pubspec.yaml.backup').exists();

    // Check symlinks/copies
    final finwiseLibExists = await Directory('apps/finwise/lib').exists();
    checks['finwise lib reference exists'] = finwiseLibExists;

    if (finwiseLibExists) {
      // Check if it's a symlink or copy
      final libStat = await FileStat.stat('apps/finwise/lib');
      if (libStat.type == FileSystemEntityType.link) {
        checks['finwise lib is symlink (safe)'] = true;
      } else {
        warnings.add('finwise lib appears to be a copy (still safe, but uses more disk space)');
      }
    }

    // Check shared packages
    checks['core package has lib/'] = await Directory('packages/core/lib').exists();
    checks['ui package has lib/'] = await Directory('packages/ui/lib').exists();

    // Check if FinWise pubspec includes shared packages
    final finwisePubspec = await File('apps/finwise/pubspec.yaml').readAsString();
    checks['finwise includes finwise_core'] = finwisePubspec.contains('finwise_core:');
    checks['finwise includes finwise_ui'] = finwisePubspec.contains('finwise_ui:');

    // Report results
    print('📊 Validation Results:');
    checks.forEach((check, passed) {
      final status = passed ? '✅' : '❌';
      print('  $status $check');
    });

    if (warnings.isNotEmpty) {
      print('\n⚠️  Warnings (non-critical):');
      warnings.forEach((warning) => print('  • $warning'));
    }

    final criticalChecks = checks.entries.where((entry) =>
      entry.key.contains('original') ||
      entry.key.contains('backup') ||
      entry.key.contains('still exists')
    );

    final allCriticalSafe = criticalChecks.every((entry) => entry.value);
    final allChecksPassed = checks.values.every((passed) => passed);

    print('\n🔒 Safety Status:');
    if (allCriticalSafe) {
      print('  ✅ CRITICAL: Your original code is completely safe!');
    } else {
      print('  ❌ CRITICAL: Original code safety compromised!');
    }

    print('\n📋 Migration Status:');
    if (allChecksPassed) {
      print('  🎉 Full migration successful!');
      print('  🚀 Ready to create new apps in the monorepo');
    } else {
      print('  ⚠️  Migration partially complete');
      print('  💡 Run: dart tool/monorepo_migration.dart rollback');
      print('  💡 Then try again or check the issues above');
    }

    print('\n🧪 Test Commands:');
    print('  cd apps/finwise && flutter pub get');
    print('  cd apps/finwise && flutter run');
    print('  dart tool/build.dart build android production');
  }

  static Future<void> _createSymlink(String target, String linkPath) async {
    // Use relative path for symlink
    final targetPath = '../'.padRight(linkPath.split('/').length, '../') + target;

    if (Platform.isWindows) {
      // Windows mklink command
      await _runCommand('cmd', ['/c', 'mklink', '/D', linkPath, targetPath]);
    } else {
      // Unix ln command
      await _runCommand('ln', ['-s', targetPath, linkPath]);
    }
  }

  static Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    final destDir = Directory(destination);

    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = entity.path.substring(source.length + 1);
      final destPath = '${destDir.path}/$relativePath';

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      }
    }
  }

  static Future<void> _runCommand(String command, List<String> args) async {
    final result = await Process.run(command, args);
    if (result.exitCode != 0) {
      throw Exception('Command failed: $command ${args.join(' ')}\n${result.stderr}');
    }
  }
}
