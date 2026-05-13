import 'dart:ui';

import 'package:sleepable_ai/modules/alarm/views/alarm_ringing_view.dart';
import 'package:sleepable_ai/modules/dreambot/bindings/dreambot_binding.dart';
import 'package:sleepable_ai/modules/dreambot/views/dreambot_view.dart';
import 'package:sleepable_ai/modules/heart_bpm_measurement/views/heart_bpm_measurement_view.dart';
import 'package:sleepable_ai/modules/profile_sleep_reminder/views/profile_sleep_reminder_view.dart';
import 'package:sleepable_ai/modules/sign_up/views/sign_up_view.dart';
import 'package:sleepable_ai/modules/sleep_report/views/sleep_report_view.dart';
import 'package:sleepable_ai/modules/welcome/bindings/welcome_binding.dart';
import 'package:sleepable_ai/modules/welcome/views/welcome_view.dart';

import '../../../core/utils/library.dart';
import '../modules/accurate_sleep_recorder/bindings/accurate_sleep_recorder_binding.dart';
import '../modules/accurate_sleep_recorder/views/accurate_sleep_recorder_view.dart';
import '../modules/alarm/bindings/alarm_binding.dart';
import '../modules/alarm/views/alarm_view.dart';
import '../modules/alarm/views/melodies.dart';
import '../modules/best_sound_machine/bindings/best_sound_machine_binding.dart';
import '../modules/best_sound_machine/views/best_sound_machine_view.dart';
import '../modules/body_scanner/bindings/body_scanner_binding.dart';
import '../modules/body_scanner/views/body_scanner_view.dart';
import '../modules/boot_up/bindings/boot_up_binding.dart';
import '../modules/boot_up/views/boot_up_view.dart';
import '../modules/breathwork/bindings/breathwork_binding.dart';
import '../modules/breathwork/views/breathwork_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/email_login/views/email_login_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/free_trial/bindings/free_trial_binding.dart';
import '../modules/free_trial/views/free_trial_view.dart';
import '../modules/heart_bpm/bindings/heart_bpm_binding.dart';
import '../modules/heart_bpm/views/heart_bpm_view.dart';
import '../modules/heart_bpm_measurement/bindings/heart_bpm_measurement_binding.dart';
import '../modules/language/bindings/language_binding.dart';
import '../modules/language/views/language_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/music/bindings/music_binding.dart';
import '../modules/music/views/music_view.dart';
import '../modules/otp_verification/views/otp_verification_view.dart';
import '../modules/patented_sleep_tracker/bindings/patented_sleep_tracker_binding.dart';
import '../modules/patented_sleep_tracker/views/patented_sleep_tracker_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/model/user_profile_model.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile_sleep_goal/bindings/profile_sleep_goal_binding.dart';
import '../modules/profile_sleep_goal/views/profile_sleep_goal_view.dart';
import '../modules/profile_sleep_reminder/bindings/profile_sleep_reminder_binding.dart';
import '../modules/progress/bindings/progress_binding.dart';
import '../modules/progress/views/progress_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/sign_in/bindings/sign_in_binding.dart';
import '../modules/sign_in/views/sign_in_view.dart';
import '../modules/sign_up/bindings/sign_up_binding.dart';
import '../modules/sleep_goal/bindings/sleep_goal_binding.dart';
import '../modules/sleep_goal/views/sleep_goal_view.dart';
import '../modules/sleep_info/bindings/sleep_info_binding.dart';
import '../modules/sleep_info/views/sleep_info_view.dart';
import '../modules/sleep_quiz/bindings/sleep_quiz_binding.dart';
import '../modules/sleep_quiz/views/sleep_quiz_view.dart';
import '../modules/sleep_quiz_result/controllers/sleep_quiz_result_controller.dart';
import '../modules/sleep_quiz_result/views/sleep_quiz_result_view.dart';
import '../modules/sleep_report/bindings/sleep_report_binding.dart';
import '../modules/sleep_sound/bindings/sleep_sound_binding.dart';
import '../modules/sleep_sound/views/sleep_sound_view.dart';
import '../modules/sleep_tracker_screen/bindings/sleep_tracker_screen_binding.dart';
import '../modules/sleep_tracker_screen/views/sleep_tracker_screen_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.bootUp;
  static const initialHome = Routes.dashboard;

  // static const alarmRinging = Routes.alarmRinging;
  static final routes = [
      GetPage(name: _Paths.bootUp, page: () => BootUpView(), binding: BootUpBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.welcome, page: () => WelcomeView(), binding: WelcomeBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.sleepGoal, page: () => SleepGoalView(), binding: SleepGoalBinding(), transition: Transition.downToUp),
    GetPage(name: _Paths.bodyScanner, page: () => BodyScannerView(), binding: BodyScannerBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.sleepReport, page: () => SleepReportView(), binding: SleepReportBinding(), transition: Transition.fadeIn),
    GetPage(name: _Paths.accurateSleepRecorder, page: () => AccurateSleepRecorderView(), binding: AccurateSleepRecorderBinding(), transition: Transition.fadeIn),
     GetPage(name: _Paths.bestSoundMachine, page: () => BestSoundMachineView(), binding: BestSoundMachineBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.login, page: () => LoginView(), binding: LoginBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.signup, page: () => SignupScreen(), binding: SignupBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.signIn, page: () => SignInScreen(), binding: SignInBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.forgotPassword, page: () => ForgotPasswordScreen(), binding: ForgotPasswordBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.freeTrial, page: () => FreeTrialView(), binding: FreeTrialBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),



    GetPage(name: _Paths.dashboard, page: () => DashboardScreen(), binding: DashboardBinding(), transition: Transition.downToUp,preventDuplicates: true,),
    GetPage(name: _Paths.home, page: () => HomeScreen(), binding: HomeBinding(), transition: Transition.downToUp),
    GetPage(name: _Paths.sleepSound, page: () => SleepSoundView(),),// binding: SleepSoundBinding()
    GetPage(name: _Paths.music, page: () => MusicView(), binding: MusicBinding()),
    GetPage(name: _Paths.sleepTracker, page: () => SleepTrackerScreen(), binding: SleepTrackerBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),

    GetPage(name: _Paths.profile, page: () => ProfileScreen(), binding: ProfileBinding()),
    GetPage(name: _Paths.settings, page: () => SettingsView(), binding: SettingsBinding()),
     GetPage(
      name: _Paths.editProfile,
      page: () {
        final UserProfileData? data = Get.arguments as UserProfileData?;
        return data == null
            ? const Scaffold(body: Center(child: Text("No data")))
            : EditProfileView(data: data);
      },
    ),

    GetPage(name: _Paths.progress, page: () => ProgressScreen(), binding: ProgressBinding()),
     GetPage(name: _Paths.heartBPM, page: () => HeartBPMView(), binding: HeartBPMBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(milliseconds: 100)),
    GetPage(
      name: _Paths.heartBPMMeasurement,
      page: () => HeartBpmMeasurementView(),
      binding: HeartBpmMeasurementBinding(),
      customTransition: BlurFadeRoute(),
      transitionDuration: const Duration(milliseconds: 100),
    ),
    GetPage(name: _Paths.breathwork, page: () => BreathworkView(), binding: BreathworkBinding()),
    GetPage(name: _Paths.alarm, page: () => AlarmScreen(), binding: AlarmBinding()),
    GetPage(name: _Paths.alarmRinging, page: () => AlarmRingingScreen(), transition: Transition.fadeIn),
    GetPage(name: _Paths.dreamBot, page: () => DreamBotScreen(), binding: DreamBotBinding(), transition: Transition.fadeIn),
     GetPage(name: _Paths.language, page: () => LanguageView(), binding: LanguageBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.profileSleepReminder, page: () => ProfileSleepReminderScreen(), binding: ProfileSleepReminderBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.profileSleepGoal, page: () => ProfileSleepGoalScreen(), binding: ProfileSleepGoalBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.sleepInfo, page: () => SleepInfoView(), binding: SleepInfoBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(name: _Paths.sleepQuiz, page: () => SleepQuizView(), binding: SleepQuizBinding(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(
      name: Routes.sleepQuizResult,
      page: () => const SleepQuizResultView(),
      binding: BindingsBuilder(() {
        Get.put(SleepQuizResultController());
      }),
    ),
    GetPage(name: _Paths.melodies, page: () => MelodiesScreen(), customTransition: BlurFadeRoute(), transitionDuration: const Duration(seconds: 1)),
    GetPage(
      name: Routes.otpScreen,
      page: () => const OtpVerificationView(),
      binding: LoginBinding(), // Ye zaroori hai taaki LoginController mil sake
    ),
    GetPage(
        name: Routes.emailLogin,
        page: () => const EmailLoginView(),
        binding: LoginBinding()
    ),
  ];
}

class BlurFadeTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Stack(
      children: [
        /// OLD SCREEN → Blur + Fade out
        FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(animation),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10 * animation.value, sigmaY: 10 * animation.value),
            child: Container(color: Colors.black.withOpacity(0)),
          ),
        ),

        /// NEW SCREEN → Fade IN + slight scale
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ],
    );
  }
}

class BlurFadeRoute extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation, Animation<double> secondary, Widget child) {
    /// OLD PAGE → fade out + blur + darker
    final oldScreen = FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(secondary),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 40 * secondary.value, // more smooth blur
          sigmaY: 40 * secondary.value,
        ),
        child: Container(
          color: Colors.black.withOpacity(0.4 * secondary.value),
          // ⬆ slowly increases to 0.4 opacity
        ),
      ),
    );

    /// NEW PAGE → fade in from 0.5 to 1.0
    final newScreen = FadeTransition(
      opacity: Tween<double>(begin: 0.01, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );

    return Stack(children: [oldScreen, newScreen]);
  }
}

