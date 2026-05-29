import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/rating_dialog.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import '../controllers/alarm_controller.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  final controller = Get.find<AlarmController>();

  RxString currentTime = "".obs;
  Timer? _timer;

  late VideoPlayerController _videoController;
  Future<void>? _initializeVideo;

  @override
  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Initialize controller
    _videoController = VideoPlayerController.asset(
      Assets.videoWakeup,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    // 🔥 Optimized Initialization logic
    _initializeVideo = _videoController.initialize().then((_) {
      if (!mounted) return;

      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // Keep silent to let AlarmController handle music
      _videoController.play();

      setState(() {}); // Refresh to show the video in FutureBuilder
    }).catchError((error) {
      debugPrint("🎥 Video Player Error: $error");
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController.dispose();
    final alarmController = Get.find<AlarmController>();
    alarmController.stopAlarm(snoozeAfterStop: false);
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;
    String minute = now.minute.toString().padLeft(2, '0');
    String amPm = now.hour >= 12 ? context.lang.PM : context.lang.AM;

    currentTime.value = "${hour.toString().padLeft(2, '0')}:$minute $amPm";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// 🔥 PERFECT BACKGROUND VIDEO
            Positioned.fill(
              child: _initializeVideo == null
                  ? Container(color: Colors.black) // during 300 ms delay
                  : FutureBuilder(
                      future: _initializeVideo,
                      builder: (_, snap) {
                        if (snap.connectionState == ConnectionState.done) {
                          return FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(width: _videoController.value.size.width, height: _videoController.value.size.height, child: VideoPlayer(_videoController)),
                          );
                        }
                        return Container(color: Colors.black);
                      },
                    ),
            ),

            /// 🔥 UI OVER VIDEO
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => Text(
                      currentTime.value,
                      style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    context.lang.haveNiceDay,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 60),

                  /// 🔵 STOP ALARM BUTTON
                  GestureDetector(
                    onTap: () async {
                      final AlarmController controller = Get.find<AlarmController>();
                      // 1. Stop the alarm immediately in the controller
                      await controller.stopAlarm(snoozeAfterStop: false);

                      // 2. Stop and dispose of the video player here locally
                      if (_videoController.value.isPlaying) {
                        await _videoController.pause();
                      }

                      // 3. Small delay ensures the 'Stop' logic finishes before the screen is destroyed
                      // Get.offAll(() => DashboardScreen());
                      if (!Get.isRegistered<ProgressController>()) {
                        Get.put(ProgressController());
                      }
                      final progressController = Get.find<ProgressController>();
                      progressController.loadAllData();

                      // 3. Run Cleanup and Navigate
                      final sleepController = Get.find<SleepTrackerController>();
                      sleepController.performCleanup(sleepController);

                      Get.offAllNamed(Routes.dashboard);
                      Future.delayed(const Duration(milliseconds: 400), () {
                        Get.dialog(
                          const RatingDialog(),
                          barrierDismissible: false,
                        );
                      });
                    },

                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.6), blurRadius: 15, spreadRadius: 5)],
                      ),
                      alignment: Alignment.center,
                      child:  Text(
                        context.lang.wakeUp,
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
