import 'package:get/get.dart';

import '../controllers/sleep_tracker_screen_controller.dart';

import 'package:get/get.dart';
import '../controllers/sleep_tracker_screen_controller.dart';

class SleepTrackerBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent so Wake/Quit can finish cleanup after Get.offAllNamed(dashboard)
    // removes the sleep-tracker route (otherwise stop API / FGS teardown is skipped).
    if (!Get.isRegistered<SleepTrackerController>()) {
      Get.put<SleepTrackerController>(SleepTrackerController(), permanent: true);
    }
  }
}

