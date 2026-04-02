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

const Duration _miniPlayerSlideDuration = Duration(milliseconds: 250);
const Duration _miniPlayerFadeDuration = Duration(milliseconds: 200);
const Duration _exitConfirmationWindow = Duration(seconds: 2);

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

class _AppShellBackHandler extends StatefulWidget {
  const _AppShellBackHandler({required this.child});

  final Widget child;

  @override
  State<_AppShellBackHandler> createState() => _AppShellBackHandlerState();
}

class _AppShellBackHandlerState extends State<_AppShellBackHandler> {
  DateTime? _lastBackPressedAt;
  String? _lastBackPromptRoute;
  bool _isExitDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: widget.child,
    );
  }

  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      _clearExitPromptState();
      return;
    }

    final NavigatorState? navigator = Get.key.currentState;
    final bool handledByNavigator = await navigator?.maybePop() ?? false;
    if (handledByNavigator) {
      _clearExitPromptState();
      return;
    }

    final DateTime now = DateTime.now();
    final String currentRoute = _resolveCurrentRouteName();
    final DateTime? lastBackPressedAt = _lastBackPressedAt;
    final bool shouldShowExitDialog =
        lastBackPressedAt != null &&
        _lastBackPromptRoute == currentRoute &&
        now.difference(lastBackPressedAt) <= _exitConfirmationWindow;

    if (!shouldShowExitDialog) {
      _lastBackPressedAt = now;
      _lastBackPromptRoute = currentRoute;
      _showExitPromptSnackBar();
      return;
    }

    if (_isExitDialogVisible) {
      return;
    }

    _isExitDialogVisible = true;
    final bool shouldExit = await _showExitDialog();
    _isExitDialogVisible = false;
    _clearExitPromptState();

    if (!shouldExit) {
      return;
    }

    await SystemNavigator.pop();
  }

  void _clearExitPromptState() {
    _lastBackPressedAt = null;
    _lastBackPromptRoute = null;
  }

  String _resolveCurrentRouteName() {
    if (Get.isRegistered<AppShellController>()) {
      return normalizeAppRoute(
        Get.find<AppShellController>().currentRoute.value,
      );
    }

    return normalizeAppRoute(Get.currentRoute);
  }

  void _showExitPromptSnackBar() {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) {
      Get.rawSnackbar(
        message: 'Press again to exit'.tr,
        duration: _exitConfirmationWindow,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: _exitConfirmationWindow,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            _exitSnackBarBottomInset(context),
          ),
          elevation: 0,
          backgroundColor: colors.inverseSurface.withValues(alpha: 0.94),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Text(
            'Press again to exit'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onInverseSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                  'Exit App'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to exit?'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.72),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Exit'.tr),
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
      final bool shouldShowMiniPlayer =
          currentSong != null &&
          shouldShowGlobalMiniPlayerOnRoute(currentRoute);

      if (currentSong == null) {
        return const SizedBox.shrink();
      }

      return AnimatedPositioned(
        duration: _miniPlayerSlideDuration,
        curve: Curves.easeOutCubic,
        left: 16,
        right: 16,
        bottom: _miniPlayerBottomInset(context, currentRoute),
        child: IgnorePointer(
          ignoring: !shouldShowMiniPlayer,
          child: AnimatedSlide(
            duration: _miniPlayerSlideDuration,
            curve: Curves.easeOutCubic,
            offset: shouldShowMiniPlayer ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: _miniPlayerFadeDuration,
              curve: Curves.easeOut,
              opacity: shouldShowMiniPlayer ? 1 : 0,
              child: GlobalMiniPlayer(
                song: currentSong,
                controller: playerController,
                onOpen: () => Get.toNamed(AppPages.player),
              ),
            ),
          ),
        ),
      );
    });
  }
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

double _exitSnackBarBottomInset(BuildContext context) {
  final String route = Get.isRegistered<AppShellController>()
      ? normalizeAppRoute(Get.find<AppShellController>().currentRoute.value)
      : normalizeAppRoute(Get.currentRoute);

  final bool hasVisibleMiniPlayer =
      Get.isRegistered<PlayerController>() &&
      Get.find<PlayerController>().currentSong.value != null &&
      shouldShowGlobalMiniPlayerOnRoute(route);

  if (hasVisibleMiniPlayer) {
    return _miniPlayerBottomInset(context, route) +
        kGlobalMiniPlayerHeight +
        12;
  }

  if (_isMainSectionRoute(route)) {
    return kMainSectionFloatingNavBottom + kMainSectionFloatingNavHeight + 16;
  }

  return math.max(24, MediaQuery.of(context).viewPadding.bottom + 20);
}

bool _isMainSectionRoute(String route) {
  return route == AppPages.home ||
      route == AppPages.favoriteSongs ||
      route == AppPages.dashboard ||
      route == AppPages.chatList;
}
