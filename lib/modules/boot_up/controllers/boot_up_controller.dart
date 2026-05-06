
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

// class BootUpController extends GetxController {
//   late VideoPlayerController videoController;
//   final RxBool isVideoReady = false.obs;
//
//   bool _navigated = false;
//
//   bool onboardingDone = false;
//   bool bodyScannerDone = false;
//   bool sleepReportDone = false;
//   bool accurateSleepRecorderDone = false;
//   // bool patentedSleepTrackerDone = false;
//   bool bestSoundMachineDone = false;
//   bool loginStatus = false;
//
//   @override
//   void onInit() {
//     super.onInit();
//     initCall();
//   }
//
//   /// 1️⃣ Initialize everything
//   Future<void> initCall() async {
//     await getCacheData();
//     _initVideo();
//   }
//
//   /// 2️⃣ Load SharedPreferences
//   Future<void> getCacheData() async {
//     print("getCacheData");
//
//     onboardingDone =
//         getBoolAsync(AppSharedPreferenceKeys.onboardingCompleted);
//     bodyScannerDone =
//         getBoolAsync(AppSharedPreferenceKeys.bodyScannerCompleted);
//     sleepReportDone =
//         getBoolAsync(AppSharedPreferenceKeys.sleepReportCompleted);
//     accurateSleepRecorderDone =
//         getBoolAsync(AppSharedPreferenceKeys.accurateSleepRecorderCompleted);
//     // patentedSleepTrackerDone =
//     //     getBoolAsync(AppSharedPreferenceKeys.patentedSleepTrackerCompleted);
//     bestSoundMachineDone =
//         getBoolAsync(AppSharedPreferenceKeys.bestSoundMachineCompleted);
//
//     loginStatus =
//         getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn);
//
//     isLoggedIn(loginStatus);
//
//     final token =
//     getStringAsync(AppSharedPreferenceKeys.apiToken);
//     print("------token--------$token");
//
//     if (token.isNotEmpty) {
//       apiToken = token;
//     }
//
//     final userDataStr =
//     getStringAsync(AppSharedPreferenceKeys.currentUserData);
//
//     if (userDataStr.isNotEmpty) {
//       try {
//         final userData = UserDataResponseModel.fromJson(
//           jsonDecode(userDataStr),
//         );
//         loggedInUser(userData);
//       } catch (e) {
//         log("Error decoding user data: $e");
//       }
//     }
//   }
//
//   /// 3️⃣ Initialize boot video
//
//   Future<void> _initVideo() async {
//     try {
//       videoController = VideoPlayerController.asset(
//         Assets.onboardingBootUpFinal,
//       );
//
//       await videoController.initialize();
//
//       // Check if the video is actually playable
//       if (videoController.value.hasError) {
//         throw Exception("Video initialization failed");
//       }
//
//       isVideoReady.value = true;
//       videoController.play();
//       videoController.addListener(_videoListener);
//     } catch (e) {
//       debugPrint("❌ Physical Device Error (Codec unsupported): $e");
//       // 🟢 CRITICAL: If the phone can't play the video, just go to the next screen
//       _navigateNext();
//     }
//   }
//   /// 4️⃣ Listen for video end
//   void _videoListener() {
//     final value = videoController.value;
//
//     if (!value.isInitialized || _navigated) return;
//
//     if (value.position >= value.duration &&
//         value.duration > Duration.zero) {
//       WidgetsBinding.instance
//           .addPostFrameCallback((_) => _navigateNext());
//     }
//   }
//
//   bool get hasValidSession {
//     final loggedIn =
//     getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn);
//     final token =
//     getStringAsync(AppSharedPreferenceKeys.apiToken);
//
//     return loggedIn && token.isNotEmpty;
//   }
//   bool get isSleepTrackerOn {
//     return getBoolAsync(
//       AppSharedPreferenceKeys.isSleepTrackingActive,
//       defaultValue: false,
//     );
//   }
//   Future<bool> _checkHasValidSession() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final loggedIn =
//         prefs.getBool(AppSharedPreferenceKeys.isUserLoggedIn) ?? false;
//
//     final token =
//         prefs.getString(AppSharedPreferenceKeys.apiToken) ?? '';
//
//     return loggedIn && token.isNotEmpty;
//   }
//
//   Future<bool> _checkSleepTrackerOn() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     return prefs.getBool(
//       AppSharedPreferenceKeys.isSleepTrackingActive,
//     ) ??
//         false;
//   }
//   /// 5️⃣ SINGLE navigation point
//   Future<void> _navigateNext() async {
//     if (_navigated) return;
//     _navigated = true;
//
//     videoController.removeListener(_videoListener);
//     videoController.pause();
//
//     final hasValidSession = await _checkHasValidSession();
//     final isSleepTrackerOn = await _checkSleepTrackerOn();
//
//     if (!onboardingDone) {
//       Get.offAllNamed(Routes.welcome);
//       return;
//     }
//
//     if (!bodyScannerDone) {
//       Get.offAllNamed(Routes.bodyScanner);
//       return;
//     }
//
//     if (!sleepReportDone) {
//       Get.offAllNamed(Routes.sleepReport);
//       return;
//     }
//
//     if (!accurateSleepRecorderDone) {
//       Get.offAllNamed(Routes.accurateSleepRecorder);
//       return;
//     }
//
//     // if (!patentedSleepTrackerDone) {
//     //   Get.offAllNamed(Routes.patentedSleepTracker);
//     //   return;
//     // }
//
//     if (!bestSoundMachineDone) {
//       Get.offAllNamed(Routes.bestSoundMachine);
//       return;
//     }
//
//     // if (hasValidSession) {
//     //   if (isSleepTrackerOn) {
//     //     Get.offAllNamed(Routes.sleepTracker);
//     //   } else {
//     //     Get.offAllNamed(Routes.dashboard);
//     //   }
//     //   return;
//     // }
//     if (hasValidSession) {
//       final prefs = await SharedPreferences.getInstance();
//       final int? activeId = prefs.getInt('sleep_tracker_id'); // Check for the ID
//       final bool isTracking = prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
//
//       if (isTracking && activeId != null) {
//         // 🔥 JUMP DIRECTLY TO TRACKER
//         Get.offAllNamed(Routes.sleepTracker, arguments: activeId);
//       } else {
//         Get.offAllNamed(Routes.dashboard);
//       }
//       return;
//     }
//
//     Get.offAllNamed(Routes.login);
//   }
//   @override
//   void onClose() {
//     if (videoController.value.isInitialized) {
//       videoController.dispose();
//     }
//     super.onClose();
//   }
// }

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

  // Future<void> _navigateNext() async {
  //   if (_navigated) return;
  //   _navigated = true;
  //
  //   // 🧹 Cleanup Video Resources immediately
  //   videoController.removeListener(_videoListener);
  //   if (videoController.value.isPlaying) videoController.pause();
  //
  //   // 1️⃣ Fetch fresh data from Prefs (Avoid cached nb_utils here for safety)
  //   final bool onboardingDone = prefs.getBool(AppSharedPreferenceKeys.onboardingCompleted) ?? false;
  //   final bool bodyScannerDone = prefs.getBool(AppSharedPreferenceKeys.bodyScannerCompleted) ?? false;
  //   final bool sleepReportDone = prefs.getBool(AppSharedPreferenceKeys.sleepReportCompleted) ?? false;
  //   final bool accurateSleepRecorderDone = prefs.getBool(AppSharedPreferenceKeys.accurateSleepRecorderCompleted) ?? false;
  //   final bool bestSoundMachineDone = prefs.getBool(AppSharedPreferenceKeys.bestSoundMachineCompleted) ?? false;
  //
  //   final bool loggedIn = prefs.getBool(AppSharedPreferenceKeys.isUserLoggedIn) ?? false;
  //   final String token = prefs.getString(AppSharedPreferenceKeys.apiToken) ?? '';
  //
  //   // 2️⃣ Navigation Logic (Onboarding First)
  //   if (!onboardingDone) return Get.offAllNamed(Routes.welcome);
  //   if (!bodyScannerDone) return Get.offAllNamed(Routes.bodyScanner);
  //   if (!sleepReportDone) return Get.offAllNamed(Routes.sleepReport);
  //   if (!accurateSleepRecorderDone) return Get.offAllNamed(Routes.accurateSleepRecorder);
  //   if (!bestSoundMachineDone) return Get.offAllNamed(Routes.bestSoundMachine);
  //
  //   // 3️⃣ Session & Tracker Logic
  //   if (loggedIn && token.isNotEmpty) {
  //     final int activeId = prefs.getInt('sleep_tracker_id') ?? 0;
  //     final bool isTracking = prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
  //
  //     // 🔥 CRITICAL: Only jump if ID is valid and not 0
  //     if (isTracking && activeId > 0) {
  //       print("🚀 Resuming active sleep session: $activeId");
  //       Get.offAllNamed(Routes.sleepTracker, arguments: activeId);
  //     } else {
  //       Get.offAllNamed(Routes.dashboard);
  //     }
  //   } else {
  //     Get.offAllNamed(Routes.login);
  //   }
  // }
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