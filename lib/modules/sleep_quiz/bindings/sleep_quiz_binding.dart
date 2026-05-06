import 'package:get/get.dart';
import '../controllers/sleep_quiz_controller.dart';

import 'package:get/get.dart';
import '../controllers/sleep_quiz_controller.dart';

class SleepQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SleepQuizController>(() => SleepQuizController());
  }
}
