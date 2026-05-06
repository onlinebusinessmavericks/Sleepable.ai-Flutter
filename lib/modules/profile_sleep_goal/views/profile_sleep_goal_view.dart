
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/custom_loader.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/profile_sleep_goal_controller.dart';

class ProfileSleepGoalScreen extends StatelessWidget {
  final controller = Get.put(ProfileSleepGoalController());
  final profileCtrl = Get.find<ProfileController>();

  ProfileSleepGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

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
            child: Obx(() => IconButton(
              // Loading ke waqt back button disable
              onPressed: controller.isSaving.value ? null : () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white10,
                shape: const CircleBorder(),
              ),
            )),
          ),
        ),
        title: Text(
          context.lang.sleepGoal,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 21 * SizeConfigs.textScale,
              fontWeight: FontWeight.w500
          ),
        ),
        centerTitle: true,
      ),

      // 🔥 Full Screen Loader ke liye Stack aur Obx ka use
      body: Obx(() => Stack(
        children: [
          // MAIN CONTENT
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// ===== Circular Sleep Ring =====
                      _buildCircularGauge(context),

                      const SizedBox(height: 30),

                      /// ===== Bedtime & Wakeup Card =====
                      _buildTimeSelectionCards(context),
                    ],
                  ),
                ),
              ),

              /// ===== Save Button =====
              _buildSaveButton(context),
            ],
          ),

          // 🔥 LOADING OVERLAY
          if (controller.isSaving.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoaderWidget(size: 150), // Aapka custom loader
                ),
              ),
            ),
        ],
      )),
    );
  }

  Widget _buildCircularGauge(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: SfRadialGauge(
        axes: [
          RadialAxis(
            minimum: 0,
            maximum: 24,
            startAngle: 270,
            endAngle: 270,
            showLabels: false,
            showTicks: true,
            interval: 1,
            minorTicksPerInterval: 3,
            axisLineStyle: const AxisLineStyle(
              thickness: 0.18,
              thicknessUnit: GaugeSizeUnit.factor,
              color: Color(0xFF2A2F3A),
            ),
            ranges: [
              GaugeRange(
                startValue: controller.liveBed.value,
                endValue: controller.liveWake.value < controller.liveBed.value
                    ? 24
                    : controller.liveWake.value,
                startWidth: 0.18,
                endWidth: 0.18,
                sizeUnit: GaugeSizeUnit.factor,
                gradient: const SweepGradient(
                  colors: [Color(0xFF7B6DFF), Color(0xFF5F9CFF)],
                ),
              ),
              if (controller.liveWake.value < controller.liveBed.value)
                GaugeRange(
                  startValue: 0,
                  endValue: controller.liveWake.value,
                  startWidth: 0.18,
                  endWidth: 0.18,
                  sizeUnit: GaugeSizeUnit.factor,
                  gradient: const SweepGradient(
                    colors: [Color(0xFF5F9CFF), Color(0xFFFFC107)],
                  ),
                ),
            ],
            pointers: [
              MarkerPointer(
                value: controller.liveBed.value,
                enableDragging: !controller.isSaving.value, // Loading pe drag band
                markerType: MarkerType.image,
                imageUrl: Assets.homeMoon,
                markerHeight: 30, markerWidth: 30,
                onValueChanging: (args) {
                  final snapped = controller.snap(args.value) % 24;
                  args.value = snapped;
                  controller.liveBed.value = snapped;
                  if (controller.shouldHaptic(snapped)) HapticFeedback.selectionClick();
                },
                onValueChangeEnd: (v) => controller.bedTime.value = controller.liveBed.value,
              ),
              MarkerPointer(
                value: controller.liveWake.value,
                enableDragging: !controller.isSaving.value, // Loading pe drag band
                markerType: MarkerType.image,
                imageUrl: Assets.homeSun,
                markerHeight: 30, markerWidth: 30,
                onValueChanging: (args) {
                  final snapped = controller.snap(args.value) % 24;
                  args.value = snapped;
                  controller.liveWake.value = snapped;
                  if (controller.shouldHaptic(snapped)) HapticFeedback.selectionClick();
                },
                onValueChangeEnd: (v) => controller.wakeUpTime.value = controller.liveWake.value,
              ),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Text(
                  controller.liveDuration,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                positionFactor: 0.0,
              ),
              for (int i = 0; i < 24; i += 3)
                GaugeAnnotation(
                  widget: Text(
                    i == 0 ? "24" : i.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(i % 6 == 0 ? 0.9 : 0.5),
                      fontSize: i % 6 == 0 ? 14 : 12,
                      fontWeight: i % 6 == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  angle: (i * 15) - 90,
                  positionFactor: 0.68,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF0E1A2B), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _timeTile(
              context,
              icon: Icons.nightlight_round,
              iconColor: const Color(0xFF7B6DFF),
              title: context.lang.bedtime,
              subtitle: context.lang.bedtimeSub,
              time: controller.formatTime(controller.bedTime.value),
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            _timeTile(
              context,
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFFFC107),
              title: context.lang.wakeUpTime,
              subtitle: context.lang.wakeUpTimeSub,
              time: controller.formatTime(controller.wakeUpTime.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: controller.isSaving.value
              ? null
              : () {
            if (profileCtrl.settings.value != null) {
              controller.saveSleepGoal(profileCtrl.settings.value!);
            } else {
              Get.snackbar(context.lang.errorLabel,
                context.lang.errorSettingsNotLoaded,);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F8DFF),
            disabledBackgroundColor: const Color(0xFF4F8DFF).withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: Text(
            context.lang.save,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeTile(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String subtitle, required String time}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16 * SizeConfigs.textScale,
                      fontWeight: FontWeight.w600
                  ) ?? const TextStyle(),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 13 * SizeConfigs.textScale
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 16 * SizeConfigs.textScale,
                fontWeight: FontWeight.w600
            ) ?? const TextStyle(),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}