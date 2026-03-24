import 'package:flutter/material.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.isLoading,
    required this.lyrics,
    this.scrollController,
  });

  final bool isLoading;
  final String lyrics;
  final ScrollController? scrollController;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  int _activeLineIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeLineIndex = _firstVisibleLineIndex(widget.lyrics);
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _activeLineIndex = _firstVisibleLineIndex(widget.lyrics);
    }
  }

  int _firstVisibleLineIndex(String value) {
    final List<String> lines = value.split('\n');
    final int index = lines.indexWhere((String line) => line.trim().isNotEmpty);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> lines = widget.lyrics.split('\n');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              key: ValueKey<String>(widget.lyrics),
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              itemCount: lines.length,
              itemBuilder: (BuildContext context, int index) {
                final String line = lines[index].trim();
                if (line.isEmpty) {
                  return const SizedBox(height: 18);
                }

                final bool isActive = index == _activeLineIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _activeLineIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          line,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                height: 1.7,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.92),
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
