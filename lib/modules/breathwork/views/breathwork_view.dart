import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
// import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../routes/app_pages.dart';
import '../../heart_bpm/views/heart_bpm_view.dart';
import '../../music/views/music_view.dart';
import '../controllers/breathwork_controller.dart';

class BreathworkView extends StatefulWidget {
  const BreathworkView({super.key});

  @override
  State<BreathworkView> createState() => _BreathworkViewState();
}

class _BreathworkViewState extends State<BreathworkView> with TickerProviderStateMixin {
  late AnimationController _cardAnim;
  late AnimationController _textAnim;

  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late AnimationController lottieController;
  Worker? _remainingWorker;
  Worker? _playingWorker;
  final BreathworkController controller = Get.find<BreathworkController>();

  @override
  void initState() {
    super.initState();

    _cardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    lottieController = AnimationController(vsync: this);

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _textAnim, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _textAnim, curve: Curves.easeIn);

    // 🔥 2. Assign workers and check 'mounted'
    _remainingWorker = ever(controller.remainingSeconds, (value) async {
      if (!mounted) return;
      if (value == 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _textAnim.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _cardAnim.forward();
      } else {
        _cardAnim.reset();
        _textAnim.reset();
      }
    });

    _playingWorker = ever(controller.isPlaying, (playing) {
      if (!mounted) return;
      if (playing == true) {
        lottieController.repeat();
      } else {
        // Safe check to prevent calling stop on disposed ticker
        if (lottieController.isAnimating) lottieController.stop();
      }
    });
  }

  @override
  void dispose() {
    // 🔥 3. DISPOSE WORKERS FIRST
    _remainingWorker?.dispose();
    _playingWorker?.dispose();

    _cardAnim.dispose();
    _textAnim.dispose();
    lottieController.dispose();

    // We don't call controller.stopAllTimers() here
    // unless you want the timer to stop every time they leave the screen.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              /// ----------------------------------------
              /// 🔹 Header Row (Always Visible)
              /// ----------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SmallCircleIcon(
                      icon: Icons.arrow_back_rounded,
                      size: 20 * SizeConfigs.textScale,
                      iconColor: Colors.white,
                      backgroundColor: Colors.white10,
                      onTap: () {
                        controller.stopAllTimers();
                        Get.back();
                      },
                    ),
          
                    Text(
                      context.lang.breathwork,
                      // "Breathwork",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    ),
          
                    /// ℹ️ Shows "redo" only if timer is finished
                    Obx(() {
                      final seconds = controller.remainingSeconds.value;
          
                      return GestureDetector(
                        onTap: seconds <= 0 ? controller.resetBreathing : () => showInfoSheet(context),
                        child: seconds <= 0
                            ? Row(
                                children: [
                                  Icon(Icons.undo, size: 18, color: AppColors.blueLine),
                                  const SizedBox(width: 2),
                                  Text(
                                    context.lang.redo,
                                    // "Redo",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blueLine, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                                child: const Icon(Icons.info_outline, size: 18, color: Colors.white),
                              ),
                      );
                    }),
                  ],
                ),
              ),

              
              // const SizedBox(height: 20),
              /// ----------------------------------------
              /// 🔥 Hide Everything Below When Timer = 0
              /// ----------------------------------------
              Obx(() {

                final seconds = controller.remainingSeconds.value;
          
                if (seconds <= 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 40),
                      Lottie.asset(Assets.lottieBreathingExercise, height: 200, fit: BoxFit.contain),
                      // const SizedBox(height: 40),
          
                      /// 🌬 Title Fade + Slide
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Text(
                            context.lang.breathworkCompleted,
                            // "Breathwork Completed!",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
          
                      const SizedBox(height: 10),
                      Text(
                        context.lang.stepCalmerSleep,
                        // "That's a step toward a calmer sleep.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 14 * SizeConfigs.textScale,
                          // fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.lang.howYourExperience,
                        // "How was your experience?",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
          
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 👎 BAD
                          GestureDetector(
                            onTap: () => controller.rateExperience(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.thumb_down_alt_rounded, color: Colors.redAccent, size: 28),
                            ),
                          ),
          
                          const SizedBox(width: 40),
          
                          // 👍 GOOD
                          GestureDetector(
                            onTap: () => controller.rateExperience(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.thumb_up_alt_rounded, color: Colors.lightGreenAccent, size: 28),
                            ),
                          ),
                        ],
                      ),
          
                      const SizedBox(height: 40),
          
                      /// 🌟 Card Animation
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(Assets.homeSleepableAppIcon, height: 20, width: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        context.lang.calmYourHeartRate,
                                        // "Calm Your Heart Rate",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale),
                                      ),
                                    ],
                                  ),
          
                                  const SizedBox(height: 12),
          
                                  Text(
                                    context.lang.breathworkRelaxesBodyCalmsHeartRateMeasureHeartRateEffects,
                                    // "Breathwork relaxes your body and calms your heart rate. Measure your heart rate to see the effects.",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 14 * SizeConfigs.textScale),
                                  ),
          
                                  const SizedBox(height: 16),
          
                                  /// Start Breathwork Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: AppColors.animationStartColor.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      onPressed: () {
                                        controller.resetBreathing(); // 🟩 reset before starting
                                        Get.toNamed(Routes.breathwork);
                                      },
                                      child: Text(
                                        context.lang.measureYourHeartRate,
                                        // "Measure Your Heart Rate",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.animationStartColor, fontSize: 16 * SizeConfigs.textScale),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // const SizedBox(height: 14),
          
                      // Secondary Button
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueLine,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {
                              Get.toNamed(Routes.sleepTracker);
                            },
                            child: Text(
                              context.lang.startSleep,
                              // "Start Sleep",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w200) ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
          
                return Column(

                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 45,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: controller.items.length,
                          itemBuilder: (context, i) {
                            final item = controller.items[i];

                            return Obx(
                                  () {
                                final isSelected = controller.selectedFilter.value == i;

                                return GestureDetector(
                                  onTap: () {
                                    controller.onSelectFilter(i);
                                    // Don't recreate the controller, just reset it
                                    lottieController.reset();
                                    if (controller.isPlaying.value) {
                                      lottieController.repeat();
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSelected ? 14 : 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF3A7CFF)
                                          : const Color(0xFF1C1F2E),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item["icon"] as IconData,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            item["label"].toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 12 * SizeConfigs.textScale,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
          
                    /// ----------------------------------------
                    /// ⏱ Timer Row
                    /// ----------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        controller.isPlaying.value
                            ? const SizedBox()
                            : SmallCircleIcon(size: 25, icon: Icons.remove, backgroundColor: Colors.white10, iconColor: Colors.white, onTap: controller.removeTime),
          
                        const SizedBox(width: 20),
          
                        Column(
                          children: [
                            Text(
                              formatTime(seconds),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blueLine, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              controller.isPlaying.value ? context.lang.remainingTime : context.lang.setTimer,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: controller.isPlaying.value ? Colors.white70 : AppColors.blueLine,
                                fontSize: 13 * SizeConfigs.textScale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
          
                        const SizedBox(width: 20),
          
                        controller.isPlaying.value ? const SizedBox() : SmallCircleIcon(size: 25, icon: Icons.add, backgroundColor: Colors.white10, iconColor: Colors.white, onTap: controller.addTime),
                      ],
                    ),
          
                    const SizedBox(height: 40),
          
                    /// ----------------------------------------
                    /// 🧘 Instruction
                    /// ----------------------------------------
                    Text(
                      controller.instruction.value,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    ),
          
                    const SizedBox(height: 5),
          
                    /// ----------------------------------------
                    /// 🔵 Breathing Animation
                    /// ----------------------------------------
                    SizedBox(
                      height: 345,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(2),
                        child: Center(
                          child: Lottie.asset(
                            controller.selectedFilter.value == 0 ? Assets.lottieBreathingAnimation :controller.selectedFilter.value == 1? Assets.lottieBoxBreathing:Assets.lottieBreathingLotus,
                            controller: lottieController,
                            onLoaded: (composition) {

                              lottieController
                                ..duration = composition.duration
                                ..stop();
                            },
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
          
                    const SizedBox(height: 3),
          
                    /// ----------------------------------------
                    /// ▶ Start / ⏸ Pause / ⏯ Resume
                    /// ----------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Obx(() {
                        // if (!controller.isPlaying.value && !controller.isPaused.value) {
                        //   return mainButton("Start", controller.startBreathing);
                        // }
                        if (!controller.isPlaying.value && !controller.isPaused.value) {
                          if (controller.countdown.value > 0) {
                            return mainButton("${controller.countdown.value}", () {},context);
                          }
          
                          return mainButton(context.lang.start, () {
                            controller.startCountdown();
                            // Lottie countdown (optional)
                          },context);
                        }
          
                        if (controller.isPaused.value) {
                          return mainButton(context.lang.resume, () {
                            controller.resumeBreathing();
                            lottieController.repeat(); // <-- RESUME animation
                          },context);
                        }
          
                        return mainButton(context.lang.pause, () {
                          lottieController.reset();
                          controller.pauseBreathing();
                          lottieController.stop(); // <-- PAUSE animation
                        },context);
                      }),
                    ),
                    GestureDetector(
                      onTap:(){controller.stopAllTimers();
                      Get.back();},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 48,
                          width: 80,
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                          child: Center(
                            child: Text(
                              context.lang.stop,
                              // "Stop",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

String formatTime(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return "$m:$s";
}

Widget mainButton(String label, VoidCallback onTap,BuildContext context) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E90FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
    ),
    onPressed: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label == context.lang.start) ...[const Icon(Icons.access_time, color: Colors.white), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    ),
  );
}

void showInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.70, // <--- FIXED HEIGHT
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  ),
                ),

                /// Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            context.lang.moreInformation,
                            // "More Information",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          context.lang.howExercise,
                          // "How to exercise?",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blueLine, fontSize: 18, fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 14),
                        _buildStep(Icons.self_improvement, "${context.lang.step} 1:", context.lang.sitComfortablePositionRelaxCompletely),
                        _buildStep(Icons.play_circle_fill, "${context.lang.step} 2:", context.lang.pressStartStayMoment),
                        _buildStep(Icons.air, "${context.lang.step} 3:", context.lang.breatheSyncOrbInhaleHoldExhale),
                        _buildStep(Icons.timer_outlined, "${context.lang.step} 4:", context.lang.gentlyGiveAllYourFocusYourBreath),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              context.lang.safetyNote,
                              // "Safety Note",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          context.lang.consultHealthcareProfessionalMedicalConditionsAsthmaAnxietyBeforeStartingBreathworkStopFeelDizzy,
                          // "Consult a healthcare professional if you have medical conditions like asthma or anxiety before starting breathwork. Stop if you feel dizzy.",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w300),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                /// Bottom Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E90FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      context.lang.gotIt,
                      // "Got It",
                      style: TextStyle(color: Colors.white, fontSize: 16 * SizeConfigs.textScale),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildStep(IconData icon, String step, String desc) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blueLine, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                desc,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
