import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finwise/core/performance/performance_optimizer.dart';
import 'package:finwise/core/performance/bundle_optimizer.dart';
import 'package:finwise/core/animations/animation_optimizer.dart';
import 'package:finwise/core/performance/snappiness_optimizer.dart';

/// Unified optimization manager that coordinates all performance optimizations
/// Provides a single API for apps to access all optimization features
class OptimizationManager {
  static final OptimizationManager _instance = OptimizationManager._internal();
  factory OptimizationManager() => _instance;
  OptimizationManager._internal();

  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();
  final BundleOptimizer _bundleOptimizer = BundleOptimizer();
  final AnimationOptimizer _animationOptimizer = AnimationOptimizer();
  final SnappinessOptimizer _snappinessOptimizer = SnappinessOptimizer();

  bool _isInitialized = false;
  final StreamController<OptimizationEvent> _eventController =
      StreamController<OptimizationEvent>.broadcast();

  /// Initialize all optimization services
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🚀 Initializing Optimization Manager...');

    await Future.wait([
      _performanceOptimizer.initialize(),
      _bundleOptimizer.initialize(),
      _animationOptimizer.initialize(),
      _snappinessOptimizer.initialize(),
    ]);

    _setupOptimizationMonitoring();
    _isInitialized = true;

    debugPrint('✅ Optimization Manager initialized');

