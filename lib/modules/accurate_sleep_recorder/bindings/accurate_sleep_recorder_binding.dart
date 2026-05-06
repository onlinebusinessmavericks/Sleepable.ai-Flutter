
import 'package:get/get.dart';
import '../controllers/accurate_sleep_recorder_controller.dart';

class AccurateSleepRecorderBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<AccurateSleepRecorderController>(() => AccurateSleepRecorderController());
  }
}

