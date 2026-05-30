import 'dart:io';
import 'dart:math' as math;

import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:sleepable_ai/localization/lang_extension.dart';
import 'package:video_player/video_player.dart';

import '../../../widgets/custom_loader.dart';
import '../../../widgets/offer_widget.dart';
import '../../email_login/views/email_login_view.dart';
import '../../music/views/music_view.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    final textTheme = Theme.of(context).textTheme;
    final bool hideBack = Get.arguments?["hideBack"] ?? false;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark));

    return PopScope(
      // 🔥 Set 'canPop' to false to block the physical back button
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // Optional: Show a "Press again to exit" or just do nothing
          debugPrint("System back button blocked");
        },
      child: Stack(
          children: [ Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            double h = constraints.maxHeight;
            double w = constraints.maxWidth;
      
            return Container(
              width: w,
              height: h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0D21), Color(0xFF0B0D21)]),//[Color(0xFF1B0831), Color(0xFF0A0514)]
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0 * SizeConfigs.paddingScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20 * SizeConfigs.paddingScale),
      
                        /// 🔹 Back Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child: Row(
                          children: [
                            if (!hideBack && Navigator.canPop(context)) SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 22 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
                          ],
                        ),),
      
                        SizedBox(height: h * 0.01),
      
                        /// 🧠 Title
                        Image.asset(Assets.homeSleepableTextLogo, width: w * 0.50, fit: BoxFit.contain),
                        SizedBox(height: h * 0.01),
      
                        /// ⭐ Lottie Animation
                        // Lottie.asset(Assets.lottieLogin, repeat: true, width: w * 0.70, height: h * 0.30, fit: BoxFit.contain),
                        SizedBox(
                          width: w,
                          height: h * 0.40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Obx(() {
                              if (!controller.isVideoReady.value) {
                                return const Center(child: CircularProgressIndicator());
                              }
      
                              return FittedBox(
                                fit: BoxFit.cover,  // this automatically scales & crops
                                child: SizedBox(
                                  width: controller.videoController.value.size.width,
                                  height: controller.videoController.value.size.height,
                                  child: VideoPlayer(controller.videoController),
                                ),
                              );
                            }),
                          ),
                        ),
      
                        SizedBox(height: h * 0.01),
      
                        /// 🧠 Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child:  Text(
                        context.lang.sleepSmarterDreamDeeper,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 25 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                        ),),
                        SizedBox(height: 10),
      
                        /// 📝 Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
                      child:  Text(
                        context.lang.transformSleepCuperPower,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 14 * SizeConfigs.textScale),
                        ),),
      
                        SizedBox(height: h * 0.030),
      
                        /// 🍎 Apple Button

                        if (Platform.isIOS)
                          _mainButton(
                            text: Get.context?.lang.signupApple ?? "Sign up with Apple",
                            textColor: Colors.white,
                            bgColor: Colors.transparent,
                            image: Image.asset(Assets.homeApple, width: 25, height: 25),
                            onPressed: controller.loginWithApple,
                          ),
                        if (Platform.isIOS)SizedBox(height: h * 0.020),
                        /// 📧 Email Button
                        _mainButton(text:context.lang.continueGoogle, textColor: Colors.white, bgColor: Colors.transparent, image: Image.asset(Assets.homeGoogle, width: 25, height: 25),onPressed: ()async{
                          await Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true,);
                          controller.loginWithGoogle();
                          },),
                        SizedBox(height: 12),
                        _mainButton(
                          text: "Sign in with Email",
                          textColor: Colors.white70,
                          bgColor: Colors.white10,
                          image: Image.asset(Assets.homeMail, width: 20, height: 20),
                          onPressed: () {
                            // Nayi screen par bhejein jahan Email/Pass fill ho sake
                            Get.to(() => EmailLoginView());
                          },
                        ),
                        SizedBox(height: 12),
                        SizedBox(height: h * 0.01),
      
                        /// 🔹 Sign In Link

      
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
            /// 🔄 GLOBAL LOADER
            Obx(() {
              return controller.isLoading.value
                  ? Center(child: LoaderWidget(size:sw(150)))
                  : const SizedBox.shrink();
            }),
          ]),
    );
  }

  Widget _mainButton({required String text, required Color bgColor, required Color textColor, required Image image, required VoidCallback onPressed, }) {
    return  Padding(
        padding: EdgeInsets.symmetric(horizontal: 18 * SizeConfigs.paddingScale),
        child:SizedBox(
      width: double.infinity,
      height: 54 * SizeConfigs.paddingScale,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(width: 1, color: Colors.white10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            image, // ⬅️ your custom image
            SizedBox(width: 10 * SizeConfigs.paddingScale),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 52 * SizeConfigs.paddingScale,
      height: 52 * SizeConfigs.paddingScale,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: color, size: 28 * SizeConfigs.textScale),
    );
  }
}
