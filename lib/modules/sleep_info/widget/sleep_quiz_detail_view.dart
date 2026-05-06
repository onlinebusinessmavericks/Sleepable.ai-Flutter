import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/modules/sleep_info/controllers/sleep_info_controller.dart';

import '../../../core/utils/library.dart';
import '../../../localization/lang_extension.dart';
import '../../music/views/music_view.dart';

class SleepQuizDetailView extends StatelessWidget {
  final Map<String, dynamic> data;

  const SleepQuizDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SleepInfoController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: SmallCircleIcon(
            icon: Icons.arrow_back_rounded,
            size: 20 * SizeConfigs.textScale,
            iconColor: Colors.white,
            backgroundColor: Colors.white10,
            onTap: () => Get.back(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
          child: Text(
            "Sleepable",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 21 * SizeConfigs.textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              10,
              22,
              120, // space for button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Header Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    data['image'],
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 22),

                // 🔹 Title
                Text(
                  data['title'] ?? context.lang.understandSleepBetter,

                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Highlights

                Row(
                  children: [
                    // _checkItem("Quick & simple questions"),
                    // const SizedBox(width: 20),
                    // _checkItem("Built with sleep science"),
                    _checkItem(context.lang.quickSimpleQuestions),
                    const SizedBox(width: 20),
                    _checkItem(context.lang.builtWithSleepScience),
                  ],
                ),


                const SizedBox(height: 18),

                // 🔹 Description
                Text(
                  data['description'] ??
                      context.lang.quizTheoryDesc,// "Sleep plays a vital role in your physical and mental well-being. This short questionnaire helps you reflect on your sleep habits and uncover patterns that may be affecting your rest, energy, and daily performance.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70, height: 1.6),
                ),

                const SizedBox(height: 26),

                // 🔹 What you'll gain
                Text(
                  context.lang.whatYouWillGain,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),
                _gainItem(
                  title: context.lang.sleepOverviewTitle,
                  desc: context.lang.sleepOverviewDesc,
                ),

                _gainItem(
                  title: context.lang.personalInsightsTitle,
                  desc: context.lang.personalInsightsDesc,
                ),

                _gainItem(
                  title: context.lang.actionableGuidanceTitle,
                  desc: context.lang.actionableGuidanceDesc,
                ),
                // _gainItem(
                //   title: "Sleep overview",
                //   desc:
                //   "Get a clear snapshot of your current sleep patterns and potential areas of concern.",
                // ),
                //
                // _gainItem(
                //   title: "Personal insights",
                //   desc:
                //   "Understand how your sleep habits may influence focus, mood, and recovery.",
                // ),
                //
                // _gainItem(
                //   title: "Actionable guidance",
                //   desc:
                //   "Receive practical suggestions to help you improve sleep quality and consistency.",
                // ),

                const SizedBox(height: 26),

                // 🔹 Theoretical Background
                Text(
                  context.lang.theoreticalBackground,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  context.lang.quizTheoryDesc,//"Based on established sleep research and behavioral science, this assessment is designed to encourage early awareness of sleep-related challenges and promote healthier sleep routines through informed decision-making.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70, height: 1.6),
                ),
              ],
            ),
          ),

          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Obx(() {
              // 1. Determine which quiz we are looking at
              String quizType = data['title'] == 'Night Breathing & Rest Check'
                  ? 'night_breathing'
                  : 'sleep_patterns';

              // 2. Check if we already have a saved result for this quiz
              String savedResult = getStringAsync('quiz_result_$quizType');
              bool hasCompleted = savedResult.isNotEmpty;

              return GestureDetector(
                onTapDown: (_) => controller.updateScale(0.94),
                onTapUp: (_) => controller.updateScale(1.0),
                onTapCancel: () => controller.updateScale(1.0),
                child: AnimatedScale(
                  scale: controller.buttonScale.value,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Haptics.vibrate(HapticsType.light, useAndroidHapticConstants: true);

                        if (hasCompleted) {
                          // 🔥 If completed, skip the quiz and pass the saved data directly to the result screen
                          Get.toNamed(Routes.sleepQuizResult, arguments: {
                            'saved_data': jsonDecode(savedResult),
                            'quiz_type': quizType
                          });
                        } else {
                          // 🔥 If not completed, start the quiz normally
                          Get.toNamed(Routes.sleepQuiz, arguments: {'quizTitle': data['title']});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCompleted ? Colors.green : AppColors.accentColor, // Turn green if done!
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        hasCompleted ? context.lang.viewResults : context.lang.startQuiz,
                        // hasCompleted ? "View Results" : "Start Quiz", // Dynamic Text
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= Components =================

  Widget _checkItem(String text) {
    return Flexible(
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gainItem({required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
