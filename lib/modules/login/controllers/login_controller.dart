import 'dart:developer' as dev;
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sleepable_ai/modules/login/model/google_social_login_model.dart';
import 'package:video_player/video_player.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../../widgets/timezone.dart';
import '../../otp_verification/views/otp_verification_view.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/model/user_profile_model.dart';

class LoginController extends BaseController {
  final isLoading = false.obs;
  final isVideoReady = false.obs;

  late VideoPlayerController videoController;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ===================== INIT =====================

  @override
  void onInit() {
    super.onInit();

    videoController = VideoPlayerController.asset(Assets.onboardingLoginLogoBg)
      ..initialize().then((_) {
        isVideoReady.value = true;
        videoController
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });
  }

  @override
  void onClose() {
    videoController.dispose();
    super.onClose();
  }

  // ===================== GOOGLE LOGIN =====================

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      await _handleSocialLogin(provider: "google", user: userCredential.user);
    } catch (e) {
      isLoading.value = false;
      print("❌ Google Login Error: $e");
    }
  }

  // ===================== APPLE LOGIN =====================

  Future<void> loginWithApple() async {
    try {
      isLoading.value = true;

      // 1. Apple ID Se Credential Lena
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 2. Firebase Credential Create Karna
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 3. Firebase Auth Se Sign In
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // 4. Handle Social Login (Same as Google)
      await _handleSocialLogin(provider: "apple", user: userCredential.user);

    } catch (e) {
      isLoading.value = false;
      print("❌ Apple Login Error: $e");
      // User cancel kare toh loading band honi chahiye
    }
  }
  // ===================== FACEBOOK LOGIN =====================

  Future<void> loginWithFaceBook() async {
    try {
      isLoading.value = true;

      // final LoginResult result = await FacebookAuth.instance.login(
      //   permissions: ['email', 'public_profile'],
      // );
      final LoginResult result = await FacebookAuth.instance.login(permissions: ['public_profile']);

      if (result.status != LoginStatus.success) {
        isLoading.value = false;
        print("❌ Facebook Login Cancelled or Failed");
        return;
      }

      final AccessToken accessToken = result.accessToken!;

      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      _onLoginSuccess(userCredential.user);
    } catch (e) {
      isLoading.value = false;
      print("❌ Facebook Login Error: $e");
    }
  }

  // ===================== SING UP =====================

  Future<void> loginWithEmail() async {
    Get.toNamed(Routes.signup);
  }

  // ===================== SOCIAL LOGIN HANDLER =====================

  Future<void> _handleSocialLogin({required String provider, required User? user}) async {
    if (user == null) {
      isLoading.value = false;
      return;
    }

    try {
      final Map<String, dynamic> request = await _buildSocialLoginRequest(provider: provider, user: user);
      final SocialLoginResponse response = await AuthServiceApis.socialLogin(request: request);

      if (response.success == true) {
        // 1. Tokens & Login Status Save
        await setValue(AppSharedPreferenceKeys.apiToken, response.data.tokens.access);
        await setValue(AppSharedPreferenceKeys.refreshToken, response.data.tokens.refresh);
        await setValue(AppSharedPreferenceKeys.isUserLoggedIn, true);

        // 2. Profile Setup
        final userData = UserProfileData(
          name: response.data.name,
          profileImage: response.data.avatarUrl,
          phoneNumber: response.data.phone,
          countryCode: response.data.countryCode,
        );
        await setValue(AppSharedPreferenceKeys.currentUserData, jsonEncode(response.data.toJson()));
        Get.put(ProfileController()).profile.value = userData;

        // 3. Subscription Setup
        final subController = Get.isRegistered<SubscriptionController>()
            ? Get.find<SubscriptionController>()
            : Get.put(SubscriptionController(), permanent: true);

        // Pehle Login response se update karein
        bool loginPremiumStatus = response.data.isPremium;
        await subController.updatePremiumStatus(loginPremiumStatus, isFromBackend: true);

        // 🔥 DOUBLE CHECK & DATA PREP
        if (!loginPremiumStatus) {
          print("🔄 Login said false, double checking...");
          await Future.wait([
            subController.getBackendSubscriptionStatus(),
            subController.checkSpinStatus(),
          ]);
        }

        // 🔥 Navigation se pehle Products load karna trigger karein
        // Agar Paywall dikhana hai to ye zaroori hai
        await subController.initData();

        // 🚀 FINAL NAVIGATION
        if (subController.isPremium.value == true) {
          print("✅ User is Premium. Going to Dashboard.");
          Get.offAllNamed(Routes.dashboard);
        } else {
          print("❌ User is FREE. Showing Paywall on Dashboard.");
          // Dashboard par jao aur arguments bhejo
          Get.offAllNamed(
              Routes.dashboard,
              arguments: {'show_paywall': true}
          );
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      // ⚠️ Yahan login fail hone par user ko error dikhana zaroori hai
      print("❌ Social Login Error: $e");
      // Get.snackbar("Login Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  // ===================== BUILD REQUEST BODY =====================

  Map<String, dynamic> getSavedDeviceInfo() {
    final raw = getStringAsync(AppSharedPreferenceKeys.deviceInfo);

    if (raw.isEmpty) return {};

    try {
      return jsonDecode(raw);
    } catch (e) {
      return {};
    }
  }
  Future<Map<String, dynamic>> _buildSocialLoginRequest({required String provider, required User user}) async {
    /// Provider UID
    String? providerUid = "";
    try {
      providerUid = user.providerData.firstWhere((e) => e.providerId.contains(provider)).uid;
    } catch (e) {
      providerUid = user.uid;
    }

    // --- NAME LOGIC START ---
    String finalName = "";

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      finalName = user.displayName!;
    } else if (user.email != null && user.email!.isNotEmpty) {
      // Example: vikas.patel@gmail.com -> vikas patel
      String emailPart = user.email!.split('@')[0];

      // Clean dots/underscores and capitalize
      // nb_utils ka validate() aur capitalizeFirstLetter() use karein
      finalName = emailPart.replaceAll('.', ' ').replaceAll('_', ' ').validate().capitalizeFirstLetter();
    } else {
      finalName = Get.context?.lang.dreamerName ?? "Dreamer";
    }
    // --- NAME LOGIC END ---

    final deviceInfo = getSavedDeviceInfo();
    String? fcmToken = deviceInfo["fcm_token"];

    if (fcmToken == null || fcmToken.isEmpty) {
      if (Platform.isIOS) {
        dev.log("⚠️ iOS Free Account: Skipping getToken() to prevent crash.");
        fcmToken = "";
      } else {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          dev.log("❌ FCM Token Error: $e");
          fcmToken = "";
        }
      }
    }

    String deviceTimezone = await getCurrentTimezone();
    final String onboardingRaw = getStringAsync(AppSharedPreferenceKeys.onboardingData, defaultValue: "{}");
    final Map<String, dynamic> onboardingData = onboardingRaw.isNotEmpty ? jsonDecode(onboardingRaw) : {};

    /// ✅ FINAL API BODY
    return {
      "provider": provider,
      "provider_id": providerUid,
      "email": user.email ?? "",
      "name": finalName,
      "avatar_url": user.photoURL ?? "",
      "referral_code": "",
      "device_info": {
        "device_id": deviceInfo["device_id"] ?? "",
        "device_name": deviceInfo["device_name"] ?? "",
        "device_version": deviceInfo["device_version"] ?? "",
        "app_version": deviceInfo["app_version"] ?? "",
        "fcm_token": fcmToken ?? "",
        "timezone": deviceTimezone,
      },
      "onboarding_data": onboardingData,
    };
  }

  void _onLoginSuccess(User? user) {
    if (user == null) {
      isLoading.value = false;
      throw Exception("Firebase user is null");
    }

    print("✅ Login Success");
    print("👤 UID: ${user.uid}");
    print("📧 Email: ${user.email}");
    print("🙍 Name: ${user.displayName}");
    print("🖼 Photo: ${user.photoURL}");
    print("⏰ Last Sign-In: ${user.metadata.lastSignInTime}");
    print("🕒 Account Created: ${user.metadata.creationTime}");

    for (var provider in user.providerData) {
      print("🔐 Provider: ${provider.providerId}");
      print("🆔 Provider UID: ${provider.uid}");
      print("📧 Provider Email: ${provider.email}");
      print("🙍 Provider Name: ${provider.displayName}");
      print("🖼 Provider Photo: ${provider.photoURL}");
    }
  }

  // ===================== SKIP =====================

  void skip() {
    Get.offAllNamed(Routes.dashboard);
  }

  // ===================== EMAIL LOGIN (FOR REVIEWER) =====================

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> loginWithEmailApi() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    try {
      isLoading.value = true;

      final Map<String, dynamic> request = {
        "email": emailController.text.trim(),
        "password": passwordController.text,
      };

      // Yahan apni AuthServiceApis call karein jo backend ne banayi hai
      final response = await AuthServiceApis.emailLogin(request: request);

      if (response.success == true) {
        // OTP Screen par bhejein (Agar static OTP setup hai)
        Get.toNamed(
            Routes.otpScreen,
            arguments: {"email": emailController.text.trim()}
        );
      } else {
        Get.snackbar("Error", response.message);
      }
    } catch (e) {
      print("❌ Email Login Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  // ===================== OTP VERIFICATION (FOR REVIEWER) =====================

  final otpController = TextEditingController();

  Future<void> verifyOtpApi() async {
    final String email = Get.arguments["email"] ?? "";
    final String otp = otpController.text.trim();

    if (otp.length < 6) {
      Get.snackbar("Error", "Enter 6-digit OTP");
      return;
    }

    try {
      isLoading.value = true;
      final Map<String, dynamic> request = {
        "email": email,
        "otp_code": otp,
      };

      // OTP verify hone ke baad backend tokens (SocialLoginResponse) bhejega
      final response = await AuthServiceApis.verifyEmailOtp(request: request);

      if (response.success == true) {
        // ✅ SUCCESS: Wahi logic call karein jo social login ke tokens save karta hai
        // Humne _handleSocialLogin ko refactor kiya hai niche
        await _saveTokensAndNavigate(response);
      } else {
        Get.snackbar("OTP Error", response.message ?? "Invalid OTP");
      }
    } catch (e) {
      dev.log("❌ OTP Verification Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

// Common function to save tokens and move to Dashboard
  Future<void> _saveTokensAndNavigate(SocialLoginResponse response) async {
    // 1. Tokens & Login Status Save
    await setValue(AppSharedPreferenceKeys.apiToken, response.data.tokens.access);
    await setValue(AppSharedPreferenceKeys.refreshToken, response.data.tokens.refresh);
    await setValue(AppSharedPreferenceKeys.isUserLoggedIn, true);

    // 2. Profile Setup
    final userData = UserProfileData(
      name: response.data.name,
      profileImage: response.data.avatarUrl,
      phoneNumber: response.data.phone,
      countryCode: response.data.countryCode,
    );
    await setValue(AppSharedPreferenceKeys.currentUserData, jsonEncode(response.data.toJson()));
    Get.put(ProfileController()).profile.value = userData;

    // 3. Subscription Check & Navigate
    final subController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);

    await subController.initData();

    if (subController.isPremium.value == true) {
      Get.offAllNamed(Routes.dashboard);
    } else {
      Get.offAllNamed(Routes.dashboard, arguments: {'show_paywall': true});
    }
  }
}
