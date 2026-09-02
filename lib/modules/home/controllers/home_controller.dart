import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:sleepable_ai/core/utils/library.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import 'package:sleepable_ai/modules/home/model/artist_model.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../data/services/api_sevices.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/notification_service.dart';
import '../../../widgets/rating_dialog.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../../widgets/timezone.dart';
import '../../login/model/google_social_login_model.dart';
import '../../profile/model/UserSettings.dart';
import '../../sleep_info/model/sleeppedia_item.dart';
import '../../sleep_info/widget/sleeppedia_data.dart';
import '../../sleep_sound/model/sound_sub_category_model.dart';
import '../../sleep_tracker_screen/controllers/tracker_exit_guard.dart';
import '../model/home_page_response.dart';
class HomeController extends GetxController with GetTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 1. SERVICES & CONTROLLERS
  // ---------------------------------------------------------------------------
  final screenScrollController = ScrollController();
  late AnimationController animationController;
  late AnimationController horizontalController;
  final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: 7);
  late Timer _timer;

  // ---------------------------------------------------------------------------
  // 2. OBSERVABLES (STATE MANAGEMENT)
  // ---------------------------------------------------------------------------

  // --- Loading States ---
  final RxBool isLoadingHome = false.obs;
  final RxBool isLoadingArtists = false.obs;

  // --- API Data ---
  final Rx<HomePageResponse?> homeData = Rx<HomePageResponse?>(null);

  // --- Sleep Summary & Progress ---
  var lastNightSleepHours = 7.0.obs;
  var lastNightQuality = 4.obs;
  var sleepProgress = 0.70.obs;
  var message = "".obs;
  var toDayDate = "".obs;

  // --- Sleep Goals & Bedtime ---
  var bedtime = TimeOfDay(hour: 1, minute: 0).obs;
  var targetBedtime = "".obs;
  var targetWakeTime = "".obs;
  var sleepGoalHours = 8.0.obs;
  var tonightGoalHours = 8.0.obs;
  var countdownText = "".obs;
  var selectedNumber = 8.obs;

  // --- Toggles & UI State ---
  var reminderOn = true.obs;
  var isEnabled = false.obs;
  var reminderEnabled = false.obs;
  var isOn = true.obs;
  var isStatusBarDark = false.obs;
  var statusBarOpacity = 0.0.obs;
  var hasShownShowcase = false.obs;
  RxInt premiumClickCount = 0.obs;
  var tappedIndex = (-1).obs;
  var selectedIndex = 0.obs;
  var currentBanner = 0.obs;

  // --- Animations State ---
  RxDouble buttonX = 0.0.obs;
  RxDouble buttonY = 0.0.obs;
  var moonAngle = 0.0.obs;
  // var direction = 0.0.obs;
  var isFullMoon = true.obs;
  var isDirection = true.obs;

  // --- Greeting ---
  var greeting = ''.obs;
  Rx<TimeOfDay?> bedTime = Rx<TimeOfDay?>(null);
  Rx<TimeOfDay?> wakeTime = Rx<TimeOfDay?>(null);
  RxInt sleepQuality = 0.obs;

  // --- Animations ---
  late Animation<double> animation;
  late Animation<double> breathingAnimation;
  late Animation<double> horizontalAnimation;

  // --- userName ---
  RxString userName = "".obs;
  RxString token = "".obs;

  // ---------------------------------------------------------------------------
  // 3. GETTERS
  // ---------------------------------------------------------------------------
  bool get canSave => bedTime.value != null && wakeTime.value != null;

  // ---------------------------------------------------------------------------
  // 4. LIFECYCLE METHODS
  // ---------------------------------------------------------------------------

  ///For Sleep duration
  RxDouble averageSleep = 0.0.obs;
  RxList<double> chartValues = <double>[].obs;
  RxList<String> chartLabels = <String>[].obs;
  RxBool isChartLoading = false.obs;
  var selectedBarIndex = (-1).obs; // -1 means no bar is currently selected
  var selectedTab = "Week".obs;

  final Rx<SleepStatus?> sleepStatus = Rx<SleepStatus?>(null);
  final RxBool isSavingSettings = false.obs;
  @override
  void onInit() {
    super.onInit();
    updateFilteredItems();

    // 2. Worker setup for future changes
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController(),permanent: true);

    ever(subController.isPremium, (bool val) {
      print("🔥 HomeController: Premium worker triggered with: $val");
      updateFilteredItems();
    });
    _setupControllers();
    _initAnimations();

    // 1. Load basic user info
    loadUserFromPrefs();
    updateGreeting();
    initTodayDate();
    // 2. 🔥 INSTANT CACHE LOAD (The "No-Delay" Fix)
    String cachedJson = getStringAsync("cached_home_data");
    if (cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson);
        homeData.value = HomePageResponse.fromJson(decoded);
        _syncHomeState(); // UI fills up instantly here
        print("📦 Home screen loaded from cache");
      } catch (e) {
        print("❌ Cache load failed: $e");
      }
    }

    // 3. Start API refresh in background
    _refreshAllData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTimers();
      toggleMoon();
      // directionLeftRight();
      changeSelectedNumber(8);
    });
  }
