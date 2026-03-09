import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_pages.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final playerController = Get.find<PlayerController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _Panel(
              title: 'Appearance',
              child: Column(
                children: <Widget>[
                  SegmentedButton<ThemeMode>(
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                    ],
                    selected: <ThemeMode>{controller.themeMode.value},
                    onSelectionChanged: (Set<ThemeMode> selection) =>
                        controller.setThemeMode(selection.first),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Immersive player'),
                    subtitle: const Text(
                      'Use stronger artwork-driven background styling.',
                    ),
                    value: controller.immersivePlayer.value,
                    onChanged: controller.setImmersivePlayer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Playback',
              child: Column(
                children: <Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show lyrics'),
                    subtitle: const Text(
                      'Load lyrics when a song becomes active.',
                    ),
                    value: controller.showLyrics.value,
                    onChanged: (bool value) {
                      controller.setShowLyrics(value);
                      playerController.setShowLyrics(value);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Refresh library'),
                    subtitle: const Text(
                      'Rescan device storage for audio files.',
                    ),
                    trailing: const Icon(Icons.refresh_rounded),
                    onTap: () async {
                      await homeController.loadLibrary(forceRefresh: true);
                      homeController.showRefreshedToast();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Account',
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open profile'),
                    subtitle: const Text('View your Firebase profile details.'),
                    trailing: const Icon(Icons.person_rounded),
                    onTap: () => Get.toNamed(AppPages.profile),
                  ),
                  Obx(() {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Logout'),
                      subtitle: const Text('Sign out from your account.'),
                      trailing: authController.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      enabled: !authController.isLoading.value,
                      onTap: authController.isLoading.value
                          ? null
                          : authController.logout,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'About',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'PulseBeat is designed around your local library with a stronger visual language than a stock file-list player.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Songs loaded: ${homeController.songs.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
