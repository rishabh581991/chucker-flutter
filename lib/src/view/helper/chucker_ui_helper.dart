import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/settings.dart';
import 'package:chucker_flutter/src/view/chucker_page.dart';
import 'package:chucker_flutter/src/view/helper/chucker_button.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:chucker_flutter/src/view/widgets/notification.dart'
    as notification;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///[ChuckerUiHelper] handles the UI part of `chucker_flutter`
///
///You must initialize ChuckerObserver in the `MaterialApp`
///of your application as it is required to show notification and the screens
///of `chucker_flutter`
class ChuckerUiHelper {
  static final List<OverlayEntry?> _overlayEntries = List.empty(growable: true);

  ///Only for testing
  static bool notificationShown = false;

  ///[settings] to modify ui behaviour of chucker screens and notification
  static Settings settings = Settings.defaultObject();

  ///[showNotification] shows the rest api [method] (GET, POST, PUT, etc),
  ///[statusCode] (200, 400, etc) response status and [path]
  static bool showNotification({
    required String method,
    required int statusCode,
    required String path,
    required DateTime requestTime,
  }) {
    notificationShown = false;

    if (!ChuckerUiHelper.settings.showNotification) {
      debugPrint(
        '''
ChuckerFlutter: Your notification setting is off. You can turn it on by visiting the settings page from Chucker Flutter screen.
        ''',
      );
      return false;
    }
    // Try to get navigator for overlay - use dual navigation system
    final navigator = ChuckerFlutter._navigator;
    if (navigator == null) {
      debugPrint(
        '''
ChuckerFlutter: No navigator available. Either add ChuckerFlutter.navigatorObserver to your MaterialApp or call ChuckerFlutter.initialize() after your app starts.
        ''',
      );
      return false;
    }
    if (!ChuckerFlutter.showNotification) {
      debugPrint(
        '''
ChuckerFlutter: You programmatically vetoed notification behavior. Make sure to remove `ChuckerFlutter.showNotification = true` to continue receiving notifications.
        ''',
      );
      return false;
    }

    final overlay = navigator.overlay;
    final entry = _createOverlayEntry(method, statusCode, path, requestTime);
    _overlayEntries.add(entry);
    overlay?.insert(entry);
    notificationShown = true;
    return true;
  }

  static OverlayEntry _createOverlayEntry(
    String method,
    int statusCode,
    String path,
    DateTime requestTime,
  ) {
    return OverlayEntry(
      builder: (context) {
        return Align(
          alignment: settings.notificationAlignment,
          child: notification.Notification(
            statusCode: statusCode,
            method: method,
            path: path,
            removeNotification: _removeNotification,
            requestTime: requestTime,
          ),
        );
      },
    );
  }

  static void _removeNotification() {
    for (final entry in _overlayEntries) {
      if (entry != null) {
        entry.remove();
      }
    }
    _overlayEntries.clear();
  }

  /// @rishabh::: [showChuckerScreen] shows the screen containing the list of recored
  ///api requests
  static void showChuckerScreen() {
    SharedPreferencesManager.getInstance().getSettings();
    final navigator = ChuckerFlutter._navigator;
    if (navigator == null) {
      debugPrint(
        '''
  ChuckerFlutter: Navigator is null. Make sure ChuckerFlutter.initialize() is called in your app 
  or that navigation context is available.
        ''',
      );
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => MaterialApp(
          key: const Key('chucker_material_app'),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: Localization.localizationsDelegates,
          supportedLocales: Localization.supportedLocales,
          locale: Localization.currentLocale,
          theme: ThemeData(
            useMaterial3: false,
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: primaryColor,
                ),
          ),
          home: const ChuckerPage(),
        ),
      ),
    );
  }
}

///[ChuckerFlutter] is a helper class to initialize the library
///
///[chuckerButton] and notifications only be visible in debug mode
class ChuckerFlutter {
  // Store navigation context without using NavigatorObserver
  static NavigatorState? _mainNavigator;
  static BuildContext? _buttonContext;
  static String? _currentRoute;
  static final List<String> _routeHistory = [];

  ///[navigatorObserver] - DEPRECATED: Returns null to avoid navigator conflicts with auto_route
  ///For compatibility, this returns null to avoid navigator conflicts
  static NavigatorObserver? get navigatorObserver => null;

  ///[showOnRelease] decides whether to allow Chucker Flutter working in release
  ///mode or not.
  ///By default its value is `false`
  static bool showOnRelease = false;

