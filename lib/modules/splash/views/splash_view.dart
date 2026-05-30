import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../generated/assets.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<SplashController>();
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    double textScale = width / 390;
    return Scaffold(
      body: Container(
        color: AppColors.splashBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.imagesSleepableLogo,
                width: width * 0.765,
                height: width * 0.765,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
