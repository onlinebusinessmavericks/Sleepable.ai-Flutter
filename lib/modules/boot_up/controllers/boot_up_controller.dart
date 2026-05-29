
import 'dart:convert';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import 'dart:async';
import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../data/services/common.dart';
import 'package:video_player/video_player.dart';
import '../../login/model/login_model.dart';

class BootUpController extends GetxController {
  late VideoPlayerController videoController;
  final RxBool isVideoReady = false.obs;
  bool _navigated = false;

  // Change to late or initialize via prefs directly in navigateNext
  late SharedPreferences prefs;

  @override
  void onInit() {
    super.onInit();
    initCall();
  }

  Future<void> initCall() async {
    prefs = await SharedPreferences.getInstance(); // Initialize once
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      videoController = VideoPlayerController.asset(Assets.onboardingBootUpFinal);
      await videoController.initialize();

      if (videoController.value.hasError) throw Exception(Get.context?.lang.videoError);

      isVideoReady.value = true;
      videoController.play();
      videoController.addListener(_videoListener);

      // 🕒 Safety Timeout: If video hangs, navigate after 6 seconds anyway
      Future.delayed(const Duration(seconds: 6), () => _navigateNext());

    } catch (e) {
      debugPrint("❌ Video Error: $e");
      _navigateNext();
    }
  }

  void _videoListener() {
    if (_navigated) return;

    final value = videoController.value;
    if (value.position >= value.duration) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (_navigated) return;
    _navigated = true;

    videoController.removeListener(_videoListener);
    if (videoController.value.isPlaying) videoController.pause();

    // 1️⃣ Onboarding Checks (Local Prefs are enough here)
    if (!(prefs.getBool(AppSharedPreferenceKeys.onboardingCompleted) ?? false)) return Get.offAllNamed(Routes.welcome);
    if (!(prefs.getBool(AppSharedPreferenceKeys.bodyScannerCompleted) ?? false)) return Get.offAllNamed(Routes.bodyScanner);
    if (!(prefs.getBool(AppSharedPreferenceKeys.sleepReportCompleted) ?? false)) return Get.offAllNamed(Routes.sleepReport);
    if (!(prefs.getBool(AppSharedPreferenceKeys.accurateSleepRecorderCompleted) ?? false)) return Get.offAllNamed(Routes.accurateSleepRecorder);
    if (!(prefs.getBool(AppSharedPreferenceKeys.bestSoundMachineCompleted) ?? false)) return Get.offAllNamed(Routes.bestSoundMachine);

    final bool loggedIn = prefs.getBool(AppSharedPreferenceKeys.isUserLoggedIn) ?? false;
    final String token = prefs.getString(AppSharedPreferenceKeys.apiToken) ?? '';

    // 2️⃣ Session & Tracker Logic
    if (loggedIn && token.isNotEmpty) {
      try {
        // 🔥 Calling NEW API to check real-time status
        final statusResponse = await TrackerApis.checkTrackerStatus();

        if (statusResponse.success && statusResponse.data.isRunning) {
          int activeId = statusResponse.data.sleepTrackerId;

          // Sync local preferences with API data just in case
          await prefs.setBool(AppSharedPreferenceKeys.isSleepTrackingActive, true);
          await prefs.setInt('sleep_tracker_id', activeId);

          print("🚀 Resuming active sleep session from API: $activeId");
          Get.offAllNamed(Routes.sleepTracker, arguments: activeId);
        } else {
          // Tracker is NOT running on server, clean up local prefs
          await prefs.setBool(AppSharedPreferenceKeys.isSleepTrackingActive, false);
          await prefs.setInt('sleep_tracker_id', 0);

          Get.offAllNamed(Routes.dashboard);
        }
      } catch (e) {
        debugPrint("❌ Tracker Status API Error: $e");
        // Fallback to Dashboard if API fails but session is valid
        Get.offAllNamed(Routes.dashboard);
      }
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
  @override
  void onClose() {
    videoController.removeListener(_videoListener);
    videoController.dispose();
    super.onClose();
  }
}