import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/app_shell_controller.dart';
import '../routes/app_pages.dart';
import '../views/home/home_screen.dart';
import '../widgets/floating_music_nav_bar.dart';
import '../widgets/main_section_scaffold.dart';
import 'chat_list_page.dart';
import 'dashboard_page.dart';
import 'favorite_songs_page.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  final AppController _appController = Get.find<AppController>();
  final HomeController _homeController = Get.find<HomeController>();
  final AppShellController _shellController = Get.find<AppShellController>();
  late final PageController _pageController;
  late final Worker _appModeWorker;
  late final Map<String, Widget> _tabPages;

  late String _currentRoute;

  List<String> get _availableRoutes => <String>[
    AppPages.home,
    AppPages.favoriteSongs,
    AppPages.dashboard,
    if (_appController.isOnline) AppPages.chatList,
  ];

  int get _currentPageIndex => _routeIndexFor(_currentRoute);

  @override
  void initState() {
    super.initState();
    _tabPages = <String, Widget>{
      AppPages.home: const HomeScreen(showBottomNav: false),
      AppPages.favoriteSongs: const FavoriteSongsPage(showBottomNav: false),
      AppPages.dashboard: const DashboardPage(showBottomNav: false),
      AppPages.chatList: const ChatListPage(showBottomNav: false),
    };
    _currentRoute = _resolveInitialRoute();
    _pageController = PageController(initialPage: _currentPageIndex);
    _shellController.syncMainSectionRouteAfterBuild(_currentRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _homeController.ensureInitialLibraryLoad();
    });
    _appModeWorker = ever(_appController.appMode, (_) {
      _handleTabAvailabilityChange();
    });
  }

  String _resolveInitialRoute() {
    final List<String> routes = _availableRoutes;
    final String normalizedRoute = normalizeAppRoute(widget.initialRoute);
    if (routes.contains(normalizedRoute)) {
      return normalizedRoute;
    }

    return routes.first;
  }

  int _routeIndexFor(String route) {
    final int routeIndex = _availableRoutes.indexOf(route);
    return routeIndex < 0 ? 0 : routeIndex;
  }

  void _handleTabAvailabilityChange() {
    final List<String> routes = _availableRoutes;
    final String nextRoute = routes.contains(_currentRoute)
        ? _currentRoute
        : routes.last;
    final int nextIndex = _routeIndexFor(nextRoute);

    if (mounted) {
      setState(() {
        _currentRoute = nextRoute;
      });
    } else {
      _currentRoute = nextRoute;
    }
    _shellController.setMainSectionRoute(nextRoute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final int currentIndex = (_pageController.page ?? _currentPageIndex)
          .round();
      if (currentIndex != nextIndex) {
        _pageController.jumpToPage(nextIndex);
      }
    });
  }

  Future<void> _handleRouteSelected(String route) async {
    final List<String> routes = _availableRoutes;
    if (!routes.contains(route) || route == _currentRoute) {
      return;
    }

    final int nextIndex = _routeIndexFor(route);
    setState(() {
      _currentRoute = route;
    });
    _shellController.setMainSectionRoute(route);

    if (!_pageController.hasClients) {
      return;
    }

    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    final List<String> routes = _availableRoutes;
    if (index < 0 || index >= routes.length) {
      return;
    }

    final String nextRoute = routes[index];
    if (nextRoute == _currentRoute) {
      return;
    }

    setState(() {
      _currentRoute = nextRoute;
    });
    _shellController.setMainSectionRoute(nextRoute);
  }

  @override
  void dispose() {
    _appModeWorker.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> routes = _availableRoutes;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView(
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          children: routes
              .map(
                (String route) => _KeepAliveTabPage(
                  key: PageStorageKey<String>('main-tab-$route'),
                  child: _tabPages[route]!,
                ),
              )
              .toList(growable: false),
        ),
        Positioned(
          left: kMainSectionFloatingInset,
          right: kMainSectionFloatingInset,
          bottom: kMainSectionFloatingNavBottom,
          child: SizedBox(
            height: kMainSectionFloatingNavHeight,
            child: FloatingMusicNavBar(
              currentRoute: _currentRoute,
              onRouteSelected: _handleRouteSelected,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepAliveTabPage extends StatefulWidget {
  const _KeepAliveTabPage({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin<_KeepAliveTabPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
