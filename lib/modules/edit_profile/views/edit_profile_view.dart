import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_loader.dart';
import '../../profile/model/user_profile_model.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileView extends StatelessWidget {
  final UserProfileData data;

  const EditProfileView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController(data));
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return Obx(() {
      return Stack(
        children: [
          /// MAIN SCREEN
          Scaffold(
            backgroundColor: const Color(0xFFE3F3F0),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: controller.isSaving.value ? null : Get.back,
              ),
              centerTitle: true,
              title: Text(
                context.lang.profile,
               // "Profile",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.card),
              ),
            ),
            body: _buildBody(context, controller),
          ),

          /// FULLSCREEN LOADER (covers AppBar + body)
          if (controller.isSaving.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: LoaderWidget(size: 150),
                ),
              ),
            ),
        ],
      );
    });
  }
  Widget _buildBody(BuildContext context, EditProfileController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  /// PROFILE IMAGE

                  Stack(
                      children: [
                        // GestureDetector(
                        //   onTap: () => _showImagePickerOptions(context, controller),
                        //   child: CircleAvatar(
                        //     radius: 50,
                        //     backgroundColor: Colors.white,
                        //     backgroundImage: controller.imagePath.value.isNotEmpty ? FileImage(File(controller.imagePath.value)) : const AssetImage(Assets.homeSleepableAppIcon) as ImageProvider,
                        //   ),
                        // ),
                        GestureDetector(
                          onTap: () => _showImagePickerOptions(context, controller),
                          child:
                          // Obx(() {
                          //   ImageProvider imageProvider;
                          //
                          //   if (controller.imagePath.value.isNotEmpty) {
                          //     // 1️⃣ Local picked image
                          //     imageProvider = FileImage(File(controller.imagePath.value));
                          //   } else if (controller.data.profileImage != null &&
                          //       controller.data.profileImage!.isNotEmpty) {
                          //     // 2️⃣ Existing profile image from API
                          //     imageProvider = NetworkImage(controller.data.profileImage!);
                          //   } else {
                          //     // 3️⃣ Default asset
                          //     imageProvider = const AssetImage(Assets.homeSleepableAppIcon);
                          //   }
                          //
                          //   return CircleAvatar(
                          //     radius: 50 * SizeConfigs.paddingScale,
                          //     backgroundColor: Colors.white,
                          //     backgroundImage: imageProvider,
                          //   );
                          // }),
                          Obx(() {
                            ImageProvider imageProvider;

                            if (controller.imagePath.value.isNotEmpty) {
                              // 1. Just picked a new file
                              imageProvider = FileImage(File(controller.imagePath.value));
                            } else {
                              // 2. Logic to pick between Uploaded, Social, or Asset
                              final String? uploadedImg = controller.data.profileImage;
                              final String? socialImg = controller.data.avatarUrl;

                              if (uploadedImg != null && uploadedImg.isNotEmpty) {
                                imageProvider = NetworkImage(uploadedImg);
                              } else if (socialImg != null && socialImg.isNotEmpty) {
                                imageProvider = NetworkImage(socialImg);
                              } else {
                                imageProvider = const AssetImage(Assets.homeSleepableAppIcon);
                              }
                            }

                            return CircleAvatar(
                              radius: 50 * SizeConfigs.paddingScale,
                              backgroundColor: Colors.white,
                              backgroundImage: imageProvider,
                            );
                          })
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImagePickerOptions(context, controller),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, size: 18),
                            ),
                          ),
                        ),
                      ]),

                  const SizedBox(height: 30),

                  /// FORM BOX
                  Container(
                    padding:  EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.lang.myProfile,
                          // 'My profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18 * SizeConfigs.textScale),
                        ),
                        SizedBox(height: 6 * SizeConfigs.paddingScale),
                        Text(
                          context.lang.weUsePersonalizedRecommendationsCalculateYourDailyGoals,
                          //'We use this data to give you personalized recommendations and calculate your daily goals',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey, fontSize: 13 * SizeConfigs.textScale),
                        ),
                        SizedBox(height: 25 * SizeConfigs.paddingScale),
                        _label(context, context.lang.firstName),
                        _textField(context, controller.firstNameCtrl),

                        SizedBox(height: 15 * SizeConfigs.paddingScale),
                        _label(context, context.lang.email),
                        _textFieldEmail(context, controller.emailCtrl),

                        SizedBox(height: 15 * SizeConfigs.paddingScale),
                        _label(context, context.lang.birthdate),
                        _birthDatePicker(context, controller),

                        SizedBox(height: 15 * SizeConfigs.paddingScale),
                        _label(context,context.lang.gender),
                        SizedBox(height: 15 * SizeConfigs.paddingScale),
                        _genderSelector(controller),

                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: controller.isSaving.value ? null : controller.saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A506B),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Obx(
                                  () => controller.isSaving.value
                                  ?  Text(context.lang.saving)
                                  :  Text(
                                    context.lang.save,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          // ElevatedButton(
                          //   onPressed: controller.saveProfile,
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: const Color(0xFF3A506B),
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 50, vertical: 12),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(30),
                          //     ),
                          //   ),
                          //   child: const Text(
                          //     "Save",
                          //     style: TextStyle(
                          //         color: Colors.white, fontWeight: FontWeight.bold),
                          //   ),
                          // ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ---------------- HELPERS ----------------

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15 * SizeConfigs.textScale),
    );
  }

  Widget _textField(BuildContext context, TextEditingController controller, {bool enabled = true}) {
    return TextField(
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87, fontSize: 15 * SizeConfigs.textScale),
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
  // Widget _textFieldEmail(BuildContext context, TextEditingController controller, {bool enabled = true}) {
  //   return TextField(
  //     style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87, fontSize: 15 * SizeConfigs.textScale),
  //     controller: controller,
  //     enabled: enabled,
  //     decoration: InputDecoration(
  //       filled: true,
  //       fillColor: Colors.grey.shade100,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  //     ),
  //   );
  // }
  Widget _textFieldEmail(
      BuildContext context,
      TextEditingController controller, {
        bool enabled = true,
      }) {
    return TextField(
      controller: controller,
      readOnly: true, // ✅ Read only
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.black87,
        fontSize: 15 * SizeConfigs.textScale,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  Widget _birthDatePicker(BuildContext context, EditProfileController controller) {
    return Obx(() {
      return GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
          if (picked != null) {
            controller.birthDate.value = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          }
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: controller.birthDate.value.isEmpty ? context.lang.selectBirthdate: controller.birthDate.value,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
      );
    });
  }

  Widget _genderSelector(EditProfileController controller) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Female', 'Male', 'Non binary'].map((gender) {
          final isSelected = controller.selectedGender.value == gender;
          return GestureDetector(
            onTap: () => controller.selectedGender.value = gender,
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDDF3F1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey),
              ),
              alignment: Alignment.center,
              child: Text(
                gender,
                style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.black : Colors.grey),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showImagePickerOptions(BuildContext context, EditProfileController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title:  Text(context.lang.camera),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title:  Text(context.lang.gallery),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
