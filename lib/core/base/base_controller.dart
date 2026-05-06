import 'package:get/get.dart';

class BaseController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxBool isFilterApplied = false.obs;
  RxInt page = 1.obs;
  void setLoading(bool value) {
    isLoading.value = value;
  }
  // void setLoading(bool value) => isLoading.value = value;
  void setLastPage(bool value) => isLastPage.value = value;
  void setRefresh(bool value) => isRefresh.value = value;
  void resetPage() => page.value = 1;
}
