
import 'package:get/get.dart';
import '../controllers/welcome_controller.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }
}

