// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:giffy_dialog/giffy_dialog.dart';
// import 'package:sleepable_ai/localization/lang_extension.dart';
// import '../../../core/constants/colors.dart';
// import '../../../data/billing/billing_controller.dart';
// import '../../../generated/assets.dart';
// import '../../../widgets/custom_button.dart';
// import '../controllers/patented_sleep_tracker_controller.dart';
//
// class PatentedSleepTrackerView extends GetView<PatentedSleepTrackerController> {
//   const PatentedSleepTrackerView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ---------------- BACKGROUND ----------------
//           Positioned.fill(child: Lottie.asset(Assets.lottieSleepReportBackground, fit: BoxFit.cover, repeat: true)),
//
//           // ---------------- FOREGROUND ----------------
//           Column(
//             children: [
//               const SizedBox(height: 80),
//
//               // --------- Title ---------
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Text(
//                   context.lang.patentedSleeptTracker,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w100),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Text(
//                   context.lang.sleepableAiTechBringsExpertSleepTrackAnalysis,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 80),
//
//               const SizedBox(height: 80),
//               // --------- Bottom Content ---------
//               Image.asset(Assets.homeSleepableTextLogo, height: 29),
//
//               const SizedBox(height: 16),
//
//
//               const SizedBox(height: 30),
//               AnimatedNextButton(onPressed: controller.goNext),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
