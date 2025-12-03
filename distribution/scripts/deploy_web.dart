#!/usr/bin/env dart

/// Web deployment script for FinWise
/// Handles PWA deployment to cloud hosting

import 'dart:io';
import 'dart:convert';

class WebDeployer {
  static const String projectName = 'finwise';

  static Future<void> main(List<String> args) async {
    print('🌐 FinWise Web Deployment');
    print('=' * 35);

    final environment = args.isNotEmpty ? args[0] : 'production';
    final version = args.length > 1 ? args[1] : await _getVersionFromPubspec();

    try {
      await _validateEnvironment();
      await _configureAWS();
      await _deployToS3(environment, version);
      await _invalidateCloudFront();
      await _updateServiceWorker();
      await _runHealthChecks();
      await _notifySlack(environment, version, 'success');

      print('\n✅ Web deployment completed successfully!');
      print('🌐 App available at: https://finwise.app');

    } catch (e) {
      print('\n❌ Web deployment failed: $e');
      await _notifySlack(environment, version, 'failure');
      exit(1);
    }
  }

  static Future<void> _validateEnvironment() async {
    print('🔍 Validating environment...');

    // Check for build files
    final webBuildDir = Directory('build/web');
    if (!await webBuildDir.exists()) {
      throw Exception('Web build not found. Run build first: dart tool/build.dart build web production');
    }

    // Check for required AWS environment variables
    final requiredVars = [
      'AWS_ACCESS_KEY_ID',
      'AWS_SECRET_ACCESS_KEY',
      'AWS_REGION',
      'WEB_BUCKET_NAME',
    ];

    for (final varName in requiredVars) {
      if (Platform.environment[varName] == null) {
        throw Exception('Missing required environment variable: $varName');
      }
    }

    // Check for deployment config
    final configFile = File('distribution/web/deploy-config.json');
    if (!await configFile.exists()) {
      print('⚠️  Deploy config not found, creating default...');
      await _createDefaultConfig();
    }

    print('✅ Environment validation passed');
  }

