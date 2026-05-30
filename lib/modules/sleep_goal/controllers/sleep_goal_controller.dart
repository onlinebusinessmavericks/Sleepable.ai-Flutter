import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../localization/lang_extension.dart';
import '../../common/controllers/selection_flow_controller.dart';

class SleepGoalController extends GetxController with GetTickerProviderStateMixin {

  late AnimationController animationController;
  late Animation<double> animation;
  var buttonScale = 1.0.obs;
  final RxInt currentIndex = 0.obs;
  final RxList<String> selectedInterests = <String>[].obs;
  final flowController = Get.find<SelectionFlowController>();

  /// Store all question–answer pairs for backend
  final RxMap<String, dynamic> answers = <String, dynamic>{}.obs;
  final playReverseTitle = false.obs;
  final Rx<TimeOfDay> selectedTime = TimeOfDay.now().obs;
  final RxBool timeSelected = false.obs;


  // Constructor mein silent parameters add karein
  final AudioPlayer _audioPlayer = AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
  ); // 🎵 onboarding music
  void updateTime(int hour, int minute, String amPm) {
    int adjustedHour = amPm == 'PM' && hour != 12 ? hour + 12 : (amPm == 'AM' && hour == 12 ? 0 : hour);

    selectedTime.value = TimeOfDay(hour: adjustedHour, minute: minute);
    timeSelected.value = true;

    // Format time nicely (e.g., 07:30 AM)
    final formattedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';

    // Save this time under the current question title
    final currentQuestion = questions[currentIndex.value];
    final title = currentQuestion['title'] as String;

    answers[title] = formattedTime;
  }
  final List<Map<String, dynamic>> questions = [
    {
      'type': 'time_picker',
      'title': Get.context?.lang.whatTimeDidYouWakeUpToday,
      'key': 'wake_up_time',
      'multiSelect': true
    },
    {
      'type': 'time_picker',
      'title': Get.context?.lang.whatTimeDidYouGoToBedLastNight,
      'key': 'sleep_time',
      'multiSelect': true
    },
    {
      'title': Get.context?.lang.howMuchSleepDoYouUsuallyGetAtNight,
      'key': 'usual_sleep_duration',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.lessThan6Hours, 'emoji': Assets.onboardingC1},
        {'title': Get.context?.lang.a6To8Hours, 'emoji': Assets.onboardingC2},
        {'title': Get.context?.lang.a8To10hours, 'emoji': Assets.onboardingC3},
        {'title': Get.context?.lang.moreThan10Hours, 'emoji': Assets.onboardingC3},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.howSatisfiedAreYouWithYourSleep,
      'key': 'sleep_satisfaction',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.verySatisfied, 'emoji': '😌'},
        {'title': Get.context?.lang.neutral, 'emoji': '😐'},
        {'title': Get.context?.lang.unsatisfied, 'emoji': '😕'},
        {'title': Get.context?.lang.veryUnsatisfied, 'emoji': '😣'},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.whatYourSleepPosition,
      'key': 'sleep_position',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.back, 'emoji': Assets.positionsSleepBack1},
        {'title': Get.context?.lang.side, 'emoji': Assets.positionsSleepSideways},
        {'title': Get.context?.lang.fetal, 'emoji': Assets.positionsSleepFetal},
        {'title': Get.context?.lang.stomach, 'emoji': Assets.positionsSleepStomach},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.howMuchTimeYouNeedToFallSleepInBed,
      'key': 'time_to_fall_asleep',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.aFewMinutes, 'emoji': '⏱️'},
        {'title': Get.context?.lang.a15To30Minutes, 'emoji': '⏱️'},
        {'title': Get.context?.lang.a30To45Minutes, 'emoji': '⏱️'},
        {'title': Get.context?.lang.struggleToFallAsleep, 'emoji': '😴'},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.doYouWakeUpNightAndHaveTroubleGettingBackSleep,
      'key': 'night_wakeups',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.never, 'emoji': '🚫'},
        {'title': Get.context?.lang.someTimes, 'emoji': '🕐'},
        {'title': Get.context?.lang.prettyOften, 'emoji': '⏰'},
        {'title': Get.context?.lang.mostNights, 'emoji': '🌙'},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.howOftenYouWakeUpTiredMorning,
      'key': 'morning_tiredness',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.always, 'emoji': '😫'},
        {'title': Get.context?.lang.usually, 'emoji': '😐'},
        {'title': Get.context?.lang.someTimes, 'emoji': '😌'},
        {'title': Get.context?.lang.rarely, 'emoji': '😴'},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.howDarkYourBedRoomWhenSleep,
      'key': 'room_darkness',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.completelyDark, 'emoji': '🌑'},
        {'title': Get.context?.lang.mostlyDark, 'emoji': '🌘'},
        {'title': Get.context?.lang.partiallyDark, 'emoji': '🌓'},
        {'title': Get.context?.lang.bright, 'emoji': '🌞'},
      ],
      'multiSelect': false,
    },
    {
      'title': Get.context?.lang.whichHabitHaveMayAffectYourSleepQuality,
      'key': 'negative_habits',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.scrollingBeforeBed, 'emoji': '📱'},
        {'title': Get.context?.lang.havingCaffeineSfternoon, 'emoji': '☕'},
        {'title': Get.context?.lang.eatingLateNight, 'emoji': '🍔'},
        {'title': Get.context?.lang.exercisingLateDay, 'emoji': '🏋️‍♂️'},
        {'title': Get.context?.lang.noneAbove, 'emoji': '✅'},
      ],
      'multiSelect': true,
    },
    {
      'title': Get.context?.lang.doesLackSleepAffectYourDailyLife,
      'key': 'daily_life_impact',
      'subtitle': '',
      'items': [
        {'title': Get.context?.lang.veryMuch, 'emoji': '😫'},
        {'title': Get.context?.lang.someWhat, 'emoji': '😕'},
        {'title': Get.context?.lang.little, 'emoji': '😐'},
        {'title': Get.context?.lang.notAtAll, 'emoji': '😌'},
      ],
      'multiSelect': false,
    },
  ];
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();

    // 🎨 Looping animations (gradient + breathing)
    animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    animation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: animationController, curve: Curves.linear));
    _startOnboardingMusic();
  }
  Future<void> _startOnboardingMusic() async {
    try {
      // 🔴 setAsset ki jagah setAudioSource use karein aur tag zaroori hai
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse('asset:///${Assets.onboardingSleepbaleOnbordingBackground}'),
          tag: const MediaItem(
            id: 'onboarding_music', // Unique ID
            album: "Sleepable AI",
            title: "Onboarding Background",
            artist: "Sleepable AI",
          ),
        ),
      );

      _audioPlayer.setLoopMode(LoopMode.one);
      _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Audio error: $e');
    }
  }
  @override
  void onClose() {
    animationController.dispose();
    // _audioPlayer.stop();     // ⏹ Stop music immediately
    // _audioPlayer.dispose();
  }
  bool canProceed() {
    final currentQuestion = questions[currentIndex.value];
    final type = currentQuestion['type'] as String? ?? '';
    final isMulti = currentQuestion['multiSelect'] as bool;

    if (type == 'time_picker') {
      return timeSelected.value;
    }

    if (isMulti) {
      return selectedInterests.isNotEmpty;
    }

    return selectedInterests.length == 1;
  }

  /// Toggle selection logic
  void toggleSelection(String title) {
    if (isProcessing.value) return;
    final currentQuestion = questions[currentIndex.value];
    final isMulti = currentQuestion['multiSelect'] as bool;

    if (isMulti) {
      if (selectedInterests.contains(title)) {
        selectedInterests.remove(title);
      } else {
        selectedInterests.add(title);
      }
      return; // multi-select does NOT auto-next
    }

    // 🔐 Single select
    selectedInterests
      ..clear()
      ..add(title);

    if (!canProceed()) return;

    isProcessing.value = true;
    playReverseTitle.value = true;

    Future.delayed(const Duration(milliseconds: 350), () {
      saveCurrentSelection();
      nextQuestion();
      isProcessing.value = false;
    });
  }

  /// Save current selection to answers JSON
  void saveCurrentSelection() {
    final currentQuestion = questions[currentIndex.value];
    final title = currentQuestion['key'] ?? currentQuestion['title'] as String;
    final type = currentQuestion['type'] as String? ?? '';

    if (type == 'time_picker') {
      // Save the selectedTime for time picker
      final time = selectedTime.value;
      final hour = time.hourOfPeriod;
      final minute = time.minute;
      final amPm = time.period == DayPeriod.am ? 'AM' : 'PM';

      final formattedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';

      answers[title] = formattedTime;

      print('Saved time for "$title": $formattedTime');
    } else {
      final isMulti = currentQuestion['multiSelect'] as bool;

      if (isMulti) {
        answers[title] = selectedInterests.toList();
      } else {
        answers[title] = selectedInterests.isNotEmpty ? selectedInterests.first : null;
      }
    }
  }

  void nextQuestion() {
    if (!canProceed()) return;

    playReverseTitle.value = false;

    if (currentIndex.value < questions.length - 1) {
      selectedInterests.clear();
      timeSelected.value = false;
      currentIndex.value++;
    } else {
      final payload = buildFinalPayload();

      // pretty print in console (optional)
      final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
      debugPrint(prettyJson, wrapWidth: 1024);

      // 🔹 SAVE to SharedPreferences
      setValue(
        AppSharedPreferenceKeys.onboardingData,
        jsonEncode(payload),
      );
      setValue(AppSharedPreferenceKeys.onboardingCompleted, true);
      // Save selection in flow controller (existing logic)
      flowController.saveSelection(
        "sleep_survey",
        [jsonEncode(payload)],
      );

      // Stop & dispose audio
      _audioPlayer.stop();
      _audioPlayer.dispose();

      // Go next
      Get.toNamed(Routes.bodyScanner);
    }
  }

  void previousQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      selectedInterests.clear();
    } else {
      Get.back();
    }
  }

  double get progress => (currentIndex.value + 1) / questions.length;

  Map<String, dynamic> buildFinalPayload() {
    final List<Map<String, dynamic>> formattedAnswers = [];

    answers.forEach((questionTitle, answerValue) {
      final question = questions.firstWhere(
            (q) => q['title'] == questionTitle,
        orElse: () => {},
      );

      formattedAnswers.add({
        'key': question['key'] ?? questionTitle,
        'question': questionTitle,
        'answer': answerValue,
      });
    });

    return {
      'survey_type': 'sleep_survey',
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'answers': formattedAnswers,
    };
  }

}
