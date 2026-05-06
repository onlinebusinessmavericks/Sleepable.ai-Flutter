import 'package:sleepable_ai/core/utils/library.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: false);

  }
}
