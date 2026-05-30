import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:sleepable_ai/widgets/custom_loader.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../heart_bpm/views/heart_bpm_view.dart';
import '../../music/views/music_view.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../controllers/heart_bpm_measurement_controller.dart';

class HeartBpmMeasurementView extends GetView<HeartBpmMeasurementController> {
  const HeartBpmMeasurementView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body:  SafeArea(

        child: Obx(
          () => Stack(
            children: [
              /// 🟢 MAIN UI
              buildMainContent(context),

              /// 🔴 FULL SCREEN LOADER
              if (controller.isLoading.value)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5), // dim background
                    child: const Center(child: LoaderWidget(size: 120)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Column buildMainContent(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16 * SizeConfigs.paddingScale),

        // 🔹 Header Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
              Text(
                context.lang.heartRate,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
              ),
              GestureDetector(
                onTap: () => showInfoSheet(context),
                child: Container(
                  padding: EdgeInsets.all(8 * SizeConfigs.paddingScale),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                  child: const Icon(Icons.info_outline, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 40 * SizeConfigs.paddingScale),

        // 🔹 Get Ready
        Text(
          context.lang.getReady,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blueLine, fontSize: 17 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
        ),

        SizedBox(height: 12 * SizeConfigs.paddingScale),

        // 🔹 Title Text
        Text(
          "${context.lang.getThemMostOut}\n${context.lang.ofYourSleep}",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
        ),

        const Spacer(),

        // 🔹 Heart Rate Circle
        Stack(
          alignment: Alignment.center,
          children: [
            // 🔵 Circular Image
            Container(
              width: 200 * SizeConfigs.paddingScale,
              height: 200 * SizeConfigs.paddingScale,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              // REQUIRED for rounding!
              child: Image.asset(Assets.homeBpmPhone, fit: BoxFit.cover),
            ),

            // 🔵 Radial Glow on Top
            Container(
              width: 200 * SizeConfigs.paddingScale,
              height: 200 * SizeConfigs.paddingScale,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x33808000), Color(0x66000000)], center: Alignment.center, radius: 0.85),
              ),
            ),
          ],
        ),

        const Spacer(),

        // 🔹 Description
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30 * SizeConfigs.paddingScale),
          child: Text(

            "${context.lang.monitoringYourHeartRateBeforeSleepHelps} "
            "${context.lang.identifyStressLevelsImproveSleepQualityAnd} "
            "${context.lang.optimizeOverallHealth}",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w200) ?? const TextStyle(),
          ),
        ),

        SizedBox(height: 60 * SizeConfigs.paddingScale),

        // 🔹 Buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16 * SizeConfigs.paddingScale),
          child: Column(
            children: [
              Column(
                children: [
                  _buildAnimatedButtonHeartRate(
                    text: context.lang.measureHeartRate, //"Measure Heart Rate",
                    color: const Color(0xFF1E90FF),
                    controller: controller,
                    onTap: () => controller.goToNextScreen(),
                  ),

                  SizedBox(height: 14 * SizeConfigs.paddingScale),

                  _buildAnimatedButtonMeasuring(
                    text: context.lang.startWithoutMeasuring,
                    color: Colors.white12,
                    controller: controller,
                    onTap: () => controller.startWithoutMeasuring(),
                    isSecondary: true,
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
Widget _buildAnimatedButtonHeartRate({
  required String text,
  required Color color,
  required VoidCallback onTap,
  required dynamic controller,
  bool isSecondary = false,
}) {
  return Obx(() => GestureDetector(
    // 1. 🔥 THE PRESS: Vibrate and Sink down immediately
    onTapDown: (_) {
      Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true); // Mimics a real button click
      controller.updateScaleHeartRate(0.92); // Deep sink for better feedback
    },

    // 2. 🚀 THE RELEASE: Pop up and go to the next screen
    onTapUp: (_) {
      controller.updateScaleHeartRate(1.0);
      onTap();
    },

    // 3. 🛡️ THE SAFETY: Return to normal if the user slides their finger away
    onTapCancel: () => controller.updateScaleHeartRate(1.0),

    child: AnimatedScale(
      scale: controller.scaleHeartRate.value,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16 * SizeConfigs.paddingScale),
        decoration: BoxDecoration(
          color: color, // Set the background color here
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSecondary ? [] : [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSecondary ? Colors.white70 : Colors.white,
              fontSize: 16 * SizeConfigs.textScale,
              fontWeight: FontWeight.w600, // Semi-bold looks more professional
            ),
          ),
        ),
      ),
    ),
  ));
}
Widget _buildAnimatedButtonMeasuring({
  required String text,
  required Color color,
  required VoidCallback onTap,
  required dynamic controller,
  bool isSecondary = false,
}) {
  return Obx(() => GestureDetector(
    // 1. 🔥 THE SINK: Triggered the millisecond your finger touches the glass
    onTapDown: (_) {
      Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true); // Instant "click" feel
      controller.updateScaleMeasuring(0.92); // Sinks deeper (92%) for better feel
    },

    // 2. 🚀 THE ACTION: Triggered only when you lift your finger
    onTapUp: (_) {
      controller.updateScaleMeasuring(1.0); // Pops back up
      onTap(); // Go to next screen
    },

    // 3. 🛡️ THE CANCEL: If the user slides their finger off the button
    onTapCancel: () => controller.updateScaleMeasuring(1.0),

    child: AnimatedScale(
      scale: controller.scaleMeasuring.value,
      duration: const Duration(milliseconds: 100), // Snappy response
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16 * SizeConfigs.paddingScale),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSecondary ? [] : [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSecondary ? Colors.white70 : Colors.white,
              fontSize: 16 * SizeConfigs.textScale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  ));
}