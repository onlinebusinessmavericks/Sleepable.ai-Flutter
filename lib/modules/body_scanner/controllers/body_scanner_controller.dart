import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../generated/assets.dart';
import '../../../routes/app_pages.dart';

class BodyScannerController extends GetxController
    with GetSingleTickerProviderStateMixin {

  late VideoPlayerController videoControllers;
  final RxBool isVideoReady = false.obs;

  @override
  void onInit() {
    super.onInit();

    videoControllers = VideoPlayerController.asset(
      // Assets.onboardingHumanscan,
       Assets.onboardingHumanFinal,
    )
      ..initialize().then((_) {
        isVideoReady.value = true;
        videoControllers
          ..setLooping(true)
          ..setVolume(0) // muted (recommended)
          ..play();
      });
  }

  void goNext() {
    setValue(AppSharedPreferenceKeys.bodyScannerCompleted, true);
    Get.offNamed(Routes.sleepReport);
  }


  @override
  void onClose() {
    if (videoControllers.value.isInitialized) {
      videoControllers.dispose();
    }
    super.onClose();
  }
}
