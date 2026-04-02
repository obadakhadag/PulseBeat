import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../routes/app_pages.dart';

class FloatingMusicNavBar extends StatelessWidget {
  const FloatingMusicNavBar({
    super.key,
    required this.currentRoute,
    this.onRouteSelected,
  });

  final String currentRoute;
  final ValueChanged<String>? onRouteSelected;

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find<AppController>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? const Color(0xFF1A1A1A)
        : colors.surface.withValues(alpha: 0.94);
    final Color inactiveColor = colors.onSurface.withValues(alpha: 0.62);
    return Obx(() {
      final List<_NavItem> items = <_NavItem>[
        const _NavItem(
          route: AppPages.home,
          icon: Icons.home_rounded,
          label: 'Home',
        ),
        const _NavItem(
          route: AppPages.favoriteSongs,
          icon: Icons.favorite_rounded,
          label: 'Favorites',
        ),
        const _NavItem(
          route: AppPages.dashboard,
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        if (appController.isOnline)
          const _NavItem(
            route: AppPages.chatList,
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
          ),
      ];

      return SizedBox(
        height: 76,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: items
                  .map((_NavItem item) {
                    final bool isSelected = item.route == currentRoute;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: <Color>[
                                      colors.secondary,
                                      colors.tertiary,
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : colors.onSurface.withValues(
                                    alpha: isDark ? 0.02 : 0.04,
                                  ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                if (item.route == currentRoute) {
                                  return;
                                }
                                if (onRouteSelected != null) {
                                  onRouteSelected!(item.route);
                                  return;
                                }
                                Get.offNamed<dynamic>(item.route);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      item.icon,
                                      color: isSelected
                                          ? colors.onPrimary
                                          : inactiveColor,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.label.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: isSelected
                                                ? colors.onPrimary
                                                : inactiveColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.5,
                                            height: 1,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final String label;
}
