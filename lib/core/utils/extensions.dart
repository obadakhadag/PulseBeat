import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension DurationFormatting on Duration {
  String toClock() {
    final totalSeconds = inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    if (inHours > 0) {
      final hours = inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

extension BuildContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}

extension StringFormatting on String {
  String get fallbackArtist =>
      trim().isEmpty || this == '<unknown>' ? 'Unknown Artist'.tr : this;

  String ellipsis([int limit = 36]) {
    if (length <= limit) {
      return this;
    }
    return '${substring(0, limit - 1)}...';
  }
}