  ///[isDebugMode] A wrapper of Flutter's `kDebugMode` constant
  static bool isDebugMode = kDebugMode;

  ///[showNotification] decides whether to show in app notification or not
  ///By default its value is `true`
  static bool showNotification = true;

  ///[ChuckerButton] can be placed anywhere in the UI to open Chucker Screen
  static final chuckerButton = isDebugMode || ChuckerFlutter.showOnRelease
      ? ChuckerButton.getInstance()
      : const SizedBox.shrink();

  ///[showChuckerScreen] navigates to the chucker home screen
  static void showChuckerScreen() => ChuckerUiHelper.showChuckerScreen();

  /// Initialize ChuckerFlutter with the main navigator context
  /// Call this once in your main app after MaterialApp is created
  static void initialize(BuildContext context) {
    final navigator = Navigator.of(context);
    setMainNavigator(navigator);
  }

  // Internal methods to manage global state
  static void setMainNavigator(NavigatorState? navigator) {
    if (_mainNavigator == null && navigator != null) {
      _mainNavigator = navigator;
      debugPrint('ChuckerFlutter: Main navigator reference established');
    }
  }

  static NavigatorState? get _navigator {
    // Try to get the navigator from multiple sources
    if (_mainNavigator != null) {
      return _mainNavigator;
    }

    // Try to get from stored button context if available
    if (_buttonContext != null) {
      try {
        return Navigator.of(_buttonContext!);
      } catch (e) {
        debugPrint('ChuckerFlutter: Could not get navigator from button context: $e');
      }
    }

    // Try to get from current overlay context
    try {
      final overlay = WidgetsBinding.instance.rootElement;
      if (overlay != null) {
        final navigator = Navigator.maybeOf(overlay);
        if (navigator != null) {
          return navigator;
        }
      }
    } catch (e) {
      debugPrint('ChuckerFlutter: Could not find navigator from overlay: $e');
    }

    // Last fallback: try to get from global navigator key if available
    try {
      final context = WidgetsBinding.instance.rootElement;
      if (context != null) {
        return Navigator.of(context, rootNavigator: true);
      }
    } catch (e) {
      debugPrint('ChuckerFlutter: Could not find navigator context: $e');
    }

    return null;
  }

  // Public getter for the navigator
  static NavigatorState? get mainNavigator => _navigator;

  static void updateRoute(String? route, String action) {
    _currentRoute = route;
    _routeHistory.insert(0, '$action: ${route ?? "Unknown"}');
    if (_routeHistory.length > 10) {
      _routeHistory.removeLast();
    }
    debugPrint('ChuckerFlutter: Navigation $action - $route');
  }

  /// Get current navigation context for HTTP request tracking
  static Map<String, dynamic> getNavigationContext() {
    return {
      'currentRoute': _currentRoute ?? 'Unknown',
      'routeHistory': _routeHistory,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get current route name
  static String? getCurrentRoute() => _currentRoute;

  /// Get navigation history
  static List<String> getNavigationHistory() =>
      List.unmodifiable(_routeHistory);
  
  /// Store button context for navigation fallback
  static void setButtonContext(BuildContext? context) {
    _buttonContext = context;
  }
}

/*///[ChuckerFlutter] is a helper class to initialize the library
///
///[chuckerButton] and notifications only be visible in debug mode
class ChuckerFlutter {
  ///[navigatorObserver] observes the navigation of your app. It must be
  ///referenced in your MaterialApp widget
  static final navigatorObserver = NavigatorObserver();

  ///[showOnRelease] decides whether to allow Chucker Flutter working in release
  ///mode or not.
  ///By default its value is `false`
  static bool showOnRelease = false;

  ///[isDebugMode] A wrapper of Flutter's `kDebugMode` constant
  static bool isDebugMode = kDebugMode;

  ///[showNotification] decides whether to show in app notification or not
  ///By default its value is `true`
  static bool showNotification = true;

  ///[ChuckerButton] can be placed anywhere in the UI to open Chucker Screen
  static final chuckerButton = isDebugMode || ChuckerFlutter.showOnRelease
      ? ChuckerButton.getInstance()
      : const SizedBox.shrink();

  ///[showChuckerScreen] navigates to the chucker home screen
  static void showChuckerScreen() => ChuckerUiHelper.showChuckerScreen();
}*/
