
  import 'dart:developer' as dev;

import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import '../../../core/utils/library.dart';
  import '../../../data/services/api_sevices.dart';
  import '../../../localization/lang_extension.dart';
import '../../../widgets/timezone.dart';
  import '../../profile/controllers/profile_controller.dart';
  import '../../profile/model/UserSettings.dart';
  import '../../settings/model/user_settings_model.dart';

  class ProfileSleepReminderController extends GetxController {
    Rx<TimeOfDay> reminderTime = const TimeOfDay(hour: 22, minute: 0).obs;
    RxBool isReminderEnabled = true.obs;
    RxBool isSaving = false.obs;

    @override
    void onInit() {
      super.onInit();
      _loadInitialSettings();
    }

    void _loadInitialSettings() {
      if (!Get.isRegistered<ProfileController>()) return;
      var existing = Get.find<ProfileController>().settings.value;
      if (existing == null) return;

      isReminderEnabled.value = existing.sleepReminders ?? false;

      // Parse existing time safely
      if (existing.remindAt != null && existing.remindAt!.contains(':')) {
        reminderTime.value = _parseTimeString(existing.remindAt!);
      }
    }

    /// Helper to parse "HH:mm:ss" or "HH:mm" safely
    TimeOfDay _parseTimeString(String timeStr) {
      try {
        List<String> parts = timeStr.split(':');
        int hour = int.tryParse(parts[0].trim()) ?? 22;
        int minute = int.tryParse(parts[1].trim()) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return const TimeOfDay(hour: 22, minute: 0);
      }
    }

    /// Helper to force ANY string into "HH:mm:ss"
    /// This fixes the "Time has wrong format" error for all fields
    String _ensureApiFormat(String? timeStr, {String fallback = "00:00:00"}) {
      if (timeStr == null || timeStr.isEmpty || !timeStr.contains(':')) return fallback;

      // If it's already HH:mm:ss, return it. If HH:mm, add :00
      List<String> parts = timeStr.split(':');
      String h = parts[0].padLeft(2, '0');
      String m = parts.length > 1 ? parts[1].padLeft(2, '0') : "00";
      return "$h:$m:00";
    }

    String formatTimeOfDayToApi(TimeOfDay time) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
    }

    String get formattedTime {
      final hour = reminderTime.value.hourOfPeriod == 0 ? 12 : reminderTime.value.hourOfPeriod;
      final minute = reminderTime.value.minute.toString().padLeft(2, '0');
      final period = reminderTime.value.period == DayPeriod.am ? "AM" : "PM";
      return "$hour:$minute $period";
    }

    Future<void> saveSleepReminder(UserSettingsData currentSettings) async {
      if (isSaving.value) return;
      isSaving.value = true;
      String deviceTimezone = await getCurrentTimezone();
      print("🚀 API Timezone Identifier: $deviceTimezone");
      try {
        // 1. Format the new reminder time
        String apiRemindAt = formatTimeOfDayToApi(reminderTime.value);

        // 2. IMPORTANT: Fix ALL other time fields so the API doesn't reject the request
        String fixedAlarmTime = _ensureApiFormat(currentSettings.alarmTime, fallback: "07:00:00");
        String fixedBedtime = _ensureApiFormat(currentSettings.bedtime, fallback: "23:00:00");
        String fixedWakeup = _ensureApiFormat(currentSettings.wakeUpTime, fallback: "07:00:00");

        // 3. Fix the "Invalid pk" error. If 1 doesn't exist, try null or a known valid ID.
        // If your API expects a valid ID, ensure this matches an ID from your music list.
        int? validMelodyId = (currentSettings.melodyId == 0 || currentSettings.melodyId == 1)
            ? null // Sending null often tells the API to use the default melody
            : currentSettings.melodyId;

        UserSettings requestBody = UserSettings(
          alarmEnabled: currentSettings.alarmEnabled,
          alarmTime: fixedAlarmTime, // Fixed
          meridiem: currentSettings.meridiem,
          repeatType: currentSettings.repeatType,
          repeatDays: currentSettings.repeatDays,
          melodyId: validMelodyId, // Fixed PK issue
          snoozeMinutes: currentSettings.snoozeMinutes,
          fadeIn: currentSettings.fadeIn,
          bedtime: fixedBedtime, // Fixed
          wakeUpTime: fixedWakeup, // Fixed
          sleepReminders: isReminderEnabled.value,
          remindAt: apiRemindAt, // Fixed
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
            dev.log("🏠 Home Page Data Refreshed after Reminder Update");
          }
          Get.back();
        } else {
          Get.snackbar(Get.context?.lang.errorLabel ?? "Error", response.message ?? "Format Error");
        }
      } catch (e) {
        debugPrint("❌ API Error: $e");
        Get.snackbar(
            // "Error", "Update failed. Check your internet."
          Get.context?.lang.errorLabel ?? "Error",
          Get.context?.lang.updateFailed ?? "Update failed. Check your internet.",
        );

      } finally {
        isSaving.value = false;
      }
    }

    /// 5. TIME PICKER UI
    Future<void> pickTime(BuildContext context) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: reminderTime.value,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                surface: Color(0xFF0E1A2B),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        reminderTime.value = picked;
      }
    }
  }