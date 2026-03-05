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
    final max = total.inMilliseconds <= 0
        ? 1.0
        : total.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

    return Column(
      children: <Widget>[
        Slider(
          min: 0,
          max: max,
          value: value,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        Row(
          children: <Widget>[
            Text(
              position.toClock(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Spacer(),
            Text(
              total.toClock(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }
}
