import 'package:get/get.dart';

import '../pages/chat_page.dart';
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

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/';
  static const String player = '/player';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String userProfile = '/userProfile';
  static const String chat = '/chat';
  static const String search = '/search';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(name: splash, page: () => const SplashScreen()),
    GetPage<dynamic>(name: login, page: () => const LoginScreen()),
    GetPage<dynamic>(name: home, page: () => const HomeScreen()),
    GetPage<dynamic>(name: player, page: () => const PlayerScreen()),
    GetPage<dynamic>(name: settings, page: () => const SettingsScreen()),
    GetPage<dynamic>(name: profile, page: () => const ProfilePage()),
    GetPage<dynamic>(name: userProfile, page: () => const UserProfilePage()),
    GetPage<dynamic>(name: chat, page: () => const ChatPage()),
    GetPage<dynamic>(name: search, page: () => const SearchPage()),
  ];
}
