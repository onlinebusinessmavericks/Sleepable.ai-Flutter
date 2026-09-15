import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../constants/shared_prefences.dart';
import '../../data/services/api_sevices.dart';
import '../../routes/app_pages.dart';
import '../../widgets/SubscriptionController.dart';

Map<String, dynamic> localOnboardingPayload() {
  if (!getBoolAsync(AppSharedPreferenceKeys.onboardingCompleted)) {
    return {};
  }
  final raw = getStringAsync(AppSharedPreferenceKeys.onboardingData);
  if (raw.isEmpty || raw == '{}') return {};
  try {
    final parsed = jsonDecode(raw);
    if (parsed is Map && parsed.isNotEmpty) {
      return Map<String, dynamic>.from(parsed);
    }
  } catch (_) {}
  return {};
}

/// Pushes quiz answers to the backend when the user is already logged in
/// (delete → login → re-onboard). First-time users send this on login instead.
Future<void> syncOnboardingToBackend() async {
  final token = getStringAsync(AppSharedPreferenceKeys.apiToken);
  if (token.isEmpty) return;
  final payload = localOnboardingPayload();
  if (payload.isEmpty) return;
  try {
    await AuthServiceApis.saveOnboardingData(onboardingData: payload);
  } catch (e) {
    debugPrint('syncOnboardingToBackend failed: $e');
  }
}

/// After login: new users (onboarding flags cleared) go through Welcome.
/// Returning users go to Dashboard, with the start-trial paywall if needed.
Future<void> navigateAfterAuth({required bool showPaywall}) async {
  if (!getBoolAsync(AppSharedPreferenceKeys.onboardingCompleted)) {
    Get.offAllNamed(Routes.welcome);
    return;
  }
  if (!getBoolAsync(AppSharedPreferenceKeys.bodyScannerCompleted)) {
    Get.offAllNamed(Routes.bodyScanner);
    return;
  }
  if (!getBoolAsync(AppSharedPreferenceKeys.sleepReportCompleted)) {
    Get.offAllNamed(Routes.sleepReport);
    return;
  }
  if (!getBoolAsync(AppSharedPreferenceKeys.accurateSleepRecorderCompleted)) {
    Get.offAllNamed(Routes.accurateSleepRecorder);
    return;
  }
  if (!getBoolAsync(AppSharedPreferenceKeys.bestSoundMachineCompleted)) {
    Get.offAllNamed(Routes.bestSoundMachine);
    return;
  }

  if (showPaywall) {
    Get.offAllNamed(Routes.dashboard, arguments: {'show_paywall': true});
  } else {
    Get.offAllNamed(Routes.dashboard);
  }
}

bool shouldShowStartTrialPaywall() {
  if (!Get.isRegistered<SubscriptionController>()) return true;
  final sub = Get.find<SubscriptionController>();
  return !(sub.isPremium.value || sub.isOnFreeTrial);
}
