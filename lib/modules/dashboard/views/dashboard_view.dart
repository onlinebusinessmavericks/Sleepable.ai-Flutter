import 'dart:io';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:sleepable_ai/modules/profile/views/profile_view.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import '../../../localization/lang_extension.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../progress/views/progress_view.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../../sleep_sound/views/sleep_sound_view.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import '../../sleep_sound/widget/PlayerFullSheetUI.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());

  final SleepSoundController sleepSoundController = Get.find();

  final List<Widget> pages = [HomeScreen(), SleepSoundView(), ProgressScreen(), ProfileScreen()];

  final iconList = [Assets.homeHomeNew, Assets.homeSoundsNew, Assets.homeProgressNew, Assets.homeProfileNew1];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (controller.currentIndex.value != 0) {
          // If not on Home, go back to Home first
          controller.changeTab(0);
          return;
        }

        // Otherwise, show the exit dialog
        if (!didPop) {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit) exit(0);
        }
      },
      child: Obx(() {
        return Scaffold(
          extendBody: true,
          backgroundColor: AppColors.backgroundColor,
          body: Column(
            children: [
              // 🔹 Main Page Content
              Expanded(child: pages[controller.currentIndex.value]),
            ],
          ),

          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.animationStartColor, AppColors.animationEndColor], begin: Alignment.bottomCenter, end: Alignment.topCenter),
              boxShadow: [BoxShadow(color: AppColors.animationEndColor.withOpacity(0.8), blurRadius: 20, spreadRadius: 4)],
            ),
            child: FloatingActionButton(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () async {
                // await Haptics.vibrate(HapticsType.light);
                await Haptics.vibrate(HapticsType.light, useAndroidHapticConstants: true);
                await openSleepOnboardingBottomSheet(context);
              },
              child: Transform.rotate(
                angle: 20 * 3.1415926535 / 180,
                child: Image.asset(Assets.homeDream, width: 32, height: 32, color: Colors.white, filterQuality: FilterQuality.none),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: AnimatedBottomNavigationBar.builder(
            itemCount: iconList.length,
            height: 75,
            tabBuilder: (int index, bool isActive) {
              final color = isActive ? Colors.white : Colors.white30;
              return GestureDetector(
                onTap: () {
                  controller.changeTab(index);

                  if (index == 1) {
                    // 🔊 Sounds tab index
                    sleepSoundController.onSoundTabVisible();
                    sleepSoundController.refreshCurrentTabSilently();
                  }

                  if (index == 2) {
                    // This will initialize the controller (and trigger its onInit)
                    // ONLY if it hasn't been created yet.
                    final progressController = Get.isRegistered<ProgressController>() ? Get.find<ProgressController>() : Get.put(ProgressController());
                  }
                },

                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: isActive ? 15 : 17),
                    Image.asset(iconList[index], color: color, width: isActive ? 28 : 26, height: isActive ? 28 : 26, filterQuality: FilterQuality.none),
                    Text(
                      _getLabel(index, context),
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
            activeIndex: controller.currentIndex.value,
            gapLocation: GapLocation.center,
            notchSmoothness: NotchSmoothness.verySmoothEdge,
            backgroundColor: AppColors.backgroundColor,
            splashColor: Colors.transparent,
            splashSpeedInMilliseconds: 0,
            elevation: 0,
            borderColor: Colors.transparent,
            shadow: const Shadow(color: Colors.transparent),
            backgroundGradient: null,
            onTap: (_) {
              print("object");
            },
          ),
        );
      }),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return GiffyDialog(
              key: const Key("ExitAppDialog"),
              backgroundColor: const Color(0xFF1E1E1E),
              giffy: Center(child: Image.asset(Assets.homeSleepableAppIcon, height: 120, fit: BoxFit.contain)),
              title: Text(
                context.lang.exitApp,
                // 'Exit App?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
              ),
              content: Text(
                context.lang.areYouSureYouWantCloseApp,
                // 'Are you sure you want to close the app?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text(context.lang.cancel, style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Get.back(result: true),
                  child: Text(context.lang.yesExit, style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _getLabel(int index, BuildContext context) {
    switch (index) {
      case 0:
        return context.lang.home; //'Home';
      case 1:
        return context.lang.sounds; //'Sounds';
      case 2:
        return context.lang.progress; //'Progress';
      case 3:
        return context.lang.profile; //'Profile';
      default:
        return '';
    }
  }
}
