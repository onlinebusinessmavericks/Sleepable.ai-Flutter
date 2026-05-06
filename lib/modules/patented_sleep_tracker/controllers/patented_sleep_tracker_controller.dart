import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../widgets/offer_widget.dart';

class PatentedSleepTrackerController extends GetxController
    with GetSingleTickerProviderStateMixin {

  late AnimationController progressController;

  @override
  void onInit() {
    super.onInit();
  }


  void goNext() {
    if (Get.context != null) {
      // showNotBedTimeSheet(Get.context!);
      // OR
      setValue(AppSharedPreferenceKeys.patentedSleepTrackerCompleted, true);
      Get.offNamed(Routes.bestSoundMachine);
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}