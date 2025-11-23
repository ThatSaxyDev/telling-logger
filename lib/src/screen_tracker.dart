import 'package:flutter/widgets.dart';

/// Tracks screen navigation and reports screen views
class ScreenTracker extends RouteObserver<PageRoute<dynamic>> {
  /// Callback when a new screen is viewed
  final Function(String screenName, String? previousScreen) onScreenView;
  
  /// Current screen name
  String? _currentScreen;
  
  ScreenTracker({required this.onScreenView});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _trackScreen(route, previousRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _trackScreen(previousRoute, route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _trackScreen(newRoute, oldRoute);
    }
  }

  void _trackScreen(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      final screenName = route.settings.name ?? 'Unknown';
      final previousScreen = previousRoute is PageRoute 
          ? previousRoute.settings.name 
          : null;

      // Only track if screen actually changed
      if (screenName != _currentScreen) {
        _currentScreen = screenName;
        onScreenView(screenName, previousScreen);
      }
    }
  }
}
