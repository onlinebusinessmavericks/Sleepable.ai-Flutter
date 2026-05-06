import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../widgets/timezone.dart';
import '../../settings/model/user_settings_model.dart';
import '../model/UserSettings.dart';
import '../model/consecutive_streak_response.dart';
import '../model/user_profile_model.dart';

class ProfileController extends GetxController {


  RxDouble avgSleepHours = 0.0.obs;
  RxBool isStreakLoading = false.obs;

  RxInt bestStreak = 2.obs;
  RxInt daysSober = 88.obs;
  RxDouble progress = 0.0.obs;
  RxDouble totalDays = 3.0.obs;
  RxInt trackedNights = 0.obs;
  RxInt avgSleepScore = 0.obs;
  /// 🌙 Sleep Tracker Switches
  RxBool batteryWarning = false.obs;
  RxBool heartRateTracker = true.obs;

  /// 🔔 Notification Switch
  RxBool notificationEnabled = true.obs;
  var currentStreak = 0.obs;
  // This stores the list of StreakDay objects from the API
  var streakCalendar = <StreakDay>[].obs;
  // Your list of 7 dates to display in the UI
  var streakWeekDates = <DateTime>[].obs;
  final screenScrollController = ScrollController();
  var isStatusBarDark = false.obs;
  final RxBool isProfileLoading = false.obs;
  final Rx<UserProfileData?> profile = Rx<UserProfileData?>(null);

  var statusBarOpacity = 0.0.obs;
  /// -------------------- STATE --------------------
  final RxBool isLoading = false.obs;
  final Rx<UserSettingsData?> settings = Rx<UserSettingsData?>(null);
  @override
  void onInit() {
    super.onInit();

    // 1. Load from storage immediately (Synchronous/Local)
    _loadInitialProfile();
    generateWeekDates();
    fetchStreakData();
    // 2. Then call APIs (Asynchronous/Network)
    fetchProfile();
    fetchSettings();
    updateUserStreak();
    screenScrollController.addListener(onScroll);
  }
  void _precacheUserImage(String? url) {
    if (url != null && url.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(url), Get.context!);
    }
  }
  Future<void> _loadInitialProfile() async {
    final String? cachedData = await getString(AppSharedPreferenceKeys.currentUserData);
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final data = UserProfileData.fromJson(jsonDecode(cachedData));
        profile.value = data;

        // 🚀 Start loading the image from cache into memory immediately
        _precacheUserImage(data.profileImage ?? data.avatarUrl);
      } catch (e) {
        debugPrint("Error loading profile cache: $e");
      }
    }
  }
  void generateWeekDates() {
    DateTime now = DateTime.now();
    // Standardizing to "Midnight" ensures date comparisons don't fail due to minutes/seconds
    DateTime today = DateTime(now.year, now.month, now.day);

    streakWeekDates.value = List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));
  }

  Future<void> fetchStreakData() async {
    try {
      final response = await SettingsApis.getConsecutiveStreak();
      if (response.success == true && response.data != null) {
        currentStreak.value = response.data!.currentStreak ?? 0;
        streakCalendar.assignAll(response.data!.streakCalendar ?? []);

        // Update the date objects based on what the API sent
        _syncDatesWithApi();
      }
    } catch (e) {
      print("Error fetching streak: $e");
    }
  }

  void _syncDatesWithApi() {
    // Map the string dates from API to DateTime objects for the UI Row
    streakWeekDates.value = streakCalendar.map((item) {
      return DateTime.parse(item.date); // Converts "2026-04-03" to DateTime
    }).toList();
  }