    _eventController.add(OptimizationEvent.initialized);
  }

  /// Setup monitoring for optimization adjustments
  void _setupOptimizationMonitoring() {
    // Monitor performance changes and adjust optimizations
    Timer.periodic(const Duration(seconds: 30), (_) {
      _monitorAndAdjustOptimizations();
    });

    // Listen to performance optimizer events
    // (Would be implemented if PerformanceOptimizer had events)
  }

  /// Monitor and adjust optimizations based on current conditions
  Future<void> _monitorAndAdjustOptimizations() async {
    final performanceMetrics = _performanceOptimizer.getCurrentMetrics();
    final deviceCapabilities = _performanceOptimizer.getDeviceCapabilities();

    // Adjust bundle optimization
    if (performanceMetrics.memoryUsage > 100 * 1024 * 1024) { // 100MB
      await _bundleOptimizer.optimizeForLowMemory();
      _eventController.add(OptimizationEvent.lowMemoryMode);
    }

    // Adjust animation optimization
    if (performanceMetrics.fps < 50) {
      _animationOptimizer.refreshAnimationSettings();
      _eventController.add(OptimizationEvent.performanceAdjusted);
    }

    // Adjust snappiness optimization
    if (_performanceOptimizer.isLowPowerMode) {
      await _snappinessOptimizer.optimizeSnappiness();
      _eventController.add(OptimizationEvent.batteryOptimization);
    }

    // Preload critical modules based on usage patterns
    await _bundleOptimizer.preloadCriticalModules();
  }

  /// Get optimized scroll physics
  ScrollPhysics getOptimizedScrollPhysics() {
    return _snappinessOptimizer.createOptimizedScrollPhysics();
  }

  /// Create optimized list view
  Widget createOptimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return _snappinessOptimizer.createOptimizedListView(
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? getOptimizedScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }

  /// Create optimized grid view
  Widget createOptimizedGridView({
    required SliverGridDelegate gridDelegate,
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return _snappinessOptimizer.createOptimizedGridView(
      gridDelegate: gridDelegate,
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? getOptimizedScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }

  /// Create optimized single child scroll view
  Widget createOptimizedSingleChildScrollView({
    required Widget child,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return _snappinessOptimizer.createOptimizedSingleChildScrollView(
      child: child,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? getOptimizedScrollPhysics(),
      padding: padding,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }

  /// Create optimized page view
  Widget createOptimizedPageView({
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.horizontal,
    bool reverse = false,
    bool pageSnapping = true,
    ScrollPhysics? physics,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool allowImplicitScrolling = false,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    bool padEnds = true,
  }) {
    return _snappinessOptimizer.createOptimizedPageView(
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      pageSnapping: pageSnapping,
      physics: physics ?? getOptimizedScrollPhysics(),
      dragStartBehavior: dragStartBehavior,
      allowImplicitScrolling: allowImplicitScrolling,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      scrollBehavior: scrollBehavior,
      padEnds: padEnds,
    );
  }

  /// Create optimized gesture detector
  Widget createOptimizedGestureDetector({
    required Widget child,
    GestureTapCallback? onTap,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    GestureTapCancelCallback? onTapCancel,
    GestureLongPressCallback? onLongPress,
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
    HitTestBehavior? behavior,
  }) {
    return _snappinessOptimizer.createOptimizedGestureDetector(
      child: child,
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onLongPress: onLongPress,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      behavior: behavior,
    );
  }

  /// Create smooth button
  Widget createSmoothButton({
    required Widget child,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ButtonStyle? style,
    bool enableFeedback = true,
  }) {
    return _snappinessOptimizer.createSmoothButton(
      child: child,
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      enableFeedback: enableFeedback,
    );
  }

  /// Create optimized text field
  Widget createOptimizedTextField({
    TextEditingController? controller,
    FocusNode? focusNode,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    bool? showCursor,
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines,
    int? minLines,
    int? maxLength,
    bool maxLengthEnforced = true,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    GestureTapCallback? onTap,
    TapRegionCallback? onTapOutside,
    MouseCursor? mouseCursor,
    InputCounterWidgetBuilder? buildCounter,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutofillClient? autofillClient,
    String? restorationId,
  }) {
    return _snappinessOptimizer.createOptimizedTextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      showCursor: showCursor,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      maxLengthEnforced: maxLengthEnforced,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      onTap: onTap,
      onTapOutside: onTapOutside,
      mouseCursor: mouseCursor,
      buildCounter: buildCounter,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics ?? getOptimizedScrollPhysics(),
      autofillHints: autofillHints,
      autofillClient: autofillClient,
      restorationId: restorationId,
    );
  }

  /// Create animated list item
  Widget createAnimatedListItem({
    required Widget child,
    required int index,
    Duration? delay,
    Offset? slideOffset,
    double? scale,
  }) {
    return _animationOptimizer.createAnimatedListItem(
      child: child,
      index: index,
      delay: delay,
      slideOffset: slideOffset,
      scale: scale,
    );
  }

  /// Create smooth loader
  Widget createSmoothLoader({
    Color? color,
    double? size,
    String? message,
  }) {
    return _animationOptimizer.createSmoothLoader(
      color: color,
      size: size,
      message: message,
    );
  }

  /// Create custom hero transition
  Widget createCustomHero({
    required Object tag,
    required Widget child,
    Curve? flightShuttleBuilder,
  }) {
    return _animationOptimizer.createCustomHero(
      tag: tag,
      child: child,
      flightShuttleBuilder: flightShuttleBuilder,
    );
  }

  /// Create staggered animation
  Widget createStaggeredAnimation({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Offset? slideOffset,
    double? fadeStart,
  }) {
    return _animationOptimizer.createStaggeredAnimation(
      children: children,
      staggerDelay: staggerDelay,
      slideOffset: slideOffset,
      fadeStart: fadeStart,
    );
  }

  /// Create state transition
  Widget createStateTransition({
    required Widget child,
    required Animation<double> animation,
    bool isForward = true,
  }) {
    return _animationOptimizer.createStateTransition(
      child: child,
      animation: animation,
      isForward: isForward,
    );
  }

  /// Create interactive animation
  Widget createInteractiveAnimation({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Duration? animationDuration,
  }) {
    return _animationOptimizer.createInteractiveAnimation(
      child: child,
      onTap: onTap,
      onLongPress: onLongPress,
      animationDuration: animationDuration,
    );
  }

  /// Create micro-interaction
  Widget createMicroInteraction({
    required Widget child,
    required MicroInteractionType type,
    VoidCallback? onComplete,
  }) {
    return _animationOptimizer.createMicroInteraction(
      child: child,
      type: type,
      onComplete: onComplete,
    );
  }

  /// Create smooth bottom sheet
  Widget createSmoothBottomSheet({
    required Widget child,
    required Animation<double> animation,
    BorderRadius? borderRadius,
  }) {
    return _animationOptimizer.createSmoothBottomSheet(
      child: child,
      animation: animation,
      borderRadius: borderRadius,
    );
  }

  /// Create shimmer effect
  Widget createShimmerEffect({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? period,
  }) {
    return _animationOptimizer.createShimmerEffect(
      child: child,
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: period,
    );
  }

  /// Load feature module dynamically
  Future<void> loadFeatureModule(String featureName) async {
    await _bundleOptimizer.loadFeatureModule(featureName);
  }

  /// Preload critical modules
  Future<void> preloadCriticalModules() async {
    await _bundleOptimizer.preloadCriticalModules();
  }

  /// Get optimization event stream
  Stream<OptimizationEvent> get optimizationEvents => _eventController.stream;

  /// Get current optimization status
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'performance': _performanceOptimizer.getCurrentMetrics().toJson(),
      'bundle': _bundleOptimizer.getBundleMetrics(),
      'animation': {
        'quality': _animationOptimizer.animationQuality,
        'duration': _animationOptimizer.optimizedDuration.inMilliseconds,
      },
      'snappiness': _snappinessOptimizer.getSnappinessSettings(),
      'device': _performanceOptimizer.getDeviceCapabilities().toJson(),
    };
  }

  /// Manually trigger optimization
  Future<void> triggerOptimization() async {
    await _performanceOptimizer.triggerOptimization();
    await _bundleOptimizer.optimizeForLowMemory();
    await _snappinessOptimizer.optimizeSnappiness();
    await _animationOptimizer.refreshAnimationSettings();

    _eventController.add(OptimizationEvent.manualOptimization);
  }

  /// Get optimized page transitions
  PageTransitionsBuilder getOptimizedPageTransitions() {
    return _animationOptimizer.createOptimizedPageTransition();
  }

  /// Dispose resources
  void dispose() {
    _performanceOptimizer.dispose();
    _animationOptimizer.disposeCachedControllers();
    _eventController.close();
  }
}

