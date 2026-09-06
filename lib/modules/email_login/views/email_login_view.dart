import '../../../core/utils/library.dart';
import '../../../localization/lang_extension.dart';
import '../../login/controllers/login_controller.dart';

class EmailLoginView extends GetView<LoginController> {
  const EmailLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(context.lang.signInWithEmail, style: textTheme.titleMedium?.copyWith(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Email Field
            _textField(
              controller: controller.emailController,
              hint:context.lang.emailAddress,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            // Password Field
            _textField(
              controller: controller.passwordController,
              hint: context.lang.password,
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 40),
            // Login Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.loginWithEmailApi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    :  Text(context.lang.continues, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )),
            const SizedBox(height: 18),
            // The sign-up screen existed but nothing linked to it, so a new
            // email user had no way to create an account at all.
            Center(
              child: TextButton(
                onPressed: () => Get.toNamed(Routes.signup),
                child: Text(
                  _signUpCopy(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
/// The app ships five languages and there is no existing key for this line, so
/// it carries its own table rather than falling back to English everywhere.
String _signUpCopy() {
  const map = {
    "en": "New here? Create an account",
    "de": "Neu hier? Konto erstellen",
    "fr": "Nouveau ? Creer un compte",
    "es": "Nuevo aqui? Crea una cuenta",
    "pt": "Novo por aqui? Crie uma conta",
  };
  return map[Get.locale?.languageCode ?? "en"] ?? map["en"]!;
}
