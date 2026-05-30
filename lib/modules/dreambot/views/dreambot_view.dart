import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/library.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../music/views/music_view.dart';
import '../../progress/model/dream_list_response.dart';
import '../controllers/dreambot_controller.dart';

class DreamBotScreen extends GetView<DreamBotController> {
  final bool? fromProgress;
  int selectedDreamId = 0;

  DreamBotScreen({super.key}) : fromProgress = Get.parameters["fromProgress"] == "true";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              SizedBox(height: 20 * SizeConfigs.textScale),
              _header(context, fromProgress),
              SizedBox(height: 20 * SizeConfigs.textScale),

              Expanded(
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: controller.isFirstTime.value ? _firstTimeInputUI(context) : _chatList()),
              ),

              // 🔥 Logic to hide the bottom area for Old Dreams
              _buildBottomArea(context),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBottomArea(BuildContext context) {
    return Obx(() {
      // 1. Check if the image/result has already been generated
      bool hasResult = controller.messages.any((m) => m["isDreamResult"] == true);

      // 2. If the final image is already on screen, show nothing at the bottom
      if (hasResult) {
        return const SizedBox(height: 20);
      }

      // 3. If it's the very first entry screen (Big Box), don't show chat yet
      if (controller.isFirstTime.value) {
        return _analyzeButtonFirstTime(context, fromProgress);
      }

      // 4. Normal Flow: Stack the Generate Button (if ready) and the Chat Input
      return Column(mainAxisSize: MainAxisSize.min, children: [if (controller.canAnalyze.value) _bigAnalyzeButton(context), _bottomChatInput(context)]);
    });
  }

  Widget _bigAnalyzeButton(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: ElevatedButton(
          // Disable while loading
          onPressed: controller.isFirstAnalyzeLoading.value ? null : controller.runFinalAnalysis,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: Colors.blueAccent.withOpacity(0.6),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: controller.isFirstAnalyzeLoading.value
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      context.lang.generateDreamImage,
                      // "Generate Dream Image",
                      style: TextStyle(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool? fromProgress) {
    // Check if we opened this from an existing dream in the list
    final bool isViewingHistory = Get.parameters["dreamId"] != null && int.parse(Get.parameters["dreamId"]!) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, onTap: () => Get.back()),
          Image.asset(Assets.alarmDreamBotLogo, width: 170),
          const SizedBox(width: 40), // Placeholder to keep logo centered
        ],
      ),
    );
  }

  Widget _firstTimeInputUI(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          padding: const EdgeInsets.all(20), // Added padding for the welcome message
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.dialogCard.withOpacity(0.3),
            image: DecorationImage(image: AssetImage(Assets.alarmDrearBotBackground), fit: BoxFit.cover, opacity: 0.2),
          ),
          child: Obx(() {
            if (controller.isFirstAnalyzeLoading.value) {
              return const Center(child: LoaderWidget(size: 120));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 THE DYNAMIC WELCOME MESSAGE FROM API
                Text(
                  controller.welcomeMessage.value,
                  // style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontSize: 15 * SizeConfigs.textScale,
                      fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 16),

                // THE INPUT FIELD
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (v) {
                      controller.userInput.value = v.trim();
                      controller.isTyping.value = v.trim().isNotEmpty;
                    },
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.lang.typeYourResponseHere,//"Type your response here...",
                      hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white60, fontSize: 14 * SizeConfigs.textScale),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _analyzeButtonFirstTime(BuildContext context, bool? fromProgress) {
    return Obx(() {
      bool isUserReady = controller.userInput.value.trim().isNotEmpty;
      bool isLoading = controller.isFirstAnalyzeLoading.value;
      String welcomeMsg = controller.welcomeMessage.value.toLowerCase();
      bool isLimitReached = welcomeMsg.contains(context.lang.upgrade) || welcomeMsg.contains(context.lang.limit);
      final subController = Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : Get.put(SubscriptionController());
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Container(
          // 🔥 Gradient logic yahan handle hogi
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: isLimitReached
                ? const LinearGradient(
              colors: [AppColors.proLight, AppColors.proDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null, // Limit nahi hai toh no gradient
            color: !isLimitReached
                ? (isUserReady ? Colors.blue : AppColors.dialogCard.withOpacity(0.3))
                : null,
          ),
          child: ElevatedButton(
            onPressed: () {
              if (isLoading) return;

              if (isLimitReached) {
                // ✅ Step 1: Upgrade click par Premium Sheet open karein
                showPremiumOfferSheet4(context);
                debugPrint("Action: Opening Premium Sheet");
              } else if (isUserReady) {
                controller.handleFirstAction();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // 🔥 Keep this transparent
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
              isLimitReached ? context.lang.upgradePremium : (fromProgress == true ? context.lang.analyzeMyDream : context.lang.analyze),
              style: TextStyle(
                color: (isUserReady || isLimitReached) ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ),
      );
    });
  }
  Widget _chatList() {
    return Obx(
      () => Container(
        // We keep the main container background clean/transparent
        color: Colors.transparent,
        padding: const EdgeInsets.all(6),
        child: ListView.builder(
          controller: controller.scrollController,
          itemCount: controller.messages.length + (controller.isBotTyping.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (controller.isBotTyping.value && index == controller.messages.length) {
              return _botTypingBubble();
            }

            final msg = controller.messages[index];
            final bool isUser = msg["isUser"] ?? false;

            if (isUser) {
              return _buildUserBubble(context, msg);
            } else if (msg["isDreamResult"] == true) {
              // 🔥 This shows the special card with the background image
              return _buildDreamResultCard(context, msg);
            } else {
              // 💬 Standard Chat bubble
              return _buildBotBubble(context, msg);
            }
          },
        ),
      ),
    );
  }
  Widget _buildDreamResultCard(BuildContext context, Map<String, dynamic> msg) {
    final boxDecoration = BoxDecoration(
      color: const Color(0xFF181822),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );

    // Helper to check if string or list is effectively empty
    bool isEmpty(dynamic value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      if (value is Iterable) return value.isEmpty;
      return false;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: !isEmpty(msg["image"])
                ? Image.network(
              msg["image"],
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            )
                : Container(
              height: 220,
              width: double.infinity,
              color: Colors.white10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
                  Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40),
                  SizedBox(height: 10),
                  Text(context.lang.noImageAvailable, style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. DATE
          if (!isEmpty(msg["date"]))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    controller.formatDreamDate(msg["date"]),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (!isEmpty(msg["date"])) SizedBox(height: 16 * SizeConfigs.paddingScale),

          // 3. SUMMARY CARD
          if (!isEmpty(msg["summary"])) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: boxDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowHeader(Icons.auto_awesome, context.lang.summary),
                  const SizedBox(height: 12),
                  Text(msg["summary"], style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
                ],
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // 4. EMOTION CARD
          if (!isEmpty(msg["emotion"])) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: boxDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:  [
                      Icon(Icons.favorite_border, color: Color(0xFFF48FB1), size: 20),
                      SizedBox(width: 10),
                      Text(context.lang.emotion, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(msg["emotion"], style: const TextStyle(color: Color(0xFFF48FB1), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // 5. KEYWORDS CARD
          if (!isEmpty(msg["keywords"])) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: boxDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowHeader(Icons.mouse_outlined, context.lang.keywords),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (msg["keywords"] as List).map((k) => _keywordChip(k.toString())).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // SCENES SECTION
          if (!isEmpty(msg["scenes"])) ...[
            _resultSectionCard(
              title:context.lang.dreamScenes,
              icon: Icons.photo_library_outlined,
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (msg["scenes"] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final scene = msg["scenes"][index];
                    final imageUrl = scene.imageUrl.startsWith('http') ? scene.imageUrl : "https://api.sleepable.ai${scene.imageUrl}";
                    return GestureDetector(
                      onTap: () {
                        // 🔥 Image badi screen pe dikhane ke liye call
                        _showFullScreenImage(imageUrl, scene.title);
                      },
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(imageUrl, fit: BoxFit.cover),
                              Container(
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
                                ),
                                child: Text(scene.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // 6. MANIFESTATION CARD
          if (!isEmpty(msg["manifestation"])) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: boxDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(context.lang.manifestationGuidance, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(msg["manifestation"], style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
                ],
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // INTERPRETATION
          if (!isEmpty(msg["interpretation"])) ...[
            _resultSectionCard(
              title: context.lang.interpretation,
              icon: Icons.psychology_alt_outlined,
              child: Text(msg["interpretation"], style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // GUIDANCE
          if (!isEmpty(msg["guidance"])) ...[
            _resultSectionCard(
              title: context.lang.guidance,//"Guidance",
              icon: Icons.lightbulb_outline,
              child: Text(msg["guidance"], style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // ACTION STEPS
          if (!isEmpty(msg["actionSteps"])) ...[
            _resultSectionCard(
              title: context.lang.actionSteps,//"Action Steps",
              icon: Icons.check_circle_outline,
              child: Column(
                children: (msg["actionSteps"] as List)
                    .map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFFA683FF)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(step.toString(), style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
            SizedBox(height: 12 * SizeConfigs.paddingScale),
          ],

          // CHAT HISTORY
          if (!isEmpty(msg["chatHistory"])) ...[
            const SizedBox(height: 24),
             Text(context.lang.conversation, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...((msg["chatHistory"] as List).map((chat) => _buildHistoryChatBubble(chat,context)).toList()),
          ]
        ],
      ),
    );
  }
  Widget _resultSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF181822),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowHeader(icon, title),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
  // 🔥 NEW: Conversation Chat Bubbles (Matches screenshots 4 & 5)
// 🔥 UPDATED: Conversation Chat Bubbles (Left/Right aligned with profile icon)
  Widget _buildHistoryChatBubble(MessageData chat,BuildContext context) {
    bool isUser = chat.role == 'user';

    if (isUser) {
      // 👤 USER BUBBLE (Aligned Right)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          decoration: BoxDecoration(
            color: const Color(0xFF231F37), // Subtle purple background for user
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                context.lang.you,// "You",
                style: TextStyle(color: Color(0xFFA683FF), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                chat.content,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      );
    } else {
      // 🤖 DREAMBOT BUBBLE (Aligned Left with Icon)
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Icon
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6),
              child: Image.asset(Assets.homeSleepableAppIcon, width: 35),
            ),
            // Chat Bubble
            Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(maxWidth: Get.width * 0.72),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B26), // Dark grey background for bot
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    context.lang.dreamBot,//"DreamBot",
                    style: TextStyle(color: Color(0xFFA683FF), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chat.content,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
  // Helper UI Methods
  Widget _rowHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFA683FF), size: 20), // Purple Icon
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _keywordChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF252535), // Darker chip background
          borderRadius: BorderRadius.circular(8) // Slightly square borders like screenshot
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFA683FF), fontSize: 13)), // Purple text
    );
  }

  // 💬 Helper for regular bot messages
  Widget _buildBotBubble(BuildContext context, Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(right: 6, top: 10), child: Image.asset(Assets.homeSleepableAppIcon, width: 35)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: Get.width * 0.75),
            decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(16)),
            // child: Text(
            //   msg["msg"] ?? '',
            //   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 15 * SizeConfigs.textScale),
            // ),
            child: Text(
              msg["msg"] ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontSize: 15 * SizeConfigs.textScale,
                  fontWeight: FontWeight.w600 // 🔥 ADDED THIS
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 Helper for user messages
  Widget _buildUserBubble(BuildContext context, Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
        // child: Text(
        //   msg["msg"] ?? '',
        //   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 15 * SizeConfigs.textScale),
        // ),
        child: Text(
          msg["msg"] ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontSize: 15 * SizeConfigs.textScale // 🔥 Missing the fontWeight: FontWeight.w600!
          ),
        ),
      ),
    );
  }

  // ---------------- BOTTOM CHAT INPUT ----------------
  Widget _bottomChatInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                // 1. Keep the FocusNode as a FocusNode, don't pass a bool here
                focusNode: controller.focusNode,

                // 2. Use the 'enabled' property to disable input during loading
                enabled: !controller.isFirstAnalyzeLoading.value,

                onChanged: (v) => controller.userInput.value = v,
                decoration: InputDecoration(
                  // 3. Optional: Change hint text when loading
                  hintText: controller.isFirstAnalyzeLoading.value ? context.lang.generatingYourDream : context.lang.typeHere,
                  filled: true,
                  fillColor: controller.isFirstAnalyzeLoading.value
                      ? Colors.white.withOpacity(0.05) // Dim it slightly when disabled
                      : Colors.white10,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: controller.isFirstAnalyzeLoading.value
                      ? Colors
                            .white38 // Fade text color when loading
                      : Colors.white60,
                  fontSize: 14 * SizeConfigs.textScale,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                print('ontap if (!controller.isFirstAnalyzeLoading.value)');
                if (!controller.isFirstAnalyzeLoading.value) controller.sendMessage();
              },
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue,
                child: Icon(Icons.send, color: controller.isFirstAnalyzeLoading.value ? Colors.grey : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6, top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(right: 6, top: 10), child: Image.asset(Assets.homeSleepableAppIcon, width: 35)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(16)),
              child: const SizedBox(width: 30, child: TypingDots()),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        int dots = (_controller.value * 3).floor() + 1;
        return Text(
          '.' * dots,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}

void _showFullScreenImage(String url, String title) {
  Get.dialog(
    Scaffold(
      backgroundColor:  AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.white38, size: 50),
          ),
        ),
      ),
    ),
    useSafeArea: false,
  );
}