import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/shared_prefences.dart';
import '../../modules/login/model/login_model.dart';
import '../../data/services/common.dart';
import '../../modules/alarm/controllers/alarm_controller.dart';
import '../../modules/common/controllers/selection_flow_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/dreambot/controllers/dreambot_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/progress/controllers/progress_controller.dart';
import '../../modules/sleep_sound/controllers/sleep_sound_controller.dart';
import '../../modules/sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../../widgets/SubscriptionController.dart';

/// Wipes the previous account from the device so the next login cannot
/// reuse cached home/profile/onboarding state.
class SessionClear {
  SessionClear._();

  /// Logout keeps device onboarding so the user is not sent through the
  /// intro videos again. User data, tokens, and caches are still removed.
  static Future<void> clearForLogout() => _clear(resetOnboarding: false);

  /// Delete also resets onboarding so the same Google/email account is
  /// treated as a brand-new user on this device.
  static Future<void> clearForDelete() => _clear(resetOnboarding: true);

  static Future<void> _clear({required bool resetOnboarding}) async {
    await _signOutProviders();
    await _resetRevenueCat();
    await _wipePrefs(resetOnboarding: resetOnboarding);
    await _resetInMemoryState();
  }

  static Future<void> _signOutProviders() async {
    try {
      final google = GoogleSignIn();
      await google.signOut();
      try {
        await google.disconnect();
      } catch (_) {}
    } catch (e) {
      debugPrint('SessionClear Google signOut: $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('SessionClear Firebase signOut: $e');
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  static Future<void> _resetRevenueCat() async {
    if (!Get.isRegistered<SubscriptionController>()) return;
    await Get.find<SubscriptionController>().clearSessionState();
  }

  static Future<void> _wipePrefs({required bool resetOnboarding}) async {
    final prefs = await SharedPreferences.getInstance();
    final keep = <String>{
      'language_code',
      AppSharedPreferenceKeys.selectedLanguageCode,
      AppSharedPreferenceKeys.currentThemeMode,
      AppSharedPreferenceKeys.displayTimeFormat,
      AppSharedPreferenceKeys.deviceInfo,
      AppSharedPreferenceKeys.appInfo,
      AppSharedPreferenceKeys.deviceId,
      AppSharedPreferenceKeys.deviceName,
      AppSharedPreferenceKeys.deviceVersion,
      AppSharedPreferenceKeys.appVersion,
      AppSharedPreferenceKeys.fcmToken,
      AppSharedPreferenceKeys.platform,
    };
    if (!resetOnboarding) {
      keep.addAll(AppSharedPreferenceKeys.onboardingKeys);
    }

    for (final key in prefs.getKeys().toList()) {
      if (keep.contains(key)) continue;
      await removeKey(key);
      await prefs.remove(key);
    }
  }

  static Future<void> _resetInMemoryState() async {
    loggedInUser.value = UserDataResponseModel();
    isLoggedIn.value = false;
    apiToken = '';

    if (Get.isRegistered<SelectionFlowController>()) {
      Get.find<SelectionFlowController>().selections.clear();
    }

    if (Get.isRegistered<SleepSoundController>()) {
      await Get.find<SleepSoundController>().resetForNewSession();
    }

    _deleteIfRegistered<HomeController>();
    _deleteIfRegistered<ProfileController>();
    _deleteIfRegistered<ProgressController>();
    _deleteIfRegistered<DashboardController>();
    _deleteIfRegistered<AlarmController>();
    _deleteIfRegistered<SleepTrackerController>();
    _deleteIfRegistered<DreamBotController>();
  }

  static void _deleteIfRegistered<T>() {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>(force: true);
      }
    } catch (e) {
      debugPrint('SessionClear delete $T: $e');
    }
  }
}
