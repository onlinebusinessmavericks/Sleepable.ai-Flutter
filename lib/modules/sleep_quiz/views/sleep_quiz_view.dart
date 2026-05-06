import '../../../localization/lang_extension.dart';
import '../controllers/sleep_quiz_controller.dart';

import '../../../core/utils/library.dart';

class SleepQuizView extends GetView<SleepQuizController> {
  const SleepQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      // ✅ PERFECT CENTER + BACK BUTTON
      body: SafeArea(
        child: Obx(() {
          final q = controller.questions[controller.currentIndex.value];
          final selected = controller.answers[q.key];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${controller.currentIndex.value + 1}",
                        style: const TextStyle(
                          fontSize: 22, // 👈 BIG
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: "/${controller.total}",
                        style: const TextStyle(
                          fontSize: 14, // 👈 small
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Obx(() {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: controller.animatedProgress.value),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(value: value, minHeight: 6, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(AppColors.accentColor));
                    },
                  ),
                );
              }),

              const SizedBox(height: 28),

              // 🔹 Question
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  q.question,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 26 * SizeConfigs.textScale, fontWeight: FontWeight.w500, fontFamily: 'Coolvetica'),

                  //style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 YES
              _answerTile(context, emoji: "🤔", text: lang.yesLabel, isSelected: selected == "yes", onTap: () => controller.selectAnswer("yes")),

              // 🔹 NO
              _answerTile(context, emoji: "🤗", text: lang.noLabel, isSelected: selected == "no", onTap: () => controller.selectAnswer("no")),

              const Spacer(),

              // 🔹 Bottom Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: _bottomButton(text: lang.previous, enabled: true, onTap: controller.previous, isPrimary: false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _bottomButton(
                          text: controller.isLast ? lang.finish : lang.next,
                        // text: controller.isLast ? "Finish" : "Next",
                          enabled: controller.hasAnswer, onTap: controller.next, isPrimary: true),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ================= Widgets =================

  Widget _answerTile(BuildContext context, {required String emoji, required String text, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(color: isSelected ? AppColors.accentColor : AppColors.card, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Text(
                emoji,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 17 * SizeConfigs.textScale, fontWeight: FontWeight.w100, overflow: TextOverflow.ellipsis),
                // style: const TextStyle(fontSize: 24)
              ),
              const SizedBox(width: 14),
              Text(text,
                  // style: const TextStyle(color: Colors.white, fontSize: 18)
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 17 * SizeConfigs.textScale,
                fontWeight: FontWeight.w100,
                overflow: TextOverflow.ellipsis,
              ),
              ),
              // const Spacer(),
              // if (isSelected)
              //   const Icon(Icons.check_circle,
              //       color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton({required String text, required bool enabled, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: enabled ? (isPrimary ? AppColors.accentColor : Colors.white24) : Colors.white10),
        child: Text(
          text,
          // style: const TextStyle(color: Colors.white, fontSize: 18)
          style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontSize: 18, fontWeight: enabled ? FontWeight.w600 : FontWeight.w200),
        ),
      ),
    );
  }
}
