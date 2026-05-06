import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import '../../../core/constants/colors.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../controllers/free_trial_controller.dart';

class FreeTrialView extends GetView<FreeTrialController> {
  const FreeTrialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: Lottie.asset(Assets.lottieSleepReportBackground, fit: BoxFit.cover)),
          Center(
            child: Obx(
              () => animatedItem(
                visible: controller.step.value >= 1,
                child: Text.rich(
                  TextSpan(
                    children: [
                       TextSpan(text: "${context.lang.start} ",style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold),
                       ),
                      TextSpan(
                        text: "7",
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.starFillColor, fontSize: 35, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " days for free!"),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget animatedItem({required bool visible, required Widget child}) {
  return AnimatedScale(
    scale: visible ? 1.0 : 1.5, // 👈 BIG → SMALL
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
    child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: const Duration(milliseconds: 400), child: child),
  );
}
