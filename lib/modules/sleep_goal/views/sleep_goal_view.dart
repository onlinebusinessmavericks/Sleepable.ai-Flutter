import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide LinearGradient;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:haptic_feedback/haptic_feedback.dart';

// import 'package:marquee/marquee.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/sleep_goal_controller.dart';

class SleepGoalView extends StatelessWidget {
  const SleepGoalView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SleepGoalController>();

    return WillPopScope(
        onWillPop: () async {

          // 👈 If NOT first question → go back question
          if (controller.currentIndex.value > 0) {
            controller.previousQuestion();
            return false; // ⛔ prevent screen pop
          }

          // 👈 First question → allow exit to Welcome screen
          return true;
        },
        child:AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // transparent background
        statusBarIconBrightness: Brightness.light, // ANDROID icons
        statusBarBrightness: Brightness.light, // iOS icons
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20 * SizeConfigs.paddingScale),
            child: Obx(() {
              final question = controller.questions[controller.currentIndex.value];

              // ✅ Safe list extraction (for multiple-choice questions)
              final items = (question['items'] is List) ? question['items'] as List<dynamic> : [];

              // ✅ Optional: get type and title for later logic
              final type = question['type']?.toString() ?? '';

              return Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        // for circular ripple
                        onTap: controller.previousQuestion,
                        child: Padding(
                          padding: EdgeInsets.all(SizeConfigs.screenWidth * 0.015),
                          child: Image.asset(Assets.onboardingBack, color: AppColors.iconColor, width: SizeConfigs.screenWidth * 0.050, height: SizeConfigs.screenWidth * 0.050),
                        ),
                      ),

                      type == 'interstitial' ? SizedBox() : SizedBox(width: SizeConfigs.screenWidth * 0.085),
                      type == 'interstitial'
                          ? SizedBox()
                          : Center(
                              child: Container(
                                margin: EdgeInsets.only(left: SizeConfigs.screenWidth * 0.04),
                                width: SizeConfigs.screenWidth * 0.50,
                                height: 5,
                                decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2.5)),
                                child: Obx(() {
                                  final progress = controller.progress.clamp(0.0, 1.0);
                                  return AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(color: AppColors.iconColor, borderRadius: BorderRadius.circular(2.5)),
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ],
                  ),
                  SizedBox(height: SizeConfigs.screenHeight * 0.01),

                  // Animated Question Section
                  Expanded(
                    key: ValueKey(controller.currentIndex.value),
                    child: Column(
                      children: [
                        Obx(
                          () => AnimatedTitle(
                            title: question['title'],
                            playReverse: controller.playReverseTitle.value,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 26 * SizeConfigs.textScale, fontWeight: FontWeight.w500, fontFamily: 'Coolvetica'),
                          ),
                        ).paddingOnly(top: SizeConfigs.screenHeight * 0.04, left: SizeConfigs.screenWidth * 0.1, right: SizeConfigs.screenWidth * 0.10, bottom: SizeConfigs.screenHeight * 0.02),

                        SizedBox(height: SizeConfigs.screenHeight * 0.03),

                        // Question Options Animated List
                        if (type == 'time_picker')
                          Obx(() {
                            final selectedTime = controller.selectedTime.value;
                            final hour = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
                            final minute = selectedTime.minute;
                            final amPm = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';

                            // controller.updateTime(hour, minute, amPm);
                            const backgroundColor = AppColors.backgroundColor;

                            TextStyle unselectedStyle = const TextStyle(color: Colors.grey, fontSize: 18);
                            TextStyle selectedStyle = const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold);
                            //
                            // Widget buildPickerItem(int value, int selectedValue, String suffix) {
                            //   return Center(child: Text('$value$suffix', style: value == selectedValue ? selectedStyle : unselectedStyle));
                            // }
                            Widget buildPickerItem(int value, int selectedValue, String suffix) {
                              // 👈 Format to 2-digit string
                              String formattedValue = value.toString().padLeft(2, '0');

                              return Center(
                                child: Text(
                                  '$formattedValue$suffix',
                                  style: value == selectedValue ? selectedStyle : unselectedStyle,
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pickers Row
                                SizedBox(
                                  height: SizeConfigs.screenHeight * 0.3,
                                  // 👈 gives space for upper and lower numbers
                                  child: Row(
                                    children: [
                                      // Hour picker
                                      Expanded(
                                        child: CupertinoPicker(
                                          backgroundColor: backgroundColor,
                                          itemExtent: 40,
                                          // height of each row
                                          diameterRatio: 1.2,
                                          // 👈 controls visible curvature (optional)
                                          scrollController: FixedExtentScrollController(initialItem: hour - 1),
                                          onSelectedItemChanged: (index) {
                                            controller.updateTime(index + 1, minute, amPm);
                                          },
                                          children: List.generate(12, (index) => buildPickerItem(index + 1, hour, '')),
                                        ),
                                      ),

                                      // Minute picker
                                      Expanded(
                                        child: CupertinoPicker(
                                          backgroundColor: backgroundColor,
                                          itemExtent: 40,
                                          diameterRatio: 1.2,
                                          scrollController: FixedExtentScrollController(initialItem: minute),
                                          onSelectedItemChanged: (index) {
                                            controller.updateTime(hour, index, amPm);
                                          },
                                          children: List.generate(60, (index) => buildPickerItem(index, minute, '')),
                                        ),
                                      ),

                                      // AM/PM picker
                                      Expanded(
                                        child: CupertinoPicker(
                                          backgroundColor: AppColors.backgroundColor,
                                          itemExtent: 40,
                                          diameterRatio: 1.2,
                                          scrollController: FixedExtentScrollController(initialItem: amPm == 'AM' ? 0 : 1),
                                          onSelectedItemChanged: (index) {
                                            controller.updateTime(hour, minute, index == 0 ? 'AM' : 'PM');
                                          },
                                          children: [Get.context?.lang.AM , Get.context?.lang.PM].map((e) => Center(child: Text(e!, style: e == amPm ? selectedStyle : unselectedStyle))).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          })
                        else
                          Expanded(
                            child: ListView.builder(
                              clipBehavior: Clip.none,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return Obx(() {
                                  final isSelected = controller.selectedInterests.contains(item['title']);

                                  return TweenAnimationBuilder<Offset>(
                                    tween: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
                                    duration: Duration(milliseconds: 400 + (index * 100)),
                                    curve: Curves.easeOut,
                                    builder: (context, offset, child) {
                                      return Transform.translate(
                                        offset: Offset(offset.dx * 200, 0),
                                        child: Opacity(opacity: 1 - offset.dx.abs(), child: child),
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: () async {
                                        controller.toggleSelection(item['title']);

                                        // Wait for glow animation before moving on
                                        await Future.delayed(const Duration(seconds: 4));
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        margin: EdgeInsets.symmetric(vertical: SizeConfigs.screenHeight * 0.011),
                                        padding: EdgeInsets.symmetric(
                                          vertical: (item['emoji'] is String && item['emoji'].toString().contains('assets/images/onboarding/positions')) ? 0 : SizeConfigs.screenHeight * 0.014,
                                          horizontal: (item['emoji'] is String && item['emoji'].toString().contains('assets/images/onboarding/positions'))
                                              ? SizeConfigs.screenHeight * 0.001
                                              : SizeConfigs.screenWidth * 0.045,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: AppColors.cardColor,
                                          border: Border.all(color: isSelected ? Colors.blueAccent.withOpacity(0.9) : AppColors.borderColor, width: isSelected ? 1.5 : 0.8),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                                                  BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                                                ]
                                              : [],
                                        ),

                                        child:
                                            Row(
                                              children: [
                                                if (item['emoji'] is String && item['emoji'].toString().contains('assets/images/onboarding/positions'))
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: Image.asset(
                                                      item['emoji'],
                                                      height: 70 * SizeConfigs.textScale,
                                                      width: 70 * SizeConfigs.textScale,
                                                      fit: BoxFit.cover,
                                                      // color: AppColors.iconColor,
                                                    ),
                                                  )
                                                else if (item['emoji'] is String && item['emoji'].toString().contains('assets/images/'))
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: Image.asset(
                                                      item['emoji'],
                                                      height: 30 * SizeConfigs.textScale,
                                                      width: 30 * SizeConfigs.textScale,
                                                      fit: BoxFit.contain,
                                                      color: AppColors.iconColor,
                                                    ),
                                                  )
                                                else
                                                  Text(item['emoji'], style: TextStyle(fontSize: 23.3 * SizeConfigs.textScale)),
                                                SizedBox(width: SizeConfigs.screenWidth * 0.04),
                                                Expanded(
                                                  child: Marquee(
                                                    child: Text(
                                                      item['title'],
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        color: AppColors.white,
                                                        fontSize: 17 * SizeConfigs.textScale,
                                                        fontWeight: FontWeight.w100,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ).paddingAll(
                                              (item['emoji'] is String && item['emoji'].toString().contains('assets/images/onboarding/positions'))
                                                  ? 0.01 * SizeConfigs.paddingScale
                                                  : 6 * SizeConfigs.paddingScale,
                                            ),
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfigs.screenHeight * 0.02),

                  Obx(() {
                    final question = controller.questions[controller.currentIndex.value];
                    final title = question['title'] as String;
                    final type = question['type'] as String? ?? '';
                    final isMulti = question['multiSelect'] as bool;

                    bool hasAnswer = false;

                    if (type == 'time_picker') {
                      hasAnswer = controller.timeSelected.value;
                    } else if (isMulti) {
                      hasAnswer = controller.selectedInterests.isNotEmpty;
                    } else {
                      hasAnswer = controller.answers[title] != null;
                    }

                    // single select → auto next
                    if (!isMulti && type != 'time_picker') {
                      return const SizedBox.shrink();
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      // Use a transition builder to make the button fade/scale in when 'hasAnswer' becomes true
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                      },
                      child: hasAnswer
                          ? Obx(() => GestureDetector(
                        key: const ValueKey('continue_btn_wrapper'), // Key moves here for AnimatedSwitcher
                        // --- Instant Visual/Physical Feedback ---
                        onTapDown: (_) {
                          controller.buttonScale.value = 0.94;
                          Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true); // Vibrate on press for better feel
                        },
                        onTapUp: (_) => controller.buttonScale.value = 1.0,
                        onTapCancel: () => controller.buttonScale.value = 1.0,

                        // --- The Logic Call ---
                        onTap: () async {
                          // Ensure button pops back up visually before logic runs
                          controller.buttonScale.value = 1.0;

                          controller.playReverseTitle.value = true;

                          // Small delay to let the animation breathe
                          await Future.delayed(const Duration(milliseconds: 400));

                          controller.saveCurrentSelection();
                          controller.nextQuestion();
                        },
                        child: AnimatedScale(
                          scale: controller.buttonScale.value,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          child: AnimatedBuilder(
                            animation: controller.animationController,
                            builder: (_, __) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    vertical: SizeConfigs.screenHeight * 0.018),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  // Pulse color slightly when pressed
                                  color: controller.buttonScale.value < 1.0
                                      ? AppColors.blueLine.withOpacity(0.9)
                                      : null,
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppColors.blueLine.withOpacity(.7),
                                      AppColors.blueLine.withOpacity(.4),
                                      AppColors.blueLine.withOpacity(.9)
                                    ],
                                    stops: [
                                      controller.animation.value - 0.9,
                                      controller.animation.value,
                                      controller.animation.value + 0.9
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    context.lang.continues,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ))
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      ),
    ));
  }
}

class AnimatedTitle extends StatefulWidget {
  final String title;
  final TextStyle? style;
  final bool playReverse;
  final VoidCallback? onReverseComplete;

  const AnimatedTitle({super.key, required this.title, this.style, this.playReverse = false, this.onReverseComplete});

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Listen for reverse completion:
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // reverse finished (title out)
        widget.onReverseComplete?.call();
      }
    });

    // Play the entry animation
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedTitle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Title changed -> re-play entry animation
    if (oldWidget.title != widget.title) {
      _controller
        ..reset()
        ..forward();
      return;
    }

    // playReverse changed from false -> true : run exit animation
    if (!oldWidget.playReverse && widget.playReverse) {
      // Ensure controller is at completed (1.0) state, then reverse
      if (_controller.status != AnimationStatus.completed) {
        _controller.forward().whenComplete(() => _controller.reverse());
      } else {
        _controller.reverse();
      }
      return;
    }

    // If playReverse toggled from true -> false while still dismissed,
    // bring it back to visible so next title can animate in when it changes.
    if (oldWidget.playReverse && !widget.playReverse) {
      // reset to 0 then forward to show again on next title update
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Text(widget.title, style: widget.style, textAlign: TextAlign.center),
      ),
    );
  }
}

class _InterstitialScreen extends StatelessWidget {
  final Widget media;
  final String buttonText;
  final String subTitle;
  final VoidCallback onNext;

  const _InterstitialScreen({required this.media, required this.buttonText, required this.subTitle, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// IMAGE
        // Image.asset(image, height: h * 0.35, fit: BoxFit.contain),
        /// MEDIA (Image / Lottie / Video)
        SizedBox(
          height: h * 0.35,
          child: Center(child: media),
        ),

        SizedBox(height: h * 0.02),

        /// TEXT (scroll only if needed)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: h * 0.25),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 18),
              ),
            ),
          ),
        ),

        SizedBox(height: h * 0.03),

        /// BUTTON
        // SizedBox(
        AnimatedNextButton(onPressed: onNext),

        SizedBox(height: h * 0.03),
      ],
    );
  }
}

Widget buildMedia(dynamic media) {
  if (media is String) {
    if (media.endsWith('.json')) {
      return Lottie.asset(media);
    }

    if (media.endsWith('.png') || media.endsWith('.jpg') || media.endsWith('.jpeg')) {
      return Image.asset(media, fit: BoxFit.contain);
    }

    if (media.endsWith('.mp4')) {
      return AssetVideoPlayer(media); // ✅ FIX
    }
  }

  return const SizedBox();
}

class AssetVideoPlayer extends StatefulWidget {
  final String path;

  const AssetVideoPlayer(this.path, {super.key});

  @override
  State<AssetVideoPlayer> createState() => _AssetVideoPlayerState();
}

class _AssetVideoPlayerState extends State<AssetVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.path)
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox();
    }

    return AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller));
  }
}
