import 'package:get/get.dart';

import '../controllers/sleep_tracker_screen_controller.dart';

import 'package:get/get.dart';
import '../controllers/sleep_tracker_screen_controller.dart';

class SleepTrackerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SleepTrackerController>(SleepTrackerController());//, permanent: true
  }
}
