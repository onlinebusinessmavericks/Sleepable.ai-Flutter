import 'package:sleepable_ai/core/utils/library.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  BuildContext? homeShowcaseContext;
  void changeTab(int index) {
    currentIndex.value = index;
  }

}
