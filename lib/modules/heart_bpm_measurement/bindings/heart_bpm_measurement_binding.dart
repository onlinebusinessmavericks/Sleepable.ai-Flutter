import 'package:sleepable_ai/core/utils/library.dart';
import '../controllers/heart_bpm_measurement_controller.dart';

class HeartBpmMeasurementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HeartBpmMeasurementController>(() => HeartBpmMeasurementController());
  }
}