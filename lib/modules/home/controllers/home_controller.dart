import 'dart:async';
import 'dart:convert';

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
import '../../../widgets/rating_dialog.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../../widgets/timezone.dart';
import '../../login/model/google_social_login_model.dart';
import '../../profile/model/UserSettings.dart';
import '../../sleep_info/model/sleeppedia_item.dart';
import '../../sleep_info/widget/sleeppedia_data.dart';
import '../../sleep_sound/model/sound_sub_category_model.dart';
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
  // final RxList<Artist> profiles = <Artist>[].obs;

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
    // fetchArtists();
  }

  // @override
  // void onReady() {
  //   super.onReady();
  //   // Login se jo argument bheja tha use check karein
  //   if (Get.arguments != null && Get.arguments['show_paywall'] == true) {
  //
  //     // Thoda sa delay (100-200ms) dena behtar hai taaki UI settle ho jaye
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       final subController = Get.find<SubscriptionController>();
  //
  //       bool hasSpun = subController.spinInfo.value?.alreadySpun ?? false;
  //
  //       if (hasSpun) {
  //         showPremiumOfferSheet6(Get.context!);
  //       } else {
  //         showPremiumOfferSheet4(Get.context!);
  //       }
  //
  //       // Argument ko clear kar dein taaki tab change par dobara sheet na khule
  //       Get.arguments['show_paywall'] = false;
  //     });
  //   }
  //   horizontalController.forward(from: 0.0);
  // }

  // @override
  // void onReady() {
  //   super.onReady();
  //
  //   // 1. UI Animations start karein
  //   horizontalController.forward(from: 0.0);
  //
  //   // 2. Logic Check: Pehle Paywall ko priority dein, agar wo nahi hai toh Rating check karein
  //   if (Get.arguments != null && Get.arguments['show_paywall'] == true) {
  //     _showInitialPaywall();
  //   } else {
  //     // Agar Paywall nahi dikhana, tabhi Rating mangne ki koshish karein
  //     _checkAndShowRatingDialog();
  //   }
  // }
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
    // 3. Priority 2: Auto-Show Premium (Agar user premium nahi hai toh)
    else if (!subController.isPremium.value) {
      // Thoda delay taaki screen load hone ke baad smooth popup aaye
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) {
          showRotatingPremiumSheet(Get.context!);
        }
      });
    }
    // 4. Priority 3: Rating Dialog (Sirf Premium users ya tab jab Paywall skip ho jaye)
    else {
      _checkAndShowRatingDialog();
    }
  }
  // Helper 1: Paywall Handler
  void _showInitialPaywall() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (isClosed) return; // Safety check

      final subController = Get.find<SubscriptionController>();
      // Humne pehle hi discuss kiya tha ki alreadySpun check karna hai
      bool hasSpun = subController.spinInfo.value?.alreadySpun ?? false;

      if (hasSpun) {
        showPremiumOfferSheet6(Get.context!);
      } else {
        showPremiumOfferSheet4(Get.context!);
      }

      // Argument clear karein taaki loop na bane
      Get.arguments['show_paywall'] = false;
    });
  }

