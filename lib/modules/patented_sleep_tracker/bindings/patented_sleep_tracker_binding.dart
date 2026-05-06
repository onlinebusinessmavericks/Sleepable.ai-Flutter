
import 'package:get/get.dart';
import '../controllers/patented_sleep_tracker_controller.dart';

class PatentedSleepTrackerBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<PatentedSleepTrackerController>(() => PatentedSleepTrackerController());
  }
}

