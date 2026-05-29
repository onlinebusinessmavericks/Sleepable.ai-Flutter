import 'dart:async';
import 'package:get/get.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';

import '../../../core/utils/library.dart';

class BreathworkController extends GetxController {
  // Timer Settings
  RxInt totalSeconds = 96.obs; // User-selected duration
  RxInt remainingSeconds = 96.obs; // Live countdown timer

  // States
  RxBool isPlaying = false.obs;
  RxBool isPaused = false.obs;

  // UI Text
  RxString instruction = "${Get.context?.lang.pressStartBegin}\n${Get.context?.lang.breathingExercise}".obs;

  // Lottie + UI countdown
  RxInt countdown = 0.obs;

  Timer? timer;
  int initialSeconds = 96;
  RxInt instructionStep = 0.obs; // 0 = inhale, 1 = hold, 2 = exhale
  Timer? instructionTimer;
  RxInt instructionRemaining = 4.obs;
  RxInt selectedFilter = 0.obs;

  final items = [
    {"label": Get.context?.lang.goldStandard ?? "Gold Standard (4–7–8)", "icon": Icons.star_rounded},
    {"label": Get.context?.lang.boxBreathing ??"Box Breathing (4-4-4-4)", "icon": Icons.crop_square_rounded},
    {"label": Get.context?.lang.slowBreathing ??"Slow Breathing (6–0–8)", "icon": Icons.circle_outlined},
  ];

  // ============================================================
  // 1) 3..2..1 Countdown Before Start
  // ============================================================

  Future<void> startCountdown() async {
    if (isPlaying.value) return;
    countdown.value = 3;

    while (countdown.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      countdown.value--;
    }

    // Start breathing when countdown reaches zero
    startBreathing();
  }

  // ============================================================
  // 2) Start Breathing Exercise
  // ============================================================

  void startBreathing() {
    isPlaying.value = true;
    isPaused.value = false;

    remainingSeconds.value = totalSeconds.value;

    startMainTimer();
    _startInstructionFlow();
  }

  // ============================================================
  // 3) Pause Breathing
  // ============================================================
  void pauseBreathing() {
    isPaused.value = true;
    isPlaying.value = false;

    timer?.cancel();
    instructionTimer?.cancel();
    selectedFilter.refresh(); // 👈 force rebuild

    totalSeconds.value = 96;
    remainingSeconds.value = 96;
    remainingSeconds.refresh(); // 👈 force timer rebuild

    resetBreathing();
    startMainTimer();
  }

  // ============================================================
  // 4) Resume Breathing
  // ============================================================

  void resumeBreathing() {
    isPaused.value = false;
    isPlaying.value = true;

    startMainTimer();
    _startInstructionFlow(resume: true); // <--- NEW
  }

  // ============================================================
  // 5) MAIN COUNTDOWN TIMER
  // ============================================================

  void startMainTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isPlaying.value) {
        t.cancel();
        return;
      }

      if (remainingSeconds.value <= 0) {
        t.cancel();
        isPlaying.value = false;
        // instruction.value = "Exercise Completed";
        instruction.value = Get.context?.lang.exerciseCompleted ??  "Exercise Completed";
      } else {
        remainingSeconds.value--;
      }
    });
  }

  // ============================================================
  // 6) Instruction Cycle (4 sec each)
  // ============================================================

  // Different durations for steps
  RxList<int> stepDurations = <int>[4, 7, 8].obs;

  final List<List<int>> breathingPatterns = [
    [4, 7, 8], // Gold Standard
    [4, 4, 4, 4], // Box Breathing
    [6, 0, 8], // Slow Breathing
  ];


  void _startInstructionFlow({bool resume = false}) {
    instructionTimer?.cancel();

    final pattern = breathingPatterns[selectedFilter.value];
    if (pattern.isEmpty) return;

    if (!resume) {
      instructionRemaining.value = pattern[instructionStep.value];
    }

    _applyInstructionText();

    instructionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying.value) {
        timer.cancel();
        return;
      }

      instructionRemaining.value--;

      if (instructionRemaining.value <= 0) {
        // Move to next step
        instructionStep.value = (instructionStep.value + 1) % pattern.length;

        // Set next step duration
        instructionRemaining.value = pattern[instructionStep.value];

        // Update instruction text
        _applyInstructionText();
      }
    });
  }

  void _applyInstructionText() {
    final pattern = breathingPatterns[selectedFilter.value];
    final stepIndex = instructionStep.value;

    if (pattern.isEmpty) return;

    // Determine instruction text
    // We cycle: Breathe in -> Hold -> Breathe out -> Hold -> repeat
    // Rule: even index: Breathe in / Breathe out, odd index: Hold

    String text;
    if (stepIndex % 2 == 0) {
      // Even index: decide in/out based on position
      text = (stepIndex ~/ 2) % 2 == 0
          ? "${Get.context?.lang.breatheIn}\n${Get.context?.lang.theBallUp}"
          : "${Get.context?.lang.breathOut}\n${Get.context?.lang.ballDown}";
    } else {
      // Odd index: Hold
      text = "${Get.context?.lang.holdYourBreath}\n";
    }

    // If duration is 0 (like 0 in pattern), skip Hold and mark as breathe out
    if (pattern[stepIndex] == 0) {
      text = "${Get.context?.lang.breathOut}\n${Get.context?.lang.ballDown}";;
    }

    instruction.value = text;
  }

  // ============================================================
  // 7) RESET + TIME ADJUST
  // ============================================================

  void resetBreathing() {
    timer?.cancel();
    instructionTimer?.cancel();

    isPlaying.value = false;
    isPaused.value = false;

    instructionStep.value = 0;
    instructionRemaining.value = 4;

    instruction.value = "${Get.context?.lang.pressStartBegin}\n${Get.context?.lang.breathingExercise}";//"Press start to begin\nbreathing exercise";
    remainingSeconds.value = totalSeconds.value;
  }

  void addTime() {
    totalSeconds.value += 24;
    if (!isPlaying.value) remainingSeconds.value = totalSeconds.value;
  }

  void removeTime() {
    if (totalSeconds.value > 24) {
      totalSeconds.value -= 24;
      if (!isPlaying.value) remainingSeconds.value = totalSeconds.value;
    }
  }

  void rateExperience(bool good) {
    print("Experience: ${good ? 'Good' : 'Bad'}");
  }

  void stopAllTimers() {
    timer?.cancel();
    instructionTimer?.cancel();

    isPlaying.value = false;
    isPaused.value = false;

    instructionStep.value = 0;
    instructionRemaining.value = 4;

    instruction.value = "${Get.context?.lang.pressStartBegin}\n${Get.context?.lang.breathingExercise}";//"Press start to begin\nbreathing exercise";
    remainingSeconds.value = totalSeconds.value;
  }
  void onSelectFilter(int i) {
    selectedFilter.value = i;

    // Update patterns
    stepDurations.clear();
    stepDurations.addAll(breathingPatterns[i]);

    // Clean up current session
    timer?.cancel();
    instructionTimer?.cancel();

    // Reset to initial state (Don't start automatically)
    isPlaying.value = false;
    isPaused.value = false;
    countdown.value = 0;

    instructionStep.value = 0;
    instructionRemaining.value = breathingPatterns[i][0];

    instruction.value = "${Get.context?.lang.pressStartBegin}\n${Get.context?.lang.breathingExercise}";//"Press start to begin\nbreathing exercise";
    remainingSeconds.value = totalSeconds.value;

    // Refresh UI
    instruction.refresh();
    selectedFilter.refresh();
  }

}
