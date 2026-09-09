import 'package:flutter/material.dart';
import 'app_logger.dart';

/// Navigation event logger for route transitions.
class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.d('➡️ [Nav Pushed] Route: ${route.settings.name ?? 'Route'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.d('⬅️ [Nav Popped] Route: ${route.settings.name ?? 'Route'}');
  }
}
