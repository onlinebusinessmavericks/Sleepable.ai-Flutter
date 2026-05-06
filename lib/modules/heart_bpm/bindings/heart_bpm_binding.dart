import 'package:sleepable_ai/core/utils/library.dart';
import '../controllers/heart_bpm_controller.dart';

class HeartBPMBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HeartBPMController>(() => HeartBPMController());
  }
}