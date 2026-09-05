import 'dart:async';
import 'dart:developer' as dev;
import 'package:audio_session/audio_session.dart';
import 'package:camera/camera.dart';

// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';

// import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/notification_service.dart';
import '../../../widgets/timezone.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/model/UserSettings.dart';
import '../../settings/model/user_settings_model.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../views/alarm_ringing_view.dart';

class AlarmController extends GetxController with WidgetsBindingObserver {
  // --------------------------
  // UI Values
  // --------------------------
  RxInt hour = 8.obs;
  RxInt minute = 30.obs;
  RxBool isAm = true.obs;
  RxInt bedHour = 10.obs;
  RxInt bedMinute = 30.obs;
  RxBool bedIsAm = false.obs; // false = PM
  RxBool fadeIn = false.obs;
  RxBool wakeUp = false.obs;

  FixedExtentScrollController? hourController;
  FixedExtentScrollController? minuteController;
  FixedExtentScrollController? amPmController;

  FixedExtentScrollController? hourBedTimeController;
  FixedExtentScrollController? minuteBedTimeController;
  FixedExtentScrollController? amPmBedTimeController;
  bool wheelsSynced = false;
  bool wakeUpWheelsSynced = false;
  bool bedTimeWheelsSynced = false;
  var scale = 1.0.obs;
  RxBool isProcessingBack = false.obs;
  @override

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.onAlarmRingNotificationTap = openRingingFromNotification;
    // 1. Set HARD defaults immediately
    hour.value = 8;
    minute.value = 30;
    isAm.value = true;

    _initControllers();

    if (Get.isRegistered<ProfileController>()) {
      var s = Get.find<ProfileController>().settings.value;
      if (s != null) {
        _loadFromSettingsData(s);
      }
    } else {
      await _loadSavedAlarm();
    }

    // Force a sync to ensure the controllers are at 8:30
    syncWheels();
    isProcessingBack.value = false;

