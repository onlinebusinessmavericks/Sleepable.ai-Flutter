import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../../routes/app_pages.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../sleep_sound/controllers/sleep_sound_controller.dart';
import 'tracker_exit_guard.dart';
import 'package:battery_plus/battery_plus.dart';
enum TrackerState { idle, musicPlaying, silenceRecording }
@pragma('vm:entry-point')
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  // 🟢 Error 1 Fix: onStart ab Future<void> hona chahiye
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    debugPrint("Background Task Started");
  }

  // 🟢 Error 3 Fix: onRepeatEvent mein sirf timestamp aata hai
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Isse khali chhod dein agar use nahi karna
  }

  // 🟢 Error 2 Fix: onDestroy mein timestamp aur bool aata hai
  @override
  Future<void> onDestroy(DateTime timestamp, bool isUserAction) async {
    debugPrint("Background Task Destroyed");
  }

  // Notification button click handler
  @override
  void onNotificationButtonPressed(String id) {
    debugPrint("Notification button pressed in background: $id");
    // Main app (Controller) ko data bhej rahe hain
    FlutterForegroundTask.sendDataToMain(id);
  }
}
class SleepTrackerController extends GetxController with WidgetsBindingObserver {
  // ===================== STATE =====================
  final trackerState = TrackerState.idle.obs;

  // ===================== UI =====================
  RxBool showIntro = true.obs;
  RxString currentTime = ''.obs;
  RxDouble ambientNoise = 0.0.obs;
  RxDouble rawDb = 0.0.obs;

  Timer? _uiDbTimer;
  Timer? _clockTimer;

  // ===================== AUDIO =====================
  final AudioRecorder recorder = AudioRecorder();
  RxBool isRecording = false.obs;
  String? currentFilePath;

  // ===================== NOISE =====================
  late NoiseMeter _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSub;
  bool _noiseStarted = false;

  // ===================== RECORD CONTROL =====================
  Timer? _silenceTimer;
  Timer? _maxRecordTimer;

  DateTime? eventStartTime;
  DateTime? lastSoundTime;
  DateTime? _lastSavedTime;

  // ===================== TUNING =====================
  double _baselineDb = 30;
  double _smoothedDb = 0;

  final Duration silenceGap = const Duration(seconds: 8);
  final Duration minRecordDuration = const Duration(seconds: 3);
  final Duration maxRecordDuration = const Duration(minutes: 15);
  final Duration recordCooldown = const Duration(seconds: 5);

  // ===================== BRIGHTNESS =====================
  Timer? _amplitudeTimer;
  Timer? _idleDimTimer;
  RxString recordingStatus = ''.obs;
  RxString storedTime = "".obs;
  RxBool isCalibrating = false.obs;
  DateTime? _calibrationStartTime;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  RxDouble motionIntensity = 0.0.obs;
  final List<Map<String, dynamic>> nightNoiseMap = [];
  final List<Map<String, dynamic>> nightMotionMap = [];
  Timer? _mappingTimer;
  // 🔋 --- BATTERY LOGIC --- 🔋
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  RxBool isCharging = false.obs;
  RxInt batteryLevel = 100.obs;
  RxBool showBatteryWarning = false.obs;
  void Function(Object)? _taskDataCallback;
  bool _taskDataCallbackAttached = false;
  bool _lifecycleObserverAttached = false;

  // ===================== INIT =====================
  @override
  void onInit() {
    super.onInit();
    _ensureTaskDataCallback();
    _initController();
  }

