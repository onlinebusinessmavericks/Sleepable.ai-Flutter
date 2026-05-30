import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../widgets/custom_loader.dart';
import '../../music/views/music_view.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);

    return Obx(() => Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 22.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
              child: Text(
                "Forgot Password",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel(context, "Email"),
                    const SizedBox(height: 6),
                    _emailField(),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:Colors.blueAccent,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:  Text("Send Reset Link",style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15 * SizeConfigs.textScale),
                      ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),

        /// 🔄 Loader
        if (controller.isLoading.value)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: const Center(child: LoaderWidget(size: 150)),
            ),
          ),
      ],
    ));
  }

  // ---------------- FIELD ----------------

  Widget _emailField() {
    return TextFormField(
      controller: controller.emailCtrl,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v!.isEmpty) return "Email required";
        if (!v.isEmail) return "Invalid email";
        return null;
      },
      style: const TextStyle(color: AppColors.white),
      decoration: _decoration(hint: "Enter your email"),
    );
  }

  // ---------------- DECORATION ----------------

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: AppColors.secondaryTextColor),
      filled: true,
      fillColor: AppColors.cardDark,
      errorStyle: const TextStyle(color: Colors.redAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
  Widget buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w900,
        fontSize: 14 * SizeConfigs.textScale,
      ),
    );
  }
}
