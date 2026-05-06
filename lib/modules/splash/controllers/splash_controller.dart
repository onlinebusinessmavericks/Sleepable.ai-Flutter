import 'package:get/get.dart';
import 'dart:async';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));
    Get.offNamed(Routes.bootUp);
  }
}
