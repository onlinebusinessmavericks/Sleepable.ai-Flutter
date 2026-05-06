
import 'package:get/get.dart';
import '../controllers/boot_up_controller.dart';

class BootUpBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<BootUpController>(() => BootUpController());
  }
}

