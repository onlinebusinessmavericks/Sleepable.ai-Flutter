import 'package:get/get.dart';

import '../controllers/profile_sleep_reminder_controller.dart';

class ProfileSleepReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileSleepReminderController>(() => ProfileSleepReminderController());
  }
}
