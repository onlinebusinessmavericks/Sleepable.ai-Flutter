import 'package:sleepable_ai/core/utils/library.dart';

import '../controllers/alarm_controller.dart';

class AlarmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AlarmController>(() => AlarmController());
  }
}