import 'package:flutter/widgets.dart';

/// NavigatorObserver specifically designed for go_router compatibility
class GoRouterScreenTracker extends NavigatorObserver {
  /// Callback when a new screen is viewed
  final Function(String screenName, String? previousScreen) onScreenView;
  
  /// Current screen path
  String? _currentScreen;
  
  GoRouterScreenTracker({required this.onScreenView});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackNavigation(route, previousRoute, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // When popping, we care about where we're going (previousRoute)
    if (previousRoute != null) {
      _trackNavigation(previousRoute, route, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackNavigation(newRoute, oldRoute, 'replace');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _trackNavigation(previousRoute, route, 'remove');
    }
  }

  void _trackNavigation(Route<dynamic> route, Route<dynamic>? previousRoute, String action) {
    // Try to get route name/path from settings
    String? screenName = route.settings.name;
    
    // If no name in settings, try to extract from arguments (go_router passes location here sometimes)
    if (screenName == null || screenName.isEmpty || screenName == '/') {
      final args = route.settings.arguments;
      if (args is Map && args.containsKey('location')) {
        screenName = args['location'] as String?;
      }
    }
    
    // Fallback to route type
    screenName ??= 'UNNAMED_SCREEN';
    
    // Get previous screen name
    String? previousScreen;
    if (previousRoute != null) {
      previousScreen = previousRoute.settings.name;
      if (previousScreen == null || previousScreen.isEmpty) {
        final args = previousRoute.settings.arguments;
        if (args is Map && args.containsKey('location')) {
          previousScreen = args['location'] as String?;
        }
      }
      previousScreen ??= 'UNNAMED_SCREEN';
    }

    // Only track if screen actually changed
    if (screenName != _currentScreen) {
      _currentScreen = screenName;
      onScreenView(screenName, previousScreen);
    }
  }
  
  /// Helper to extract route info for debugging
  // String _routeStr(Route<dynamic> route) {
  //   return 'route(${route.settings.name}: ${route.settings.arguments})';
  // }
}
