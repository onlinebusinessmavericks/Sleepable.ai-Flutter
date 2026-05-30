
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../localization/lang_extension.dart';
class HeartRateService {
  static final List<Map<String, dynamic>> ageRanges = [
    {"age": 20, "min": 100, "max": 170},
    {"age": 30, "min": 95,  "max": 162},
    {"age": 35, "min": 93,  "max": 157},
    {"age": 40, "min": 90,  "max": 153},
    {"age": 45, "min": 88,  "max": 149},
    {"age": 50, "min": 85,  "max": 145},
    {"age": 55, "min": 83,  "max": 140},
    {"age": 60, "min": 80,  "max": 136},
    {"age": 65, "min": 78,  "max": 132},
    {"age": 70, "min": 75,  "max": 128},
  ];

  Map<String, int> getTargetRange(int age) {
    // Find closest age group
    final range = ageRanges.firstWhere(
          (item) => age <= item["age"],
      orElse: () => ageRanges.last,
    );

    return {"min": range["min"], "max": range["max"]};
  }
}
class HeartBPMController extends GetxController {
  CameraController? cameraController;

  RxBool isMeasuring = false.obs;
  RxBool fingerOn = false.obs;
  RxBool isCameraReady = false.obs;

  RxInt countdown = 30.obs;
  RxInt bpm = 0.obs;
  RxInt finalBpm = 0.obs;

  RxBool showSaveButton = false.obs;
  RxBool showRestartButton = false.obs;

  RxDouble progress = 0.0.obs;
  RxDouble previousProgress = 0.0.obs;

  /// detection buffers
  final List<double> _redValues = [];
  final List<int> _timestamps = [];

  /// baseline ambient
  final List<double> _baseline = [];
  double _baselineAvg = 0;
  bool _baselineReady = false;

  Timer? _countdownTimer;
  Timer? _bpmTimer;
  Timer? _progressTimer;

  int _startTime = 0;

