import 'package:get/get.dart';

import '../pages/chat_list_page.dart';
import '../core/bindings/app_bindings.dart';
import '../pages/chat_page.dart';
import '../pages/collection_page.dart';
import '../pages/favorite_songs_page.dart';
import '../pages/follow_requests_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import '../pages/user_profile_page.dart';
import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';
import '../views/player/player_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/splash/splash_screen.dart';

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
  static const String collection = '/collection';
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
      page: () => const HomeScreen(),
      binding: HomeBinding(),
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
      page: () => const ProfilePage(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: userProfile,
      page: () => const UserProfilePage(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: chat,
      page: () => const ChatPage(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: chatList,
      page: () => const ChatListPage(),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: followRequests,
      page: () => const FollowRequestsPage(),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: collection,
      page: () => const CollectionPage(),
      binding: HomeBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: search,
      page: () => const SearchPage(),
      transition: Transition.fadeIn,
      transitionDuration: _pageTransitionDuration,
    ),
    GetPage<dynamic>(
      name: favoriteSongs,
      page: () => const FavoriteSongsPage(),
      binding: HomeBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _pageTransitionDuration,
    ),
  ];
}
