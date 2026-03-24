import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../themes/app_theme.dart';

class AppHelpers {
  const AppHelpers._();

  static LinearGradient songGradient({
    required int seed,
    required Brightness brightness,
  }) {
    final random = Random(seed);
    final hueA = random.nextDouble() * 360;
    final hueB = (hueA + 55 + random.nextDouble() * 70) % 360;
    final saturation = brightness == Brightness.dark ? 0.70 : 0.78;
    final lightnessA = brightness == Brightness.dark ? 0.38 : 0.70;
    final lightnessB = brightness == Brightness.dark ? 0.28 : 0.58;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        HSLColor.fromAHSL(1, hueA, saturation, lightnessA).toColor(),
        HSLColor.fromAHSL(1, hueB, saturation, lightnessB).toColor(),
      ],
    );
  }

  static List<BoxShadow> glowShadows(BuildContext context) {
    final surfaces = Theme.of(context).extension<AppSurfaces>();
    final primary =
        surfaces?.primaryGlow ?? Theme.of(context).colorScheme.primary;
    return <BoxShadow>[
      BoxShadow(
        color: primary.withValues(alpha: 0.16),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }

  static void showToast(String message) {
    Get.snackbar(
      'PulseBeat',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}
