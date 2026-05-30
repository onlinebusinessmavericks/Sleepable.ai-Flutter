import '../../../core/utils/library.dart';

import 'package:get/get.dart';
import '../../../localization/lang_extension.dart';
import '../model/sleep_quiz_question_model.dart';

class SleepQuizController extends GetxController {
  final questions = <SleepQuizQuestion>[].obs; // Make this observable and empty initially
  final currentIndex = 0.obs;
  final answers = <String, String>{}.obs;
  final animatedProgress = 0.0.obs;
  String currentQuizType = "sleep_patterns";
  @override
  void onInit() {
    animatedProgress.value = 0.0; // first question = 1/total
    super.onInit();
    _loadQuestions();
  }
  void _loadQuestions() {
    final lang = Get.context!.lang; // 🔥 Access Localization
    final args = Get.arguments as Map<String, dynamic>?;
    final quizTitle = args?['quizTitle'] ?? "";

    if (quizTitle == 'Night Breathing & Rest Check') {
      currentQuizType = "night_breathing";
      questions.value = [
        SleepQuizQuestion(key: 'snoring', question: lang.qSnoring),
        SleepQuizQuestion(key: 'morning_headache', question: lang.qMorningHeadache),
        SleepQuizQuestion(key: 'gasping_air', question: lang.qGaspingAir),
        SleepQuizQuestion(key: 'breathing_pauses', question: lang.qBreathingPauses),
        SleepQuizQuestion(key: 'sleepy_driving', question: lang.qSleepyDriving),
        SleepQuizQuestion(key: 'dry_mouth', question: lang.qDryMouth),
        SleepQuizQuestion(key: 'irritable_moody', question: lang.qIrritable),
        SleepQuizQuestion(key: 'low_stamina', question: lang.qLowStamina),
        SleepQuizQuestion(key: 'chest_discomfort', question: lang.qChestDiscomfort),
        SleepQuizQuestion(key: 'daytime_sleepiness', question: lang.qDaytimeSleepiness),
        SleepQuizQuestion(key: 'blood_pressure', question: lang.qBloodPressure),
        SleepQuizQuestion(key: 'nasal_breathing', question: lang.qNasalBreathing),
      ];
    } else {
      currentQuizType = "sleep_patterns";
      questions.value = [
        SleepQuizQuestion(key: 'difficulty_sleep', question: lang.qDifficultySleep),
        SleepQuizQuestion(key: 'night_awakenings', question: lang.qNightAwakenings),
        SleepQuizQuestion(key: 'daytime_fatigue', question: lang.qDaytimeFatigue),
        SleepQuizQuestion(key: 'sleep_medication', question: lang.qSleepMedication),
        SleepQuizQuestion(key: 'evening_alcohol', question: lang.qEveningAlcohol),
        SleepQuizQuestion(key: 'sleep_anxiety', question: lang.qSleepAnxiety),
        SleepQuizQuestion(key: 'late_sleep_schedule', question: lang.qLateSchedule),
        SleepQuizQuestion(key: 'loud_snoring', question: lang.qSnoring), // Reused
        SleepQuizQuestion(key: 'gasping_breath', question: lang.qGaspingAir), // Reused
        SleepQuizQuestion(key: 'breathing_pauses', question: lang.qBreathingPauses), // Reused
        SleepQuizQuestion(key: 'excessive_sleepiness', question: lang.qDaytimeSleepiness), // Reused
        SleepQuizQuestion(key: 'sleepy_driving', question: lang.qSleepyDriving), // Reused
        SleepQuizQuestion(key: 'morning_headache', question: lang.qMorningHeadache), // Reused
        SleepQuizQuestion(key: 'medical_conditions', question: lang.qMedicalConditions),
        SleepQuizQuestion(key: 'excess_weight', question: lang.qExcessWeight),
      ];
    }
    animatedProgress.value = 0.0;
  }

  // Update these getters to use questions.length
  int get total => questions.length;
  bool get hasAnswer => answers.containsKey(questions[currentIndex.value].key);
  bool get isLast => currentIndex.value == questions.length - 1;

  // final currentIndex = 0.obs;
  final isAnimating = false.obs;



  double get progress => (currentIndex.value + 1) / total;


  void selectAnswer(String value) {
    final key = questions[currentIndex.value].key;
    answers[key] = value;
    answers.refresh();
  }


  double get targetProgress => (currentIndex.value + 1) / total;

  void next() {
    if (!hasAnswer || isAnimating.value) return;

    isAnimating.value = true;
    animatedProgress.value = (currentIndex.value + 1) / total;

    if (!isLast) {
      currentIndex.value++;
    } else {
      // ✅ Generate the JSON and pass it to the Result screen!
      final payload = buildResultJson();
      debugPrint("🟢 Sending Sleep Quiz Payload: $payload");

      Get.offAllNamed(Routes.sleepQuizResult, arguments: payload);
    }

    isAnimating.value = false;
  }

  void previous() {
    if (currentIndex.value > 0) {
      isAnimating.value = true;

      currentIndex.value--;
      animatedProgress.value = currentIndex.value / total;

      isAnimating.value = false;
    } else {
      Get.back();
    }
  }

  /// ✅ FINAL JSON FOR BACKEND
  Map<String, dynamic> buildResultJson() {
    return {"quiz_type": currentQuizType,"answers": answers, "completed_at": DateTime.now().toIso8601String()};
  }
}