// Helper 2: Rating Handler (Session Count Logic)
  void _checkAndShowRatingDialog() {
    // Key names (nb_utils use ho raha hai)
    const String appOpenCountKey = "app_open_count";
    const String ratedKey = "user_has_rated";

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
  // @override
  // void onClose() {
  //   if (screenScrollController.hasClients) {
  //     screenScrollController.removeListener(_onScrollSafe);
  //   }
  //   screenScrollController.dispose();
  //   animationController.dispose();
  //   horizontalController.dispose();
  //   _timer.cancel();
  //   super.onClose();
  // }
  // @override
  // void onClose() {
  //   // Always remove listener BEFORE disposing
  //   if (screenScrollController.hasClients) {
  //     screenScrollController.removeListener(_onScrollSafe);
  //   }
  //
  //   // Cancel timer before disposing other things
  //   _timer?.cancel();
  //
  //   screenScrollController.dispose();
  //   animationController.dispose();
  //   horizontalController.dispose();
  //   super.onClose();
  // }
  // @override
  // void onClose() {
  //   // 2. Stop timers and remove listeners
  //   _timer?.cancel();
  //   if (screenScrollController.hasClients) {
  //     screenScrollController.removeListener(_onScrollSafe);
  //   }
  //
  //   // 3. STOP animations before disposing
  //   // This prevents the 'Ticker' from trying to update a dead controller
  //   animationController.stop();
  //
  //   // 4. Dispose in order
  //   screenScrollController.dispose();
  //   animationController.dispose();
  //   horizontalController.dispose();
  //
  //   // If you have a PageController for that PageView:
  //   // pageController.dispose();
  //
  //   super.onClose();
  // }
  // @override
  // void onClose() {
  //   _timer?.cancel();
  //
  //   // Explicitly check if controllers were initialized before disposing
  //   if (Get.isRegistered<HomeController>()) {
  //     animationController.stop();
  //     animationController.dispose();
  //     horizontalController.stop();
  //     horizontalController.dispose();
  //   }
  //
  //   if (screenScrollController.hasClients) {
  //     screenScrollController.removeListener(_onScrollSafe);
  //   }
  //   screenScrollController.dispose();
  //   scrollController.dispose(); // You forgot to dispose the FixedExtentScrollController!
  //
  //   super.onClose();
  // }
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
    if (progress < 0.3) return [Colors.red, Colors.orange];
    if (progress < 0.5) return [Colors.orange, Colors.yellow];
    if (progress < 0.8) return [AppColors.animationStartColor, AppColors.animationEndColor];
    return [Colors.green, Colors.teal];
  }

  // final List<SleeppediaItem> dashboardSleeppedia = sleeppediaList.take(3).toList();
  final List<SleeppediaItem> dashboardSleeppedia = getLocalizedSleeppediaList().take(3).toList();
  // final List<Map<String, dynamic>> sleeppedia = [
  //   {'title': 'Insomnia', 'image': Assets.sleeppediaInsomania},
  //   {'title': 'Hypersomnia', 'image': Assets.sleeppediaHypersomnia1},
  //   {'title': 'Snoring', 'image': Assets.sleeppediaSnoring},
  // ];
  // final sleepQuizzes = [
  //   {'title': 'Catch Your Z\'s: Unpacking Your Sleep', 'image': Assets.homeBackgroundMountains},
  //   {'title': 'Breathing abnormal pauses while sleeping...', 'image': Assets.homeBackgroundMountains},
  // ];
  // final List<Map<String, dynamic>> sleepQuizzes = [
  //   {
  //     'title': 'Understand Your Sleep Patterns',
  //     'subtitle': '15 quick questions',
  //     'image': Assets.imagesSleeppediaQuiz1,
  //     'description':
  //     'Explore your sleep habits, daily energy levels, and rest quality through a short assessment.',
  //   },
  //   {
  //     'title': 'Night Breathing & Rest Check',
  //     'subtitle': '12 simple questions',
  //     'image': Assets.sleeppediaQuiz2,
  //     'description':
  //     'Identify possible breathing-related sleep disturbances.',
  //   },
  // ];
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
  // ---------------------------------------------------------------------------
  // 5. PRIVATE INITIALIZERS
  // ---------------------------------------------------------------------------
  // void _setupControllers() {
  //   screenScrollController.addListener(_onScrollSafe);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final size = MediaQuery.of(Get.context!).size;
  //     buttonX.value = size.width * 0.8;
  //     buttonY.value = size.height * 0.65;
  //   });
  // }
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

  // ---------------------------------------------------------------------------
  // 6. API METHODS
  // ---------------------------------------------------------------------------

  // Future<void> fetchHomePageData() async {
  //   try {
  //     isLoadingHome.value = true;
  //     final response = await HomeApis.getHomePage();
  //
  //     if (response != null && response.success && response.data != null) {
  //       homeData.value = response;
  //       updateInsightMessage();
  //       final summary = response.data!.sleepSummary;
  //       // .toDouble() ensures safety even if API returns int 0 instead of 0.0
  //       lastNightSleepHours.value = summary.totalSleepHours.toDouble();
  //       sleepProgress.value = (summary.progressPercentage / 100).toDouble();
  //
  //       final goal = response.data!.tonightSleepGoal;
  //
  //       // Safe check for the countdown text
  //       if (goal.hoursUntilBedtime > 0) {
  //         countdownText.value = "${goal.hoursUntilBedtime.toInt()}h until Bedtime";
  //       } else {
  //         countdownText.value = "Bedtime reached";
  //       }
  //     } else {
  //       countdownText.value = "Unable to load goal";
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Home Page API Error: $e");
  //     countdownText.value = "Error loading data";
  //   } finally {
  //     isLoadingHome.value = false;
  //   }
  // }
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
  // void _syncHomeState() {
  //   if (homeData.value?.data == null) return;
  //
  //   final data = homeData.value!.data!;
  //   sleepStatus.value = data.sleepStatus;
  //   // Update Insight (the lightbulb msg)
  //   updateInsightMessage();
  //   isEnabled.value = data.tonightSleepGoal.reminderEnable;
  //   // Update Summary
  //   lastNightSleepHours.value = data.sleepSummary.totalSleepHours.toDouble();
  //   sleepProgress.value = (data.sleepSummary.progressPercentage / 100).toDouble();
  //
  //   // Update Countdown
  //   final goal = data.tonightSleepGoal;
  //   if (goal.hoursUntilBedtime > 0) {
  //     countdownText.value = "${goal.hoursUntilBedtime.toInt()}h until Bedtime";
  //   } else {
  //     countdownText.value = "Bedtime reached";
  //   }
  // }
  // void _syncHomeState() {
  //   if (homeData.value?.data == null) return;
  //
  //   final data = homeData.value!.data!;
  //   final goal = data.tonightSleepGoal;
  //   final summary = data.sleepSummary;
  //
  //   sleepStatus.value = data.sleepStatus;
  //   updateInsightMessage();
  //
  //   // ✅ 1. Toggle sync
  //   isEnabled.value = goal.reminderEnable;
  //
  //   // ✅ 2. Summary & Progress sync
  //   lastNightSleepHours.value = summary.totalSleepHours.toDouble();
  //   sleepProgress.value = (summary.progressPercentage / 100).toDouble();
  //
  //   // ✅ 3. Target Bedtime & Goal sync (IMPORTANT)
  //   // API se "01:00 AM" aayega, use parse karke bedtime Rx variable mein daalna hoga
  //   if (goal.targetBedtime.isNotEmpty) {
  //     bedtime.value = _parseTimeOfDay(goal.targetBedtime);
  //   }
  //   if (goal.reminderEnable != null) {
  //     isEnabled.value = goal.reminderEnable;
  //   }
  //   // Goal hours (Jo 11h goal dikh raha hai)
  //   selectedNumber.value = goal.goalHours.toInt();
  //   int newGoal = goal.goalHours.toInt();
  //   selectedNumber.value = newGoal;
  //   if (scrollController.hasClients) {
  //     // animateToItem use karein taaki smooth feel aaye
  //     scrollController.animateToItem(
  //         newGoal - 1,
  //         duration: const Duration(milliseconds: 500),
  //         curve: Curves.easeInOut
  //     );}
  //   // ✅ 4. Countdown Text sync (API se direct fetch karein agar available ho)
  //   if (goal.hoursUntilBedtime > 0) {
  //     updateCountdown(); // Isse aapka custom banner refresh hoga
  //   } else {
  //     countdownText.value = "Bedtime reached";
  //   }
  // }
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

    // 🔥 THE STABILITY FIX: Use addPostFrameCallback
    // Isse guarantee milti hai ki UI render hone ke BAAD hi wheel ghumega
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (scrollController.hasClients) {
    //     scrollController.animateToItem(
    //       newGoal - 1,
    //       duration: const Duration(milliseconds: 600), // Thoda sa slow for premium feel
    //       curve: Curves.easeOutCubic, // Better smoothness
    //     );
    //   }
    // });
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
  // ---------------------------------------------------------------------------
  // 7. PUBLIC BUSINESS LOGIC / HELPERS
  // ---------------------------------------------------------------------------
  // void onScroll(double offset) {
  //   if (offset > 250 && !isStatusBarDark.value) {
  //     isStatusBarDark.value = true;
  //     _updateStatusBar(Brightness.light, Colors.black);
  //   } else if (offset <= 250 && isStatusBarDark.value) {
  //     isStatusBarDark.value = false;
  //     _updateStatusBar(Brightness.light, Colors.transparent);
  //   }
  // }
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

  // void updateCountdown() {
  //   final now = DateTime.now();
  //   final bed = DateTime(now.year, now.month, now.day, bedtime.value.hour, bedtime.value.minute);
  //   Duration diff = bed.isBefore(now) ? bed.add(const Duration(days: 1)).difference(now) : bed.difference(now);
  //
  //   countdownText.value = "${diff.inHours}${Get.context!.lang.h} ${diff.inMinutes.remainder(60)}${Get.context!.lang.m} ${Get.context!.lang.untilBedtime}";
  // }

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
  // void updateCountdown() {
  //   final now = DateTime.now();
  //   final bed = DateTime(now.year, now.month, now.day, bedtime.value.hour, bedtime.value.minute);
  //
  //   // Kitna time bacha hai sone mein
  //   Duration diff = bed.isBefore(now) ? bed.add(const Duration(days: 1)).difference(now) : bed.difference(now);
  //
  //   // Banner Text: Isme Bedtime aur Goal dono dikhao
  //   // Example: "9h 38m until bedtime (8h goal)"
  //   countdownText.value =
  //   "${diff.inHours}${Get.context!.lang.h} ${diff.inMinutes.remainder(60)}${Get.context!.lang.m} "
  //       "${Get.context!.lang.untilBedtime} ";
  //       // "(${selectedNumber.value}${Get.context!.lang.h} goal)";
  // }
// HomeController.dart
//   Future<void> updateReminderApi(bool newValue) async {
//     try {
//       isSavingSettings.value = true;
//       final response = await SettingsApis.fetchUserSettings(); // 1. Fresh data lo
//
//       if (response.success && response.data != null) {
//         final current = response.data!;
//         String deviceTimezone = await getCurrentTimezone();
//
//         UserSettings requestBody = UserSettings(
//           alarmEnabled: current.alarmEnabled,
//           alarmTime: _ensureApiFormat(current.alarmTime),
//           meridiem: current.meridiem,
//           repeatType: current.repeatType,
//           repeatDays: current.repeatDays,
//           melodyId: current.melodyId,
//           snoozeMinutes: current.snoozeMinutes,
//           fadeIn: current.fadeIn,
//           batteryWarning: current.batteryWorning,
//           heartRateTracking: current.heartRateTracking,
//           notifications: current.notifications,
//           timezone: deviceTimezone,
//
//           // 🔥 FIX 1: Toggle status update karo
//           sleepReminders: newValue,
//
//           // 🔥 FIX 2: Bedtime controller waali nahi, balki jo backend pe hai wahi rakho
//           // Kyunki ye toggle sirf reminder ON/OFF karne ke liye hai
//           bedtime: _ensureApiFormat(current.bedtime),
//
//           // Reminder time profile waala hi rehne do
//           remindAt: _ensureApiFormat(current.remindAt),
//           wakeUpTime: _ensureApiFormat(current.wakeUpTime),
//         );
//
//         final updateResponse = await SettingsApis.updateUserSettings(requestBody);
//         if (updateResponse.success) {
//           isEnabled.value = newValue;
//           fetchHomePageData();
//         }
//       }
//     } catch (e) {
//       isEnabled.value = !newValue;
//     } finally {
//       isSavingSettings.value = false;
//     }
//   }
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

  // void directionLeftRight() {
  //   if (isDirection.value) direction.value = 10;
  //   isDirection.value = !isDirection.value;
  // }

  void toggle() => isOn.value = !isOn.value;

  // void updateGreeting() {
  //   final hour = DateTime.now().hour;
  //   if (hour >= 5 && hour < 12) greeting.value = Get.context!.lang.goodMorning;
  //   else if (hour >= 12 && hour < 17) greeting.value = Get.context!.lang.goodAfternoon;
  //   else if (hour >= 17 && hour < 21) greeting.value = Get.context!.lang.goodEvening;
  //   else greeting.value = Get.context!.lang.goodNight;
  // }
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
  // RxInt premiumClickCount = 0.obs;

  // void showRotatingPremiumSheet(BuildContext context) {
  //   premiumClickCount.value++;
  //   // showPremiumOfferSheet4(context);
  //   // Logic to rotate 1 -> 2 -> 3 and reset
  //   if (premiumClickCount.value == 1) {
  //     showPremiumOfferSheet(context);
  //     // showPremiumOfferSheet5(context);
  //     // showPremiumOfferSheet6(context);
  //     // showPremiumOfferSheet4(context);
  //   } else if (premiumClickCount.value == 2) {
  //     showPremiumOfferSheet2(context);
  //   } else {
  //     showPremiumOfferSheet3(context);
  //     premiumClickCount.value = 0; // Reset after the 3rd one
  //   }
  // }
  // void showRotatingPremiumSheet(BuildContext context) {
  //   final subController = Get.find<SubscriptionController>();
  //   final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;
  //
  //   premiumClickCount.value++;
  //
  //   // --- Logic for 4 Sheets Rotation (If Spun) ---
  //   if (hasAlreadySpun) {
  //     if (premiumClickCount.value == 1) {
  //       showPremiumOfferSheet(context);
  //     } else if (premiumClickCount.value == 2) {
  //       showPremiumOfferSheet2(context);
  //     } else if (premiumClickCount.value == 3) {
  //       showPremiumOfferSheet3(context);
  //     } else {
  //       // 🎯 4th Click par Discounted Sheet 6 dikhao
  //       showPremiumOfferSheet6(context);
  //       premiumClickCount.value = 0; // Reset after 4th
  //     }
  //   }
  //   // --- Logic for 3 Sheets Rotation (Default/Not Spun) ---
  //   else {
  //     if (premiumClickCount.value == 1) {
  //       showPremiumOfferSheet(context);
  //     } else if (premiumClickCount.value == 2) {
  //       showPremiumOfferSheet2(context);
  //     } else {
  //       showPremiumOfferSheet3(context);
  //       premiumClickCount.value = 0; // Reset after 3rd
  //     }
  //   }
  // }
  void showRotatingPremiumSheet(BuildContext context) {
    final subController = Get.find<SubscriptionController>();
    final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

    premiumClickCount.value++;

    // Future<dynamic> store karein taaki hum .then() use kar sakein
    Future<dynamic>? sheetFuture;

    if (hasAlreadySpun) {
      // 4 Sheets Rotation (1, 2, 3, 6)
      if (premiumClickCount.value == 1) sheetFuture = showPremiumOfferSheet(context);
      else if (premiumClickCount.value == 2) sheetFuture = showPremiumOfferSheet2(context);
      else if (premiumClickCount.value == 3) sheetFuture = showPremiumOfferSheet3(context);
      else {
        sheetFuture = showPremiumOfferSheet6(context);
        premiumClickCount.value = 0;
      }
    } else {
      // 3 Sheets Rotation (1, 2, 3)
      if (premiumClickCount.value == 1) sheetFuture = showPremiumOfferSheet(context);
      else if (premiumClickCount.value == 2) sheetFuture = showPremiumOfferSheet2(context);
      else {
        sheetFuture = showPremiumOfferSheet3(context);
        premiumClickCount.value = 0;
      }
    }

    // ✅ Jab sheet band ho jaye (User cancels), tab rating check karein
    sheetFuture?.then((_) {
      // Thoda delay taaki sheet poori tarah band ho jaye
      subController.checkAndShowRatingAfterPostDelay();
    });
  }
  // ---------------------------------------------------------------------------
  // 8. STATIC DATA LISTS
  // ---------------------------------------------------------------------------

// HomeController ke andar

// HomeController.dart
  // HomeController.dart mein filteredItems ko aise update karein:
  // final List<Map<String, dynamic>> allItems = [
  //   {'id': 'white_noise', 'icon': Icons.music_note, 'label': Get.context!.lang.whiteNoise},
  //   {'id': 'sleep_aid', 'icon': Icons.bedtime, 'label': Get.context!.lang.sleepAid},
  //   {'id': 'premium', 'icon': Icons.star, 'label': Get.context!.lang.premium}, // ✅ Check ID: 'premium'
  //   {'id': 'story', 'icon': Icons.auto_stories_rounded, 'label': "Story"}, // ✅ Naya Item
  //   {'id': 'dreambot', 'icon': Icons.mark_unread_chat_alt, 'label': Get.context!.lang.dreamBot},
  //   {'id': 'breathwork', 'icon': Icons.lens_blur, 'label': Get.context!.lang.breathwork},
  // ];
  final List<Map<String, dynamic>> allItems = [
    {'id': 'white_noise', 'icon': Icons.music_note, 'label': Get.context?.lang.whiteNoise ?? "White Noise"},
    {'id': 'sleep_aid', 'icon': Icons.bedtime, 'label': Get.context?.lang.sleepAid ?? "Sleep Aid"},
    {'id': 'premium', 'icon': Icons.star, 'label': Get.context?.lang.premium ?? "Premium"},
    {'id': 'story', 'icon': Icons.auto_stories_rounded, 'label': Get.context?.lang.story ?? "Story"}, // ✅ Localized
    {'id': 'dreambot', 'icon': Icons.mark_unread_chat_alt, 'label': Get.context?.lang.dreamBot ?? "DreamBot"},
    {'id': 'breathwork', 'icon': Icons.lens_blur, 'label': Get.context?.lang.breathwork ?? "Breathwork"},
  ];

  // 2. Ek reactive list banayein UI ke liye
  var filteredItems = <Map<String, dynamic>>[].obs;
  void updateFilteredItems() {
    final subController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());

    bool isPremium = subController.isPremium.value;
    print("STABLE DEBUG: Running Filter. User Premium: $isPremium");

    List<Map<String, dynamic>> newList = [];

    if (isPremium) {
      // ✅ Premium hai: Premium hatao, Story rakho
      newList = allItems.where((item) => item['id'] != 'premium').toList();
    } else {
      // ❌ Free hai: Premium rakho, Story hatao
      newList = allItems.where((item) => item['id'] != 'story').toList();
    }

    filteredItems.assignAll(newList);
  }
  // void updateFilteredItems() {
  //   final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());
  //   print("STABLE DEBUG: Running Filter. User Premium: ${subController.isPremium.value}");
  //
  //   if (subController.isPremium.value == true) {
  //     // strict check using 'id'
  //     final newList = allItems.where((item) => item['id'] != 'premium').toList();
  //     filteredItems.assignAll(newList);
  //   } else {
  //     filteredItems.assignAll(allItems);
  //   }}
/// Payment
}