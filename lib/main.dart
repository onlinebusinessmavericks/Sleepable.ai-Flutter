
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/widgets/SubscriptionController.dart';
import 'package:sleepable_ai/widgets/notification_service.dart';

import 'bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_theme.dart';
import 'data/services/api_sevices.dart';
import 'modules/sleep_sound/controllers/sleep_sound_controller.dart';
import 'routes/app_pages.dart';
import 'localization/app_localizations.dart';
import 'localization/language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.sleepableai.audio',
  //   androidNotificationChannelName: 'Sleepable AI Audio',
  //   androidNotificationOngoing: true, // Notification user swip karke hata nahi payega jab tak audio chal raha hai
  // );
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.sleepableai.audio',
  //   androidNotificationChannelName: 'Sleepable AI Audio',
  //   androidNotificationOngoing: true,
  //   // This allows the notification to show even if we don't have play/pause buttons
  // );
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.sleepableai.audio',
  //   androidNotificationChannelName: 'Sleepable AI Audio',
  //   androidNotificationOngoing: true,
  // );

  // 2. Lock the status bar to transparent with light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Fixes the black bar
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons
      statusBarBrightness: Brightness.dark, // iOS equivalent
    ),
  );
  /// ✅ nb_utils (MANDATORY)
  await initialize();

  /// ✅ Firebase
  await Firebase.initializeApp();
  /// 🔥 ADD HIGH IMPORTANCE CHANNEL HERE
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // This ID must match your AndroidManifest meta-data
      'High Importance Notifications',
      description: 'This channel is used for important sleep reminders and reports.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  // await SubscriptionController.init();
  try {
    await SubscriptionController.init();
  } catch (e) {
    print("RevenueCat init failed (Expected on iOS without Paid Account): $e");
  }
  // Initialize Notification listeners (Taps/Redirects)
  try {
    await NotificationService.init();
  } catch (e) {
    print("Notification Service init failed: $e");
  }
  // await PurchaseApi.init();
  /// ✅ Media store
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'SleepableAI';
  }
  /// ✅ AI service
  // await YamNetService.init();

  /// ✅ Language controller
  Get.put(LanguageController(), permanent: true);

  /// ✅ Orientation lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final controller = Get.put(SleepSoundController(), permanent: true);
  print("main controller hash: ${controller.hashCode}");
    runApp(const MyApp());
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const ClampingScrollPhysics(),
        scrollbars: false,
      ),
      debugShowCheckedModeBanner: false,

      /// ✅ Bindings
      initialBinding: InitialBinding(),

      /// ✅ Routing
      title: 'Sleepable AI',
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,

      /// ✅ Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      /// ✅ Global sizing
      builder: (context, child) {
        SizeConfigs.init(context);
        SizeConfigs2.init(context);
        return child!;
      },

      /// ✅ Localization
      locale: Get.find<LanguageController>().locale.value,
      fallbackLocale: const Locale('en'),

      localizationsDelegates: const [
        AppLocalizations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
    );
  }
}
