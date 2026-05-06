import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:sleepable_ai/modules/alarm/views/melodies.dart';
import 'package:sleepable_ai/modules/alarm/views/snooze.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/custom_loader.dart';
import '../../music/views/music_view.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/alarm_controller.dart';

class AlarmScreen extends GetView<AlarmController> {
   AlarmScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 1. Block the default back action
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 2. Trigger the EXACT same logic as the UI button
        _handleBackAndSave(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        body: Obx(() =>Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40 * SizeConfigs.textScale),
                  // 🔥 Custom Top Bar (instead of AppBar)
                  Row(
                    children: [
                      SmallCircleIcon(
                        icon: Icons.arrow_back_rounded,
                        size: 20 * SizeConfigs.textScale,
                        iconColor: AppColors.white,
                        backgroundColor: Colors.white10,
                        onTap: () {
                          Navigator.maybePop(context);

                        },
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            context.lang.wakeUpAlarm,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                      // This keeps spacing equal on right side
                      SizedBox(width: 20),
                    ],
                  ),

                  SizedBox(height: 15 * SizeConfigs.textScale),

                  Obx(
                        () => listTile(
                        context,
                          context.lang.wakeUpAlarm,
                        Text(
                          controller.wakeUp.value
                              ? context.lang.onlyWorksAfterStartingSleepTracker
                              : context.lang.alarmCurrentlyOff, // Changed from ""
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: controller.wakeUp.value ? AppColors.textBoldColor : Colors.redAccent,
                              fontSize: 14 * SizeConfigs.textScale,
                              fontWeight: FontWeight.w300
                          ),
                        ),
                        switchValue: controller.wakeUp.value,
                          onSwitch: (v) async {
                            if (v) {
                              // 🔥 1. Check permissions BEFORE turning the switch on
                              // This ensures the app has the right to wake the phone up
                              await controller.prepareAlarmPermissions();

                              // 2. Now set the value and schedule
                              controller.wakeUp.value = true;
                              controller.scheduleAlarm();
                            } else {
                              // 3. Turn off and cleanup
                              controller.wakeUp.value = false;
                              await controller.disableAlarm();
                            }

                            controller.wheelsSynced = false;
                          },

                    ),
                  ),

                  Obx(() => controller.wakeUp.value ? SizedBox(height: 15 * SizeConfigs.textScale) : SizedBox()),

                  Obx(() {
                    if (!controller.wakeUp.value) return SizedBox();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // 🟢 Increase this delay to 350ms. This ensures the API/Local data
                      // has finished loading and the UI is fully rendered before jumping.
                      Future.delayed(const Duration(milliseconds: 150), () {
                        print("🚀 BottomSheet sync triggered...");
                        controller.syncWakeUpWheels();
                      });
                    });
                    return _buildTimePicker(context);
                  }),
                  Obx(() => controller.wakeUp.value ? SizedBox(height: 25) : SizedBox()),

                  Obx(() {
                    if (!controller.wakeUp.value) return SizedBox();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 15),

                          Text(
                              context.lang.repeat,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontSize: 17,
                            ),
                          ),

                          SizedBox(height: 4),

                          /// Selected days summary
                          // Text(
                          //   controller.getSelectedText,
                          //   style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          //     color: Colors.blue,
                          //     fontSize: 14 * SizeConfigs.textScale,
                          //     fontWeight: FontWeight.w300,
                          //   ),
                          // ),
                          Obx(() => Text(
                            controller.getSelectedText(context),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.blue,
                              fontSize: 14 * SizeConfigs.textScale,
                              fontWeight: FontWeight.w300,
                            ),
                          )),

                          SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (index) {
                              final isSelected = controller.selected[index];
                              final shortDays = controller.getDaysShort(context);
                              return GestureDetector(
                                onTap: () => controller.toggle(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    // controller.daysShort[index],
                                    shortDays[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                  Obx(() => controller.wakeUp.value ? SizedBox(height: 25) : SizedBox()),

                  // SETTINGS LIST
                  Obx(
                    () => controller.wakeUp.value
                        ? Container(
                            padding: const EdgeInsets.only(left: 18, right: 18),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 15 * SizeConfigs.textScale),

                                listTile(
                                  context,
                                  context.lang.melodies,
                                  Obx(
                                    () => Text(
                                      controller.selectedMelody.value,
                                      style:
                                      Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                    ),
                                  ),
                                  onTap: () => Get.toNamed(Routes.melodies),
                                ),
                                Divider(color: Colors.grey.shade700),
                                // listTile(
                                //   context,
                                //   "Snooze",
                                //   Obx(
                                //     () => Text(
                                //       controller.selectedSnooze.value,
                                //       style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                //     ),
                                //   ),
                                //   onTap: () => Get.to(() => SnoozeScreen()),
                                // ),
                                listTile(
                                  context,
                                  context.lang.snooze,
                                  Obx(
                                        () => Text(
                                      controller.getSnoozeDisplay(context),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: AppColors.textBoldColor,
                                          fontSize: 14 * SizeConfigs.textScale,
                                          fontWeight: FontWeight.w300
                                      ),
                                    ),
                                  ),
                                  onTap: () => Get.to(() => SnoozeScreen()),
                                ),
                                Divider(color: Colors.grey.shade700),

                                Obx(
                                  () => listTile(
                                    context,
                                    context.lang.fadeIn,
                                    Text(
                                      context.lang.default1,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                    ),
                                    switchValue: controller.fadeIn.value,
                                    onSwitch: (v) => controller.fadeIn.value = v,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(),
                  ),
                ],
              ),
            ),
            // 🔥 FULL SCREEN LOADER LAYER
            if (controller.isProcessingBack.value)
              Container(
                color: Colors.black.withOpacity(0.5), // Dim the background
                child: Center(
                  child: LoaderWidget(size: sw(150)),
                ),
              ),
          ],
        )),
      ),
    );
  }

  Widget listTile(BuildContext context, String title, Widget subtitle, {bool? switchValue, ValueChanged<bool>? onSwitch, VoidCallback? onTap}) {
    return ListTile(
      minTileHeight: 0,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 17 * SizeConfigs.textScale),
      ),
      subtitle: subtitle,
      // ⬅️ Now accepts a Widget
      trailing: switchValue != null
          ? Switch(
              value: switchValue,
              onChanged: onSwitch,
              activeColor: Colors.white,
              activeTrackColor: Colors.blue.shade600,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade700,
            )
          : Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
