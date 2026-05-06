
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../login/model/google_social_login_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/model/user_profile_model.dart';

class EditProfileController extends GetxController {
  EditProfileController(this.data);

  final UserProfileData data;
  final isSaving = false.obs;

  // Observables
  final imagePath = ''.obs;
  final selectedGender = 'Male'.obs;
  final birthDate = ''.obs;
  final email = ''.obs;

  // Controllers (IMPORTANT)
  final firstNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final profileController = Get.find<ProfileController>();

  @override
  void onInit() {
    super.onInit();

    // USE CONSTRUCTOR DATA
    firstNameCtrl.text = data.name ?? '';
    birthDate.value = _formatDob(data.dateOfBirth);
    selectedGender.value = data.gender ?? 'Male';
    emailCtrl.text = data.email ?? '';
    print("--------${email.value}");
    loadUserFromPrefs();
  }

  void loadUserFromPrefs() {
    final userDataStr =
    getStringAsync(AppSharedPreferenceKeys.currentUserData);

    if (userDataStr.isNotEmpty) {
      try {
        final userData = SocialLoginResponseData.fromJson(
          jsonDecode(userDataStr),
        );

        // ✅ Set email in controller
        emailCtrl.text = userData.email ?? '';

      } catch (e) {
        log("Error decoding user data: $e");
      }
    }else{
      print("didnt get email");
    }
  }
  String _formatDob(String? apiDob) {
    if (apiDob == null) return '';
    final date = DateTime.parse(apiDob);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      imagePath.value = picked.path;
    }
  }
  Future<void> saveProfile() async {
    if (isSaving.value) return; // prevent double tap

    try {
      isSaving.value = true; // 🔥 START LOADING

      /// Convert DOB → API format yyyy-MM-dd
      final parsedDate = DateFormat('dd/MM/yyyy').parse(birthDate.value);
      final apiDob = DateFormat('yyyy-MM-dd').format(parsedDate);

      final fields = {
        "name": firstNameCtrl.text.trim(),
        "country_code": "+91",
        "phone_number": "9712331214",
        "date_of_birth": apiDob,
        "gender": selectedGender.value,
        "address": "Surat",
      };

      final File? image =
      imagePath.value.isNotEmpty ? File(imagePath.value) : null;

      /// 🌐 API CALL
      final response = await SettingsApis.updateProfile(
        fields: fields,
        profileImage: image,
      );

      await profileController.fetchProfile(); // 🔁 REFRESH
      if (response.success) {
        // 1. Fetch fresh data from API to sync the ProfileController
        await profileController.fetchProfile();

        // 2. CRITICAL: Save the updated profile to SharedPreferences
        // so it persists on restart and shows up correctly everywhere.
        if (profileController.profile.value != null) {
          await setValue(
              AppSharedPreferenceKeys.currentUserData,
              jsonEncode(profileController.profile.value!.toJson())
          );
        }

        Get.back();}// close page

      Get.snackbar(
        Get.context?.lang.success ?? "Success",
        Get.context?.lang.profileUpdatedSuccessfully ?? "Profile updated successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ UPDATE PROFILE ERROR");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      Get.snackbar(
        Get.context?.lang.error ?? "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false; // 🔥 STOP LOADING
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    emailCtrl.dispose();
    super.onClose();
  }
}
