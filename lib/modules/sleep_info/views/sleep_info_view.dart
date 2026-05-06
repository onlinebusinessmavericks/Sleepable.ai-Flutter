import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:sleepable_ai/modules/sleep_info/views/sleeppedia_detail_view.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../home/widget/Youtubeer_view.dart';
import '../../music/views/music_view.dart';
import '../controllers/sleep_info_controller.dart';
import '../widget/sleep_quiz_detail_view.dart';

class SleepInfoView extends GetView<SleepInfoController> {
  const SleepInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 22.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SmallCircleIcon(
              icon: Icons.arrow_back_rounded,
              size: 20 * SizeConfigs.textScale,
              iconColor: Colors.white,
              backgroundColor: Colors.white10,
              onTap: () => Get.back(),//Get.offAllNamed(Routes.dashboard),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: controller.tabs.length,
              itemBuilder: (context, index) {
                return Obx(() {
                  final isSelected = controller.selectedTab.value == index;

                  return GestureDetector(
                    onTap: () => controller.changeTab(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔹 Tab Text
                          Text(
                            controller.tabs[index],
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: isSelected ? Colors.white : Colors.grey.shade700, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                          ),

                          const SizedBox(height: 6),

                          // 🔹 Bottom Indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 20 : 0,
                            height: 3,
                            decoration: BoxDecoration(color: const Color(0xFF3A7CFF), borderRadius: BorderRadius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // ================= CONTENT =================
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged, // 🔥 sync tab
              children: [
                _buildSleeppedia(context),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                  child: GridView.builder(
                    itemCount: homeController.sleepQuizzes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12 * SizeConfigs.paddingScale,
                      mainAxisSpacing: 12 * SizeConfigs.paddingScale,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final item = homeController.sleepQuizzes[index];
                      return _buildSleepQuizGrid(context, item);
                    },
                  ),
                ),
                _buildYouTubeTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSleeppedia(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final cardHeight = isSmallPhone ? 70.0 : 75.0;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
      itemCount: controller.sleeppedia.length,
      itemBuilder: (context, index) {
        final item = controller.sleeppedia[index];

        return GestureDetector(
          onTap: () {
            Get.to(() => SleeppediaDetailView(item: item));
          },
          child: Container(
            height: cardHeight * SizeConfigs.paddingScale,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.card.withOpacity(0.98), borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(item.image, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.card.withOpacity(0.98), Colors.transparent]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * SizeConfigs.paddingScale, vertical: 14 * SizeConfigs.paddingScale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepQuizGrid(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Get.to(() => SleepQuizDetailView(data: data));
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(child: Image.asset(data['image'], fit: BoxFit.cover)),

            // Dark gradient for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
                ),
              ),
            ),

            // Text content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   data['title'],
                  //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  const SizedBox(height: 4),
                  Text(data['subtitle'], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingVideos.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF3A7CFF)));
      }

      if (controller.videos.isEmpty) {
        return  Center(child: Text(context.lang.noVideosFound, style: TextStyle(color: Colors.white)));
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: controller.videos.length,
        itemBuilder: (context, index) {
          final videoItem = controller.videos[index];
          final snippet = videoItem['snippet'];

          // Safety check: Access videoId correctly from the 'id' map
          // final dynamic idData = videoItem['id'];
          // final String? videoId = idData is Map ? idData['videoId'] : null;
          final idData = videoItem['id'];
          final String? videoId = (idData is Map && idData['kind'] == 'youtube#video')
              ? idData['videoId']
              : null;
          return GestureDetector(
            onTap: () {
              if (videoId != null && videoId.isNotEmpty) {
                Get.to(() => YouTubePlayerView(
                  videoId: videoId,
                  title: snippet['title'] ?? context.lang.untitledVideo,
                ));
              } else {
                Get.snackbar(
                  context.lang.noticeLabel,
                  context.lang.notPlayableVideo,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        snippet['thumbnails']?['high']?['url'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey, child: const Icon(Icons.error)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      snippet['title'] ?? context.lang.untitledVideo,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
