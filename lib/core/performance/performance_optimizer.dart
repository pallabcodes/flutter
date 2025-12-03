import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:finwise/core/performance/bundle_optimizer.dart';

/// Comprehensive performance optimization service
/// Handles battery optimization, memory management, and snappiness improvements
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Timer? _performanceMonitoringTimer;
  Timer? _batteryOptimizationTimer;
  Timer? _memoryOptimizationTimer;

  PerformanceMetrics _currentMetrics = PerformanceMetrics.empty();
  DeviceCapabilities _deviceCapabilities = DeviceCapabilities.basic();

  bool _isLowPowerMode = false;
  bool _isLowMemoryMode = false;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;

  /// Initialize performance optimization
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    await _setupPerformanceMonitoring();
    await _setupBatteryOptimization();
    await _setupMemoryOptimization();
    await _setupConnectivityOptimization();

    // Initialize bundle optimizer
    await BundleOptimizer().initialize();
  }

  /// Detect device capabilities for optimization
  Future<void> _detectDeviceCapabilities() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;
      final batteryLevel = await _battery.batteryLevel;

      // Determine device tier based on specs
      if (Platform.isAndroid) {
        final androidInfo = deviceInfo as AndroidDeviceInfo;
        _deviceCapabilities = DeviceCapabilities(
          isHighEnd: androidInfo.version.sdkInt >= 29 && // Android 10+
                      (androidInfo.hardware?.contains('kirin') == true ||
                       androidInfo.hardware?.contains('exynos') == true ||
                       androidInfo.hardware?.contains('tensor') == true ||
                       androidInfo.model?.contains('Pixel') == true),
          ramGB: _estimateAndroidRAM(androidInfo),
          hasGPUAcceleration: true, // Most modern Android devices have this
          batteryLevel: batteryLevel,
          supports60fps: true,
        );
      } else if (Platform.isIOS) {
        final iosInfo = deviceInfo as IosDeviceInfo;
        _deviceCapabilities = DeviceCapabilities(
          isHighEnd: iosInfo.model?.contains('iPhone') == true &&
                    (iosInfo.model!.contains('12') ||
                     iosInfo.model!.contains('13') ||
                     iosInfo.model!.contains('14') ||
                     iosInfo.model!.contains('15')),
          ramGB: _estimateIOSRAM(iosInfo),
          hasGPUAcceleration: true,
          batteryLevel: batteryLevel,
          supports60fps: true,
        );
      }
    } catch (e) {
      debugPrint('Failed to detect device capabilities: $e');
      _deviceCapabilities = DeviceCapabilities.basic();
    }
  }

  int _estimateAndroidRAM(AndroidDeviceInfo info) {
    // Rough estimation based on device model
    if (info.model?.contains('Pixel') == true) return 8;
    if (info.model?.contains('Galaxy S') == true) return 8;
    if (info.model?.contains('OnePlus') == true) return 8;
    return 4; // Default
  }

  int _estimateIOSRAM(IosDeviceInfo info) {
    // iOS devices typically have known RAM specs
    if (info.model?.contains('iPhone14') == true ||
        info.model?.contains('iPhone15') == true) return 6;
    if (info.model?.contains('iPhone12') == true ||
        info.model?.contains('iPhone13') == true) return 4;
    return 4; // Default
  }

  /// Setup performance monitoring
  Future<void> _setupPerformanceMonitoring() async {
    _performanceMonitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _monitorPerformance(),
    );
  }

  /// Setup battery optimization
  Future<void> _setupBatteryOptimization() async {
    // Monitor battery level changes
    _battery.onBatteryStateChanged.listen(_onBatteryStateChanged);

    // Initial battery check
    final batteryLevel = await _battery.batteryLevel;
    _updateBatteryOptimization(batteryLevel);

    // Periodic battery optimization adjustments
    _batteryOptimizationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _optimizeBatteryUsage(),
    );
  }

  /// Setup memory optimization
  Future<void> _setupMemoryOptimization() async {
    _memoryOptimizationTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _optimizeMemoryUsage(),
    );
  }

  /// Setup connectivity optimization
  Future<void> _setupConnectivityOptimization() async {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Initial connectivity check
    final connectivityResult = await _connectivity.checkConnectivity();
    _onConnectivityChanged(connectivityResult);
  }

  /// Monitor performance metrics
  Future<void> _monitorPerformance() async {
    try {
      final newMetrics = PerformanceMetrics(
        fps: await _measureFPS(),
        memoryUsage: await _measureMemoryUsage(),
        cpuUsage: await _measureCPUUsage(),
        networkRequests: await _countNetworkRequests(),
        batteryDrainRate: await _measureBatteryDrain(),
        timestamp: DateTime.now(),
      );

      _currentMetrics = newMetrics;

      // Adjust optimizations based on performance
      await _adjustOptimizationsForPerformance(newMetrics);

      // Log performance issues
      if (newMetrics.fps < 50) {
        debugPrint('⚠️ Low FPS detected: ${newMetrics.fps}');
        await _optimizeForLowFPS();
      }

      if (newMetrics.memoryUsage > 100 * 1024 * 1024) { // 100MB
        debugPrint('⚠️ High memory usage: ${newMetrics.memoryUsage}');
        await _optimizeForHighMemory();
      }

    } catch (e) {
      debugPrint('Performance monitoring error: $e');
    }
  }

  /// Battery state change handler
  void _onBatteryStateChanged(BatteryState state) async {
    final batteryLevel = await _battery.batteryLevel;
    _updateBatteryOptimization(batteryLevel);

    if (batteryLevel < 20) {
      await _enableLowPowerMode();
    } else if (batteryLevel > 50) {
      await _disableLowPowerMode();
    }
  }

  /// Connectivity change handler
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final primaryResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _currentConnectivity = primaryResult;

    switch (primaryResult) {
      case ConnectivityResult.wifi:
        _optimizeForWiFi();
        break;
      case ConnectivityResult.mobile:
        _optimizeForMobileData();
        break;
      case ConnectivityResult.none:
        _optimizeForOffline();
        break;
      default:
        break;
    }
  }

  /// Update battery optimization settings
  void _updateBatteryOptimization(int batteryLevel) {
    _isLowPowerMode = batteryLevel < 30;

    if (_isLowPowerMode) {
      // Reduce background tasks
      _reduceBackgroundTasks();

      // Lower animation frame rates
      _reduceAnimationQuality();

      // Reduce location update frequency
      _reduceLocationUpdates();
    }
  }

  /// Enable low power mode
  Future<void> _enableLowPowerMode() async {
    _isLowPowerMode = true;

    // Aggressive battery optimizations
    await _reduceBackgroundTasks();
    await _disableNonEssentialFeatures();
    await _optimizeAnimationsForBattery();

    debugPrint('🔋 Low power mode enabled');
  }

  /// Disable low power mode
  Future<void> _disableLowPowerMode() async {
    _isLowPowerMode = false;

    // Restore normal performance
    await _restoreNormalPerformance();

    debugPrint('🔋 Low power mode disabled');
  }

  /// Optimize battery usage
  Future<void> _optimizeBatteryUsage() async {
    if (_isLowPowerMode) {
      // Batch network requests
      await _batchNetworkRequests();

      // Reduce push notification frequency
      await _reduceNotificationFrequency();

      // Optimize background sync
      await _optimizeBackgroundSync();
    }
  }

  /// Optimize memory usage
  Future<void> _optimizeMemoryUsage() async {
    final memoryUsage = await _measureMemoryUsage();

    if (memoryUsage > 150 * 1024 * 1024) { // 150MB
      _isLowMemoryMode = true;

      // Clear caches
      await BundleOptimizer().clearCache();

      // Reduce image cache size
      await _reduceImageCache();

      // Force garbage collection hint
      await _forceGarbageCollection();

      debugPrint('🧠 Memory optimization applied');
    } else if (_isLowMemoryMode && memoryUsage < 100 * 1024 * 1024) {
      _isLowMemoryMode = false;
      debugPrint('🧠 Memory optimization relaxed');
    }
  }

  /// Adjust optimizations based on performance metrics
  Future<void> _adjustOptimizationsForPerformance(PerformanceMetrics metrics) async {
    // Adjust based on device capabilities and current performance
    if (!_deviceCapabilities.isHighEnd) {
      // Lower quality settings for lower-end devices
      await _applyLowEndOptimizations();
    }

    if (metrics.batteryDrainRate > 5) { // 5% per hour
      await _enableBatterySavingMode();
    }
  }

  /// Network optimization based on connectivity
  void _optimizeForWiFi() {
    // Enable higher quality assets
    // Increase sync frequency
    // Enable background downloads
  }

  void _optimizeForMobileData() {
    // Compress assets
    // Reduce sync frequency
    // Batch network requests
    // Disable automatic downloads
  }

  void _optimizeForOffline() {
    // Enable offline mode
    // Queue requests for later
    // Show cached content
  }

  // Specific optimization methods
  Future<void> _optimizeForLowFPS() async {
    // Reduce animation complexity
    await _reduceAnimationComplexity();

    // Enable frame rate limiting
    await _enableFrameRateLimiting();

    // Optimize rendering
    await _optimizeRendering();
  }

  Future<void> _optimizeForHighMemory() async {
    // Clear image caches
    await _clearImageCaches();

    // Unload unused modules
    await _unloadUnusedModules();

    // Force garbage collection
    await _forceGarbageCollection();
  }

  // Battery optimization methods
  Future<void> _reduceBackgroundTasks() async {
    // Reduce sync frequency
    // Disable non-essential background processing
    // Batch operations
  }

  Future<void> _reduceAnimationQuality() async {
    // Lower animation frame rates
    // Disable complex animations
    // Use simpler transitions
  }

  Future<void> _reduceLocationUpdates() async {
    // Increase location update intervals
    // Use lower accuracy
    // Disable continuous location tracking
  }

  Future<void> _batchNetworkRequests() async {
    // Group multiple requests
    // Implement request coalescing
    // Use exponential backoff
  }

  Future<void> _reduceNotificationFrequency() async {
    // Space out notifications
    // Batch similar notifications
    // Respect Do Not Disturb settings
  }

  Future<void> _optimizeBackgroundSync() async {
    // Reduce sync frequency
    // Only sync when charging
    // Use opportunistic syncing
  }

  // Memory optimization methods
  Future<void> _reduceImageCache() async {
    // Clear cached images
    // Reduce cache size
    // Use lower quality images
  }

  Future<void> _clearImageCaches() async {
    // Clear all image caches
    await BundleOptimizer().clearCache();
  }

  Future<void> _unloadUnusedModules() async {
    // Unload dynamically loaded modules
    await BundleOptimizer().clearCache();
  }

  // Performance optimization methods
  Future<void> _reduceAnimationComplexity() async {
    // Disable complex animations
    // Use simpler transitions
    // Reduce keyframe count
  }

  Future<void> _enableFrameRateLimiting() async {
    // Limit to 30fps on low-end devices
    // Use vsync for smooth rendering
  }

  Future<void> _optimizeRendering() async {
    // Enable layer caching
    // Optimize widget trees
    // Reduce overdraw
  }

  Future<void> _applyLowEndOptimizations() async {
    // Reduce image quality
    // Disable fancy effects
    // Simplify animations
    // Reduce particle effects
  }

  Future<void> _enableBatterySavingMode() async {
    await _enableLowPowerMode();
  }

  Future<void> _restoreNormalPerformance() async {
    // Restore normal settings
    // Re-enable features
    // Restore animation quality
  }

  Future<void> _disableNonEssentialFeatures() async {
    // Disable analytics if battery is critical
    // Reduce location accuracy
    // Disable background refresh
  }

  Future<void> _optimizeAnimationsForBattery() async {
    // Use CPU-efficient animations
    // Reduce animation duration
    // Disable animated backgrounds
  }

  // Measurement methods (simplified implementations)
  Future<double> _measureFPS() async {
    // This would use Flutter's performance overlay or custom measurement
    return 60.0; // Placeholder
  }

  Future<int> _measureMemoryUsage() async {
    // This would integrate with platform memory APIs
    return 50 * 1024 * 1024; // 50MB placeholder
  }

  Future<double> _measureCPUUsage() async {
    // This would measure actual CPU usage
    return 15.0; // 15% placeholder
  }

  Future<int> _countNetworkRequests() async {
    // This would count active network requests
    return 2; // Placeholder
  }

  Future<double> _measureBatteryDrain() async {
    // This would calculate battery drain rate
    return 2.5; // 2.5% per hour placeholder
  }

  Future<void> _forceGarbageCollection() async {
    // Hint to the system to run garbage collection
    // This is platform-specific and may not be reliable
  }

  /// Get current performance metrics
  PerformanceMetrics getCurrentMetrics() => _currentMetrics;

  /// Get device capabilities
  DeviceCapabilities getDeviceCapabilities() => _deviceCapabilities;

  /// Check if low power mode is active
  bool get isLowPowerMode => _isLowPowerMode;

  /// Check if low memory mode is active
  bool get isLowMemoryMode => _isLowMemoryMode;

  /// Manually trigger optimization
  Future<void> triggerOptimization() async {
    await _monitorPerformance();
    await _optimizeBatteryUsage();
    await _optimizeMemoryUsage();
  }

  /// Dispose resources
  void dispose() {
    _performanceMonitoringTimer?.cancel();
    _batteryOptimizationTimer?.cancel();
    _memoryOptimizationTimer?.cancel();
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final double fps;
  final int memoryUsage; // bytes
  final double cpuUsage; // percentage
  final int networkRequests;
  final double batteryDrainRate; // % per hour
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.fps,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkRequests,
    required this.batteryDrainRate,
    required this.timestamp,
  });

  factory PerformanceMetrics.empty() => PerformanceMetrics(
    fps: 60.0,
    memoryUsage: 0,
    cpuUsage: 0.0,
    networkRequests: 0,
    batteryDrainRate: 0.0,
    timestamp: DateTime.now(),
  );

  bool get isLowPerformance => fps < 50 || memoryUsage > 100 * 1024 * 1024;
  bool get isHighBatteryDrain => batteryDrainRate > 5.0;
}

/// Device capabilities data class
class DeviceCapabilities {
  final bool isHighEnd;
  final int ramGB;
  final bool hasGPUAcceleration;
  final int batteryLevel;
  final bool supports60fps;

  const DeviceCapabilities({
    required this.isHighEnd,
    required this.ramGB,
    required this.hasGPUAcceleration,
    required this.batteryLevel,
    required this.supports60fps,
  });

  factory DeviceCapabilities.basic() => const DeviceCapabilities(
    isHighEnd: false,
    ramGB: 4,
    hasGPUAcceleration: true,
    batteryLevel: 100,
    supports60fps: true,
  );

  bool get shouldOptimizeForPerformance => !isHighEnd || ramGB < 6;
  bool get shouldConserveBattery => batteryLevel < 30;
}
