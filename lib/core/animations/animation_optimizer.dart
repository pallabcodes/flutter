import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:finwise/core/performance/performance_optimizer.dart';

/// Animation and transition optimization service
/// Provides smooth, battery-efficient animations and custom transitions
class AnimationOptimizer {
  static final AnimationOptimizer _instance = AnimationOptimizer._internal();
  factory AnimationOptimizer() => _instance;
  AnimationOptimizer._internal();

  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();

  // Animation performance settings
  Duration _defaultDuration = const Duration(milliseconds: 300);
  Curve _defaultCurve = Curves.easeOutCubic;
  double _animationQuality = 1.0; // 0.0 to 1.0

  // Cached animation controllers
  final Map<String, AnimationController> _cachedControllers = {};

  /// Initialize animation optimization
  Future<void> initialize() async {
    await _setupAnimationOptimization();
    await _configurePerformanceBasedAnimations();
  }

  /// Setup animation optimization based on device capabilities
  Future<void> _setupAnimationOptimization() async {
    final deviceCapabilities = _performanceOptimizer.getDeviceCapabilities();

    if (!deviceCapabilities.isHighEnd) {
      // Reduce animation quality for lower-end devices
      _animationQuality = 0.7;
      _defaultDuration = const Duration(milliseconds: 200);
      _defaultCurve = Curves.easeOut;
    }

    if (deviceCapabilities.ramGB < 4) {
      // Further reduce for low-memory devices
      _animationQuality = 0.5;
      _defaultDuration = const Duration(milliseconds: 150);
    }

    if (_performanceOptimizer.isLowPowerMode) {
      // Reduce animations when battery is low
      _animationQuality = 0.3;
      _defaultDuration = const Duration(milliseconds: 100);
    }
  }

  /// Configure performance-based animation adjustments
  Future<void> _configurePerformanceBasedAnimations() async {
    // Monitor performance and adjust animations dynamically
    Timer.periodic(const Duration(seconds: 10), (_) {
      final metrics = _performanceOptimizer.getCurrentMetrics();

      if (metrics.fps < 50) {
        // Reduce animation quality when FPS is low
        _reduceAnimationQuality();
      } else if (metrics.fps > 55 && _animationQuality < 1.0) {
        // Gradually increase quality when performance is good
        _increaseAnimationQuality();
      }
    });
  }

  /// Create optimized page transition
  PageTransitionsBuilder createOptimizedPageTransition() {
    return _OptimizedPageTransitionsBuilder();
  }

  /// Create smooth list item animation
  Widget createAnimatedListItem({
    required Widget child,
    required int index,
    Duration? delay,
    Offset? slideOffset,
    double? scale,
  }) {
    return _AnimatedListItem(
      child: child,
      index: index,
      delay: delay ?? Duration(milliseconds: index * 50),
      slideOffset: slideOffset ?? const Offset(0, 0.1),
      scale: scale ?? 0.95,
      quality: _animationQuality,
    );
  }

  /// Create smooth loading animation
  Widget createSmoothLoader({
    Color? color,
    double? size,
    String? message,
  }) {
    return _SmoothLoader(
      color: color ?? Colors.blue,
      size: size ?? 40.0,
      message: message,
      quality: _animationQuality,
    );
  }

  /// Create custom hero transition
  Widget createCustomHero({
    required Object tag,
    required Widget child,
    Curve? flightShuttleBuilder,
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: flightShuttleBuilder ?? _createHeroFlightShuttle,
      child: child,
    );
  }

  /// Create staggered animation for multiple items
  Widget createStaggeredAnimation({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Offset? slideOffset,
    double? fadeStart,
  }) {
    return _StaggeredAnimation(
      children: children,
      staggerDelay: staggerDelay,
      slideOffset: slideOffset ?? const Offset(0, 0.2),
      fadeStart: fadeStart ?? 0.0,
      quality: _animationQuality,
    );
  }

  /// Create smooth state transition
  Widget createStateTransition({
    required Widget child,
    required Animation<double> animation,
    bool isForward = true,
  }) {
    return _StateTransition(
      child: child,
      animation: animation,
      isForward: isForward,
      quality: _animationQuality,
    );
  }

  /// Create gesture-based interactive animation
  Widget createInteractiveAnimation({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Duration? animationDuration,
  }) {
    return _InteractiveAnimation(
      child: child,
      onTap: onTap,
      onLongPress: onLongPress,
      animationDuration: animationDuration ?? _defaultDuration,
      quality: _animationQuality,
    );
  }

