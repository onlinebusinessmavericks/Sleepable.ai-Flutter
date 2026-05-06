import '../../../core/utils/library.dart';

class SignInController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isPasswordVisible = false.obs;

  /// 🔐 SIGN IN
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final payload = {
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text,
      };

      /// 🔥 API CALL
      // await AuthApis.login(payload);

      Get.snackbar(
        "Success",
        "Logged in successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
