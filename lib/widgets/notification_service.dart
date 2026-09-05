

import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'dart:developer' as dev;
import 'package:sleepable_ai/routes/app_pages.dart';

import '../core/constants/shared_prefences.dart';
import '../data/services/api_sevices.dart';
import '../modules/sleep_sound/controllers/sleep_sound_controller.dart';
import '../modules/sleep_tracker_screen/controllers/tracker_exit_guard.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Set by AlarmController - avoids circular import.
  static void Function()? onAlarmRingNotificationTap;

  static Future<void> init() async {
    dev.log("🔔 NotificationService: Initializing...");
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      dev.log("🔄 FCM Token Rotated Automatically: $newToken");

      // Check karein ki user logged in hai ya nahi
      bool isLoggedIn = getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn);
      if (isLoggedIn) {
        await _sendTokenToBackend(newToken);
      }
    });

    // 2. Token Updates
    try {
      await updateTokenToServer();
    } catch (e) {
      dev.log("⚠️ Token update skipped: $e");
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      dev.log("🔄 FCM Token Refreshed: $newToken");
      _sendTokenToBackend(newToken);
    });

    // 3. Local Notifications Init
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          handleRedirect(jsonDecode(response.payload!));
        }
      },
    );

    // 4. Message Handlers (Sirf ek-ek baar)
    FirebaseMessaging.onMessage.listen((message) {
      dev.log("🔔 Foreground Message: ${message.notification?.title}");
      if (message.notification != null) {
        showLocalNotification(
          id: message.notification.hashCode,
          title: message.notification!.title ?? "",
          body: message.notification!.body ?? "",
          data: message.data,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) => handleRedirect(message.data));

    // Cold-start: stash the destination immediately (no 2s delay).
    // BootUpController consumes pendingDashboardTab so it does not overwrite
    // Progress with Home after the splash video.
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await stashPendingRedirect(initialMessage.data);
      // Apply once routes are ready - short delay only for GetMaterialApp mount
      Future.delayed(const Duration(milliseconds: 400), () {
        handleRedirect(initialMessage.data);
      });
    } else {
      // Avoid a stale tab from a killed cold-start opening Progress on next launch
      await setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
    }
  }

  /// Persist tab intent before Boot navigates to dashboard (avoids Home → Progress flash).
  static Future<void> stashPendingRedirect(Map<String, dynamic> data) async {
    final type = (data['type'] ?? data['notification_type'] ?? '').toString().toLowerCase();
    final tab = _tabIndexForType(type);
    if (tab != null) {
      await setValue(AppSharedPreferenceKeys.pendingDashboardTab, tab);
      dev.log("📌 Stashed pending dashboard tab: $tab for type=$type");
    }
  }

  static int? _tabIndexForType(String type) {
    switch (type) {
      case 'caffeine_cutoff':
      case 'streak_risk':
      case 'inactivity_alert':
      case 'streak_milestone':
        return 0;
      case 'windup_alert':
        return 1;
      case 'weekly_summary':
      case 'first_sleep_tracked':
      case 'morning_summary':
      case 'sleep_report':
      case 'sleep_report_ready':
      case 'dream_milestone':
        return 2;
      case 'bedtime_reminder':
      case 'milestone_7':
      case 'milestone_25':
      case 'milestone_50':
      case 'milestone_100':
      case 'milestone_200':
      case 'milestone_365':
      case 'badge_unlocked':
        return 3;
      default:
        return null;
    }
  }

  static Future<void> requestNotificationPermission() async {
    dev.log("📡 Requesting Notification Permission from Home Screen...");
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      dev.log("✅ User granted notification permission from Home Screen");
      // Token refresh push karwa dein safe side ke liye
      await updateTokenToServer();
    } else {
      dev.log("❌ User denied notification permission");
    }
  }

  static Future<void> updateTokenToServer() async {
    try {
      if (Platform.isIOS) {
        dev.log("🌐 iOS Token Verification started...");

        // Live Device par APNs token check karein
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          dev.log("⚠️ APNS Token abhi tak generate nahi hua. Kuch der baad dubara try karein.");
          // Kabhi-kabhi iOS me APNs generate hone me thoda time lagta hai
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _messaging.getAPNSToken();
        }

        dev.log("🚀 APNS Token Found: $apnsToken");
      }

      // Ab fresh FCM Token generate karein
      await _messaging.deleteToken();
      String? token = await _messaging.getToken();

      if (token != null) {
        dev.log("🆕 Fresh FCM Token for iOS/Android: $token");
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      dev.log("❌ Error fetching fresh token: $e");
    }
  }
  static Future<void> _sendTokenToBackend(String token) async {
    bool isLoggedIn = getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn);
    if (!isLoggedIn) {
      dev.log("ℹ️ User not logged in, skipping FCM update.");
      return;
    }

    final rawDeviceInfo = getStringAsync(AppSharedPreferenceKeys.deviceInfo);
    Map<String, dynamic> deviceInfo = rawDeviceInfo.isNotEmpty ? jsonDecode(rawDeviceInfo) : {};

    String deviceId = deviceInfo["device_id"] ?? "unknown_device";

    try {
      await AuthServiceApis.updateFcmToken(request: {
        "fcm_token": token,
        "device_id": deviceId,
      });
      dev.log("✅ FCM Token Updated on Backend");
    } catch (e) {
      dev.log("❌ Failed to update FCM Token API: $e");
    }
  }
  static void showLocalNotification({required int id, required String title, required String body, required Map<String, dynamic> data}) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true));

    _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: jsonEncode(data), // Pass data for navigation on tap
    );
  }

  /// Full-screen style cue when snooze/alarm fires while app is backgrounded.
  static Future<void> showAlarmRingNotification({String title = 'Wake-up Alarm', String body = 'Tap to open'}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Wake-up and snooze alarms',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      ongoing: true,
      autoCancel: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await _localNotifications.show(
      id: 9001,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: jsonEncode({'type': 'alarm_ring'}),
    );
  }

  static Future<void> cancelAlarmRingNotification() async {
    try {
      await _localNotifications.cancel(id: 9001);
    } catch (_) {}
  }

  static void handleRedirect(Map<String, dynamic> data) {
    dev.log("🚀 NOTIFICATION DATA RECEIVED: $data");

    if (!data.containsKey('type')) {
      dev.log("❌ ERROR: Key 'type' missing from notification data.");
      return;
    }

    String type = data['type'].toString();
    dev.log("📍 Notification Type: [$type]");

    switch (type) {
      case 'alarm_ring':
        try {
          onAlarmRingNotificationTap?.call();
        } catch (e) {
          dev.log("alarm_ring redirect error: $e");
        }
        break;

    // --- HOME SCREEN (Tab 0) ---
      case 'caffeine_cutoff':
      case 'streak_risk':
      case 'inactivity_alert':
      case 'streak_milestone':
        _switchToTab(0);
        break;

    // --- SOUNDS SCREEN (Tab 1) ---
      case 'windup_alert':
        _switchToTab(1);
        break;

    // --- PROGRESS SCREEN (Tab 2) - sleep report / summaries ---
      case 'weekly_summary':
      case 'first_sleep_tracked':
      case 'morning_summary':
      case 'sleep_report':
      case 'sleep_report_ready':
        _switchToTab(2);
        break;

    // --- DREAM RELATED (Specific Redirects) ---
      case 'dream_report_ready':
      case 'dream_pattern':
        String id = data['dream_id']?.toString() ?? "0";
        // ✅ Match the parameter name 'dreamId' used in Controller onInit
        Get.toNamed("${Routes.dreamBot}?dreamId=$id&fromProgress=true");
        break;
      case 'dream_milestone':
        _switchToTab(2); // Dream screen Progress tab ka part hai
        break;


    // --- PROFILE / BADGES SCREEN (Tab 3) ---
      case 'bedtime_reminder': // Image ke mutabiq ye Sleep Tracker/Profile side hai
      case 'milestone_7':
      case 'milestone_25':
      case 'milestone_50':
      case 'milestone_100':
      case 'milestone_200':
      case 'milestone_365':
      case 'badge_unlocked':

        _switchToTab(3);
        break;

      case 'payment_screen':
        if (Get.currentRoute == Routes.dashboard) {
          _openPremiumSheet();
        } else {
          Get.offAllNamed(Routes.dashboard);
          Future.delayed(const Duration(milliseconds: 800), () => _openPremiumSheet());
        }
        break;

      default:
        dev.log("⚠️ No specific case for type [$type], defaulting to Home");
        _switchToTab(0);
    }
  }
  /// Helper function to switch tabs safely with the Bottom Bar visible
  static bool _isSwitchingTab = false;
  static void _switchToTab(int index) {
    if (_isSwitchingTab) return;
    _isSwitchingTab = true;
    try {
      // During Wake/Quit exit, never remount dashboard (fixes Home double-pop
      // when bedtime_reminder / sleep_report arrives mid-navigation).
      if (TrackerExitGuard.shouldSuppressDashboardRemount) {
        setValue(AppSharedPreferenceKeys.pendingDashboardTab, index);
        if (Get.isRegistered<DashboardController>() && Get.currentRoute == Routes.dashboard) {
          Get.find<DashboardController>().changeTab(index);
          setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
        } else {
          dev.log("⏳ Suppress remount - stashed tab $index during tracker exit");
        }
        return;
      }

      setValue(AppSharedPreferenceKeys.pendingDashboardTab, index);

      if (Get.isRegistered<DashboardController>() && Get.currentRoute == Routes.dashboard) {
        Get.find<DashboardController>().changeTab(index);
        setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
      } else if (Get.currentRoute == Routes.bootUp || Get.currentRoute == '/' || Get.currentRoute.isEmpty) {
        dev.log("⏳ Waiting for BootUp to open dashboard tab $index");
      } else {
        Get.offAllNamed(Routes.dashboard, arguments: index);
        setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSwitchingTab = false;
      });
    }
  }

  // Separate helper for cleaner logs
  static void _openPremiumSheet() {
    try {
      final controller = Get.find<HomeController>();
      if (Get.context != null) {
        dev.log("✅ Context and Controller found. Calling showRotatingPremiumSheet");
        controller.showRotatingPremiumSheet(Get.context!);
      } else {
        dev.log("❌ ERROR: Get.context is NULL. Cannot show bottom sheet.");
      }
    } catch (e) {
      dev.log("❌ ERROR: Could not find HomeController. Make sure it is initialized. Exception: $e");
    }
  }
}
