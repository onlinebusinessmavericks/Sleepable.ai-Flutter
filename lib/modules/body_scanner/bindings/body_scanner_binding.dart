
import 'package:get/get.dart';
import '../controllers/body_scanner_controller.dart';

class BodyScannerBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<BodyScannerController>(() => BodyScannerController());
  }
}