    // Restore snooze after process survival / route clears
    unawaited(_restorePendingSnoozeOrRing());
  }
  // Inside AlarmController
  void prepareWakeUpPicker() {
    wakeUpWheelsSynced = false;
    // We don't re-initialize controllers here to avoid losing
    // attachment to the ListWheelScrollView
  }
  void updateScale(double value) {
    scale.value = value;
  }
  void debugValues(String source) {
    print("-----------------------------------------");
    print("🔍 DEBUG REPORT FROM: [$source]");
    print("⏰ Current Rx State: ${hour.value}:${minute.value.toString().padLeft(2, '0')} ${isAm.value ? 'AM' : 'PM'}");
    print("🎡 Controllers: Hour: ${hourController?.hasClients}, Min: ${minuteController?.hasClients}, AM/PM: ${amPmController?.hasClients}");
    if (hourController?.hasClients ?? false) {
      print("📍 Wheel Indices: Hour: ${hourController?.selectedItem}, Min: ${minuteController?.selectedItem}");
    }
    print("-----------------------------------------");
  }


  void syncWakeUpWheels() {
    if (hourController?.hasClients != true || minuteController?.hasClients != true) return;

    const int offset = 5040;
    try {
      // 🟢 Perfect logic math
      int hIndex = offset + (hour.value % 12);
      int mIndex = offset + minute.value;
      int apmIndex = isAm.value ? 0 : 1;

      hourController!.jumpToItem(hIndex);
      minuteController!.jumpToItem(mIndex);

      if (amPmController != null && amPmController!.hasClients) {
        amPmController!.jumpToItem(apmIndex);
      }

      wakeUpWheelsSynced = true;
      debugPrint("🎯 BottomSheet Centered at: ${hour.value}:${minute.value}");
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    }
  }
  // ... other variables ...
  void prepareBedtimePicker() {
    nextAlarmTime.value = '';
    bedTimeWheelsSynced = false;
  }
  void syncBedTimeWheels() {
    // 🟢 Safety Check: If controllers are disposed or not in UI, stop immediately.
    if (hourBedTimeController == null || hourBedTimeController?.hasClients != true) return;
    if (minuteBedTimeController == null || minuteBedTimeController?.hasClients != true) return;

    const int offset = 5040;

    try {
      // 🟢 Calculate indices based on current bedHour and bedMinute
      int hIndex = offset + (bedHour.value % 12);
      int mIndex = offset + bedMinute.value;
      int apmIndex = bedIsAm.value ? 0 : 1;

      // 🟢 Force Jump - This snaps the wheels instantly
      hourBedTimeController!.jumpToItem(hIndex);
      minuteBedTimeController!.jumpToItem(mIndex);

      if (amPmBedTimeController != null && amPmBedTimeController!.hasClients) {
        amPmBedTimeController!.jumpToItem(apmIndex);
      }

      bedTimeWheelsSynced = true;
      debugPrint("🎯 Bedtime Wheels Synced to: ${bedHour.value}:${bedMinute.value}");
    } catch (e) {
      debugPrint("❌ Prevented Bedtime sync crash: $e");
    }
  }

  bool initialWakeUpState = false;

  void _loadFromSettingsData(UserSettingsData data) {
    wakeUp.value = data.alarmEnabled;
    initialWakeUpState = data.alarmEnabled;
    fadeIn.value = data.fadeIn;

    // Hydrate repeat-day chips from English API keys (sun/mon/...).
    final apiDays = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
    if (data.repeatDays.isNotEmpty) {
      final normalized = data.repeatDays.map((d) => d.toLowerCase().trim()).toSet();
      for (int i = 0; i < apiDays.length && i < selected.length; i++) {
        selected[i] = normalized.contains(apiDays[i]);
      }
      selected.refresh();
    }

    if (data.alarmTime.contains(":")) {
      final parts = data.alarmTime.split(":");
      int h24 = int.parse(parts[0]);
      int m = int.parse(parts[1]);

      bool isMorning = h24 < 12;
      int h12 = h24 % 12 == 0 ? 12 : h24 % 12;

      hour.value = h12;
      minute.value = m;
      isAm.value = isMorning;

      // 🔥 CRITICAL FIX: Force the wheels to jump to the new data
      Future.delayed(const Duration(milliseconds: 300), () {
        syncWheels();
        syncWakeUpWheels();
      });
    }
  }
  Future<void> saveWakeUpTime() async {
    final prefs = await SharedPreferences.getInstance();

    // 🔹 If nothing selected yet → use default 8:30 AM
    int hour12Value = hour.value == 0 ? 8 : hour.value;
    int minuteValue = minute.value;
    bool isAmValue = isAm.value;

    // If minute also not initialized
    if (hour.value == 0 && minute.value == 0) {
      minuteValue = 30;
      isAmValue = true;
    }

    // 🔹 Convert 12h → 24h
    int hour24;

    if (isAmValue) {
      hour24 = hour12Value % 12;
    } else {
      hour24 = (hour12Value % 12) + 12;
    }

    final formatted = "${hour24.toString().padLeft(2, '0')}:${minuteValue.toString().padLeft(2, '0')}";

    await prefs.setString("wake_up_time", formatted);

    print("💾 Final Saved Wake Up Time: $formatted");
  }


  void _initControllers() {
    const int offset = 5040;

    // 🟢 Created ONLY ONCE at default values.
    hourController = FixedExtentScrollController(initialItem: offset + (hour.value % 12));
    minuteController = FixedExtentScrollController(initialItem: offset + minute.value);
    amPmController = FixedExtentScrollController(initialItem: isAm.value ? 0 : 1);

    hourBedTimeController = FixedExtentScrollController(initialItem: offset + (bedHour.value % 12));
    minuteBedTimeController = FixedExtentScrollController(initialItem: offset + bedMinute.value);
    amPmBedTimeController = FixedExtentScrollController(initialItem: bedIsAm.value ? 0 : 1);
  }

  Future<void> _loadSavedAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTime = prefs.getString("wake_up_time_display");

    if (storedTime == null || storedTime.isEmpty) {
      hour.value = 8; minute.value = 30; isAm.value = true;
      return;
    }

    final parts = storedTime.split(":");
    int h24 = int.parse(parts[0]);
    int m = int.parse(parts[1].split(" ")[0]);

    bool isMorning = h24 < 12;
    int h12 = h24 % 12 == 0 ? 12 : h24 % 12;

    hour.value = h12;
    minute.value = m;
    isAm.value = isMorning;
    wakeUp.value = true;

    // 🔥 CRITICAL FIX: Do NOT recreate controllers.
    // Force the existing UI wheels to jump to the new data!
    Future.delayed(const Duration(milliseconds: 300), () {
      syncWheels();
      syncWakeUpWheels();
    });
  }

  // Inside AlarmController
  void syncWheels() {
    // 🟢 Safety: If the UI isn't ready or controllers aren't attached, stop.
    if (hourController?.hasClients != true || minuteController?.hasClients != true) return;

    const int offset = 5040;

    try {
      // 🟢 Logic: Calculate indices based on the CURRENT Rx values (e.g., 10 and 32)
      final int hIndex = offset + (hour.value % 12);
      final int mIndex = offset + minute.value;
      final int apmIndex = isAm.value ? 0 : 1;

      // 🟢 Use jumpToItem to snap instantly to the correct position
      hourController!.jumpToItem(hIndex);
      minuteController!.jumpToItem(mIndex);
      amPmController!.jumpToItem(apmIndex);

      wheelsSynced = true;
      debugPrint("✅ Centered Wheels at: ${hour.value}:${minute.value} ${isAm.value ? 'AM' : 'PM'}");
    } catch (e) {
      print("❌ Sync error: $e");
    }
  }
  Future<void> disableAlarm() async {
    alarmTimer?.cancel();           // Stop the ticking timer
    nextAlarmTime.value = "";       // Clear the "08:30 AM" display
    originalAlarmDateTime = null;
    nextAlarmDateTime = null;
    wakeUp.value = false;           // Ensure the switch stays off
    await _clearPersistedSnooze();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("wake_up_time"); // Clear local storage

    print("🛑 Local Alarm fully disabled");
  }

  void setHour(int index) {
    int newValue = (index % 12) + 1;
    if (hour.value != newValue) {
      hour.value = newValue;
      saveWakeUpTime();
    }
  }

  void setMinute(int index) {
    int newValue = index % 60;
    if (minute.value != newValue) {
      minute.value = newValue;
      saveWakeUpTime();
    }
  }

  void setAmPm(int index) {
    isAm.value = (index == 0);
    if (Get.context != null) {
      nextAlarmTime.value = displayAlarmTime(Get.context!);
    }
    saveWakeUpTime();
    syncWheels();
  }


  // --------------------------
  // Permissions for Android 12+ exact alarm
  // --------------------------
  // Inside AlarmController
  Future<void> prepareAlarmPermissions() async {
    // Check exact alarm
    await requestExactAlarmPermission();

    // Check notifications (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Check Overlay
    var status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      // Show a quick message so user knows why they are leaving the app
      Get.snackbar(
        Get.context?.lang.permissionRequired ?? "Permission Required",
        Get.context?.lang.pleaseAllowDisplayOverOtherAppsAlarmScreenAppear ?? "Please allow 'Display over other apps' so the alarm screen can appear.",
        // "Permission Required",
        // "Please allow 'Display over other apps' so the alarm screen can appear.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      await Future.delayed(const Duration(seconds: 2));
      await checkOverlayPermission();
    }
  }
  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }
  Future<void> checkOverlayPermission() async {
    if (GetPlatform.isAndroid) {
      var status = await Permission.systemAlertWindow.status;
      if (!status.isGranted) {
        await Permission.systemAlertWindow.request();
      }
    }
  }
  // --------------------------
  // Alarm Scheduling
  // --------------------------
  Timer? alarmTimer;
  RxString nextAlarmTime = "".obs;

  DateTime? originalAlarmDateTime; // the initial alarm time
  DateTime? nextAlarmDateTime; // for current alarm or snooze

  AudioPlayer? alarmPlayer;

  RxString selectedMelody = "Forest Stream".obs;
  RxString selectedMelodyAsset = Assets.musicForestStreamMusic.obs;

  void setMelody(String name, String assetPath) {
    selectedMelody.value = name;
    selectedMelodyAsset.value = assetPath;
  }

  RxString selectedSnooze = "10".obs;
  String getSnoozeDisplay(BuildContext context) {
    if (selectedSnooze.value == "0") return context.lang.never;
    return "${selectedSnooze.value} ${context.lang.min}";
  }
  void setSnooze(String value) => selectedSnooze.value = value;

  // --------------------------
  // Schedule Main Alarm
  // --------------------------

  void scheduleAlarm() async {
    print("📅 scheduleAlarm() called");

    // 1. Convert 12h to 24h for DateTime calculation
    int h = hour.value;
    if (!isAm.value && h != 12) h += 12; // PM logic
    if (isAm.value && h == 12) h = 0;    // 12 AM logic

    final now = DateTime.now();
    // Create the target time for today
    originalAlarmDateTime = DateTime(now.year, now.month, now.day, h, minute.value);

    // 2. 🛡️ Safety: If time has already passed today, set for tomorrow
    if (originalAlarmDateTime!.isBefore(now)) {
      originalAlarmDateTime = originalAlarmDateTime!.add(const Duration(days: 1));
    }

    nextAlarmDateTime = originalAlarmDateTime;
    final duration = nextAlarmDateTime!.difference(now);

    // 3. Start the actual Timer
    _startAlarmTimer(duration);

    // 4. 🔥 CRITICAL UI UPDATES
    // Ensure the reactive variables are updated so Obx catches them
    nextAlarmTime.value = _formatTime(nextAlarmDateTime!);
    wakeUp.value = true; // Force the switch to "ON"

    // 5. 💾 PERSISTENCE (Save everything)
    final prefs = await SharedPreferences.getInstance();

    // Save 24h format for API/Logic
    await prefs.setString("wake_up_time", apiAlarmTime);

    // Save Display format for UI (e.g., "08:30 AM")
    await prefs.setString("wake_up_time_display", nextAlarmTime.value);

    // Save the Enabled state
    await prefs.setBool("alarm_enabled", true);

    print("⏰ Alarm confirmed for: ${nextAlarmTime.value}");
    print("⏳ Rings in: ${duration.inHours}h ${duration.inMinutes % 60}m");
  }
  // --------------------------
  // Ring Alarm
  // --------------------------
  Future<void> ringAlarm() async {
    final session = await AudioSession.instance;
    print("🔔 [ALARM] Ringing Sequence Started...");

    // First ring: tear down tracker + finalize session (AI wake_time).
    // Snooze re-ring: session already stopped - skip.
    if (Get.isRegistered<SleepTrackerController>()) {
      final tracker = Get.find<SleepTrackerController>();
      final prefs = await SharedPreferences.getInstance();
      final stillHasSession = (prefs.getInt('sleep_tracker_id') ?? 0) > 0;
      if (stillHasSession) {
        await tracker.prepareForAlarmRing();
        await Future.delayed(const Duration(milliseconds: 200));
        unawaited(tracker.finalizeSessionAtAlarmRing());
      }
    }

    try {
      print("🔔 [ALARM] Deactivating Session...");
      await session.setActive(false);

      print("🔔 [ALARM] Reconfiguring Audio Session...");
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: const AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm,
          contentType: AndroidAudioContentType.music,
        ),
      ));

      print("🔔 [ALARM] Activating Session...");
      await session.setActive(true);

      alarmPlayer ??= AudioPlayer();
      print("🔔 [ALARM] Setting Asset: ${selectedMelodyAsset.value}");
      await alarmPlayer!.setAsset(selectedMelodyAsset.value);
      await alarmPlayer!.setLoopMode(LoopMode.one);

      Future.delayed(const Duration(milliseconds: 100), () {
        alarmPlayer!.play();
        print("🔔 [ALARM] Audio PLAYING.");
      });
    } catch (e) {
      print("❌ [ALARM ERROR] Detailed: $e");
      alarmPlayer?.play();
    }

    await _clearPersistedSnooze();
    await _openRingingUiSafely();
  }

  /// Opens ringing UI only when app is resumed - avoids stuck navigator when
  /// snooze fires in background. Plays sound regardless; shows notification if paused.
  Future<void> _openRingingUiSafely() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;

    if (!resumed) {
      _pendingOpenRinging = true;
      try {
        await NotificationService.showAlarmRingNotification();
      } catch (e) {
        debugPrint("alarm notification error: $e");
      }
      debugPrint("🔔 Alarm ready - UI deferred until resume");
      return;
    }

    _pendingOpenRinging = false;
    try {
      await NotificationService.cancelAlarmRingNotification();
    } catch (_) {}

    // Replace current route so tracker (waves/Lottie) is disposed - do not stack under.
    final alreadyRinging = Get.currentRoute.contains('AlarmRinging');
    final onDashboard = Get.currentRoute == Routes.dashboard ||
        Get.currentRoute.contains('dashboard') ||
        Get.currentRoute.contains('Dashboard');

    if (alreadyRinging) {
      Get.off(() => const AlarmRingingScreen());
    } else if (onDashboard) {
      Get.to(() => const AlarmRingingScreen());
    } else {
      Get.off(() => const AlarmRingingScreen());
    }
  }

  /// Notification tap / resume entry.
  void openRingingFromNotification() {
    unawaited(_openRingingUiSafely());
  }

  Future<void> stopAlarm({bool snoozeAfterStop = true}) async {
    try {
      if (alarmPlayer != null) {
        await alarmPlayer!.stop();
        await alarmPlayer!.dispose();
        alarmPlayer = null;
      }
    } catch (e) {
      debugPrint("Error stopping audio: $e");
      alarmPlayer = null;
    }

    if (snoozeAfterStop) {
      await _startSnoozeIfNeeded();
    } else {
      await cancelPendingSnooze();
    }
  }

  /// Cancel a waiting snooze so Wake permanently ends the alarm.
  Future<void> cancelPendingSnooze() async {
    alarmTimer?.cancel();
    alarmTimer = null;
    await _clearPersistedSnooze();
  }

  /// Minutes configured for snooze (0 = Never).
  int get snoozeMinutes {
    if (selectedSnooze.value == "0") return 0;
    return int.tryParse(selectedSnooze.value) ?? 0;
  }

  bool get isSnoozeEnabled => snoozeMinutes > 0;

  bool _pendingOpenRinging = false;
  bool _isAppResumed = true;

  Future<void> _startSnoozeIfNeeded() async {
    if (!isSnoozeEnabled) return;

    final minutes = snoozeMinutes;
    final now = DateTime.now();
    nextAlarmDateTime = now.add(Duration(minutes: minutes));

    print("🕒 Snooze start at $now");
    print("⏰ Snoozed alarm will ring at $nextAlarmDateTime");

    await _persistSnoozeFireAt(nextAlarmDateTime!);
    _startAlarmTimer(nextAlarmDateTime!.difference(now));
    nextAlarmTime.value = _formatTime(nextAlarmDateTime!);
  }

  Future<void> _persistSnoozeFireAt(DateTime dt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppSharedPreferenceKeys.snoozeFireAtMs, dt.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("persist snooze error: $e");
    }
  }

  Future<void> _clearPersistedSnooze() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppSharedPreferenceKeys.snoozeFireAtMs);
    } catch (_) {}
  }

  Future<void> _restorePendingSnoozeOrRing() async {
    try {
      if (_pendingOpenRinging && _isAppResumed) {
        await _openRingingUiSafely();
      }

      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(AppSharedPreferenceKeys.snoozeFireAtMs);
      if (ms == null) return;

      final fireAt = DateTime.fromMillisecondsSinceEpoch(ms);
      final remaining = fireAt.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 1) {
        await prefs.remove(AppSharedPreferenceKeys.snoozeFireAtMs);
        await ringAlarm();
      } else {
        nextAlarmDateTime = fireAt;
        nextAlarmTime.value = _formatTime(fireAt);
        _startAlarmTimer(remaining);
        debugPrint("😴 Restored snooze timer - rings in ${remaining.inSeconds}s");
      }
    } catch (e) {
      debugPrint("restore snooze error: $e");
    }
  }

  void _startAlarmTimer(Duration duration) {
    alarmTimer?.cancel();

    if (duration.isNegative) {
      print("⚠️ Alarm duration is negative, skipping timer.");
      return;
    }

    print("⏳ Timer started for ${duration.inSeconds} seconds");
    alarmTimer = Timer(duration, () {
      unawaited(ringAlarm());
    });
  }
  // --------------------------
  // Format Time
  // --------------------------
  String _formatTime(DateTime dt) {
    int displayHour = dt.hour % 12;
    if (displayHour == 0) displayHour = 12;
    String? amPm = dt.hour >= 12 ? Get.context?.lang.PM : Get.context?.lang.AM;
    return "${displayHour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
  }

  void refreshCurrentTime() {
    final now = DateTime.now();

    int h = now.hour;
    int m = now.minute;
    bool am = h < 12;

    // Convert to 12-hour format
    int displayHour = h % 12;
    if (displayHour == 0) displayHour = 12;

    hour.value = displayHour;
    minute.value = m;
    isAm.value = am;

    print("⏱ Clock synced → $displayHour:$m ${am ? Get.context?.lang.AM : Get.context?.lang.PM}");
  }

  // // Order: Sun → Sat
 List<String> getDaysShort(BuildContext context) {
    final l = context.lang;
    return [l.s, l.m1, l.t, l.w, l.t2, l.f, l.s2];
  }

  List<String> getDaysFull(BuildContext context) {
    final l = context.lang;
    return [l.sun, l.mon, l.tue, l.wed, l.thu, l.fri, l.sat];
  }
  RxList<bool> selected = RxList<bool>.from([true, true, true, true, true, true, false]);

  String getSelectedText(BuildContext context) {
    final lang = context.lang;

    // CASE 1 - All selected
    if (selected.every((e) => e)) return lang.everyDay;

    // CASE 2 - None selected
    if (selected.every((e) => !e)) return lang.noDaysSelected;

    // CASE 3 - Some selected
    List<String> list = [];
    final fullDays = getDaysFull(context); // Translated list yahan se milegi

    for (int i = 0; i < selected.length; i++) {
      if (selected[i]) {
        list.add(fullDays[i]);
      }
    }
    return list.join(" ");
  }

  void toggle(int index) {
    selected[index] = !selected[index];
  }

  String get selectedAlarmTime {
    int h = hour.value;
    final m = minute.value;

    // Convert to 24-hour format
    if (isAm.value && h == 12) h = 0;
    if (!isAm.value && h != 12) h += 12;

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// For API → "07:30", "22:15"
  String get apiAlarmTime {
    int h = hour.value;
    final m = minute.value;

    if (isAm.value && h == 12) h = 0;
    if (!isAm.value && h != 12) h += 12;

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// For UI → "07:30 AM", "10:15 PM"
  String displayAlarmTime(BuildContext context) {
    final h = hour.value.toString().padLeft(2, '0');
    final m = minute.value.toString().padLeft(2, '0');

    // Translation ka use karein
    final period = isAm.value ? context.lang.AM : context.lang.PM;

    return '$h:$m $period';
  }

  /// Helper to force ANY string into strict "HH:mm:ss"
  String _ensureStrictApiFormat(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || !timeStr.contains(':')) return "00:00:00";
    List<String> parts = timeStr.split(':');
    String h = parts[0].padLeft(2, '0');
    String m = parts.length > 1 ? parts[1].padLeft(2, '0') : "00";
    return "$h:$m:00";
  }

// AlarmController.dart
//   Future<void> saveAlarmSettings(UserSettingsData currentSettings,BuildContext context) async {
//     if (isProcessingBack.value) return;
//     isProcessingBack.value = true;
//
//     try {
//       String deviceTimezone = await getCurrentTimezone();
//
//       UserSettings requestBody = UserSettings(
//         // 🔥 Alarm specific updates
//         alarmEnabled: wakeUp.value,
//         alarmTime: _ensureStrictApiFormat(apiAlarmTime),
//         meridiem: isAm.value ? context.lang.AM : context.lang.PM,
//
//         // 🔥 Keep current bedtime and reminders SAFE
//         bedtime: _ensureStrictApiFormat(currentSettings.bedtime),
//         wakeUpTime: _ensureStrictApiFormat(currentSettings.wakeUpTime),
//         remindAt: _ensureStrictApiFormat(currentSettings.remindAt),
//         sleepReminders: currentSettings.sleepReminders,
//
//         // Other fields
//         repeatType: _calculateRepeatType(context),
//         repeatDays: _getApiRepeatDays(context),
//         melodyId: currentSettings.melodyId <= 0 ? 40 : currentSettings.melodyId,
//         // snoozeMinutes: int.tryParse(selectedSnooze.value.split(' ')[0]) ?? 10,
//         snoozeMinutes: int.tryParse(selectedSnooze.value) ?? 10,
//         fadeIn: fadeIn.value,
//         batteryWarning: currentSettings.batteryWorning,
//         heartRateTracking: currentSettings.heartRateTracking,
//         notifications: currentSettings.notifications,
//         timezone: deviceTimezone,
//       );
//
//       final response = await SettingsApis.updateUserSettings(requestBody);
//       if (response.success) {
//         if (Get.isRegistered<ProfileController>()) {
//           await Get.find<ProfileController>().fetchSettings();
//         }
//
//         if (Get.isRegistered<HomeController>()) {
//           Get.find<HomeController>().fetchHomePageData();
//           dev.log("🏠 Home Page Refreshed after Alarm Update");
//         }
//         Get.back();
//       }
//     } finally {
//       isProcessingBack.value = false;
//     }
//   }
//
  Future<void> saveAlarmSettings(UserSettingsData currentSettings, BuildContext context) async {
    if (isProcessingBack.value) return;
    isProcessingBack.value = true;

    try {
      String deviceTimezone = await getCurrentTimezone();

      // 🛡️ 1. Sanitize Meridiem Dynamically for API (Never send translated strings)
      String apiMeridiem = isAm.value ? "AM" : "PM";

      // 🛡️ 2. Sanitize Repeat Type & Repeat Days via helpers
      String apiRepeatType = _calculateRepeatTypeForApi();
      List<String> apiRepeatDays = _getApiRepeatDaysForApi();

      UserSettings requestBody = UserSettings(
        // 🔥 Alarm specific updates
        alarmEnabled: wakeUp.value,
        alarmTime: _ensureStrictApiFormat(apiAlarmTime),
        meridiem: apiMeridiem, // ✅ Safely sends "AM" or "PM"

        // 🔥 Keep current bedtime and reminders SAFE
        bedtime: _ensureStrictApiFormat(currentSettings.bedtime),
        wakeUpTime: _ensureStrictApiFormat(currentSettings.wakeUpTime),
        remindAt: _ensureStrictApiFormat(currentSettings.remindAt),
        sleepReminders: currentSettings.sleepReminders,

        // 🔥 Backend compliant configurations
        repeatType: apiRepeatType,   // ✅ Safely sends "everyday", "once", or "custom"
        repeatDays: apiRepeatDays,   // ✅ Safely sends ["sun", "mon", etc.]

        melodyId: currentSettings.melodyId <= 0 ? 40 : currentSettings.melodyId,
        snoozeMinutes: int.tryParse(selectedSnooze.value) ?? 10,
        fadeIn: fadeIn.value,
        batteryWarning: currentSettings.batteryWorning,
        heartRateTracking: currentSettings.heartRateTracking,
        notifications: currentSettings.notifications,
        timezone: deviceTimezone,
      );

      // Log request payload for confirmation before transmission
      print("🚀 EN ROUTE SANITIZED PAYLOAD: ${requestBody.toJson()}");

      final response = await SettingsApis.updateUserSettings(requestBody);
      if (response.success) {
        if (Get.isRegistered<ProfileController>()) {
          await Get.find<ProfileController>().fetchSettings();
        }

        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchHomePageData();
          dev.log("🏠 Home Page Refreshed after Alarm Update");
        }
        Get.back();
      }
    } catch (e) {
      print("❌ Error in saveAlarmSettings: $e");
    } finally {
      isProcessingBack.value = false;
    }
  }
  String _calculateRepeatTypeForApi() {
    // Check states using direct indexes independent of UI rendering languages
    if (selected.every((e) => e)) {
      return "everyday";
    }
    if (selected.every((e) => !e)) {
      return "once";
    }
    return "custom";
  }

  // ==========================================
  // 🛡️ HELPER 2: HARDCODED ENGLISH SYSTEM KEYS FOR API
  // ==========================================
  List<String> _getApiRepeatDaysForApi() {
    // Backend standard format arrays
    final List<String> standardApiDays = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
    List<String> activeDays = [];

    for (int i = 0; i < selected.length; i++) {
      if (selected[i]) {
        activeDays.add(standardApiDays[i]);
      }
    }
    return activeDays;
  }
  String _calculateRepeatType(BuildContext context) {
    // 1. Agar saare 7 din select hain
    if (selected.every((e) => e)) {
      return context.lang.everyDay;
    }

    // 2. Agar ek bhi din select nahi hai
    if (selected.every((e) => !e)) {
      return context.lang.once;
    }

    // 3. Agar kuch specific din select hain (mon, tue etc.)
    return context.lang.custom;
  }
// Helper for Repeat Days
  List<String> _getApiRepeatDays(BuildContext context) {
    final l = context.lang;
    final List<String> dayKeys = [l.sun, l.mon, l.tue, l.wed, l.thu, l.fri, l.sat];
    List<String> activeDays = [];
    for (int i = 0; i < selected.length; i++) {
      if (selected[i]) activeDays.add(dayKeys[i]);
    }
    return activeDays;
  }
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop sound only - never cancel a persisted snooze here (Home navigation
    // must not kill the waiting re-ring).
    try {
      alarmPlayer?.stop();
      alarmPlayer?.dispose();
      alarmPlayer = null;
    } catch (_) {}
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppResumed = true;
      unawaited(_restorePendingSnoozeOrRing());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isAppResumed = false;
    } else if (state == AppLifecycleState.detached) {
      _isAppResumed = false;
      // Keep persisted snooze; only hush audio if process is dying.
      try {
        alarmPlayer?.stop();
      } catch (_) {}
    }
  }
}
