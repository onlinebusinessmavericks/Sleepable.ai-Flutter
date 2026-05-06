import 'package:sleepable_ai/core/utils/library.dart';
import '../../../widgets/SubscriptionController.dart';
import '../controllers/login_controller.dart';
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Login controller as usual
    Get.lazyPut<LoginController>(() => LoginController());

    // 2. 🔥 THE FIX: SubscriptionController ko permanent load karein
    // Ye ensure karega ki Login se Dashboard jaate waqt data loss na ho
    Get.put(SubscriptionController(), permanent: true);
  }
}