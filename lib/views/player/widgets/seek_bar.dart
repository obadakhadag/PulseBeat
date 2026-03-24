import 'package:flutter/material.dart';

import '../../../core/utils/extensions.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.total,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Duration position;
  final Duration total;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final double max = total.inMilliseconds <= 0
        ? 1
        : total.inMilliseconds.toDouble();
    final double value = position.inMilliseconds
        .clamp(0, max.toInt())
        .toDouble();

    return Column(
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: theme.colorScheme.secondary,
            inactiveTrackColor: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.18 : 0.12,
            ),
            thumbColor: isDark ? Colors.white : theme.colorScheme.secondary,
            overlayColor: theme.colorScheme.secondary.withValues(alpha: 0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            min: 0,
            max: max,
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Row(
          children: <Widget>[
            Text(
              position.toClock(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isDark ? 0.74 : 0.68,
                ),
              ),
            ),
            const Spacer(),
            Text(
              total.toClock(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isDark ? 0.74 : 0.68,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
