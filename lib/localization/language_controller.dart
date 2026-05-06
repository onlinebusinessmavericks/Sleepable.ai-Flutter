import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

import '../data/services/api_sevices.dart';

class LanguageController extends GetxController {
  Rx<Locale> locale = const Locale('en').obs;

  static const _key = 'language_code';

  final languages = const <LanguageItem>[
    LanguageItem(code: 'en', name: 'English'),
    LanguageItem(code: 'de', name: 'Deutsch'), //Deutsch (German)
    LanguageItem(code: 'fr', name: 'Français'), //Français (French)
    LanguageItem(code: 'pt', name: 'Português'), //Português (Portuguese)
    LanguageItem(code: 'es', name: 'Español'), //Español (Spanish)
  ];

  @override
  void onInit() {
    _loadLanguage();
    super.onInit();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCode = prefs.getString(_key);
    if (savedCode != null) {
      _apply(savedCode);
      return;
    }

    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    const supported = ['en', 'de', 'fr', 'pt', 'es'];

    final code = supported.contains(deviceLocale.languageCode) ? deviceLocale.languageCode : 'en';

    _apply(code);
    await prefs.setString(_key, code);
  }

  void _apply(String code) {
    locale.value = Locale(code);
    Get.updateLocale(locale.value);
  }
  Future<void> changeLanguage(String code) async {
    // 1. UI update
    _apply(code);

    // 2. Local preference save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);

    // 3. 🔥 API call to backend
    bool isSuccess = await SettingsApis.updateUserLanguage(code);

    if (isSuccess) {
      debugPrint("✅ Language updated on backend: $code");
    } else {
      debugPrint("⚠️ Backend language update failed");
    }
  }
  // Future<void> changeLanguage(String code) async {
  //   _apply(code);
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_key, code);
  // }
}

class LanguageItem {
  final String code;
  final String name;

  const LanguageItem({required this.code, required this.name});
}
