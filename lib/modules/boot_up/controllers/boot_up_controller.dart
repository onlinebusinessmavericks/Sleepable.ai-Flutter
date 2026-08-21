
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
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';

class BootUpController extends GetxController {
  late VideoPlayerController videoController;
  final RxBool isVideoReady = false.obs;
  bool _navigated = false;

  late SharedPreferences prefs;

  @override
  void onInit() {
    super.onInit();
    initCall();
  }

  Future<void> initCall() async {
    prefs = await SharedPreferences.getInstance();
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

    if (!(prefs.getBool(AppSharedPreferenceKeys.onboardingCompleted) ?? false)) return Get.offAllNamed(Routes.welcome);
    if (!(prefs.getBool(AppSharedPreferenceKeys.bodyScannerCompleted) ?? false)) return Get.offAllNamed(Routes.bodyScanner);
    if (!(prefs.getBool(AppSharedPreferenceKeys.sleepReportCompleted) ?? false)) return Get.offAllNamed(Routes.sleepReport);
    if (!(prefs.getBool(AppSharedPreferenceKeys.accurateSleepRecorderCompleted) ?? false)) return Get.offAllNamed(Routes.accurateSleepRecorder);
    if (!(prefs.getBool(AppSharedPreferenceKeys.bestSoundMachineCompleted) ?? false)) return Get.offAllNamed(Routes.bestSoundMachine);

    final bool loggedIn = prefs.getBool(AppSharedPreferenceKeys.isUserLoggedIn) ?? false;
    final String token = prefs.getString(AppSharedPreferenceKeys.apiToken) ?? '';

    if (loggedIn && token.isNotEmpty) {
      try {
        final bool localTracking =
            prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
        final int localId = prefs.getInt('sleep_tracker_id') ?? 0;

        final statusResponse = await TrackerApis.checkTrackerStatus();

        if (statusResponse.success &&
            statusResponse.data.isRunning &&
            localTracking &&
            localId > 0) {
          int activeId = statusResponse.data.sleepTrackerId;

          await prefs.setBool(AppSharedPreferenceKeys.isSleepTrackingActive, true);
          await prefs.setInt('sleep_tracker_id', activeId);

          print("🚀 Resuming active sleep session from API: $activeId");
          Get.offAllNamed(Routes.sleepTracker, arguments: activeId);
        } else {
          // Local quit/wake already happened, or server idle — never resume.
          if (statusResponse.success &&
              statusResponse.data.isRunning &&
              (!localTracking || localId <= 0)) {
            final orphanId = statusResponse.data.sleepTrackerId;
            debugPrint("🧹 Orphan tracker on server after local quit: $orphanId — stopping");
            unawaited(TrackerApis.stopSleepTracker(sleepTrackerId: orphanId));
          }

          await prefs.setBool(AppSharedPreferenceKeys.isSleepTrackingActive, false);
          await prefs.setInt('sleep_tracker_id', 0);

          _goDashboardHonoringPendingTab();
        }
      } catch (e) {
        debugPrint("❌ Tracker Status API Error: $e");
        // If local still thinks tracking is on but status API failed, hard-stop
        // so a bad network night cannot leave FGS / orphan session.
        final bool localTracking =
            prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
        final int localId = prefs.getInt('sleep_tracker_id') ?? 0;
        if (localTracking || localId > 0) {
          unawaited(SleepTrackerController.emergencyStopOrphanTracker());
        }
        _goDashboardHonoringPendingTab();
      }
    } else {
      Get.offAllNamed(Routes.login);
    }
  }

  void _goDashboardHonoringPendingTab() {
    final pending = prefs.getInt(AppSharedPreferenceKeys.pendingDashboardTab) ?? -1;
    if (pending >= 0) {
      prefs.setInt(AppSharedPreferenceKeys.pendingDashboardTab, -1);
      Get.offAllNamed(Routes.dashboard, arguments: pending);
    } else {
      Get.offAllNamed(Routes.dashboard);
    }
  }

  @override
  void onClose() {
    videoController.removeListener(_videoListener);
    videoController.dispose();
    super.onClose();
  }
}