// At the top of your controller
  RxString currentInsight = "".obs;
  // Define a key for the index
   String insightIndexKey = "insight_message_index";

  String insightLastMessageKey = "insight_last_message";

  void updateInsightMessage() {
    final insights = homeData.value?.data?.sleepInsights ?? [];

    if (insights.isNotEmpty) {
      int lastIndex = getIntAsync(insightIndexKey, defaultValue: 0);
      if (lastIndex >= insights.length) lastIndex = 0;

      // ✅ Update variable
      currentInsight.value = insights[lastIndex];

      // ✅ Cache the STRING so we can show it instantly next time
      setValue(insightLastMessageKey, currentInsight.value);

      // Prepare next index
      int nextIndex = (lastIndex + 1) % insights.length;
      setValue(insightIndexKey, nextIndex);
    } else {
      currentInsight.value = homeData.value?.data?.sleepSummary.message ?? "";
      setValue(insightLastMessageKey, currentInsight.value);
    }
  }
  void _refreshAllData() {
    fetchHomePageData();
    fetchSleepChart("weekly");
  }

  @override
  void onReady() {
    super.onReady();

    // 1. UI Animations start karein
    horizontalController.forward(from: 0.0);

    final subController = Get.find<SubscriptionController>();

    // 2. Priority 1: Paywall from Login/Arguments
    if (Get.arguments != null && Get.arguments['show_paywall'] == true) {
      _showInitialPaywall();
    }
    else if (!Platform.isIOS) {
      Future.delayed(const Duration(seconds: 1), () async {
        if (isClosed) return;
        // Re-check after the launch sync: premium status is fetched
        // asynchronously, so it may still have been unknown when onReady ran.
        if (await _isPremiumAfterSync(subController)) {
          _checkAndShowRatingDialog();
          return;
        }
        if (!isClosed) showRotatingPremiumSheet(Get.context!);
      });
    }
    // 4. Priority 3: Rating Dialog (Sirf Premium users ya tab jab Paywall skip ho jaye)
    else {
      _checkAndShowRatingDialog();
    }
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!isClosed) {
        NotificationService.requestNotificationPermission();
      }
    });
  }
  /// Premium status is fetched asynchronously at launch, so waits briefly for
  /// that sync before answering. Without this a paying or admin-granted user
  /// gets an upsell on app open.
  Future<bool> _isPremiumAfterSync(SubscriptionController sub) async {
    if (!sub.isInitialSyncDone.value) {
      await sub.isInitialSyncDone.stream
          .firstWhere((done) => done)
          .timeout(const Duration(seconds: 6), onTimeout: () => true);
    }
    return sub.isPremium.value;
  }

  // Helper 1: Paywall Handler
  void _showInitialPaywall() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (isClosed) return;

      final subController = Get.find<SubscriptionController>();

      // Never upsell someone who already has premium.
      if (await _isPremiumAfterSync(subController)) {
        if (Get.arguments != null) Get.arguments['show_paywall'] = false;
        return;
      }
      if (isClosed) return;

      if (Platform.isIOS) {
        showPremiumOfferSheet4(Get.context!);
      } else {
        bool hasSpun = subController.spinInfo.value?.alreadySpun ?? false;
        if (hasSpun) {
          showPremiumOfferSheet6(Get.context!);
        } else {
          showPremiumOfferSheet4(Get.context!);
        }
      }

      Get.arguments['show_paywall'] = false;
    });
  }

