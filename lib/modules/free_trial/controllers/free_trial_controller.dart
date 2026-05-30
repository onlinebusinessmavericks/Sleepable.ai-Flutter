// import 'package:sleepable_ai/modules/login/views/login_view.dart';
// import 'package:get/get.dart';
// import 'dart:async';
// import '../../../core/utils/library.dart';
// import '../../../routes/app_pages.dart';
// import '../../../widgets/offer_widget.dart';
// import '../../dashboard/controllers/dashboard_controller.dart';
//
// class FreeTrialController extends GetxController {
//   RxInt step = 0.obs;
//   late BuildContext _context;
//
//   /// Call this once from UI
//   void setContext(BuildContext context) {
//     _context = context;
//   }
//   @override
//   void onReady() {
//     super.onReady();
//     _start();
//   }
//
//   Future<void> _start() async {
//     await Future.delayed(const Duration(milliseconds: 600));
//     step.value = 1; // show text
//
//     await Future.delayed(const Duration(seconds: 2));
//     goNextScreen(); // 🚀 move next
//   }
//
//   void goNextScreen() {
//     showNotBedTimeSheet(Get.context!);
//   }
// }
