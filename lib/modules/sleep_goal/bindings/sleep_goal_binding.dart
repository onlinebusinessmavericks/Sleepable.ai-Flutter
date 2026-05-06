import 'package:get/get.dart';

import '../controllers/sleep_goal_controller.dart';

class SleepGoalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SleepGoalController>(() => SleepGoalController());
  }
}
