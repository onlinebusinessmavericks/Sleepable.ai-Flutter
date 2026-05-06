import 'package:get/get.dart';

import '../controllers/breathwork_controller.dart';

class BreathworkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BreathworkController>(() => BreathworkController());
  }
}
