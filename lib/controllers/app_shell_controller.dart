import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';

String normalizeAppRoute(String? route) => route?.trim() ?? '';

bool isHomeRoute(String? route) {
  return normalizeAppRoute(route) == AppPages.home;
}

bool shouldShowGlobalMiniPlayerOnRoute(String? route) {
  final String normalizedRoute = normalizeAppRoute(route);
  return normalizedRoute.isNotEmpty &&
      !isHomeRoute(normalizedRoute) &&
      normalizedRoute != AppPages.player &&
      normalizedRoute != AppPages.login &&
      normalizedRoute != AppPages.splash;
}

class AppShellController extends GetxController {
  final RxString currentRoute = AppPages.splash.obs;

  bool _routeSyncQueued = false;
  String? _pendingRouteName;

  void queueRouteSync([String? routeName]) {
    final String trimmedRoute = routeName?.trim() ?? '';
    if (trimmedRoute.isNotEmpty) {
      _pendingRouteName = trimmedRoute;
    }

    if (_routeSyncQueued) {
      return;
    }

    _routeSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeSyncQueued = false;

      final String fallbackRoute = Get.currentRoute.trim();
      final String nextRoute = (_pendingRouteName?.trim().isNotEmpty ?? false)
          ? _pendingRouteName!.trim()
          : fallbackRoute;

      _pendingRouteName = null;

      if (nextRoute.isEmpty || nextRoute == currentRoute.value) {
        return;
      }

      currentRoute.value = nextRoute;
    });
  }
}

class AppShellNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _queueRouteSync(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _queueRouteSync(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _queueRouteSync(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _queueRouteSync(newRoute);
  }

  void _queueRouteSync(Route<dynamic>? route) {
    if (!Get.isRegistered<AppShellController>()) {
      return;
    }

    final String? routeName = _extractRouteName(route);
    if (routeName == null) {
      return;
    }

    Get.find<AppShellController>().queueRouteSync(routeName);
  }
}

String? _extractRouteName(Route<dynamic>? route) {
  final String settingsName = route?.settings.name?.trim() ?? '';
  if (settingsName.isNotEmpty) {
    return settingsName;
  }

  if (route is GetPageRoute<dynamic>) {
    final String routeName = route.routeName?.trim() ?? '';
    if (routeName.isNotEmpty) {
      return routeName;
    }
  }

  return null;
}
