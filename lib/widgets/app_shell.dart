import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/app_shell_controller.dart';
import '../controllers/player_controller.dart';
import '../data/models/song_model.dart';
import '../routes/app_pages.dart';
import 'global_mini_player.dart';
import 'main_section_scaffold.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AppShellBackHandler(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: child),
          const _GlobalMiniPlayerOverlay(),
        ],
      ),
    );
  }
}

class _AppShellBackHandler extends StatelessWidget {
  const _AppShellBackHandler({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        final NavigatorState? navigator = Get.key.currentState;
        final bool handledByNavigator = await navigator?.maybePop() ?? false;
        if (handledByNavigator) {
          return;
        }

        final bool shouldExit = await _showExitDialog();
        if (!shouldExit) {
          return;
        }

        await SystemNavigator.pop();
      },
      child: child,
    );
  }

  Future<bool> _showExitDialog() async {
    final BuildContext? dialogHostContext = Get.overlayContext ?? Get.context;
    if (dialogHostContext == null) {
      return false;
    }

    final bool? shouldExit = await showDialog<bool>(
      context: dialogHostContext,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        final ColorScheme colors = theme.colorScheme;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      colors.primary,
                      colors.tertiary,
                      colors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: colors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Exit App',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to exit?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.72),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }
}

class _GlobalMiniPlayerOverlay extends StatelessWidget {
  const _GlobalMiniPlayerOverlay();

  @override
  Widget build(BuildContext context) {
    final AppShellController shellController = Get.find<AppShellController>();
    final PlayerController playerController = Get.find<PlayerController>();

    return Obx(() {
      final SongModel? currentSong = playerController.currentSong.value;
      final String currentRoute = shellController.currentRoute.value;

      if (currentSong == null || !_shouldShowMiniPlayer(currentRoute)) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 16,
        right: 16,
        bottom: _miniPlayerBottomInset(context, currentRoute),
        child: GlobalMiniPlayer(
          song: currentSong,
          controller: playerController,
          onOpen: () => Get.toNamed(AppPages.player),
        ),
      );
    });
  }
}

bool _shouldShowMiniPlayer(String route) {
  return route != AppPages.player &&
      route != AppPages.login &&
      route != AppPages.splash;
}

double _miniPlayerBottomInset(BuildContext context, String route) {
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  if (mediaQuery.viewInsets.bottom > 0) {
    return mediaQuery.viewInsets.bottom + 16;
  }

  if (_isMainSectionRoute(route)) {
    return kMainSectionFloatingNavBottom + kMainSectionFloatingNavHeight + 16;
  }

  if (route == AppPages.chat) {
    return math.max(104, mediaQuery.viewPadding.bottom + 88);
  }

  return math.max(16, mediaQuery.viewPadding.bottom + 12);
}

bool _isMainSectionRoute(String route) {
  return route == AppPages.home ||
      route == AppPages.favoriteSongs ||
      route == AppPages.dashboard ||
      route == AppPages.chatList;
}
