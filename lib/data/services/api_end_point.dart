class APIEndPoints {
  ///Auth & User
  static const String socialLogin = 'users/auth/';
  static const String logOut = 'users/logout/';
  static const String deleteAccount = 'users/delete-account/';
  static const String updateFCMToken = 'users/update-fcm-token/';
  /// AI data-sharing consent (Apple Guideline 5.1.1(i) / 5.1.2(i))
  static const String aiConsent = 'users/ai-consent/';
  ///Home
  static const String homePage = "homepage/home-page";

  ///sounds
  // static const String fetchSoundsArtists = 'sounds/artists/';
  static const String fetchSoundsCategories = 'sounds/categories/';
  static const String fetchSoundsSubCategories = 'sounds/subcategories/?category_slug=';
  static const String fetchSoundsList = 'sounds/list/';
  static const String soundsMixedCreate = 'sounds/mixed/create/';
  static const String soundsMixedList = 'sounds/mixed/list/';
  static const String soundsMixedDetail = 'sounds/mixed/'; // + <id>/
  static const String forgotPassword = 'users/forgot-password/';
  static const String resetPassword = 'users/reset-password/';
  static const String toggleFavorite = 'sounds/favorite/toggle/';
  static const String fetchFavoriteSounds = 'sounds/favorite/list/';
 ///Setting
  static const String getProfile = 'users/get-profile/';
  static const String updateProfile = 'users/update-profile/';
  static const userSettings = "users/settings/";
  static const String updateStreak = "users/update-streak/";
  static const String streak = "users/streak/";
  // static const String updateUser = 'users/update/';
  /// Tracker
  static const String trackerNotesCategories = 'tracker/notes/categories/';
  static const String createSleepNote = 'tracker/notes/create/';
  static const String updateSleepNote = 'tracker/notes/detail/';
  static const String startSleepTracker = 'tracker/start/';
  static const String stopSleepTracker = 'tracker/stop/';
  static const String uploadTrackerAudio = 'tracker/audio/';
  /// Chat / Dream Bot
  static const String chat = 'chat/';
  static const String startDreamSession = 'progress/dreambot/start/';
// For message and analyze, we will inject the ID dynamically in the API service
  /// Progress
  static const String sleepDurationChart = 'progress/sleep-duration-chart';
  static const String sleepCalendar = 'progress/sleep-calendar/';
  static const String sleepConsistencyData = "progress/sleep-consistancy-data";
  static const String keyInsights = "progress/key-insights";
  static const String achievementBadges = "progress/achievement-badges";
  static const String dreamList = 'progress/dream-list/';
  static const String analyzeDream = 'progress/analyze-dream/';
  static const String sleepRecorder = 'progress/sleep-recorder';
  static const String snoringIntensity = "progress/send-snoring-intensity-data";
  static const String aiInsights = "progress/ai-insights";
  static const String sleepQuality = "progress/sleep-quality";
  static const String sleepStages = "progress/sleep-stages/";
  static const String personalizedRecommendations = "progress/personalized-recommendations";
  static const String sleepQuiz = "progress/sleep-quiz/";


  /// Subscription & Spin Wheel
  static const String spinWheel = 'users/spin-wheel/';
  static const String verifyPurchase = 'users/verify-purchase/';
  static const String subscriptionStatus = 'users/subscription/';
}

