import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../widgets/offer_widget.dart';

// class SleepReportController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   late AnimationController progressController;
//   RxDouble progress = 0.0.obs;
//
//   bool _isDisposed = false;
//   RxBool isCompleted = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 7),
//     );
//
//     progressController.addListener(_updateProgress);
//     _startProgress();
//   }
//
//   // 1. Named listener allows for clean removal
//   void _updateProgress() {
//     if (!_isDisposed) {
//       progress.value = progressController.value;
//     }
//   }
//
//   Future<void> _startProgress() async {
//     try {
//       if (_isDisposed) return;
//
//       /// PHASE 1 → Fast (0% → 60%)
//       // 2. Use a local variable check because hasClients doesn't exist for AnimationController
//       await progressController.animateTo(
//         1.0,
//         duration: const Duration(seconds: 2),
//         curve: Curves.easeIn,
//       );
//       isCompleted.value = true;
//
//       if (_isDisposed) return;
//
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       if (_isDisposed) return;
//
//       /// PHASE 2 → Slow (61% → 100%)
//       await progressController.animateTo(
//         1.0,
//         duration: const Duration(seconds: 2),
//         curve: Curves.easeIn,
//       );
//     } catch (e) {
//       // 3. Catching the 'disposed' error if it happens mid-animation
//       debugPrint("Animation safely cancelled: $e");
//     }
//   }
//
//   void goNext() {
//     // It's good practice to stop the controller manually before navigating
//     progressController.stop();
//     setValue(AppSharedPreferenceKeys.sleepReportCompleted, true);
//     Get.offNamed(Routes.accurateSleepRecorder);
//   }
//
//   @override
//   void onClose() {
//     _isDisposed = true;
//     // Remove listener before disposing to stop Rx updates immediately
//     progressController.removeListener(_updateProgress);
//     progressController.dispose();
//     super.onClose();
//   }
// }
class SleepReportController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController progressController;
  RxDouble progress = 0.0.obs;
  RxBool isCompleted = false.obs; // Button dikhane ke liye

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