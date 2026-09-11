import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/auth_navigation.dart';
import '../../../generated/assets.dart';
import '../../../routes/app_pages.dart';

class BestSoundMachineController extends GetxController
    with GetSingleTickerProviderStateMixin {

  late VideoPlayerController videoController;
  final RxBool isVideoReady = false.obs;

  @override
  void onInit() {
    super.onInit();

    videoController = VideoPlayerController.asset(
      Assets.onboardingSoundFinal,
    )
      ..initialize().then((_) {
        isVideoReady.value = true;
        videoController
          ..setLooping(true)
          ..setVolume(1.0)
          ..play();
      });
  }

  Future<void> goNext() async {
    setValue(AppSharedPreferenceKeys.bestSoundMachineCompleted, true);
    videoController.pause();
    final loggedIn = getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn);
    final token = getStringAsync(AppSharedPreferenceKeys.apiToken);
    if (loggedIn && token.isNotEmpty) {
      await syncOnboardingToBackend();
      await navigateAfterAuth(showPaywall: shouldShowStartTrialPaywall());
      return;
    }
    Get.offNamed(Routes.login, arguments: {"hideBack": true});
  }

  @override
  void onClose() {
    videoController.dispose();
    super.onClose();
  }
}
