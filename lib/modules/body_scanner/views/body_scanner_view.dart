import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/colors.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/body_scanner_controller.dart';

//
class BodyScannerView extends GetView<BodyScannerController> {
  const BodyScannerView({super.key});

  @override
  Widget build(BuildContext context) {

    return
    Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [

            /// 🔥 FULLSCREEN VIDEO
            Positioned.fill(
              child: Obx(() {
                if (!controller.isVideoReady.value) {
                  return Container(
                    color: AppColors.background, // or AppColors.background
                  );
                }

                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: controller.videoControllers.value.size.width, height: controller.videoControllers.value.size.height, child: VideoPlayer(controller.videoControllers)),
                );
              }),
            ),

            /// 🔘 BUTTON
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedNextButton(onPressed: controller.goNext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
