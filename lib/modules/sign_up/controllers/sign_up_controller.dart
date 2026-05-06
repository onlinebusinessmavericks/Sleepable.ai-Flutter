import '../../../core/utils/library.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  // Controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final zipCtrl = TextEditingController();

  // Observables
  final birthDate = ''.obs;
  final selectedGender = ''.obs;
  final isPasswordVisible = false.obs;

  /// 📅 Pick DOB
  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthDate.value =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  /// 🌐 SIGNUP
  Future<void> createAccount() async {
    /// 🔴 FIELD VALIDATION
    if (!formKey.currentState!.validate()) return;

    if (birthDate.value.isEmpty) {
      Get.snackbar("Error", "Please select birthdate");
      return;
    }

    if (selectedGender.value.isEmpty) {
      Get.snackbar("Error", "Please select gender");
      return;
    }

    try {
      isLoading.value = true;

      final payload = {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text,
        "date_of_birth": birthDate.value,
        "gender": selectedGender.value,
        "phone_number": phoneCtrl.text.trim(),
        "country": countryCtrl.text.trim(),
        "city": cityCtrl.text.trim(),
        "zip_code": zipCtrl.text.trim(),
      };

      // await AuthApis.signup(payload);

      Get.snackbar(
        "Success",
        "Account created successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    phoneCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    zipCtrl.dispose();
    super.onClose();
  }
}
