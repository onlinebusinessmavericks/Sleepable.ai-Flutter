import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../core/constants/colors.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/sleep_report_controller.dart';

class SleepReportView extends GetView<SleepReportController> {
  const SleepReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ---------------- BACKGROUND ----------------
          Positioned.fill(
            child: Lottie.asset(
              Assets.lottieSleepReportBackground,
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),

          // ---------------- FOREGROUND ----------------
          Column(
            children: [
              const SizedBox(height: 80),

              // --------- Title ---------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.lang.creatingYourSleepReport,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              // --------- CENTER AREA ---------
                Center(
                  child:
                  sleepProgressCircle(context), // 🎯 PERFECT CENTER
                ),

              const SizedBox(height: 80),
              // --------- Bottom Content ---------
              Image.asset(
                Assets.homeSleepableTextLogo,
                height: 29,
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.lang.sleepableAiHasProvenBestSleepingApp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 15),
                ),
              ),

              const SizedBox(height: 30),
             // AnimatedNextButton(
             //    onPressed: controller.goNext,
             //  ),
              Obx(() {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 800), // Fade speed
                  opacity: controller.isCompleted.value ? 1.0 : 0.0,
                  child: controller.isCompleted.value
                      ? AnimatedNextButton(onPressed: controller.goNext)
                      : const SizedBox(height: 50), // Space maintain rakhega taaki UI jump na kare
                );
              }),

              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );

  }
}
Widget sleepProgressCircle(BuildContext context) {
  final controller = Get.find<SleepReportController>();
  final size = MediaQuery.of(context).size;
  final double circleSize = size.width * 0.38;

  return Obx(() {
    final percent = (controller.progress.value * 100).toInt();

    return Container(
      width: circleSize,
      height: circleSize,
      // color: Colors.red, // debug only
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: circleSize,
            height: circleSize,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation(
                Colors.grey.withOpacity(0.25),
              ),
            ),
          ),

          // Animated progress ring
          SizedBox(
            width: circleSize,
            height: circleSize,
            child: CircularProgressIndicator(
              value: controller.progress.value,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF2F8CFF),
              ),
            ),
          ),

          // Center text
          Text(
            "$percent%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  });
}
