import 'package:get/get.dart';

import '../controllers/profile_sleep_goal_controller.dart';

class ProfileSleepGoalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileSleepGoalController>(() => ProfileSleepGoalController());
  }
}
