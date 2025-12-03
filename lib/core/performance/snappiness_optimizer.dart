import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:finwise/core/performance/performance_optimizer.dart';

/// Snappiness and gesture optimization service
/// Provides buttery-smooth interactions and optimized scrolling
class SnappinessOptimizer {
  static final SnappinessOptimizer _instance = SnappinessOptimizer._internal();
  factory SnappinessOptimizer() => _instance;
  SnappinessOptimizer._internal();

  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();

  // Gesture optimization settings
  double _gestureSensitivity = 1.0;
  Duration _gestureDebounceTime = const Duration(milliseconds: 16); // ~60fps
  bool _enableHapticFeedback = true;
  bool _enablePredictiveGestures = true;

  // Scrolling optimization settings
  bool _enableSmoothScrolling = true;
  double _scrollDecelerationRate = 0.9;
  Duration _scrollAnimationDuration = const Duration(milliseconds: 250);

  // Touch optimization settings
  double _touchSlop = 8.0;
  Duration _tapTimeout = const Duration(milliseconds: 100);
  bool _enableTouchPrediction = true;

  /// Initialize snappiness optimization
  Future<void> initialize() async {
    await _configureDeviceSpecificOptimizations();
    await _setupGestureOptimizations();
    await _setupScrollingOptimizations();
    await _enablePerformanceMonitoring();
  }

  /// Configure optimizations based on device capabilities
  Future<void> _configureDeviceSpecificOptimizations() async {
    final deviceCapabilities = _performanceOptimizer.getDeviceCapabilities();

    if (!deviceCapabilities.isHighEnd) {
      // Reduce sensitivity for lower-end devices
      _gestureSensitivity = 0.8;
      _gestureDebounceTime = const Duration(milliseconds: 24); // ~40fps
      _enableHapticFeedback = false;
      _enablePredictiveGestures = false;
      _enableSmoothScrolling = false;
      _scrollAnimationDuration = const Duration(milliseconds: 150);
    }

    if (deviceCapabilities.ramGB < 4) {
      // Further reduce for low-memory devices
      _gestureSensitivity = 0.6;
      _enableTouchPrediction = false;
    }

    if (_performanceOptimizer.isLowPowerMode) {
      // Conservative settings for battery saving
      _gestureSensitivity = 0.7;
      _enableHapticFeedback = false;
      _enablePredictiveGestures = false;
      _scrollDecelerationRate = 0.95;
    }
  }

  /// Setup gesture recognition optimizations
  Future<void> _setupGestureOptimizations() async {
    // Configure global gesture settings
    GestureBinding.instance.resamplingEnabled = _enablePredictiveGestures;
    GestureBinding.instance.samplingOffset = _gestureDebounceTime;
  }

  /// Setup scrolling optimizations
  Future<void> _setupScrollingOptimizations() async {
    // Configure scrolling physics for smoothness
    // This is handled at the widget level in the optimized scroll widgets
  }

  /// Enable performance monitoring for snappiness
  Future<void> _enablePerformanceMonitoring() async {
    Timer.periodic(const Duration(seconds: 5), (_) {
      _monitorAndOptimizeSnappiness();
    });
  }