  /// Create micro-interaction animation
  Widget createMicroInteraction({
    required Widget child,
    required MicroInteractionType type,
    VoidCallback? onComplete,
  }) {
    return _MicroInteraction(
      child: child,
      type: type,
      onComplete: onComplete,
      quality: _animationQuality,
    );
  }

  /// Create smooth bottom sheet animation
  Widget createSmoothBottomSheet({
    required Widget child,
    required Animation<double> animation,
    BorderRadius? borderRadius,
  }) {
    return _SmoothBottomSheet(
      child: child,
      animation: animation,
      borderRadius: borderRadius ?? BorderRadius.circular(16.0),
      quality: _animationQuality,
    );
  }

  /// Create loading shimmer effect
  Widget createShimmerEffect({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? period,
  }) {
    return _ShimmerEffect(
      child: child,
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: period ?? const Duration(milliseconds: 1500),
      quality: _animationQuality,
    );
  }

  /// Preload and cache animation assets
  Future<void> preloadAnimationAssets() async {
    // Preload commonly used animation assets
    // This helps reduce jank during first animations
  }

  /// Get cached animation controller
  AnimationController getCachedController({
    required TickerProvider vsync,
    required String key,
    Duration? duration,
  }) {
    if (_cachedControllers.containsKey(key)) {
      return _cachedControllers[key]!;
    }

    final controller = AnimationController(
      vsync: vsync,
      duration: duration ?? _defaultDuration,
    );

    _cachedControllers[key] = controller;
    return controller;
  }

  /// Dispose cached controllers
  void disposeCachedControllers() {
    for (final controller in _cachedControllers.values) {
      controller.dispose();
    }
    _cachedControllers.clear();
  }

  /// Reduce animation quality for performance
  void _reduceAnimationQuality() {
    if (_animationQuality > 0.3) {
      _animationQuality = (_animationQuality - 0.1).clamp(0.3, 1.0);
      _defaultDuration = Duration(milliseconds: (_defaultDuration.inMilliseconds * 0.8).round());
    }
  }

  /// Increase animation quality when performance allows
  void _increaseAnimationQuality() {
    if (_animationQuality < 1.0) {
      _animationQuality = (_animationQuality + 0.05).clamp(0.3, 1.0);
      _defaultDuration = Duration(milliseconds: (_defaultDuration.inMilliseconds * 1.1).round());
    }
  }

  /// Create hero flight shuttle
  Widget _createHeroFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return _HeroFlightShuttle(
      animation: animation,
      fromHeroContext: fromHeroContext,
      toHeroContext: toHeroContext,
      quality: _animationQuality,
    );
  }

  /// Get current animation quality
  double get animationQuality => _animationQuality;

  /// Get optimized duration for animations
  Duration get optimizedDuration => _defaultDuration;

  /// Get optimized curve for animations
  Curve get optimizedCurve => _defaultCurve;

  /// Force refresh animation settings
  Future<void> refreshAnimationSettings() async {
    await _setupAnimationOptimization();
  }
}

/// Optimized page transitions builder
class _OptimizedPageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use fade transition for better performance on lower-end devices
    final deviceCapabilities = PerformanceOptimizer().getDeviceCapabilities();

    if (!deviceCapabilities.isHighEnd) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    }

    // Use slide transition with optimized curve for high-end devices
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}

/// Animated list item with performance optimizations
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Offset slideOffset;
  final double scale;
  final double quality;

  const _AnimatedListItem({
    required this.child,
    required this.index,
    required this.delay,
    required this.slideOffset,
    required this.scale,
    required this.quality,
  });

  @override
  _AnimatedListItemState createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (300 * widget.quality).round()),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.scale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Smooth loading animation
class _SmoothLoader extends StatefulWidget {
  final Color color;
  final double size;
  final String? message;
  final double quality;

  const _SmoothLoader({
    required this.color,
    required this.size,
    required this.message,
    required this.quality,
  });

  @override
  _SmoothLoaderState createState() => _SmoothLoaderState();
}

