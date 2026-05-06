// import 'dart:io';
//
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:sleepable_ai/modules/login/views/login_view.dart';
// import 'package:get/get.dart';
// import 'dart:async';
// import '../../../core/utils/library.dart';
// import '../../../routes/app_pages.dart';
// import '../../dashboard/controllers/dashboard_controller.dart';
//
// class LanguageController extends GetxController {
//   Rx<Locale> locale = const Locale('en').obs;
//
//   static const _key = 'language_code';
//
//   final languages = const [
//     {'code': 'en', 'name': 'English'},
//     {'code': 'hi', 'name': 'हिन्दी'},
//     {'code': 'fr', 'name': 'Français'},
//     {'code': 'de', 'name': 'Deutsch'},
//     {'code': 'ar', 'name': 'العربية'},
//   ];
//
//   @override
//   void onInit() {
//     _loadLanguage();
//     super.onInit();
//   }
//
//   Future<void> _loadLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString(_key) ?? 'en';
//     _apply(saved);
//   }
//
//   void _apply(String code) {
//     locale.value = Locale(code);
//     Get.updateLocale(locale.value);
//   }
//
//   Future<void> changeLanguage(String code) async {
//     _apply(code);
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_key, code);
//   }
// }
