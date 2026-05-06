import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/colors.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../controllers/boot_up_controller.dart';

class BootUpView extends GetView<BootUpController> {
  const BootUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (!controller.isVideoReady.value) {
          return Container(
            color: AppColors.background,
          );
        }

        final video = controller.videoController;

        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover, // 🔥 FULL WIDTH (crop if needed)
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          ),
        );
      }),

    );
  }
}