  void _ensureTaskDataCallback() {
    if (_taskDataCallbackAttached) return;
    _taskDataCallback = (data) {
      print("📥 DATA RECEIVED: $data");
      if (data == 'stop_service') {
        forceQuitFromNotification();
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
    _taskDataCallbackAttached = true;
  }

  void _detachTaskDataCallback() {
    if (!_taskDataCallbackAttached || _taskDataCallback == null) return;
    try {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    } catch (_) {}
    _taskDataCallbackAttached = false;
  }
  Future<void> triggerInstantBackgroundService() async {
    // toast("🔍 Step 1: Requesting Permissions...");
    bool hasPermission = await _checkPermissions();
    if (!hasPermission) {
      // toast("❌ Error: Microphone/Notification Permission Denied!");
      return;
    }

    // toast("🛠️ Step 2: Initializing Foreground Config...");
    _initService();

    // toast("📡 Step 3: Pushing Service Native Request...");
    await _startNoiseMeter();
  }
  Future<void> _initController() async {
    final lang = Get.context!.lang;
    // New tracking session — re-attach resources
    _ensureTaskDataCallback();
    if (!_lifecycleObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverAttached = true;
    }

    await _checkPermissions();
    await _configureAudioSession();

    // 🚀 CALL IT HERE
    _initService();
    await _startNoiseMeter();
    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    _initBatteryListener();
    WakelockPlus.enable();

    _updateTime();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _startIntro();

    await Future.delayed(const Duration(milliseconds: 300));

    trackerState.value = TrackerState.silenceRecording;

    // Now when this is called, the service is already initialized
    await _startNoiseMeter();
    _startMotionTracking(); // 🟢 Start Accelerometer

    // 2. Start the Data Logger (The "Night Map")
    _startNightMapping();
    _startUiDbTimer();

    final prefs = await SharedPreferences.getInstance();
    storedTime.value = prefs.getString("wake_up_time_display") ?? lang.noTimeSet;

    print("📦 Stored time from prefs: ${storedTime.value}");

    resetDimTimer();
  }

  // Inside SleepTrackerController
  RxDouble dimAmount = 0.0.obs;
  Timer? _dimTimer;



  void _initBatteryListener() async {
    // 1. Get the initial state right when the screen opens
    batteryLevel.value = await _battery.batteryLevel;
    final BatteryState initialState = await _battery.batteryState;
    isCharging.value = (initialState == BatteryState.charging || initialState == BatteryState.connectedNotCharging);

    _evaluateBatteryWarning(); // Check if we should show the warning

    // 2. Listen for changes (e.g., user plugs in the charger)
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      isCharging.value = (state == BatteryState.charging || state == BatteryState.connectedNotCharging);
      batteryLevel.value = await _battery.batteryLevel;

      _evaluateBatteryWarning(); // Re-evaluate whenever state changes
    });
  }

