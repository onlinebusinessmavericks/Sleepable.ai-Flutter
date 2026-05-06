
import 'package:get/get.dart';
import '../controllers/sleep_report_controller.dart';

class SleepReportBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<SleepReportController>(() => SleepReportController());
  }
}

