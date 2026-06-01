import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../localization/language_controller.dart';
import '../controllers/welcome_controller.dart';

class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);
    final languageController = Get.find<LanguageController>();
    return Scaffold(
      body:
          // SafeArea(
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  /// -------- BACKGROUND --------
                  Positioned.fill(child: Image.asset(Assets.homeWelcomeImage, fit: BoxFit.cover)),

                  /// -------- CONTENT --------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfigs.hp(0.28)),

                      /// -------- LOTTIE TITLE --------
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfigs.wp(0.06)),
                        child: Lottie.asset(Assets.lottieWelcome, width: SizeConfigs.wp(0.5), fit: BoxFit.contain, repeat: true),
                      ),

                      SizedBox(height: SizeConfigs.hp(0.02)),

                      /// -------- SUBTITLE --------
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfigs.wp(0.08)),
                        child: Text(
                          "${context.lang.letStartFindingOutYou}\n${context.lang.haveProblemWithSleep}",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18 * SizeConfigs.text, fontWeight: FontWeight.bold, color: AppColors.white.withOpacity(0.9)),
                        ),
                      ),

                      SizedBox(height: SizeConfigs.hp(0.04)),

                      /// -------- STARS --------
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfigs.wp(0.00)),
                        child: Lottie.asset(Assets.lottieRating2, width: SizeConfigs.wp(0.55), fit: BoxFit.contain),
                      ),

                      const Spacer(),

                      /// -------- START BUTTON --------
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfigs.wp(0.06)),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Obx(
                            () => GestureDetector(
                              // 1. PRESS DOWN: Make this almost instant (50-80ms)
                              onTapDown: (_) {
                                controller.buttonScale.value = 0.92;
                                Haptics.vibrate(HapticsType.light, useAndroidHapticConstants: true);
                              },
                              // 2. RELEASE: Snap back with a bounce
                              onTapUp: (_) => controller.buttonScale.value = 1.0,
                              onTapCancel: () => controller.buttonScale.value = 1.0,

                              onTap: () async {
                                // 3. TRIGGER: Delay slightly so the user sees the button pop back up
                                await Future.delayed(const Duration(milliseconds: 120));
                                controller.onStartPressed();
                              },

                              child: AnimatedScale(
                                scale: controller.buttonScale.value,
                                // Fast duration makes it feel reactive
                                duration: const Duration(milliseconds: 120),
                                // easeOutBack gives that tiny "pop" at the end
                                curve: Curves.easeOutBack,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  margin: EdgeInsets.only(bottom: SizeConfigs.hp(0.13)),
                                  padding: EdgeInsets.symmetric(horizontal: SizeConfigs.wp(0.06), vertical: SizeConfigs.hp(0.018)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(40 * SizeConfigs.radius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        // Shadow gets smaller/tighter when button is pressed
                                        blurRadius: controller.buttonScale.value < 1.0 ? 4 : 12,
                                        spreadRadius: controller.buttonScale.value < 1.0 ? 0 : 2,
                                        offset: controller.buttonScale.value < 1.0 ? const Offset(0, 2) : const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.lang.startQuiz,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18 * SizeConfigs.text, fontWeight: FontWeight.bold, color: AppColors.background),
                                      ),
                                      SizedBox(width: SizeConfigs.wp(0.025)),
                                      // The Arrow Icon Circle
                                      Container(
                                        height: SizeConfigs.wp(0.07),
                                        width: SizeConfigs.wp(0.07),
                                        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: SizeConfigs.wp(0.05),
                    child: Obx(() {
                      // Current selected language code fetch kiya
                      final currentLangCode = languageController.locale.value.languageCode;

                      return Container(
                        // padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        padding: const EdgeInsets.only(left: 4, right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15), // Glassmorphic translucent effect
                          borderRadius: BorderRadius.circular(20 * SizeConfigs.radius),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLangCode,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                            dropdownColor: const Color(0xFF1A1A2E),
                            // Dropdown menu open hone par dark background
                            style: TextStyle(color: Colors.white, fontSize: 14 * SizeConfigs.text, fontWeight: FontWeight.w600),
                            alignment: Alignment.centerRight,
                            borderRadius: BorderRadius.circular(16),
                            onChanged: (String? newLanguageCode) {
                              if (newLanguageCode != null) {
                                Haptics.vibrate(HapticsType.selection);
                                languageController.changeLanguage(newLanguageCode);
                              }
                            },
                            items: languageController.languages.map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item.code,
                                child: Row(
                                  children: [
                                    const Icon(Icons.language, size: 16, color: Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(item.name, style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
      // ),
    );
  }
}

class SizeConfigs {
  static late double w;
  static late double h;
  static late double text;
  static late double radius;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    w = size.width;
    h = size.height;

    // Base design: iPhone 12 (390 × 844)
    text = (w / 390).clamp(0.85, 1.2);
    radius = (w / 390).clamp(0.8, 1.3);
  }

  static double wp(double percent) => w * percent;

  static double hp(double percent) => h * percent;
}