  void _evaluateBatteryWarning() {
    // Logic: Show warning if Battery is LESS than 20% AND it is NOT charging
    if (!isCharging.value && batteryLevel.value <= 20) {
      showBatteryWarning.value = true;
    } else {
      showBatteryWarning.value = false;
    }
  }
  void resetDimTimer() {
    // 1. Brighten the UI immediately by removing the black overlay
    dimAmount.value = 0.0;

    _dimTimer?.cancel();

    // 2. Start a timer to dim the UI after 10 seconds of inactivity
    _dimTimer = Timer(const Duration(seconds: 10), () {
      if (_isAppResumed) {
        // Just apply the visual overlay.
        // The hardware stays at whatever the user/system set it to.
        dimAmount.value = 0.85;
      }
    });
  }
  void _startMotionTracking() {
    _accelSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Calculate total movement magnitude
      // Formula: sqrt(x² + y² + z²)
      double magnitude = (event.x.abs() + event.y.abs() + event.z.abs());

      if (magnitude > 0.5) {
        // Threshold to ignore tiny vibrations
        motionIntensity.value = magnitude;
        _handleMovement(magnitude);
      }
    });
  }

  void _startNightMapping() {
    _mappingTimer?.cancel();
    _mappingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (trackerState.value == TrackerState.idle) {
        timer.cancel();
        return;
      }

      final timestamp = DateTime.now().toIso8601String();

      // Log noise floor (helps detect background music vs silence)
      nightNoiseMap.add({"t": timestamp, "db": rawDb.value.toStringAsFixed(1), "is_recording": isRecording.value});

      // Log motion (The #1 signal for Deep Sleep)
      nightMotionMap.add({"t": timestamp, "m": motionIntensity.value.toStringAsFixed(2)});
    });
  }

  void _handleMovement(double magnitude) {
    // Logic: High magnitude = "Awake" or "Light Sleep"
    // If moving significantly, you might want to reset your silence timer
    if (magnitude > 2.0) {
      debugPrint("🏃 Significant movement detected: $magnitude");
      // Optional: record a clip if movement is violent (tossing)
    }
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.mixWithOthers |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
      // AVAudioSessionCategoryOptions.allowBluetooth, // Added back for completeness
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      // 🟢 Use gainTransientMayDuck: This is the most "sharing" focus type.
      // It tells Android "I'm using audio, but I don't mind if others keep playing."
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false, // 🟢 CRITICAL: Prevents auto-pause
    ));
    await session.setActive(true);
  }
  // ===================== INTRO =====================
  Future<void> _startIntro() async {
    await Future.delayed(const Duration(seconds: 2));
    showIntro.value = false;
    await startCalibration();

    // After calibration is done, set state to recording/monitoring
    trackerState.value = TrackerState.silenceRecording;
  }

  Future<void> startCalibration() async {
    final lang = Get.context?.lang;
    isCalibrating.value = true;
    _calibrationStartTime = DateTime.now();
    recordingStatus.value = lang?.calibratingSensors ?? "Calibrating room sensors...";

    // We reset baseline to current raw noise to start fresh
    _baselineDb = rawDb.value > 0 ? rawDb.value : 30.0;

    await Future.delayed(const Duration(seconds: 5));

    isCalibrating.value = false;
    recordingStatus.value = "";
    debugPrint("✅ Calibration Complete. Final Baseline: ${_baselineDb.toStringAsFixed(1)} dB");
  }

  DateTime? _lastProcessTime;
  bool _isAppResumed = true; // Update this via WidgetsBindingObserver


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;

    if (_isAppResumed) {
      WakelockPlus.enable();
      _startUiDbTimer(); // Restart only when user is looking at the screen
      resetDimTimer();
    } else {
      // 🔋 STOP UI UPDATES - Ye hang hone se bachayega
      _uiDbTimer?.cancel();

      if (trackerState.value == TrackerState.idle) {
        WakelockPlus.disable();
      } else {
        // Background monitoring ke liye wakelock on rakhein
        WakelockPlus.enable();
      }
    }
    super.didChangeAppLifecycleState(state);
  }
  double _getDynamicGap(double baseline) {
    // 🟢 If room is louder than 65dB (Full Volume Music),
    // we increase the gap to 12.0 so the music's own beats don't trigger it.
    if (baseline > 65) return 8.0;
    if (baseline > 55) return 7.0;
    if (baseline > 45) return 8.0;
    return 5.0;
  }
  Future<void> _onNoise(NoiseReading reading) async {
    if (trackerState.value != TrackerState.silenceRecording && !isCalibrating.value) return;

    final now = DateTime.now();
    if (_lastProcessTime != null && now.difference(_lastProcessTime!).inMilliseconds < 1000) return;
    _lastProcessTime = now;

    double db = reading.meanDecibel;

    // 🔥 PLATFORM SPECIFIC SCALING
    if (Platform.isIOS) {
      // iOS par values negative hoti hain (-120 to 0)
      if (db.isInfinite || db.isNaN || db < -120) {
        db = 0.0;
      } else {
        // Negative ko 0-120 ki range mein convert kar rahe hain
        db = (db + 120).clamp(0.0, 120.0);
      }
    } else {
      // 🟢 ANDROID: Aapka purana "Perfect" logic (0 to 100 range)
      if (db.isInfinite || db.isNaN) db = 0.0;
      db = db.clamp(0.0, 100.0);
    }

    // Baaki saara calculation (Smoothing/Baseline) same rahega
    double smoothed = _smoothDb(db);
    rawDb.value = smoothed;
    // UI update trigger - ab dB numbers move honge
    if (_isAppResumed) {
      rawDb.value = smoothed;
    }

    if (isCalibrating.value) {
      _baselineDb = (_baselineDb * 0.5) + (smoothed * 0.5);
      return;
    }

    if (!isRecording.value) {
      if (smoothed < _baselineDb) {
        _baselineDb = smoothed;
      } else if (smoothed > 45) {
        _baselineDb = (_baselineDb * 0.95) + (smoothed * 0.05);
      } else {
        _baselineDb = (_baselineDb * 0.98) + (smoothed * 0.02);
      }

      double sensitivityGap = (smoothed > 45) ? 5.0 : 4.0;
      final triggerDb = _baselineDb + sensitivityGap;

      if (smoothed >= triggerDb) {
        if (_lastSavedTime != null && now.difference(_lastSavedTime!) < recordCooldown) return;

        debugPrint("🚀 TRIGGERED: $smoothed dB (Baseline: $_baselineDb, Gap: $sensitivityGap)");

        // 🔥 IMPORTANT: lastSavedTime update karein taaki cooldown kaam kare
        _lastSavedTime = now;

        await _startRecording();
        _resetSilenceTimer();
      }
    } else {
      if (smoothed >= (_baselineDb + 4.0)) {
        _resetSilenceTimer();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      debugPrint("🎙️ SWITCHING: Stopping NoiseMeter, starting AudioRecorder...");
      if (_noiseSub != null) {
        await _noiseSub?.cancel();
        _noiseSub = null;
        _noiseStarted = false;
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final cacheDir = await getTemporaryDirectory();
      final tempPath = '${cacheDir.path}/.sleep_cache_${DateTime.now().millisecondsSinceEpoch}.wav';

      await recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,

          // 🔥 FIX: iOS par 'null' ki jagah default config bhejni padegi
          androidConfig: Platform.isAndroid
              ? const AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition,
            audioManagerMode: AudioManagerMode.modeNormal,
          )
              : const AndroidRecordConfig(), // iOS ke liye default (non-null)

          echoCancel: false,
          noiseSuppress: false,
          autoGain: false,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: tempPath,
      );

      currentFilePath = tempPath;
      isRecording.value = true;
      eventStartTime = DateTime.now();

      // 📝 iOS debugging ke liye console mein print:
      if (Platform.isIOS) {
        debugPrint("🍎 [iOS] RECORDING STARTED: $tempPath");
      } else {
        debugPrint("✅ [Android] RECORDING ACTIVE: File saved to $tempPath");
      }

      _listenToAmplitude();

      _maxRecordTimer?.cancel();
      _maxRecordTimer = Timer(maxRecordDuration, () async {
        if (isRecording.value) {
          debugPrint("⏰ MAX DURATION REACHED (15m): Stopping.");
          await stopRecording();
        }
      });
    } catch (e) {
      debugPrint("❌ ERROR STARTING RECORDER: $e");
      // iOS par agar permission issue ho toh ye trigger hoga
      _startNoiseMeter();
    }
  }
  void _listenToAmplitude() {
    _amplitudeTimer?.cancel();
    print("🎤 [TRACKER] Amplitude Monitor Started.");

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {

      // Safety check prints
      if (trackerState.value == TrackerState.idle || !isRecording.value) {
        print("🛑 [TRACKER] Monitor Safety: Stopping timer to release Mic.");
        timer.cancel();
        _amplitudeTimer = null;
        return;
      }

      try {
        final amp = await recorder.getAmplitude();

        // Double check after async call
        if (trackerState.value == TrackerState.idle) {
          print("🛑 [TRACKER] Post-Amp Check: State is now IDLE, skipping logic.");
          return;
        }

        double currentDb = 105 + amp.current;
        double smoothed = _smoothDb(currentDb);
        rawDb.value = smoothed;

        // Log only every few seconds to keep console clean
        if (DateTime.now().second % 5 == 0 && DateTime.now().millisecond < 200) {
          print("🎤 [TRACKER] Monitoring... Current: ${smoothed.toStringAsFixed(1)} dB");
        }

        if (currentDb >= (_baselineDb + _getDynamicGap(_baselineDb))) {
          _resetSilenceTimer();
        }
      } catch (e) {
        print("❌ [TRACKER ERROR] Amplitude Check Failed: $e");
      }
    });
  }
  // ===================== SILENCE TIMER =====================
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(silenceGap, () async {
      if (isRecording.value) {
        await stopRecording();
      }
    });
  }

  void _startUiDbTimer() {
    _uiDbTimer?.cancel();
    _uiDbTimer = Timer.periodic(const Duration(seconds: 1), (_) { // 👈 1 second interval
      ambientNoise.value = rawDb.value;
    });
  }

  double _smoothDb(double newDb) {
    // Subtracting 10-15dB makes the UI numbers look like ShutEye/SleepCycle
    // while the internal logic still uses the raw hardware numbers.
    double displayDb = newDb - 10.0;
    _smoothedDb = (_smoothedDb * 0.4) + (displayDb * 0.6);
    return _smoothedDb.clamp(20.0, 100.0);
  }

  void _updateBaseline(double db) {
    _baselineDb = (_baselineDb * 0.7) + (db * 0.3);
  }

  void _updateTime() {
    final now = DateTime.now();
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    currentTime.value =
        "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} "
        "${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  void onClose() async {
    await releasePostSessionResources();
    try {
      if (isRecording.value) {
        await recorder.stop();
      }
      await recorder.dispose();
    } catch (_) {}
    super.onClose();
  }

  /// Release CPU/battery leftovers that permanent controller would otherwise keep
  /// after Wake/Quit (wakelock, battery stream, FGS callback, lifecycle observer).
  Future<void> releasePostSessionResources() async {
    try {
      trackerState.value = TrackerState.idle;

      _dimTimer?.cancel();
      _idleDimTimer?.cancel();
      _mappingTimer?.cancel();
      _amplitudeTimer?.cancel();
      _silenceTimer?.cancel();
      _maxRecordTimer?.cancel();
      _uiDbTimer?.cancel();
      _clockTimer?.cancel();

      await _noiseSub?.cancel();
      _noiseSub = null;
      _noiseStarted = false;
      await _accelSub?.cancel();
      _accelSub = null;

      await _batteryStateSubscription?.cancel();
      _batteryStateSubscription = null;

      _detachTaskDataCallback();

      if (_lifecycleObserverAttached) {
        WidgetsBinding.instance.removeObserver(this);
        _lifecycleObserverAttached = false;
      }

      nightNoiseMap.clear();
      nightMotionMap.clear();

      try {
        await WakelockPlus.disable();
      } catch (_) {}
    } catch (e) {
      debugPrint("releasePostSessionResources error: $e");
    }
  }

  Color getDbColor(double db) {
    if (db < 35) return Colors.green;
    if (db < 50) return Colors.yellow;
    if (db < 65) return Colors.orange;
    return Colors.red;
  }

  final RxBool isStopping = false.obs;

  /// 🌙 Stop Sleep Tracker
    Future<bool> stopSleepTracker(int sleepTrackerId) async {
      if (isStopping.value) return false;

      isStopping.value = true;

      try {
        // 🛑 STOP RECORDING SAFELY
        if (isRecording.value) {
          await stopRecording();
        }

        await _noiseSub?.cancel();
        _noiseStarted = false;
        _mappingTimer?.cancel();
        print("noiseHistory-----$nightNoiseMap");
        print("motionHistory-----$nightMotionMap");
        final response = await TrackerApis.stopSleepTracker(
          sleepTrackerId: sleepTrackerId,
        );

        if (response.success == true) {
          await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sleep_tracker_id');

          // 3. 🔥 THE FIX: Update the reactive variable in SleepSoundController
          // This makes the "Start Sleep" button REAPPEAR instantly
          if (Get.isRegistered<SleepSoundController>()) {
            Get.find<SleepSoundController>().isTrackingActive.value = false;
            debugPrint("📢 SleepSoundController notified: tracking is now FALSE");}
          debugPrint("✅ Sleep tracker stopped");
          return true;
        }

        return false;
      } catch (e) {
        debugPrint("❌ stopSleepTracker error: $e");
        return false;
      } finally {
        isStopping.value = false;
      }
    }

  void _initService() {
    final lang = Get.context!.lang;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sleep_tracker_channel',
        channelName: 'Sleepable AI Tracker',
        channelDescription:lang.serviceText, //'Analyzing sleep patterns and providing relaxation audio.',
        channelImportance: NotificationChannelImportance.MAX, // High priority
        priority: NotificationPriority.HIGH,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        // 🟢 CRITICAL: Ise FALSE rakhein taaki Home dabane par service na mare
        stopWithTask: false,
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
    );
  }
  Future<void> _startNoiseMeter() async {
    if (_noiseStarted) return;
    final lang = Get.context!.lang;

    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      try {
        final ServiceRequestResult success = await FlutterForegroundTask.startService(
          serviceId: 256,
          notificationTitle: lang.serviceTitle ?? 'Sleepable AI is Active',
          notificationText: lang.serviceText ?? 'Monitoring your sleep...',
          notificationIcon: const NotificationIcon(
            metaDataName: 'mipmap/ic_launcher',
          ),
        );

        // 🔥 DEBUG TOAST 1: Native plugin link response verify karne ke liye
        // toast("📊 Native Result: ${success.toString()}");

        if (Platform.isIOS) {
          await FlutterForegroundTask.updateService(
            notificationTitle: lang.serviceTitle ?? 'Sleepable AI is Active',
            notificationText: lang.serviceText ?? 'Monitoring your sleep...',
          );
          _noiseStarted = true;
          // 🔥 DEBUG TOAST 2: iOS notification bridge activation tracer
          // toast("🍏 iOS Foreground Channel Active!");
        } else {
          _noiseStarted = true;
        }
      } catch (e) {
        // 🔥 DEBUG TOAST 3: Kuch bhi catch exception hua toh direct trigger alert
        // toast("❌ Service Start Exception: ${e.toString()}");
      }
    } else {
      _noiseStarted = true;
    }

    if (_noiseStarted) {
      _noiseMeter = NoiseMeter();
      _noiseSub = _noiseMeter.noise.listen(_onNoise);
      trackerState.value = TrackerState.silenceRecording;

      // 🔥 DEBUG TOAST 4: Final pipeline complete sync trace
      // toast("🎙️ System Monitoring Active!");
    }
  }
  // Controller ke andar ye naya function add karein
  Future<void> forceQuitFromNotification() async {
    debugPrint("🚨 Notification Stop Triggered: Running Cleanup...");

    // Do NOT force-enable sleepReminders here — that caused an immediate
    // bedtime reminder after quit, then another Home navigation.
    await clearLocalTrackingFlags();

    TrackerExitGuard.beginExitNavigation();
    Get.offAllNamed(Routes.dashboard);

    try {
      await performCleanup(this).timeout(const Duration(seconds: 12), onTimeout: () {});
    } catch (e) {
      debugPrint("forceQuit cleanup error: $e");
      await emergencyStopOrphanTracker();
    } finally {
      TrackerExitGuard.endExitNavigation();
      unawaited(TrackerExitGuard.showRatingOnceAfterExit());
    }
  }

  // 3. Updated stopRecording for the 15-min re-record flow
  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    try {
      _maxRecordTimer?.cancel();
      _silenceTimer?.cancel();

      final path = await recorder.stop();
      isRecording.value = false;

      // Small delay to release hardware mic
      await Future.delayed(const Duration(milliseconds: 500));

      // 🔄 THE RE-RECORD FLOW:
      // Immediately start onng again for the next 15-min window
      // 🔄 THE RE-RECORD FLOW:
      if (trackerState.value == TrackerState.silenceRecording) {
        // 🟢 Ensure state is still active
        debugPrint("🔄 Background loop: Restarting listener...");
        await _startNoiseMeter();
      } else {
        debugPrint("🛑 Tracker is Idle. Stopping loop permanently.");
      }

      if (path == null) return;

      // Proceed with upload in the background...
      _uploadInBackground(path);
    } catch (e) {
      debugPrint("❌ Background Stop Error: $e");
      // Never restart meters during Wake/Quit cleanup (idle).
      if (trackerState.value == TrackerState.silenceRecording) {
        await _startNoiseMeter();
      }
    }
  }

  Future<bool> _checkPermissions() async {
    // 1. Check Microphone
    final micStatus = await Permission.microphone.request();
    print("🎙️ Mic Status: $micStatus");

    bool isNotificationGranted = false;

    // 2. Check Notification (Crucial for Foreground Service Visibility)
    if (Platform.isAndroid) {
      final NotificationPermission notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        final res = await FlutterForegroundTask.requestNotificationPermission();
        isNotificationGranted = (res == NotificationPermission.granted);
      } else {
        isNotificationGranted = true;
      }


    } else if (Platform.isIOS) {
      // 🔥 THE ABSOLUTE IOS NOTIFICATION FIX
      final notificationStatus = await Permission.notification.request();
      print("🔔 [iOS] Notification Request Status: $notificationStatus");
      isNotificationGranted = notificationStatus.isGranted;

    }

    // Master validation response
    bool finalResult = micStatus.isGranted && isNotificationGranted;

    return finalResult;
  }
  Future<void> _uploadInBackground(String path) async {
    final file = File(path);
    final now = DateTime.now();
    final start = eventStartTime ?? now;
    final duration = now.difference(start);

    // 1. Validation: Skip and delete if the clip is too short (garbage data)
    if (duration < minRecordDuration) {
      debugPrint("🗑️ Clip too short (${duration.inSeconds}s). Deleting cache.");
      if (await file.exists()) await file.delete();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final int savedSleepTrackerId = prefs.getInt('sleep_tracker_id') ?? 0;

      // ISO-8601 with timezone offset so server does not treat local as UTC
      final recordedAt = _formatRecordedAtWithOffset(start);
      final wallClockSeconds = duration.inSeconds.clamp(1, maxRecordDuration.inSeconds);

      final soundController = Get.find<SleepSoundController>();
      bool isAnythingPlayingInApp = soundController.playingSounds.isNotEmpty ||
          soundController.playingMusic.isNotEmpty;

      bool isMusicLikely = isAnythingPlayingInApp || (_baselineDb > 40.0);

      final Map<String, dynamic> extraData = {
        "baseline_db": _baselineDb.toStringAsFixed(1),
        "motion_at_trigger": motionIntensity.value.toStringAsFixed(2),
        "is_music_likely": isMusicLikely,
        "active_media_type": soundController.playingMusic.isNotEmpty
            ? soundController.playingMusic.first.categoryName
            : "None",
        "clip_duration_seconds": wallClockSeconds,
      };

      debugPrint("📤 Uploading Sleep Data: $extraData recordedAt=$recordedAt");

      await TrackerApis.uploadTrackerAudio(
        sleepTrackerId: savedSleepTrackerId,
        audioFile: file,
        recordedAt: recordedAt,
        wallClockSeconds: wallClockSeconds,
      );

      debugPrint("✅ Upload Successful for: $recordedAt (${wallClockSeconds}s wall)");
    } catch (e) {
      debugPrint("❌ Background Upload Failed: $e");
    } finally {
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Cache Cleared: Temporary file removed.");
      }
    }
  }

  /// Local wall time with numeric offset, e.g. 2026-08-14T02:15:30+05:30
  String _formatRecordedAtWithOffset(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final oh = offset.inHours.abs().toString().padLeft(2, '0');
    final om = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final stamp = DateFormat('yyyy-MM-ddTHH:mm:ss').format(local);
    return '$stamp$sign$oh:$om';
  }
  /// Re-attach wakelock / battery / FGS callback after a previous Wake release
  /// when starting another night on the permanent controller.
  Future<void> armSessionResources() async {
    _ensureTaskDataCallback();
    if (!_lifecycleObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverAttached = true;
    }
    if (_batteryStateSubscription == null) {
      _initBatteryListener();
    }
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  /// When alarm rings: stop the sleep session immediately so AI "wake time"
  /// = alarm ring time even if the user never taps Wake.
  Future<void> finalizeSessionAtAlarmRing() async {
    try {
      await prepareForAlarmRing();

      final prefs = await SharedPreferences.getInstance();
      final int savedId = prefs.getInt('sleep_tracker_id') ?? 0;

      await clearLocalTrackingFlags();
      try {
        await FlutterForegroundTask.stopService();
      } catch (_) {}
      await releasePostSessionResources();

      if (savedId > 0) {
        try {
          await TrackerApis.stopSleepTracker(sleepTrackerId: savedId)
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint("finalizeSessionAtAlarmRing stop API: $e");
        }
      }
      await prefs.setInt('sleep_tracker_id', 0);
      await prefs.remove('sleep_note_ids');
      await prefs.remove('sleep_description');
      debugPrint("✅ Session finalized at alarm ring (id=$savedId)");
    } catch (e) {
      debugPrint("finalizeSessionAtAlarmRing error: $e");
    }
  }

  /// Lightweight teardown so alarm UI stays responsive (cancel meters/timers).
  /// Does NOT stop waves/Lottie — hang fix is sensor/timer teardown only.
  Future<void> prepareForAlarmRing() async {
    try {
      trackerState.value = TrackerState.idle;
      _dimTimer?.cancel();
      _idleDimTimer?.cancel();
      _mappingTimer?.cancel();
      _amplitudeTimer?.cancel();
      _silenceTimer?.cancel();
      _maxRecordTimer?.cancel();
      _uiDbTimer?.cancel();
      _clockTimer?.cancel();
      await _noiseSub?.cancel();
      _noiseSub = null;
      _noiseStarted = false;
      await _accelSub?.cancel();
      _accelSub = null;
      if (isRecording.value) {
        try {
          await recorder.stop();
        } catch (_) {}
        isRecording.value = false;
      }
    } catch (e) {
      debugPrint("prepareForAlarmRing error: $e");
    }
  }

  /// Mark tracking inactive immediately so reboot cannot resume.
  /// Keeps `sleep_tracker_id` until [performCleanup] finishes the stop API.
  Future<void> clearLocalTrackingFlags() async {
    try {
      trackerState.value = TrackerState.idle;
      await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
      if (Get.isRegistered<SleepSoundController>()) {
        Get.find<SleepSoundController>().isTrackingActive.value = false;
      }
    } catch (e) {
      debugPrint("clearLocalTrackingFlags error: $e");
    }
  }

  /// Last-resort stop when SleepTrackerController is not available / cleanup timed out.
  static Future<void> emergencyStopOrphanTracker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('sleep_tracker_id') ?? 0;
      await setValue(AppSharedPreferenceKeys.isSleepTrackingActive, false);
      if (Get.isRegistered<SleepSoundController>()) {
        Get.find<SleepSoundController>().isTrackingActive.value = false;
      }
      if (id > 0) {
        try {
          await TrackerApis.stopSleepTracker(sleepTrackerId: id)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      await prefs.setInt('sleep_tracker_id', 0);
      await prefs.remove('sleep_note_ids');
      await prefs.remove('sleep_description');
      try {
        await FlutterForegroundTask.stopService();
      } catch (_) {}
      if (Get.isRegistered<SleepTrackerController>()) {
        await Get.find<SleepTrackerController>().releasePostSessionResources();
      }
    } catch (e) {
      debugPrint("emergencyStopOrphanTracker error: $e");
    }
  }

  Future<void> performCleanup(SleepTrackerController sleepController) async {
    int savedSleepTrackerId = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedSleepTrackerId = prefs.getInt('sleep_tracker_id') ?? 0;

      await prepareForAlarmRing();
      await clearLocalTrackingFlags();

      // Best-effort stop of any leftover recording without restarting meters
      try {
        await stopRecording();
      } catch (_) {}

      if (savedSleepTrackerId > 0) {
        try {
          // Prefer direct API so we are not blocked by isStopping / stopRecording loops
          await TrackerApis.stopSleepTracker(sleepTrackerId: savedSleepTrackerId)
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint("performCleanup stop API error: $e");
        }
      }

      await prefs.remove('sleep_note_ids');
      await prefs.remove('sleep_description');
      debugPrint("Cleanup successful for tracker $savedSleepTrackerId");
    } catch (e) {
      debugPrint("Cleanup error: $e");
    } finally {
      // ALWAYS clear local state + FGS + leftover listeners — even on timeout
      try {
        await clearLocalTrackingFlags();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('sleep_tracker_id', 0);
        await FlutterForegroundTask.stopService();
        await releasePostSessionResources();
      } catch (e) {
        debugPrint("Cleanup finally error: $e");
      }
    }
  }
}
