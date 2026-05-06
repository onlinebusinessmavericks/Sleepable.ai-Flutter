import 'package:sleepable_ai/core/utils/library.dart';

import '../controllers/dreambot_controller.dart';

class DreamBotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DreamBotController>(() => DreamBotController());
  }
}