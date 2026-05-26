import 'dart:async';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../data/services/api_sevices.dart';
import '../../../routes/app_pages.dart';
import '../../alarm/controllers/alarm_controller.dart';
import '../../music/views/music_view.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';

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
  // Future<void> startWithoutMeasuring() async {
  //   if (!Get.isRegistered<AlarmController>()) {
  //     Get.put(AlarmController(), permanent: true);
  //   }
  //
  //   final AlarmController alarmController = Get.find<AlarmController>();
  //   // final alarmController = Get.find<AlarmController>();
  //   try {
  //     isLoading.value = true;
  //     final prefs = await SharedPreferences.getInstance();
  //
  //     final List<int> savedNoteIds =
  //         prefs.getStringList('sleep_note_ids')?.map(int.parse).toList() ?? [];
  //
  //     final String savedDescription =
  //         prefs.getString('sleep_description') ?? '';
  //
  //     final String savedWakeUpTime =
  //         prefs.getString('wake_up_time') ?? '08:30';
  //
  //     final String savedWakeUpTimeam =
  //         prefs.getString('wake_up_time_display') ??
  //             '${alarmController.hour.value.toString().padLeft(2, '0')}:'
  //                 '${alarmController.minute.value.toString().padLeft(2, '0')} '
  //                 '${alarmController.isAm.value ? 'AM' : 'PM'}';
  //     // toast("⏰ ----- Wake up time: $savedWakeUpTimeam");
  //     final int savedHeartRate =
  //         prefs.getInt('heart_rate') ?? 0;
  //     /// 🔍 DEBUG PRINTS
  //    print("🧠 savedNoteIds: $savedNoteIds");
  //     print("📝 savedDescription: $savedDescription");
  //     print("⏰ savedWakeUpTime: $savedWakeUpTime");
  //     print("⏰ savedWakeUpTimeam: $savedWakeUpTimeam");
  //     print("⏰ savedHeartRate: $savedHeartRate");
  //     final response = await TrackerApis.startSleepTracker(
  //       wakeUpTime: savedWakeUpTimeam,
  //       noteIds: savedNoteIds,
  //       description: savedDescription,
  //       heartRate: savedHeartRate,
  //     );
  //
  //     if (response.success == true) {
  //       await prefs.setInt('sleep_tracker_id', response.data!.sleepTrackerId);
  //       await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, true);
  //
  //       // 2. 🔥 THE FIX: Update the reactive variable in SleepSoundController
  //       // This makes the "Start Sleep" button disappear instantly in the UI
  //       if (Get.isRegistered<SleepSoundController>()) {
  //         final soundCtrl = Get.find<SleepSoundController>();
  //         soundCtrl.isTrackingActive.value = true;
  //         print("📢 SleepSoundController notified: isTrackingActive = true");
  //       }
  //       // ✅ IMPORTANT: Clear the temporary pre-sleep notes/description
  //       // so they don't leak into the next night's session.
  //       await prefs.remove('sleep_note_ids');
  //       await prefs.remove('sleep_description');
  //
  //       Get.offNamed(Routes.sleepTracker);
  //     }
  //     else {
  //       Get.snackbar(Get.context?.lang.error ??"Error" , response.message ?? "Failed");
  //     }
  //
  //   } catch (e) {
  //     Get.snackbar(Get.context?.lang.error ?? "Error", e.toString());
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  Future<void> startWithoutMeasuring() async {
    if (!Get.isRegistered<AlarmController>()) {
      Get.put(AlarmController(), permanent: true);
    }

    final AlarmController alarmController = Get.find<AlarmController>();
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

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

        // 🔥 TOAST 2: Server response sync alert
        // toast("✅ Session Active! ID: ${response.data!.sleepTrackerId}");

        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.isTrackingActive.value = true;
          print("📢 SleepSoundController notified: isTrackingActive = true");
        }

        // 🔥 FIX: Controller ko 'permanent: true' ke sath put karo!
        // Isse screen route (Get.offNamed) change hone par bhi controller delete nahi hoga,
        // aur native background notification thread strictly lock rahega.
        final sleepTrackerCtrl = Get.isRegistered<SleepTrackerController>()
            ? Get.find<SleepTrackerController>()
            : Get.put(SleepTrackerController(), permanent: true);

        // Bina kisi delay ke local service start karo (Toasts and checks run inside)
        await sleepTrackerCtrl.triggerInstantBackgroundService();

        await prefs.remove('sleep_note_ids');
        await prefs.remove('sleep_description');

        // Safe page replacement
        Get.offNamed(Routes.sleepTracker);
      }
      else {
        // toast("❌ Backend Rejected Session: ${response.message}");
        Get.snackbar(Get.context?.lang.error ??"Error" , response.message ?? "Failed");
      }

    } catch (e) {
      // toast("💥 Code Exception Triggered: ${e.toString()}");
      Get.snackbar(Get.context?.lang.error ?? "Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  // Future<void> startWithoutMeasuring() async {
  //   try {
  //     isLoading.value = true;
  //     final prefs = await SharedPreferences.getInstance();
  //     final List<int> savedNoteIds =
  //         prefs.getStringList('sleep_note_ids')?.map(int.parse).toList() ?? [];
  //
  //     final String savedDescription =
  //         prefs.getString('sleep_description') ?? '';
  //
  //     final String savedWakeUpTime =
  //         prefs.getString('wake_up_time') ?? '';
  //
  //     /// 🔹 Dummy / default values since not measuring heart rate
  //     final response = await TrackerApis.startSleepTracker(
  //       wakeUpTime: savedWakeUpTime,
  //       noteIds: savedNoteIds,
  //       description: savedDescription,
  //       heartRate: 0,              // 👈 no measurement
  //     );
  //
  //     /// ✅ Navigate after success
  //     Get.offNamed(Routes.sleepTracker);
  //
  //   } catch (e) {
  //     Get.snackbar(
  //       "Error",
  //       "Failed to start sleep tracker",
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  /// Cancel timer if leaving screen
  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
