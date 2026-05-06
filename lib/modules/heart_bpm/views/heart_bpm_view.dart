import 'package:sleepable_ai/core/utils/library.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../breathwork/controllers/breathwork_controller.dart';
import '../../breathwork/views/breathwork_view.dart';
import '../../music/views/music_view.dart';
import '../controllers/heart_bpm_controller.dart';
import 'package:camera/camera.dart';


class HeartBPMView extends StatefulWidget {
  const HeartBPMView({super.key});

  @override
  State<HeartBPMView> createState() => _HeartBPMViewState();
}

class _HeartBPMViewState extends State<HeartBPMView> with TickerProviderStateMixin {
  late AnimationController _cardAnim;
  late AnimationController _textAnim;
  late AnimationController _buttonAnim;

  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Card animation
    _cardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));

    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeIn);

    // Stress text animation
    _textAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _textAnim, curve: Curves.easeOut));

    _textFade = CurvedAnimation(parent: _textAnim, curve: Curves.easeIn);

    // Button text animation
    _buttonAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _buttonAnim, curve: Curves.easeOut));

    _buttonFade = CurvedAnimation(parent: _buttonAnim, curve: Curves.easeIn);

    final c = Get.find<HeartBPMController>();

    // Trigger animations when measurement finishes
    ever(c.showSaveButton, (value) async {
      if (value == true) {
        await Future.delayed(const Duration(seconds: 1));
        _textAnim.forward();

        await Future.delayed(const Duration(seconds: 1));
        _cardAnim.forward();

        await Future.delayed(const Duration(seconds: 1));
        _buttonAnim.forward();
      } else {
        _cardAnim.reset();
        _textAnim.reset();
        _buttonAnim.reset();
      }
    });
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _buttonAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HeartBPMController c = Get.find();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
               SizedBox(height: 20 * SizeConfigs.paddingScale),

              /// 🔹 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
                    Text(
                     context.lang.heartRate,
                      // "Heart Rate",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => showInfoSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                        child: const Icon(Icons.info_outline, size: 18, color: Colors.white),
                      ),
                    ),

                  ],
                ),
              ),
              SizedBox(height: 16 * SizeConfigs.paddingScale),


              /// 🔹 MEASUREMENT TITLE
              Obx(
                () => c.fingerOn.value
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(Assets.iconsMeasurementIcon, width: 30, height: 30, color: AppColors.removeButton),
                            const SizedBox(width: 10),
                            Text(
                              context.lang.measuring,
                              // "Measuring...",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w300) ?? const TextStyle(),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),

              /// 🔹 CAMERA + BPM CIRCLE
              Center(
                child: Obx(() {
                  if (!c.showSaveButton.value && (!c.isCameraReady.value || c.cameraController == null || !c.cameraController!.value.isInitialized)) {
                    return const Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator());
                  }

                  final controller = c.cameraController!;
                  return SizedBox(
                    height: 280* SizeConfigs.paddingScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        /// Circular animation
                        Obx(() {
                          final fingerOn = c.fingerOn.value;
                          final finished = c.showSaveButton.value;

                          // If finger is not on the camera → hide arc & reset progress
                          if (!fingerOn) {
                            c.previousProgress.value = 0.0;
                            return const SizedBox();
                          }
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 350),
                            tween: Tween(begin: c.previousProgress.value, end: c.progress.value),
                            builder: (_, value, __) {
                              final progress = finished ? 1.0 : value;

                              // Decide arc color using BPM + AGE
                              final arcColor = c.getArcColor(
                                finished ? c.finalBpm.value : c.bpm.value,
                                30,
                              );

                              return SizedBox(
                                width: 270* SizeConfigs.paddingScale,
                                height: 270* SizeConfigs.paddingScale,
                                child: CustomPaint(
                                  painter: RoundedArcPainter(
                                    progress: progress,
                                    color: arcColor,   // ← dynamic color
                                    strokeWidth: 12,
                                  ),
                                ),
                              );
                            },
                            onEnd: () => c.previousProgress.value = c.progress.value,
                          );

                        }),

                        /// Inner camera + BPM
                        Obx(() {
                          final finished = c.showSaveButton.value;

                          return ClipOval(
                            child: Container(
                              width: 255* SizeConfigs.paddingScale,
                              height: 255* SizeConfigs.paddingScale,
                              color: finished ? Colors.red.withOpacity(0.15) : Colors.transparent,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (!finished && controller.value.isInitialized)
                                    OverflowBox(
                                      maxWidth: double.infinity,
                                      maxHeight: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(width: 255, height: 255, child: CameraPreview(controller)),
                                      ),
                                    ),

                                  /// BPM + Animation
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        finished
                                            ? "${c.finalBpm.value}" // After measurement complete
                                            : (c.fingerOn.value
                                                  ? "${c.bpm.value}" // Finger ON → live BPM
                                                  : "0"),
                                        // finished ? "${c.finalBpm.value}" : "${c.bpm.value}",
                                        style: TextStyle(fontSize: finished ? 70 : 60, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Lottie.asset(Assets.lottieHeart, repeat: true, width: 60 * SizeConfigs.paddingScale, height: 60 * SizeConfigs.paddingScale),
                                          Text(
                                            context.lang.bpm,
                                            // "bpm",
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.w200),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: 12 * SizeConfigs.paddingScale),
              // const SizedBox(height: 20),
              // Obx(
              //   () => c.showSaveButton.value
              //       ? FadeTransition(
              //           opacity: _textFade,
              //           child: SlideTransition(
              //             position: _textSlide,
              //             child: Padding(
              //               padding:  EdgeInsets.only(top: 12* SizeConfigs.paddingScale, left: 20* SizeConfigs.paddingScale, right: 20* SizeConfigs.paddingScale, bottom: 20* SizeConfigs.paddingScale),
              //               child: Text(
              //                 c.getAgeBasedMessage(c.finalBpm.value,30),
              //                // "${c.finalBpm.value} Suggests stress or anxiety; might result in restless or lighter sleep.",
              //                 textAlign: TextAlign.center,
              //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
              //               ),
              //             ),
              //           ),
              //         )
              //       : const SizedBox(),
              // ),
              Obx(
                    () => c.showSaveButton.value
                    ? FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 12 * SizeConfigs.paddingScale,
                        left: 20 * SizeConfigs.paddingScale,
                        right: 20 * SizeConfigs.paddingScale,
                        bottom: 20 * SizeConfigs.paddingScale,
                      ),
                      child: Text(
                        c.ageBasedMessage.value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          color: Colors.white70,
                          fontSize: 14 * SizeConfigs.textScale,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(),
              ),


              /// 🔹 CALM HEART RATE CARD
              Obx(
                () => c.showSaveButton.value
                    ?
                FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Padding(
                            padding:  EdgeInsets.symmetric(horizontal: 18* SizeConfigs.paddingScale),
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
                                      Image.asset(Assets.homeSleepableAppIcon, height: 20* SizeConfigs.paddingScale, width: 20* SizeConfigs.paddingScale),
                                      const SizedBox(width: 10),
                                      Text(
                                        context.lang.calmYourHeartRate,
                                        // "Calm Your Heart Rate",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    textAlign: TextAlign.center,
                                    context.lang.heartElevatedDescription,
                                    // "Your heart is elevated. Let's slow it down with gentle breathing to prepare your body for sleep.",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.animationStartColor.withOpacity(0.2),
                                        // padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      onPressed: (){
                                        Get.put(BreathworkController());
                                        Get.to(
                                              () => BreathworkView(),
                                          transition: Transition.fadeIn,
                                          duration: const Duration(milliseconds: 100),
                                        );

                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                        Lottie.asset(Assets.lottieBreathingExercise, repeat: true, width: 60 * SizeConfigs.paddingScale, height: 60 * SizeConfigs.paddingScale, fit: BoxFit.contain),
                                          const SizedBox(width: 6),
                                          Text(
                                            context.lang.startBreathwork,
                                            // "Start Breathwork",
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.animationStartColor, fontSize: 16 * SizeConfigs.textScale),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),

              /// 🔹 FOOTNOTE
              Obx(
                () => c.showSaveButton.value
                    ? SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: Text(
                          context.lang.fingerFlashlightInstruction,
                          // "Put finger on the flashlight and cover the back camera",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                        ),
                      ),
              ),

               SizedBox(height: 20* SizeConfigs.paddingScale),

              /// 🔹 START SLEEP BUTTON
              Obx(
                () => c.showSaveButton.value
                    ?    FadeTransition(
                  opacity: _buttonFade,
                  child: SlideTransition(
                      position: _buttonSlide,
                      child:Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 20* SizeConfigs.paddingScale),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E90FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () => Get.toNamed(Routes.sleepTracker),
                            child: Text(
                              context.lang.startSleep,
                              // "Start Sleep",
                              style: TextStyle(color: Colors.white, fontSize: 16 * SizeConfigs.textScale),
                            ),
                          ),
                        ),
                      )))
                    : const SizedBox(),
              ),

               SizedBox(height: 30* SizeConfigs.paddingScale),
            ],
          ),
        ),
      ),
    );
  }
}

class RoundedArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;
  final double strokeWidth;

  RoundedArcPainter({required this.progress, required this.color, this.strokeWidth = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -90 * 3.1415926535 / 180; // start at top
    final sweepAngle = 2 * 3.1415926535 * progress;

    final paintBg = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintArc = Paint()
      ..color = progress > 0 ? color : Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Draw full background circle
    canvas.drawArc(rect, 0, 6.28318, false, paintBg);

    // Draw progress arc only if > 0
    if (progress > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintArc);
    }
    // else do nothing → no red dot at 0
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
void showInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
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
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          context.lang.howToMeasure,
                          // "How to measure?",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildStep(Icons.touch_app, "${context.lang.step} 1:", context.lang.placeFingertipOverCamera),
                        _buildStep(Icons.camera, "${context.lang.step} 2:", context.lang.coverLensFully),
                        _buildStep(Icons.favorite, "${context.lang.step} 3:", context.lang.automaticMeasurementStart),
                        _buildStep(Icons.timer, "${context.lang.step} 4:", context.lang.keepFingerSteady),

                        const SizedBox(height: 25),

                        Text(
                          context.lang.disclaimer,
                          // "Disclaimer",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          context.lang.ppgMethodDescription,
                          // "This feature uses the PPG method to estimate your heart rate and HRV. "
                          //     "It's designed for general wellness and not meant for medical use.",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
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
        Icon(icon, color: Colors.lightBlueAccent, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
