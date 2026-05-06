import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/assets.dart';
import '../localization/lang_extension.dart';
import '../localization/languages.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> with SingleTickerProviderStateMixin {
  int _step = 1;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  // Future<void> _launchStore() async {
  //   const String packageName = 'com.yourcompany.sleepable';
  //   final Uri url = Uri.parse("market://details?id=$packageName");
  //   final Uri webUrl = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
  //
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url, mode: LaunchMode.externalApplication);
  //   } else {
  //     await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  //   }
  //   Get.back();
  // }
  // Future<void> _launchStore() async {
  //   const String packageName = 'com.sleepableai.sleepableai';
  //
  //   // 🔥 showAllReviews=true parameter rating section open karne mein help karta hai
  //   final Uri url = Uri.parse("market://details?id=$packageName&showAllReviews=true");
  //   final Uri webUrl = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
  //
  //   try {
  //     if (await canLaunchUrl(url)) {
  //       await launchUrl(url, mode: LaunchMode.externalApplication);
  //     } else {
  //       await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  //     }
  //   } catch (e) {
  //     debugPrint("Could not launch store: $e");
  //   }
  //   Get.back();
  // }
  Future<void> _launchStore() async {
    const String packageName = 'com.sleepableai.sleepableai';
    final Uri url = Uri.parse("market://details?id=$packageName&showAllReviews=true");
    final Uri webUrl = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");

    // 🔥 PERSISTENCE: Save flag that user interacted with rating
    setValue("user_has_rated", true);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch store: $e");
    }
    Get.back();
  }
  @override
  Widget build(BuildContext context) {
    // Determine responsive width (max 400, or 90% of screen)
    double screenWidth = MediaQuery.of(context).size.width;
    final lang = context.lang;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF143B73), Color(0xFF0C1F42)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView( // Prevents bottom overflow on small phones
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    setValue("app_open_count", 0); // Reset count on close
                    Get.back();
                  },
                  icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                ),
              ),
              AnimatedCrossFade(
                firstChild: _buildStep1(screenWidth,lang),
                secondChild: _buildStep2(screenWidth,lang),
                crossFadeState: _step == 1 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 400),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // 🔥 RESET COUNT: Isse user hamesha ke liye block nahi hoga,
                  // par agle kuch sessions tak pareshan bhi nahi hoga.
                  setValue("app_open_count", 0);
                  Get.back();
                },
                child:  Text(
                  lang.maybeLater,// "No, maybe later",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(double screenWidth,BaseLanguage lang) {
    // Dynamic star sizing based on width
    double starSize = (screenWidth < 350) ? 35 : 45;

    return Column(
      key: const ValueKey(1),
      children: [
        // const Icon(Icons.nights_stay, size: 70, color: Colors.white), // Placeholder for Assets.homeSleepableAppIcon
        Center(
            // 🔥 Removed 'const' here
            child: Image.asset(
              Assets.homeSleepableAppIcon,
              width: 70,
              height: 70,
              fit: BoxFit.contain, // Ensures the logo scales nicely without getting cut off
            ),
          ),
        const SizedBox(height: 20),
         Text(
          lang.ratingTitle,//"Glad you like Sleepable!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
         Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            lang.ratingStep1Desc,//"If you like what we do, please leave a review",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: () => setState(() => _step = 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(4, (index) => Icon(
                  Icons.star_rounded,
                  color: const Color(0xFF0F224A),
                  size: starSize
              )),
              Flexible( // Added Flexible to prevent horizontal overflow
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: starSize),
                      const Icon(Icons.keyboard_double_arrow_up_outlined, color: Colors.white, size: 20),
                       Text(
                        lang.theBest,// "The best!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(double screenWidth,BaseLanguage lang) {
    double starSize = (screenWidth < 350) ? 35 : 45;

    return Column(
      key: const ValueKey(2),
      children: [
        // const Icon(Icons.nights_stay, size: 70, color: Colors.white),
        Center(
            // 🔥 Removed 'const' here
            child: Image.asset(
              Assets.homeSleepableAppIcon,
              width: 70,
              height: 70,
              fit: BoxFit.contain, // Ensures the logo scales nicely without getting cut off
            ),
          ),
        const SizedBox(height: 20),
         Text(
          lang.ratingTitle,//"Glad you like Sleepable!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
         Text(
          lang.ratingStep2Desc,// "If you appreciate our work, kindly consider leaving a positive review!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => Icon(
              Icons.star_rounded,
              color: const Color(0xFFFFD700),
              size: starSize
          )),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _launchStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child:  Text(lang.goRating, style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ],
    );
  }
}