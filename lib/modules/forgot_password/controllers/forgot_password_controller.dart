import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final resetFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  /// 0 = enter email, 1 = enter OTP + new password
  final step = 0.obs;

  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  /// Step 1: request OTP email
  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final payload = {
        "email": emailCtrl.text.trim(),
      };

      final response = await AuthServiceApis.forgotPassword(request: payload);
      if (response.success) {
        Get.snackbar(
          "Success",
          response.message.isNotEmpty
              ? response.message
              : "If that email is registered, you will receive an OTP shortly.",
          snackPosition: SnackPosition.BOTTOM,
        );
        step.value = 1;
      } else {
        Get.snackbar(
          "Error",
          response.message.isNotEmpty ? response.message : "Could not send reset email",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 2: verify OTP and set new password
  Future<void> resetPassword() async {
    if (!resetFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final response = await AuthServiceApis.resetPassword(request: {
        "email": emailCtrl.text.trim(),
        "otp_code": otpCtrl.text.trim(),
        "new_password": newPasswordCtrl.text.trim(),
      });

      if (response.success) {
        Get.snackbar(
          "Success",
          response.message.isNotEmpty
              ? response.message
              : "Password reset successfully. You can now log in.",
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back(); // back to sign in
      } else {
        Get.snackbar(
          "Error",
          response.message.isNotEmpty ? response.message : "Could not reset password",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void backToEmailStep() {
    step.value = 0;
    otpCtrl.clear();
    newPasswordCtrl.clear();
    confirmPasswordCtrl.clear();
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
