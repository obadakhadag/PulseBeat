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
            trackHeight: 5,
            activeTrackColor: Theme.of(context).colorScheme.onSurface,
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.18),
            thumbColor: Theme.of(context).colorScheme.secondary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.14),
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
            const Spacer(),
            Text(
              total.toClock(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