// 🟢 Change from Future<void> to Future<bool>
  Future<bool> updateSettings({UserSettingsData? customNewData}) async {
    String deviceTimezone = await getCurrentTimezone();
    try {
      isLoading.value = true;
      final base = customNewData ?? settings.value;

      // 1. Helper to force "HH:mm:ss" (Fixes the 400 Time Format error)
      String _toApiTime(String? t) {
        if (t == null || t.isEmpty) return "00:00:00";
        List<String> parts = t.split(':');
        String h = parts[0].padLeft(2, '0');
        String m = parts.length > 1 ? parts[1].padLeft(2, '0') : "00";
        return "$h:$m:00";
      }

      // 2. THE MELODY GUARD (Fixes the PK error)
      // Your example shows "melody_id": 2 is valid.
      // If we have 0 or 1, we force it to 2.
      int finalMelodyId = (base?.melodyId == 0 || base?.melodyId == 1 || base?.melodyId == null)
          ? 2
          : base!.melodyId!;

      // 3. Construct the Request Object
      final requestBody = UserSettings(
        alarmEnabled: base?.alarmEnabled ?? true,
        alarmTime: _toApiTime(base?.alarmTime),
        meridiem: base?.meridiem ?? "AM",
        repeatType: base?.repeatType ?? "custom",
        repeatDays: base?.repeatDays ?? ["mon", "wed", "fri"],
        melodyId: finalMelodyId, // ✅ Safely set to 2 or higher
        snoozeMinutes: base?.snoozeMinutes ?? 10,
        fadeIn: base?.fadeIn ?? true,
        bedtime: _toApiTime(base?.bedtime),
        wakeUpTime: _toApiTime(base?.wakeUpTime),
        sleepReminders: base?.sleepReminders ?? true,
        remindAt: _toApiTime(base?.remindAt),
        batteryWarning: batteryWarning.value,
        heartRateTracking: heartRateTracker.value,
        notifications: notificationEnabled.value,
        timezone: deviceTimezone,
      );

      // 4. Send to API
      final response = await SettingsApis.updateUserSettings(requestBody);

      if (response.success) {
        await fetchSettings(); // Sync local UI with the server
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Update Settings Error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> updateUserStreak() async {
    try {
      isStreakLoading(true);
      // Format today's date: YYYY-MM-DD
      String today = DateTime.now().toString().split(' ')[0];

      final response = await SettingsApis.updateStreak(today);

      if (response.success && response.data != null) {
        // currentStreak.value = response.data!.streakCount;
        // avgTimeHours.value = response.data!.avgTime;
      }
    } catch (e) {
      debugPrint("❌ Streak Update Error: $e");
    } finally {
      isStreakLoading(false);
    }
  }
  /// -------------------- SETTINGS API --------------------

  Future<void> fetchProfile() async {
    try {
      final UserProfileData? result = await SettingsApis.fetchUserProfile();
      if (result != null) {
        profile.value = result;

        // 🚀 Pre-cache the new image if it changed
        _precacheUserImage(result.profileImage ?? result.avatarUrl);
        avgSleepHours.value = result.avgSleepHours!;
        trackedNights.value = result.trackedNights!;
        avgSleepScore.value = result.avgSleepScore!;
        await setValue(
            AppSharedPreferenceKeys.currentUserData,
            jsonEncode(result.toJson())
        );
      }
    } catch (e) {
      debugPrint("❌ Profile Sync Error: $e");
    }
  }
  /// -------------------- SETTINGS API --------------------
    Future<void> fetchSettings() async {
    try {
      isLoading.value = true;

      final response = await SettingsApis.fetchUserSettings();

      if (response.success == true && response.data != null) {
        final data = response.data!;

        settings.value = data;

        // 🔁 SWITCHES
        batteryWarning.value = data.batteryWorning ?? false;
        heartRateTracker.value = data.heartRateTracking ?? false;
        notificationEnabled.value = data.notifications ?? false;

      } else {
        Get.snackbar("Error", "Failed to load settings");
      }
    } catch (e) {
      debugPrint("⚠️ Settings API error → $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> updateToggles() async {
    if (settings.value == null) return;
    String deviceTimezone = await getCurrentTimezone();
    try {
      // Map existing settings to the Request Model + use current RX values for switches
      final requestBody = UserSettings(
        alarmEnabled: settings.value!.alarmEnabled,
        alarmTime: settings.value!.alarmTime,
        meridiem: settings.value!.meridiem,
        repeatType: settings.value!.repeatType,
        repeatDays: settings.value!.repeatDays,
        melodyId: settings.value!.melodyId,
        snoozeMinutes: settings.value!.snoozeMinutes,
        fadeIn: settings.value!.fadeIn,
        bedtime: settings.value!.bedtime,
        wakeUpTime: settings.value!.wakeUpTime,
        sleepReminders: settings.value!.sleepReminders,
        remindAt: settings.value!.remindAt,
        // The updated values from your Obx switches:
        batteryWarning: batteryWarning.value,
        heartRateTracking: heartRateTracker.value,
        notifications: notificationEnabled.value,
        timezone: deviceTimezone,
      );

      final response = await SettingsApis.updateUserSettings(requestBody);

      if (response.success) {
        // Refresh local settings object to keep data perfectly in sync
        fetchSettings();
      }
    } catch (e) {
      debugPrint("❌ Failed to update toggles: $e");
      // Optional: Revert the UI switch if the API fails
      // fetchSettings();
    }
  }

  @override
  void onClose() {
    // 1. Remove the listener first while the controller is still 'alive'
    if (screenScrollController.hasClients) {
      screenScrollController.removeListener(onScroll);
    }

    // 2. Add a tiny delay or check to let the physics engine settle
    // then dispose
    Future.microtask(() {
      if (!isClosed) {
        screenScrollController.dispose();
      }
    });

    super.onClose();
  }

  void onScroll() {
    if (isClosed || !screenScrollController.hasClients) return;

    try {
      if (!screenScrollController.position.hasContentDimensions) return;

      double offset = screenScrollController.offset;

      if (offset > 100 && !isStatusBarDark.value) {
        isStatusBarDark.value = true;
        _updateStatusBar(Colors.black);
      } else if (offset <= 100 && isStatusBarDark.value) {
        isStatusBarDark.value = false;
        _updateStatusBar(Colors.transparent);
      }
    } catch (e) {
      debugPrint("Scroll handled safely during disposal");
    }
  }
// Helper to keep the code clean
  void _updateStatusBar(Color color) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: color,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  // Generate the last 7 days ending today
  List<DateTime> dates = List.generate(7, (index) {
    // index 6 is today, index 0 is 6 days ago
    return DateTime.now().subtract(Duration(days: 6 - index));
  });
  // Put this inside your build method
  List<DateTime> weekDates = List.generate(7, (index) {
    return DateTime.now().add(Duration(days: index));
  });
  // Inside your GetxController:
// A list of dates where the user successfully tracked their sleep/habit
  RxList<DateTime> completedDates = <DateTime>[
    DateTime.now().subtract(const Duration(days: 1)), // Yesterday (mock data)
    DateTime.now().subtract(const Duration(days: 2)), // 2 Days ago (mock data)
  ].obs;
  // String formatTime(String? time) {
  //   if (time == null || time.isEmpty) return "--";
  //   return time.substring(0, 5); // "07:00:00" → "07:00"
  // }
  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "--";

    try {
      // Splits "17:31:00" into ["17", "31", "00"]
      List<String> parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? "PM" : "AM";

      // Convert 24h to 12h logic
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;

      return "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      // Fallback if parsing fails
      return time.substring(0, 5);
    }
  }

}
