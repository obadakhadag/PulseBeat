import 'package:get/get.dart';

import '../core/bindings/app_bindings.dart';
import '../pages/chat_page.dart';
import '../pages/follow_requests_page.dart';
import '../pages/main_tabs_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import '../pages/user_profile_page.dart';
import '../views/auth/login_screen.dart';
import '../views/player/player_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/splash/splash_screen.dart';
import '../widgets/online_only_gate.dart';

class AppPages {
  const AppPages._();

  static const Duration _pageTransitionDuration = Duration(milliseconds: 260);

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String player = '/player';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String userProfile = '/userProfile';
  static const String chat = '/chat';
  static const String chatList = '/chatList';
  static const String followRequests = '/followRequests';
  static const String dashboard = '/dashboard';
  static const String collection = dashboard;
  static const String search = '/search';
  static const String favoriteSongs = '/favoriteSongs';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(name: login, page: () => const LoginScreen()),
    GetPage<dynamic>(
      name: home,
      page: () => const MainTabsPage(initialRoute: home),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: player,
      page: () => const PlayerScreen(),
      transition: Transition.downToUp,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: profile,
      page: () => const OnlineOnlyGate(
        title: 'Profile is unavailable offline',
        message: 'Sign in to view and edit your account profile.',
        child: ProfilePage(),
      ),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: userProfile,
      page: () => const OnlineOnlyGate(
        title: 'Profiles are unavailable offline',
        message: 'Sign in to compare libraries and open other user profiles.',
        child: UserProfilePage(),
      ),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: chat,
      page: () => const OnlineOnlyGate(
        title: 'Chat is unavailable offline',
        message: 'Sign in to open direct messages and social sharing.',
        child: ChatPage(),
      ),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: chatList,
      page: () => const OnlineOnlyGate(
        title: 'Chats are unavailable offline',
        message: 'Sign in to see your conversations and message other users.',
        child: MainTabsPage(initialRoute: chatList),
      ),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: followRequests,
      page: () => const OnlineOnlyGate(
        title: 'Follow requests are unavailable offline',
        message: 'Sign in to manage followers and social activity.',
        child: FollowRequestsPage(),
      ),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: dashboard,
      page: () => const MainTabsPage(initialRoute: dashboard),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: search,
      page: () => const OnlineOnlyGate(
        title: 'People search is unavailable offline',
        message: 'Sign in to search for users and open their profiles.',
        child: SearchPage(),
      ),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: favoriteSongs,
      page: () => const MainTabsPage(initialRoute: favoriteSongs),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
  ];
}
