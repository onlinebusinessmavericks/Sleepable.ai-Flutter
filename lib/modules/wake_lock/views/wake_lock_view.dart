// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/breathwork_controller.dart';
//
// class WakeLockView extends StatelessWidget {
//   const WakeLockView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final WakeLockController controller = Get.find<WakeLockController>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("WakeLock Status"),
//       ),
//       body: Center(
//         child: Obx(() => Text(
//           controller.isWakeLockEnabled.value
//               ? "🟢 Screen is WAKE (11PM-9AM)"
//               : "🔴 Screen can SLEEP (Daytime)",
//           style: const TextStyle(fontSize: 20),
//           textAlign: TextAlign.center,
//         )),
//       ),
//     );
//   }
// }