  final int measureDuration = 30;
  var ageBasedMessage = ''.obs;
  @override
  void onInit() {
    super.onInit();
    // initCamera();
  }
  @override
  void onReady() {
    super.onReady();

    // ✅ UI is already rendered
    Future.microtask(() {
      initCamera();
    });
  }
  Color getArcColor(int bpm, int age) {
    final range = HeartRateService().getTargetRange(age);
    final min = range["min"]!;
    final max = range["max"]!;

    if (bpm < min) {
      return Colors.green;       // BELOW range
    } else if (bpm > max) {
      return Colors.red;         // ABOVE range
    } else {
      return Colors.deepOrangeAccent;      // WITHIN target range
    }
  }
  Future<void> updateAgeBasedMessage(int bpm, int age) async {
    final range = HeartRateService().getTargetRange(age);
    final min = range["min"]!;
    final max = range["max"]!;

    // Shortcut for cleaner code
    final lang = Get.context?.lang;

    String status;
    if (bpm < min) {
      status = lang?.belowTargetRange ?? "Below target range.";
    } else if (bpm > max) {
      status = lang?.aboveTargetRange ?? "Above target range.";
    } else {
      status = lang?.withinTargetZone ?? "Within target zone.";
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heart_rate', bpm);

    // Labels fetch with fallbacks
    final ageLabel = lang?.age ?? "Age";
    final rangeLabel = lang?.targetRange ?? "Target Range";
    final bpmUnit = lang?.bpm ?? "bpm";
    final yourBpmLabel = lang?.yourBpm ?? "Your BPM";

    // Final Localized Message
    ageBasedMessage.value =
    "$ageLabel $age — $rangeLabel: $min–$max $bpmUnit.\n"
        "$yourBpmLabel: $bpm — $status";
  }

  Future<void> initCamera() async {
    final cams = await availableCameras();
    cameraController = CameraController(
      cams.first,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );

    await cameraController!.initialize();

    // 🔥 FIX: Flash on karne se pehle 500ms ka delay dein
    await Future.delayed(const Duration(milliseconds: 500));
    await cameraController!.setFlashMode(FlashMode.torch);

    // 🔥 FIX: Stream shuru karne se pehle phir se thoda delay dein
    await Future.delayed(const Duration(milliseconds: 500));

    isCameraReady.value = true;
    _startStream();
  }
  // -----------------------------------------------------------
  // LIGHT + RED DETECTION STREAM
  // -----------------------------------------------------------
  void _startStream() {
    cameraController!.startImageStream((image) {
      double brightness = _averageBrightness(image); // FAST
      double redValue = _averageRed(image); // SAFE SAMPLING

      if (!_baselineReady) {
        _baseline.add(brightness);
        if (_baseline.length >= 40) {
          _baselineAvg = _baseline.reduce((a, b) => a + b) / _baseline.length;
          _baselineReady = true;
        }
        return;
      }

      bool detected = brightness < (_baselineAvg * 0.70);

      _updateFingerState(detected, redValue);


      if (fingerOn.value) {
        if (!isMeasuring.value && !showRestartButton.value) {
          _startMeasurement();
        }
        if (isMeasuring.value) {
          _redValues.add(redValue);
          _timestamps.add(DateTime.now().millisecondsSinceEpoch);
        }
      }
    });
  }

  // -----------------------------------------------------------
  // FINGER STATE (debounce)
  // -----------------------------------------------------------
  int _yes = 0, _no = 0;
  void _updateFingerState(bool detected, double redValue) {
    // Finger should have high RED + low BRIGHTNESS
    bool fingerLikely =
        detected &&             // low brightness (covering flash)
            redValue > 120 &&       // enough red signal
            redValue < 240;         // avoid white/light objects

    if (fingerLikely) {
      _yes++;
      _no = 0;

      if (_yes >= 5 && !fingerOn.value) {
        fingerOn.value = true;

        // Reset progress as soon as finger detected
        progress.value = 0.0;
        previousProgress.value = 0.0;
      }
    } else {
      _no++;
      _yes = 0;

      if (_no >= 5 && fingerOn.value) {
        fingerOn.value = false;

        /// FULL RESET
        isMeasuring.value = false;

        progress.value = 0.0;
        previousProgress.value = 0.0;
        bpm.value = 0;
        finalBpm.value = 0;

        _redValues.clear();
        _timestamps.clear();

        // stop timers safely
        _countdownTimer?.cancel();
        _bpmTimer?.cancel();
        _progressTimer?.cancel();
      }
    }
  }


  // -----------------------------------------------------------
  // START MEASUREMENT
  // -----------------------------------------------------------

  void _startMeasurement() {
    isMeasuring.value = true;

    bpm.value = 0;
    finalBpm.value = 0;
    countdown.value = measureDuration;

    /// FULL CLEAN RESET
    progress.value = 0.0;
    previousProgress.value = 0.0;

    _redValues.clear();
    _timestamps.clear();

    /// IMPORTANT — reset timer reference AFTER clearing progress
    _startTime = DateTime.now().millisecondsSinceEpoch;

    // countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (t) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        t.cancel();
      }
    });

    // bpm update
    _bpmTimer?.cancel();
    _bpmTimer = Timer.periodic(Duration(seconds: 1), (t) {
      if (_redValues.length > 4) {
        bpm.value = _calculateBPM(_redValues, _timestamps);
      }
    });

    // smooth progress
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(Duration(milliseconds: 30), (t) {
      int elapsed = DateTime.now().millisecondsSinceEpoch - _startTime;
      double p = elapsed / (measureDuration * 1000);

      previousProgress.value = progress.value;
      progress.value = p.clamp(0, 1);

      if (p >= 1) {
        bpm.value = _calculateBPM(_redValues, _timestamps);
        stopMeasurement(reset: false);
      }
    });
  }

  void stopMeasurement({bool reset = false}) {
    isMeasuring.value = false;

    // 1. Saare timers pehle cancel karein
    _countdownTimer?.cancel();
    _bpmTimer?.cancel();
    _progressTimer?.cancel();

    // 2. Flash ko turant off karein
    cameraController?.setFlashMode(FlashMode.off);

    if (reset) {
      print("------------ Reset: Finger Removed -------------------");
      // Agar finger hat gayi hai, toh stream check karke stop karein
      _safeStopStream();
      return;
    }

    /// -------------------------------
    /// ✅ FINAL BPM CALCULATION
    /// -------------------------------
    finalBpm.value = bpm.value;
    showSaveButton.value = true;
    showRestartButton.value = true;

    // Age based message update (UI ke liye)
    updateAgeBasedMessage(finalBpm.value, 30);

    print("------------ Measurement Finished: OFF FLASH -------------------");

    /// -------------------------------
    /// 🔥 SAFE STOP CAMERA STREAM
    /// -------------------------------
    _safeStopStream();

    /// -------------------------------
    /// 🔥 HIDE CAMERA FROM UI
    /// -------------------------------
    isCameraReady.value = false;
  }

