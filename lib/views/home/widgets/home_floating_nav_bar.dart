import 'package:flutter/material.dart';

import '../../../routes/app_pages.dart';
import '../../../widgets/floating_music_nav_bar.dart';
import '../../../widgets/main_section_scaffold.dart';

class HomeFloatingNavBar extends StatelessWidget {
  const HomeFloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: kMainSectionFloatingNavHeight,
      child: FloatingMusicNavBar(currentRoute: AppPages.home),
    );
  }
}
