import 'package:sleepable_ai/core/utils/library.dart';

import '../controllers/alarm_controller.dart';

class AlarmBinding extends Bindings {
  @override
  void dependencies() {
    // Must stay alive across Get.offAllNamed(dashboard) so snooze timers survive.
    if (!Get.isRegistered<AlarmController>()) {
      Get.put(AlarmController(), permanent: true);
    }
  }
}
