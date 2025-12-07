import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Route guard that checks authentication status for protected routes
/// Redirects unauthenticated users to login screen
class RouteGuard {
  /// Provider container for accessing Riverpod providers outside of widget tree
  final ProviderContainer _container = ProviderContainer();

  /// Check if user is authenticated
  bool _isAuthenticated() {
    final authState = _container.read(authStateProvider);
    return authState.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );
  }

  /// Guard protected routes - redirect to login if not authenticated
  Route<dynamic>? guardProtectedRoute(RouteSettings settings, Route<dynamic>? protectedRoute) {
    if (_isAuthenticated()) {
      return protectedRoute;
    }

    // User not authenticated, redirect to login
    return MaterialPageRoute<dynamic>(
      builder: (context) => const LoginScreen(),
      settings: const RouteSettings(name: AppRouter.login),
      maintainState: false,
    );
  }

  /// Check if current route is accessible
  bool isRouteAccessible(String routeName) {
    final routeInfo = AppRoutes.getRouteInfo(routeName);
    if (routeInfo == null) return false;

    // Public routes are always accessible
    if (!routeInfo.requiresAuth) return true;

    // Protected routes require authentication
    return _isAuthenticated();
  }

  /// Get appropriate route based on authentication status
  String getInitialRoute() {
    if (_isAuthenticated()) {
      return AppRouter.home;
    }
    return AppRouter.login;
  }

  /// Handle authentication state changes
  void onAuthStateChanged(bool isAuthenticated, [String? redirectRoute]) {
    final currentRoute = _getCurrentRoute();

    if (isAuthenticated) {
      // User signed in
      if (currentRoute == AppRouter.login || currentRoute == AppRouter.splash) {
        // Redirect to home or specified route
        final targetRoute = redirectRoute ?? AppRouter.home;
        _navigateToRoute(targetRoute);
      }
    } else {
      // User signed out
      if (AppRoutes.getRouteInfo(currentRoute)?.requiresAuth == true) {
        // Redirect to login
        _navigateToRoute(AppRouter.login);
      }
    }
  }

  /// Get current route name
  String _getCurrentRoute() {
    // This would need to be implemented to track current route
    // For now, return home as fallback
    return AppRouter.home;
  }

  /// Navigate to route
  void _navigateToRoute(String routeName) {
    final navigatorKey = AppRouter.navigatorKey;
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushReplacementNamed(routeName);
    }
  }

  /// Clean up resources
  void dispose() {
    _container.dispose();
  }
}

/// Authentication-aware navigation observer
/// Monitors route changes and handles authentication redirects
class AuthNavigationObserver extends NavigatorObserver {
  final RouteGuard _routeGuard;

  AuthNavigationObserver(this._routeGuard);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute.settings.name);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // Handle route removal if needed
  }

  void _handleRouteChange(String? routeName) {
    if (routeName == null) return;

    final routeInfo = AppRoutes.getRouteInfo(routeName);
    if (routeInfo == null) return;

    // Log navigation for debugging
    _logNavigation(routeName, routeInfo.requiresAuth);
  }

  void _logNavigation(String routeName, bool requiresAuth) {
    // In debug mode, log navigation events
    assert(() {
      print('🧭 Navigation: $routeName (Auth required: $requiresAuth)');
      return true;
    }());
  }
}

/// Route transition configurations
class RouteTransitions {
  /// Standard material page transition
  static RouteTransitionsBuilder material = (context, animation, secondaryAnimation, child) {
    return child; // Default MaterialPageRoute transition
  };

  /// Fade transition
  static RouteTransitionsBuilder fade = (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  };

  /// Slide from right transition
  static RouteTransitionsBuilder slideRight = (context, animation, secondaryAnimation, child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  };

  /// Slide from bottom transition (for modals)
  static RouteTransitionsBuilder slideUp = (context, animation, secondaryAnimation, child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  };

  /// Scale transition
  static RouteTransitionsBuilder scale = (context, animation, secondaryAnimation, child) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  };
}

/// Route configuration class for custom transitions
class RouteConfig {
  final String name;
  final RouteTransitionsBuilder transition;
  final bool fullscreenDialog;
  final Duration transitionDuration;

  const RouteConfig({
    required this.name,
    required this.transition,
    this.fullscreenDialog = false,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  /// Default route configurations
  static final List<RouteConfig> defaults = [
    RouteConfig(
      name: AppRouter.camera,
      transition: RouteTransitions.fade,
      fullscreenDialog: true,
    ),
    RouteConfig(
      name: AppRouter.receiptProcessing,
      transition: RouteTransitions.fade,
      fullscreenDialog: true,
    ),
    RouteConfig(
      name: AppRouter.createBudget,
      transition: RouteTransitions.slideUp,
      fullscreenDialog: true,
    ),
  ];

  /// Get route config by name
  static RouteConfig? getConfig(String routeName) {
    return defaults.firstWhere(
      (config) => config.name == routeName,
      orElse: () => RouteConfig(
        name: '',
        transition: RouteTransitions.material,
      ),
    );
  }
}
