import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepable_ai/core/constants/colors.dart';

import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/ai_consent_dialog.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../progress/controllers/progress_controller.dart';

class DreamBotController extends GetxController {

  RxBool isFirstTime = true.obs;
  RxBool isBotTyping = false.obs;
  RxBool isFirstAnalyzeLoading = false.obs;
  RxBool canAnalyze = false.obs; // Controls visibility of the Generate Button
  RxBool isTyping = false.obs;
  RxString userInput = "".obs;
  RxString welcomeMessage = "Initializing DreamBot...".obs;

  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  TextEditingController textController = TextEditingController();
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();

  int currentDreamId = 0;
  int userMessageCount = 0; // Tracks how many messages the user sent

  bool _consentPromptOpen = false;
  bool _sessionStartInFlight = false;
  bool _sessionStarted = false;

  /// 🔒 Apple Guideline 5.1.1(i) / 5.1.2(i)
  /// Explicit permission must be obtained BEFORE sending the user's personal data
  /// (dream text, sleep stats) to a third-party AI provider.
  /// Returns true once consent has been granted (either now or previously).
  Future<bool> _requireAiConsent() async {
    if (hasAiConsent()) return true;
    if (_consentPromptOpen) return false; // a dialog is already open

    _consentPromptOpen = true;
    // Let the first frame finish; the Navigator is not ready during onInit.
    await WidgetsBinding.instance.endOfFrame;

    bool granted = false;
    final ctx = Get.context;
    if (ctx != null) granted = await ensureAiConsent(ctx);
    _consentPromptOpen = false;

    if (!granted) {
      isFirstAnalyzeLoading.value = false;
      isBotTyping.value = false;
      welcomeMessage.value = aiConsentDeclinedMessage();
    }
    return granted;
  }

  SubscriptionController? get _sub => Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : null;

  bool _isOnTrial() {
    final sub = _sub;
    return sub != null && sub.isTrial.value && !sub.isPremium.value;
  }

  /// The trial includes a single dream. Once it is used there is nothing to
  /// upgrade to - the store converts the trial on its own schedule - so the
  /// free-user "upgrade to premium" copy would be misleading here.
  String _trialDreamLimitMessage() {
    const map = {
      "en": {
        "used": "That was your 1 dream for the free trial.",
        "in": "Unlimited dreams unlock in {days} days, when your Premium starts.",
        "tomorrow": "Unlimited dreams unlock tomorrow, when your Premium starts.",
        "soon": "Unlimited dreams unlock as soon as your trial ends.",
      },
      "de": {
        "used": "Das war Ihr 1 Traum in der kostenlosen Testphase.",
        "in": "Unbegrenzte Traeume gibt es in {days} Tagen, wenn Ihr Premium startet.",
        "tomorrow": "Unbegrenzte Traeume gibt es morgen, wenn Ihr Premium startet.",
        "soon": "Unbegrenzte Traeume gibt es, sobald Ihre Testphase endet.",
      },
      "fr": {
        "used": "C'etait votre 1 reve de la periode d'essai.",
        "in": "Les reves illimites arrivent dans {days} jours, au debut de votre Premium.",
        "tomorrow": "Les reves illimites arrivent demain, au debut de votre Premium.",
        "soon": "Les reves illimites arrivent des la fin de votre essai.",
      },
      "es": {
        "used": "Ese fue tu unico sueno de la prueba gratuita.",
        "in": "Los suenos ilimitados se activan en {days} dias, cuando empiece tu Premium.",
        "tomorrow": "Los suenos ilimitados se activan manana, cuando empiece tu Premium.",
        "soon": "Los suenos ilimitados se activan en cuanto termine tu prueba.",
      },
      "pt": {
        "used": "Esse foi o seu unico sonho do teste gratuito.",
        "in": "Sonhos ilimitados chegam em {days} dias, quando o seu Premium comecar.",
        "tomorrow": "Sonhos ilimitados chegam amanha, quando o seu Premium comecar.",
        "soon": "Sonhos ilimitados chegam assim que o teste terminar.",
      },
    };
    final table = map[Get.locale?.languageCode ?? "en"] ?? map["en"]!;
    final days = _sub?.trialDaysRemaining;
    final String wait = days == null
        ? table["soon"]!
        : days <= 1
            ? table["tomorrow"]!
            : table["in"]!.replaceAll("{days}", "$days");
    return "${table["used"]!} $wait";
  }

