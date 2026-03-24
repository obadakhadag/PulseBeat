import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeSearchSection extends StatelessWidget {
  const HomeSearchSection({
    super.key,
    required this.onChanged,
    required this.onOpenSort,
  });

  final ValueChanged<String> onChanged;
  final Future<void> Function() onOpenSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search songs, artists, albums'.tr,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: onOpenSort,
            icon: const Icon(Icons.tune_rounded),
          ),
          fillColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
