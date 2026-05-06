// import 'package:flutter/material.dart';
// import '../../../core/theme/text_theme.dart';
// import '../../music/views/music_view.dart';
// import 'package:get/get.dart';
// import '../../../core/constants/colors.dart';
// import '../../../generated/assets.dart';
// import '../controllers/dreambot_controller.dart';
//
// class MelodiesScreen extends StatelessWidget {
//   MelodiesScreen({super.key});
//
//   final controller = Get.find<AlarmController>();
//
//   final List<Map<String, String>> melodies = [
//     {"name": "Forest Stream", "asset": Assets.musicForestStreamMusic},
//     {"name": "Morning Birds", "asset": Assets.musicMorningBirdsMusic},
//     {"name": "Mountain Breeze", "asset": Assets.musicMountainBreezeMusic},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             SizedBox(height: 16 * SizeConfigs.textScale),
//
//             // ---- TOP BAR ----
//             Row(
//               children: [
//                 SmallCircleIcon(
//                   icon: Icons.arrow_back_rounded,
//                   size: 20 * SizeConfigs.textScale,
//                   iconColor: AppColors.white,
//                   backgroundColor: Colors.white10,
//                   onTap: () => Get.back(),
//                 ),
//
//                 Expanded(
//                   child: Center(
//                     child: Text(
//                       "Melodies",
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         color: AppColors.white,
//                         fontSize: 21 * SizeConfigs.textScale,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(width: 40), // keeps symmetry
//               ],
//             ),
//
//             SizedBox(height: 20 * SizeConfigs.textScale),
//
//             // ---- LIST ----
//             Expanded(
//               child:  ListView.separated(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                   itemCount: melodies.length,
//                   separatorBuilder: (_, __) =>
//                       Divider(color: Colors.white12, height: 1),
//                   itemBuilder: (context, index) {
//                     final item = melodies[index];
//                     final isSelected =
//                         controller.selectedMelody.value == item["name"];
//
//                     return GestureDetector(
//                       onTap: () {
//                         controller.setMelody(item["name"]!, item["asset"]!);
//                         Get.back();
//                       },
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 180),
//                         curve: Curves.easeOut,
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 18, horizontal: 20),
//                         decoration: BoxDecoration(
//                           color:
//                           isSelected ? Colors.white10 : Colors.transparent,
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               item["name"]!,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleMedium
//                                   ?.copyWith(
//                                 color: AppColors.white,
//                                 fontSize: 18 * SizeConfigs.textScale,
//                               ),
//                             ),
//
//                             const Spacer(),
//
//                             // Checkmark
//                             AnimatedOpacity(
//                               duration: const Duration(milliseconds: 200),
//                               opacity: isSelected ? 1 : 0,
//                               child: const Icon(
//                                 Icons.check_circle_rounded,
//                                 color: Color(0xFF3F8CFF),
//                                 size: 26,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../music/views/music_view.dart';
import '../controllers/alarm_controller.dart';

class MelodiesScreen extends StatelessWidget {
  MelodiesScreen({super.key});

  final controller = Get.find<AlarmController>();

  final List<Map<String, String>> melodies = [
    {"name": "Forest Stream", "asset": Assets.musicForestStreamMusic},
    {"name": "Morning Birds", "asset": Assets.musicMorningBirdsMusic},
    {"name": "Mountain Breeze", "asset": Assets.musicMountainBreezeMusic},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              SizedBox(height: 20 * SizeConfigs.textScale),

              // ---------- TOP BAR ----------
              Row(
                children: [
                  SmallCircleIcon(
                    icon: Icons.arrow_back_rounded,
                    size: 20 * SizeConfigs.textScale,
                    iconColor: AppColors.white,
                    backgroundColor: Colors.white10,
                    onTap: () => Get.back(),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        context.lang.melodies,
                        style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 21 * SizeConfigs.textScale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),

              SizedBox(height: 45 * SizeConfigs.textScale),

              // ---------- LIST ----------
              Expanded(
                child: ListView.separated(
                    // padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: melodies.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = melodies[index];
                      final isSelected = controller.selectedMelody.value == item["name"];

                      return GestureDetector(
                        onTap: () {
                          // 1. Update the selection immediately
                          controller.setMelody(item["name"]!, item["asset"]!);

                          // 2. Small delay so the user sees the 'Check' icon and the Blue border
                          Future.delayed(const Duration(milliseconds: 250), () {
                            Get.back();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white10 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item["name"]!,
                                style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 17 * SizeConfigs.textScale,),

                                // Theme.of(context).textTheme.titleMedium?.copyWith(
                                //   color: AppColors.white,
                                //   fontSize: 18 * SizeConfigs.textScale,
                                // ),
                              ),

                              Spacer(),

                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.blueAccent,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
