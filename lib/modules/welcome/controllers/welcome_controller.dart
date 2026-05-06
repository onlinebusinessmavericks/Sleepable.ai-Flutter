// import 'dart:io';
//
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:sleepable_ai/modules/login/views/login_view.dart';
// import 'package:get/get.dart';
// import 'dart:async';
// import '../../../core/utils/library.dart';
// import '../../../routes/app_pages.dart';
// import '../../dashboard/controllers/dashboard_controller.dart';
//
// class WelcomeController extends GetxController {
//   @override
//   void onInit() {
//     super.onInit();
//     _start();
//     getAppInfo();
//     getDeviceInfo();
//   }
//
//   Future<void> _start() async {
//     await Future.delayed(const Duration(seconds: 2));
//   }
//   // Button animation scale
//   var buttonScale = 1.0.obs;
//
//   // Method that runs when Start is pressed
//   Future<void> onStartPressed() async {
//     // Shrink
//     buttonScale.value = 0.9;
//     await Future.delayed(Duration(milliseconds: 120));
//
//     // Expand
//     buttonScale.value = 1.0;
//     await Future.delayed(Duration(milliseconds: 120));
//
//     // After animation → go next screen
//     // Get.toNamed(Routes.login);
//     Get.toNamed(Routes.sleepGoal);
//
//     // );
//   }
//
//   Future<void> getAppInfo() async {
//     final info = await PackageInfo.fromPlatform();
//
//     print("📦 App Name: ${info.appName}");
//     print("🆔 Package Name: ${info.packageName}");
//     print("🔢 Version: ${info.version}");
//     print("🏗 Build Number: ${info.buildNumber}");
//   }
//   Future<void> getDeviceInfo() async {
//     final deviceInfo = DeviceInfoPlugin();
//
//     if (Platform.isAndroid) {
//       final android = await deviceInfo.androidInfo;
//
//       print("📱 Device: ${android.manufacturer} ${android.model}");
//       print("🤖 Android Version: ${android.version.release}");
//       print("🧠 SDK: ${android.version.sdkInt}");
//       print("🆔 Device ID: ${android.id}");
//       print("🧩 Brand: ${android.brand}");
//     }
//
//     if (Platform.isIOS) {
//       final ios = await deviceInfo.iosInfo;
//
//       print("📱 Device: ${ios.name}");
//       print("📱 Model: ${ios.model}");
//       print("🍎 iOS Version: ${ios.systemVersion}");
//       print("🆔 Identifier: ${ios.identifierForVendor}");
//     }
//   }
// }
import 'dart:io';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../routes/app_pages.dart';

class WelcomeController extends GetxController {
  var buttonScale = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _saveAppInfo(),
      _saveDeviceInfo(),
    ]);
  }


  Future<void> onStartPressed() async {
    // Navigation happens here
    Get.toNamed(Routes.sleepGoal);
  }
  /// ▶ Button animation
  // Future<void> onStartPressed() async {
  //   // await HapticFeedback.vibrate();
  //   await Haptics.vibrate(HapticsType.light);
  //   buttonScale.value = 0.9;
  //   await Future.delayed(const Duration(milliseconds: 120));
  //
  //   buttonScale.value = 1.0;
  //   await Future.delayed(const Duration(milliseconds: 120));
  //
  //   Get.toNamed(Routes.sleepGoal);
  // }

  /// 📦 Save App Info
  Future<void> _saveAppInfo() async {
    final info = await PackageInfo.fromPlatform();

    final appInfo = {
      "app_name": info.appName,
      "package_name": info.packageName,
      "version": info.version,
      "build_number": info.buildNumber,
    };

    await setValue(AppSharedPreferenceKeys.appInfo, jsonEncode(appInfo));

    log("✅ App Info Saved: $appInfo");
  }

  /// 📱 Save Device Info
  // Future<void> _saveDeviceInfo() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //   final package = await PackageInfo.fromPlatform();
  //
  //   Map<String, dynamic> data = {};
  //
  //   if (Platform.isAndroid) {
  //     final android = await deviceInfo.androidInfo;
  //
  //     data = {
  //       "device_id": android.id,
  //       "device_name": "${android.manufacturer} ${android.model}",
  //       "device_version": android.version.release,
  //       "app_version": package.version,
  //       "fcm_token": getStringAsync(AppSharedPreferenceKeys.fcmToken),
  //     };
  //   }
  //
  //   if (Platform.isIOS) {
  //     final ios = await deviceInfo.iosInfo;
  //
  //     data = {
  //       "device_id": ios.identifierForVendor ?? "",
  //       "device_name": ios.name,
  //       "device_version": ios.systemVersion,
  //       "app_version": package.version,
  //       "fcm_token": getStringAsync(AppSharedPreferenceKeys.fcmToken),
  //     };
  //   }
  //
  //   await setValue(
  //     AppSharedPreferenceKeys.deviceInfo,
  //     jsonEncode(data),
  //   );
  //
  //   log("✅ Device Info Saved: $data");
  // }

  Future<void> _saveDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final package = await PackageInfo.fromPlatform();

    // 2. Try to get the latest FCM Token
    String? fcmToken = getStringAsync(AppSharedPreferenceKeys.fcmToken);

    if (fcmToken.isEmpty) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? "";
        // Save it for future use
        if (fcmToken.isNotEmpty) {
          await setValue(AppSharedPreferenceKeys.fcmToken, fcmToken);
        }
      } catch (e) {
        log("❌ Error fetching FCM Token: $e");
      }
    }

    Map<String, dynamic> data = {};

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      data = {
        "device_id": android.id,
        "device_name": "${android.manufacturer} ${android.model}",
        "device_version": android.version.release,
        "app_version": package.version,
        "fcm_token": fcmToken, // 3. Updated Token
      };
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      data = {
        "device_id": ios.identifierForVendor ?? "",
        "device_name": ios.name,
        "device_version": ios.systemVersion,
        "app_version": package.version,
        "fcm_token": fcmToken, // 3. Updated Token
      };
    }

    await setValue(
      AppSharedPreferenceKeys.deviceInfo,
      jsonEncode(data),
    );

    log("✅ Device Info (including FCM) Saved: $data");
  }
}
