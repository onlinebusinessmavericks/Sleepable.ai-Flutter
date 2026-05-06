// import 'package:get/get.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
// import 'dart:developer';
//
// class WakeLockController extends GetxController {
//   RxBool isWakeLockEnabled = false.obs;
//
//   /// Background task for AlarmManager
//   static void wakeLockTask() async {
//     final now = DateTime.now();
//     final hour = now.hour;
//
//     // final shouldWake = (hour >= 23 || hour < 9); // 11PM-9AM
//     final shouldWake = (hour >= 15 || hour < 12); // 3 PM (15) to 12 PM (12)
//
//     if (shouldWake) {
//       await WakelockPlus.enable();
//       print("🟢 WakeLock ENABLED at $now");
//     } else {
//       await WakelockPlus.disable();
//       print("🔴 WakeLock DISABLED at $now");
//     }
//   }
//
//   @override
//   void onInit() {
//     super.onInit();
//     // initial check when app opens
//     wakeLockTask();
//   }
// }