  @override
  void onInit() {
    super.onInit();
    final sub = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : null;
    if (sub == null || !sub.showDreambot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.back();
        }
      });
      return;
    }
    final String? rawId = Get.parameters["dreamId"] ?? Get.arguments?["dream_id"]?.toString();
    int? paramId = int.tryParse(rawId ?? "0");

    if (paramId != null && paramId > 0) {
      _loadOldDreamFromHistory(paramId);
    } else {
      // 🚀 Step 1: Call the API immediately so the Bot message is ready
      // when the user lands on the screen.
      startNewDreamSession();
    }
  }
  @override
  void onReady() {
    super.onReady();
    // Do not start a second session — onInit already handles it.
  }
  String formatDreamDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "";
    try {
      // 1. Parse the string "2026-04-01 17:27:14" into a DateTime object
      DateTime parsedDate = DateTime.parse(rawDate);

      // 2. Format it to "Wednesday, 1 Apr 2026"
      // EEEE = Full weekday, d = Day, MMM = Short month, yyyy = Full year
      return DateFormat('EEEE, d MMM yyyy').format(parsedDate);
    } catch (e) {
      // If something goes wrong, just return the raw date to avoid a crash
      return rawDate;
    }
  }
  void startNewDreamSession() async {
    if (_sessionStartInFlight || (_sessionStarted && currentDreamId > 0)) {
      debugPrint("⏭ Skipping duplicate DreamBot session start");
      return;
    }
    _sessionStartInFlight = true;
    // 🔒 Consent is required before sending data to a third-party AI
    // (Apple 5.1.1(i) / 5.1.2(i)).
    if (!await _requireAiConsent()) {
      _sessionStartInFlight = false;
      return;
    }

    try {
      // Don't clear if we already have messages (to avoid flickering)
      if (messages.isEmpty) {
        isFirstAnalyzeLoading.value = true;
      }

      debugPrint("🚀 Calling Start Session to get Welcome Message...");
      final res = await ProgressApis.startDreamSession();

      if (res != null && res['success'] == true) {
        currentDreamId = res['data']['dream_id'];
        _sessionStarted = true;
        String botWelcome = res['data']['welcome_message'];

        // Update the dynamic welcome message for the "Big Input Box"
        welcomeMessage.value = botWelcome;

        // 🔥 THE KEY: Even though we are in "FirstTime" mode (Big Input Box),
        // we add the message to the list so it's there when the chat starts.
        if (messages.isEmpty) {
          messages.add({"isUser": false, "msg": botWelcome});
        }

        debugPrint("🎯 Session Started. ID: $currentDreamId");
      } else {
        // The backend's copy asks free users to upgrade; a trial user has
        // already paid their way in and only has to wait it out.
        String errorMsg = _isOnTrial()
            ? _trialDreamLimitMessage()
            : (res?['message'] ?? "Limit reached.");
        welcomeMessage.value = errorMsg;
        // If there's an error, we don't add to messages yet to keep UI clean
      }
    } catch (e) {
      debugPrint("🛑 API Error Caught: $e");
      String rawError = e.toString().replaceAll("${Get.context?.lang.exception}:", "").trim();

      if (rawError.toLowerCase().contains("${Get.context?.lang.forbidden}") || rawError.toLowerCase().contains("${Get.context?.lang.pageNotFound}")) {
        // A trial user gets one dream, and cannot buy their way out early -
        // the store converts the trial on its own schedule. Tell them that
        // rather than asking them to upgrade.
        rawError = _isOnTrial()
            ? _trialDreamLimitMessage()
            : (Get.context?.lang.freeUsersCanStartDreamSessionMonthUpgradePremiumUnlimitedAccess ??
                "Free users can start 1 dream session per month. Upgrade to premium for unlimited access.");
      }

      welcomeMessage.value = rawError;
    } finally {
      isFirstAnalyzeLoading.value = false;
      _sessionStartInFlight = false;
    }
  }

  // This is called when the user clicks the "Analyze" button
  void handleFirstAction() async {
    String msg = userInput.value.trim();
    if (msg.isEmpty) return;

    // If the session failed to start earlier (e.g. internet issue), try again
    if (currentDreamId == 0) {
       startNewDreamSession();
    }

    // If we have a successful session now, proceed to send the message
    if (currentDreamId != 0) {
      await sendMessage();
    } else {
      // If still no ID (likely Premium Limit), show the toast
      _showToast(welcomeMessage.value);
    }
  }

  Future<void> sendMessage() async {
    String msg = userInput.value.trim();
    if (msg.isEmpty || currentDreamId == 0) return;

    // 🔒 The dream text is sent to a third-party AI, so consent is required.
    if (!await _requireAiConsent()) return;

    // Standard Chat UI update
    // We don't clear the list because index 0 is the Bot's welcome message
    messages.add({"isUser": true, "msg": msg});

    userMessageCount++;
    textController.clear();
    userInput.value = "";
    isTyping.value = false;
    isBotTyping.value = true;

    // Switch from Big Box to Chat List
    isFirstTime.value = false;
    scrollToBottom();

    try {
      final res = await ProgressApis.sendDreamMessage(currentDreamId, msg);
      isBotTyping.value = false;

      if (res['success']) {
        messages.add({"isUser": false, "msg": res['data']['response']});
        if (res['data']['can_analyze'] == true || userMessageCount >= 3) {
          canAnalyze.value = true;
        }
      }
    } catch (e) {
      isBotTyping.value = false;
      debugPrint("Send Message Error: $e");
    }
    scrollToBottom();
  }

