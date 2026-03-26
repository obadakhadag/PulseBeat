import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';

class FloatingMusicNavBar extends StatelessWidget {
  const FloatingMusicNavBar({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? const Color(0xFF1A1A1A)
        : colors.surface.withValues(alpha: 0.94);
    final Color inactiveColor = colors.onSurface.withValues(alpha: 0.62);
    final List<_NavItem> items = const <_NavItem>[
      _NavItem(route: AppPages.home, icon: Icons.home_rounded, label: 'Home'),
      _NavItem(
        route: AppPages.favoriteSongs,
        icon: Icons.favorite_rounded,
        label: 'Favorites',
      ),
      _NavItem(
        route: AppPages.dashboard,
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _NavItem(
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          if (item.route == currentRoute) {
                            return;
                          }
                          Get.offNamed<dynamic>(item.route);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? colors.onPrimary
                                    : inactiveColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label.tr,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? colors.onPrimary
                                      : inactiveColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
