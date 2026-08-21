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
                child: SmallCircleIcon(
                  icon: Icons.arrow_back_rounded,
                  size: 20 * SizeConfigs.textScale,
                  iconColor: Colors.white,
                  backgroundColor: Colors.white10,
                  onTap: () {
                    if (controller.step.value == 1) {
                      controller.backToEmailStep();
                    } else {
                      Get.back();
                    }
                  },
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                controller.step.value == 0 ? "Forgot Password" : "Reset Password",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontSize: 21 * SizeConfigs.textScale,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: controller.step.value == 0 ? _emailStep(context) : _resetStep(context),
            ),
          ),
        ),

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

  Widget _emailStep(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your account email. We'll send a one-time code to reset your password.",
            style: TextStyle(color: Colors.white70, fontSize: 14 * SizeConfigs.textScale),
          ),
          const SizedBox(height: 20),
          buildLabel(context, "Email"),
          const SizedBox(height: 6),
          _emailField(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                "Send OTP",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15 * SizeConfigs.textScale,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resetStep(BuildContext context) {
    return Form(
      key: controller.resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter the OTP sent to ${controller.emailCtrl.text.trim()} and choose a new password.",
            style: TextStyle(color: Colors.white70, fontSize: 14 * SizeConfigs.textScale),
          ),
          const SizedBox(height: 20),
          buildLabel(context, "OTP Code"),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.otpCtrl,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "OTP required";
              if (v.trim().length < 4) return "Enter a valid OTP";
              return null;
            },
            style: const TextStyle(color: AppColors.white),
            decoration: _decoration(hint: "6-digit code"),
          ),
          const SizedBox(height: 16),
          buildLabel(context, "New Password"),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.newPasswordCtrl,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Password required";
              if (v.length < 8) return "Minimum 8 characters";
              return null;
            },
            style: const TextStyle(color: AppColors.white),
            decoration: _decoration(hint: "New password"),
          ),
          const SizedBox(height: 16),
          buildLabel(context, "Confirm Password"),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.confirmPasswordCtrl,
            obscureText: true,
            validator: (v) {
              if (v != controller.newPasswordCtrl.text) return "Passwords do not match";
              return null;
            },
            style: const TextStyle(color: AppColors.white),
            decoration: _decoration(hint: "Confirm password"),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                "Reset Password",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15 * SizeConfigs.textScale,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.secondaryTextColor),
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
