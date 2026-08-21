import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../data/services/config.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../sleep_info/controllers/sleep_info_controller.dart';
import '../../sleep_info/views/sleeppedia_detail_view.dart';
import '../../sleep_info/widget/sleep_quiz_detail_view.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../../sleep_sound/model/SoundItem.dart';
import '../../sleep_sound/widget/MixBarWidget.dart';
import '../../sleep_sound/widget/PlayerFullSheetUI.dart';

class HomeScreen extends GetView<HomeController> {
  HomeScreen({super.key});

  final controller = Get.put(HomeController());

  final GlobalKey totalSleepKey = GlobalKey();
  final GlobalKey setReminderKey = GlobalKey();

  // double buttonX = 250; // default position
  // double buttonY = 500;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subController = Get.find<SubscriptionController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Forces transparency
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark, // For iOS Dark mode
        systemNavigationBarColor: Colors.transparent,
      ),

      child: Obx(() {
        // Agar user logged in hai aur sync abhi tak nahi hua, sirf tabhi loader dikhao
        // Lekin agar cache mein data hai (isPremium), toh seedha UI dikhao
        if (!subController.isInitialSyncDone.value && !subController.isPremium.value) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: true),

              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                controller: controller.screenScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Greeting + Cloud
                    Stack(
                      children: [
                        /// 🔹 Background image
                        RepaintBoundary(
                          child: Stack(
                            children: [
                              Container(
                                height: 340 * SizeConfigs.paddingScale,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(image: AssetImage(Assets.homeBackgroundMountains), fit: BoxFit.cover,filterQuality: FilterQuality.low,),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(top: 52 * SizeConfigs.paddingScale, left: 17 * SizeConfigs.paddingScale, child: Image.asset(Assets.homeSleepableTextLogo, height: 23)),
                        Positioned(
                          top: 52 * SizeConfigs.paddingScale,
                          right: 14 * SizeConfigs.paddingScale,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: AppColors.glowPinkColor.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(Assets.homeSleepableAppIcon, height: 38),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          top: 80 * SizeConfigs.paddingScale,
                          child: Obx(() {
                            return Text(
                              "${controller.greeting.value}, ${controller.userName}",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                            ).paddingSymmetric(horizontal: 17 * SizeConfigs.paddingScale);
                          }),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 106 * SizeConfigs.paddingScale,
                          child: Obx(() {
                            return Text(
                              controller.toDayDate.value.isNotEmpty ? DateFormat('d MMMM, y').format(DateTime.parse(controller.toDayDate.value)) : context.lang.loading,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                            ).paddingSymmetric(horizontal: 17 * SizeConfigs.paddingScale);
                          }),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 150 * SizeConfigs.paddingScale,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.background]),
                            ),
                          ),
                        ),

                        /// 🔹 Foreground content aligned at bottom
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4 * SizeConfigs.paddingScale),

                              // 🔹 Horizontal list
                              SizedBox(
                                height: 100 * SizeConfigs.paddingScale,
                                child: NotificationListener<OverscrollIndicatorNotification>(
                                  onNotification: (overscroll) {
                                    overscroll.disallowIndicator(); // remove scroll glow
                                    return true;
                                  },

                                  child: Obx(() {
                                    final currentItems = controller.filteredItems;
                                    final dashboardController = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>() : Get.put(DashboardController());

                                    final sleepSoundController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

                                    return ListView.builder(
                                      padding: EdgeInsets.only(left: 18 * SizeConfigs.paddingScale),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: currentItems.length,
                                      cacheExtent: 1000,
                                      itemBuilder: (context, index) {
                                        // final item = controller.items[index];
                                      final item = currentItems[index];
                                      String itemLabel = "";
                                      switch (item['lang_key']) {
                                        case 'white_noise': itemLabel = context.lang.whiteNoise; break;
                                        case 'sleep_aid': itemLabel = context.lang.sleepAid; break;
                                        case 'premium': itemLabel = context.lang.premium; break;
                                        case 'story': itemLabel = context.lang.story ?? "Story"; break;
                                        case 'dreamBot': itemLabel = context.lang.dreamBot; break;
                                        case 'breathwork': itemLabel = context.lang.breathwork; break;
                                        default: itemLabel = "Class";
                                      }
                                        return Obx(() {
                                          final isTapped = controller.tappedIndex.value == index;
                                          return GestureDetector(
                                            onTap: () {
                                              controller.tappedIndex.value = index;
                                              Future.delayed(const Duration(milliseconds: 120), () {
                                                if (controller.tappedIndex.value == index) {
                                                  controller.tappedIndex.value = -1;
                                                }

                                                // ✅ Hamesha ID check karein, Label nahi
                                                final String itemId = item['id'];

                                                if (itemId == 'white_noise') {
                                                  sleepSoundController.setJumpArguments(jumpTab: "white-noise", jumpFilter: "__all__");
                                                  dashboardController.changeTab(1);
                                                } else if (itemId == 'sleep_aid') {
                                                  sleepSoundController.setJumpArguments(jumpTab: "music", jumpFilter: "__all__");
                                                  dashboardController.changeTab(1);
                                                } else if (itemId == 'story') {
                                                  sleepSoundController.setJumpArguments(jumpTab: "story", jumpFilter: "__all__");
                                                  dashboardController.changeTab(1);
                                                } else if (itemId == 'premium') {
                                                  controller.showRotatingPremiumSheet(context);
                                                } else if (itemId == 'dreambot') {
                                                  Get.toNamed(Routes.dreamBot, parameters: {"fromProgress": "true", "dreamId": "0"});
                                                } else if (itemId == 'breathwork') {
                                                  Get.toNamed(Routes.breathwork);
                                                }
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              margin: EdgeInsets.only(right: 10 * SizeConfigs.paddingScale),
                                              width: 65 * SizeConfigs.paddingScale,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 85 * SizeConfigs.paddingScale,
                                                    height: 53 * SizeConfigs.paddingScale,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [AppColors.blueColor.withOpacity(0.7), AppColors.starFillColor, AppColors.white10],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(isTapped ? 1 * SizeConfigs.paddingScale : 0),
                                                      child: Container(
                                                        decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(28)),
                                                        child: Center(
                                                          child: Icon(item['icon'], color: isTapped ? AppColors.primary : Colors.white, size: 26 * SizeConfigs.paddingScale),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 6 * SizeConfigs.paddingScale),
                                                  Text(
                                                    itemLabel,
                                                    maxLines: 2,
                                                    textAlign: TextAlign.center,
                                                    style: Theme
                                                        .of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(color: AppColors.white, fontSize: 10 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        });
                                      },
                                    );

                                  }  )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6 * SizeConfigs.paddingScale),

                    /// Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blueBackground,
                        borderRadius: BorderRadius.circular(56),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppColors.textColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(
                              () => Text(
                                controller.currentInsight.value.isNotEmpty ? controller.currentInsight.value : context.lang.youHadGreatNightSleepKeepItUp,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).paddingSymmetric(horizontal: 18 * SizeConfigs.paddingScale),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),

                    /// Last Night's Sleep (Old UI style + New API Data)

                    Obx(() {
                      // 1. Extract Data from API model
                      final summary = controller.homeData.value?.data?.sleepSummary;
                      final sleepHours = summary?.totalSleepHours ?? 0.0;
                      final qualityRating = summary?.qualityRating ?? 0;

                      double actualHours = summary?.totalSleepHours ?? 0.0;

                      // 🔥 FIX 1: Agar hamesha 8 hours ka hi goal rakhna hai, toh API se variable mat lo.
                      // Direct 8.0 hardcode karo taaki calculation hamesha 8 ke hisab se ho.
                      double goalHours = 8.0;

                      // 5.55 / 8.0 = 0.69375 (Clamping isko 0.69 hi rakhegi, 1.0 nahi hone degi)
                      double progress = (actualHours / goalHours).clamp(0.0, 1.0);

                      return Container(
                        padding: const EdgeInsets.only(top: 10, bottom: 15, left: 18, right: 18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4 * SizeConfigs.paddingScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.lang.lastNightSleep,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.white, fontSize: 22 * SizeConfigs.textScale),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 1.0),
                                  child: Image.asset(Assets.iconsGraph, height: 20, width: 30, color: AppColors.graphIconColor),
                                ),
                              ],
                            ),
                            SizedBox(height: 18 * SizeConfigs.paddingScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${sleepHours}${context.lang.h}",
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.white, fontSize: 48 * SizeConfigs.textScale, height: 1),
                                    ),
                                    Text(
                                      context.lang.totalSleep,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 15 * SizeConfigs.textScale),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        if (index < qualityRating.floor()) {
                                          return Icon(Icons.star_rounded, color: AppColors.starFillColor);
                                        } else if (index == qualityRating.floor() && (qualityRating % 1) != 0) {
                                          return Icon(Icons.star_half_rounded, color: AppColors.starFillColor);
                                        } else {
                                          return Icon(Icons.star_rounded, color: AppColors.starColor);
                                        }
                                      }),
                                    ),
                                    Text(
                                      context.lang.quality,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 15 * SizeConfigs.textScale),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * SizeConfigs.paddingScale),

                            /// Safe & Clean Progress Bar
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: progress),
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                              builder: (context, value, _) {
                                final gradientColors = controller.getGradientColors(value);

                                return LayoutBuilder(builder: (context, constraints) {
                                  // Ab constraints.maxWidth ka exact 69% hi fillWidth banega
                                  final double fillWidth = constraints.maxWidth * value;

                                  return Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      // 🔥 FIX 2: AnimatedContainer hata kar normal Container lagaya hai
                                      // Kyunki smooth animation TweenAnimationBuilder khud handle kar raha hai
                                      child: Container(
                                        width: fillWidth,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                              colors: gradientColors,
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ).paddingSymmetric(horizontal: 18 * SizeConfigs.paddingScale);
                    }),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),

                    /// Tonight's Goal
                    Obx(() {
                      // Extract API data
                      final goal = controller.homeData.value?.data?.tonightSleepGoal;

                      // Use API values as defaults if available
                      final String displayBedtime = goal?.targetBedtime ?? controller.formatTimeOfDay(controller.bedtime.value);
                      return Container(
                        padding: const EdgeInsets.only(top: 10, bottom: 8, left: 18, right: 18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4 * SizeConfigs.paddingScale),

                            /// Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.lang.tonightGoal,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale),
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * SizeConfigs.paddingScale),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                        displayBedtime, // 🔥 API Data
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blueColor, fontSize: 33 * SizeConfigs.textScale, fontWeight: FontWeight.w900),
                                      ),
                                    Text(
                                      context.lang.targetBedtime,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 15 * SizeConfigs.textScale),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 10 * SizeConfigs.paddingScale),

                            /// Countdown Banner with Marquee
                            AnimatedBuilder(
                              animation: controller.animationController,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [AppColors.blueLine.withOpacity(.7), AppColors.blueLine.withOpacity(.4), AppColors.blueLine.withOpacity(.9)],
                                      stops: [controller.animation.value - 0.9, controller.animation.value, controller.animation.value + 0.9],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 10),
                                      const Icon(Icons.watch_later, color: AppColors.text, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Marquee(
                                          child: Text(
                                            controller.countdownText.value, // 🔥 Calculated via API hours_until_bedtime in controller
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.text, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 5 * SizeConfigs.paddingScale),

                            /// Reminder Toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.lang.setReminder,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.white,
                                    fontSize: 16 * SizeConfigs.textScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // 🔥 Loader removed, Switch is now always visible
                                Obx(() => Switch(
                                  padding: EdgeInsets.zero,
                                  value: controller.isEnabled.value, // Local RxBool
                                  onChanged: (value) {
                                    // 1. Instant UI Update (User ko wait nahi karna padega)
                                    controller.isEnabled.value = value;

                                    // 2. Silent API Call in background
                                    controller.updateReminderApi(value);
                                  },
                                )),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).paddingSymmetric(horizontal: 18 * SizeConfigs.paddingScale),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),

                    /// Weekly Sleep Pattern
                    Container(
                      padding: const EdgeInsets.only(top: 10, bottom: 15, left: 18, right: 18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                          context.lang.sleepDuration,// "Sleep Duration",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                              ),
                              Obx(() {
                                final duration = controller.averageSleep.value;
                                return Text(
                                  "${duration.toStringAsFixed(1)}${context.lang.hourUnit}",
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.white, fontSize: 36 * SizeConfigs.textScale, height: 1),
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: 20 * SizeConfigs.paddingScale),

                          /// 🔥 Bar Chart Section

                          Obx(() {
                            final data = controller.chartValues;
                            final labels = controller.chartLabels;
                            final selectedTab = controller.selectedTab.value;
                            final int selectedIndex = controller.selectedBarIndex.value;
                            final bool isMonthly = selectedTab == "Month";

                            // 🔥 FIX: Agar data empty hai toh 7 bars dikhao, warna jitna data hai utna.
                            final int columnCount = data.isNotEmpty ? data.length : 7;
                            final double chartHeight = 170 * SizeConfigs.paddingScale;

                            // Placeholder labels for empty state
                            final List<String> placeholderLabels = ["M", "T", "W", "T", "F", "S", "S"];

                            double highestValueInList = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b).toDouble() : 0.0;
                            final double maxVal = highestValueInList > 0 ? highestValueInList : 8.0;

                            Widget buildRow() {
                              return Row(
                                mainAxisAlignment: isMonthly ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(columnCount, (index) {
                                  // Safe check for data and labels
                                  final double value = data.length > index ? data[index].toDouble() : 0.0;
                                  final String label = labels.length > index ? labels[index] : placeholderLabels[index % 7];

                                  return GestureDetector(
                                    onTap: () {
                                      if (data.isNotEmpty) controller.selectedBarIndex.value = index;
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: isMonthly ? 8 * SizeConfigs.paddingScale : 0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              alignment: Alignment.bottomCenter,
                                              clipBehavior: Clip.none,
                                              children: [
                                                // 1. The Bar Container (Outer Pill)
                                                Container(
                                                  width: 14 * SizeConfigs.paddingScale,
                                                  height: double.infinity, // Height fix
                                                  decoration: BoxDecoration(
                                                    // Empty state background aur border hamesha dikhega
                                                    color: Colors.white.withOpacity(0.08),
                                                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(30),
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        final double fillHeight = (value / maxVal) * constraints.maxHeight;
                                                        return Column(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            AnimatedContainer(
                                                              duration: const Duration(milliseconds: 600),
                                                              curve: Curves.easeOutCubic,
                                                              width: double.infinity,
                                                              height: fillHeight, // Ye 0 hoga agar data nahi hai
                                                              decoration: BoxDecoration(
                                                                gradient: value > 0
                                                                    ? const LinearGradient(
                                                                    begin: Alignment.bottomCenter,
                                                                    end: Alignment.topCenter,
                                                                    colors: [Colors.blueAccent, Colors.purpleAccent]
                                                                )
                                                                    : null,
                                                                borderRadius: BorderRadius.circular(30),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),

                                                // 2. Custom Tooltip UI (Only show if value > 0)
                                                Positioned(
                                                  bottom: (value / maxVal) * (chartHeight - 60) + 10,
                                                  child: Visibility(
                                                    visible: selectedIndex == index && value > 0,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(6),
                                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                                                          ),
                                                          child: Text(
                                                            "${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}h",
                                                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        CustomPaint(size: const Size(10, 5), painter: DrawTriangleShape()),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8 * SizeConfigs.paddingScale),
                                          Text(
                                            label,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: value > 0 ? Colors.white70 : Colors.white24, // Label color based on data
                                                fontSize: 10.5 * SizeConfigs.textScale,
                                                fontWeight: FontWeight.w400
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }

                            return SizedBox(
                              height: chartHeight,
                              child: isMonthly ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: buildRow()) : buildRow(),
                            );
                          }),
                          SizedBox(height: 15 * SizeConfigs.paddingScale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, color: AppColors.textBoldColor, size: 20 * SizeConfigs.textScale),
                              SizedBox(width: 6 * SizeConfigs.paddingScale),
                              Text(
                                context.lang.tapBarsForDetails,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).paddingSymmetric(horizontal: 18 * SizeConfigs.paddingScale),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),
                    _buildPremiumBannerCarousel(context),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.recentlyUpdate,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "💖",
                      onSeeAllTap: () {
                        final dashboardController = Get.find<DashboardController>();
                        final sleepSoundController = Get.find<SleepSoundController>();
                        sleepSoundController.setJumpArguments(jumpTab: "white-noise", jumpFilter: "__all__");
                        // 2. Switch Tab (MISSING IN YOUR PREVIOUS CODE)
                        dashboardController.changeTab(1);
                      },
                    ),
                    SizedBox(height: 6),
                    _buildRecentlyUpdated(context, textTheme),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.featured,
                      Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                      showSeeAll: false,
                      emoji: '🌙',
                      onSeeAllTap: () {
                        final dashboardController = Get.find<DashboardController>();
                        final sleepSoundController = Get.find<SleepSoundController>();
                        sleepSoundController.setJumpArguments(jumpTab: "music", jumpFilter: "__all__");
                        // 2. Switch Tab
                        dashboardController.changeTab(1);
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: Text(context.lang.theBestSleepAidsYouCanMiss, style: textTheme.bodyMedium),
                    ),

                    SizedBox(height: 6),
                    _buildFeatured(context, textTheme),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.sleeppedia,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: '💤',
                      onSeeAllTap: () {
                        Get.toNamed(Routes.sleepInfo);
                      },
                    ),
                    SizedBox(height: 6),
                    _buildSleeppedia(context),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.healingMusic,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "🎵",
                      onSeeAllTap: () {
                        final dashboardController = Get.find<DashboardController>();
                        final sleepSoundController = Get.find<SleepSoundController>();
                        sleepSoundController.setJumpArguments(jumpTab: "music", jumpFilter: "__all__");
                        // 2. Switch Tab
                        dashboardController.changeTab(1);
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: Text(context.lang.deepHealingMusicBody, style: textTheme.bodyMedium),
                    ),
                    SizedBox(height: 6),
                    _buildHealingMusic(context, textTheme),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.sleepStory,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "🎵",
                      onSeeAllTap: () {
                        final dashboardController = Get.find<DashboardController>();
                        final sleepSoundController = Get.find<SleepSoundController>();
                        sleepSoundController.setJumpArguments(jumpTab: "story", jumpFilter: "__all__");
                        // 2. Switch Tab
                        dashboardController.changeTab(1);
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: Text(context.lang.sayGoodbyeSleeplessNightsWithSleepStory, style: textTheme.bodyMedium),
                    ),
                    SizedBox(height: 6),
                    _buildSleepStory(context, textTheme),
                    SizedBox(height: 15),
                    _buildSectionHeader(context,
                      context.lang.sleepMeditation,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "🎵",
                      onSeeAllTap: () {
                        final dashboardController = Get.find<DashboardController>();
                        final sleepSoundController = Get.find<SleepSoundController>();
                        sleepSoundController.setJumpArguments(jumpTab: "music", jumpFilter: "__all__");
                        // 2. Switch Tab
                        dashboardController.changeTab(1);
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: Text(context.lang.aGuidedSleepMeditationWorriesTroublesFallAsleepFast, style: textTheme.bodyMedium),
                    ),
                    SizedBox(height: 6),
                    _buildSleepMeditation(context, textTheme),

                    /// 🔹 Profiles section

                    Obx(() {
                      // If the token is empty, we show the login/account prompt
                      if (controller.token.isEmpty) {
                        return Column(
                          children: [
                            SizedBox(height: 15 * SizeConfigs.paddingScale),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                              child: _accountCard(context),
                            ),
                          ],
                        );
                      }

                      // If the token is NOT empty (User is logged in), return an empty space or nothing
                      return const SizedBox.shrink();
                    }),
                    // SizedBox(height: 15 * SizeConfigs.paddingScale),

                    // /// 🔹 Welcome banner
                    // _welcomeBanner(context),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),
                    _buildSectionHeader(context,
                      context.lang.sleepQuiz,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "🤖",
                      onSeeAllTap: () {
                        Get.toNamed(
                          Routes.sleepInfo,
                          arguments: {
                            'tabIndex': 1, // 👈 open SleepQuiz tab
                          },
                        );
                        Get.toNamed(Routes.sleepInfo);
                      },
                      showSeeAll: true,
                    ),
                    SizedBox(height: 6 * SizeConfigs.paddingScale),
                    SizedBox(
                      height: 160 * SizeConfigs.paddingScale,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.sleepQuizzes.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12 * SizeConfigs.paddingScale),
                        itemBuilder: (context, index) {
                          final item = controller.sleepQuizzes[index];
                          return _quizCard(context, item, index, controller.sleepQuizzes.length);
                        },
                      ),
                    ),

                    SizedBox(height: 15 * SizeConfigs.paddingScale),
                    _buildSectionHeader(context,
                      context.lang.dailyQuote,
                      Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
                      emoji: "🌻",
                      showSeeAll: false,
                    ),
                    SizedBox(height: 15 * SizeConfigs.paddingScale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: _buildDailyQuote(context),
                    ),

                    SizedBox(height: 180 * SizeConfigs.paddingScale),
                  ],
                ),
              ),
              // ),
            ),

            /// FIXED BOTTOM MIX BAR
            Obx(() {
              return Positioned(
                left: controller.buttonX.value,
                top: controller.buttonY.value,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final size = MediaQuery.of(context).size;

                    controller.buttonX.value = (controller.buttonX.value + details.delta.dx).clamp(0.0, size.width - 60);

                    controller.buttonY.value = (controller.buttonY.value + details.delta.dy).clamp(0.0, size.height - 190 - 60);
                  },

                  child: MixBarWidget(isFromHome: true),
                ),
              );
            }),
          ],
        ),
      );}),

    );
  }

  Widget _buildPremiumBannerCarousel(BuildContext context) {
    final controller = PageController(viewportFraction: 0.9);
    final RxInt currentPage = 0.obs;

    // Controllers initialize karein

    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      final List<Map<String, dynamic>> allBanners = [
        {
          'id': 'premium',
          'title': context.lang.sleepablePremium,
          'subtitle': context.lang.unlockAllFeatures,
          'color': Colors.blue,
          'icon': Icons.workspace_premium
        },
        {
          'id': 'dreambot',
          'title': context.lang.dreamBotTitle,
          'subtitle': context.lang.visualizeImagination,
          'color': Colors.indigo,
          'icon': Icons.auto_fix_high_rounded,
        },
        {
          'id': 'therapy',
          'title': context.lang.soundTherapy,
          'subtitle': context.lang.calmMindWithMusic,
          'color': Colors.teal,
          'icon': Icons.music_note_rounded
        },
      ];
      // Filter logic: Agar isPremium true hai, toh 'premium' id wala banner hata do
      final banners = subController.isPremium.value
          ? allBanners.where((b) => b['id'] != 'premium').toList()
          : allBanners;

      // Agar saare banners khatam ho jayein (safety check)
      if (banners.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 110 * SizeConfigs.paddingScale,
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              onPageChanged: (index) => currentPage.value = index,
              itemBuilder: (context, index) {
                final item = banners[index];
                return GestureDetector(
                  onTap: () {
                    // ID ke basis par navigation handle karein (zyada safe hai)
                    if (item['id'] == 'premium') {
                      final homeController = Get.put(HomeController());
                      homeController.showRotatingPremiumSheet(context);
                    } else if (item['id'] == 'dreambot') {
                      Get.toNamed(
                        Routes.dreamBot,
                        parameters: {"fromProgress": "true", "dreamId": "0"},
                      );
                    } else if (item['id'] == 'therapy') {
                      final dashboardController = Get.find<DashboardController>();
                      final sleepSoundController = Get.find<SleepSoundController>();
                      sleepSoundController.setJumpArguments(jumpTab: "white-noise", jumpFilter: "__all__");
                      dashboardController.changeTab(1);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
                    decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(30)
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'].toString(),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 21 * SizeConfigs.textScale,
                                    fontWeight: FontWeight.w600
                                ),
                              ),
                              SizedBox(height: 6 * SizeConfigs.paddingScale),
                              Text(
                                item['subtitle'].toString(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 14 * SizeConfigs.textScale
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(item['icon'] as IconData, color: Colors.amberAccent, size: 42 * SizeConfigs.paddingScale),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10 * SizeConfigs.paddingScale),

          /// Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final bool isActive = currentPage.value == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 10 * SizeConfigs.paddingScale : 6 * SizeConfigs.paddingScale,
                height: 6 * SizeConfigs.paddingScale,
                decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3)
                ),
              );
            }),
          ),
        ],
      );
    });
  }
  Widget _buildSectionHeader(BuildContext context,String title, TextStyle textStyle, {String? emoji, bool showSeeAll = true, VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
      child: Row(
        children: [
          /// LEFT SIDE (emoji + title)
          Expanded(
            child: Row(
              children: [
                if (emoji != null) Text(emoji, style: TextStyle(fontSize: 22 * SizeConfigs.textScale)),
                if (emoji != null) const SizedBox(width: 6),

                /// TITLE (MARQUEE / TEXT)
                Expanded(
                  child: Marquee(
                    child: Text(title, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),

          /// RIGHT SIDE (SEE ALL)
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                context.lang.seeAll,// 'See All',
                style: textStyle.copyWith(color: Colors.blueAccent, fontSize: 16 * SizeConfigs.textScale),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentlyUpdated(BuildContext context, TextTheme textTheme) {
    final width = MediaQuery.of(context).size.width;
    final isSmallPhone = width < 380;
    final imageHeight = isSmallPhone ? 160.0 : 180.0;
    final cardWidth = width * 0.4;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());
    // 1. Get the Sleep Sound Controller to manage playback
    final sleepController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

    return Obx(() {
      final list = controller.homeData.value?.data?.recentSounds ?? [];

      if (list.isEmpty) {
        return Container(
          height: imageHeight,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(child: Icon(Icons.music_note, color: Colors.white24)),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(list.length, (index) {
            final item = list[index];
            final imageUrl = "$BASE_URL2${item.image}";

            final String rawType = item.type?.toLowerCase() ?? "music";
            return Obx(() {
              // 2. Check if this specific item is currently playing
              final isPlaying = sleepController.playingMusic.any((m) => m.id == item.id) || sleepController.playingSounds.any((s) => s.id == item.id);
              final isActuallyPlaying = isPlaying && !sleepController.isPaused.value;

              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 18 : 0),
                decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// --- IMAGE + LABELS ---
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 3. Premium Paywall Check
                            if (item.isPremium && subController.isPremium.value == false) {
                              // 1. Check karein ki user ne pehle hi spin wheel use kiya hai ya nahi
                              final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                              if (hasAlreadySpun) {
                                // ✅ Agar spin ho gaya hai -> Seedha discounted offer dikhao
                                // showPremiumOfferSheet6(context);
                                controller.showRotatingPremiumSheet(context);
                              } else {
                                // ❌ Agar spin nahi hua -> Default premium sheet dikhao
                                showPremiumOfferSheet4(context);
                              }
                              return;
                            }


                            final soundObj = SoundItem(
                              id: item.id,
                              name: item.name,
                              image: imageUrl,
                              file: item.file ?? "",
                              categoryName: rawType == "music"
                                  ? (Get.context?.lang.musicLabel ?? "Music")
                                  : (rawType == "story"
                                  ? (Get.context?.lang.storyLabel ?? "Story")
                                  : (item.type ?? "Music")),
                              subcategoryName: item.subcategory ?? "",
                              duration: item.duration,
                              isPremium: item.isPremium,

                              // 🔥 The missing/extra parameters cleanly formatted:
                              isFavorite: Get.isRegistered<SleepSoundController>()
                                  ? Get.find<SleepSoundController>().lookupFavorite(item.id)
                                  : false,
                              isNew: item.isNew,
                              // Map directly from HomeSoundItem
                              subcategory: item.subcategory ?? "",
                              // Map directly from HomeSoundItem
                              slug: '', // Empty string since Home API doesn't send a slug
                            );
                            final isMusicOrStory = item.type?.toLowerCase() == "music" || item.type?.toLowerCase() == "story";

                            if (isMusicOrStory) {
                              // 5a. If already playing, just pause
                              if (isPlaying) {
                                sleepController.togglePause();
                                return;
                              }

                              // 5b. Open Full Player UI if nothing is playing yet
                              if (sleepController.playingSounds.isEmpty) {
                                if (!sleepController.isAnyPlayerVisible.value) {
                                  sleepController.isAnyPlayerVisible.value = true;
                                  Get.bottomSheet(PlayerFullSheetUI(sound: soundObj), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                    sleepController.isAnyPlayerVisible.value = false;
                                  });
                                }
                              }

                              // 5c. Actually trigger the music to play
                              sleepController.toggleMusic(soundObj);
                            } else {
                              // 6. Treat as Ambient Sound (Mixes/Noise)
                              sleepController.toggleSound(soundObj);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            // Add a subtle blue glow when playing
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: imageHeight,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image, color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// "NEW" Tag
                        if (item.isNew)
                          Positioned(
                            top: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                context.lang.newTag,
                                style: textTheme.bodySmall?.copyWith(color: Colors.white, fontSize: 8 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                        /// 🟢 Lock Icon (Shows if Premium)
                        if (item.isPremium && subController.isPremium.value == false)
                          Positioned(
                            top: 12,
                            right: 16,
                            child: Icon(Icons.lock, color: AppColors.white, size: 20),
                          ),
                        /// 🟢 Play/Pause Overlay (Shows if Active)
                        if (isPlaying)
                          Positioned(
                            bottom: 10,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                              child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            ),
                          ),

                        /// Duration tag
                        if (!isPlaying) // Hide duration if the play button is showing to avoid clutter
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                sleepController.formatDuration(item.duration), // Formats 646 to 10:46
                                style: textTheme.bodySmall?.copyWith(color: Colors.white, fontSize: 9 * SizeConfigs.textScale),
                              ),
                            ),
                          ),
                      ],
                    ),

                    /// --- DETAILS ---
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              color: isPlaying ? Colors.blueAccent : AppColors.white, // Highlight title if playing
                              fontSize: 14 * SizeConfigs.textScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subcategory ?? (rawType == "music" ? context.lang.musicLabel : (rawType == "story" ? context.lang.storyLabel : rawType)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(fontSize: 12 * SizeConfigs.textScale, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            });
          }),
        ),
      );
    });
  }

  Widget _buildFeatured(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final imageHeight = isSmallPhone ? 170.0 : 210.0;
    final cardWidth = size.width * 0.85;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());
    return Obx(() {
      // 1. Get the list of featured sounds (Stories)
      final featuredList = controller.homeData.value?.data?.featuredSounds ?? [];

      if (featuredList.isEmpty) return const SizedBox.shrink();
      // 2. Get the Sleep Sound Controller to manage playback
      final sleepController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * SizeConfigs.paddingScale),
        child: SizedBox(
          height: imageHeight + 75, // Space for image + title/subtitle
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredList.length,
            padding: const EdgeInsets.only(left: 18, right: 8),
            itemBuilder: (context, index) {
              final item = featuredList[index];
              final String imageUrl = "$BASE_URL2${item.image ?? item.thumbnail ?? ""}";

              final String rawType = item.type ?? "Story";
              // 3. Wrap individual item in Obx to react to play/pause state
              return Obx(() {
                final isPlaying = sleepController.playingMusic.any((m) => m.id == item.id) || sleepController.playingSounds.any((s) => s.id == item.id);
                final isActuallyPlaying = isPlaying && !sleepController.isPaused.value;

                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: AppColors.transparent, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// --- IMAGE + LABELS ---
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.isPremium && subController.isPremium.value == false) {
                                // 1. Check karein ki user ne pehle hi spin wheel use kiya hai ya nahi
                                final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                if (hasAlreadySpun) {
                                  // ✅ Agar spin ho gaya hai -> Seedha discounted offer dikhao
                                  // showPremiumOfferSheet6(context);
                                  controller.showRotatingPremiumSheet(context);
                                } else {
                                  // ❌ Agar spin nahi hua -> Default premium sheet dikhao
                                  showPremiumOfferSheet4(context);
                                }
                                return;
                              }
                              // 5. Map HomeSoundItem to SoundItem for the player
                              final soundObj = SoundItem(
                                id: item.id,
                                name: item.name,
                                image: imageUrl,
                                file: item.file ?? "",
                                // The audio path from JSON
                                // categoryName: item.type ?? "Story",
                                categoryName: rawType == "Story"
                                    ? context.lang.storyLabel
                                    : (rawType.toLowerCase() == "music"
                                    ? context.lang.musicLabel
                                    : rawType),
                                // Usually "Story" here
                                subcategoryName: item.subcategory ?? "",
                                duration: item.duration,
                                isPremium: item.isPremium,
                                isFavorite: Get.isRegistered<SleepSoundController>()
                                  ? Get.find<SleepSoundController>().lookupFavorite(item.id)
                                  : false,
                                isNew: item.isNew,
                                subcategory: item.subcategory ?? "",
                                slug: '',
                              );

                              final isMusicOrStory = item.type?.toLowerCase() == "music" || item.type?.toLowerCase() == "story";

                              if (isMusicOrStory) {
                                // 6a. If already playing, just pause
                                if (isPlaying) {
                                  sleepController.togglePause();
                                  return;
                                }

                                // 6b. Open Full Player UI if nothing is playing
                                if (sleepController.playingSounds.isEmpty) {
                                  if (!sleepController.isAnyPlayerVisible.value) {
                                    sleepController.isAnyPlayerVisible.value = true;
                                    Get.bottomSheet(PlayerFullSheetUI(sound: soundObj), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                      sleepController.isAnyPlayerVisible.value = false;
                                    });
                                  }
                                }

                                // 6c. Trigger the audio to play
                                sleepController.toggleMusic(soundObj);
                              } else {
                                // Treat as Ambient Sound
                                sleepController.toggleSound(soundObj);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              // 🔥 Add a subtle blue glow when playing
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(24)),
                                boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(24)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: imageHeight,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.white10),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image, color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// "NEW" tag
                          if (item.isNew)
                            Positioned(
                              top: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  context.lang.newTag,
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                          /// 🔥 Play/Pause Overlay (Shows if Active)
                          if (isPlaying)
                            Positioned(
                              bottom: 8,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                              ),
                            ),

                          /// Duration tag - Formatting via controller
                          if (!isPlaying) // Hide duration if the play button is showing
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  sleepController.formatDuration(item.duration), // Formats properly
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 8.5),
                                ),
                              ),
                            ),
                        ],
                      ),

                      /// --- DETAILS SECTION ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(Assets.homeSleepableAppIcon, width: isSmallPhone ? 35 : 40, height: isSmallPhone ? 35 : 40, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: isPlaying ? Colors.blueAccent : AppColors.white, // Highlight title if playing
                                      fontSize: 14 * SizeConfigs.textScale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.subcategory ?? (rawType == "Story" ? context.lang.storyLabel : rawType),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),

                            // 🔹 Lock Icon for Premium Content
                            if (item.isPremium && subController.isPremium.value == false)// Assuming isPremium controls locks
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 2),
                                child: Icon(Icons.lock, color: Colors.amber.withOpacity(0.8), size: 16),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      );
    });
  }


  Widget _buildSleeppedia(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final cardHeight = isSmallPhone ? 70.0 : 75.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
      child: Column(
        // item is now a SleeppediaItem object
        children: controller.dashboardSleeppedia.map((item) {
          return GestureDetector(
            onTap: () {
              // Navigates directly to the detail view using the object
              Get.to(() => SleeppediaDetailView(item: item));
            },
            child: Container(
              height: cardHeight * SizeConfigs.paddingScale,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.card.withOpacity(0.98), borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ✅ FIXED: Use item.image instead of item['image']
                          Image.asset(item.image, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.card.withOpacity(0.98), Colors.transparent]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * SizeConfigs.paddingScale, vertical: 14 * SizeConfigs.paddingScale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                // ✅ FIXED: Use item.title instead of item['title']
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                              ),
                              // Only check for subtitle if your model has that field.
                              // If it doesn't exist in SleeppediaItem, this block can be removed.
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealingMusic(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final imageHeight = isSmallPhone ? 160.0 : 180.0;
    final cardWidth = size.width * 0.42;
    final containerHeight = imageHeight + 80;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      // 🔥 Accessing the items list from the SoundSection object
      final section = controller.homeData.value?.data?.healingSounds;
      final list = section?.items ?? [];

      if (list.isEmpty) return const SizedBox.shrink();
      // 1. Get the Sleep Sound Controller to manage playback
      final sleepController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = list[index];
                final String imageUrl = "$BASE_URL2${item.image ?? ""}";
                final String rawType = item.type ?? "Healing Music";

                // 2. Wrap individual item in Obx to react to play/pause state
                return Obx(() {
                  final isPlaying = sleepController.playingMusic.any((m) => m.id == item.id) || sleepController.playingSounds.any((s) => s.id == item.id);
                  final isActuallyPlaying = isPlaying && !sleepController.isPaused.value;

                  return Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: 12, left: index == 0 ? 18 : 0),
                    decoration: BoxDecoration(color: AppColors.transparent, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// --- IMAGE STACK ---
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // 3. Premium Paywall Check
                                if (item.isPremium && subController.isPremium.value == false) {
                                  // 1. Check karein ki user ne pehle hi spin wheel use kiya hai ya nahi
                                  final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                  if (hasAlreadySpun) {
                                    // ✅ Agar spin ho gaya hai -> Seedha discounted offer dikhao
                                    // showPremiumOfferSheet6(context);
                                    controller.showRotatingPremiumSheet(context);
                                  } else {
                                    // ❌ Agar spin nahi hua -> Default premium sheet dikhao
                                    showPremiumOfferSheet4(context);
                                  }
                                  return;
                                }

                                // 4. Map HomeSoundItem to SoundItem for the player
                                final soundObj = SoundItem(
                                  id: item.id,
                                  name: item.name,
                                  image: imageUrl,
                                  file: item.file ?? "",
                                  // The audio path from JSON
                                  // categoryName: item.type ?? "Healing Music",
                                  categoryName: rawType == "Healing Music"
                                      ? context.lang.healingMusic
                                      : (rawType.toLowerCase() == "music"
                                      ? context.lang.musicLabel
                                      : (rawType.toLowerCase() == "story"
                                      ? context.lang.storyLabel
                                      : rawType)),
                                  subcategoryName: item.subcategory ?? "",
                                  duration: item.duration,
                                  isPremium: item.isPremium,
                                  isFavorite: Get.isRegistered<SleepSoundController>()
                                  ? Get.find<SleepSoundController>().lookupFavorite(item.id)
                                  : false,
                                  isNew: item.isNew,
                                  subcategory: item.subcategory ?? "",
                                  slug: '',
                                );

                                final isMusicOrStory = item.type?.toLowerCase() == "music" || item.type?.toLowerCase() == "story";

                                if (isMusicOrStory || soundObj.categoryName == "Healing Music") {
                                  // 5a. If already playing, just pause
                                  if (isPlaying) {
                                    sleepController.togglePause();
                                    return;
                                  }

                                  // 5b. Open Full Player UI if nothing is playing
                                  if (sleepController.playingSounds.isEmpty) {
                                    if (!sleepController.isAnyPlayerVisible.value) {
                                      sleepController.isAnyPlayerVisible.value = true;
                                      Get.bottomSheet(PlayerFullSheetUI(sound: soundObj), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                        sleepController.isAnyPlayerVisible.value = false;
                                      });
                                    }
                                  }

                                  // 5c. Trigger the audio to play
                                  sleepController.toggleMusic(soundObj);
                                } else {
                                  // Treat as Ambient Sound
                                  sleepController.toggleSound(soundObj);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                // 🔥 Add a subtle blue glow when playing
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: imageHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white10),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.white10,
                                      child: const Icon(Icons.broken_image, color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// 🟢 Lock Icon (Shows if Premium)
                            if (item.isPremium && subController.isPremium.value == false) Positioned(top: 12, right: 16, child: Icon(Icons.lock, color: AppColors.white, size: 20)),

                            /// 🟢 Play/Pause Overlay (Shows if Active)
                            if (isPlaying)
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                  child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                ),
                              ),

                            /// Duration tag
                            if (!isPlaying) // Hide duration if the play button is showing to avoid UI clutter
                              Positioned(
                                bottom: 10,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.cardColor.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                                  child: Text(
                                    sleepController.formatDuration(item.duration), // Formats 646 to 10:46
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 8.5 * SizeConfigs.textScale),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        /// --- TEXT DETAILS ---
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  color: isPlaying ? Colors.blueAccent : AppColors.white, // Highlight title if playing
                                  fontSize: 12 * SizeConfigs.textScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                // item.subcategory ?? item.type ?? "",
                                item.subcategory ?? (rawType == "Healing Music" ? context.lang.healingMusic : rawType),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSleepStory(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final imageHeight = isSmallPhone ? 170.0 : 210.0;
    final cardWidth = size.width * 0.85;
    final containerHeight = imageHeight + 80;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      // 🔥 Get the sleepStory object and its nested items list
      final section = controller.homeData.value?.data?.sleepStory;
      final list = section?.items ?? [];

      if (list.isEmpty) return const SizedBox.shrink();
      // 1. Get the Sleep Sound Controller to manage playback
      final sleepController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = list[index];
                final String imageUrl = "$BASE_URL2${item.image ?? ""}";
                final String rawType = item.type ?? "Story";

                // 2. Wrap individual item in Obx to react to play/pause state
                return Obx(() {
                  final isPlaying = sleepController.playingMusic.any((m) => m.id == item.id) || sleepController.playingSounds.any((s) => s.id == item.id);
                  final isActuallyPlaying = isPlaying && !sleepController.isPaused.value;

                  return Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: 12, left: index == 0 ? 18 : 0),
                    decoration: BoxDecoration(color: AppColors.transparent, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// --- IMAGE STACK ---
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // 3. Premium Paywall Check
                                if (item.isPremium && subController.isPremium.value == false) {
                                  // 1. Check karein ki user ne pehle hi spin wheel use kiya hai ya nahi
                                  final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                  if (hasAlreadySpun) {
                                    // ✅ Agar spin ho gaya hai -> Seedha discounted offer dikhao
                                    // showPremiumOfferSheet6(context);
                                    controller.showRotatingPremiumSheet(context);
                                  } else {
                                    // ❌ Agar spin nahi hua -> Default premium sheet dikhao
                                    showPremiumOfferSheet4(context);
                                  }
                                  return;
                                }

                                // 4. Map HomeSoundItem to SoundItem for the player
                                final soundObj = SoundItem(
                                  id: item.id,
                                  name: item.name,
                                  image: imageUrl,
                                  file: item.file ?? "",
                                  // The audio path from JSON
                                  // categoryName: item.type ?? "Story",
                                  categoryName: rawType == "Story"
                                      ? context.lang.storyLabel
                                      : (rawType.toLowerCase() == "music"
                                      ? context.lang.musicLabel
                                      : rawType),
                                  subcategoryName: item.subcategory ?? "",
                                  duration: item.duration,
                                  isPremium: item.isPremium,
                                  isFavorite: Get.isRegistered<SleepSoundController>()
                                  ? Get.find<SleepSoundController>().lookupFavorite(item.id)
                                  : false,
                                  isNew: item.isNew,
                                  subcategory: item.subcategory ?? "",
                                  slug: '',
                                );

                                final isMusicOrStory = item.type?.toLowerCase() == "music" || item.type?.toLowerCase() == "story";

                                if (isMusicOrStory || soundObj.categoryName == "Story") {
                                  // 5a. If already playing, just pause
                                  if (isPlaying) {
                                    sleepController.togglePause();
                                    return;
                                  }

                                  // 5b. Open Full Player UI if nothing is playing
                                  if (sleepController.playingSounds.isEmpty) {
                                    if (!sleepController.isAnyPlayerVisible.value) {
                                      sleepController.isAnyPlayerVisible.value = true;
                                      Get.bottomSheet(PlayerFullSheetUI(sound: soundObj), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                        sleepController.isAnyPlayerVisible.value = false;
                                      });
                                    }
                                  }

                                  // 5c. Trigger the audio to play
                                  sleepController.toggleMusic(soundObj);
                                } else {
                                  // Treat as Ambient Sound
                                  sleepController.toggleSound(soundObj);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                // 🔥 Add a subtle blue glow when playing
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: imageHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white10),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.white10,
                                      child: const Icon(Icons.broken_image, color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// 🟢 Lock Icon (Shows if Premium)
                            if (item.isPremium && subController.isPremium.value == false) Positioned(top: 12, right: 16, child: const Icon(Icons.lock, color: Colors.white, size: 20)),

                            /// 🟢 Play/Pause Overlay (Shows if Active)
                            if (isPlaying)
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                  child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                ),
                              ),

                            /// Duration tag
                            if (!isPlaying) // Hide duration if the play button is showing
                              Positioned(
                                bottom: 10,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.cardColor.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                                  child: Text(
                                    sleepController.formatDuration(item.duration), // Formats properly
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 8.5 * SizeConfigs.textScale),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        /// --- DETAILS ---
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  color: isPlaying ? Colors.blueAccent : AppColors.white, // Highlight title if playing
                                  fontSize: 12 * SizeConfigs.textScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                // item.subcategory ?? item.type ?? "",
                                item.subcategory ?? (rawType == "Story" ? context.lang.storyLabel : rawType),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSleepMeditation(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final imageHeight = isSmallPhone ? 160.0 : 180.0;
    final cardWidth = size.width * 0.42;
    final containerHeight = imageHeight + 80;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      // 🔥 Access the sleepMeditation object and its nested items list
      final section = controller.homeData.value?.data?.sleepMeditation;
      final list = section?.items ?? [];

      if (list.isEmpty) return const SizedBox.shrink();
      final sleepController = Get.isRegistered<SleepSoundController>() ? Get.find<SleepSoundController>() : Get.put(SleepSoundController());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = list[index];
                final String imageUrl = "$BASE_URL2${item.image ?? ""}";

                final String rawType = item.type ?? "Meditation";
                // 2. Wrap individual item in Obx to react to play/pause state
                return Obx(() {
                  final isPlaying = sleepController.playingMusic.any((m) => m.id == item.id) || sleepController.playingSounds.any((s) => s.id == item.id);
                  final isActuallyPlaying = isPlaying && !sleepController.isPaused.value;

                  return Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: 12, left: index == 0 ? 18 : 0),
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// --- IMAGE STACK ---
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {

                                // 3. Premium Paywall Check
                                if (item.isPremium && subController.isPremium.value == false) {
                                  // 1. Check karein ki user ne pehle hi spin wheel use kiya hai ya nahi
                                  final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                                  if (hasAlreadySpun) {
                                    // ✅ Agar spin ho gaya hai -> Seedha discounted offer dikhao
                                    // showPremiumOfferSheet6(context);
                                    controller.showRotatingPremiumSheet(context);
                                  } else {
                                    // ❌ Agar spin nahi hua -> Default premium sheet dikhao
                                    showPremiumOfferSheet4(context);
                                  }
                                  return;
                                }
                                // 4. Map HomeSoundItem to SoundItem for the player
                                final soundObj = SoundItem(
                                  id: item.id,
                                  name: item.name,
                                  image: imageUrl,
                                  file: item.file ?? "",
                                  // The audio path from JSON
                                  // categoryName: item.type ?? "Meditation",
                                  categoryName: rawType == "Meditation"
                                      ? context.lang.meditationLabel
                                      : (rawType.toLowerCase() == "music"
                                      ? context.lang.musicLabel
                                      : (rawType.toLowerCase() == "story"
                                      ? context.lang.storyLabel
                                      : rawType)),
                                  subcategoryName: item.subcategory ?? "",
                                  duration: item.duration,
                                  isPremium: item.isPremium,
                                  isFavorite: Get.isRegistered<SleepSoundController>()
                                  ? Get.find<SleepSoundController>().lookupFavorite(item.id)
                                  : false,
                                  isNew: item.isNew,
                                  subcategory: item.subcategory ?? "",
                                  slug: '',
                                );

                                final isMusicOrStory = item.type?.toLowerCase() == "music" || item.type?.toLowerCase() == "story";

                                if (isMusicOrStory || soundObj.categoryName == "Meditation") {
                                  // 5a. If already playing, just pause
                                  if (isPlaying) {
                                    sleepController.togglePause();
                                    return;
                                  }

                                  // 5b. Open Full Player UI if nothing is playing
                                  if (sleepController.playingSounds.isEmpty) {
                                    if (!sleepController.isAnyPlayerVisible.value) {
                                      sleepController.isAnyPlayerVisible.value = true;
                                      Get.bottomSheet(PlayerFullSheetUI(sound: soundObj), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent).whenComplete(() {
                                        sleepController.isAnyPlayerVisible.value = false;
                                      });
                                    }
                                  }

                                  // 5c. Trigger the audio to play
                                  sleepController.toggleMusic(soundObj);
                                } else {
                                  // Treat as Ambient Sound
                                  sleepController.toggleSound(soundObj);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                // 🔥 Add a subtle blue glow when playing
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  boxShadow: isPlaying ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)] : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: imageHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white10),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.white10,
                                      child: const Icon(Icons.broken_image, color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// 🟢 Lock Icon (Shows if Premium)
                            if (item.isPremium && subController.isPremium.value == false) Positioned(top: 12, right: 16, child: const Icon(Icons.lock, color: Colors.white, size: 20)),

                            /// 🟢 Play/Pause Overlay (Shows if Active)
                            if (isPlaying)
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                  child: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                ),
                              ),

                            /// Duration tag
                            if (!isPlaying) // Hide duration if the play button is showing to avoid UI clutter
                              Positioned(
                                bottom: 10,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                                  child: Text(
                                    sleepController.formatDuration(item.duration), // Beautiful format (e.g. 15:00)
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 8.5 * SizeConfigs.textScale),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        /// --- TEXT DETAILS ---
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  color: isPlaying ? Colors.blueAccent : Colors.white, // Highlight title if playing
                                  fontSize: 12 * SizeConfigs.textScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                // item.subcategory ?? item.type ?? "Meditation",
                                  item.subcategory ?? (rawType == "Meditation" ? context.lang.meditationLabel : rawType),

                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSoundscape(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final imageHeight = isSmallPhone ? 160.0 : 180.0;
    final cardWidth = size.width * 0.42;
    final containerHeight = imageHeight + 80;

    return Obx(() {
      // 🔥 Access the soundScape object and its nested items list
      final section = controller.homeData.value?.data?.soundScape;
      final list = section?.items ?? [];

      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = list[index];
                const String baseUrl = "https://api.sleepable.ai";
                final String imageUrl = "$BASE_URL2${item.image ?? ""}";

                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: 12, left: index == 0 ? 18 : 0),
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// --- IMAGE STACK ---
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Get.toNamed(Routes.player, arguments: item),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(30)),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                height: imageHeight,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image, color: Colors.white24),
                                ),
                              ),
                            ),
                          ),

                          /// "NEW" Tag - Dynamic based on API boolean
                          if (item.isNew)
                            Positioned(
                              top: 12,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30)),
                                child: Text(
                                  'NEW',
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8.5 * SizeConfigs.textScale),
                                ),
                              ),
                            ),

                          /// Duration tag
                          Positioned(
                            bottom: 10,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.cardColor.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                "${item.duration}s",
                                style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 8.5 * SizeConfigs.textScale),
                              ),
                            ),
                          ),

                          /// Lock Icon (Optional: if soundscapes can be premium)
                          if (item.isLocked) Positioned(top: 12, right: 16, child: const Icon(Icons.lock, color: Colors.white, size: 20)),
                        ],
                      ),

                      /// --- TEXT DETAILS ---
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              item.subcategory ?? item.type ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }



  Widget _sectionSoundScenes(BuildContext context, TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final cardWidth = isSmallPhone ? 135.0 : 150.0;

    return Obx(() {
      // 🔥 Get data from API model
      final section = controller.homeData.value?.data?.soundScenes;
      final list = section?.items ?? [];

      if (list.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * SizeConfigs.paddingScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 190 * SizeConfigs.paddingScale, // Adjusted height for the grid + text
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                padding: const EdgeInsets.only(left: 18),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = list[index];
                  // const String baseUrl = "https://api.sleepable.ai";
                  final String imageUrl = "$BASE_URL2${item.image ?? ""}";

                  return GestureDetector(
                    onTap: () {}, //=> Get.toNamed(Routes.player, arguments: item),
                    child: Container(
                      width: cardWidth * SizeConfigs.paddingScale,
                      margin: EdgeInsets.only(right: 12 * SizeConfigs.paddingScale),
                      padding: EdgeInsets.only(left: 12 * SizeConfigs.paddingScale, right: 12 * SizeConfigs.paddingScale, bottom: 14 * SizeConfigs.paddingScale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.05)), // Added subtle border
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.02), Colors.white.withOpacity(0.01)]),
                      ),
                      // decoration: BoxDecoration(
                      //     color: const Color(0xFF101830),
                      //     borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ✅ THE OLD 2x2 GRID UI (Updated for API Images)
                          GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.only(top: 1 * SizeConfigs.paddingScale),
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8 * SizeConfigs.paddingScale, mainAxisSpacing: 8 * SizeConfigs.paddingScale),
                            itemCount: 4,
                            // Fixed 4 slots like your old UI
                            itemBuilder: (context, i) {
                              return Container(
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(40 * SizeConfigs.paddingScale)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(35 * SizeConfigs.paddingScale),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    // Shimmer or placeholder
                                    placeholder: (context, url) => Container(color: Colors.white10),
                                    errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white24, size: 20),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 10 * SizeConfigs.paddingScale),

                          // API Title
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                          ),

                          // API Subtitle (Subcategory or Type)
                          Text(
                            item.subcategory ?? item.type ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(fontSize: 11 * SizeConfigs.textScale, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _accountCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final titleFontSize = isSmallPhone ? 19.0 : 21.0;
    final descFontSize = isSmallPhone ? 11.0 : 12.0;
    final buttonPaddingH = isSmallPhone ? 24.0 : 28.0;
    final buttonPaddingV = isSmallPhone ? 8.0 : 10.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(color: const Color(0xFF162039), borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)),
      child: Column(
        children: [
          Text(
            "${context.lang.sleepableAccount} ✨",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: titleFontSize * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
          ),
          SizedBox(height: 6 * SizeConfigs.paddingScale),
          Text(
            context.lang.createAccountKeepSafeAcrossDevicesFavoritesContents,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: descFontSize * SizeConfigs.textScale, fontWeight: FontWeight.w500) ?? const TextStyle(),
          ),
          SizedBox(height: 14 * SizeConfigs.paddingScale),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)),
            ),
            onPressed: () {
              Get.toNamed(Routes.login);
            },
            child: Text(context.lang.logIn, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _welcomeBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(color: const Color(0xFF101830), borderRadius: BorderRadius.circular(20 * SizeConfigs.paddingScale)),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.orangeAccent),
          SizedBox(width: 12 * SizeConfigs.paddingScale),
          Expanded(
            child: Text(
              "Welcome aboard 👋👀...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 10 * SizeConfigs.textScale),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {},
            child: const Text("Open", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _quizCard(BuildContext context, Map<String, dynamic> data, int index, int totalItems) {
    // Make width responsive
    final cardWidth = MediaQuery.of(context).size.width * 0.485;

    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 18 * SizeConfigs.paddingScale : 0, right: index == totalItems - 1 ? 18 * SizeConfigs.paddingScale : 0),
      child: GestureDetector(
        onTap: () {
          // 1. Check if SleepInfoController is NOT already registered
          if (!Get.isRegistered<SleepInfoController>()) {
            Get.put(SleepInfoController());
            print("✅ SleepInfoController registered successfully");
          } else {
            print("ℹ️ SleepInfoController already exists, reusing instance");
          }
          // 2. Navigate to the Detail View
          Get.to(() => SleepQuizDetailView(data: data));
        },
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24), // Slightly smaller radius for small cards
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(data['image'], width: double.infinity, fit: BoxFit.fill),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * SizeConfigs.paddingScale, vertical: 8 * SizeConfigs.paddingScale),
                  child: SizedBox(
                    height: 16 * SizeConfigs.textScale, // Give it a fixed height
                    child: Marquee(
                      child: Text(
                        data['title'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12 * SizeConfigs.textScale, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuote(BuildContext context) {
    // 1. Get the controller
    final controller = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(color: const Color(0xFF162039), borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)),
      child: Obx(() {
        // 2. Extract the quote data from the API response
        final quoteData = controller.homeData.value?.data?.dailyQuote;

        // 3. Set up safe fallbacks using your original text
        // final String quoteText = quoteData?.quote ?? "Some people talk in their sleep.\nLecturers talk while other people sleep.";
        // final String authorText = quoteData?.author ?? "Albert Camus";

        final String quoteText = quoteData?.quote ?? context.lang.defaultQuote;
        final String authorText = quoteData?.author ?? context.lang.defaultAuthor;
        return Column(
          children: [
            Text(
              "✨",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10 * SizeConfigs.paddingScale),

            // 4. Inject the dynamic quote (wrapped in quotes)
            Text(
              '"$quoteText"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 24 * SizeConfigs.paddingScale),

            // 5. Inject the dynamic author
            Text(
              authorText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 14 * SizeConfigs.paddingScale),
          ],
        );
      }),
    );
  }

  //
  // // ---------------- Offer Banner ----------------
  Widget _offerBanner(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final padding = isSmallPhone ? 14.0 : 20.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16 * SizeConfigs.paddingScale),
      margin: EdgeInsets.only(left: padding, right: padding, bottom: 40 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(Icons.card_giftcard, color: Colors.orange, size: 40),
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
          SizedBox(width: 16 * SizeConfigs.paddingScale),
          Expanded(
            child: Text(context.lang.oneTimeOfferYou, style: TextStyle(color: Colors.white)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * SizeConfigs.paddingScale, vertical: 6 * SizeConfigs.paddingScale),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: Text(context.lang.open, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SleepBarChart extends StatelessWidget {
  final List<double> sleepHours;

  const SleepBarChart({super.key, required this.sleepHours});

  @override
  Widget build(BuildContext context) {
   // final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = [
      context.lang.mon,
      context.lang.tue,
      context.lang.wed,
      context.lang.thu,
      context.lang.fri,
      context.lang.sat,
      context.lang.sun
    ];
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          // Set maxY slightly higher than 10 or your max goal to ensure the background looks consistent
          maxY: 12,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 4,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${value.toInt()}${context.lang.h}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 10.5 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 10.5 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.card,
              // Use your card color for tooltip bg
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              tooltipBorder: const BorderSide(color: Colors.white24, width: 1),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY} ${context.lang.h}',
                  Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white, fontSize: 11 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          barGroups: List.generate(sleepHours.length, (i) {
            final double value = sleepHours[i];
            final bool isEmpty = value == 0; // Check if data is 0

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 18,
                  borderRadius: BorderRadius.circular(20),
                  // Active bar styling
                  gradient: LinearGradient(colors: [AppColors.animationStartColor, AppColors.animationEndColor], begin: Alignment.bottomCenter, end: Alignment.topCenter),

                  // 🔥 DYNAMIC BACKGROUND LOGIC
                  backDrawRodData: BackgroundBarChartRodData(
                    show: isEmpty, // 👈 ONLY show if the value is 0
                    toY: 12, // Match your maxY
                    color: Colors.white.withOpacity(0.1), // The "Empty Box" fill
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DrawTriangleShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white;
    var path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
