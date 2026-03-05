import 'package:flutter/material.dart';

class LyricsView extends StatelessWidget {
  const LyricsView({super.key, required this.isLoading, required this.lyrics});

  final bool isLoading;
  final String lyrics;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              key: ValueKey<String>(lyrics),
              physics: const BouncingScrollPhysics(),
              child: Text(
                lyrics,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
            ),
    );
  }
}
