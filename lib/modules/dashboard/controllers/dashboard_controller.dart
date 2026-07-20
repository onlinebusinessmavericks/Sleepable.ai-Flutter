import 'package:sleepable_ai/core/utils/library.dart';

import '../../../widgets/ai_consent_dialog.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  BuildContext? homeShowcaseContext;
  void changeTab(int index) {
    currentIndex.value = index;
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
