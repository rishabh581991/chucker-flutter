import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:flutter/material.dart';

/// Custom NavigatorObserver for Chucker Flutter that properly manages
/// navigation state and provides context for HTTP request tracking
class ChuckerNavigatorObserver extends NavigatorObserver {
  NavigatorState? _navigator;
  String? _currentRoute;
  final List<String> _routeHistory = [];

  /// Get the current navigator instance
  NavigatorState? get navigator => _navigator;

  /// Get the current route name
  String? get currentRoute => _currentRoute;

  /// Get navigation history
  List<String> get routeHistory => List.unmodifiable(_routeHistory);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateNavigatorReference();
    _trackRouteChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateNavigatorReference();
    if (previousRoute != null) {
      _trackRouteChange(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateNavigatorReference();
    if (newRoute != null) {
      _trackRouteChange(newRoute, 'replace');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateNavigatorReference();
    if (previousRoute != null) {
      _trackRouteChange(previousRoute, 'remove');
    }
  }

  /// @rishabh::: Update the navigator reference from the current navigation stack
  void _updateNavigatorReference() {
    // Use the inherited navigator property from NavigatorObserver
    _navigator = super.navigator;
  }

  /// Track route changes for HTTP request context
  void _trackRouteChange(Route<dynamic> route, String action) {
    final routeName = route.settings.name ?? 'Unknown Route';
    _currentRoute = routeName;

    // Add to history (keep last 10 routes)
    _routeHistory.insert(0, '$action: $routeName');
    if (_routeHistory.length > 10) {
      _routeHistory.removeLast();
    }

    // Log navigation for debugging
    debugPrint('ChuckerFlutter: Navigation $action - $routeName');

    // Store current route in shared preferences for HTTP request context
    _storeCurrentRoute(routeName);
  }

  /// Store current route information for HTTP request association
  void _storeCurrentRoute(String routeName) {
    try {
      final prefs = SharedPreferencesManager.getInstance();
      // This could be used to associate HTTP requests with the current screen
      // Implementation depends on how you want to use this data
    } catch (e) {
      debugPrint('ChuckerFlutter: Failed to store route info - $e');
    }
  }

  /// Get navigation context for HTTP requests
  Map<String, dynamic> getNavigationContext() {
    return {
      'currentRoute': _currentRoute ?? 'Unknown',
      'routeHistory': _routeHistory,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