/// Optimization event types
enum OptimizationEventType {
  initialized,
  performanceAdjusted,
  batteryOptimization,
  lowMemoryMode,
  manualOptimization,
}

class OptimizationEvent {
  final OptimizationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const OptimizationEvent(this.type, [this.data]) : timestamp = DateTime.now();

  factory OptimizationEvent.initialized = const OptimizationEvent(OptimizationEventType.initialized);
  factory OptimizationEvent.performanceAdjusted = const OptimizationEvent(OptimizationEventType.performanceAdjusted);
  factory OptimizationEvent.batteryOptimization = const OptimizationEvent(OptimizationEventType.batteryOptimization);
  factory OptimizationEvent.lowMemoryMode = const OptimizationEvent(OptimizationEventType.lowMemoryMode);
  factory OptimizationEvent.manualOptimization = const OptimizationEvent(OptimizationEventType.manualOptimization);
}

/// Extension methods for easy integration
extension OptimizationExtensions on BuildContext {
  /// Get the optimization manager instance
  OptimizationManager get optimization => OptimizationManager();

  /// Create optimized list view directly from context
  Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return OptimizationManager().createOptimizedListView(
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }
}

/// Helper widget to wrap apps with optimization
class OptimizationWrapper extends StatefulWidget {
  final Widget child;
  final bool enableOptimizations;

  const OptimizationWrapper({
    super.key,
    required this.child,
    this.enableOptimizations = true,
  });

  @override
  State<OptimizationWrapper> createState() => _OptimizationWrapperState();
}

class _OptimizationWrapperState extends State<OptimizationWrapper> {
  final OptimizationManager _optimizationManager = OptimizationManager();

  @override
  void initState() {
    super.initState();
    if (widget.enableOptimizations) {
      _optimizationManager.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _optimizationManager.dispose();
    super.dispose();
  }
}