// Helper 2: Rating Handler (Session Count Logic)
  void _checkAndShowRatingDialog() {
    // Key names (nb_utils use ho raha hai)
    const String appOpenCountKey = "app_open_count";
    const String ratedKey = "user_has_rated";

    // Skip if Wake/Quit already queued/showed rating for this exit
    if (TrackerExitGuard.isExitInProgress ||
        TrackerExitGuard.shouldSuppressDashboardRemount ||
        TrackerExitGuard.didQueueRatingForExit) {
      return;
    }

    // 1. Agar user ne rate kar diya hai, toh seedha wapas jao
    if (getBoolAsync(ratedKey, defaultValue: false)) return;

    // 2. Increment Session Count
    int currentCount = getIntAsync(appOpenCountKey, defaultValue: 0);
    currentCount++;
    setValue(appOpenCountKey, currentCount);

    // 3. LOGIC: 3rd session se shuru karein aur har 5 session baad dikhayein
    // Example: 3, 8, 13, 18... session par dikhega
    if (currentCount >= 3 && (currentCount - 3) % 5 == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          Get.dialog(
            const RatingDialog(),
            barrierDismissible: false,
          );
        }
      });
    }
  }
  Future<void> fetchSleepChart(String type) async {
    try {
      isChartLoading.value = true;

      final response = await ProgressApis.getSleepDurationChart(dataType: type);

      // This is the overall average at the top of the card
      averageSleep.value = response.data.averageHours;

      final breakdown = response.data.breakdown;

      // Use the normalized '.value' from our model
      chartValues.value = breakdown.map((e) => e.value).toList();

      chartLabels.value = breakdown.map((e) {
        // For Year view, we keep the full label (e.g. 2026)
        // For others, our model already shortened them (e.g. Mon, Jan)
        return e.label;
      }).toList();

    } catch (e) {
      debugPrint("❌ Sleep chart error: $e");
    } finally {
      isChartLoading.value = false;
    }
  }
  String safeShort(String text) {
    // If it's a number (year like 2026) → return full
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return text;
    }

    // If it's long text → truncate to 3
    if (text.length > 3) {
      return text.substring(0, 3);
    }

    return text;
  }

  @override
  void onClose() {
    _timer?.cancel();

    // Stop animations before disposing to prevent "Ticker active" crashes
    if (animationController.isAnimating) animationController.stop();
    if (horizontalController.isAnimating) horizontalController.stop();

    animationController.dispose();
    horizontalController.dispose();

    // Dispose the fixed extent controller (The wheel picker)
    scrollController.dispose();

    if (screenScrollController.hasClients) {
      screenScrollController.removeListener(_onScrollSafe);
    }
    screenScrollController.dispose();

    super.onClose();
  }
  void loadUserFromPrefs() {
    // 1. Get the standalone token (Most reliable)
    final savedToken = getStringAsync(AppSharedPreferenceKeys.apiToken);

    if (savedToken.isNotEmpty) {
      token.value = savedToken;
      print("✅ Token Loaded Directly: ${token.value}");
    } else {
      print("❌ Token key '${AppSharedPreferenceKeys.apiToken}' is EMPTY in Prefs");
    }

    // 2. Get the User Profile JSON for the Name/Avatar
    final userDataStr = getStringAsync(AppSharedPreferenceKeys.currentUserData);
    if (userDataStr.isNotEmpty) {
      try {
        final userData = SocialLoginResponseData.fromJson(jsonDecode(userDataStr));
        userName.value = userData.name;
      } catch (e) {
        print("❌ Profile JSON Parse Error: $e");
      }
    }
  }

  List<Color> getGradientColors(double progress) {
    // 1. Agar progress 30% se kam hai (0.0 se 0.29) -> Red/Orange
    if (progress < 0.3) {
      return [Colors.red, Colors.orange];
    }

    // 2. Agar progress 60% se kam hai (0.3 se 0.59) -> Orange/Yellow
    if (progress < 0.6) {
      return [Colors.orange, Colors.yellow];
    }

    // 3. Agar progress 100% se kam hai (0.6 se 0.99) -> Blue/Purple (Jo aapka normal theme color hai)
    // 🎯 Aapka 5.55 hours (69%) ab is range mein aayega, toh yahan Green nahi dikhega!
    if (progress < 1.0) {
      return [AppColors.animationStartColor, AppColors.animationEndColor];
    }

    // 4. Jab progress exact 1.0 (8 hours) ya usse upar hogi, tabhi Green/Teal milega!
    return [Colors.green, Colors.teal];
  }

  final List<SleeppediaItem> dashboardSleeppedia = getLocalizedSleeppediaList().take(3).toList();

  final List<Map<String, dynamic>> sleepQuizzes = [
    {
      'title': Get.context?.lang.understandSleepPatterns ?? 'Understand Your Sleep Patterns',
      'subtitle': Get.context?.lang.quickQuestions15 ?? '15 quick questions',
      'image': Assets.imagesSleeppediaQuiz1,
      'description': Get.context?.lang.exploreSleepHabitsDesc ??
          'Explore your sleep habits, daily energy levels, and rest quality through a short assessment.',
    },
    {
      'title': Get.context?.lang.nightBreathingRestCheck ?? 'Night Breathing & Rest Check',
      'subtitle': Get.context?.lang.simpleQuestions12 ?? '12 simple questions',
      'image': Assets.sleeppediaQuiz2,
      'description': Get.context?.lang.identifyBreathingDisturbancesDesc ??
          'Identify possible breathing-related sleep disturbances.',
    },
  ];

