// // import '../../../core/utils/library.dart';
// // import '../model/sleep_quiz_result_model.dart';
// //
// // class SleepQuizResultController extends GetxController {
// //   final result = Rxn<SleepQuizResult>();
// //
// //   @override
// //   void onInit() {
// //     super.onInit();
// //
// //     /// 👇 temporary mock (later replace with API)
// //     result.value = SleepQuizResult(
// //       title: "Sleeplessness",
// //       summary:
// //       "The main cause of your sleep problem appears to be sleeplessness. "
// //           "Many people experience this at some point, but chronic sleeplessness "
// //           "can impact overall quality of life.\n\n"
// //           "It may be linked to stress, lifestyle habits, medical conditions, "
// //           "or sleep-related disorders such as breathing irregularities.",
// //       suggestions: [
// //         "Avoid caffeine, alcohol, and heavy meals before bedtime.",
// //         "Exercise regularly and prefer side or stomach sleeping.",
// //         "Create a calming bedtime routine.",
// //         "Keep bedroom temperature around 20°C (68–72°F).",
// //       ],
// //     );
// //   }
// //
// //   void redoQuiz() {
// //     Get.offAllNamed(
// //       Routes.dashboard,
// //     );
// //   }
// //
// // }
// import '../../../core/utils/library.dart';
// import 'package:get/get.dart';
// import '../../sleep_quiz/model/quiz_result_response.dart';
// import '../model/sleep_quiz_result_model.dart'; // Make sure this points to your new model
// import '../../../data/services/api_sevices.dart'; // Adjust path for your ProgressApis
//
// class SleepQuizResultController extends GetxController {
//   // Uses the API model we created earlier
//   final result = Rxn<QuizResultData>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _fetchResults();
//   }
//
//   Future<void> _fetchResults() async {
//     // 1. Get the payload passed from the Quiz screen
//     final payload = Get.arguments as Map<String, dynamic>?;
//
//     if (payload == null) {
//       Get.snackbar("Error", "No quiz data found.");
//       return;
//     }
//
//     // 2. Call the API (The UI will automatically show the CircularProgressIndicator because result.value is null)
//     final apiResponse = await ProgressApis.submitSleepQuiz(payload);
//
//     // 3. Update the UI with real data
//     if (apiResponse != null && apiResponse.success && apiResponse.data != null) {
//       result.value = apiResponse.data;
//     } else {
//       Get.snackbar("Error", "Could not generate your results. Try again.");
//     }
//   }
//
//   void redoQuiz() {
//     Get.offAllNamed(Routes.dashboard);
//   }
// }

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