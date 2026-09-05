import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../../sleep_tracker_screen/controllers/tracker_exit_guard.dart';
import '../controllers/alarm_controller.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  final controller = Get.find<AlarmController>();

  RxString currentTime = "".obs;
  Timer? _timer;
  Timer? _autoWakeTimer;
  bool _isHandlingWake = false;
  bool _isHandlingSnooze = false;

  /// If user never taps Wake/Snooze, still leave alarm UI and land on Home.
  static const Duration _autoWakeAfter = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _autoWakeTimer = Timer(_autoWakeAfter, () {
      debugPrint("⏰ Auto-Wake: user did not press Wake/Snooze within $_autoWakeAfter");
      _handleWake();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoWakeTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;
    String minute = now.minute.toString().padLeft(2, '0');
    final amPm = (Get.context != null)
        ? (now.hour >= 12 ? Get.context!.lang.PM : Get.context!.lang.AM)
        : (now.hour >= 12 ? 'PM' : 'AM');
    currentTime.value = "${hour.toString().padLeft(2, '0')}:$minute $amPm";
  }

  Future<void> _clearTrackerLocalStateNow() async {
    try {
      if (Get.isRegistered<SleepTrackerController>()) {
        await Get.find<SleepTrackerController>().clearLocalTrackingFlags();
      } else {
        await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
      }
    } catch (e) {
      debugPrint("clearTrackerLocalState error: $e");
    }
  }

  Future<void> _backgroundAfterWake(SleepTrackerController? sleepCtrl) async {
    try {
      if (sleepCtrl != null) {
        await sleepCtrl.performCleanup(sleepCtrl).timeout(
          const Duration(seconds: 12),
          onTimeout: () {},
        );
      } else if (Get.isRegistered<SleepTrackerController>()) {
        final c = Get.find<SleepTrackerController>();
        await c.performCleanup(c).timeout(const Duration(seconds: 12), onTimeout: () {});
      } else {
        await SleepTrackerController.emergencyStopOrphanTracker();
      }
    } catch (e) {
      debugPrint("background wake cleanup error: $e");
      try {
        await SleepTrackerController.emergencyStopOrphanTracker();
      } catch (_) {}
    } finally {
      TrackerExitGuard.endExitNavigation();
      await TrackerExitGuard.showRatingOnceAfterExit();
      _scheduleDeferredProgressRefresh();
    }
  }

  void _scheduleDeferredProgressRefresh() {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        if (!Get.isRegistered<ProgressController>()) {
          Get.put(ProgressController());
        }
        await Get.find<ProgressController>().loadAllData();
      } catch (e) {
        debugPrint("deferred progress refresh error: $e");
      }
    });
  }

  /// Snooze: stop sound, schedule next ring, go Home and wait (unlimited).
  Future<void> _handleSnooze() async {
    if (_isHandlingWake || _isHandlingSnooze) return;
    if (!controller.isSnoozeEnabled) return;

    _isHandlingSnooze = true;
    _autoWakeTimer?.cancel();

    try {
      final mins = controller.snoozeMinutes;
      await controller.stopAlarm(snoozeAfterStop: true).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );

      // Confirm snooze so Home does not feel like Quit/Wake
      try {
        final ctx = Get.context;
        if (ctx != null) {
          toast("${ctx.lang.snooze} $mins ${ctx.lang.min}");
        } else {
          toast("Snoozed $mins min");
        }
      } catch (_) {
        toast("Snoozed $mins min");
      }

      // Home pe chhupa ke wait - no rating / no exit-guard (not a final wake)
      Get.offAllNamed(Routes.dashboard);
      debugPrint("😴 Snooze armed for $mins min - waiting on Home");
    } catch (e) {
      debugPrint("Snooze handler error: $e");
      _isHandlingSnooze = false;
    }
  }

  Future<void> _handleWake() async {
    if (_isHandlingWake) return;
    _isHandlingWake = true;
    _autoWakeTimer?.cancel();
    try {
      // Permanent dismiss - cancel any pending snooze too
      unawaited(
        controller.stopAlarm(snoozeAfterStop: false).timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        ),
      );

      final SleepTrackerController? sleepCtrl =
          Get.isRegistered<SleepTrackerController>() ? Get.find<SleepTrackerController>() : null;

      await _clearTrackerLocalStateNow();

      TrackerExitGuard.beginExitNavigation();
      Get.offAllNamed(Routes.dashboard);

      unawaited(_backgroundAfterWake(sleepCtrl));
    } catch (e) {
      debugPrint("Wake handler error: $e");
      try {
        await _clearTrackerLocalStateNow();
      } catch (_) {}
      TrackerExitGuard.beginExitNavigation();
      Get.offAllNamed(Routes.dashboard);
      unawaited(_backgroundAfterWake(
        Get.isRegistered<SleepTrackerController>() ? Get.find<SleepTrackerController>() : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSnooze = controller.isSnoozeEnabled;

    return WillPopScope(
      onWillPop: () async {
        await _handleWake();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A152F), Colors.black],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => Text(
                      currentTime.value,
                      style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.lang.haveNiceDay,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 60),
                  GestureDetector(
                    onTap: _handleWake,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.6), blurRadius: 15, spreadRadius: 5),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.lang.wakeUp,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (showSnooze) ...[
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _handleSnooze,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          "${context.lang.snooze} ${controller.snoozeMinutes} ${context.lang.min}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
