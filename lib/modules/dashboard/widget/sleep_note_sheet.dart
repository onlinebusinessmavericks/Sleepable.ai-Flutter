// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../core/theme/text_theme.dart';
// import '../../sleep_sound/controllers/sleep_sound_controller.dart';
//
// class SleepNoteSheet {
//   static void open(BuildContext context, SleepSoundController controller) {
//     SizeConfigs.init(context);
//
//     Get.bottomSheet(
//       Container(
//         height: SizeConfigs.screenHeight * 0.85,
//         decoration: const BoxDecoration(
//           color: Color(0xFF0A152F),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//
//         child: Column(
//           children: [
//
//             /// ---------- HEADER ----------
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: GestureDetector(
//                       onTap: () => Get.back(),
//                       child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 36),
//                     ),
//                   ),
//
//                   Text(
//                     "Add Sleep Note",
//                     style: TextStyle(color: Colors.white, fontSize: 20),
//                   )
//                 ],
//               ),
//             ),
//
//             /// ---------- BODY ----------
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // your tags UI
//                     // your text field UI
//                   ],
//                 ),
//               ),
//             ),
//
//             /// ---------- BUTTON ----------
//             Padding(
//               padding: EdgeInsets.only(bottom: 20),
//               child: ElevatedButton(
//                 onPressed: () {
//                   controller.saveSleepNote();   // you can create this fn
//                   Get.back();
//                 },
//                 child: const Text("Done"),
//               ),
//             ),
//
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }
// }