// Helper method for the Toast
  void _showToast(String message) {
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withOpacity(0.8),
      borderRadius: 10,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      isDismissible: true,
    );
  }

  void runFinalAnalysis() async {
    // 🔒 Dream analysis runs on a third-party AI, so consent is required.
    if (!await _requireAiConsent()) return;
    if (currentDreamId <= 0) {
      _showToast("Dream session not ready yet. Please wait a moment.");
      return;
    }

    try {
      isFirstAnalyzeLoading.value = true;

      // Use the session finalize endpoint (full conversation + 3 scenes),
      // not the legacy one-shot analyze-dream path.
      final res = await ProgressApis.finalizeDreamAnalysis(currentDreamId);
      if (res['success'] != true || res['data'] is! Map) {
        _showToast(res['message']?.toString() ?? "Analysis failed");
        return;
      }

      final Map<String, dynamic> d = Map<String, dynamic>.from(res['data']);
      final int dreamId = (d['dream_id'] as num?)?.toInt() ?? currentDreamId;
      final bool imagesPending = d['images_pending'] == true;
      final String imagePath = (d['image_url'] ?? d['image'] ?? '').toString();

      messages.add({
        "isUser": false,
        "isDreamResult": true,
        "title": d['title']?.toString() ?? "",
        "summary": d['summary']?.toString() ?? "",
        "emotion": d['emotion']?.toString() ?? "",
        "keywords": d['keywords'] is List ? List.from(d['keywords']) : <dynamic>[],
        "manifestation": d['manifestation_message']?.toString() ?? "",
        "interpretation": d['interpretation']?.toString() ?? "",
        "guidance": d['guidance']?.toString() ?? "",
        "actionSteps": d['action_steps'] is List ? List.from(d['action_steps']) : <dynamic>[],
        "scenes": d['scenes'] is List ? List.from(d['scenes']) : <dynamic>[],
        "date": d['created_at']?.toString() ?? "",
        "image": _absoluteImageUrl(imagePath),
        "chatHistory": d['chat_history'],
        "imagesPending": imagesPending,
      });

      canAnalyze.value = false;

      if (imagesPending) {
        _pollForDreamImages(dreamId, messages.length - 1);
      }

      if (Get.isRegistered<ProgressController>()) {
        Get.find<ProgressController>().fetchMyDreams();
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
    } finally {
      isFirstAnalyzeLoading.value = false;
      // Show analysis result from the top (image/summary first), not Action Steps at bottom
      scrollToTop();
    }
  }
  String _absoluteImageUrl(String path) {
    if (path.isEmpty) return "";
    return path.startsWith('http') ? path : "https://api.sleepable.ai$path";
  }

  /// Dream images are generated after the analysis text is returned (~50s), so
  /// re-read the dream a few times and update the card in place once they exist.
  Future<void> _pollForDreamImages(int dreamId, int messageIndex) async {
    if (dreamId == 0) return;

    for (int attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(const Duration(seconds: 15));
      if (isClosed) return;

      try {
        final res = await ProgressApis.getDreamById(dreamId);
        if (!res.success || res.data.isEmpty) continue;

        final d = res.data.first;
        final bool ready = d.scenes.isNotEmpty || d.image.isNotEmpty;
        if (!ready && d.imagesPending) continue;

        if (messageIndex < 0 || messageIndex >= messages.length) return;
        final updated = Map<String, dynamic>.from(messages[messageIndex]);
        updated["scenes"] = d.scenes;
        updated["image"] = _absoluteImageUrl(d.image);
        updated["imagesPending"] = false;
        messages[messageIndex] = updated;
        messages.refresh();
        return;
      } catch (e) {
        debugPrint("Dream image poll attempt ${attempt + 1} failed: $e");
      }
    }

    // Gave up waiting: stop showing the loader rather than spinning forever.
    if (messageIndex >= 0 && messageIndex < messages.length) {
      final updated = Map<String, dynamic>.from(messages[messageIndex]);
      updated["imagesPending"] = false;
      messages[messageIndex] = updated;
      messages.refresh();
    }
  }

  void _loadOldDreamFromHistory(int id) async {
    isFirstTime.value = false; // Switch to chat view immediately
    try {
      // 1. Ensure the progress controller has data
      final progressCont = Get.isRegistered<ProgressController>()
          ? Get.find<ProgressController>()
          : await Get.put(ProgressController());

      // 2. Fetch fresh list if empty (important for deep links)
      if (progressCont.myDreamsList.isEmpty) {
        await progressCont.fetchMyDreams();
      }

      final dream = progressCont.myDreamsList.firstWhere((d) => d.id == id);

      // Set current ID so the user can continue chatting if they want
      currentDreamId = dream.id;

      messages.add({
        "isUser": false,
        "isDreamResult": true,
        "title": dream.title,
        "summary": dream.summary,
        "emotion": dream.emotion,
        "keywords": dream.keywords,
        "manifestation": dream.manifestationMessage,
        "interpretation": dream.interpretation,
        "guidance": dream.guidance,
        "actionSteps": dream.actionSteps,
        "scenes": dream.scenes,
        "date": dream.createdAt,
        "image": dream.image.isNotEmpty
            ? (dream.image.startsWith('http') ? dream.image : "https://api.sleepable.ai${dream.image}")
            : "",
        "chatHistory": dream.chatHistory,
      });

      // 🔥 If the dream was already analyzed, allow more questions (Chat mode)
      canAnalyze.value = false;

    } catch (e) {
      debugPrint("Dream history error: $e");
      // Fallback: Start new if old one fails
      startNewDreamSession();
    }
  }
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// After dream analysis, open the result from the top (not Guidance/Action Steps).
  void scrollToTop() {
    void jump() {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }

    // Wait for the tall result card to layout, then pin to top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      jump();
      Future.delayed(const Duration(milliseconds: 150), jump);
    });
  }

  void resetForEditing() async {
    messages.clear();
    isFirstTime.value = true;
    canAnalyze.value = false;
    isTyping.value = false;
    userInput.value = "";
    textController.clear();
    currentDreamId = 0;
    _sessionStarted = false;
    _sessionStartInFlight = false;
    startNewDreamSession();
    focusNode.requestFocus();
  }
}
