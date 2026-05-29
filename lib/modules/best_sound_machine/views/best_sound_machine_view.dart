import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/colors.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/best_sound_machine_controller.dart';

class BestSoundMachineView extends GetView<BestSoundMachineController> {
  const BestSoundMachineView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ---------------- BACKGROUND ----------------
            Positioned.fill(
              child: Container(color: AppColors.background1),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Obx(() {
                  // 🔹 Background always visible
                  if (!controller.isVideoReady.value) {
                    return Container(
                      color: AppColors.background, // or AppColors.background
                    );
                  }
                  final video = controller.videoController;

                  return SizedBox.expand(
                    child: FittedBox(
                      // ✅ Use 'cover' to fill screen without stretching.
                      // It will crop slightly to maintain the perfect shape.
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: video.value.size.width,
                        height: video.value.size.height,
                        child: VideoPlayer(video),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedNextButton(
                  delay: Duration(seconds: 13),
                  onPressed: controller.goNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