// Inside _setupControllers
  void _setupControllers() {
    screenScrollController.addListener(_onScrollSafe);
    // WidgetsBinding.instance.addPostFrameCallback is already good,
    // but ensure you check if the controller is closed before setting values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      final size = MediaQuery.of(Get.context!).size;
      buttonX.value = size.width * 0.8;
      buttonY.value = size.height * 0.65;
    });
  }
  void _initAnimations() {
    animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3)
    )..repeat(reverse: true);

    animation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.linear)
    );

    breathingAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut)
    );

    horizontalController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2)
    );

    horizontalAnimation = Tween<double>(begin: -15.0, end: 10.0).animate(
        CurvedAnimation(parent: horizontalController, curve: Curves.easeInOut)
    );
  }

  void _initTimers() {
    startCountdown();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!isClosed) {
        updateGreeting();
        updateCountdown();
      }
    });
  }

  Future<void> fetchHomePageData() async {
    try {
      // Only show loader if we don't have cached data yet
      if (homeData.value == null) isLoadingHome.value = true;

      final response = await HomeApis.getHomePage();

      if (response != null && response.success && response.data != null) {
        // ✅ 1. Save the entire response to cache
        // Ensure your HomePageResponse has a toJson() method!
        setValue("cached_home_data", jsonEncode(response.toJson()));

        // 2. Update the UI model
        homeData.value = response;

        // 3. Sync all UI variables
        _syncHomeState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            int targetIndex = (homeData.value?.data?.tonightSleepGoal.goalHours.toInt() ?? 8) - 1;
            scrollController.jumpToItem(targetIndex);
          }
        });
      } else {
        countdownText.value =  Get.context?.lang.unableToLoadGoal ?? "Unable to load goal";
      }
    } catch (e) {
      debugPrint("❌ Home Page API Error: $e");
      countdownText.value =  Get.context?.lang.errorLoadingData ?? "Error loading data";
    } finally {
      isLoadingHome.value = false;
    }
  }

  void _syncHomeState() {
    final newData = homeData.value?.data;
    if (newData == null) return;

    // Use distinct checks where possible to prevent UI flicker
    final newSleepHours = newData.sleepSummary.totalSleepHours.toDouble();
    if (lastNightSleepHours.value != newSleepHours) {
      lastNightSleepHours.value = newSleepHours;
    }
    if (homeData.value?.data == null) return;

    final data = homeData.value!.data!;
    final goal = data.tonightSleepGoal;
    final summary = data.sleepSummary;

    sleepStatus.value = data.sleepStatus;
    updateInsightMessage();

    // ✅ 1. Toggle sync
    isEnabled.value = goal.reminderEnable;

    // ✅ 2. Summary & Progress sync
    lastNightSleepHours.value = summary.totalSleepHours.toDouble();
    sleepProgress.value = (summary.progressPercentage / 100).toDouble();

    // ✅ 3. Target Bedtime Sync
    if (goal.targetBedtime.isNotEmpty) {
      bedtime.value = _parseTimeOfDay(goal.targetBedtime);
    }

    // ✅ 4. Goal Wheel Sync
    int newGoal = goal.goalHours.toInt();
    selectedNumber.value = newGoal;

    // Inside _syncHomeState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        int target = goal.goalHours.toInt() - 1;
        if (scrollController.selectedItem != target) {
          scrollController.animateToItem(
            target,
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut, // Gives that organic Gen-Z bounce
          );
        }
      }
    });

    // ✅ 5. Countdown Text sync
    if (goal.hoursUntilBedtime > 0) {
      updateCountdown();
    } else {
      countdownText.value = Get.context?.lang.bedtimeReached ?? "Bedtime reached";
    }
  }
  // Controller ke andar ye helper add karein
  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      // Expected format: "hh:mm a" (e.g., "01:00 AM")
      final format = DateFormat.jm();
      final dateTime = format.parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      debugPrint("❌ Error parsing time: $e");
      return const TimeOfDay(hour: 22, minute: 0); // Default fallback
    }
  }

  void onScroll(double offset) {
    // Only trigger logic if the state actually needs to change
    bool shouldBeDark = offset > 250;

    if (shouldBeDark != isStatusBarDark.value) {
      isStatusBarDark.value = shouldBeDark;
      _updateStatusBar(
          Brightness.light,
          shouldBeDark ? Colors.black : Colors.transparent
      );
    }
  }

  void _updateStatusBar(Brightness brightness, Color color) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: color,
      statusBarIconBrightness: brightness,
    ));
  }

  void _onScrollSafe() {
    if (screenScrollController.hasClients) {
      onScroll(screenScrollController.offset);
    }
  }

  void clear() {
    bedTime.value = null;
    wakeTime.value = null;
    sleepQuality.value = 0;
  }

  void initTodayDate() {
    toDayDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void calculateStars() {
    if (bedTime.value != null && wakeTime.value != null) {
      final bedMinutes = bedTime.value!.hour * 60 + bedTime.value!.minute;
      final wakeMinutes = wakeTime.value!.hour * 60 + wakeTime.value!.minute;
      int diffMinutes = wakeMinutes - bedMinutes;
      if (diffMinutes <= 0) diffMinutes += 24 * 60;
      final diffHours = diffMinutes / 60.0;

      if (diffHours < 5) sleepQuality.value = 1;
      else if (diffHours < 6) sleepQuality.value = 2;
      else if (diffHours < 7) sleepQuality.value = 3;
      else if (diffHours < 8) sleepQuality.value = 4;
      else sleepQuality.value = 5;
    }
  }

  void changeSelectedNumber(int number) => selectedNumber.value = number;

  void startCountdown() => updateCountdown();

  void updateCountdown() {
    final now = DateTime.now();
    final bed = DateTime(now.year, now.month, now.day, bedtime.value.hour, bedtime.value.minute);

    // Kitna time bacha hai sone mein
    Duration diff = bed.isBefore(now)
        ? bed.add(const Duration(days: 1)).difference(now)
        : bed.difference(now);

    final lang = Get.context?.lang;

    // Units and Labels
    final hUnit = lang?.h ?? "h";
    final mUnit = lang?.m ?? "m";
    final untilText = lang?.untilBedtime ?? "until bedtime";
    final goalText = lang?.goal ?? "goal";

    // Banner Text Logic
    // Example: "9h 38m until bedtime (8h goal)"
    countdownText.value =
    "${diff.inHours}$hUnit ${diff.inMinutes.remainder(60)}$mUnit $untilText "
        "(${selectedNumber.value}$hUnit $goalText)";
  }

  Future<void> updateReminderApi(bool newValue) async {
    // 🔥 1. Instant UI Update (Optimistic UI)
    // Isse user ko bina wait kiye turant feedback milega
    isEnabled.value = newValue;

    try {
      // Note: Humne isSavingSettings ko skip kar diya hai taaki loader na dikhe

      // 2. Fetch current settings for latest payload info
      final response = await SettingsApis.fetchUserSettings();

      if (response.success && response.data != null) {
        final current = response.data!;
        String deviceTimezone = await getCurrentTimezone();

        UserSettings requestBody = UserSettings(
          alarmEnabled: current.alarmEnabled,
          alarmTime: _ensureApiFormat(current.alarmTime),
          meridiem: current.meridiem,
          repeatType: current.repeatType,
          repeatDays: current.repeatDays,
          melodyId: current.melodyId,
          snoozeMinutes: current.snoozeMinutes,
          fadeIn: current.fadeIn,
          batteryWarning: current.batteryWorning,
          heartRateTracking: current.heartRateTracking,
          notifications: current.notifications,
          timezone: deviceTimezone,

          // Hum wahi value bhej rahe hain jo user ne toggle ki hai
          sleepReminders: newValue,

          // Existing values maintain rakhein taaki home screen ka time jump na kare
          bedtime: _ensureApiFormat(current.bedtime),
          remindAt: _ensureApiFormat(current.remindAt),
          wakeUpTime: _ensureApiFormat(current.wakeUpTime),
        );

        // 3. PUT call in background
        final updateResponse = await SettingsApis.updateUserSettings(requestBody);

        if (updateResponse.success) {
          // Chupchap refresh karein taaki cache updated rahe
          // false pass karein agar fetchHomePageData mein koi bada loader ho
          fetchHomePageData();
        } else {
          // Agar API fail ho gayi toh wapas purani state pe le jao (Rollback)
          isEnabled.value = !newValue;
          // Get.snackbar("Error", "Sync failed, please try again.");
          Get.snackbar(
              Get.context?.lang.error ?? "Error",
              Get.context?.lang.syncFailedTryAgain ?? "Sync failed, please try again."
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Silent update error: $e");
      // Network error pe wapas purani state
      isEnabled.value = !newValue;
    }
  }
// Helper utility to avoid "Time has wrong format" errors
  String _ensureApiFormat(String? timeStr, {String fallback = "00:00:00"}) {
    if (timeStr == null || timeStr.isEmpty || !timeStr.contains(':')) return fallback;
    List<String> parts = timeStr.split(':');
    String h = parts[0].padLeft(2, '0');
    String m = parts.length > 1 ? parts[1].padLeft(2, '0') : "00";
    return "$h:$m:00";
  }

// Helper function to format TimeOfDay for API
  String formatTimeOfDayToApi(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat("HH:mm:ss").format(dt);
  }
  void toggleMoon() {
    moonAngle.value = isFullMoon.value ? -50 : 50;
    isFullMoon.value = !isFullMoon.value;
  }

  void toggle() => isOn.value = !isOn.value;

  void updateGreeting() {
    final hour = DateTime.now().hour;
    final lang = Get.context?.lang;

    if (hour >= 5 && hour < 12) {
      greeting.value = lang?.goodMorning ?? "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      greeting.value = lang?.goodAfternoon ?? "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      greeting.value = lang?.goodEvening ?? "Good Evening";
    } else {
      greeting.value = lang?.goodNight ?? "Good Night";
    }
  }

  String formatTime(TimeOfDay time) {
    final dt = DateTime(0, 0, 0, time.hour, time.minute);
    return DateFormat("hh:mm a").format(dt);
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  void changeIndex(int index) => selectedIndex.value = index;

  void showRotatingPremiumSheet(BuildContext context) {
    final subController = Get.find<SubscriptionController>();

    if (Platform.isIOS) {
      showPremiumOfferSheet4(context);
      return;
    }

    final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

    premiumClickCount.value++;

    Future<dynamic>? sheetFuture;

    if (hasAlreadySpun) {
      if (premiumClickCount.value == 1) sheetFuture = showPremiumOfferSheet(context);
      else if (premiumClickCount.value == 2) sheetFuture = showPremiumOfferSheet2(context);
      else if (premiumClickCount.value == 3) sheetFuture = showPremiumOfferSheet3(context);
      else {
        sheetFuture = showPremiumOfferSheet6(context);
        premiumClickCount.value = 0;
      }
    } else {
      if (premiumClickCount.value == 1) sheetFuture = showPremiumOfferSheet(context);
      else if (premiumClickCount.value == 2) sheetFuture = showPremiumOfferSheet2(context);
      else {
        sheetFuture = showPremiumOfferSheet3(context);
        premiumClickCount.value = 0;
      }
    }

    sheetFuture?.then((_) {
      subController.checkAndShowRatingAfterPostDelay();
    });
  }

  var filteredItems = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> getLocalizedItems() {
    return [
      {'id': 'white_noise', 'icon': Icons.music_note, 'lang_key': 'white_noise'},
      {'id': 'sleep_aid', 'icon': Icons.bedtime, 'lang_key': 'sleep_aid'},
      {'id': 'premium', 'icon': Icons.star, 'lang_key': 'premium'},
      {'id': 'story', 'icon': Icons.auto_stories_rounded, 'lang_key': 'story'},
      {'id': 'dreambot', 'icon': Icons.mark_unread_chat_alt, 'lang_key': 'dreamBot'},
      {'id': 'breathwork', 'icon': Icons.lens_blur, 'lang_key': 'breathwork'},
    ];
  }


  void updateFilteredItems() {
    final subController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());

    bool isPremium = subController.isPremium.value;
    print("STABLE DEBUG: Running Filter. User Premium: $isPremium");

    List<Map<String, dynamic>> freshItems = getLocalizedItems();
    List<Map<String, dynamic>> newList = [];

    if (isPremium) {
      newList = freshItems.where((item) => item['id'] != 'premium').toList();
    } else {
      newList = freshItems.where((item) => item['id'] != 'story' && item['id'] != 'dreambot').toList();
    }

    filteredItems.assignAll(newList);
    filteredItems.refresh();
  }
}