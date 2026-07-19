
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../widgets/ai_consent_dialog.dart';
import '../model/AIInsightsResponse.dart';
import '../model/SnoringIntensityResponse.dart';
import '../model/achievement_badges_response.dart';
import '../model/dream_list_response.dart';
import '../model/recommendations_response.dart';
import '../model/sleep_audio_response.dart';
import '../model/sleep_calendar_response.dart';
import '../model/sleep_quality_response.dart';
import '../model/sleep_stages_response.dart';
import '../views/progress_view.dart';

class ProgressController extends GetxController with GetTickerProviderStateMixin {
  bool _isInitialLoad = true;
  // --- 1. Global & Tab States ---
  var selectedTab = "Week".obs;
  var isLoading = false.obs; // Used for Snoring loading

  // --- 2. Module Loading States ---
  RxBool isChartLoading = false.obs;
  RxBool isConsistencyLoading = false.obs;
  RxBool isInsightsLoading = false.obs;

  RxBool isLoadingBadges = false.obs;
  RxBool isLoadingDreams = false.obs;
  RxBool isLoadingAudio = false.obs;

  // --- 3. Sleep Duration Data ---
  RxDouble averageSleep = 0.0.obs;
  RxList<double> chartValues = <double>[].obs;
  RxList<String> chartLabels = <String>[].obs;

  // --- 4. Sleep Consistency Data ---
  RxDouble bedtimeRegularity = 0.0.obs;
  RxDouble wakeTimePattern = 0.0.obs;
  RxString avgBedtime = "".obs;
  RxString avgWakeTime = "".obs;
  RxString sleepWindowVariance = "--".obs;

  // --- 5. Key Insights Data ---
  RxDouble consistencyScore = 0.0.obs;
  RxDouble avgSleepHours = 0.0.obs;
  RxDouble sleepQualityScore = 0.0.obs;
  RxInt sleepStreakDays = 0.obs;

  RxDouble sleepTrend = 0.0.obs;
  RxDouble qualityTrend = 0.0.obs;
  RxDouble consistencyTrend = 0.0.obs;

  // --- 6. Snoring Intensity Data ---
  var snoreVisible = false.obs;
  var snoreChartData = <SnorePoint>[].obs;

  // ---  Sleep Quality ---
  RxList<SleepQualityPoint> sleepQualityData = <SleepQualityPoint>[].obs;
  RxBool isQualityLoading = false.obs;
// Today's Quality Variables
  RxDouble todaySleepScore = 0.0.obs;
  RxDouble todayDurationScore = 0.0.obs;
  RxDouble todayEnvScore = 0.0.obs;
  RxDouble todayPhasesScore = 0.0.obs;
  RxDouble durationHours = 0.0.obs;
  RxString todayTimeInBed = "0h 0m".obs;
  RxString todayTimeAsleep = "0m".obs;
  // ---  Sleep Stages ---
  RxBool isStagesLoading = false.obs;
  var sleepSummary = Rxn<SleepStagesSummary>();
  RxList<SleepInterval> sleepIntervals = <SleepInterval>[].obs; // Replaces dynamicSleepStages
  RxList<String> hourLabels = <String>[].obs;

  // --- 7. Achievements & Dreams ---
  var achievementBadges = Rxn<AchievementData>();
  var achiveData = 0.obs;
  RxList<DreamData> myDreamsList = <DreamData>[].obs;

  // --- 7. Achievements & Dreams ---
  RxList<RecommendationItem> recommendationList = <RecommendationItem>[].obs;
  RxBool isRecLoading = false.obs;

  // --- 8. Audio & Recordings ---
  final AudioPlayer _player = AudioPlayer();
  final RxString playingUrl = "".obs;
  final RxBool isPlaying = false.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  // RxList<AudioCategoryData> categories = <AudioCategoryData>[].obs;
  RxList<RecordingCategory> categories = <RecordingCategory>[].obs;

  // --- 9. Animations & Stages ---
  late AnimationController sleepStageController;
  late AnimationController snoreController;
  late AnimationController breathingController;
  RxBool sleepStageVisible = false.obs;
  RxBool breathingVisible = false.obs;
  RxList<SleepStage> sleepStages = <SleepStage>[].obs;
// Controller ke andar
  RxString dateLabel = "Today".obs;

