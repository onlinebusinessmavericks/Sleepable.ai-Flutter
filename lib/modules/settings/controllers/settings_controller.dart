import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sleepable_ai/data/models/common_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../data/services/api_sevices.dart';
import '../../../data/services/session_clear.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/ai_consent_dialog.dart';
import '../model/user_settings_model.dart';
import '../widget/webview.dart';
import 'package:sleepable_ai/widgets/app_snackbar.dart';

class SettingsController extends GetxController {
  void onShareApp() {
    final String localizedSubject = Get.context?.lang.shareSubject ?? "Check out this awesome app!";
    print("object");
    const appUrl = "https://play.google.com/store/apps/details?id=com.example.app";
    Share.share(appUrl, subject: localizedSubject);
  }

  void onRateUs() {
    // TODO: Play Store / App Store redirect
  }
  void onEmailSupport() async {
      // 1. Get localized strings for Subject and Body
      final String localizedSubject = Get.context?.lang.supportRequestSubject ?? 'Support Request';
      final String localizedBody = Get.context?.lang.supportEmailBody ?? 'Hi team,\n\nI need help with...';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'onlinebusinessmavericks@gmail.com',
        query: _encodeQueryParameters({
          'subject': localizedSubject,
          'body': localizedBody,
        }),
      );

    try {
      // Note: On some Android Emulators, canLaunchUrl returns false even if it works.
      // It is often better to just try launching.
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // appSnackbar("Error", "Could not open email app");
      appSnackbar(
          Get.context?.lang.errorLabel ?? "Error",
          Get.context?.lang.errorNoEmail ?? "Could not open email app"
      );
      debugPrint("📧 Email error → $e");
    }
  }

// Helper function to ensure spaces are encoded as %20 and not +
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
  /// Apple Guideline 3.1.1: restore an existing subscription.
  void onRestorePurchases() {
    final sub = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());
    sub.restorePurchases();
  }

  /// 🔒 Apple 5.1.1(i) / 5.1.2(i): gives the user control to review, grant and
  /// revoke AI data sharing.
  void onAiDataSharing(BuildContext context) => showAiDataSettings(context);

// Inside SettingsController
  void onPrivacyPolicy() {
    Get.to(() =>  WebViewScreen(
        title: Get.context?.lang.privacyPolicy ?? "Privacy Policy",
        url: "https://sleepable.ai/privacy.html"
    ));
  }

  void onTermsOfService() {
    Get.to(() =>  WebViewScreen(
        title: Get.context?.lang.termsService ?? "Terms of Service",
        url: "https://sleepable.ai/terms.html"
    ));
  }


  void onCommunityGuidelines() {}

  void onManageSubscription() async {
    try {
      final Uri url;
      if (GetPlatform.isIOS) {
        url = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (GetPlatform.isAndroid) {
        url = Uri.parse('https://play.google.com/store/account/subscriptions');
      } else {
        url = Uri.parse('https://sleepable.ai');
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      appSnackbar("Error", "Could not open subscription management");
    }
  }

  void onSignIn() {
    Get.offAllNamed(Routes.login);
  }

  /// -------------------- LOGOUT --------------------
   void showLogoutDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (_) {
          return GiffyDialog(
            key: const Key("DeleteAccountDialog"),

            giffy: Lottie.asset(
              Assets.lottieLineLogoutIconAnimations,
              height: 120,
              fit: BoxFit.fitHeight,
              repeat: true,
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.color(
                    const ['**'], // apply to all layers
                    value: Colors.white,
                  ),
                ],
              ),
            ),


            title: Text(
              context.lang.logoutTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),

            content:  Text(
              context.lang.logoutContent,
              // 'Are you sure you want to log out of your account? '
              //     'You can log back in anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            actionsAlignment: MainAxisAlignment.center,
            backgroundColor: const Color(0xFF1E1E1E),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:  Text(
                  context.lang.cancel,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // 🔥 red for destructive action
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async{
                  Navigator.pop(context);
                  await logout();
                },
                child:  Text(
          context.lang.yesLogout,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  Future<void> logout() async {
    try {
      final token = getStringAsync(AppSharedPreferenceKeys.fcmToken);
      final request = {
        if (token.isNotEmpty) "fcm_token": token,
      };

      try {
        await AuthServiceApis.logOut(request: request);
      } catch (e) {
        debugPrint("🚪 Logout API error → $e");
      }

      await SessionClear.clearForLogout();
      Get.offAllNamed(Routes.login);
    } catch (e) {
      debugPrint("🚪 Logout error → $e");
      await SessionClear.clearForLogout();
      Get.offAllNamed(Routes.login);
    }
  }

  /// -------------------- DELETE ACCOUNT --------------------

  void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return GiffyDialog(
          key: const Key("DeleteAccountDialog"),

          giffy: Lottie.asset(
            Assets.lottieDelete,
            height: 120,
            fit: BoxFit.fitHeight,
            repeat: true,
          ),

          title:  Text(
            context.lang.deleteTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),

          content:  Text(
            context.lang.deleteContent,  // 'Are you sure you want to permanently delete your account? '
            //     'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),

          actionsAlignment: MainAxisAlignment.center,
          backgroundColor: const Color(0xFF1E1E1E),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text(
                context.lang.cancel,
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // 🔥 red for destructive action
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async{
                Navigator.pop(context);
                await onDeleteAccount(context);


                // 🧠 Add your actual delete logic here
                // controller.deleteUserAccount();
              },
              child:  Text(
        context.lang.yesDelete,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  /// Guards against a second tap while the first delete is still in flight.
  bool _deleteInFlight = false;

  Future<void> onDeleteAccount(BuildContext context) async {
    if (_deleteInFlight) return;
    _deleteInFlight = true;
    try {
      final CommonResponse response =
      await AuthServiceApis.deleteAccount();

      if (response.success == true) {
        await SessionClear.clearForDelete();
        Get.offAllNamed(Routes.login);
        appSnackbar(
          Get.context?.lang.accountDeletedLabel ?? "Account Deleted",
          response.message ?? Get.context?.lang.accountDeletedSuccess ?? "Your account has been deleted successfully",
        );
      } else {
        appSnackbar(
          Get.context?.lang.deleteFailedLabel ?? "Delete Failed",
          response.message ?? Get.context?.lang.somethingWentWrong ?? "Something went wrong",
        );
      }
    } catch (e) {
      debugPrint("Delete account error: $e");
      appSnackbar(
        Get.context?.lang.deleteFailedLabel ?? "Delete Failed",
        e.toString().replaceFirst('Exception:', '').trim(),
      );
    } finally {
      _deleteInFlight = false;
    }
  }
}