class _SmoothLoaderState extends State<_SmoothLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    final duration = Duration(milliseconds: (2000 / widget.quality).round());

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    strokeWidth: 3.0,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Staggered animation for multiple items
class _StaggeredAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Offset slideOffset;
  final double fadeStart;
  final double quality;

  const _StaggeredAnimation({
    required this.children,
    required this.staggerDelay,
    required this.slideOffset,
    required this.fadeStart,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = Duration(milliseconds: index * staggerDelay.inMilliseconds);

        return _AnimatedListItem(
          child: child,
          index: index,
          delay: delay,
          slideOffset: slideOffset,
          scale: 1.0,
          quality: quality,
        );
      }).toList(),
    );
  }
}

/// State transition animation
class _StateTransition extends AnimatedWidget {
  final Widget child;
  final bool isForward;
  final double quality;

  const _StateTransition({
    required Animation<double> animation,
    required this.child,
    required this.isForward,
    required this.quality,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    return FadeTransition(
      opacity: Tween<double>(
        begin: isForward ? 0.0 : 1.0,
        end: isForward ? 1.0 : 0.0,
      ).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: isForward ? const Offset(0.1, 0) : Offset.zero,
          end: isForward ? Offset.zero : const Offset(-0.1, 0),
        ).animate(CurvedAnimation(
          parent: animation,
          curve: quality > 0.7 ? Curves.easeOutCubic : Curves.easeOut,
        )),
        child: child,
      ),
    );
  }
}

/// Interactive animation with gesture feedback
class _InteractiveAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration animationDuration;
  final double quality;

  const _InteractiveAnimation({
    required this.child,
    this.onTap,
    this.onLongPress,
    required this.animationDuration,
    required this.quality,
  });

  @override
  _InteractiveAnimationState createState() => _InteractiveAnimationState();
}

class _InteractiveAnimationState extends State<_InteractiveAnimation>
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
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
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
            child: widget.child,
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

/// Micro-interaction animations
enum MicroInteractionType {
  success,
  error,
  warning,
  pulse,
  bounce,
  shake,
}

class _MicroInteraction extends StatefulWidget {
  final Widget child;
  final MicroInteractionType type;
  final VoidCallback? onComplete;
  final double quality;

  const _MicroInteraction({
    required this.child,
    required this.type,
    this.onComplete,
    required this.quality,
  });

  @override
  _MicroInteractionState createState() => _MicroInteractionState();
}

class _MicroInteractionState extends State<_MicroInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    final duration = Duration(milliseconds: (400 * widget.quality).round());

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    switch (widget.type) {
      case MicroInteractionType.success:
        _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case MicroInteractionType.error:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case MicroInteractionType.pulse:
        _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case MicroInteractionType.bounce:
        _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
      case MicroInteractionType.shake:
        _animation = Tween<double>(begin: -5.0, end: 5.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
        );
        break;
      default:
        _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    }

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        switch (widget.type) {
          case MicroInteractionType.shake:
            return Transform.translate(
              offset: Offset(_animation.value, 0),
              child: widget.child,
            );
          default:
            return Transform.scale(
              scale: _animation.value,
              child: widget.child,
            );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Smooth bottom sheet animation
class _SmoothBottomSheet extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final BorderRadius borderRadius;
  final double quality;

  const _SmoothBottomSheet({
    required this.child,
    required this.animation,
    required this.borderRadius,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius.topLeft.x * animation.value),
            topRight: Radius.circular(borderRadius.topRight.x * animation.value),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1 * animation.value),
                  blurRadius: 10 * animation.value,
                  spreadRadius: 2 * animation.value,
                ),
              ],
            ),
            child: this.child,
          ),
        );
      },
    );
  }
}

/// Shimmer loading effect
class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;
  final double quality;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.period,
    required this.quality,
  });

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quality < 0.5) {
      // Skip shimmer on low-quality mode
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Custom hero flight shuttle
class _HeroFlightShuttle extends StatelessWidget {
  final Animation<double> animation;
  final BuildContext fromHeroContext;
  final BuildContext toHeroContext;
  final double quality;

  const _HeroFlightShuttle({
    required this.animation,
    required this.fromHeroContext,
    required this.toHeroContext,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified hero animation - in production, this would be more sophisticated
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 1.0,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: DefaultTextStyle(
          style: DefaultTextStyle.of(fromHeroContext).style,
          child: Container(
            color: Colors.white,
            child: const Icon(Icons.account_balance_wallet, size: 48),
          ),
        ),
      ),
    );
  }
}
