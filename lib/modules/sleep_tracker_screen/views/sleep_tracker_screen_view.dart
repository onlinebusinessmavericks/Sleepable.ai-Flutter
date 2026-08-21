import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/constants/colors.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../alarm/controllers/alarm_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import '../../sleep_sound/widget/MixBarWidget.dart';
import '../controllers/sleep_tracker_screen_controller.dart';
import '../controllers/tracker_exit_guard.dart';

class SleepTrackerScreen extends StatefulWidget {
  @override
  _SleepTrackerScreenState createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>  {
  final controller = Get.find<SleepTrackerController>();

  @override
  void initState() {
    print("---------------init call---------------");
    super.initState();
  }

  @override
  void dispose() {
    print("---------------dispose call---------------");
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF001933),
        body: Stack(
          children: [
            // 1. The Main Content (Buttons, Waves, etc.)
            Obx(() {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: controller.showIntro.value
                    ? _buildIntroText(context)
                    : const _MainSleepScreen(),
              );
            }),

            Obx(() {
              final dimValue = controller.dimAmount.value;
              // Jab screen dimmed ho, tab click "Ignore" mat karo taaki resetDimTimer trigger ho sake
              // Lekin buttons ko click karne dene ke liye overlay ko transparent rakho target points par.

              return IgnorePointer(
                ignoring: dimValue < 0.1, // Jab light ho toh overlay touch block na kare
                child: GestureDetector(
                  onTap: () => controller.resetDimTimer(),
                  child: AnimatedOpacity(
                    duration: const Duration(seconds: 1), // 5s bahut zyada hai, 2s smooth lagta hai
                    opacity: dimValue,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black, // Pure black is better for OLED
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  Widget _buildIntroText(BuildContext context) {
    final lang = context.lang;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.goodNight,// "Good night",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(lang.startingSleepTracker, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 4),
            Text(lang.keepChargerConnected, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white54, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// -------------------- Main Sleep Screen --------------------
class _MainSleepScreen extends StatefulWidget {
  const _MainSleepScreen();

  @override
  State<_MainSleepScreen> createState() => _MainSleepScreenState();
}

class _MainSleepScreenState extends State<_MainSleepScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// One shared ticker drives all waves (cheaper than many controllers).
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      // ~12fps feel — smoother on mid devices overnight
      duration: const Duration(milliseconds: 3200),
    );
    _syncWaveTicker();
  }

  void _syncWaveTicker() {
    final resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (resumed) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else if (_waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncWaveTicker();
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final controller = Get.find<SleepTrackerController>();
    if (!Get.isRegistered<AlarmController>()) {
      Get.put(AlarmController(), permanent: true);
    }
    final alarmController = Get.find<AlarmController>();

    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: RepaintBoundary(
                  // Lower Lottie frame rate to reduce overnight jank
                  child: Lottie.asset(
                    Assets.lottieCloud,
                    repeat: true,
                    fit: BoxFit.contain,
                    height: 220,
                    frameRate: const FrameRate(12),
                  ),
                ),
              ),

              Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTopHeader(controller, context),
                  const Spacer(flex: 1),
                  _buildBatteryWarning(controller),
                  const Spacer(flex: 1),
                  _buildTimeSection(controller, alarmController, context),
                  const Spacer(flex: 2),
                  _buildMixBarSection(size, context),
                  const Spacer(flex: 2),
                  _buildQuitButton(size, controller, context),
                  const Spacer(flex: 4),
                ],
              ),

              RepaintBoundary(
                child: Stack(
                  children: List.generate(_waveConfigs.length, (i) => Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: WavePainter(
                          animation: _waveController,
                          phase: i * 0.4,
                          color: _waveConfigs[i]['color'] as Color,
                          amplitude: _waveConfigs[i]['amplitude'] as double,
                          stroke: _waveConfigs[i]['stroke'] as double,
                          frequency: _waveConfigs[i]['frequency'] as double,
                        ),
                        size: Size(size.width, 140),
                      ),
                    ),
                  )),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildTopHeader(SleepTrackerController controller, BuildContext context) {
    return Column(
      children: [
        // 1. Static Asset - NO Obx here. This builds once and stays in memory.
        Image.asset(Assets.alarmSleeptrackerlogo, width: 150),

        const SizedBox(height: 10),

        // 2. Dynamic DB Text - ONLY wrap the moving parts in Obx.
        Obx(() {
          final db = controller.ambientNoise.value;
          final finiteDb = db.isFinite ? db : 0.0;

          return Text(
            "${finiteDb.abs().toStringAsFixed(0)} dB",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: controller.getDbColor(finiteDb),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          );
        }),

        const SizedBox(height: 4),

        // 3. Static Label - Built once.
         Text(
          context.lang.ambientNoise,
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }


  Widget _buildTimeSection(SleepTrackerController controller, AlarmController alarmController, BuildContext context) {
    return Column(
      children: [
        Obx(() => GestureDetector(
          onTap: () => Get.toNamed(Routes.alarm),
          child: Text(
            controller.currentTime.value,
            style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
          ),
        )),
        const SizedBox(height: 8),
        Obx(() {
          // 1. Check if the alarm is actually toggled ON
          final isAlarmOn = alarmController.wakeUp.value;
          final time = alarmController.nextAlarmTime.value;

          // 2. Determine what string to display
          String displayTime;
          if (!isAlarmOn) {
            displayTime = "Off"; // 👈 Force "Off" if the switch is disabled
          } else if (time.isNotEmpty) {
            displayTime = time;
          } else if (controller.storedTime.value.isNotEmpty) {
            displayTime = controller.storedTime.value;
          } else {
            displayTime = "Not Set";
          }

          // 3. Render the UI
          return GestureDetector(
            onTap: () => Get.toNamed(Routes.alarm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
              child: Text(
                isAlarmOn ? "Alarm $displayTime" : "Alarm Off", // Changes format completely when off
                style: const TextStyle(color: Colors.white70, fontSize: 18, decoration: TextDecoration.underline),
              ),
            ),
          );
        }),
      ],
    );
  }
  Widget _buildBatteryWarning(SleepTrackerController trackerController) {
    final lang = Get.context!.lang;
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Obx(() {
      final isSettingEnabled = profileController.batteryWarning.value;
      final isBatteryLow = trackerController.showBatteryWarning.value;
      final isCharging = trackerController.isCharging.value; // Listen to charging state

      // 🔥 Hide if:
      // 1. Setting is off in Profile OR
      // 2. Battery is fine OR
      // 3. Phone is currently charging
      if (!isSettingEnabled || !isBatteryLow || isCharging) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.battery_alert_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children:  [
                Text(
                  lang.preventShutdown,
                  style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                    lang.connectCharger,// "Connect device to charger",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
  Widget _buildMixBarSection(Size size, BuildContext context) {
    final SleepSoundController soundController = Get.find<SleepSoundController>();
    return Obx(() {
      final hasSounds = soundController.playingSounds.isNotEmpty || soundController.playingMusic.isNotEmpty;
      if (hasSounds) {
        return SizedBox(width: size.width * 0.9, child: MixBarWidget(isFromsleepTracker: true));
      }
      return GestureDetector(
        onTap: () => Get.toNamed(Routes.sleepSound, arguments: {"fromMixBar": true}),
        child: Container(
          width: size.width * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50)),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.play_arrow_rounded, color: Colors.white)),
              const SizedBox(width: 12),
              const Text("No mix added", style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuitButton(Size size, SleepTrackerController controller, BuildContext context) {
    double buttonSize = (size.width * 0.25).clamp(80.0, 150.0);
    return GestureDetector(
      onTap: () async {
        await Haptics.vibrate(HapticsType.light, useAndroidHapticConstants: true);
        controller.resetDimTimer();
        _showQuitSheet(context);
      },
      child: Container(
        width: buttonSize, // Use fixed size instead of % for the circle button to keep it circular
        height: buttonSize,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Text("Quit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// -------------------- Wave Configurations (2 layers — light overnight) --------------------
final List<Map<String, dynamic>> _waveConfigs = [
  {'color': Colors.white.withOpacity(0.35), 'amplitude': 12.0, 'stroke': 2.0, 'frequency': 2.8},
  {'color': Colors.white.withOpacity(0.85), 'amplitude': 22.0, 'stroke': 2.8, 'frequency': 3.8},
];

// -------------------- Wave Painter --------------------
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double phase;
  final Color color;
  final double amplitude;
  final double stroke;
  final double frequency;

  WavePainter({
    required this.animation,
    required this.color,
    required this.amplitude,
    required this.stroke,
    required this.frequency,
    this.phase = 0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..isAntiAlias = false;

    final path = Path();
    const double baseWave = 2 * pi;
    final phaseOffset = (animation.value + phase) * baseWave;

    for (double x = 0; x <= size.width; x += 10) {
      final progress = (x / size.width) * baseWave * frequency;
      final y = size.height / 2 + sin(progress + phaseOffset) * amplitude;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.stroke != stroke ||
      oldDelegate.frequency != frequency ||
      oldDelegate.phase != phase;
}

void _showQuitSheet(BuildContext context) {
  final homeController = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  print("----title----${homeController.sleepStatus.value?.title}");
  print("----title----${homeController.sleepStatus.value?.subtitle}");
  // final title = homeController.sleepStatus.value?.title ?? "Your sleep wasn’t proper last night";
  // final subtitle = homeController.sleepStatus.value?.subtitle ??
  //     "Keep tracking to improve your sleep pattern.\nStay consistent for better results.";
  // 1. Title Default: A friendly but firm observation
  final title = homeController.sleepStatus.value?.title ??
      "Your sleep wasn’t quite right";

// 2. Subtitle Default: Focus on the "Consistency" benefit
  final subtitle = homeController.sleepStatus.value?.subtitle ??
      "Tracking every night helps us provide better insights for your rest.";
  Get.bottomSheet(
    SafeArea(
      child: Container(
        width: double.infinity,
        height: 540,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF0A152F),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(Assets.lottieMonkeySleep, fit: BoxFit.cover, repeat: true, height: 200, width: 200,frameRate: FrameRate(24),addRepaintBoundary: true,),
            // const Icon(Icons.nightlight_round, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w200),
      
              //style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 30),
      
            // 🟢 Keep Tracking (enabled)
            ElevatedButton(
              onPressed: () {
                Get.back(); // close the sheet only
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(90, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                context.lang.keepTracking,//"Keep Tracking",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w200) ?? const TextStyle(),
              ),
            ),
            const SizedBox(height: 14),
      
            // ⚪ Quit Now (disabled look)
            ElevatedButton(
              onPressed: () {
                Get.back();
                final AlarmController controller = Get.find<AlarmController>();
                controller.prepareBedtimePicker();
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showNotBedTimeSheet(context);
                });
                // Get.offAndToNamed(Routes.dashboard);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                // Remove background
                shadowColor: MaterialStateProperty.all(Colors.transparent),
                // Remove shadow
                surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
                // Remove tint (Material 3)
                foregroundColor: MaterialStateProperty.all(Colors.white70),
                // Text color
                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 48)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                overlayColor: MaterialStateProperty.all(Colors.transparent), // Remove splash/press color
              ),
              child: Text(
                context.lang.quitNow,// "Quit Now",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w200) ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void _showNotBedTimeSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: false,
    transitionAnimationController: AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 500)),
    builder: (context) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        height: SizeConfigs.screenHeight * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0A152F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: openNotBedTimeAlarmBottomSheet(context),
      );
    },
  );
}

openNotBedTimeAlarmBottomSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);
  final AlarmController controller = Get.find<AlarmController>();
  // controller.prepareBedtimePicker();
  // 1. Reset the sync flag and clear pending UI strings
  controller.bedTimeWheelsSynced = false;


  // 2. Trigger Safe Sync after the BottomSheet finishes its opening animation
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (controller.hourBedTimeController?.hasClients ?? false) {
        controller.syncBedTimeWheels();
      }
    });
  });

  return SafeArea(
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
        child: Column(
          children: [
            SizedBox(height: 20 * SizeConfigs.paddingScale),
    
            Text(
              context.lang.notBedtimeYet,// "Not bedtime yet",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
            Text(
              context.lang.sleepableWillRemind,// "Sleepable will remind you to sleep at:",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
    
            const Spacer(),
    
            // --- TIME PICKER CONTAINER ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HOUR WHEEL
                  _buildSafeWheel(
                    context,
                    controller: controller.hourBedTimeController!,
                    onChanged: (index) {
                      int val = (index % 12);
                      if (val == 0) val = 12;
                      controller.bedHour.value = val;
                    },
                    itemBuilder: (index) {
                      int displayHour = (index % 12);
                      if (displayHour == 0) displayHour = 12;
                      return Obx(() => _buildWheelText(
                        context,
                        displayHour.toString().padLeft(2, '0'),
                        controller.bedHour.value == displayHour,
                      ));
                    },
                  ),
    
                  _buildFixedLabel(context, "h"),
                  _buildFixedLabel(context, ":"),
    
                  // MINUTE WHEEL
                  _buildSafeWheel(
                    context,
                    controller: controller.minuteBedTimeController!,
                    onChanged: (index) {
                      controller.bedMinute.value = index % 60;
                    },
                    itemBuilder: (index) {
                      int displayMin = index % 60;
                      return Obx(() => _buildWheelText(
                        context,
                        displayMin.toString().padLeft(2, '0'),
                        controller.bedMinute.value == displayMin,
                      ));
                    },
                  ),
    
                  _buildFixedLabel(context, "min"),
    
                  const SizedBox(width: 15),
    
                  // AM / PM WHEEL
                  _buildSafeWheel(
                    context,
                    controller: controller.amPmBedTimeController!,
                    itemCount: 2,
                    onChanged: (index) {
                      controller.bedIsAm.value = (index == 0);
                    },
                    itemBuilder: (index) {
                      final text = index == 0 ? "AM" : "PM";
                      return Obx(() => _buildWheelText(
                        context,
                        text,
                        controller.bedIsAm.value == (index == 0),
                      ));
                    },
                  ),
                ],
              ),
            ),
    
            const Spacer(),
    
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Obx(() => GestureDetector(
                // 🔥 1. THE CLICK: Vibrate and Shrink the moment the finger touches
                onTapDown: (_) {
                  Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true); // Short, sharp "click"
                  controller.updateScale(0.92); // Deep sink for better feedback
                },
    
                // 🔥 2. THE ACTION: Run logic and pop back up on release
                onTapUp: (_) {
                  controller.updateScale(1.0);
    
                  // Execute your logic
                  _handleSetReminder(context, controller);
                },
    
                // 🛡️ THE SAFETY: Reset if the user slides their finger away
                onTapCancel: () => controller.updateScale(1.0),
    
                child: AnimatedScale(
                  scale: controller.scale.value,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      context.lang.setReminder,//   "Set Reminder",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16 * SizeConfigs.textScale,
                      ),
                    ),
                  ),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  context.lang.notNow,//"Not now",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- HELPER WIDGETS ---

Widget _buildSafeWheel(
    BuildContext context, {
      required FixedExtentScrollController controller,
      required Function(int) onChanged,
      required Widget Function(int) itemBuilder,
      int itemCount = 10000,
    }) {
  return SizedBox(
    height: 150,
    width: 50,
    child: ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 35,
      perspective: 0.002,
      useMagnifier: true,
      magnification: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        HapticFeedback.selectionClick();
        onChanged(index);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) => itemBuilder(index),
      ),
    ),
  );
}

Widget _buildWheelText(BuildContext context, String text, bool isSelected) {
  return Center(
    child: Text(
      text,
      style: isSelected
          ? Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.white,
        fontSize: 25 * SizeConfigs.textScale,
      )
          : Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textBoldColor,
        fontSize: 14 * SizeConfigs.textScale,
        fontWeight: FontWeight.w300,
      ),
    ),
  );
}

Widget _buildFixedLabel(BuildContext context, String label) {
  return Text(
    label,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppColors.white,
      fontSize: 25 * SizeConfigs.textScale,
    ),
  ).paddingSymmetric(horizontal: 2);
}
void _handleSetReminder(BuildContext context, dynamic controller) async {
  // 1. Calculate the 24h format for the API
  int h = controller.bedHour.value;
  if (!controller.bedIsAm.value && h != 12) h += 12; // PM
  if (controller.bedIsAm.value && h == 12) h = 0; // 12 AM

  final String formattedBedtime =
      "${h.toString().padLeft(2, '0')}:${controller.bedMinute.value.toString().padLeft(2, '0')}:00";

  // Enable reminders only if bedtime is far enough that the server won't
  // immediately push bedtime_reminder (which remounted Home after quit).
  final bool enableReminders =
      TrackerExitGuard.shouldEnableSleepRemindersOnQuit(formattedBedtime);

  final SleepTrackerController? sleepCtrl = Get.isRegistered<SleepTrackerController>()
      ? Get.find<SleepTrackerController>()
      : null;

  if (sleepCtrl != null) {
    await sleepCtrl.clearLocalTrackingFlags();
  } else {
    await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
  }

  TrackerExitGuard.beginExitNavigation();
  Get.offAllNamed(Routes.dashboard);

  Future(() async {
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        profileCtrl.updateSettings(
          customNewData: profileCtrl.settings.value?.copyWith(
            remindAt: formattedBedtime,
            sleepReminders: enableReminders,
          ),
        );
      }

      if (sleepCtrl != null) {
        sleepCtrl.trackerState.value = TrackerState.idle;
        await sleepCtrl.performCleanup(sleepCtrl).timeout(
          const Duration(seconds: 12),
          onTimeout: () {},
        );
      } else {
        await SleepTrackerController.emergencyStopOrphanTracker();
      }
    } catch (e) {
      debugPrint("quit reminder background error: $e");
      try {
        await SleepTrackerController.emergencyStopOrphanTracker();
      } catch (_) {}
    } finally {
      TrackerExitGuard.endExitNavigation();
      await TrackerExitGuard.showRatingOnceAfterExit();
      // Defer Progress refresh so Home stays responsive after Quit
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          if (!Get.isRegistered<ProgressController>()) {
            Get.put(ProgressController());
          }
          await Get.find<ProgressController>().loadAllData();
        } catch (_) {}
      });
    }
  });
}