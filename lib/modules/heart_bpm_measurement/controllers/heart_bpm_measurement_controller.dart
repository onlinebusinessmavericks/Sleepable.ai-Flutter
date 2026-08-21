import 'dart:async';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../data/services/api_sevices.dart';
import '../../../routes/app_pages.dart';
import '../../alarm/controllers/alarm_controller.dart';
import '../../music/views/music_view.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../../sleep_tracker_screen/controllers/tracker_exit_guard.dart';

class HeartBpmMeasurementController extends GetxController {
  Timer? _timer;

  final RxBool isLoading = false.obs;
  var scaleHeartRate = 1.0.obs;
  var scaleMeasuring = 1.0.obs;

  // Add this method to handle the animation state
  void updateScaleHeartRate(double value) {
    scaleHeartRate.value = value;
  }
  void updateScaleMeasuring(double value) {
    scaleMeasuring.value = value;
  }
  /// Start auto navigation after [seconds]
  void startAutoNavigation() {
    // _timer = Timer(Duration(Mi: seconds), () {
    //   if (Get.isOverlaysClosed) {
        Get.toNamed(Routes.heartBPM);
      // }
    // });
  }

  /// Navigate immediately and cancel timer
  void goToNextScreen() {
    _timer?.cancel();
    Get.toNamed(Routes.heartBPM);
  }
  /// Start sleep without heart measurement
  Future<void> startWithoutMeasuring() async {
    if (!Get.isRegistered<AlarmController>()) {
      Get.put(AlarmController(), permanent: true);
    }

    final AlarmController alarmController = Get.find<AlarmController>();
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

      final int existingTrackerId = prefs.getInt('sleep_tracker_id') ?? 0;

      if (existingTrackerId != 0) {
        print("⚠️ Found old/stuck tracker ID ($existingTrackerId). Forcing stop/cleanup first...");

        // Agar controller registered hai toh uske functions se cleanup karo
        if (Get.isRegistered<SleepTrackerController>()) {
          final sleepController = Get.find<SleepTrackerController>();
          sleepController.performCleanup(sleepController);
        } else {
          // Agar controller nahi hai, toh direct API hit karke state clear karo
          try {
            await TrackerApis.stopSleepTracker(sleepTrackerId: existingTrackerId);
          } catch (_) {}
          await prefs.remove('sleep_tracker_id');
          await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
        }
      }

      // ==========================================
      // 🛡️ STEP 1: DEFENSIVE PERMISSIONS CHECK
      // ==========================================
      print("🛡️ Checking permission statuses safely before invoking native engines...");
      try {
        // Only request audio/microphone if it isn't granted yet
        if (!await Permission.microphone.isGranted) {
          await Permission.microphone.request();
        }

        // Only request notification channels if they aren't configured yet
        if (!await Permission.notification.isGranted) {
          await Permission.notification.request();
        }
      } catch (permissionError) {
        // Catches permission race conditions gracefully so code block doesn't crash
        print("⚠️ Permission request pipeline busy: $permissionError");
      }
      // ==========================================

      final List<int> savedNoteIds =
          prefs.getStringList('sleep_note_ids')?.map(int.parse).toList() ?? [];

      final String savedDescription =
          prefs.getString('sleep_description') ?? '';

      final String savedWakeUpTime =
          prefs.getString('wake_up_time') ?? '08:30';

      final String savedWakeUpTimeam =
          prefs.getString('wake_up_time_display') ??
              '${alarmController.hour.value.toString().padLeft(2, '0')}:${alarmController.minute.value.toString().padLeft(2, '0')} ${alarmController.isAm.value ? 'AM' : 'PM'}';

      final int savedHeartRate =
          prefs.getInt('heart_rate') ?? 0;

      /// 🔍 DEBUG PRINTS
      print("🧠 savedNoteIds: $savedNoteIds");
      print("📝 savedDescription: $savedDescription");
      print("⏰ savedWakeUpTime: $savedWakeUpTime");
      print("⏰ savedWakeUpTimeam: $savedWakeUpTimeam");
      print("⏰ savedHeartRate: $savedHeartRate");

      final response = await TrackerApis.startSleepTracker(
        wakeUpTime: savedWakeUpTimeam,
        noteIds: savedNoteIds,
        description: savedDescription,
        heartRate: savedHeartRate,
      );

      if (response.success == true) {
        await prefs.setInt('sleep_tracker_id', response.data!.sleepTrackerId);
        await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, true);
        TrackerExitGuard.resetForNewSession();

        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.isTrackingActive.value = true;
          print("📢 SleepSoundController notified: isTrackingActive = true");
        }

        final sleepTrackerCtrl = Get.isRegistered<SleepTrackerController>()
            ? Get.find<SleepTrackerController>()
            : Get.put(SleepTrackerController(), permanent: true);

        // Re-arm wakelock/listeners if this permanent controller was released after last Wake
        await sleepTrackerCtrl.armSessionResources();

        // ==========================================
        // ⚡ STEP 2: ISOLATED BACKGROUND SERVICE TRIGGER
        // ==========================================
        try {
          // Wrapping background setup in its own try-catch prevents platform-level
          // race conditions from crashing the UI loop.
          await sleepTrackerCtrl.triggerInstantBackgroundService();
        } catch (serviceError) {
          print("💥 Non-blocking issue when starting background threads: $serviceError");
        }
        // ==========================================

        await prefs.remove('sleep_note_ids');
        await prefs.remove('sleep_description');

        // Safe page replacement - Will now definitely trigger!
        Get.offNamed(Routes.sleepTracker);
      }
      else {
        Get.snackbar(Get.context?.lang.error ??"Error" , response.message ?? "Failed");
      }

    } catch (e) {
      Get.snackbar(Get.context?.lang.error ?? "Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  /// Cancel timer if leaving screen
  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
