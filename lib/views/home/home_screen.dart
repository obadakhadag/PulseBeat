import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/main_section_scaffold.dart';
import '../../widgets/music_page_background.dart';
import 'widgets/home_category_tabs_section.dart';
import 'widgets/home_floating_nav_bar.dart';
import 'widgets/home_header_section.dart';
import 'widgets/home_now_playing_section.dart';
import 'widgets/home_primary_content_section.dart';
import 'widgets/home_search_section.dart';
import 'widgets/sort_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final PlayerController playerController = Get.find<PlayerController>();

  @override
  void initState() {
    super.initState();
    controller.setSection(HomeSection.all);
  }

  Future<void> _openSortSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SortBottomSheet(),
    );
  }

  Future<void> _refreshLibrary() async {
    await controller.loadLibrary(forceRefresh: true);
    controller.showRefreshedToast();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final double contentBottomInset = MainSectionScaffold.bodyBottomInset();
      final double fabBottom =
          kMainSectionFloatingNavBottom + kMainSectionFloatingNavHeight + 20;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: MusicPageBackground(
          child: Stack(
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: _refreshLibrary,
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    cacheExtent: 900,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      const SliverToBoxAdapter(child: HomeHeaderSection()),
                      SliverToBoxAdapter(
                        child: HomeSearchSection(
                          onChanged: controller.updateSearch,
                          onOpenSort: _openSortSheet,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: HomeCategoryTabsSection(controller: controller),
                      ),
                      SliverToBoxAdapter(
                        child: HomeNowPlayingSection(
                          controller: controller,
                          playerController: playerController,
                        ),
                      ),
                      HomePrimaryContentSection(controller: controller),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: contentBottomInset),
                        sliver: const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: kMainSectionFloatingInset,
                right: kMainSectionFloatingInset,
                bottom: kMainSectionFloatingNavBottom,
                child: HomeFloatingNavBar(),
              ),
            ],
          ),
        ),
        floatingActionButton: controller.showScrollToTop.value
            ? Padding(
                padding: EdgeInsets.only(bottom: fabBottom),
                child: FloatingActionButton.small(
                  onPressed: controller.scrollToTop,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    });
  }
}
