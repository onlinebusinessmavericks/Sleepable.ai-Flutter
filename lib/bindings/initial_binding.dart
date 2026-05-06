import 'package:get/get.dart';
import '../modules/common/controllers/selection_flow_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SelectionFlowController(), permanent: true);
  }
}