// 🛡️ Helper function crash se bachne ke liye
  void _safeStopStream() {
    if (cameraController != null && cameraController!.value.isInitialized && cameraController!.value.isStreamingImages) {
      try {
        cameraController?.stopImageStream();
        print("✅ Camera stream stopped safely.");
      } catch (e) {
        print("⚠️ Stream stop error (already stopped): $e");
      }
    }
  }
  void restartMeasurement() async {
    showSaveButton.value = false;
    showRestartButton.value = false;

    bpm.value = 0;
    finalBpm.value = 0;
    progress.value = 0;
    previousProgress.value = 0;
    countdown.value = measureDuration;

    _redValues.clear();
    _timestamps.clear();

    /// 🔥 Restart camera
    await cameraController?.initialize();
    await cameraController?.setFlashMode(FlashMode.torch);
    isCameraReady.value = true;

    if (fingerOn.value) _startMeasurement();
  }

  // -----------------------------------------------------------
  // FAST BRIGHTNESS (Y-PLANE)
  // -----------------------------------------------------------
  double _averageBrightness(CameraImage img) {
    final bytes = img.planes[0].bytes;
    int step = 50;
    int sum = 0, count = 0;

    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    return sum / count;
  }

  // -----------------------------------------------------------
  // SAFE RED SAMPLING (NO CRASH)
  // -----------------------------------------------------------
  double _averageRed(CameraImage img) {
    if (Platform.isIOS || img.planes.length < 3) {
      final bytes = img.planes[0].bytes;
      int sum = 0;
      int count = 0;
      // BGRA format mein har 4th byte Red hota hai (ya Blue/Green depending on alignment)
      // Hum sample karke average nikalenge
      for (int i = 0; i < bytes.length; i += 40) { // step 40 for performance
        sum += bytes[i + 2]; // Index 2 is usually Red in BGRA
        count++;
      }
      return count > 0 ? (sum / count).toDouble() : 0;
    }
    int w = img.width;
    int h = img.height;

    Plane Yp = img.planes[0];
    Plane Up = img.planes[1];
    Plane Vp = img.planes[2];

    int sum = 0, count = 0;
    const step = 40;

    for (int y = 0; y < h; y += step) {
      for (int x = 0; x < w; x += step) {
        int yi = y * Yp.bytesPerRow + x;
        int uv = (y ~/ 2) * Up.bytesPerRow + (x ~/ 2);

        int Y = Yp.bytes[yi];
        int U = Up.bytes[uv] - 128;
        int V = Vp.bytes[uv] - 128;

        int R = (Y + 1.402 * V).clamp(0, 255).toInt();
        sum += R;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0;
  }

  // -----------------------------------------------------------
  // BPM CALCULATION
  // -----------------------------------------------------------
  int _calculateBPM(List<double> values, List<int> times) {
    if (values.length < 6) return 0;

    List<double> smooth = _smooth(values, 5);
    List<int> peaks = [];

    for (int i = 1; i < smooth.length - 1; i++) {
      if (smooth[i] > smooth[i - 1] && smooth[i] > smooth[i + 1]) {
        if (peaks.isEmpty || (times[i] - peaks.last) > 280) {
          peaks.add(times[i]);
        }
      }
    }

    if (peaks.length < 2) return 0;

    double secs = (peaks.last - peaks.first) / 1000.0;
    return ((peaks.length / secs) * 60).round();
  }

  List<double> _smooth(List<double> v, int w) {
    if (v.length < w) return v;
    List<double> out = [];
    for (int i = 0; i < v.length; i++) {
      int start = max(0, i - w + 1);
      double avg = v.sublist(start, i + 1).reduce((a, b) => a + b) / (i - start + 1);
      out.add(avg);
    }
    return out;
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _bpmTimer?.cancel();
    _progressTimer?.cancel();
    _countdownTimer?.cancel();
    super.onClose();
  }
}