Widget _buildTimePicker(BuildContext context) {
  final controller = Get.find<AlarmController>();

  return Container(
    padding: const EdgeInsets.only(top: 12, bottom: 18, left: 18, right: 18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _buildHourWheel(context),

                // FIXED "h"
                Text(
                  context.lang.h,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontSize: 17 * SizeConfigs.textScale,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // FIXED ":"
            Text(
              ":",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 17 * SizeConfigs.textScale,
              ),
            ),

            const SizedBox(width: 10),

            Row(
              children: [
                _buildMinuteWheel(context),

                // FIXED "min"
                Text(
                  context.lang.min,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontSize: 17 * SizeConfigs.textScale,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 15),

            _buildAmPmWheel(context),
          ],
        )
      ],
    ),
  );
}
Widget _buildHourWheel(BuildContext context) {
  final controller = Get.find<AlarmController>();
  const int infiniteCount = 10000;

  // 🟢 Define Styles here for clean code
  final TextStyle selectedStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
    color: AppColors.white,
    fontSize: 17 * SizeConfigs.textScale,
  );

  final TextStyle unselectedStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
    color: AppColors.textBoldColor,
    fontSize: 14 * SizeConfigs.textScale,
    fontWeight: FontWeight.w300,
  );

  return SizedBox(
    height: 120,
    width: 50,
    child: ListWheelScrollView.useDelegate(
      controller: controller.hourController,
      itemExtent: 35,
      useMagnifier: true,
      perspective: 0.002,
      squeeze: 1.1, // 🟢 Helps keep the active item dead-center
      physics: const FixedExtentScrollPhysics(),
      // onSelectedItemChanged: (index) {
      //   // 🟢 Logic: Convert 0-11 index to 1-12 display
      //   int val = (index % 12);
      //   if (val == 0) val = 12;
      //   controller.hour.value = val;
      //   controller.saveWakeUpTime();
      // },
      // Inside the Hour ListWheelScrollView in the BottomSheet:
      onSelectedItemChanged: (index) {
        int displayHour = (index % 12);
        if (displayHour == 0) displayHour = 12;
        controller.hour.value = displayHour;
        // Trigger save if needed
        controller.saveWakeUpTime();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: infiniteCount,
        builder: (context, index) {
          // 🟢 Display Logic
          int displayHour = (index % 12);
          if (displayHour == 0) displayHour = 12;

          return Obx(() {
            final isSelected = controller.hour.value == displayHour;

            return Center(
              child: Text(
                displayHour.toString().padLeft(2, '0'),
                style: isSelected ? selectedStyle : unselectedStyle,
              ),
            );
          });
        },
      ),
    ),
  );
}
Widget _buildMinuteWheel(BuildContext context) {
  final controller = Get.find<AlarmController>();
  const int infiniteCount = 10000;

  return SizedBox(
    height: 120,
    width: 50,
    child: ListWheelScrollView.useDelegate(
      controller: controller.minuteController,
      itemExtent: 35,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      // 🟢 Logic: index % 60 gives 0 to 59
      onSelectedItemChanged: (index) => controller.setMinute(index % 60),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: infiniteCount,
        builder: (context, index) {
          final value = index % 60;
          return Obx(() {
            final isSelected = controller.minute.value == value;
            return Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: isSelected
                    ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontSize: 17 * SizeConfigs.textScale,
                )
                    : Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textBoldColor,
                  fontSize: 14 * SizeConfigs.textScale,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          });
        },
      ),
    ),
  );
}
Widget _buildAmPmWheel(BuildContext context) {
  final controller = Get.find<AlarmController>();

  return SizedBox(
    height: 120,
    width: 50,
    child: ListWheelScrollView.useDelegate(
      controller: controller.amPmController,
      itemExtent: 35,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        controller.isAm.value = (index == 0);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 2,
        builder: (context, index) {
          return Obx(() {
            final text = index == 0 ? context.lang.AM : context.lang.PM;
            final isSelected = controller.isAm.value == (index == 0);

            return Center(
              child: Text(
                text,
                style: isSelected
                    ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontSize: 17 * SizeConfigs.textScale,
                )
                    : Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textBoldColor,
                  fontSize: 14 * SizeConfigs.textScale,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          });
        },
      ),
    ),
  );
}

/// Helper to keep the logic clean and unified
void _handleBackAndSave(BuildContext context) {
  final controller = Get.find<AlarmController>();

  // 1. If it's ON, schedule it locally so the 'nextAlarmTime' string is ready for the API
  if (controller.wakeUp.value) {
    controller.scheduleAlarm();
  }

  // 2. Only call API if the state changed OR if it's currently ON (to save time changes)
  bool stateChanged = controller.wakeUp.value != controller.initialWakeUpState;

  if (controller.wakeUp.value || stateChanged) {
    if (Get.isRegistered<ProfileController>()) {
      final currentData = Get.find<ProfileController>().settings.value;
      if (currentData != null) {
        // This will now send the valid 'nextAlarmTime' to the server
        controller.saveAlarmSettings(currentData,context);
      } else {
        Get.back();
      }
    } else {
      Get.back();
    }
  } else {
    // It was OFF and stayed OFF. No need to hit the server.
    Get.back();
  }
}
