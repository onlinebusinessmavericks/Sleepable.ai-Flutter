
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../core/utils/library.dart';

import 'dart:math' as math;
import 'package:get/get.dart';

import '../../../data/services/api_sevices.dart';
import '../../../widgets/timezone.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/model/UserSettings.dart';
import '../../settings/model/user_settings_model.dart';

class ProfileSleepGoalController extends GetxController {
  /// 🔑 FINAL VALUES (24h)
  RxDouble bedTime = 21.0.obs;
  RxDouble wakeUpTime = 6.5.obs;

  /// 🟡 LIVE VALUES (USED DURING DRAG)
  RxDouble liveBed = 21.0.obs;
  RxDouble liveWake = 6.5.obs;

  static const double minuteStep = 5 / 60;
  static const double minSleepHours = 10 / 60;
  RxBool isSaving = false.obs;
  @override
  void onInit() {
    // Get data passed from the Profile Screen settings
    if (Get.arguments != null) {
      // Logic to parse "07:00" string back to double 7.0
      String bedStr = Get.arguments['bedtime'] ?? "21:00";
      String wakeStr = Get.arguments['wake_up_time'] ?? "06:30";

      bedTime.value = _parseTimeToDouble(bedStr);
      wakeUpTime.value = _parseTimeToDouble(wakeStr);
    }

    liveBed.value = bedTime.value;
    liveWake.value = wakeUpTime.value;
    super.onInit();
  }

  double _parseTimeToDouble(String time) {
    List<String> parts = time.split(':');
    return double.parse(parts[0]) + (double.parse(parts[1]) / 60);
  }

  // ================= SNAP =================
  double snap(double v) => (v / minuteStep).round() * minuteStep;

  // ================= 24H GAUGE LOGIC =================
  // We no longer need complicated mapping. The value is just the hour.
  // We just ensure it stays within 0-24.
  double cleanValue(double v) {
    if (v < 0) return v + 24;
    if (v >= 24) return v - 24;
    return v;
  }
// ================= FORMAT =================
  String formatTime(double value) {
    final h24 = value.floor();
    final m = ((value - h24) * 60).round();
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 >= 12 ? "PM" : "AM";
    return "${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm";
  }

  // Update this to handle 12h/24h conversion more smoothly
  double toGauge(double hour24) {
    double h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

// Fixed logic for smooth dragging
  double gaugeToTimeline(double gaugeValue, double reference24) {
    double hour = gaugeValue == 12 ? 0 : gaugeValue;
    // If moving around 12, check if we are closer to the current AM or PM block
    double candidate1 = hour;      // AM or early block
    double candidate2 = hour + 12; // PM or late block

    // Pick the one closest to the current live value to prevent "jumping"
    if ((candidate1 - reference24).abs() < (candidate2 - reference24).abs()) {
      return candidate1;
    }
    return candidate2;
  }
// Inside ProfileSleepGoalController
// ================= DURATION =================
// ================= DURATION =================
  String get liveDuration => durationFrom(liveBed.value, liveWake.value);

  String durationFrom(double start, double end) {
    double diff = end - start;
    if (diff < 0) diff += 24;

    final totalMinutes = (diff * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  // ================= ARC =================
  double visualWake(double start, double end) {
    if (end <= start) end += 24;
    if (end - start < minSleepHours) {
      end = start + minSleepHours;
    }
    final dur = math.min(end - start, 11.9167);
    double g = toGauge(start) + dur;
    if (g > 12) g -= 12;
    return g;
  }

  bool get liveCrossesMidnight =>
      liveWake.value <= liveBed.value;

  double _lastHapticValue = -1;

  bool shouldHaptic(double newValue) {
    if ((newValue - _lastHapticValue).abs() >= minuteStep) {
      _lastHapticValue = newValue;
      return true;
    }
    return false;
  }
// ProfileSleepGoalController.dart
  Future<void> saveSleepGoal(UserSettingsData currentSettings) async {
    if (isSaving.value) return; // Prevent multiple clicks

    try {
      isSaving.value = true; // ⏳ Start loading
      String deviceTimezone = await getCurrentTimezone();

      String doubleToApi(double value) {
        final h = value.floor() % 24;
        final m = ((value % 1) * 60).round() % 60;
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00";
      }

      UserSettings requestBody = UserSettings(
        bedtime: doubleToApi(bedTime.value),
        wakeUpTime: doubleToApi(wakeUpTime.value),
        alarmTime: doubleToApi(wakeUpTime.value),
        alarmEnabled: currentSettings.alarmEnabled,
        meridiem: currentSettings.meridiem,
        repeatType: currentSettings.repeatType,
        repeatDays: currentSettings.repeatDays,
        melodyId: currentSettings.melodyId,
        snoozeMinutes: currentSettings.snoozeMinutes,
        fadeIn: currentSettings.fadeIn,
        sleepReminders: currentSettings.sleepReminders,
        remindAt: _ensureApiFormat(currentSettings.remindAt),
        batteryWarning: currentSettings.batteryWorning,
        heartRateTracking: currentSettings.heartRateTracking,
        notifications: currentSettings.notifications,
        timezone: deviceTimezone,
      );

      final response = await SettingsApis.updateUserSettings(requestBody);

      if (response.success) {
        if (Get.isRegistered<ProfileController>()) {
          await Get.find<ProfileController>().fetchSettings();
        }
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchHomePageData();
        }
        Get.back();
      } else {
        Get.snackbar(Get.context?.lang.error ??"Error", response.message ?? "Update failed");
      }
    } catch (e) {
      print("❌ Error: $e");
      Get.snackbar(Get.context?.lang.error ??"Error",Get.context?.lang.someWhat ?? "Something went wrong");
    } finally {
      isSaving.value = false; // ✅ Stop loading
    }
  }

  String _ensureApiFormat(String? timeStr, {String fallback = "00:00:00"}) {
    if (timeStr == null || timeStr.isEmpty || !timeStr.contains(':')) return fallback;
    List<String> parts = timeStr.split(':');
    String h = parts[0].padLeft(2, '0');
    String m = parts.length > 1 ? parts[1].padLeft(2, '0') : "00";
    return "$h:$m:00";
  }

}