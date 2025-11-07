import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/view/helper/chucker_ui_helper.dart';
import 'package:flutter/material.dart';

/// Custom NavigatorObserver for Chucker Flutter that properly manages
/// navigation state and provides context for HTTP request tracking
///
/// Each instance is independent but reports to shared global state
class ChuckerNavigatorObserver extends NavigatorObserver {
  /// Get the main app navigator instance (from global state)
  NavigatorState? get navigator => ChuckerFlutter.mainNavigator;

  /// Get the current route name (from global state)
  String? get currentRoute => ChuckerFlutter.getCurrentRoute();

  /// Get navigation history (from global state)
  List<String> get routeHistory => ChuckerFlutter.getNavigationHistory();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateMainNavigatorReference();
    _trackRouteChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateMainNavigatorReference();
    if (previousRoute != null) {
      _trackRouteChange(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateMainNavigatorReference();
    if (newRoute != null) {
      _trackRouteChange(newRoute, 'replace');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateMainNavigatorReference();
    if (previousRoute != null) {
      _trackRouteChange(previousRoute, 'remove');
    }
  }

  /// Update the main navigator reference (delegates to global state)
  void _updateMainNavigatorReference() {
    ChuckerFlutter.setMainNavigator(super.navigator);
  }

  /// Track route changes for HTTP request context (delegates to global state)
  void _trackRouteChange(Route<dynamic> route, String action) {
    final routeName = route.settings.name ?? 'Unknown Route';
    ChuckerFlutter.updateRoute(routeName, action);

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

  /// Get navigation context for HTTP requests (delegates to global state)
  Map<String, dynamic> getNavigationContext() {
    return ChuckerFlutter.getNavigationContext();
  }
}
