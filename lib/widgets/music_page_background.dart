import 'package:flutter/material.dart';

class MusicPageBackground extends StatelessWidget {
  const MusicPageBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.baseColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color backgroundColor =
        baseColor ?? Theme.of(context).scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            backgroundColor,
            colors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            colors.tertiary.withValues(alpha: isDark ? 0.10 : 0.06),
            colors.secondary.withValues(alpha: isDark ? 0.14 : 0.08),
            backgroundColor,
          ],
          stops: const <double>[0, 0.20, 0.46, 0.78, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IgnorePointer(
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -90,
                  left: -40,
                  child: _GlowOrb(
                    color: colors.primary.withValues(
                      alpha: isDark ? 0.26 : 0.14,
                    ),
                    size: 230,
                  ),
                ),
                Positioned(
                  top: 120,
                  right: -70,
                  child: _GlowOrb(
                    color: colors.secondary.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    size: 210,
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: 50,
                  child: _GlowOrb(
                    color: colors.tertiary.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    size: 220,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color, blurRadius: 120, spreadRadius: 18),
        ],
      ),
    );
  }
}
