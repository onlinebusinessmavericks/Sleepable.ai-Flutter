
import 'package:get/get.dart';
import '../../../localization/language_controller.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    print("SplashBinding → dependencies called");
    Get.lazyPut<LanguageController>(() => LanguageController());
  }
}