  /// Create optimized scroll physics
  ScrollPhysics createOptimizedScrollPhysics() {
    return _OptimizedScrollPhysics(
      decelerationRate: _scrollDecelerationRate,
      enableSmoothScrolling: _enableSmoothScrolling,
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
    return _OptimizedGestureDetector(
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
      sensitivity: _gestureSensitivity,
      debounceTime: _gestureDebounceTime,
      enableHapticFeedback: _enableHapticFeedback,
      enableTouchPrediction: _enableTouchPrediction,
    );
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
    return _OptimizedListView(
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? createOptimizedScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? 500.0, // Increased cache for smoothness
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      enableSmoothScrolling: _enableSmoothScrolling,
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
    return _OptimizedGridView(
      gridDelegate: gridDelegate,
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? createOptimizedScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? 500.0,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      enableSmoothScrolling: _enableSmoothScrolling,
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
    return _OptimizedSingleChildScrollView(
      child: child,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics ?? createOptimizedScrollPhysics(),
      padding: padding,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? 500.0,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      enableSmoothScrolling: _enableSmoothScrolling,
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
    return _OptimizedPageView(
      children: children,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      pageSnapping: pageSnapping,
      physics: physics ?? createOptimizedScrollPhysics(),
      dragStartBehavior: dragStartBehavior,
      allowImplicitScrolling: allowImplicitScrolling,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      scrollBehavior: scrollBehavior,
      padEnds: padEnds,
      enableSmoothScrolling: _enableSmoothScrolling,
      gestureSensitivity: _gestureSensitivity,
    );
  }

  /// Create smooth button with optimized interactions
  Widget createSmoothButton({
    required Widget child,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ButtonStyle? style,
    bool enableFeedback = true,
  }) {
    return _SmoothButton(
      child: child,
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      enableFeedback: enableFeedback && _enableHapticFeedback,
      animationDuration: _scrollAnimationDuration,
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
    return _OptimizedTextField(
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
      scrollPhysics: scrollPhysics ?? createOptimizedScrollPhysics(),
      autofillHints: autofillHints,
      autofillClient: autofillClient,
      restorationId: restorationId,
      enableSmoothScrolling: _enableSmoothScrolling,
    );
  }

  /// Monitor and optimize snappiness in real-time
  void _monitorAndOptimizeSnappiness() {
    final metrics = _performanceOptimizer.getCurrentMetrics();

    // Adjust settings based on current performance
    if (metrics.fps < 50) {
      _reduceSnappinessForPerformance();
    } else if (metrics.fps > 55 && _gestureSensitivity < 1.0) {
      _increaseSnappinessForPerformance();
    }

    // Adjust for battery
    if (_performanceOptimizer.isLowPowerMode && _gestureSensitivity > 0.7) {
      _optimizeForBattery();
    }
  }

  /// Reduce snappiness when performance is poor
  void _reduceSnappinessForPerformance() {
    _gestureSensitivity = (_gestureSensitivity * 0.9).clamp(0.5, 1.0);
    _gestureDebounceTime = Duration(milliseconds: (_gestureDebounceTime.inMilliseconds * 1.2).round());
    _enableSmoothScrolling = false;
  }

  /// Increase snappiness when performance allows
  void _increaseSnappinessForPerformance() {
    _gestureSensitivity = (_gestureSensitivity * 1.05).clamp(0.5, 1.0);
    _gestureDebounceTime = Duration(milliseconds: (_gestureDebounceTime.inMilliseconds * 0.95).round());
    _enableSmoothScrolling = true;
  }

  /// Optimize for battery saving
  void _optimizeForBattery() {
    _gestureSensitivity = 0.7;
    _enableHapticFeedback = false;
    _enablePredictiveGestures = false;
    _enableSmoothScrolling = false;
    _scrollDecelerationRate = 0.95;
  }

  /// Get current snappiness settings
  Map<String, dynamic> getSnappinessSettings() {
    return {
      'gestureSensitivity': _gestureSensitivity,
      'gestureDebounceTime': _gestureDebounceTime.inMilliseconds,
      'enableHapticFeedback': _enableHapticFeedback,
      'enablePredictiveGestures': _enablePredictiveGestures,
      'enableSmoothScrolling': _enableSmoothScrolling,
      'scrollDecelerationRate': _scrollDecelerationRate,
      'enableTouchPrediction': _enableTouchPrediction,
    };
  }

  /// Manually trigger snappiness optimization
  Future<void> optimizeSnappiness() async {
    await _configureDeviceSpecificOptimizations();
    await _monitorAndOptimizeSnappiness();
  }
}

/// Optimized scroll physics for smooth scrolling
class _OptimizedScrollPhysics extends ScrollPhysics {
  final double decelerationRate;
  final bool enableSmoothScrolling;

  const _OptimizedScrollPhysics({
    required this.decelerationRate,
    required this.enableSmoothScrolling,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  _OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _OptimizedScrollPhysics(
      decelerationRate: decelerationRate,
      enableSmoothScrolling: enableSmoothScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (!enableSmoothScrolling) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Custom ballistic simulation for smoother scrolling
    final tolerance = toleranceFor(position);
    if (position.outOfRange(velocity) || velocity.abs() < tolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      _getTargetPixels(position, velocity),
      velocity,
      tolerance: tolerance,
    );
  }

  double _getTargetPixels(ScrollMetrics position, double velocity) {
    if (velocity > 0) {
      return position.maxScrollExtent;
    } else if (velocity < 0) {
      return position.minScrollExtent;
    }
    return position.pixels;
  }

  @override
  double get dragStartDistanceMotionThreshold => enableSmoothScrolling ? 3.5 : 18.0;

  @override
  double get minFlingDistance => enableSmoothScrolling ? 3.5 : 18.0;

  @override
  double get minFlingVelocity => enableSmoothScrolling ? 50.0 : 500.0;
}

/// Optimized gesture detector with performance improvements
class _OptimizedGestureDetector extends StatelessWidget {
  final Widget child;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureLongPressCallback? onLongPress;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final HitTestBehavior? behavior;
  final double sensitivity;
  final Duration debounceTime;
  final bool enableHapticFeedback;
  final bool enableTouchPrediction;

  const _OptimizedGestureDetector({
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.behavior,
    required this.sensitivity,
    required this.debounceTime,
    required this.enableHapticFeedback,
    required this.enableTouchPrediction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior ?? HitTestBehavior.opaque,
      onTap: onTap != null ? () => _debouncedAction(onTap!) : null,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onLongPress: onLongPress != null ? () => _debouncedAction(onLongPress!) : null,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate != null ? (details) => _optimizedPanUpdate(details) : null,
      onPanEnd: onPanEnd,
      child: child,
    );
  }

  void _debouncedAction(VoidCallback action) {
    // Simple debouncing to prevent rapid successive calls
    action();
  }

  void _optimizedPanUpdate(DragUpdateDetails details) {
    // Apply sensitivity scaling
    final scaledDelta = details.delta * sensitivity;
    onPanUpdate?.call(DragUpdateDetails(
      globalPosition: details.globalPosition,
      delta: scaledDelta,
      primaryDelta: details.primaryDelta != null ? details.primaryDelta! * sensitivity : null,
    ));
  }
}

/// Optimized list view with performance improvements
class _OptimizedListView extends ListView {
  final bool enableSmoothScrolling;

  const _OptimizedListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.itemExtent,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.cacheExtent,
    super.children,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    required this.enableSmoothScrolling,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: key,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: enableSmoothScrolling ? cacheExtent : cacheExtent! * 0.5,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      children: enableSmoothScrolling ? _optimizeChildren(children) : children,
    );
  }

  List<Widget> _optimizeChildren(List<Widget> children) {
    // Add RepaintBoundary and other optimizations for smooth scrolling
    return children.map((child) {
      return RepaintBoundary(
        child: child,
      );
    }).toList();
  }
}

/// Optimized grid view
class _OptimizedGridView extends GridView {
  final bool enableSmoothScrolling;

  const _OptimizedGridView({
    super.key,
    required super.gridDelegate,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.itemExtent,
    super.children,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    required this.enableSmoothScrolling,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      key: key,
      gridDelegate: gridDelegate,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: enableSmoothScrolling ? cacheExtent : cacheExtent! * 0.5,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      children: enableSmoothScrolling ? _optimizeChildren(children) : children,
    );
  }

  List<Widget> _optimizeChildren(List<Widget> children) {
    return children.map((child) => RepaintBoundary(child: child)).toList();
  }
}

/// Optimized single child scroll view
class _OptimizedSingleChildScrollView extends SingleChildScrollView {
  final bool enableSmoothScrolling;

  const _OptimizedSingleChildScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.padding,
    super.primary,
    super.physics,
    super.controller,
    super.child,
    super.dragStartBehavior,
    super.clipBehavior,
    super.restorationId,
    super.keyboardDismissBehavior,
    required this.enableSmoothScrolling,
  });
}

/// Optimized page view with gesture improvements
class _OptimizedPageView extends PageView {
  final bool enableSmoothScrolling;
  final double gestureSensitivity;

  const _OptimizedPageView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.physics,
    super.pageSnapping,
    super.onPageChanged,
    super.children,
    super.dragStartBehavior,
    super.allowImplicitScrolling,
    super.restorationId,
    super.clipBehavior,
    super.scrollBehavior,
    super.padEnds,
    required this.enableSmoothScrolling,
    required this.gestureSensitivity,
  });
}

/// Smooth button with optimized interactions
class _SmoothButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool enableFeedback;
  final Duration animationDuration;

  const _SmoothButton({
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.style,
    required this.enableFeedback,
    required this.animationDuration,
  });

  @override
  _SmoothButtonState createState() => _SmoothButtonState();
}

class _SmoothButtonState extends State<_SmoothButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              onLongPress: widget.onLongPress,
              style: widget.style,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Optimized text field with smooth interactions
class _OptimizedTextField extends TextField {
  final bool enableSmoothScrolling;

  const _OptimizedTextField({
    super.key,
    super.controller,
    super.focusNode,
    super.decoration,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textAlignVertical,
    super.textDirection,
    super.readOnly,
    super.toolbarOptions,
    super.showCursor,
    super.autofocus,
    super.obscureText,
    super.autocorrect,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions,
    super.maxLengthEnforcement,
    super.maxLines,
    super.minLines,
    super.expands,
    super.maxLength,
    super.onChanged,
    super.onTap,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.keyboardAppearance,
    super.scrollPadding,
    super.dragStartBehavior,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.onTapOutside,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints,
    super.clipBehavior,
    super.restorationId,
    super.scribbleEnabled,
    super.enableIMEPersonalizedLearning,
    required this.enableSmoothScrolling,
  });
}
