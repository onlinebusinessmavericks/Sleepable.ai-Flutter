import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:sleepable_ai/modules/sleep_sound/widget/MixBarWidget.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/cached_image_widget.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../music/views/music_view.dart';
import '../controllers/sleep_sound_controller.dart';
import '../model/sound_sub_category_model.dart';
import '../model/sounds_mixed_list_model.dart';
import '../widget/MixCard.dart';
import '../widget/PlayerFullSheetUI.dart';

class SleepSoundView extends StatefulWidget {
  final bool fromMixBar;

  const SleepSoundView({Key? key, this.fromMixBar = false}) : super(key: key);

  @override
  State<SleepSoundView> createState() => _SleepSoundViewState();
}

class _SleepSoundViewState extends State<SleepSoundView> {
  final controller = Get.find<SleepSoundController>();
  final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());


  late final PageController pageController;
  final ScrollController chipScrollController = ScrollController();
  final ScrollController tabScrollController = ScrollController(); // ✅ new
  final Map<String, GlobalKey> tabKeys = {};

  late final bool isFromMixBar;

  @override
  void initState() {
    super.initState();
    final pageCount = controller.combinedPages.length;

    final initialIndex = pageCount == 0 ? 0 : controller.globalIndexFor(controller.selectedCategorySlug.value, controller.selectedSubCategorySlug.value).clamp(0, pageCount - 1);

    pageController = PageController(initialPage: initialIndex);
    for (var tab in controller.tabOrder) {
      tabKeys[tab.slug] = GlobalKey();
    }

    ever(controller.selectedCategorySlug, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerActiveTab();
      });
    });
    ever(controller.selectedSubCategorySlug, (_) => _centerActiveChip());
    // Jump to Music when "Add Music" is pressed from the mix sheet
    ever(controller.musicNavRequest, (_) async {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.fetchSubCategories("music");
        final filters = controller.getCurrentFilters("music");
        final firstFilterSlug = filters.isNotEmpty ? filters.first.slug : SleepSoundController.allSubSlug;
        if (firstFilterSlug != SleepSoundController.allSubSlug) {
          controller.selectedSubCategorySlug.value = firstFilterSlug;
        }
        jumpToTab("music", filter: firstFilterSlug);
      });
    });
    // ever(controller.selectedCategorySlug, (_) => _centerActiveTab());
    final args = Get.arguments as Map<String, dynamic>?;

    isFromMixBar = widget.fromMixBar; // ✅ ALWAYS reliable

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (args?["jumpTab"] != null) {
        _waitAndJump(args!["jumpTab"], args["jumpFilter"]);
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    chipScrollController.dispose();
    tabScrollController.dispose();
    super.dispose();
  }

  void jumpToTab(String tab, {String? filter}) {
    if (!pageController.hasClients) return;

    final index = controller.combinedPages.indexWhere((page) {
      final matchesTab = page["categorySlug"] == tab;
      if (filter == null) return matchesTab;
      return matchesTab && page["subCategorySlug"] == filter;
    });

    // if (index != -1) {
    //   pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    // }
    if (index != -1 && pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _waitAndJump(String tab, String? filter) {
    if (controller.combinedPages.isEmpty || !pageController.hasClients) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _waitAndJump(tab, filter);
      });

      return;
    }

    jumpToTab(tab, filter: filter); // ✅ FIXED
  }

  void _centerActiveTab() {
    if (!tabScrollController.hasClients) return;

    final selectedTab = controller.selectedCategorySlug.value;
    final key = tabKeys[selectedTab];

    if (key == null || key.currentContext == null) return;

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final scrollableBox = tabScrollController.position.context.storageContext.findRenderObject() as RenderBox;

    final tabPosition = box.localToGlobal(Offset.zero, ancestor: scrollableBox);

    final tabWidth = box.size.width;
    final screenWidth = MediaQuery.of(context).size.width;

    final scrollOffset = tabScrollController.offset + tabPosition.dx - (screenWidth / 2) + (tabWidth / 2);

    if (tabScrollController.hasClients) {
      // Now it is safe to access .position and .animateTo
      final double min = tabScrollController.position.minScrollExtent;
      final double max = tabScrollController.position.maxScrollExtent;

      tabScrollController.animateTo(
        scrollOffset.clamp(min, max),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _centerActiveChip() {
    if (!chipScrollController.hasClients) return;

    final categorySlug = controller.selectedCategorySlug.value;

    // ✅ MUST be List<SoundSubCategory>
    final List<SoundSubCategory> filters = controller.getCurrentFilters(categorySlug);

    if (filters.isEmpty) return;

    final selectedSubSlug = controller.selectedSubCategorySlug.value;

    final selectedIndex = filters.indexWhere((sub) => sub.slug == selectedSubSlug);

    if (selectedIndex < 0) return;

    // --- Step 1: Measure text width ---
    final label = filters[selectedIndex];
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w100);

    final textPainter = TextPainter(
      text: TextSpan(text: label.name, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;

    // --- Step 2: Chip size ---
    const horizontalPadding = 22.0;
    const horizontalMargin = 12.0;
    final chipWidth = textWidth + horizontalPadding + horizontalMargin;

    // --- Step 3: Width before selected chip ---
    double totalBefore = 0;
    for (int i = 0; i < selectedIndex; i++) {
      final prev = filters[i];

      final tp = TextPainter(
        text: TextSpan(text: prev.name, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      totalBefore += tp.width + horizontalPadding + horizontalMargin;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = totalBefore - (screenWidth / 2) + (chipWidth / 2);

    final maxExtent = chipScrollController.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0, maxExtent).toDouble();


// 2. Wrap the animation in the safety check
    if (chipScrollController.hasClients) {
      chipScrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void scrollToSelectedTab(int index) {
    // Get width of one tab + margin (adjust according to your layout)
    final tabWidth = 80.0; // approx width of each tab container
    final tabMargin = 18.0;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate desired scroll offset to center the tab
    final offset = (tabWidth + tabMargin) * index - (screenWidth / 2) + (tabWidth / 2);

    // 1. Check if the controller is attached to the UI
    if (tabScrollController.hasClients) {

      // 2. Safely calculate the clamp using the active position
      final double safeOffset = offset.clamp(
          tabScrollController.position.minScrollExtent,
          tabScrollController.position.maxScrollExtent
      );

      // 3. Start the animation
      tabScrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🔥 HARD GUARD (still REQUIRED)
      if (controller.combinedPages.isEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFF0C0E1B),
          body: Center(child: LoaderWidget(size: sw(150))),
        );
      }

      final currentIndex = controller.currentPageIndex.value.clamp(0, controller.combinedPages.length - 1);

      final page = controller.combinedPages[currentIndex];
      final currentCategory = page["categorySlug"]!;
      final currentSub = page["subCategorySlug"]!;
      final currentKey = controller.soundKey(
          controller.selectedCategorySlug.value,
          controller.selectedSubCategorySlug.value
      );

      // Check if THIS specific tab is loading
      final isTabLoading = controller.loadingKeys.contains(currentKey);
      // Check if we have data to show
      final hasData = controller.soundsBySubCategory[currentKey]?.isNotEmpty ?? false;
      final isScreenLoading =
          controller.isLoadingCategories.value ||
          controller.isLoadingSubCategories.value ||
          controller.isMixesLoading.value ||
          controller.loadingKeys.contains(controller.soundKey(currentCategory, currentSub));
       print("isFromMixBar ------$isFromMixBar");
      return Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF0C0E1B),
            appBar: AppBar(
              leading: isFromMixBar
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, iconColor: AppColors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
                    )
                  : Padding(padding: const EdgeInsets.all(8.0)),
              backgroundColor: Colors.transparent,
              title: Text(context.lang.sleepSounds, style: TextStyle(color: Colors.white)),
              centerTitle: true,
              elevation: 0,
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Obx(() {
                      final selected = controller.selectedCategorySlug.value;

                      return SingleChildScrollView(
                        controller: tabScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: controller.tabOrder.map((tab) {
                            final isSelected = selected == tab.slug;

                            return GestureDetector(
                              onTap: () async {
                                final tabSlug = tab.slug;

                                if (controller.selectedCategorySlug.value == tabSlug) return;

                                controller.selectedCategorySlug.value = tabSlug;

                                // ✅ fetch ONCE
                                await controller.fetchSubCategories(tabSlug);

                                final filters = controller.getCurrentFilters(tabSlug);
                                if (filters.isEmpty) return;

                                final firstFilterSlug = filters.first.slug;

                                final page = controller.globalIndexFor(tabSlug, firstFilterSlug);
                                  // if (page >= 0) {
                                  //   pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  // }
                                if (page >= 0 && pageController.hasClients) {
                                  pageController.animateToPage(
                                    page,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },

                              child: Container(
                                key: tabKeys[tab.id],
                                margin: const EdgeInsets.only(right: 18),
                                child: Column(
                                  children: [
                                    Text(
                                      tab.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(color: isSelected ? Colors.white : Colors.grey.shade700, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isSelected)
                                      Container(
                                        width: 20,
                                        height: 3,
                                        decoration: BoxDecoration(color: const Color(0xFF3A7CFF), borderRadius: BorderRadius.circular(4)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // ✅ Filter Chips
                    Obx(() {
                      final currentTab = controller.selectedCategorySlug.value;
                      final filters = controller.getCurrentFilters(currentTab);

                      print("currentTab-------- ------${currentTab}");
                      print("filters-------- ------${filters}");
                      // 👇 Add this line - after rebuild due to tab change, center the selected chip
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _centerActiveChip();
                      });
                      return SizedBox(
                        height: 35,
                        child: ListView.builder(
                          // key: ValueKey(currentTab),
                          key: ValueKey("${currentTab}_${Get.locale?.languageCode ?? 'en'}"),
                          controller: chipScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filters.length,
                          itemBuilder: (context, i) {
                            final f = filters[i];

                            return Obx(() {
                              final isSelected = controller.selectedSubCategorySlug.value == f.slug;

                              return GestureDetector(
                                onTap: () {
                                  controller.selectedSubCategorySlug.value = f.slug;

                                  final page = controller.globalIndexFor(currentTab, f.slug);
                                  // if (page >= 0) {
                                  //   pageController.animateToPage(page, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                                  // }
                                  if (page >= 0 && pageController.hasClients) {
                                    pageController.animateToPage(
                                      page,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  }

                                  // ✅ Also fetch sounds immediately
                                  if (!controller.isLoadingSounds.value) {
                                    controller.fetchSounds(currentTab, f.slug);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 11),
                                  decoration: BoxDecoration(color: isSelected ? const Color(0xFF3A7CFF) : const Color(0xFF1C1F2E), borderRadius: BorderRadius.circular(24)),
                                  child: Center(
                                    child: Text(
                                      f.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(color: isSelected ? AppColors.white : Colors.white, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
                                    ),
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: controller.combinedPages.length,
                        onPageChanged: controller.onGlobalPageChanged,
                        itemBuilder: (context, index) {
                          final page = controller.pageAt(index);
                          final categorySlug = page["categorySlug"]!;
                          final subCategorySlug = page["subCategorySlug"]!;

                          return Obx(() {
                            // 1. Get slugs and check tabs
                            final isMixesTab = categorySlug.toLowerCase() == "mixes";
                            final isYourMixes = subCategorySlug.toLowerCase() == "your-mixes";

                            // 2. Trigger fetch if needed
                            final key = controller.soundKey(categorySlug, subCategorySlug);
                            final hasRequested = controller.hasRequested(key);

                            if (!hasRequested) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.fetchSounds(categorySlug, subCategorySlug);
                              });
                            }

                            if (isMixesTab && isYourMixes) {


                          if (controller.apiMixes.isEmpty && !controller.isMixesLoading.value) {
                            return  Center(
                              child: Text(context.lang.noMixesFound, style: TextStyle(color: Colors.white54)),
                            );
                          }

                            final double screenWidth = MediaQuery.of(context).size.width;
                            const double horizontalPadding = 18.0 * 2;
                            const double spacing = 16.0;

                            // Calculate width for 1 of the 2 columns
                            final double itemWidth = (screenWidth - horizontalPadding - spacing) / 2;

                            // We want the Icon Box to be a rectangle slightly taller than it is wide
                            // 1.1 means height is 110% of width. Use 1.0 for a perfect square.
                            final double dynamicBoxHeight = itemWidth * 1.05;

                            // Fixed height for the title/subtitle text area
                            const double textSectionHeight = 55.0;

                            // The magic number that tells GridView how to shape the "bucket"
                            final double responsiveAspectRatio = itemWidth / (dynamicBoxHeight + textSectionHeight + 8);
                            return GridView.builder(
                              padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 150),
                              itemCount: controller.apiMixes.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16, // Space between top and bottom cards
                                crossAxisSpacing: 16, // Space between left and right cards
                                childAspectRatio: responsiveAspectRatio, // Use the calculated ratio
                              ),
                              itemBuilder: (context, i) {
                                final MixedSoundRecord mix = controller.apiMixes[i];
                                final String name = mix.title;
                                final List<String> soundNames = mix.sounds.map((s) => s.name).toList();

                                return GestureDetector(
                                  onTap: () async {
                                    await controller.restoreMixFromApi(mix);
                                    controller.isAnyPlayerVisible.value = true;
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🔹 Card design (The Icon Box)
                                      Container(
                                        height: dynamicBoxHeight,
                                        // Keep this height consistent
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C2130),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.02), Colors.white.withOpacity(0.01)]),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Center(
                                          child: IgnorePointer(
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: mix.sounds.take(4).length,
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                mainAxisSpacing: 8, // Reduced spacing inside the box
                                                crossAxisSpacing: 8,
                                                childAspectRatio: 1.0,
                                              ),
                                              itemBuilder: (context, index) {
                                                final s = mix.sounds[index];
                                                return CircleAvatar(
                                                  backgroundColor: Colors.white.withOpacity(0.08),
                                                  child: (s.emoji != null && s.emoji!.trim().isNotEmpty)
                                                      ? Text(s.emoji!, style: const TextStyle(fontSize: 24))
                                                      : CachedImageWidget(
                                                          url: s.image,
                                                          height: 80, // Responsive image size
                                                          width: 80,
                                                          circle: true,
                                                        ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // 🔹 Title and Menu Row
                                      SizedBox(
                                        height: textSectionHeight - 8, // Ensure text stays in its bounds
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15, // Slightly smaller for smaller screens
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    soundNames.join(", "),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => showMixOptions(context, mix, name),
                                              icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );}
                            final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

                            final sounds = controller.soundsFor(categorySlug, subCategorySlug);
                            if (sounds.isEmpty && !isScreenLoading)
                              return Center(
                                child: Text(context.lang.noSoundsFound, style: TextStyle(color: Colors.white54)),
                              );
                            // // ✅ Check if current tab is Music
                            final isMusicTab = categorySlug.toLowerCase() == "music";
                            final isStoryTab = categorySlug.toLowerCase() == "story";
                            final isFavTab = categorySlug.toLowerCase() == "favorites";
                            if (isMusicTab) {
                              // 🎵 Music UI
                              return GridView.builder(
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 150),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.1),
                                itemCount: sounds.length,
                                itemBuilder: (context, i) {
                                  final s = sounds[i];
                                  return Obx(() {
                                    // final isPlaying = controller.playingMusic.any((m) => m.id == s.id) || controller.playingSounds.any((it) => it.id == s.id);
                                    // final isActive = controller.playingMusic.any((m) => m.id == s.id);
                                    final isMusicPlaying = controller.playingMusic.any((m) => m.id == s.id);

                                    final isActive = isMusicPlaying;
                                    final isFav = s.isFavorite ?? false;
                                    // final isPremium = s.isPremium ?? false;
                                    print("-----isFav-----${s.isFavorite}");
                                    final isActuallyPlaying = isMusicPlaying && !controller.isPaused.value;
                                    return GestureDetector(

                                      onTap: () {
                                        final controller1 = Get.find<HomeController>();
                                        if (s.isPremium == true && subController.isPremium.value == false) {
                                          final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;
                                          if (hasAlreadySpun) {
                                            // showPremiumOfferSheet6(context);
                                            controller1.showRotatingPremiumSheet(context);
                                          } else {
                                            showPremiumOfferSheet4(context);
                                          }
                                          return;
                                        }

                                        final isMusic = s.categoryName.toLowerCase() == "music";
                                        final isAlreadyPlaying = controller.playingMusic.any((m) => m.id == s.id);

                                        if (isMusic) {
                                          // 1. If it's already playing, just toggle pause (Instant)
                                          if (isAlreadyPlaying) {
                                            controller.togglePause();
                                            return;
                                          }

                                          // 2. Open Full Player UI IMMEDIATELY
                                          if (controller.playingSounds.isEmpty) {
                                            if (!controller.isAnyPlayerVisible.value) {
                                              controller.isAnyPlayerVisible.value = true;
                                              Get.bottomSheet(
                                                PlayerFullSheetUI(sound: s),
                                                isScrollControlled: true,
                                                ignoreSafeArea: false,
                                                backgroundColor: Colors.transparent,
                                              ).whenComplete(() {
                                                controller.isAnyPlayerVisible.value = false;
                                              });
                                            }
                                          } else {
                                            if (Get.isBottomSheetOpen ?? false) Get.back();
                                          }

                                          // 3. Fire the Music Logic (Now non-blocking)
                                          controller.toggleMusic(s);
                                        }
                                      },

                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E2131),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: isActive ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: CachedImageWidget(url: s.image, height: double.infinity, width: double.infinity, fit: BoxFit.cover, circle: false, usePlaceholderIfUrlEmpty: true),
                                            ),

                                            // Gradient overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                                                ),
                                              ),
                                            ),

                                            /// Lock Icon - Now based on isLocked from API
                                            // if (isPremium)
                                            // isPremium == false
                                        // (isPremium==false && subController.isPremium.value == true)
                                        //         ? Positioned(
                                        //             top: 10,
                                        //             right: 10,
                                        //             child: GestureDetector(
                                        //               // Inside your GridView.builder for the Heart Icon
                                        //               onTap: () => controller.toggleLike(s, categorySlug, subCategorySlug),
                                        //               child: AnimatedContainer(
                                        //                 duration: const Duration(milliseconds: 300),
                                        //                 padding: const EdgeInsets.all(6),
                                        //                 decoration: BoxDecoration(color: isFav ? Colors.red.withOpacity(0.1) : Colors.black26, shape: BoxShape.circle),
                                        //                 child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 18 * SizeConfigs.textScale),
                                        //               ),
                                        //               // }),
                                        //             ),
                                        //           )
                                        //         : Positioned(top: 12, right: 16, child: Icon(Icons.lock, color: AppColors.white, size: 20)),
// Condition: Agar sound Premium hai AUR user ke paas subscription NAHI hai, toh LOCK dikhao
                                            (s.isPremium == true && subController.isPremium.value == false)
                                                ? Positioned(
                                              top: 12,
                                              right: 16,
                                              child: Icon(Icons.lock, color: AppColors.white, size: 20),
                                            )
                                                : Positioned(
                                              top: 10,
                                              right: 10,
                                              child: GestureDetector(
                                                onTap: () => controller.toggleLike(s, categorySlug, subCategorySlug),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isFav ? Colors.red.withOpacity(0.1) : Colors.black26,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    isFav ? Icons.favorite : Icons.favorite_border,
                                                    color: isFav ? Colors.red : Colors.white,
                                                    size: 18 * SizeConfigs.textScale,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Bottom info (name, duration, play)
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              right: 10,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          s.name,
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(controller.formatDuration(s.duration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 32,
                                                    width: 32,
                                                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                                    child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                                },
                              );
                            }
                            if (isFavTab) {
                              print("\n\n\n----isfavorites------\n\n\n");
                              // 🎵 Music UI
                              return GridView.builder(
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 150),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.1),
                                itemCount: sounds.length,
                                itemBuilder: (context, i) {
                                  final s = sounds[i];
                                  return Obx(() {
                                    // final isPlaying = controller.playingMusic.any((m) => m.id == s.id) || controller.playingSounds.any((it) => it.id == s.id);
                                    // final isActive = controller.playingMusic.any((m) => m.id == s.id);
                                    final isMusicPlaying = controller.playingMusic.any((m) => m.id == s.id);

                                    final isActive = isMusicPlaying;
                                    final isFav = s.isFavorite ?? false;
                                    print("-----isFav-----${s.isFavorite}");
                                    final isActuallyPlaying = isMusicPlaying && !controller.isPaused.value;
                                    return GestureDetector(
                                      onTap: () async {
                                        final isMusic = s.categoryName.toLowerCase() == "music";
                                        final isAlreadyPlaying = controller.playingMusic.any((m) => m.id == s.id);

                                        if (isMusic) {
                                          if (isAlreadyPlaying) {
                                            await controller.togglePause();
                                            return;
                                          }

                                          if (controller.playingSounds.isNotEmpty) {
                                            await controller.toggleMusic(s);
                                            // 🔥 Close the category/selection sheet if open
                                            if (Get.isBottomSheetOpen ?? false) {
                                              print("------------call first back---------");
                                              Get.back();
                                            }
                                          } else {
                                            if (!controller.isAnyPlayerVisible.value) {
                                              controller.isAnyPlayerVisible.value = true;

                                              // Open the Full Player
                                              Get.bottomSheet(PlayerFullSheetUI(sound: s), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                                controller.isAnyPlayerVisible.value = false;
                                              });
                                            }
                                            await controller.toggleMusic(s);
                                          }
                                        }
                                      },

                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E2131),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: isActive ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: CachedImageWidget(url: s.image, height: double.infinity, width: double.infinity, fit: BoxFit.cover, circle: false, usePlaceholderIfUrlEmpty: true),
                                            ),

                                            // Gradient overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                                                ),
                                              ),
                                            ),

                                            // Favorite icon inside GridView.builder
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: GestureDetector(
                                                // Inside your GridView.builder for the Heart Icon
                                                onTap: () => controller.toggleLike(s, categorySlug, subCategorySlug),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(color: isFav ? Colors.red.withOpacity(0.1) : Colors.black26, shape: BoxShape.circle),
                                                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 18 * SizeConfigs.textScale),
                                                ),
                                                // }),
                                              ),
                                            ),
                                            // Bottom info (name, duration, play)
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              right: 10,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          s.name,
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(controller.formatDuration(s.duration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 32,
                                                    width: 32,
                                                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                                    child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                                },
                              );
                            }
                            if (isStoryTab) {
                              return ListView.builder(
                                padding: const EdgeInsets.only(left: 18, right: 18, top: 15, bottom: 150),
                                itemCount: sounds.length,
                                itemBuilder: (context, i) {
                                  final s = sounds[i];
                                  return Obx(() {
                                    final double screenWidth = MediaQuery.sizeOf(context).width;
                                    final double responsiveHeight = screenWidth * 0.5;
                                    // Track if this specific story is in the music player
                                    final isPlaying = controller.playingMusic.any((m) => m.id == s.id);
                                    final isActuallyPlaying = isPlaying && !controller.isPaused.value;
                                    final isFav = s.isFavorite ?? false;
                                    // final isPremium = s.isPremium ?? false;
                                    return GestureDetector(
                                      // Update your Story Tab onTap:
                                      // Inside your Story Tab itemBuilder
                                      onTap: () async {
                                        // bool userHasNoPremium = true; // Replace with your actual premium status check
                                        // print("isPremium----$isPremium");
                                        print("subController.isPremium.value----${subController.isPremium.value}");
                                        if (s.isPremium == true && subController.isPremium.value == false) {
                                          // 1. Check karein ki user ne spin kar liya hai ya nahi
                                          final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                          if (hasAlreadySpun && !GetPlatform.isIOS) {
                                            // ✅ Agar spin ho gaya hai, toh direct discount wali sheet (Sheet 6)
                                            // iOS pe Sheet 6 ("50% OFF FOREVER") nahi (Apple 3.1.2(c)) - Sheet 4 hi.
                                            showPremiumOfferSheet6(context);
                                          } else {
                                            // ❌ Agar spin nahi hua, toh normal paywall (Sheet 4)
                                            showPremiumOfferSheet4(context);
                                          }
                                          return;
                                        }
                                        // Check if it's a long-form track (Music or from Favorites Tab)
                                        final isMusic = s.categoryName.toLowerCase() == "music";
                                        final isStory = s.categoryName.toLowerCase() == "story";
                                        final isAlreadyPlaying = controller.playingMusic.any((m) => m.id == s.id);

                                        if (isMusic || isStory || isFavTab) {
                                          // 🎵 Treat as Music: Handle Full Player / Pause logic
                                          if (isAlreadyPlaying) {
                                            await controller.togglePause();
                                            return;
                                          }

                                          if (controller.playingSounds.isNotEmpty) {
                                            await controller.toggleMusic(s);
                                            if (Get.isBottomSheetOpen ?? false) Get.back();
                                          } else {
                                            if (!controller.isAnyPlayerVisible.value) {
                                              controller.isAnyPlayerVisible.value = true;
                                              Get.bottomSheet(PlayerFullSheetUI(sound: s), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                                //isFromStory: true,
                                                controller.isAnyPlayerVisible.value = false;
                                              });
                                            }
                                            await controller.toggleMusic(s);
                                          }
                                        } else {
                                          // 🔊 Treat as ambient sound (Rain, White Noise, etc.)
                                          controller.toggleSound(s);
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: responsiveHeight,
                                        margin: const EdgeInsets.only(bottom: 20),
                                        // Increased margin for shadow visibility
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          // 🔥 Glow Shadow logic added here
                                          boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)] : [],
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: CachedImageWidget(
                                                  url: s.image,
                                                  fit: BoxFit.cover,
                                                  alignment: Alignment.topCenter, // 🔥 Anchors the top, crops the bottom
                                                ),
                                              ),
                                            ),

                                            // 2. Dark Gradient Overlay
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(20),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black.withOpacity(0.1),
                                                      Colors.black.withOpacity(0.75), // Slightly darker for better contrast
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),


                                            (s.isPremium == true && subController.isPremium.value == false)
                                                ? Positioned(top: 12, right: 16, child: Icon(Icons.lock, color: AppColors.white, size: 20))

                                            :Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: GestureDetector(
                                                      // Inside your GridView.builder for the Heart Icon
                                                      onTap: () => controller.toggleLike(s, categorySlug, subCategorySlug),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 300),
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(color: isFav ? Colors.red.withOpacity(0.1) : Colors.black26, shape: BoxShape.circle),
                                                        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 18 * SizeConfigs.textScale),
                                                      ),
                                                      // }),
                                                    ),
                                                  ),

                                            // 4. Content (Title and Duration)
                                            Positioned(
                                              bottom: 15,
                                              left: 15,
                                              right: 80,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    s.name,
                                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(controller.formatDuration(s.duration), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                                                ],
                                              ),
                                            ),

                                            // 5. Play/Pause Circle Button
                                            Positioned(
                                              bottom: 15,
                                              right: 15,
                                              child: AnimatedScale(
                                                scale: isPlaying ? 1.1 : 1.0, // Slight pop effect when active
                                                duration: const Duration(milliseconds: 200),
                                                child: Container(
                                                  height: 50,
                                                  width: 50,
                                                  decoration: BoxDecoration(
                                                    // Make button blue if playing
                                                    color: Colors.white.withOpacity(0.25),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white30, width: 0.5),
                                                  ),
                                                  child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                                },
                              );
                            } else {

                              // ⚪ Other categories (circle image view)
                              return GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                // padding: const EdgeInsets.only(left: 8, top: 15, bottom: 150),
                                // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 1, childAspectRatio: 0.75),
                                  padding: const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 150),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 10,
                                    // 🔥 Spacing badha di taaki vertical gap rahe
                                    mainAxisSpacing: 1,
                                    // 🔥 Dynamic Aspect Ratio: Small mobiles ke liye height adjustment
                                    childAspectRatio: MediaQuery.of(context).size.width < 360 ? 0.65 : 0.75,),
                                itemCount: sounds.length,
                                itemBuilder: (context, i) {
                                  final s = sounds[i];

                                  return Obx(() {
                                    final active = controller.playingSounds.any((it) => it.id == s.id);

                                    return GestureDetector(
                                      onTap: () {
                                        final controller1 = Get.find<HomeController>();
                                        // 🛡️ Logic: If it's locked, show premium sheet instead of playing
                                        if (s.isPremium == true && subController.isPremium.value == false) {
                                          // 1. Check karein ki user ne spin kar liya hai ya nahi
                                          final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                          if (hasAlreadySpun) {
                                           // showPremiumOfferSheet6(context);
                                            controller1.showRotatingPremiumSheet(context);
                                          } else {
                                           showPremiumOfferSheet4(context);
                                          }
                                          return;
                                        }
                                        controller.toggleSound(s);
                                      },
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 72,
                                            width: 72,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: active ? Colors.white12 : const Color(0xFF1C1F2E),
                                              border: active ? Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5) : null,
                                              boxShadow: active ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.35), blurRadius: 10)] : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                /// 1. MAIN CONTENT (Emoji or Image)
                                                Opacity(
                                                  // 🔥 Dim the image slightly if it's locked to make the lock icon pop
                                                  opacity: (s.isPremium ) ? 1.0 : 1.0,
                                                  child: (s.emoji != null && s.emoji!.trim().isNotEmpty)
                                                      ? Text(s.emoji!, style: const TextStyle(fontSize: 26))
                                                      : ClipRRect(
                                                    borderRadius: BorderRadius.circular(36),
                                                    child: CachedNetworkImage(
                                                      imageUrl: s.image,
                                                      height: 72, width: 72, fit: BoxFit.cover,
                                                      fadeInDuration: Duration.zero,
                                                      fadeOutDuration: Duration.zero,
                                                      placeholder: (context, url) => Container(color: const Color(0xFF1C1F2E)),
                                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white10),
                                                    ),
                                                  ),
                                                ),

                                                /// 2. PREMIUM LOCK OVERLAY

                                                /// 3. PREMIUM BADGE (Optional: Small star in corner)

                                                if (s.isPremium && subController.isPremium.value == false)
                                                  Positioned(
                                                    bottom: -7,
                                                    right: -8,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      // decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                                      child: Image.asset(Assets.homeLock, height: 30, width: 30),
                                                    //  const Icon(Icons.lock_rounded, size: 20, color: Colors.white),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            s.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: active ? Colors.white : Colors.white70,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                },
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),

                /// Floating Mix bar (on top at ~80%)
                /// Put this inside your Stack where the floating mix bar should appear
                // Obx(() => controller.showMixBar.value ? Positioned(left: 6, right: 6, bottom: MediaQuery.of(context).size.height * 0.15, child: MixBarWidget()) : const SizedBox.shrink()),
                Obx(() {
                  if (!controller.showMixBar.value) return const SizedBox.shrink();

                  // Bottom Bar ki fixed height
                  const double bottomBarHeight = 75.0;
                  // Niche se thoda gap (floating effect ke liye)
                  const double bottomGap = 3.0;
                  // System's safe area padding (iPhone home line etc.)
                  double safeAreaBottom = MediaQuery.of(context).padding.bottom;

                  return Positioned(
                    left: 10,
                    right: 10,
                    // Bar ke upar fixed distance pe rahega, screen size chahe jo bhi ho
                    bottom: bottomBarHeight + safeAreaBottom + bottomGap,
                    child: MixBarWidget(),
                  );
                }),
              ],
            ),
          ),

          /// 🔥 GLOBAL LOADER OVERLAY
          /// 🌍 ONE GLOBAL LOADER
          if (isScreenLoading && !hasData)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(child: LoaderWidget(size: sw(150))),
              ),
            ),
        ],
      );
    });
  }
}

class CustomPageScrollPhysics extends PageScrollPhysics {
  const CustomPageScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  // 🧭 Make the swipe very sensitive
  @override
  double get minFlingDistance => 5.0; // was 50 - much smaller
  @override
  double get minFlingVelocity => 50.0; // was 250 - easier flick
  @override
  double get maxFlingVelocity => 2000.0;

  @override
  double get pageFlingVelocity => 500.0;

  // Shorter transition for faster snap
  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  /// 🪄 Core logic: reduce required drag to switch pages (from ~30% → 5%)
  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position is! PageMetrics) return super.createBallisticSimulation(position, velocity);

    final PageMetrics metrics = position;
    final Tolerance tolerance = this.tolerance;

    // Current page
    double page = metrics.page!;
    double targetPage;

    if (velocity.abs() < tolerance.velocity) {
      // 👇 Reduce threshold from 0.3 → 0.05 (5%)
      final double delta = (metrics.pixels - metrics.page! * metrics.viewportDimension).abs();
      final double fractionDragged = delta / metrics.viewportDimension;

      if (fractionDragged > 0.01) {
        // go to next or previous depending on drag direction
        targetPage = metrics.pixels > metrics.page! * metrics.viewportDimension ? page + 1.0 : page - 1.0;
      } else {
        targetPage = page.roundToDouble();
      }
    } else {
      targetPage = velocity < 0.0 ? page - 1.0 : page + 1.0;
    }

    targetPage = targetPage.clamp(metrics.minScrollExtent / metrics.viewportDimension, metrics.maxScrollExtent / metrics.viewportDimension);

    return ScrollSpringSimulation(spring, metrics.pixels, targetPage * metrics.viewportDimension, velocity, tolerance: tolerance);
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(120));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

RxBool isRunning = false.obs;

void startTimer() {
  isRunning.value = true;
}

void stopTimer() {
  isRunning.value = false;
}

// ────────────────────────────────────────────────
// 🔵 TIMER CIRCLE WIDGET (Main UI Tap Trigger)
// ────────────────────────────────────────────────
class TimerCircle extends StatelessWidget {
  final SleepSoundController controller = Get.find<SleepSoundController>();

  TimerCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => openTimerBottomSheet(context),

            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: CustomPaint(
                    painter: _RoundedCircularProgressPainter(
                      progress: controller.remaining.value.inSeconds / controller.totalDuration.inSeconds,
                      color: Colors.blueAccent,
                      backgroundColor: Colors.white10,
                      strokeWidth: 2,
                    ),
                  ),
                ),

                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                  child: Icon(Icons.timer_sharp, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(controller.remaining.value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.starColor, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),

            // style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      );
    });
  }

  String _formatDuration(Duration d) {
    final lang = Get.context!.lang;
    if (d.inSeconds == 0) return lang.setTimer;
    final minutes = d.inMinutes.remainder(120).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void openTimerBottomSheet(BuildContext context) {
    final controller = Get.find<SleepSoundController>();
    controller.activeSheet.value = "timer"; // default first screen

    Get.bottomSheet(
      Obx(() {
        if (controller.activeSheet.value == "timer") {
          print("in timer");
          return _buildSetTimeSheet(context, controller);
        } else if (controller.activeSheet.value == "setTime") {
          print("set timer");
          return _buildActiveTimerSheet(context, controller);
        } else {
          return const SizedBox.shrink();
        }
      }),
      isScrollControlled: true,
    );
  }
}

Widget _buildActiveTimerSheet(BuildContext context, SleepSoundController controller) {
  final size = MediaQuery.of(context).size;
  final height = size.height;
  final width = size.width;
  final lang = context.lang;
  return Container(
    height: height * 0.75,
    decoration: const BoxDecoration(
      color: Color(0xFF0A152F),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: height * 0.03),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Top Close Arrow
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: constraints.maxWidth * 0.1, // responsive icon size
                ),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.015),

            // 🔹 Title
            Text(
        lang.setTimer,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: constraints.maxHeight * 0.01),

            // 🔹 Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04),
              child: Text(
                lang.timerSubTitle,//"As the time comes to an end, the sound will gently\nfade into silence...",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.02),

            // 🔹 Timer Circle
            Expanded(
              child: Center(
                child: Obx(() {
                  // final total = controller.totalDuration.inSeconds;
                  // final remaining = controller.remaining.value.inSeconds;
                  // final progress = total == 0 ? 0.0 : remaining / total;
                  final total = controller.totalDuration.inSeconds;
                  final remain = controller.remaining.value.inSeconds;

                  final progress = (total == 0) ? 0.0 : remain / total;
                  return FittedBox(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * 0.8,
                          height: constraints.maxWidth * 0.8,
                          child: CustomPaint(
                            painter: _RoundedCircularProgressPainter(
                              progress: progress,
                              color: Colors.blueAccent,
                              backgroundColor: Colors.white10,
                              strokeWidth: width * 0.04, // proportional stroke
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(controller.remaining.value),
                          style: TextStyle(color: Colors.white, fontSize: constraints.maxWidth * 0.08, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.02),

            // 🔹 Reset Timer Button
            Padding(
              padding: EdgeInsets.only(bottom: height * 0.02),
              child: SizedBox(
                width: constraints.maxWidth * 0.8,
                height: height * 0.065,
                child: ElevatedButton(
                  onPressed: () {
                    controller.activeSheet.value = "setTime";
                    controller.activeSheet.value = "main";
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: FittedBox(
                    child: Text(
                      lang.resetTimer,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16 * SizeConfigs.textScale),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildSetTimeSheet(BuildContext context, SleepSoundController controller) {
  final lang = context.lang;
  final size = MediaQuery.of(context).size;
  final height = size.height;
  final width = size.width;
  final RxDouble selectedMinutes = controller.totalDuration.inMinutes.toDouble().obs;
  final ScrollController scrollController = ScrollController();

  const double tickWidth = 24.0;
  const int maxMinutes = 120;
  const double minutesPerTick = 5.0;

  // 🔹 Scroll initialization
  WidgetsBinding.instance.addPostFrameCallback((_) {
    double defaultOffset = (selectedMinutes.value / minutesPerTick) * tickWidth;
    scrollController.jumpTo(defaultOffset);
  });

  scrollController.addListener(() {
    final offset = scrollController.offset;
    final newMinutes = offset / tickWidth * minutesPerTick;
    selectedMinutes.value = newMinutes.clamp(0, maxMinutes).toDouble();
  });
  return Container(
    height: height * 0.75,
    decoration: const BoxDecoration(
      color: Color(0xFF0A152F),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: EdgeInsets.symmetric(vertical: height * 0.03),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double buttonHeight = constraints.maxHeight * 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Top Close Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    controller.activeSheet.value = "timer";
                    Get.back();
                  },
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: constraints.maxWidth * 0.1),
                ),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.015),

            // 🔹 Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Text(
                lang.setTimer,// "Set Timer",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.01),

            // 🔹 Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Text(
                lang.timerQuestion,//"How long should the audio play?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.07),

            // 🔹 Selected Time
            Obx(() {
              final minutes = selectedMinutes.value.round();
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$minutes ",
                      style: TextStyle(color: Colors.white, fontSize: constraints.maxWidth * 0.12, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: lang.min,
                      style: TextStyle(color: Colors.white70, fontSize: constraints.maxWidth * 0.05, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              );
            }),

            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60, size: constraints.maxWidth * 0.07),

            SizedBox(height: constraints.maxHeight * 0.02),

            // 🔹 Time Ruler
            SizedBox(
              height: constraints.maxHeight * 0.16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ListView.builder(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: width / 2 - tickWidth / 2),
                    itemCount: (maxMinutes / minutesPerTick).round() + 1,
                    itemBuilder: (context, index) {
                      final minute = index * minutesPerTick;
                      final isBig = minute % 15 == 0;
                      final lineHeight = isBig ? constraints.maxHeight * 0.12 : constraints.maxHeight * 0.07;

                      return Container(
                        width: tickWidth,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 2, height: lineHeight, color: isBig ? Colors.blueAccent : Colors.white24),
                            SizedBox(height: constraints.maxHeight * 0.01),
                            if (isBig)
                              Text(
                                "${minute.round()}",
                                style: TextStyle(color: Colors.white70, fontSize: constraints.maxWidth * 0.03),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(top: 0, bottom: 0, child: Container(width: 2, color: Colors.blueAccent)),
                ],
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.04),

            // 🔹 Preset Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: SizedBox(
                height: buttonHeight * 0.9,
                child: LayoutBuilder(
                  builder: (context, itemConstraints) {
                    double itemWidth = itemConstraints.maxWidth / 6.2;
                    final totalWidth = controller.presetTimes.length * itemWidth + (controller.presetTimes.length - 1) * 8;
                    final horizontalPadding = ((itemConstraints.maxWidth - totalWidth) / 2).clamp(0, double.infinity);

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => SizedBox(width: width * 0.02),
                      itemCount: controller.presetTimes.length,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.toDouble()),
                      itemBuilder: (context, index) {
                        final t = controller.presetTimes[index];
                        return Obx(() {
                          final isSelected = selectedMinutes.value.round() == t;
                          return GestureDetector(
                            onTap: () {
                              selectedMinutes.value = t.toDouble();
                              double offset = (t / minutesPerTick) * tickWidth;
                              // scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
                              if (scrollController.hasClients) {
                                scrollController.animateTo(
                                  offset,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            child: AnimatedContainer(
                              width: itemWidth,
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(color: isSelected ? Colors.blueAccent : Colors.white10, borderRadius: BorderRadius.circular(30)),
                              child: Center(
                                child: Text(
                                  "$t'",
                                  style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w600, fontSize: constraints.maxWidth * 0.04),
                                ),
                              ),
                            ),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: constraints.maxHeight * 0.06),

            SizedBox(
              width: constraints.maxWidth * 0.7,
              height: height * 0.065,
              child: ElevatedButton(
                onPressed: () {
                  controller.activeSheet.value = "setTime";
                  print("its cal ********------------------------------1");

                  controller.resetTimer(selectedMinutes.value.round());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: FittedBox(
                  child: Text(
                    lang.start,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16 * SizeConfigs.textScale),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RoundedCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RoundedCircularProgressPainter({required this.progress, required this.color, required this.backgroundColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
