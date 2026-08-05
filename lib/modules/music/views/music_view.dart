import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../controllers/music_controller.dart';

/// The music player itself lives on SleepSoundController, so read its buffering
/// state from there. Returns false if that controller is not registered.
bool _isBufferingNow() {
  if (!Get.isRegistered<SleepSoundController>()) return false;
  return Get.find<SleepSoundController>().isBuffering.value;
}

class MusicView extends GetView<MusicController> {
  const MusicView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MusicController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sleep Sounds",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12), // optional: spacing
          child: SmallCircleIcon(
            icon: Icons.arrow_back_rounded,
            size: 20,
            // icon size
            iconColor: Colors.white,
            backgroundColor: AppColors.white10,
            onTap: () {
              Get.back();
              // action here
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SmallCircleIcon(
              icon: Icons.favorite_border,
              size: 20,
              iconColor: Colors.white,
              backgroundColor: AppColors.white10,
              onTap: () {
                // action here
              },
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Main Sound Card ---
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.greenColor, Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=200&q=80',

                      height: 120 * SizeConfigs.paddingScale,
                      width: 120 * SizeConfigs.paddingScale,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Text(
                      controller.currentSound.value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.white, fontSize: 18 * SizeConfigs.textScale),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gentle rainfall in a peaceful forest",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.lightGreenColor, fontSize: 15 * SizeConfigs.textScale),
                    // style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: controller.animationController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.greenColor.withOpacity(.7), AppColors.lightGreenColor.withOpacity(.4), AppColors.greenColor.withOpacity(.9)],
                            stops: [controller.animation.value - 0.9, controller.animation.value, controller.animation.value + 0.9],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(3 * SizeConfigs.paddingScale),
                        decoration: BoxDecoration(color: AppColors.white10, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(Icons.skip_previous, color: Colors.white, size: 30 * SizeConfigs.paddingScale),
                          onPressed: () {},
                        ),
                      ),
                      Obx(
                        () => Material(
                          color: Colors.white, // background color
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            splashColor: AppColors.backgroundColor.withOpacity(0.3),
                            onTap: controller.togglePlay,
                            child: Padding(
                              padding: EdgeInsets.all(16 * SizeConfigs.paddingScale),
                              // Long tracks are 20-25 MB; show buffering instead of
                              // a play icon that looks like nothing happened.
                              child: _isBufferingNow()
                                  ? SizedBox(
                                      width: 32 * SizeConfigs.paddingScale,
                                      height: 32 * SizeConfigs.paddingScale,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.backgroundColor,
                                      ),
                                    )
                                  : Icon(controller.isPlaying.value ? Icons.pause : Icons.play_arrow, color: AppColors.backgroundColor, size: 32 * SizeConfigs.paddingScale),
                            ),
                          ),
                        ),
                      ).paddingOnly(left: 16 * SizeConfigs.paddingScale, right: 16 * SizeConfigs.paddingScale),
                      Container(
                        padding: EdgeInsets.all(3 * SizeConfigs.paddingScale),
                        decoration: BoxDecoration(color: AppColors.white10, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(Icons.skip_next, color: Colors.white, size: 30 * SizeConfigs.paddingScale),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * SizeConfigs.paddingScale),
                  Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_filled_outlined, // clock icon
                          color: Colors.white70,
                          size: 18,
                        ),
                        SizedBox(width: 10 * SizeConfigs.paddingScale), // space between icon and text
                        Text(
                          "${controller.timer.value} minutes",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.white, fontSize: 14 * SizeConfigs.textScale),
                        ),
                      ],
                    ),
                  ),
                ],
              ).paddingSymmetric(horizontal: 28 * SizeConfigs.paddingScale, vertical: 28 * SizeConfigs.paddingScale),
            ),

            const SizedBox(height: 20),

            // --- Category Buttons ---
            Obx(() {
              final selectedCategory = controller.selectedCategory.value;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controller.categories.map((category) {
                    final isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () => controller.selectedCategory.value = category,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6 * SizeConfigs.paddingScale),
                        padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 11 * SizeConfigs.paddingScale),
                        decoration: BoxDecoration(color: isSelected ? AppColors.blueColor : AppColors.backGroundGreyColor, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

            SizedBox(height: 24 * SizeConfigs.textScale),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Popular Sounds",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 22 * SizeConfigs.textScale),

            // --- Sound List ---
            Obx(
              () => AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 800),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 100.0, // 👈 slides from right to left
                      curve: Curves.easeOutCubic,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: List.generate(controller.sounds.length, (index) {
                      final sound = controller.sounds[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8 * SizeConfigs.paddingScale, horizontal: 8 * SizeConfigs.paddingScale),
                        decoration: BoxDecoration(color: sound['isPlaying'] == true ? AppColors.cardBackGroundGreyColor : AppColors.cardBackGroundGreyColor, borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=100&q=80',
                              height: 45 * SizeConfigs.paddingScale,
                              width: 45 * SizeConfigs.paddingScale,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            sound['title'].toString(),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.white, fontSize: 14 * SizeConfigs.textScale),
                          ),
                          subtitle: Text(
                            sound['subtitle'].toString(),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 12 * SizeConfigs.textScale),
                          ),
                          trailing: Material(
                            color: sound['isPlaying'] == true ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: Colors.white.withOpacity(0.3),
                              onTap: () {
                                // Update all sounds
                                for (var i = 0; i < controller.sounds.length; i++) {
                                  controller.sounds[i]['isPlaying'] = i == index;
                                }
                                controller.playSound(index);
                                controller.sounds.refresh(); // important for RxList
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(Icons.play_arrow, color: (sound['isPlaying'] as bool) ? Colors.white : Colors.white70, size: 26),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 18 * SizeConfigs.paddingScale, vertical: 18 * SizeConfigs.paddingScale),
      ),
    );
  }
}

class SmallCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size; // icon size
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const SmallCircleIcon({
    super.key,
    required this.icon,
    this.size = 18,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x1AFFFFFF), // white10
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double circleSize = size * 1.5; // background circle 2x icon size

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: InkWell(
        borderRadius: BorderRadius.circular(circleSize / 2),
        onTap: onTap,
        child: Center(
          child: Icon(icon, color: iconColor, size: size),
        ),
      ),
    );
  }
}
