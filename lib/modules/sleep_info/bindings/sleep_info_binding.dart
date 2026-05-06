import 'package:sleepable_ai/core/utils/library.dart';

import 'package:get/get.dart';

import '../controllers/sleep_info_controller.dart';

class SleepInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SleepInfoController>(() => SleepInfoController());
  }
}