import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../widgets/ai_consent_dialog.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  BuildContext? homeShowcaseContext;
  void changeTab(int index) {
    currentIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int && args >= 0 && args <= 3) {
      currentIndex.value = args;
    } else if (args is Map && args['tab'] is int) {
      currentIndex.value = args['tab'] as int;
    } else {
      // Cold-start notification may have stashed a tab before Boot navigated.
      final pending = getIntAsync(AppSharedPreferenceKeys.pendingDashboardTab, defaultValue: -1);
      if (pending >= 0 && pending <= 3) {
        currentIndex.value = pending;
        setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
      }
    }
  }

  @override
  void onReady() {
    super.onReady();

    // Apple Guideline 5.1.1(i) / 5.1.2(i): ask for AI data-sharing consent once
    // on app open. It is a no-op if the user has already answered the prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      if (ctx != null) maybeShowAiConsentOnAppOpen(ctx);
    });
  }
}
