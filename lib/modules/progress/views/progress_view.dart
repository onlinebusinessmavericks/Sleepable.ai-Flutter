import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:flutter/services.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:sleep_stages_chart/sleep_stages_chart.dart' as chart;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../dreambot/views/dreambot_view.dart';
import '../../music/views/music_view.dart';
import '../controllers/progress_controller.dart';
import '../model/AIInsightsResponse.dart';
import '../model/SnoringIntensityResponse.dart';
import '../model/sleep_audio_response.dart';
import '../model/sleep_calendar_response.dart';
import '../model/sleep_quality_response.dart';
import '../widget/Insights_list.dart';

class ProgressScreen extends GetView<ProgressController> {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color awakeColor = Color(0xFFE9B95D); // Yellow
    const Color dreamColor = Color(0xFF4A90E2); // Light Blue (Dream is Blue in your SS)
    const Color lightColor = Color(0xFF354E7F); // Muted Blue
    const Color deepColor = Color(0xFF1E3A8A); // Deep Blue
    const Color textPrimary = Colors.white;
    // Map stages to specific colors for labels/bars
    // Update this to match your SleepPoint: 0=Deep, 1=Light, 2=Awake
    Color _getStageColor(int stageIndex) {
      switch (stageIndex) {
        case 0:
          return awakeColor; // Awake
        case 1:
          return dreamColor; // Dream
        case 2:
          return lightColor; // Light
        case 3:
          return deepColor; // Deep
        default:
          return lightColor;
      }
    }

