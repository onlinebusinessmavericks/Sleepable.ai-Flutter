// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../core/constants/colors.dart';
// import '../../../core/theme/text_theme.dart';
// import '../../music/views/music_view.dart';
// import '../controllers/forgot_password_controller.dart';
//
// class SignupScreen extends StatelessWidget {
//   SignupScreen({super.key});
//
//   final controller = Get.put(SignupController());
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfigs.init(context);
//
//     return Obx(() => Stack(
//       children: [
//         Scaffold(
//           backgroundColor: AppColors.backgroundColor,
//           appBar: AppBar(
//             backgroundColor: AppColors.backgroundColor,
//             elevation: 0,
//             leadingWidth: 60,
//             leading: Padding(
//               padding: const EdgeInsets.only(left: 22.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: SmallCircleIcon(
//                   icon: Icons.arrow_back_rounded,
//                   size: 20 * SizeConfigs.textScale,
//                   iconColor: Colors.white,
//                   backgroundColor: Colors.white10,
//                   onTap: () => Get.back(),
//                 ),
//               ),
//             ),
//             title: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
//               child: Text(
//                 "Create Account",
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   color: AppColors.white,
//                   fontSize: 21 * SizeConfigs.textScale,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             centerTitle: true,
//           ),
//           body: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _field("Full Name", controller.nameCtrl),
//                   _field("Email", controller.emailCtrl),
//
//                   _passwordField("Password", controller.passwordCtrl),
//                   _passwordField("Confirm Password", controller.confirmPasswordCtrl),
//
//                   _birthDate(context),
//                   _genderSelector(),
//
//                   _field("Phone Number", controller.phoneCtrl),
//                   _field("Country", controller.countryCtrl),
//                   _field("City", controller.cityCtrl),
//                   _field("Zip Code", controller.zipCtrl),
//
//                   const SizedBox(height: 30),
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: controller.isLoading.value
//                           ? null
//                           : controller.createAccount,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 50, vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: controller.isLoading.value
//                           ? const Text("Creating...")
//                           : const Text("Sign up"),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         if (controller.isLoading.value)
//           Positioned.fill(
//             child: Container(
//               color: Colors.black26,
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//           ),
//       ],
//     ));
//   }
//
//   Widget _field(String label, TextEditingController ctrl) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 6),
//         TextField(
//           controller: ctrl,
//           decoration: _decoration(),
//         ),
//         const SizedBox(height: 15),
//       ],
//     );
//   }
//
//   Widget _passwordField(String label, TextEditingController ctrl) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 6),
//         TextField(
//           controller: ctrl,
//           obscureText: true,
//           decoration: _decoration(),
//         ),
//         const SizedBox(height: 15),
//       ],
//     );
//   }
//
//   Widget _birthDate(BuildContext context) {
//     return Obx(() => GestureDetector(
//       onTap: () => controller.pickBirthDate(context),
//       child: AbsorbPointer(
//         child: TextField(
//           decoration: _decoration(
//             hint: controller.birthDate.value.isEmpty
//                 ? "Select Birthdate"
//                 : controller.birthDate.value,
//           ),
//         ),
//       ),
//     ));
//   }
//
//   Widget _genderSelector() {
//     return Obx(() => Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: ['Female', 'Male', 'Non binary'].map((g) {
//         final isSelected = controller.selectedGender.value == g;
//         return GestureDetector(
//           onTap: () => controller.selectedGender.value = g,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.teal.shade100 : Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey),
//             ),
//             child: Text(g),
//           ),
//         );
//       }).toList(),
//     ));
//   }
//
//   InputDecoration _decoration({String? hint}) {
//     return InputDecoration(
//       hintText: hint,
//       filled: true,
//       fillColor: Colors.grey.shade100,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../widgets/custom_loader.dart';
import '../../music/views/music_view.dart';
import '../controllers/sign_up_controller.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final controller = Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => Get.back(),
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
              child: Text(
                "Create Account",
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
              // decoration: BoxDecoration(
              //   color: AppColors.cardDark,
              //   borderRadius: BorderRadius.circular(22),
              // ),
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    _field(context,"Full Name", controller.nameCtrl,
                        validator: (v) =>
                        v!.isEmpty ? "Full name required" : null,),

                    _field(context,"Email", controller.emailCtrl,
                        validator: (v) {
                          if (v!.isEmpty) return "Email required";
                          if (!GetUtils.isEmail(v)) {
                            return "Enter valid email";
                          }
                          return null;
                        }),

                    _passwordField(context,"Password", controller.passwordCtrl,
                        validator: (v) {
                          if (v!.length < 6) {
                            return "Minimum 6 characters";
                          }
                          return null;
                        }),

                    _passwordField(context,
                        "Confirm Password",
                        controller.confirmPasswordCtrl,
                        validator: (v) {
                          if (v != controller.passwordCtrl.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        }),

                    _birthDate(context),
                    const SizedBox(height: 12),
                    _genderSelector(),

                    _field(context,"Phone Number", controller.phoneCtrl,
                        validator: (v) =>
                        v!.isEmpty ? "Phone required" : null),

                    _field(context,"Country", controller.countryCtrl,
                        validator: (v) =>
                        v!.isEmpty ? "Country required" : null),

                    _field(context,"City", controller.cityCtrl,
                        validator: (v) =>
                        v!.isEmpty ? "City required" : null),

                    _field(context,"Zip Code", controller.zipCtrl,
                        validator: (v) =>
                        v!.isEmpty ? "Zip code required" : null),

                    const SizedBox(height: 30),

                    // ElevatedButton(
                    //   onPressed: controller.isLoading.value
                    //       ? null
                    //       : controller.createAccount,
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.textColor,
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 60, vertical: 14),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(30),
                    //     ),
                    //   ),
                    //   child:  Text("Sign Up",style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    //     color: AppColors.white,
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 15 * SizeConfigs.textScale,
                    //   ),),
                    // ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          "Sign In",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15 * SizeConfigs.textScale),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Loader
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

  // ---------------- WIDGETS ----------------

  Widget _field(BuildContext context,String label, TextEditingController ctrl,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(label, style: _labelStyle),
        buildLabel(context, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          style: const TextStyle(color: AppColors.white),
          decoration: _decoration(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _passwordField(BuildContext context,String label, TextEditingController ctrl,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(label, style: _labelStyle),
        buildLabel(context, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: true,
          validator: validator,
          style: const TextStyle(color: AppColors.white),
          decoration: _decoration(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _birthDate(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Birth Date", style: _labelStyle),
        buildLabel(context, "Birth Date"),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => controller.pickBirthDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              decoration: _decoration(
                hint: controller.birthDate.value.isEmpty
                    ? "Select birth date"
                    : controller.birthDate.value,
              ),
              validator: (_) => controller.birthDate.value.isEmpty
                  ? "Birth date required"
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    ));
  }

  Widget _genderSelector() {
    return Obx(() => Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Female', 'Male', 'Non binary'].map((g) {
            final isSelected = controller.selectedGender.value == g;
            return GestureDetector(
              onTap: () => controller.selectedGender.value = g,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textColor.withOpacity(0.2)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textColor
                        : AppColors.borderColor,
                  ),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textColor
                        : AppColors.secondaryTextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (controller.selectedGender.value.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              "Please select gender",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 14),
      ],
    ));
  }

  // ---------------- STYLES ----------------

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

  // TextStyle get _labelStyle => const
  // TextStyle(
  //   color: AppColors.secondaryTextColor,
  //   fontSize: 14,
  // );
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
