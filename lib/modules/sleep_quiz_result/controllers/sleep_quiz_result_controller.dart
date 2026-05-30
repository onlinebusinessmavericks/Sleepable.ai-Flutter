

import 'dart:convert'; // Needed for JSON encoding
import 'package:nb_utils/nb_utils.dart'; // Needed for SharedPreferences
import '../../../core/utils/library.dart';
import 'package:get/get.dart';
import '../../../localization/lang_extension.dart';
import '../../sleep_quiz/model/quiz_result_response.dart';
import '../model/sleep_quiz_result_model.dart';
import '../../../data/services/api_sevices.dart';

class SleepQuizResultController extends GetxController {
  final result = Rxn<QuizResultData>();
  final isLoading = true.obs;

  // Keep track of the current quiz type so we know which one to clear on "Redo"
  String? currentQuizType;

  @override
  void onInit() {
    super.onInit();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final payload = Get.arguments as Map<String, dynamic>?;
    final lang = Get.context!.lang;
    if (payload == null) {
      // Get.snackbar("Error", "No quiz data found.");
      Get.snackbar(lang.errorLabel, lang.errorNoQuizData);
      isLoading.value = false;
      return;
    }

    currentQuizType = payload['quiz_type'];

    // 🔥 SCENARIO A: The user tapped "View Results" and we already have the saved data.
    if (payload.containsKey('saved_data')) {
      result.value = QuizResultData.fromJson(payload['saved_data']);
      isLoading.value = false;
      return;
    }

    // 🔥 SCENARIO B: The user just finished the quiz. Call the API.
    try {
      final apiResponse = await ProgressApis.submitSleepQuiz(payload);

      if (apiResponse != null && apiResponse.success && apiResponse.data != null) {
        result.value = apiResponse.data;

        // ✅ SAVE TO PREFERENCES FOR NEXT TIME
        if (currentQuizType != null) {
          setValue('quiz_result_$currentQuizType', jsonEncode(apiResponse.data!.toJson()));
        }

      } else {
        // Get.snackbar("Error", "Could not generate your results. Try again.");
        Get.snackbar(lang.errorLabel, lang.errorGenerateResult);
      }
    } catch (e) {
      // Get.snackbar("Error", "Network error occurred.");
      Get.snackbar(lang.errorLabel, lang.errorNetwork);
    } finally {
      isLoading.value = false;
    }
  }

  void redoQuiz() {
    // 🔥 CLEAR THE CACHE SO THEY CAN START OVER
    if (currentQuizType != null) {
      setValue('quiz_result_$currentQuizType', ''); // Empty string clears it
    }
    Get.offAllNamed(Routes.dashboard);
  }
}