    // Set status bar color (solid)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Color(0xFF0B0E17), statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark));
    SizeConfigs.init(context);
    SizeConfigs2.init(context);
    Get.put(ProgressController());
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500);
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: RefreshIndicator(
        color: Colors.pinkAccent,
        backgroundColor: const Color(0xFF1C2130),
        onRefresh: () => controller.refreshAllData(), // 🚀 Calls your reload logic
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16 * SizeConfigs.paddingScale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40 * SizeConfigs.paddingScale),
              Obx(() {
                return Container(
                  padding: EdgeInsets.all(4 * SizeConfigs.paddingScale),
                  decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // children: ["Today", "Week", "Month"].map((tab) {
                      children: [context.lang.today, context.lang.week, context.lang.month].map((tab) {
                      final isSelected = controller.selectedTab.value == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.changeTab(tab),
                          child: AnimatedContainer(
                            duration: const Duration(microseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12 * SizeConfigs.paddingScale),
                            decoration: BoxDecoration(color: isSelected ? Colors.blueAccent : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                            alignment: Alignment.center,
                            child: Text(
                              tab,
                              style: textStyle?.copyWith(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontSize: 15 * SizeConfigs.textScale,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),

              Obx(() => controller.selectedTab.value == context.lang.today ? SizedBox(height: 20 * SizeConfigs.paddingScale) : SizedBox()),
              // 📅 Center Date Label (Click to open Calendar)
              Obx(
                () => controller.selectedTab.value == context.lang.today
                    ? GestureDetector(
                        onTap: () {
                          // 🔥 Ye function custom calendar sheet open karega
                          _showCalendarBottomSheet(context);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 8 * SizeConfigs.paddingScale),
                            Obx(() {
                              return Text(
                                controller.dateLabel.value,
                                style:
                                    textStyle?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.bold) ??
                                    const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              );
                            }),
                            SizedBox(width: 4 * SizeConfigs.paddingScale),
                            // 🔥 Dropdown Icon Added Here
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      )
                    : SizedBox(),
              ),
              SizedBox(height: 20 * SizeConfigs.paddingScale),


              Obx(() {
                final isToday = controller.selectedTab.value == context.lang.today;

                return isToday
                    ? Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.lang.sleepQualityAnalysis, style: textStyle),
                                Text(
                                  "${controller.durationHours.value.toStringAsFixed(1)}${context.lang.h}",
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.white, fontSize: 36 * SizeConfigs.textScale, height: 1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _buildTodayAnalysisUI(context, controller), // Pass controller here
                            // _buildDurationBarChartUI(context, controller), // Pass controller here
                          ],
                        ),
                      )
                    : Container(
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
                                Text(context.lang.sleepDuration, style: textStyle),
                                Obx(() {
                                  final duration = controller.averageSleep.value;
                                  return Text(
                                    // "${duration.toStringAsFixed(1)}h",
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
                              final int selectedIndex = controller.selectedBarIndex.value; // Track which bar is tapped

                              // final bool isMonthly = selectedTab == "Month";
                              final bool isMonthly = selectedTab == context.lang.month;
                              final int columnCount = data.length;
                              final double chartHeight = 170 * SizeConfigs.paddingScale;

                              // Find highest value for scaling, minimum 8.0
                              double highestValue = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b).toDouble() : 0.0;
                              final double maxVal = highestValue > 8.0 ? highestValue : 8.0;

                              Widget buildRow() {
                                return Row(
                                  mainAxisAlignment: isMonthly ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(columnCount, (index) {
                                    final double value = index < data.length ? data[index].toDouble() : 0.0;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => controller.selectedBarIndex.value = index, // Update tap index
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: isMonthly ? 8 * SizeConfigs.paddingScale : 0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                width: 14 * SizeConfigs.paddingScale,
                                                child: LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    // Calculate height for both the bar and the tooltip position
                                                    final double fillHeight = maxVal == 0 ? 0 : (value / maxVal) * constraints.maxHeight;

                                                    return Stack(
                                                      alignment: Alignment.bottomCenter,
                                                      clipBehavior: Clip.none, // Crucial for tooltip to float above
                                                      children: [
                                                        // 1. The Border/Background of the bar
                                                        Container(
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          decoration: BoxDecoration(
                                                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                                                            borderRadius: BorderRadius.circular(30),
                                                          ),
                                                        ),

                                                        // 2. The Actual Data Fill (Animated)
                                                        AnimatedContainer(
                                                          duration: const Duration(milliseconds: 600),
                                                          curve: Curves.easeInOut,
                                                          width: double.infinity,
                                                          height: fillHeight,
                                                          decoration: BoxDecoration(
                                                            gradient: value > 0
                                                                ? const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.blueAccent, Colors.purpleAccent])
                                                                : null,
                                                            borderRadius: BorderRadius.circular(30),
                                                          ),
                                                        ),

                                                        // 3. Tooltip UI
                                                        Positioned(
                                                          bottom: fillHeight + 8, // Positions it 8px above the top of the bar
                                                          child: Visibility(
                                                            visible: selectedIndex == index && value > 0,
                                                            child: Column(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                                                                  ),
                                                                  child: Text(
                                                                    "${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}h",
                                                                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ),
                                                                // Downward Triangle
                                                                CustomPaint(size: const Size(8, 4), painter: DrawTriangleShape()),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8 * SizeConfigs.paddingScale),
                                            Text(
                                              index < labels.length ? labels[index] : "",
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 10.5 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
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
                          ],
                        ),
                      );
              }),

              SizedBox(height: 20 * SizeConfigs.paddingScale),
              Text(context.lang.sleepStages, style: textStyle),
              SizedBox(height: 20 * SizeConfigs.paddingScale),


              Obx(() {
                // 1. Pehle Loader Check karein
                if (controller.isStagesLoading.value) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  );
                }


                if (controller.sleepIntervals.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Obx(() {
                        final bool isFreeUser = subController.isPremium.value == false;
                        final controller = Get.find<HomeController>();
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Icon ya PRO Button Logic
                            if (isFreeUser)
                              GestureDetector(
                                onTap: () {
                                  final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;
                                  if (hasAlreadySpun) {
                                    controller.showRotatingPremiumSheet(context);
                                    // showPremiumOfferSheet6(context);
                                  } else {
                                    showPremiumOfferSheet4(context);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.proLight, AppColors.proDark],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.proDark.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    context.lang.proButton,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.bedtime_outlined,
                                color: Colors.white10,
                                size: 40,
                              ),

                            const SizedBox(height: 12),

                            // 2. Text Logic
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                isFreeUser
                        ? context.lang.proPrompt // Localized Premium prompt
                            : "${context.lang.noDataToday}\n${context.lang.noDataToday1}",
                                    // ? "No sleep data yet. Unlock deep analytics and AI insights with Sleepable Premium ✨"
                                    // : "No sleep data for today yet.\nStart your sleep tracker tonight!",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                }
                // 3. Safety Check: Data hai par summary null toh nahi?
                // Isse "Null check operator used on a null value" wali error solve ho jayegi.
                if (controller.sleepSummary.value == null) {
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                }

                // Ab yaha data 100% safe hai
                final intervals = controller.sleepIntervals;
                final labels = controller.hourLabels;
                final s = controller.sleepSummary.value!;

                return Column(
                  children: [
                    Container(
                      height: 220,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Stack(
                        children: [
                          // --- Background Grid ---
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // _buildGridRow(context, "Awake", awakeColor),
                              // _buildGridRow(context, "Dream", dreamColor),
                              // _buildGridRow(context, "Light", lightColor),
                              // _buildGridRow(context, "Deep", deepColor),
                              _buildGridRow(context, context.lang.awake, awakeColor), // "Awake"
                              _buildGridRow(context, context.lang.dream, dreamColor), // "Dream"
                              _buildGridRow(context, context.lang.light, lightColor), // "Light"
                              _buildGridRow(context, context.lang.deep, deepColor),  // "Deep"
                            ],
                          ),

                          // --- The Bars & Connectors ---
                          Padding(
                            padding: const EdgeInsets.only(left: 65, right: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(intervals.length, (index) {
                                final d = intervals[index];
                                final int depth = d.stageIndex;
                                int? nextDepth = (index + 1 < intervals.length) ? intervals[index + 1].stageIndex : null;

                                return Expanded(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Column(
                                        children: [
                                          if (depth > 0) Expanded(flex: depth * 10, child: const SizedBox()),
                                          Container(
                                            height: 35,
                                            width: double.infinity,
                                            decoration: BoxDecoration(color: _getStageColor(d.stageIndex)),
                                          ),
                                          if (3 - depth > 0) Expanded(flex: (3 - depth) * 10, child: const SizedBox()),
                                        ],
                                      ),
                                      if (nextDepth != null && nextDepth != depth)
                                        Positioned(
                                          right: -1,
                                          top: (220 / 4) * (nextDepth < depth ? nextDepth : depth) + 25,
                                          child: Container(width: 2, height: (220 / 4) * (nextDepth - depth).abs().toDouble(), color: Colors.white12),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hours Labels (-45° when crowded, e.g. monthly Jan–Dec)
                    Builder(
                      builder: (context) {
                        final bool rotateLabels = labels.length >= 8;
                        return Padding(
                          padding: EdgeInsets.only(left: 10, top: 20, right: 20, bottom: rotateLabels ? 12 : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  context.lang.hoursLabel,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white38, fontSize: 10.5 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: rotateLabels ? 42 : 20,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: labels.map((h) {
                                      final labelText = Text(
                                        h,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: rotateLabels ? 10 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );

                                      if (!rotateLabels) {
                                        return SizedBox(
                                          width: 20,
                                          child: Center(child: Marquee(child: labelText)),
                                        );
                                      }

                                      return Expanded(
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Transform.rotate(
                                            angle: -45 * 3.1415926535 / 180, // -45° best balance
                                            alignment: Alignment.center,
                                            child: labelText,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Phase Cards
                    _buildPhaseCard(controller, context.lang.awake, controller.formatMinsToText(s.totalAwakeMinutes), s.awakePercentage, awakeColor, context.lang.awakeDesc),
                    _buildPhaseCard(controller, context.lang.dream, controller.formatMinsToText(s.totalDreamMinutes), s.dreamPercentage, dreamColor, context.lang.dreamDesc),
                    _buildPhaseCard(controller, context.lang.light, controller.formatMinsToText(s.totalLightSleepMinutes), s.lightSleepPercentage, lightColor, context.lang.lightDesc),
                    _buildPhaseCard(controller, context.lang.deep, controller.formatMinsToText(s.totalDeepSleepMinutes), s.deepSleepPercentage, deepColor, context.lang.deepDesc),

                    SizedBox(height: 20 * SizeConfigs.paddingScale),
                  ],
                );
              }),

              Obx(() {
                // if (controller.isConsistencyLoading.value) {
                //   return const Center(child: CircularProgressIndicator());
                // }
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
                      Text(context.lang.sleepConsistency, style: textStyle),
                      SizedBox(height: 30 * SizeConfigs.paddingScale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            _buildCircleChart(context, "${context.lang.bedtimeRegularity}\n${context.lang.bedtimeRegularity1}", controller.bedtimeRegularity.value, const Color(0xFF3A3CF8)),
                          _buildCircleChart(context, "${context.lang.wakeTimePattern}\n${context.lang.wakeTimePattern1}", controller.wakeTimePattern.value, AppColors.glowPinkColor),
                        ],
                      ),

                      SizedBox(height: 16 * SizeConfigs.paddingScale),

                      _buildInfoRow(context, Icons.nightlight_round, context.lang.avgBedtime, controller.avgBedtime.value),

                      _buildInfoRow(context, Icons.wb_sunny, context.lang.avgWakeTime, controller.avgWakeTime.value),

                      _buildInfoRow(context, Icons.timer, context.lang.sleepWindowVar, controller.sleepWindowVariance.value),
                    ],
                  ),
                );
              }),
              SizedBox(height: 25 * SizeConfigs.paddingScale),

              Obx(() {
                if (controller.isLoading.value) {
                  return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
                }

                // Check if we actually have data to show
                // if (controller.snoreChartData.isEmpty) {
                //   return const SizedBox(
                //     height: 240,
                //     child: Center(
                //       child: Text("No snoring data available", style: TextStyle(color: Colors.white38)),
                //     ),
                //   );
                // }
                if (controller.snoreChartData.isEmpty) {
                  return SizedBox(
                    height: 240,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          // Agar user premium nahi hai toh analytics wala text dikhao
                          (subController.isPremium.value == false)
                          ?context.lang.noSnoringDataAvailableUpgradePremium
                           : context.lang.noSnoringDataAvailableToday,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return VisibilityDetector(
                  key: const Key('SnoringIntensity'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.5 && !controller.snoreVisible.value) {
                      controller.snoreVisible.value = true;
                    }
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    opacity: controller.snoreVisible.value ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B27),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.lang.snoringIntensity, style: textStyle),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 220,
                            child: SfCartesianChart(
                              margin: EdgeInsets.zero,
                              plotAreaBorderWidth: 0,

                              // X-Axis: Days of the week from JSON
                              primaryXAxis: CategoryAxis(
                                majorGridLines: const MajorGridLines(width: 0),
                                labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                axisLine: const AxisLine(width: 1, color: Colors.white10),
                                labelPlacement: LabelPlacement.onTicks,
                              ),

                              // Y-Axis: Percentage (0-100%)
                              primaryYAxis: NumericAxis(
                                minimum: 0,
                                maximum: 100,
                                interval: 25,
                                labelFormat: '{value}%',
                                majorGridLines: const MajorGridLines(
                                  width: 0.5,
                                  color: Colors.white10,
                                  dashArray: [5, 5], // Dotted lines look more professional
                                ),
                                labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                                axisLine: const AxisLine(width: 0),
                              ),

                              series: <CartesianSeries>[
                                SplineAreaSeries<SnorePoint, String>(
                                  dataSource: controller.snoreChartData,
                                  xValueMapper: (SnorePoint d, _) => d.time,
                                  yValueMapper: (SnorePoint d, _) => d.intensity,
                                  name: context.lang.intensity,
                                  // Smooth blue glow
                                  gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.4), Colors.blueAccent.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                  borderColor: Colors.blueAccent,
                                  borderWidth: 2,
                                  markerSettings: const MarkerSettings(isVisible: true, height: 4, width: 4, color: Colors.white, borderColor: Colors.blueAccent),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),


              SizedBox(height: 20 * SizeConfigs.paddingScale),

              // --- Key Insights ---
              Text(context.lang.keyInsights, style: textStyle),
              SizedBox(height: 15 * SizeConfigs.paddingScale),


              Obx(() {
                if (controller.isInsightsLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 12 * SizeConfigs.paddingScale,
                  runSpacing: 12 * SizeConfigs.paddingScale,
                  children: [
                    // 1. Average Sleep
                    _buildInsightCard(
                      context,
                      controller.sleepTrend.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      "${controller.avgSleepHours.value.toStringAsFixed(1)}${context.lang.h}",
                      context.lang.averageSleepLabel,
                      "${controller.sleepTrend.value.abs().toStringAsFixed(1)}${context.lang.m}",
                      Icons.bed,
                      arrowColor: controller.sleepTrend.value >= 0 ? Colors.greenAccent : Colors.redAccent,
                      showArrow: controller.sleepTrend.value != 0,
                    ),

                    // 2. Sleep Quality
                    _buildInsightCard(
                      context,
                      controller.qualityTrend.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      "${controller.sleepQualityScore.value.toStringAsFixed(0)}%",
                      context.lang.sleepQualityLabel,
                      "${controller.qualityTrend.value.abs().toStringAsFixed(1)}%",
                      Icons.favorite,
                      arrowColor: controller.qualityTrend.value >= 0 ? Colors.greenAccent : Colors.redAccent,
                      showArrow: controller.qualityTrend.value != 0,
                    ),

                    // 3. Consistency
                    _buildInsightCard(
                      context,
                      controller.consistencyTrend.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      "${controller.consistencyScore.value.toStringAsFixed(0)}%",
                      context.lang.consistencyLabel,
                      "${controller.consistencyTrend.value.abs().toStringAsFixed(1)}%",
                      Icons.sync_rounded,
                      arrowColor: controller.consistencyTrend.value >= 0 ? Colors.greenAccent : Colors.redAccent,
                      showArrow: controller.consistencyTrend.value != 0,
                    ),

                    // 4. Sleep Streak (Usually no trend arrow for streaks)
                    _buildInsightCard(context, null, "${controller.sleepStreakDays.value} ${context.lang.daysLabel}", context.lang.sleepStreakLabel, context.lang.daysLabel, Icons.nights_stay, showArrow: false),
                  ],
                );
              }),
              // SizedBox(height: 15 * SizeConfigs.paddingScale),
              SizedBox(height: 20 * SizeConfigs.paddingScale),

              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 15, left: 18, right: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Icon(Icons.wb_incandescent_outlined, size: 20 * SizeConfigs.textScale, color: Colors.white),
                        SizedBox(width: 12 * SizeConfigs.paddingScale),
                        Text(context.lang.aiInsights, style: textStyle),
                      ],
                    ),

                    SizedBox(height: 12 * SizeConfigs.paddingScale),

                    // Scrollable list of insight cards
                    SizedBox(height: 320 * SizeConfigs.paddingScale, child: InsightsList()),
                  ],
                ),
              ),
              SizedBox(height: 20 * SizeConfigs.paddingScale),

              Text(context.lang.achievementBadges, style: textStyle),
              SizedBox(height: 15 * SizeConfigs.paddingScale),
              Obx(() {
                if (controller.isLoadingBadges.value) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white24));
                }

                final data = controller.achievementBadges.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Early Bird Card
                    _buildBadgeCard(context, title:context.lang.earlyBird, icon: Icons.wb_sunny_rounded, isActive: data?.earlyBird ?? false),

                    SizedBox(width: 12 * SizeConfigs.paddingScale),

                    // Sleep Champion Card
                    _buildBadgeCard(
                      context,
                      title: "${context.lang.sleep}\n${context.lang.champion}",
                      // 🔥 Now using dynamic description from API
                      subtitle: data?.sleepChampionDesc ?? context.lang.wakeUpGoal,
                      icon: Icons.emoji_events_rounded,
                      isActive: data?.sleepChampion ?? false,
                      // onTap: (data != null && (data.sleepChampion || data.sleepChampQualifying >= data.sleepChampRequired))
                      //     ? () => showRewardPopup(context)
                      //     : null,
                      onTap: (data?.sleepChampion ?? false) ? () => showRewardPopup(context) : null,
                    ),
                  ],
                );
              }),
              SizedBox(height: 20 * SizeConfigs.paddingScale),

              // Night Owl Tamer Card (Full Width)
              _buildWideBadgeCard(context, title: context.lang.nightOwlTamer, subtitle:  context.lang.bedtimeBeforePM, icon: Icons.nights_stay_rounded),


              controller.selectedTab.value == context.lang.today ? SizedBox.shrink() : SizedBox(height: 20 * SizeConfigs.paddingScale),
              controller.selectedTab.value == context.lang.today ? SizedBox.shrink() : Text(context.lang.sleepQualityLabel, style: textStyle),
              controller.selectedTab.value == context.lang.today ? SizedBox.shrink() : SizedBox(height: 10 * SizeConfigs.paddingScale),

              Obx(() {
                final isToday = controller.selectedTab.value == context.lang.today;

                if (isToday) return const SizedBox.shrink();
                if (controller.isQualityLoading.value) {
                  return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                }

                return SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 1, color: Colors.white30),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                  primaryYAxis: NumericAxis(
                    minimum: 0,
                    maximum: 100,
                    // Quality score is typically 0-100
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 1, color: Colors.white30),
                    labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 13 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                  ),
                  series: <SplineSeries<SleepQualityPoint, String>>[
                    SplineSeries<SleepQualityPoint, String>(
                      dataSource: controller.sleepQualityData,
                      xValueMapper: (d, _) => d.label,
                      yValueMapper: (d, _) => d.score,
                      color: Colors.orangeAccent,
                      width: 3,
                      animationDuration: 2000,
                      markerSettings: MarkerSettings(
                        isVisible: true,
                        shape: DataMarkerType.image,
                        // Only show star if star_rating > 0
                        image: const AssetImage(Assets.homeStar),
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ],
                );
              }),


              SizedBox(height: 20 * SizeConfigs.paddingScale),
              Text(context.lang.personalizedRecommendations, style: textStyle),
              SizedBox(height: 20 * SizeConfigs.paddingScale),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    if (controller.isRecLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    }

                    // if (controller.recommendationList.isEmpty) {
                    //   return const Center(
                    //     child: Text("No recommendations yet", style: TextStyle(color: Colors.white30)),
                    //   );
                    // }
                    // 2. Empty Data State + Premium Check
                    if (controller.recommendationList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          child: Text(
                            // Free user mate premium prompt ane premium user mate default empty text
                            (subController.isPremium.value == false)
                            ? context.lang.noRecommendationsYetUpgradePremiumPersonalizedSleepImprovementTips
                            : context.lang.noRecommendationsAvailableToday,
                                // ? "No recommendations yet. Upgrade to Premium for personalized sleep improvement tips ✨"
                                // : "No recommendations available for today.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white30, fontSize: 14),
                          ),
                        ),
                      );
                    }
                    IconData _getIconForRecommendation(String title) {
                      final t = title.toLowerCase();
                      if (t.contains( context.lang.bedtime)) return Icons.schedule_rounded;
                      if (t.contains(context.lang.duration)) return Icons.timer_outlined;
                      if (t.contains(context.lang.environment)) return Icons.nights_stay_rounded;
                      if (t.contains(context.lang.deepSleep)) return Icons.bolt_rounded;
                      if (t.contains(context.lang.quality1)) return Icons.star_rounded;
                      return Icons.lightbulb_outline_rounded;
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.recommendationList.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12 * SizeConfigs.paddingScale),
                      itemBuilder: (context, index) {
                        final item = controller.recommendationList[index];
                        return _buildRecommendationTile(
                          context,
                          // Logic to pick a dynamic icon based on the title
                          icon: _getIconForRecommendation(item.title),
                          title: item.title,
                          subtitle: item.description,
                        );
                      },
                    );
                  }),
                ],
              ),
              // -------------------- Sleep Recorder --------------------
              SizedBox(height: 20 * SizeConfigs.paddingScale),
              Text(context.lang.sleepRecorder, style: textStyle),
              SizedBox(height: 20 * SizeConfigs.paddingScale),
              sleepRecorderSection(context),
              SizedBox(height: 20 * SizeConfigs.paddingScale),
              Obx(() {
                // My Dreams stays visible for free/trial users - shown locked, not hidden.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.lang.myDreams, style: textStyle),
                    SizedBox(height: 10 * SizeConfigs.paddingScale),
                    subController.isPremium.value ? _buildMyDream(context) : _lockedDreamsCard(context),
                  ],
                );
              }),
              // SizedBox(height: 15 * SizeConfigs.paddingScale),

              // -------------------- Export & Share --------------------

              Stack(
                alignment: Alignment.center,
                children: [
                  // Lottie animation
                  Lottie.asset(Assets.lottieCloud, height: 100, width: double.infinity, fit: BoxFit.cover),
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Obx(() {
                      return Text(
                        "${context.lang.sleepableWithYou} ${controller.achiveData.value} ${context.lang.day}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white30, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),

                        // TextStyle(
                        //   color: Colors.white30,
                        //   fontSize: 18,
                        //   fontWeight: FontWeight.w600,
                        // ),
                      );
                    }),
                  ),
                  // Text on top of Lottie
                  // Text(
                  //   "Sleepble has been with you for 1 day",
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
              SizedBox(height: 190 * SizeConfigs.paddingScale),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalendarBottomSheet(BuildContext context) {
    // Call fetch when opening
    controller.fetchSleepCalendar();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1218),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
               Text(
                context.lang.calendar,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Fixed Weekday Header
              // Row(
              //   children: ["S", "M", "T", "W", "T", "F", "S"]
                  Row(
                  children: [
                  context.lang.s,  // Sunday
                  context.lang.m1, // Monday
                  context.lang.t,  // Tuesday
                  context.lang.w,  // Wednesday
                  context.lang.t2, // Thursday
                  context.lang.f,  // Friday
                  context.lang.s2, // Saturday
                  ]
                    .map(
                      (day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Obx(() {
                  if (controller.isCalendarLoading.value && controller.calendarData.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }

                  if (controller.calendarData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text(context.lang.noDataFound, style: TextStyle(color: Colors.white30)),
                          TextButton(onPressed: () => controller.fetchSleepCalendar(), child: Text( context.lang.retry))
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.calendarData.length,
                    itemBuilder: (context, index) {
                      return _buildDynamicMonthGrid(controller.calendarData[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicMonthGrid(CalendarMonth monthData) {
    DateTime firstDayOfMonth = DateTime.parse("${monthData.monthLabel}-01");
    String displayTitle = DateFormat('MMMM, yyyy').format(firstDayOfMonth);

    // 0 = Sunday, 1 = Monday ... 6 = Saturday
    // Since Dart's weekday is 1 (Mon) to 7 (Sun), we use modulo 7
    int startOffset = firstDayOfMonth.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            displayTitle,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          // The total number of cells is the offset (empty spots) + the days in the month
          itemCount: monthData.days.length + startOffset,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
          // Inside _buildDynamicMonthGrid itemBuilder
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();

            final dayData = monthData.days[index - startOffset];
            DateTime date = DateTime.parse(dayData.date);

            String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            bool isToday = todayStr == dayData.date;
            bool hasSleep = dayData.hasSleep;

            return GestureDetector(
              onTap: () {
                if (dayData.hasSleep) {
                  // This calls the new logic to fetch data for March 31, 2026
                  controller.onDateSelected(dayData.date);

                  // Close the calendar sheet
                  Get.back();
                } else {
                  // Optional: Show a snackbar if no data exists for that day
                  Get.snackbar(
                      // "No Data", "No sleep was recorded for this night.",
                      context.lang.noDataLabel, // "No Data"
                      context.lang.noDataRecorded,
                      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white10, colorText: Colors.white);
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? Colors.blueAccent : const Color(0xFF1E232E),
                  border: (hasSleep && !isToday) ? Border.all(color: Colors.blueAccent, width: 1.5) : null,
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: (isToday || hasSleep) ? Colors.white : Colors.white38,
                    fontSize: 14 * SizeConfigs.textScale,
                    fontWeight: (isToday || hasSleep) ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget sleepRecorderSection(BuildContext context) {
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      if (controller.isLoadingAudio.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 1. Filter the list first
      final visibleCategories = controller.categories.where((category) {
        return category.recordings.any((item) => (item.durationSeconds ?? 0) > 0);
      }).toList();

      if (visibleCategories.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40, left: 30, right: 30),
            child: Text(
              // Check if user is NOT premium
              (subController.isPremium.value == false)
                  ? context.lang.unlockRecordingsPrompt
                  : context.lang.noRecordingsToday,
                  // ? "No recordings found. Unlock your sleep recordings and AI analysis with Sleepable Premium ✨"
                  // : "No recordings found for today.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        );
      }
      // 2. Map the filtered list using asMap().entries to keep track of the original index safely
      return Column(
        children: visibleCategories.asMap().entries.map((entry) {
          final category = entry.value;
          // We find the index in the ORIGINAL controller list for the toggle logic
          int originalIndex = controller.categories.indexOf(category);

          return sleepRecorderTile(context, category, () {
            controller.toggleExpand(originalIndex);
          });
        }).toList(),
      );
    });
  }

  Widget sleepRecorderTile(BuildContext context, RecordingCategory category, VoidCallback onTapHeader) {
    // 🔥 Define the list of recordings that actually have time
    final validRecordings = category.recordings.where((item) => (item.durationSeconds ?? 0) > 0).toList();
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTapHeader,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${category.label}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // 🔥 Updated to show count of valid items only
                  if (validRecordings.isNotEmpty)
                    Text(
                      "${validRecordings.length} ${context.lang.items}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54, fontSize: 13 * SizeConfigs.textScale),
                    ),
                  const SizedBox(width: 8),
                  Icon(category.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),

          /// Expanded List
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: category.isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(color: Colors.white12, height: 1),

                // 🔥 Updated to only map recordings that have time
                ...validRecordings.map((item) {
                  return recordingTile(item);
                }).toList(),

                const SizedBox(height: 10),

                // unlock button
                Obx(
                  () => subController.isPremium.value
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: const Color(0xFF1E90FF), borderRadius: BorderRadius.circular(24)),
                            child: Center(
                              child: Text(
                                context.lang.unlockToCheck,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
              ],
            ),
            secondChild: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget recordingTile(AudioItem item) {
    final String audioUrl = item.audioFile ?? "";
    final controller = Get.find<ProgressController>();
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    // Timeline uses wall-clock duration (uploaded as wall_clock_seconds) when available
    DateTime? startDt = item.recordedAt;
    DateTime? endDt = startDt?.add(Duration(seconds: item.durationSeconds ?? 0));

    // Prefer API-formatted local time when present (avoids TZ display drift)
    String formatTime(DateTime? dt) {
      if (item.recordedTime != null && item.recordedTime!.isNotEmpty && dt == startDt) {
        return item.recordedTime!;
      }
      if (dt == null) return "--:--";
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    }

    String formatEndTime() {
      if (endDt == null) return "--:--";
      final hour = endDt.hour > 12 ? endDt.hour - 12 : (endDt.hour == 0 ? 12 : endDt.hour);
      final minute = endDt.minute.toString().padLeft(2, '0');
      final period = endDt.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                // onTap: () => audioUrl.isNotEmpty ? controller.handlePlayPause(audioUrl) : null,
                onTap: () {
                  // 🔥 Logic: Play only if Premium, otherwise show sheet
                  if (subController.isPremium.value) {
                    if (audioUrl.isNotEmpty) controller.handlePlayPause(audioUrl);
                  } else {
                    // Check karein ki spin ho chuka hai ya nahi
                    final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;

                    if (hasAlreadySpun && !GetPlatform.isIOS) {
                      // ✅ Spin ho chuka hai -> Discounted Sheet
                      // iOS pe Sheet 6 ("50% OFF FOREVER") nahi (Apple 3.1.2(c)) -> Sheet 4.
                      showPremiumOfferSheet6(Get.context!);
                    } else {
                      // ❌ Spin nahi hua -> Normal Paywall
                      showPremiumOfferSheet4(Get.context!);
                    }
                  }
                },
                child: Obx(() {
                  bool isCurrentPlaying = controller.playingUrl.value == audioUrl && controller.isPlaying.value;
                  if (!subController.isPremium.value) {
                    return const Icon(Icons.lock_rounded, color: Colors.white38, size: 34);
                  }
                  return Icon(isCurrentPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: isCurrentPlaying ? const Color(0xFF1E90FF) : Colors.white, size: 34);
                }),
              ),
              const SizedBox(width: 12),

              // Expanded Section containing Start Time, Bar, and End Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.formatDuration(item.durationSeconds ?? 0),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        // Obx ke andar logic change karein
                        Obx(() {
                          return (subController.isPremium.value)
                              ? const SizedBox.shrink() // ✅ Premium hone par kuch nahi dikhega
                              : const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white38,
                            size: 16,
                          ); // ✅ Free user ko lock dikhega
                        }),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Seekable progress bar
                    Obx(() {
                      final bool isActive = controller.playingUrl.value == audioUrl;
                      final bool canSeek = subController.isPremium.value && audioUrl.isNotEmpty;
                      double progress = 0.0;
                      if (isActive && controller.totalDuration.value.inMilliseconds > 0) {
                        progress = (controller.currentPosition.value.inMilliseconds /
                                controller.totalDuration.value.inMilliseconds)
                            .clamp(0.0, 1.0);
                      }

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(Get.context!).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: isActive ? const Color(0xFF1E90FF) : Colors.white24,
                              inactiveTrackColor: Colors.white10,
                              thumbColor: canSeek
                                  ? (isActive ? const Color(0xFF1E90FF) : Colors.white54)
                                  : Colors.transparent,
                              disabledActiveTrackColor: Colors.white24,
                              disabledInactiveTrackColor: Colors.white10,
                            ),
                            child: Slider(
                              value: progress,
                              min: 0,
                              max: 1,
                              onChanged: canSeek
                                  ? (v) {
                                      // Optimistic UI while seeking
                                      if (isActive && controller.totalDuration.value.inMilliseconds > 0) {
                                        controller.currentPosition.value = Duration(
                                          milliseconds: (controller.totalDuration.value.inMilliseconds * v)
                                              .round(),
                                        );
                                      }
                                    }
                                  : null,
                              onChangeEnd: canSeek
                                  ? (v) => controller.seekAudio(audioUrl, v)
                                  : null,
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    controller.formatDuration(
                                      controller.currentPosition.value.inSeconds,
                                    ),
                                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10),
                                  ),
                                  Text(
                                    controller.formatDuration(
                                      controller.totalDuration.value.inSeconds > 0
                                          ? controller.totalDuration.value.inSeconds
                                          : (item.durationSeconds ?? 0),
                                    ),
                                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),

                    // Bottom Row: Start and End Times
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatTime(startDt), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                        Text(formatEndTime(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showRewardPopup(BuildContext context) {
    Get.dialog(
      Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFD7ECFF), // Same bluish card
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Medal Animation
              SizedBox(
                height: 120,
                child: Lottie.asset(
                  Assets.lottieTrophy, // your lottie file
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),
              // Congrats Text
              Text(
                context.lang.congratsLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),

                // TextStyle(
                //   decoration: TextDecoration.none,
                //   fontSize: 22,
                //   fontWeight: FontWeight.bold,
                //   color: Colors.black87,
                // ),
              ),

              const SizedBox(height: 20),

              // Claim Reward Button
              GestureDetector(
                onTap: () {
                  Get.back(); // close popup
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green, //const Color(0xFF6ED76E), // green button
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      context.lang.sleepChampion,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),

                      // TextStyle(
                      //   decoration: TextDecoration.none,
                      //   fontSize: 18,
                      //   color: Colors.white,
                      //   fontWeight: FontWeight.bold,
                      // ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildBadgeCard(BuildContext context, {required String title, String? subtitle, required IconData icon, bool isActive = false, VoidCallback? onTap}) {
    final bgColor = isActive ? Colors.green : Colors.transparent;
    final borderColor = isActive ? Colors.green : Colors.white24;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150 * SizeConfigs.paddingScale,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * SizeConfigs.paddingScale, horizontal: 14 * SizeConfigs.paddingScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SmallCircleIcon(icon: icon, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: isActive ? Colors.white10 : Colors.white.withOpacity(0.08), onTap: () {}),
                SizedBox(height: 8 * SizeConfigs.paddingScale),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                ),
                SizedBox(height: 8 * SizeConfigs.paddingScale),
                if (subtitle != null)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 11 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideBadgeCard(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      height: 70 * SizeConfigs.paddingScale,
      decoration: BoxDecoration(color: Color(0xFF161B27), borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * SizeConfigs.paddingScale),
        child: Row(
          children: [
            SmallCircleIcon(icon: icon, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white12, onTap: () {}),
            SizedBox(width: 12 * SizeConfigs.paddingScale),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                ),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleChart(BuildContext context, String label, dynamic value, Color color) {
    final double progressValue = (value is int) ? value / 100 : (value ?? 0) / 100;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(value: progressValue, color: color, backgroundColor: Colors.white10, strokeWidth: 15),
            ),
            Text(
              "${value.toInt()}%",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.white, fontSize: 15 * SizeConfigs.textScale),
            ),
          ],
        ),
        SizedBox(height: 14 * SizeConfigs.paddingScale),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 13 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * SizeConfigs.paddingScale, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8, right: 8),
                child: SmallCircleIcon(
                  icon: icon,
                  size: 18 * SizeConfigs.textScale,
                  iconColor: Colors.white,
                  backgroundColor: Colors.white10,
                  onTap: () {}, // 🔹 Removed Get.back(), better for reusable UI
                ),
              ),
              SizedBox(width: 8 * SizeConfigs.paddingScale),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 15 * SizeConfigs.textScale),

                // Theme.of(context).textTheme.titleLarge?.copyWith(
                //               color: Colors.grey,
                //               fontSize: 15 * SizeConfigs.textScale,
                //               fontWeight: FontWeight.bold,
                //             ),
              ),
            ],
          ),
          Text(
            "$value", // ✅ Safe: converts int/double/String to text
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    IconData? arrowIcon, // make nullable
    String value,
    String label,
    String change,
    IconData mainIcon, {
    Color? arrowColor, // custom arrow color
    bool showArrow = true, // control visibility
  }) {
    return Container(
      width: 176 * SizeConfigs.paddingScale,
      padding: EdgeInsets.all(14 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(
        color: const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(mainIcon, color: Colors.white, size: 22 * SizeConfigs.textScale),
              const Spacer(),
              if (showArrow && arrowIcon != null) // ✅ show only if true
                Row(
                  children: [
                    Icon(arrowIcon, color: arrowColor ?? Colors.greenAccent, size: 16 * SizeConfigs.textScale),
                    SizedBox(width: 4 * SizeConfigs.paddingScale),
                    Text(
                      change,
                      style: TextStyle(color: change.contains('-') ? Colors.redAccent : arrowColor ?? Colors.greenAccent, fontSize: 13 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              else
                Text(
                  change,
                  style: TextStyle(color: Colors.grey, fontSize: 13 * SizeConfigs.textScale),
                ),
            ],
          ),
          SizedBox(height: 10 * SizeConfigs.paddingScale),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4 * SizeConfigs.paddingScale),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161B27), borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * SizeConfigs.paddingScale, vertical: 12 * SizeConfigs.paddingScale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Changed to start for better multi-line look
          children: [
            // 1. Icon Container
            Container(
              padding: EdgeInsets.all(8 * SizeConfigs.paddingScale),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(30)),
              child: Icon(icon, color: Colors.white, size: 20 * SizeConfigs.textScale),
            ),
            SizedBox(width: 12 * SizeConfigs.paddingScale),

            // 2. Expanded forces the Column to stay within screen bounds
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                  ),
                  SizedBox(height: 4 * SizeConfigs.paddingScale),
                  // 3. Normal Text widget will now wrap automatically
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.3, // Improves readability for multi-line text
                    ),
                    // softWrap: true is default, so it will wrap to the next line
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        height: 130 * SizeConfigs.paddingScale,
        // margin: EdgeInsets.only(right: 12 * SizeConfigs.paddingScale),
        decoration: BoxDecoration(color: Color(0xFF161B27), borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * SizeConfigs.paddingScale, vertical: 12 * SizeConfigs.paddingScale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22 * SizeConfigs.textScale),
              SizedBox(height: 8 * SizeConfigs.paddingScale),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
              ),
              SizedBox(height: 2 * SizeConfigs.paddingScale),
              Text(subtitle, textAlign: TextAlign.center, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class BreathEvent {
  final String time;
  final double duration;

  BreathEvent(this.time, this.duration);
}

/// Placeholder shown to free and trial users in place of the dream list, so the
/// feature is visible but clearly locked behind Premium.
Widget _lockedDreamsCard(BuildContext context) {
  return GestureDetector(
    onTap: () => Get.put(HomeController()).showRotatingPremiumSheet(context),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, color: Colors.white54, size: 26),
          const SizedBox(height: 10),
          Text(
            context.lang.dreamBotTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            context.lang.unlockAllFeatures,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMyDream(BuildContext context) {
  final controller = Get.find<ProgressController>();
  final size = MediaQuery.of(context).size;
  // Dynamic height based on screen width
  final cardHeight = (size.width < 380 ? 70.0 : 75.0) * SizeConfigs.paddingScale;

  return Obx(() {
    // Show loader only if list is empty and fetching
    if (controller.isLoadingDreams.value && controller.myDreamsList.isEmpty) {
      return SizedBox(
        height: cardHeight + 20,
        child: const Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return SizedBox(
      height: cardHeight + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.myDreamsList.length + 1, // +1 for the static "New" card
        // padding: const EdgeInsets.only(left: 18), // Start padding for the whole row
        itemBuilder: (context, index) {
          if (index == 0) {
            // 1. Static "New Dream" Card
            return _dreamCard(
              context,
              id: 0,
              title: context.lang.newDreamAnalysis,
              subtitle: context.lang.startNewJourney,
              imagePath: Assets.homeBackgroundMountains,
              // Assuming this is your asset path
              isNew: true,
            );
          }

          // 2. Dynamic Cards from API (index - 1 because index 0 is used above)
          final dream = controller.myDreamsList[index - 1];
          return _dreamCard(
            context,
            id: dream.id,
            title: dream.title,
            subtitle: dream.summary,
            // Check if it's already a full URL or needs the prefix
            imagePath: dream.image.startsWith('http') ? dream.image : "https://api.sleepable.ai${dream.image}",
            isNew: false,
          );
        },
      ),
    );
  });
}

// Helper for the Card UI
Widget _dreamCard(BuildContext context, {required int id, required String title, required String subtitle, required String imagePath, required bool isNew}) {
  final size = MediaQuery.of(context).size;

  return GestureDetector(
    onTap: () {
      Get.toNamed(Routes.dreamBot, parameters: {"fromProgress": "true", "dreamId": id.toString()});
    },
    child: Container(
      width: size.width * 0.52,
      // Slightly wider for better text fit
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: AppColors.card.withOpacity(0.98), borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Right-aligned background image with gradient fade
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10),
                        )
                      : Image.asset(imagePath, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.card.withOpacity(0.98), Colors.transparent]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Foreground Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * SizeConfigs.paddingScale),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 12 * SizeConfigs.textScale),
                      ),
                    ],
                  ),
                ),
                Icon(isNew ? Icons.add : Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _buildPhaseCard(ProgressController controller, String title, String duration, double percent, Color color, String desc) {
  const Color cardBackground = Color(0xFF161B27); // Lighter navy for cards

  final String statusText = controller.getStageStatus(title, percent);

  // Color the status text based on how good it is
  Color statusColor = statusText == "Optimal" ? Colors.greenAccent : (statusText == "Low" ? Colors.orangeAccent : Colors.white30);

  // Text Colors
  const Color textPrimary = Colors.white;
  const Color textSecondary = Colors.white54; // For "Normal" and "30 min"
  const Color textMuted = Colors.white24; // For Grid labels and "00" hours

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.03)), // Almost invisible border
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Text(duration, style: const TextStyle(color: textSecondary, fontSize: 16)),
              ],
            ),
            Row(
              children: [
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 14)),
                SizedBox(width: 4),
                // Icon(Icons.keyboard_arrow_down, color: textMuted, size: 18),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Progress Bar
        Stack(
          children: [
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2.5)),
            ),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 5,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(desc, style: const TextStyle(color: textSecondary, fontSize: 13, height: 1.5)),
      ],
    ),
  );
}


Widget _buildGridRow(BuildContext context, String label, Color color) {
  return Row(
    children: [
      SizedBox(
        width: 55,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color.withOpacity(0.92), fontSize: 12 * SizeConfigs.textScale),
          // style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)
        ),
      ),
      const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
    ],
  );
}

Widget _buildTodayAnalysisUI(BuildContext context, ProgressController controller) {
  return LayoutBuilder(
    builder: (context, constraints) {
      double availableWidth = constraints.maxWidth;
      double ringContainerSize = availableWidth * 0.55;

      return Obx(
        () => Column(
          children: [
            Row(
              children: [
                // Left: Concentric Rings
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: ringContainerSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Duration (Primary Sleep Metric) -> Primary Purple
                        _ring(
                          val: controller.todayDurationScore.value / 100,
                          size: ringContainerSize,
                          color: AppColors.moonColor, // #7100CD - Bold Purple
                          ringKey: 'duration',
                        ),

                        // 2. Sleep Phases (Recovery) -> Bright Blue
                        _ring(
                          val: controller.todayPhasesScore.value / 100,
                          size: ringContainerSize * 0.84,
                          color: AppColors.blueColor, // #2563EB - Clear Blue
                          ringKey: 'phases',
                        ),

                        // 3. Environment (Context) -> Animation End/Violet
                        _ring(
                          val: controller.todayEnvScore.value / 100,
                          size: ringContainerSize * 0.70,
                          color: AppColors.textColor, // #875df6 - Soft Violet
                          ringKey: 'env',
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.lang.sleepScore,
                              style: TextStyle(color: Colors.white54, fontSize: 11 * SizeConfigs.textScale),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${controller.todaySleepScore.value.toInt()}",
                                  style: TextStyle(color: Colors.white, fontSize: 32 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0, left: 5),
                                  child: Text(
                                    "/100",
                                    style: TextStyle(color: Colors.white38, fontSize: 13 * SizeConfigs.textScale),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Side Labels
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(context,context.lang.sleepSpan, "${controller.todayDurationScore.value.toInt()}/100", AppColors.moonColor),
                      const SizedBox(height: 12),
                      _legend(context, context.lang.atmosphere, "${controller.todayEnvScore.value.toInt()}/100", AppColors.blueColor),
                      const SizedBox(height: 12),
                      _legend(context,context.lang.deepRecovery, "${controller.todayPhasesScore.value.toInt()}/100", AppColors.textColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Bottom Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // _stat(context, Icons.bed_outlined, "Rest Period", controller.todayTimeInBed.value),
                // // Use Vertical divider for alignment
                // Container(height: 20, width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 10)),
                // _stat(context, Icons.auto_awesome_outlined, "Actual Rest", controller.todayTimeAsleep.value),
                _stat(context, Icons.bedtime_rounded,context.lang.restPeriod, controller.todayTimeInBed.value, AppColors.moonColor),
                const SizedBox(width: 12), // Spacer instead of a divider for a modern look
                _stat(context, Icons.auto_awesome_rounded,context.lang.actualRest, controller.todayTimeAsleep.value, AppColors.greenColor),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _ring({required double val, required double size, required Color color, required String ringKey}) {
  return TweenAnimationBuilder<double>(
    // Providing a UniqueKey based on the ring identity (e.g., 'duration')
    // prevents the animation from jumping or playing twice.
    key: ValueKey(ringKey),
    tween: Tween<double>(begin: 0.0, end: val),
    duration: const Duration(milliseconds: 1500),
    curve: Curves.easeOutCubic,
    builder: (context, animatedValue, child) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: animatedValue,
          strokeWidth: size * 0.06,
          color: color,
          backgroundColor: color.withOpacity(0.1),
          strokeCap: StrokeCap.round, // This gives the single rounded edge at the tip
        ),
      );
    },
  );
}


Widget _legend(BuildContext context, String label, String val, Color color) => Container(
  margin: const EdgeInsets.only(bottom: 10), // Space between items
  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
  decoration: BoxDecoration(
    color: color.withOpacity(0.05), // Subtle tint background
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withOpacity(0.1), width: 1),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Vertical Line instead of a dot for a modern look
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Marquee(
              child: Text(
                label.toUpperCase(), // Uppercase for a technical, clean look
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white38, fontSize: 7.5 * SizeConfigs.textScale, fontWeight: FontWeight.bold, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 11),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: val.split('/')[0], // The score (e.g., 85)
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * SizeConfigs.textScale,
                  fontWeight: FontWeight.bold,
                  // fontFamily: 'Orbitron', // Use a tech font if available, else default
                ),
              ),
              TextSpan(
                text: " / 100",
                style: TextStyle(color: Colors.white24, fontSize: 11 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

Widget _stat(BuildContext context, IconData icon, String label, String time, Color accentColor) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      // Using a very faint background to define the area
      color: AppColors.white10.withOpacity(0.02),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.white10.withOpacity(0.05)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon with a subtle glow/background
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: accentColor, size: 20 * SizeConfigs.textScale),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(color: Colors.white38, fontSize: 8.5 * SizeConfigs.textScale, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

