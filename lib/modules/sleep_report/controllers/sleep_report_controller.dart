import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../widgets/offer_widget.dart';

class SleepReportController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController progressController;
  RxDouble progress = 0.0.obs;
  RxBool isCompleted = false.obs;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    progressController.addListener(_updateProgress);
    _startProgress();
  }

  void _updateProgress() {
    if (!_isDisposed) {
      progress.value = progressController.value;
    }
  }

  Future<void> _startProgress() async {
    try {
      if (_isDisposed) return;

      /// PHASE 1 → Fast (0% → 60%)
      await progressController.animateTo(
        0.6, // 🎯 Yahan 0.6 rakha hai taaki 60% pe ruke
        duration: const Duration(seconds: 3),
        curve: Curves.easeOut,
      );

      if (_isDisposed) return;

      // ⏳ Yahan thoda hold karega (Processing feel dene ke liye)
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isDisposed) return;

      /// PHASE 2 → Slow (60% → 100%)
      await progressController.animateTo(
        1.0, // 🎯 Ab 100% tak jayega
        duration: const Duration(seconds: 3),
        curve: Curves.easeIn,
      );

      // ✅ Animation complete hone ke baad button show karein
      isCompleted.value = true;

    } catch (e) {
      debugPrint("Animation safely cancelled: $e");
    }
  }

  void goNext() {
    progressController.stop();
    setValue(AppSharedPreferenceKeys.sleepReportCompleted, true);
    Get.offNamed(Routes.accurateSleepRecorder);
  }

  @override
  void onClose() {
    _isDisposed = true;
    progressController.removeListener(_updateProgress);
    progressController.dispose();
    super.onClose();
  }
}