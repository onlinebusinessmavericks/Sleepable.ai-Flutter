import 'package:sleepable_ai/modules/settings/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/custom_loader.dart';
import '../../language/views/language_view.dart';
import '../../music/views/music_view.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/profile_sleep_reminder_controller.dart';

class ProfileSleepReminderScreen extends StatelessWidget {
  final controller = Get.put(ProfileSleepReminderController());

  ProfileSleepReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return PopScope(
      canPop: false, // Prevents immediate closing
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Get current settings
        final profileCtrl = Get.find<ProfileController>();
        final currentData = profileCtrl.settings.value;

        if (currentData != null) {
          // 2. This calls your API and then Get.back() inside the controller
          await controller.saveSleepReminder(currentData);
        } else {
          Get.back();
        }
      },child:  Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 22.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SmallCircleIcon(
                icon: Icons.arrow_back_rounded,
                size: 20 * SizeConfigs.textScale,
                iconColor: Colors.white,
                backgroundColor: Colors.white10,

                onTap: () => Navigator.maybePop(context),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
            child: Text(
              context.lang.sleepReminder,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
            ),
          ),
          centerTitle: true,
        ),

        body: Obx(() =>Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0E1A2B), Color(0xFF0B1424)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Activate Sleep Reminder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.lang.activateReminder,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Obx(
                            () => Switch(
                              value: controller.isReminderEnabled.value,
                              onChanged: (val) => controller.isReminderEnabled.value = val,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.blue,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: Colors.white.withOpacity(0.1), height: 1),

                    // Remind me at
                    InkWell(
                      onTap: () {
                        if (controller.isReminderEnabled.value) {
                          controller.pickTime(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.lang.remindMeAt, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70, fontSize: 15)),
                            Row(
                              children: [
                                Obx(
                                  () => Text(
                                    controller.formattedTime,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 🔥 FULL SCREEN LOADER OVERLAY
            if (controller.isSaving.value)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54, // Dims the screen
                child: Center(
                  child: LoaderWidget(size: sw(150)),
                ),
              ),
          ],
        ) ),
      ),
    );
  }
}
