import 'package:just_audio_background/just_audio_background.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';

import '../../../core/constants/shared_prefences.dart';

class AccurateSleepRecorderController extends GetxController {
  final player = AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
  );
  // final player = AudioPlayer();
  final audios = <SleepAudio>[
    SleepAudio(
      title: Get.context!.lang.youSnored,
      time: '00:02 ${Get.context!.lang.PM}',
      audioPath: Assets.humanSnored,
      lottiePath: Assets.lottieSleepLottie,
      // lottiePath: Assets.lottieCloud,
    ),
    SleepAudio(
      title:  Get.context!.lang.youGasped,
      time: '00:07 ${Get.context!.lang.PM}',
      audioPath: Assets.onboardingGasps,
      // lottiePath: Assets.lottieStar
      lottiePath: Assets.lottieGasp,
    ),
    SleepAudio(
      title:  Get.context!.lang.youTalked,
      time: '00:04 ${Get.context!.lang.AM}',
      audioPath: Assets.onboardingSleepTalking,
      lottiePath: Assets.lottieTalking,
      // lottiePath: Assets.lottieSleepSuccess,
    ),
  ];

  RxInt currentIndex = 0.obs; // 👈 start from first

  @override
  void onInit() {
    super.onInit();

    /// Auto play first audio
    playAt(0);

    /// Listen for completion → play next
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  // Future<void> playAt(int index) async {
  //   final path = audios[index].audioPath;
  //   currentIndex.value = index;
  //
  //   if (path.startsWith('assets/')) {
  //     await player.setAsset(path);
  //   } else {
  //     await player.setFilePath(path);
  //   }
  //
  //   await player.play();
  // }
  Future<void> playAt(int index) async {
    try {
      final audio = audios[index];
      final path = audio.audioPath;
      currentIndex.value = index;

      // 2. setAsset/setFilePath ki jagah setAudioSource use karein tag ke saath
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(path.startsWith('assets/') ? 'asset:///$path' : path),
          // 🟢 MANDATORY: Jab JustAudioBackground init ho, toh ye tag dena hi padega
          tag: MediaItem(
            id: 'recorder_$index',
            album: 'Sleep Report',
            title: audio.title,
            artist: 'Sleepable AI',
          ),
        ),
      );

      await player.play();
    } catch (e) {
      debugPrint("❌ Playback Error: $e");
    }
  }


  Future<void> playNext() async {
    if (currentIndex.value < audios.length - 1) {
      await playAt(currentIndex.value + 1);
    } else {
      await player.stop();
      currentIndex.value = -1; // ❌ nothing active
    }
  }

  void goNext() {
    setValue(AppSharedPreferenceKeys.accurateSleepRecorderCompleted, true);
    // Get.offNamed(Routes.patentedSleepTracker);

    Get.offNamed(Routes.bestSoundMachine);
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }
}

class SleepAudio {
  final String title;
  final String time;
  final String audioPath;
  final String lottiePath;

  SleepAudio({
    required this.title,
    required this.time,
    required this.audioPath,
    required this.lottiePath,
  });
}
