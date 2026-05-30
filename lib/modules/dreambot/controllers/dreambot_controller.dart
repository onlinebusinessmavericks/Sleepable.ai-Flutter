import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepable_ai/core/constants/colors.dart';

import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../progress/model/dream_list_response.dart';

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

  @override
  void onInit() {
    super.onInit();
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
    // If we don't have an ID and we aren't viewing history, FORCE start.
    if (currentDreamId == 0 && !Get.parameters.containsKey("dreamId")) {
      debugPrint("🚀 Triggering Session Start from onReady");
      startNewDreamSession();
    }
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
    try {
      // Don't clear if we already have messages (to avoid flickering)
      if (messages.isEmpty) {
        isFirstAnalyzeLoading.value = true;
      }

      debugPrint("🚀 Calling Start Session to get Welcome Message...");
      final res = await ProgressApis.startDreamSession();

      if (res != null && res['success'] == true) {
        currentDreamId = res['data']['dream_id'];
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
        String errorMsg = res?['message'] ?? "Limit reached.";
        welcomeMessage.value = errorMsg;
        // If there's an error, we don't add to messages yet to keep UI clean
      }
    } catch (e) {
      debugPrint("🛑 API Error Caught: $e");
      String rawError = e.toString().replaceAll("${Get.context?.lang.exception}:", "").trim();

      if (rawError.toLowerCase().contains("${Get.context?.lang.forbidden}") || rawError.toLowerCase().contains("${Get.context?.lang.pageNotFound}")) {
        rawError = Get.context?.lang.freeUsersCanStartDreamSessionMonthUpgradePremiumUnlimitedAccess ?? "Free users can start 1 dream session per month. Upgrade to premium for unlimited access.";
      }

      welcomeMessage.value = rawError;
    } finally {
      isFirstAnalyzeLoading.value = false;
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
    try {
      isFirstAnalyzeLoading.value = true;

      // 🔥 THE FIX: Find the last message sent by the System (isUser == false)
      String lastSystemMessage = "";

      // Filter out user messages and previous result cards
      final systemMessages = messages.where(
              (m) => m["isUser"] == false && m["isDreamResult"] != true
      );

      if (systemMessages.isNotEmpty) {
        lastSystemMessage = systemMessages.last["msg"].toString();
      } else {
        lastSystemMessage = Get.context?.lang.pleaseAnalyzeDream ?? "Please analyze this dream."; // Fallback just in case
      }

      // Send the final system response to the analyze API
      final response = await ProgressApis.getDreamAnalysis(
        description: lastSystemMessage,
        dreamId: currentDreamId,
      );

      if (response.success && response.data.isNotEmpty) {
        final DreamData d = response.data.first;

        messages.add({
          "isUser": false,
          "isDreamResult": true,
          "title": d.title,
          "summary": d.summary,
          "emotion": d.emotion,
          "keywords": d.keywords,
          "manifestation": d.manifestationMessage,
          "interpretation": d.interpretation,
          "guidance": d.guidance,
          "actionSteps": d.actionSteps,
          "scenes": d.scenes,
          "date": d.createdAt,
          "image": d.image.startsWith('http') ? d.image : "https://api.sleepable.ai${d.image}",
          "chatHistory": d.chatHistory,
        });

        canAnalyze.value = false;

        if (Get.isRegistered<ProgressController>()) {
          Get.find<ProgressController>().fetchMyDreams();
        }
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
    } finally {
      isFirstAnalyzeLoading.value = false;
      scrollToBottom();
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

  void resetForEditing() async {
    messages.clear();
    isFirstTime.value = true;
    canAnalyze.value = false;
    isTyping.value = false;
    userInput.value = "";
    textController.clear();
    startNewDreamSession();
    focusNode.requestFocus();
  }
}