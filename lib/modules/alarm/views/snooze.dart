import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../localization/lang_extension.dart';
import '../../music/views/music_view.dart';
import '../controllers/alarm_controller.dart';

class SnoozeScreen extends StatefulWidget {
  const SnoozeScreen({super.key});

  @override
  State<SnoozeScreen> createState() => _SnoozeScreenState();
}

class _SnoozeScreenState extends State<SnoozeScreen> {
  final controller = Get.find<AlarmController>();

  // final List<String> options = ["5 min", "10 min", "Never"];
  final List<String> options = ["5", "10", "0"];

  late final FixedExtentScrollController pickerController;
  final RxInt selected = 0.obs;

  @override
  void initState() {
    super.initState();

    // set initial selected index
    // int initialIndex = controller.selectedSnooze.value == "5"
    //     ? 0
    //     : controller.selectedSnooze.value == "10"
    //     ? 1
    //     : 2;
    String val = controller.selectedSnooze.value;

    int initialIndex = (val == "5")
        ? 0
        : (val == "10")
        ? 1
        : (val == "0") ? 1 : 2;
    selected.value = initialIndex;

    pickerController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _saveSelection();
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20 * SizeConfigs.textScale),
                // TOP BAR
                Row(
                  children: [
                    SmallCircleIcon(
                      icon: Icons.arrow_back_rounded,
                      size: 20 * SizeConfigs.textScale,
                      iconColor: AppColors.white,
                      backgroundColor: Colors.white10,
                      onTap: () {
                        _saveSelection();
                        Get.back();
                      },
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          context.lang.snooze,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    // This keeps spacing equal on right side
                    SizedBox(width: 20),
                  ],
                ),

                SizedBox(height: 15 * SizeConfigs.textScale),

                Text(
                  context.lang.HowManyMoreMinutesSleepWouldYouLike,
                  style: // Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                  Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                ),

                const SizedBox(height: 20),

                // PICKER
                SizedBox(
                  height: 180,
                  child: CupertinoPicker(
                    scrollController: pickerController,
                    itemExtent: 50,

                    // onSelectedItemChanged: (i) => selected.value = i,
                    onSelectedItemChanged: (i) {
                      selected.value = i;
                      // Controller mein key save karein (e.g., "5", "10", ya "0")
                      controller.setSnooze(options[i]);
                    },
                    selectionOverlay: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                    ),
                    children: options.map((key) {
                      // Yahan translation logic apply karein
                      String displayText;
                      if (key == "0") {
                        displayText = context.lang.never; // "Never" ka translation
                      } else {
                        displayText = "$key ${context.lang.min}"; // "5 min" ya "10 min" ka translation
                      }

                      return Center(
                        child: Text(
                          displayText,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontSize: 17 * SizeConfigs.textScale,
                          ),
                        ),
                      );
                    }).toList(),
                    // children: options
                    //     .map(
                    //       (e) => Center(
                    //         child: Text(
                    //           e,
                    //           style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 17 * SizeConfigs.textScale),
                    //         ),
                    //       ),
                    //     )
                    //     .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // void _saveSelection() {
  //   print("💾 Selected index: ${selected.value}");
  //
  //   if (selected.value == 0) {
  //     controller.setSnooze("5 min"); // just save preference
  //   } else if (selected.value == 1) {
  //     controller.setSnooze("10 min"); // just save preference
  //   } else {
  //     controller.setSnooze("Never"); // just save preference
  //   }
  // }
  void _saveSelection() {
    // selected.value ek RxInt hai, uske index se options list ki key uthayein
    String key = options[selected.value];

    print("💾 Saving snooze key: $key");

    // Ab controller mein sirf "5", "10" ya "0" save hoga
    controller.setSnooze(key);
  }
}
