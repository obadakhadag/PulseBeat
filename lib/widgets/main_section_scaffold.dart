import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/player_controller.dart';
import '../routes/app_pages.dart';
import 'floating_music_nav_bar.dart';
import 'music_page_background.dart';

const double kMainSectionFloatingNavHeight = 76;
const double kMainSectionFloatingNavBottom = 20;
const double kMainSectionFloatingInset = 16;

class MainSectionScaffold extends StatelessWidget {
  const MainSectionScaffold({
    super.key,
    required this.currentRoute,
    required this.body,
    this.baseColor,
    this.overlays = const <Widget>[],
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final String currentRoute;
  final Widget body;
  final Color? baseColor;
  final List<Widget> overlays;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  static double bodyBottomInset({bool withMiniPlayer = false}) {
    final bool showMiniPlayer =
        withMiniPlayer &&
        Get.isRegistered<PlayerController>() &&
        Get.find<PlayerController>().currentSong.value != null;

    return withMiniPlayer
        ? (showMiniPlayer
              ? kMainSectionFloatingNavBottom +
                    kMainSectionFloatingNavHeight +
                    88 +
                    36
              : kMainSectionFloatingNavBottom +
                    kMainSectionFloatingNavHeight +
                    28)
        : kMainSectionFloatingNavBottom + kMainSectionFloatingNavHeight + 28;
  }

  bool get _showNav {
    return currentRoute == AppPages.home ||
        currentRoute == AppPages.favoriteSongs ||
        currentRoute == AppPages.dashboard ||
        currentRoute == AppPages.chatList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baseColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: MusicPageBackground(
        baseColor: baseColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            body,
            ...overlays,
            if (_showNav)
              Positioned(
                left: kMainSectionFloatingInset,
                right: kMainSectionFloatingInset,
                bottom: kMainSectionFloatingNavBottom,
                child: SizedBox(
                  height: kMainSectionFloatingNavHeight,
                  child: FloatingMusicNavBar(currentRoute: currentRoute),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
