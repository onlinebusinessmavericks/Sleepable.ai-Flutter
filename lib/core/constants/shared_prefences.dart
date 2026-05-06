class AppSharedPreferenceKeys {

  // ===================== APP STATE =====================

  static const String selectedLanguageCode = 'selected_language_code';
  static const String currentThemeMode = 'current_theme_mode';
  static const String isWalkthroughDone = 'is_walkthrough_done';
  static const String isUserLoggedIn = 'is_user_logged_in';
  static const String isPasswordRemembered = 'is_password_remembered';
  static const String isSocialLogin = 'is_social_login';
  static const String displayTimeFormat = 'display_time_format';

  // ===================== AUTH / TOKEN =====================

  static const String apiToken = 'api_token';
  static const String refreshToken = 'refresh_token';
  static const String loginDateTime = 'login_date_time';
  static const String userLoginType = 'user_login_type'; // google / apple / email

  // ===================== USER DATA =====================

  static const String userEmail = 'user_email';
  static const String userPassword = 'user_password';
  static const String userModel = 'user_model';
  static const String currentUserData = 'current_user_data';

  // ===================== DEVICE INFO =====================
  static const deviceInfo = 'device_info';
  static const appInfo = 'app_info';
  static const String deviceId = 'device_id';
  static const String deviceName = 'device_name';
  static const String deviceVersion = 'device_version';
  static const String appVersion = 'app_version';
  static const String fcmToken = 'fcm_token';
  static const String platform = 'platform'; // android / ios

  // ===================== ONBOARDING =====================

  /// Stored as JSON String
  static const String onboardingData = 'onboarding_data';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String bodyScannerCompleted = 'bodyScanner_completed';
  static const String sleepReportCompleted = 'sleepReport_completed';
  static const String accurateSleepRecorderCompleted = 'accurateSleepRecorder_completed';
  static const String patentedSleepTrackerCompleted = 'patentedSleepTracker_completed';
  static const String bestSoundMachineCompleted = 'bestSoundMachine_completed';

  // ===================== CACHE / TEMP =====================

  static const String lastApiSyncTime = 'last_api_sync_time';

  // ===================== TRACKER =====================
  static const String isSleepTrackingActive = "is_sleep_tracking_active";
}