  RxList<CalendarMonth> calendarData = <CalendarMonth>[].obs;
  RxBool isCalendarLoading = false.obs;


  //  ProgressController
  // RxList<AIInsightsResponse> aiInsightsList = <AIInsightsResponse>[].obs; // Use your model's Insight class
  // RxBool isAIInsightsLoading = false.obs;
  RxList<InsightItem> aiInsightsList = <InsightItem>[].obs;
  RxBool isAIInsightsLoading = false.obs;
  var selectedBarIndex = (-1).obs;
  // --- Global State ---
  // 🟢 NEW: Store the exact date being viewed (defaults to today)
  var activeDate = DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------


  @override
  void onInit() {
    super.onInit();
    _initAudioListeners();
    _initAnimationControllers();

    // Just set the value. Do NOT call loadAllData() here if
    // you are going to call changeTab right after.
    selectedTab.value = "Today";

    // Call changeTab once. This will act as your initial data fetch.
    changeTab("Today");
    fetchSleepCalendar();
  }

  void _initAudioListeners() {
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        playingUrl.value = "";
        currentPosition.value = Duration.zero;
      }
    });
    _player.positionStream.listen((p) => currentPosition.value = p);
    _player.durationStream.listen((d) => totalDuration.value = d ?? Duration.zero);
  }

  void _initAnimationControllers() {
    sleepStageController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    snoreController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    _player.dispose();
    sleepStageController.dispose();
    snoreController.dispose();
    breathingController.dispose();
    super.onClose();
  }

  Future<void> loadAllData() async {
    String type;
    String? dateToFetch;

    // Determine type and date based on current tab state
    if (selectedTab.value == "Today") {
      type = "today";
      dateToFetch = activeDate.value; // 🟢 Use the saved date!
    } else if (selectedTab.value == "Week") {
      type = "weekly";
      dateToFetch = null; // Weekly doesn't need a specific day
    } else {
      type = "monthly";
      dateToFetch = null; // Monthly doesn't need a specific day
    }

    // Pass the correct type and date to all APIs
    await Future.wait([
      fetchSleepChart(type),
      fetchSleepConsistency(type, date: dateToFetch),
      getSnoringData(type, date: dateToFetch),
      fetchKeyInsights(type, date: dateToFetch),
      fetchSleepQuality(type, date: dateToFetch),
      fetchAIInsights(type, date: dateToFetch),
      fetchRecommendations(type, date: dateToFetch),
      fetchAchievementBadges(type, date: dateToFetch),
      fetchSleepStages(type, date: dateToFetch),

      // Usually these don't depend on the tab, but you can update if needed
      fetchSleepAudio(type, date: dateToFetch),
      fetchMyDreams(),
    ]);
  }
  Future refreshAllData() async {
    await loadAllData();
  }

  void onDateSelected(String formattedDate) {
    // 1. Update UI state
    selectedTab.value = "Today";
    activeDate.value = formattedDate; // 🟢 Save the date!
    dateLabel.value = DateFormat('MMM dd, yyyy').format(DateTime.parse(formattedDate));

    // 2. Fetch specific date
    fetchSpecificNightData(formattedDate);
  }

  void changeTab(String tab, {String? targetDate}) {
    String normalizedTab = tab.toLowerCase();
    selectedTab.value = tab;

    String type;
    if (normalizedTab == "today") {
      type = "today";
      // 🟢 Update activeDate based on targetDate or fallback to actual today
      activeDate.value = targetDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (targetDate != null) {
        DateTime parsed = DateTime.parse(targetDate);
        dateLabel.value = DateFormat('MMM dd, yyyy').format(parsed);
      } else {
        dateLabel.value = "Today";
      }
    } else if (normalizedTab == "week") {
      type = "weekly";
    } else if (normalizedTab == "month") {
      type = "monthly";
    } else {
      type = "today";
    }

    _fetchTabSpecificData(type, customDate: activeDate.value);
  }

  Future<void> _fetchTabSpecificData(String type, {String? customDate}) async {
    // Use customDate if provided (from calendar), otherwise use actual today's date
    String dateToFetch = customDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    isChartLoading.value = true;
    isQualityLoading.value = true;
    isInsightsLoading.value = true;
    isAIInsightsLoading.value = true;
    isStagesLoading.value = true;
    await Future.wait([
      fetchSleepChart(type),
      fetchSleepConsistency(type),
      getSnoringData(type),
      fetchKeyInsights(type),
      fetchSleepQuality(type),
      fetchAIInsights(type),
      fetchRecommendations(type),
      fetchAchievementBadges(type),
      fetchSleepAudio(type),
      // Pass the specific date to the Sleep Stages API
      fetchSleepStages(type, date: type == "today" ? dateToFetch : null),

      if (_isInitialLoad) ...[

        fetchMyDreams(),
      ]
    ]);

    _isInitialLoad = false;
  }

  Future<void> fetchSpecificNightData(String date) async {
    // Set loading states
    isStagesLoading.value = true;
    isQualityLoading.value = true;
    isLoading.value = true; // snoring loading

    try {
      // We use "today" as the dataType because we want the 24h view for a specific date
      await Future.wait([
        fetchSleepStages("today", date: date),
        fetchSleepQuality("today", date: date),
        getSnoringData("today", date: date),
        fetchKeyInsights("today", date: date),
        fetchSleepConsistency("today", date: date),
        fetchAIInsights("today", date: date),
        fetchRecommendations("today", date: date),
        fetchAchievementBadges("today", date: date),
        fetchSleepAudio("today", date: date),
      ]);

    } catch (e) {
      debugPrint("Error fetching historical date: $e");
    } finally {
      isStagesLoading.value = false;
      isQualityLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> fetchAIInsights(String type, {String? date}) async {
    // 🔒 Apple 5.1.1(i) / 5.1.2(i): sleep data is never sent to a third-party AI
    // without user consent. Consent is granted via the DreamBot dialog or Settings.
    if (!hasAiConsent()) {
      aiInsightsList.clear();
      return;
    }

    try {
      isAIInsightsLoading.value = true;

      // API correctly appends ?data_type=$type and &date=$date
      final response = await ProgressApis.getAIInsights(dataType: type, date: date);

      if (response.success && response.data != null) {
        aiInsightsList.assignAll(response.data!.insights);
      } else {
        aiInsightsList.clear();
      }
    } catch (e) {
      debugPrint("❌ AI Insights Error: $e");
      aiInsightsList.clear();
    } finally {
      isAIInsightsLoading.value = false;
    }
  }

  Future<void> fetchSleepCalendar() async {
    try {
      isCalendarLoading.value = true;
      String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      // Replace with your actual API service call
      final response = await ProgressApis.getSleepCalendar(month: currentMonth);

      if (response.success) {
        calendarData.assignAll(response.months);
      }
    } catch (e) {
      debugPrint("❌ Calendar Error: $e");
    } finally {
      isCalendarLoading.value = false;
    }
  }
  Future<void> fetchSleepChart(String type) async {
    try {
      isChartLoading.value = true;
      final response = await ProgressApis.getSleepDurationChart(dataType: type);
      averageSleep.value = response.data.averageHours;
      chartValues.value = response.data.breakdown.map((e) => e.value).toList();
      chartLabels.value = response.data.breakdown.map((e) => e.label).toList();
    } catch (e) {
      debugPrint("❌ Sleep chart error: $e");
    } finally {
      isChartLoading.value = false;
    }
  }

  Future<void> fetchSleepConsistency(String type,{String? date}) async {
    try {
      isConsistencyLoading.value = true;
      final response = await ProgressApis.getSleepConsistency(dataType: type, date: date);
      bedtimeRegularity.value = response.data.bedtimeRegularity;
      wakeTimePattern.value = response.data.waketimePattern;
      avgBedtime.value = (response.data.averageBedTime == null || response.data.averageBedTime == "null") ? "--" : response.data.averageBedTime!;
      avgWakeTime.value = (response.data.averageWakeTime == null || response.data.averageWakeTime == "null") ? "--" : response.data.averageWakeTime!;
      sleepWindowVariance.value = response.data.sleepWindowVariance;
    } catch (e) {
      debugPrint("❌ Consistency error: $e");
    } finally {
      isConsistencyLoading.value = false;
    }
  }

  Future<void> getSnoringData(String type,{String? date}) async {
    try {
      isLoading.value = true;
      final response = await ProgressApis.getSnoringIntensity(dataType: type, date: date);
      if (response.success == true && response.data?.breakdown != null) {
        snoreChartData.value = response.data!.breakdown!.map((item) {
          return SnorePoint(
            time: item.label ?? "--",
            intensity: (item.avgIntensityPct ?? 0).round(),
            duration: item.totalSeconds ?? 0,
            frequency: 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("❌ Snoring Error: $e");
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> fetchKeyInsights(String type,{String? date}) async {
    try {
      isInsightsLoading.value = true;
      final response = await ProgressApis.getKeyInsights(dataType: type, date: date);

      avgSleepHours.value = response.data.averageSleepHours;
      sleepTrend.value = response.data.sleepDurationTrend;

      sleepQualityScore.value = response.data.sleepQualityScore;
      qualityTrend.value = response.data.sleepQualityTrend;

      sleepStreakDays.value = response.data.sleepStreakDays.toInt();

      consistencyScore.value = response.data.consistencyScore;
      consistencyTrend.value = response.data.consistencyTrend;

    } catch (e) {
      debugPrint("❌ Insights error: $e");
    } finally {
      isInsightsLoading.value = false;
    }
  }
  Future<void> fetchAchievementBadges(String type,{String? date}) async {
    try {
      isLoadingBadges.value = true;
      final response = await ProgressApis.getAchievementBadges(dataType: type, date: date);
      if (response.success && response.data != null) {
        achievementBadges.value = response.data;

        // This will now correctly use the value from 'sleepable_with_you_days'
        achiveData.value = response.data!.sleepableWithYouCount;
      }
    } catch (e) {
      debugPrint("❌ Badges error: $e");
    } finally {
      isLoadingBadges.value = false;
    }
  }

  Future<void> fetchSleepQuality(String type, {String? date}) async {
    try {
      isQualityLoading.value = true;

      // API call with date support
      final response = await ProgressApis.getSleepQuality(dataType: type, date: date);

      if (response.success) {
        final wrapper = response.data;

        // 1. Assign chart data (Ab ye automatically 'breakdown' ya 'hourly' utha lega)
        sleepQualityData.assignAll(wrapper.breakdown);

        // 2. Assign scores
        todaySleepScore.value = wrapper.sleepScore;
        todayDurationScore.value = wrapper.durationScore;
        todayEnvScore.value = wrapper.environmentScore;
        todayPhasesScore.value = wrapper.sleepPhasesScore;
        durationHours.value = wrapper.durationHours;

        // 3. Time in Bed (Already handled in Model for history/today)
        todayTimeInBed.value = wrapper.timeInBed;

        // 4. Time Asleep Formatting
        // Model mein humne 'timeAsleep' ko String mein rakha hai
        double totalMins = double.tryParse(wrapper.timeAsleep) ?? 0.0;

        // Agar value 0 se 24 ke beech hai (matlab hours mein hai), toh convert to minutes
        // Kyunki historical data 'duration_hours' (8.0) bhejta hai
        if (totalMins > 0 && totalMins <= 24) {
          totalMins = totalMins * 60;
        }

        todayTimeAsleep.value = formatMinsToText(totalMins.toInt());

        debugPrint("✅ Sleep Quality Updated: ${todaySleepScore.value}");
      }
    } catch (e) {
      debugPrint("❌ Sleep Quality Error: $e");
    } finally {
      isQualityLoading.value = false;
    }
  }

  String formatMinsToText(int mins) {
    // Handle zero or negative values
    if (mins <= 0) return "0 min";

    // Handle less than an hour
    if (mins < 60) return "$mins min";

    // Calculate hours and remaining minutes
    int h = mins ~/ 60;
    int m = mins % 60;

    // If it's an exact hour (e.g., 120 mins -> "2h")
    if (m == 0) {
      return "${h}h";
    }

    // Standard format (e.g., 110 mins -> "1h 50m")
    return "${h}h ${m}m";
  }

  Future<void> fetchSleepStages(String type, {String? date}) async {
    try {
      isStagesLoading.value = true;

      // 🔥 1. Pass both type and date to the API
      final response = await ProgressApis.getSleepStages(type: type, date: date);

      if (response.success && response.data != null) {
        sleepSummary.value = response.data!.summary;
        sleepIntervals.assignAll(response.data!.intervals);
        hourLabels.assignAll(response.data!.hourLabels);
      }
    } catch (e) {
      debugPrint("❌ Sleep Stages API Error: $e");
    } finally {
      isStagesLoading.value = false;
    }
  }
  Future<void> fetchMyDreams() async {
    try {
      isLoadingDreams.value = true;
      final response = await ProgressApis.getDreamList();
      if (response.success) {
        myDreamsList.assignAll(response.data.toList().cast<DreamData>());
      }
    } catch (e) {
      debugPrint("❌ Dream error: $e");
    } finally {
      isLoadingDreams.value = false;
    }
  }

  Future<void> fetchRecommendations(String type, {String? date}) async {
    // 🔒 Personalised recommendations are AI-generated, so consent is required.
    if (!hasAiConsent()) {
      recommendationList.clear();
      return;
    }

    try {
      isRecLoading.value = true;
      final response = await ProgressApis.getRecommendations(type: type, date: date);
      if (response.success && response.data != null) {
        recommendationList.assignAll(response.data!.recommendations);
      }
    } catch (e) {
      debugPrint("❌ Recommendations Error: $e");
    } finally {
      isRecLoading.value = false;
    }
  }

  Future<void> fetchSleepAudio(String type, {String? date}) async {
    try {
      isLoadingAudio.value = true;

      final response = await ProgressApis.getSleepAudioRecordings(dataType: type, date: date);

      if (response.success) {
        final mappedCategories = response.data.map((cat) {
          return RecordingCategory(
            title: cat.audioType,
            label: cat.audioTypeLabel,
            emoji: _getEmojiForType(cat.audioType),
            bgColor: _getColorForType(cat.audioType),
            recordings: cat.data,
            isExpanded: false,
          );
        }).toList();

        categories.assignAll(mappedCategories);
        for (var cat in categories) {
          debugPrint("Cat: ${cat.title} | recordings: ${cat.recordings.length}");
        }
      }
    } catch (e) {
      debugPrint("❌ Audio error: $e");
    } finally {
      isLoadingAudio.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> handlePlayPause(String audioPath) async {
    final fullUrl = "https://api.sleepable.ai$audioPath";
    try {
      if (playingUrl.value == audioPath) {
        isPlaying.value ? await _player.pause() : await _player.play();
      } else {
        playingUrl.value = audioPath;
        await _player.setUrl(fullUrl);
        await _player.play();
      }
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }

  void toggleExpand(int index) {
    categories[index].isExpanded = !categories[index].isExpanded;
    categories.refresh();
  }

  String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return "00:00";
    return "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
  }

  String _getEmojiForType(String type) {
    switch (type.toLowerCase()) {
      case 'snoring': return "😴";
      case 'animal sounds': return "🐶";
      case 'bruxism': return "🦷";
      default: return "🎶";
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'snoring': return Colors.purpleAccent;
      case 'animal sounds': return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }
  String getStageStatus(String title, double percent) {
    if (percent == 0) return "None";

    switch (title) {
      case "Deep":
        return percent < 0.15 ? "Low" : (percent > 0.25 ? "High" : "Optimal");
      case "Dream":
        return percent < 0.20 ? "Low" : (percent > 0.25 ? "High" : "Optimal");
      case "Light":
        return percent < 0.40 ? "Low" : (percent > 0.60 ? "High" : "Optimal");
      default:
        return "Normal";
    }
  }
  void _setupStaticSleepStages() {
    sleepStages.value = [
      SleepStage(start: DateTime(2025, 1, 1, 22, 0), end: DateTime(2025, 1, 1, 22, 40), index: 1, color: Colors.purpleAccent),
      SleepStage(start: DateTime(2025, 1, 1, 22, 40), end: DateTime(2025, 1, 1, 23, 20), index: 3, color: Colors.indigoAccent),
      SleepStage(start: DateTime(2025, 1, 1, 23, 20), end: DateTime(2025, 1, 2, 0, 10), index: 2, color: Colors.blueAccent),
    ];
  }
}

// -----------------------------------------------------------------------------
// Supporting Classes
// -----------------------------------------------------------------------------

class SleepStage {
  final DateTime start;
  final DateTime end;
  final int index;
  final Color color;
  SleepStage({required this.start, required this.end, required this.index, required this.color});
}

