import '../../../core/utils/library.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  final emailCtrl = TextEditingController();

  /// 🔑 SEND RESET LINK
  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final payload = {
        "email": emailCtrl.text.trim(),
      };

      /// 🔥 API CALL
      // await AuthApis.forgotPassword(payload);

      Get.snackbar(
        "Success",
        "Password reset link sent to your email",
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(); // go back to sign in
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    super.onClose();
  }
}