  static Future<void> _createDefaultConfig() async {
    final config = {
      'bucket': Platform.environment['WEB_BUCKET_NAME'] ?? 'finwise-web-prod',
      'region': Platform.environment['AWS_REGION'] ?? 'us-east-1',
      'cloudfront_distribution_id': Platform.environment['CLOUDFRONT_DISTRIBUTION_ID'],
      'cache_control': {
        'static': 'max-age=31536000,public,immutable',
        'html': 'max-age=300',
        'assets': 'max-age=31536000,public',
      },
    };

    final configFile = File('distribution/web/deploy-config.json');
    await configFile.parent.create(recursive: true);
    await configFile.writeAsString(JsonEncoder.withIndent('  ').convert(config));
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

  static Future<void> _configureAWS() async {
    print('🔧 Configuring AWS CLI...');

    await _runCommand([
      'aws', 'configure', 'set',
      'aws_access_key_id', Platform.environment['AWS_ACCESS_KEY_ID']!,
    ]);

    await _runCommand([
      'aws', 'configure', 'set',
      'aws_secret_access_key', Platform.environment['AWS_SECRET_ACCESS_KEY']!,
    ]);

    await _runCommand([
      'aws', 'configure', 'set',
      'region', Platform.environment['AWS_REGION']!,
    ]);

    print('✅ AWS CLI configured');
  }

  static Future<void> _deployToS3(String environment, String version) async {
    print('📤 Deploying to S3...');

    final bucketName = Platform.environment['WEB_BUCKET_NAME']!;
    final config = await _loadDeployConfig();

    // Upload static files with appropriate cache headers
    await _uploadWithCacheControl('build/web/static/', bucketName, config['cache_control']['static']);
    await _uploadWithCacheControl('build/web/assets/', bucketName, config['cache_control']['assets']);

    // Upload HTML files with shorter cache
    await _uploadWithCacheControl('build/web/*.html', bucketName, config['cache_control']['html']);

    // Upload everything else
    await _runCommand([
      'aws', 's3', 'sync', 'build/web/', 's3://$bucketName/',
      '--delete',
      '--cache-control', 'max-age=3600',
    ]);

    // Add version file for tracking
    final versionFile = File('build/web/version.json');
    await versionFile.writeAsString(jsonEncode({
      'version': version,
      'environment': environment,
      'deployed_at': DateTime.now().toIso8601String(),
      'build_number': await _getBuildNumber(),
    }));

    await _runCommand([
      'aws', 's3', 'cp', 'build/web/version.json', 's3://$bucketName/version.json',
      '--cache-control', 'max-age=300',
    ]);

    print('✅ S3 deployment completed');
  }

  static Future<void> _uploadWithCacheControl(String source, String bucketName, String cacheControl) async {
    await _runCommand([
      'aws', 's3', 'sync', source, 's3://$bucketName/',
      '--delete',
      '--cache-control', cacheControl,
    ]);
  }

  static Future<void> _invalidateCloudFront() async {
    final distributionId = Platform.environment['CLOUDFRONT_DISTRIBUTION_ID'];
    if (distributionId == null) {
      print('⚠️  CloudFront distribution ID not set, skipping invalidation');
      return;
    }

    print('🔄 Invalidating CloudFront cache...');

    await _runCommand([
      'aws', 'cloudfront', 'create-invalidation',
      '--distribution-id', distributionId,
      '--paths', '/*',
    ]);

    print('✅ CloudFront cache invalidated');
  }

  static Future<void> _updateServiceWorker() async {
    print('🔧 Updating service worker...');

    // Read the generated service worker
    final swFile = File('build/web/flutter_service_worker.js');
    if (!await swFile.exists()) {
      print('⚠️  Service worker not found, skipping update');
      return;
    }

    var swContent = await swFile.readAsString();

    // Add version information and cache busting
    final version = await _getVersionFromPubspec();
    final versionComment = '// FinWise v$version - ${DateTime.now().toIso8601String()}\n';

    swContent = versionComment + swContent;

    // Write back the updated service worker
    await swFile.writeAsString(swContent);

    // Upload the updated service worker
    final bucketName = Platform.environment['WEB_BUCKET_NAME']!;
    await _runCommand([
      'aws', 's3', 'cp', 'build/web/flutter_service_worker.js',
      's3://$bucketName/flutter_service_worker.js',
      '--cache-control', 'max-age=3600',
    ]);

    print('✅ Service worker updated');
  }

  static Future<void> _runHealthChecks() async {
    print('🏥 Running health checks...');

    final bucketName = Platform.environment['WEB_BUCKET_NAME']!;
    final region = Platform.environment['AWS_REGION']!;

    // Check if index.html is accessible
    final indexUrl = 'https://$bucketName.s3.$region.amazonaws.com/index.html';

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(indexUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        print('✅ Index.html is accessible');
      } else {
        print('⚠️  Index.html returned status ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      print('⚠️  Health check failed: $e');
    }

    // Check version file
    final versionUrl = 'https://$bucketName.s3.$region.amazonaws.com/version.json';
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(versionUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final versionData = await response.transform(utf8.decoder).join();
        final versionJson = jsonDecode(versionData);
        print('✅ Version file accessible: v${versionJson['version']}');
      }

      client.close();
    } catch (e) {
      print('⚠️  Version check failed: $e');
    }
  }

  static Future<Map<String, dynamic>> _loadDeployConfig() async {
    final configFile = File('distribution/web/deploy-config.json');
    final content = await configFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
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

  static Future<void> _notifySlack(String environment, String version, String status) async {
    final webhookUrl = Platform.environment['SLACK_WEBHOOK_URL'];
    if (webhookUrl == null) return;

    final emoji = status == 'success' ? '✅' : '❌';
    final message = {
      'text': '$emoji FinWise Web Deployment $status\n'
          'Version: v$version\n'
          'Environment: $environment\n'
          'Platform: Web/PWA',
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
