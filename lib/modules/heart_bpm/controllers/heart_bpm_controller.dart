
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
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

  /// PPG waveform buffers (red when available, else luma)
  final List<double> _redValues = [];
  final List<int> _timestamps = [];

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
    "$ageLabel $age - $rangeLabel: $min–$max $bpmUnit.\n"
        "$yourBpmLabel: $bpm - $status";
  }

  /// Why the camera could not be started. Empty while things are fine.
  ///
  /// Every failure here used to be an unhandled async error: the screen was
  /// left on its spinner with nothing to read and no way forward.
  RxString cameraError = ''.obs;

  Future<void> initCamera() async {
    cameraError.value = '';
    try {
      // Android needs the grant at runtime. Without it availableCameras()
      // comes back empty on some versions and initialize() throws on others.
      final status = await ph.Permission.camera.request();
      if (!status.isGranted) {
        cameraError.value = _cameraErrorText(
            status.isPermanentlyDenied ? 'deniedForever' : 'denied');
        return;
      }

      final cams = await availableCameras();
      CameraDescription? lens;
      for (final c in cams) {
        if (c.lensDirection == CameraLensDirection.back) {
          lens = c;
          break;
        }
      }
      lens ??= cams.isNotEmpty ? cams.first : null;
      if (lens == null) {
        cameraError.value = _cameraErrorText('noCamera');
        return;
      }

      cameraController = CameraController(
        lens,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();

      // Give the sensor a moment before switching the torch on.
      await Future.delayed(const Duration(milliseconds: 500));
      // Not every device has a torch. The reading is weaker without it, but
      // that is no reason to kill the screen.
      try {
        await cameraController!.setFlashMode(FlashMode.torch);
      } catch (e) {
        debugPrint("Torch unavailable: $e");
      }

      // And another before the stream starts.
      await Future.delayed(const Duration(milliseconds: 500));

      isCameraReady.value = true;
      _startStream();
    } catch (e) {
      debugPrint("Heart rate camera init failed: $e");
      cameraError.value = _cameraErrorText('failed');
    }
  }

  String _cameraErrorText(String key) {
    const map = {
      "en": {
        "denied": "Camera access is needed to read your pulse. Please allow it and try again.",
        "deniedForever": "Camera access is blocked. Turn it on for Sleepable in your phone's settings.",
        "noCamera": "No usable camera was found on this device.",
        "failed": "The camera could not be started. Close any other app using it and try again.",
      },
      "de": {
        "denied": "Fuer die Pulsmessung wird die Kamera benoetigt. Bitte erlauben und erneut versuchen.",
        "deniedForever": "Der Kamerazugriff ist blockiert. Aktivieren Sie ihn fuer Sleepable in den Einstellungen.",
        "noCamera": "Auf diesem Geraet wurde keine nutzbare Kamera gefunden.",
        "failed": "Die Kamera konnte nicht gestartet werden. Schliessen Sie andere Apps und versuchen Sie es erneut.",
      },
      "fr": {
        "denied": "L'acces a la camera est necessaire pour mesurer votre pouls. Autorisez-le puis reessayez.",
        "deniedForever": "L'acces a la camera est bloque. Activez-le pour Sleepable dans les reglages.",
        "noCamera": "Aucune camera utilisable n'a ete trouvee sur cet appareil.",
        "failed": "Impossible de demarrer la camera. Fermez les autres applications et reessayez.",
      },
      "es": {
        "denied": "Se necesita la camara para medir tu pulso. Permitelo e intentalo de nuevo.",
        "deniedForever": "El acceso a la camara esta bloqueado. Activalo para Sleepable en los ajustes.",
        "noCamera": "No se encontro ninguna camara utilizable en este dispositivo.",
        "failed": "No se pudo iniciar la camara. Cierra otras apps e intentalo de nuevo.",
      },
      "pt": {
        "denied": "A camera e necessaria para medir seu pulso. Permita e tente novamente.",
        "deniedForever": "O acesso a camera esta bloqueado. Ative-o para o Sleepable nas configuracoes.",
        "noCamera": "Nenhuma camera utilizavel foi encontrada neste aparelho.",
        "failed": "Nao foi possivel iniciar a camera. Feche outros apps e tente novamente.",
      },
    };
    final table = map[Get.locale?.languageCode ?? "en"] ?? map["en"]!;
    return table[key] ?? map["en"]![key] ?? "";
  }

  /// Opens the OS settings page so a permanently denied permission can be
  /// turned back on.
  Future<void> openCameraSettings() => ph.openAppSettings();
  // -----------------------------------------------------------
  // PPG STREAM: bright-red fingertip, not a dark frame
  // -----------------------------------------------------------
  void _startStream() {
    final cam = cameraController;
    if (cam == null || !cam.value.isInitialized) return;
    if (cam.value.isStreamingImages) return;

    unawaited(cam.startImageStream((image) {
      try {
        final sample = _sampleFrame(image);
        _updateFingerState(sample);

        if (fingerOn.value) {
          if (!isMeasuring.value && !showRestartButton.value) {
            _startMeasurement();
          }
          if (isMeasuring.value) {
            _redValues.add(sample.ppg);
            _timestamps.add(DateTime.now().millisecondsSinceEpoch);
          }
        }
      } catch (e) {
        debugPrint("Heart rate frame skipped: $e");
      }
    }).catchError((Object e) {
      debugPrint("Heart rate image stream failed: $e");
    }));
  }

  // -----------------------------------------------------------
  // FINGER STATE (debounce)
  // -----------------------------------------------------------
  int _yes = 0, _no = 0;
  void _updateFingerState(_PpgSample sample) {
    // Torch through a fingertip: high red (including 240–255), red > green/blue,
    // fairly uniform frame. A dark room / uncovered lens must not count.
    final bool redGlow = sample.red >= 140 &&
        sample.red >= sample.green + 8 &&
        sample.red >= sample.blue + 8;
    final bool lumaGlow = sample.red < 1 &&
        sample.brightness >= 140 &&
        sample.stddev < 40;
    final bool uniform = sample.stddev < 55;
    final bool fingerLikely = (redGlow && (uniform || sample.red >= 200)) || lumaGlow;

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

    /// IMPORTANT - reset timer reference AFTER clearing progress
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
    // Persist before Start Sleep can run so the tracker API gets this BPM.
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('heart_rate', finalBpm.value);
    });
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
    // A restart must not die on a device without a torch either.
    try {
      await cameraController?.initialize();
      await cameraController?.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint("Heart rate camera restart failed: $e");
    }
    isCameraReady.value = true;

    if (fingerOn.value) _startMeasurement();
  }

  // -----------------------------------------------------------
  // FRAME SAMPLING (BGRA on iOS, YUV with pixelStride on Android)
  // -----------------------------------------------------------
  _PpgSample _sampleFrame(CameraImage img) {
    if (img.planes.isEmpty) return _PpgSample.empty;
    if (Platform.isIOS || img.format.group == ImageFormatGroup.bgra8888) {
      return _sampleBgra(img);
    }
    return _sampleYuv(img);
  }

  _PpgSample _sampleBgra(CameraImage img) {
    final plane = img.planes[0];
    final bytes = plane.bytes;
    final stride = plane.bytesPerRow;
    final pixelStride = plane.bytesPerPixel ?? 4;
    const step = 8;
    double sumR = 0, sumG = 0, sumB = 0, sumY = 0, sumY2 = 0;
    int count = 0;

    for (int y = 0; y < img.height; y += step) {
      final row = y * stride;
      for (int x = 0; x < img.width; x += step) {
        final i = row + x * pixelStride;
        if (i + 2 >= bytes.length) continue;
        final b = bytes[i].toDouble();
        final g = bytes[i + 1].toDouble();
        final r = bytes[i + 2].toDouble();
        final luma = 0.299 * r + 0.587 * g + 0.114 * b;
        sumR += r;
        sumG += g;
        sumB += b;
        sumY += luma;
        sumY2 += luma * luma;
        count++;
      }
    }
    return _ppgFromSums(sumR, sumG, sumB, sumY, sumY2, count);
  }

  _PpgSample _sampleYuv(CameraImage img) {
    final yPlane = img.planes[0];
    const step = 8;
    double sumR = 0, sumG = 0, sumB = 0, sumY = 0, sumY2 = 0;
    int count = 0;

    for (int y = 0; y < img.height; y += step) {
      for (int x = 0; x < img.width; x += step) {
        final yi = _planeIndex(yPlane, x, y);
        if (yi < 0) continue;
        final Y = yPlane.bytes[yi];
        sumY += Y;
        sumY2 += Y * Y.toDouble();

        int u = 128;
        int v = 128;
        if (img.planes.length >= 3) {
          final ui = _planeIndex(img.planes[1], x, y, xSub: 2, ySub: 2);
          final vi = _planeIndex(img.planes[2], x, y, xSub: 2, ySub: 2);
          if (ui >= 0) u = img.planes[1].bytes[ui];
          if (vi >= 0) v = img.planes[2].bytes[vi];
        } else if (img.planes.length == 2) {
          // NV21-style interleaved chroma (V, U). Not BGRA.
          final uv = img.planes[1];
          final pixelStride = uv.bytesPerPixel ?? 2;
          final idx = (y ~/ 2) * uv.bytesPerRow + (x ~/ 2) * pixelStride;
          if (idx >= 0 && idx + 1 < uv.bytes.length) {
            v = uv.bytes[idx];
            u = uv.bytes[idx + 1];
          }
        }

        final ud = u - 128.0;
        final vd = v - 128.0;
        sumR += (Y + 1.402 * vd).clamp(0, 255);
        sumG += (Y - 0.344136 * ud - 0.714136 * vd).clamp(0, 255);
        sumB += (Y + 1.772 * ud).clamp(0, 255);
        count++;
      }
    }
    return _ppgFromSums(sumR, sumG, sumB, sumY, sumY2, count);
  }

  int _planeIndex(Plane plane, int x, int y, {int xSub = 1, int ySub = 1}) {
    final pixelStride = plane.bytesPerPixel ?? 1;
    final idx = (y ~/ ySub) * plane.bytesPerRow + (x ~/ xSub) * pixelStride;
    if (idx < 0 || idx >= plane.bytes.length) return -1;
    return idx;
  }

  _PpgSample _ppgFromSums(
    double sumR,
    double sumG,
    double sumB,
    double sumY,
    double sumY2,
    int count,
  ) {
    if (count <= 0) return _PpgSample.empty;
    final meanY = sumY / count;
    final variance = max(0.0, (sumY2 / count) - meanY * meanY);
    return _PpgSample(
      red: sumR / count,
      green: sumG / count,
      blue: sumB / count,
      brightness: meanY,
      stddev: sqrt(variance),
    );
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

/// One sampled camera frame for fingertip PPG detection and BPM waveform.
class _PpgSample {
  final double red;
  final double green;
  final double blue;
  final double brightness;
  final double stddev;

  const _PpgSample({
    required this.red,
    required this.green,
    required this.blue,
    required this.brightness,
    required this.stddev,
  });

  static const empty = _PpgSample(
    red: 0,
    green: 0,
    blue: 0,
    brightness: 0,
    stddev: 999,
  );

  /// Pulse waveform: red channel when RGB is available, else luma.
  double get ppg => red > 1 ? red : brightness;
}
