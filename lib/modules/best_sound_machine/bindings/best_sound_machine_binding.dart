
import 'package:get/get.dart';
import '../controllers/best_sound_machine_controller.dart';

class BestSoundMachineBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<BestSoundMachineController>(() => BestSoundMachineController());
  }
}

