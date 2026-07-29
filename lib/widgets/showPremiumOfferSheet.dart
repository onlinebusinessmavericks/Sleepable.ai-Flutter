import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;

// import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:purchases_flutter/models/customer_info_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sleepable_ai/core/utils/library.dart' hide LinearGradient;
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:spinning_wheel/controller/spin_controller.dart';
import 'package:spinning_wheel/models/wheel_label_style.dart';
import 'package:spinning_wheel/models/wheel_segment.dart';
import 'package:spinning_wheel/spinner_wheel.dart';

import '../data/services/api_sevices.dart';
import '../localization/lang_extension.dart';
import '../modules/settings/widget/webview.dart';
import 'SubscriptionController.dart';

const String _kPrivacyPolicyUrl = 'https://sleepable.ai/privacy.html';
const String _kTermsOfUseUrl = 'https://sleepable.ai/terms.html';

void _openPaywallLegalLink(BuildContext context, {required String title, required String url}) {
  Get.to(() => WebViewScreen(title: title, url: url));
}

Widget buildIosSubscriptionLegalLinks(BuildContext context, {double fontSize = 11}) {
  if (!Platform.isIOS) return const SizedBox.shrink();

  final lang = context.lang;
  final linkStyle = TextStyle(
    color: Colors.white70,
    fontSize: fontSize * SizeConfigs.textScale,
    decoration: TextDecoration.underline,
    decorationColor: Colors.white54,
    height: 1.4,
  );

  return Padding(
    padding: EdgeInsets.only(top: sh(8)),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _openPaywallLegalLink(context, title: lang.termsOfService, url: _kTermsOfUseUrl),
          child: Text(lang.termsOfService, style: linkStyle),
        ),
        Text('  •  ', style: linkStyle.copyWith(decoration: TextDecoration.none)),
        GestureDetector(
          onTap: () => _openPaywallLegalLink(context, title: lang.privacyPolicy, url: _kPrivacyPolicyUrl),
          child: Text(lang.privacyPolicy, style: linkStyle),
        ),
      ],
    ),
  );
}

showPremiumOfferSheet(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const PremiumOfferSheetFullScreen());
}

class PremiumOfferSheetFullScreen extends StatefulWidget {
  const PremiumOfferSheetFullScreen({super.key});

  @override
  State<PremiumOfferSheetFullScreen> createState() => _PremiumOfferSheetFullScreenState();
}

Widget slideFade(Animation<double> anim, Widget child, {double offset = 35}) {
  return AnimatedBuilder(
    animation: anim,
    builder: (context, _) {
      final v = anim.value;
      return Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * offset), child: child),
      );
    },
  );
}

class _PremiumOfferSheetFullScreenState extends State<PremiumOfferSheetFullScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeTitle, fadeBanner, fadePlans, fadeButton;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    fadeTitle = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25));
    fadeBanner = CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.50));
    fadePlans = CurvedAnimation(parent: _controller, curve: const Interval(0.50, 0.80));
    fadeButton = CurvedAnimation(parent: _controller, curve: const Interval(0.80, 1.0));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());
    final lang = context.lang;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(Assets.homeRedBackground, fit: BoxFit.cover)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad(20)),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: pad(2), top: sh(36)),

                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () {
                          Get.back();
                          subController.checkAndShowRatingAfterPostDelay();
                        },
                      ),
                    ),
                  ),

                  Expanded(
                    child: Obx(() {
                      final spinData = subController.spinInfo.value;
                      // bool showOffer = spinData != null && spinData.alreadySpun == true;
                      bool showOffer = spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);
                      final standardPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
                      final spinPackage = subController.spinYearlyPackage.value;

                      print("📄 [Sheet 1] showOffer: $showOffer");
                      print("📄 [Sheet 1] spinPackage null?: ${spinPackage == null}");

                      final package = showOffer ? (spinPackage ?? standardPackage) : standardPackage;

                      if (package == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      // Store-localized currency (Play Store country) — same approach as iOS
                      String currencySymbol = subController.getCurrencySymbol(package.storeProduct.currencyCode);
                      double storePrice = package.storeProduct.price;
                      String pricePerYear = package.storeProduct.priceString;

                      // Strike: standard Play price when offer is on; else 1.5x estimate
                      String strikePrice = showOffer && standardPackage != null
                          ? standardPackage.storeProduct.priceString
                          : "$currencySymbol${(storePrice * 1.5).toStringAsFixed(2)}";

                      String pricePerWeek = (storePrice / 52).toStringAsFixed(2);

                      return Column(
                        children: [
                          Flexible(flex: 12, child: slideFade(fadeBanner, Image.asset(Assets.homeGiftYourSelf1))),

                          slideFade(
                            fadePlans,
                            Column(
                              children: [
                                if (showOffer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(color: AppColors.starFillColor, borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      lang.luckySpinOffer, //"LUCKY SPIN OFFER APPLIED",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ).paddingOnly(bottom: 10),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${context.lang.only} ",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18)),
                                      ),
                                      TextSpan(
                                        text: "$currencySymbol$pricePerWeek",
                                        style: TextStyle(color: AppColors.starFillColor, fontSize: sp(28), fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: " / ${context.lang.week}",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18)),
                                      ),
                                    ],
                                  ),
                                ),
                                10.height,
                                Text(
                                  "${context.lang.total} $pricePerYear/${context.lang.year}",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: sp(16)),
                                ),
                                Text(
                                  "($strikePrice/${context.lang.year})",
                                  style: TextStyle(color: Colors.white54, fontSize: sp(14), decoration: TextDecoration.lineThrough),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          slideFade(
                            fadeButton,
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(30))),
                                  padding: EdgeInsets.symmetric(vertical: pad(18)),
                                ),
                                onPressed: () async {
                                  await subController.buyProduct(package);
                                  if (subController.isPremium.value) Get.back();
                                },
                                child: subController.isLoading.value
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        lang.seizeNow, // "Seize Now",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),

                          20.height,
                          Text(lang.cancelAnytime, style: TextStyle(color: Colors.white38, fontSize: 12)),
                          40.height,
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Animation
  Widget slideFade(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: anim.drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero)),
        child: child,
      ),
    );
  }
}

showPremiumOfferSheet2(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const PremiumOfferSheetFullScreen2());
}

class PremiumOfferSheetFullScreen2 extends StatefulWidget {
  const PremiumOfferSheetFullScreen2({super.key});

  @override
  State<PremiumOfferSheetFullScreen2> createState() => _PremiumOfferSheetFullScreen2State();
}

class _PremiumOfferSheetFullScreen2State extends State<PremiumOfferSheetFullScreen2> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeTitle, fadeBanner, fadePlans, fadeButton;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    fadeTitle = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25));
    fadeBanner = CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.50));
    fadePlans = CurvedAnimation(parent: _controller, curve: const Interval(0.50, 0.80));
    fadeButton = CurvedAnimation(parent: _controller, curve: const Interval(0.80, 1.0));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget slideFade(Animation<double> anim, Widget child, {double offset = 35}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final v = anim.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * sh(offset)), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    // final subController = Get.find<SubscriptionController>();
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Container(
      height: SizeConfigs.screenHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(sw(26))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad(20)),
          child: Obx(() {

            final spinData = subController.spinInfo.value;
            bool showOffer = spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);
            final standardPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
            final spinPackage = subController.spinYearlyPackage.value;

            // 1. Identify Package Priority
            final package = showOffer ? (spinPackage ?? standardPackage) : standardPackage;

            if (package == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            // Store-localized currency (Play Store country) — same approach as iOS
            String currencySymbol = subController.getCurrencySymbol(package.storeProduct.currencyCode);
            double storePrice = package.storeProduct.price;
            String pricePerYear = package.storeProduct.priceString;
            String yearlyPrice = pricePerYear;

            String strikePrice = showOffer && standardPackage != null
                ? standardPackage.storeProduct.priceString
                : "$currencySymbol${(storePrice * 1.5).toStringAsFixed(2)}";

            String weeklyPrice = (storePrice / 52).toStringAsFixed(2);
            return Column(
              children: [
                SizedBox(height: sh(16)),

                // CLOSE BUTTON
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      subController.checkAndShowRatingAfterPostDelay();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: pad(2), top: pad(18)),
                      child: Icon(Icons.close, color: Colors.white, size: sp(22)),
                    ),
                  ),
                ),

                SizedBox(height: sh(8)),

                // MAIN CONTENT
                Expanded(
                  child: Column(
                    children: [
                      // BANNER IMAGE
                      Flexible(flex: 17, child: slideFade(fadeBanner, Image.asset(Assets.homeBestDealOfTheYear3, fit: BoxFit.contain))),

                      SizedBox(height: sh(8)),

                      // PRICING (DYNAMIC)
                      Flexible(
                        flex: 3,
                        child: slideFade(
                          fadePlans,
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "ONLY ",
                                      style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.w200),
                                    ),
                                    TextSpan(
                                      text: "$currencySymbol$weeklyPrice",
                                      style: TextStyle(color: AppColors.starFillColor, fontSize: sp(22), fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: " / WEEK",
                                      style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.w200),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: sh(6)),

                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Total $yearlyPrice/year (",
                                      style: TextStyle(color: Colors.white, fontSize: sp(16), fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: showOffer ? "$strikePrice/year" : "$currencySymbol$strikePrice/year",
                                      style: TextStyle(color: Colors.white70, fontSize: sp(16), decoration: TextDecoration.lineThrough),
                                    ),
                                    TextSpan(
                                      text: ")",
                                      style: TextStyle(color: Colors.white, fontSize: sp(16)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // PURCHASE BUTTON
                      slideFade(
                        fadeButton,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(30))),
                              padding: EdgeInsets.symmetric(vertical: pad(18)),
                            ),
                            onPressed: () async {
                              if (package == null) {
                                toast("Please wait.");
                                return;
                              }

                              // Controller ka global purchase function use karein
                              await subController.buyProduct(package);

                              if (subController.isPremium.value) {
                                Get.back();
                              }
                            },
                            child: subController.isLoading.value
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    "Seize Now",
                                    style: TextStyle(color: Colors.white, fontSize: sp(16), fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: sh(12)),

                      // TERMS (DYNAMIC)
                      slideFade(
                        fadeTitle,
                        Text(
                          GetPlatform.isIOS
                              ? "Terms of service & Privacy policy. Please NOTE: Your Apple ID payment method will be automatically charged $yearlyPrice per a year. Cancel the subscription at least 24 hours before the current subscription period to avoid being charged."
                              : "Terms of service & Privacy policy. Please NOTE: Your Google ID payment method will be automatically charged $yearlyPrice per a year. Cancel the subscription at least 24 hours before the current subscription period to avoid being charged.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: sp(10), height: 1.4),
                        ),
                      ),

                      SizedBox(height: sh(16)),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

showPremiumOfferSheet3(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const PremiumOfferSheetFullScreen3());
}

class PremiumOfferSheetFullScreen3 extends StatefulWidget {
  const PremiumOfferSheetFullScreen3({super.key});

  @override
  State<PremiumOfferSheetFullScreen3> createState() => _PremiumOfferSheetFullScreen3State();
}

class _PremiumOfferSheetFullScreen3State extends State<PremiumOfferSheetFullScreen3> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeTitle, fadeBanner, fadePlans, fadeButton;
  late Timer _timer;
  Duration _remaining = const Duration(minutes: 0, seconds: 59, milliseconds: 59);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    fadeTitle = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25));
    fadeBanner = CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.50));
    fadePlans = CurvedAnimation(parent: _controller, curve: const Interval(0.50, 0.80));
    fadeButton = CurvedAnimation(parent: _controller, curve: const Interval(0.80, 1.0));

    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_remaining.inMilliseconds <= 0) {
        _timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _remaining -= const Duration(milliseconds: 10);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- TIMER UI HELPERS ---
  Widget offerTimer() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_remaining.inMinutes.remainder(60));
    final seconds = twoDigits(_remaining.inSeconds.remainder(60));
    final milliSeconds = twoDigits((_remaining.inMilliseconds ~/ 10) % 100);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [_timeBox(minutes), _colon(), _timeBox(seconds), _colon(), _timeBox(milliSeconds)]);
  }

  Widget _timeBox(String value) {
    return Container(
      width: sw(70),
      height: sh(60),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF081A3A),
        borderRadius: BorderRadius.circular(sw(12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: sw(8), offset: Offset(0, sh(4)))],
      ),
      child: Text(
        value,
        style: TextStyle(color: Colors.white, fontSize: sp(26), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _colon() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad(6)),
      child: Text(
        ":",
        style: TextStyle(color: Colors.white, fontSize: sp(26), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget slideFade(Animation<double> anim, Widget child, {double offset = 35}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final v = anim.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * sh(offset)), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {

      final spinData = subController.spinInfo.value;
      // Ensure this condition is same in all sheets:
      bool showOffer = spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);

      final standardPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
      final spinPackage = subController.spinYearlyPackage.value;

      // 1. Sahi Package Select Karein
      final package = showOffer ? (spinPackage ?? standardPackage) : standardPackage;

      if (package == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      // Store-localized currency (Play Store country) — same approach as iOS
      String currencySymbol = subController.getCurrencySymbol(package.storeProduct.currencyCode);
      double storePrice = package.storeProduct.price;
      String pricePerYear = package.storeProduct.priceString;
      String yearlyPrice = pricePerYear;

      String strikePrice = showOffer && standardPackage != null
          ? standardPackage.storeProduct.priceString
          : "$currencySymbol${(storePrice * 1.5).toStringAsFixed(2)}";

      String pricePerWeek = (storePrice / 52).toStringAsFixed(2);
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset(Assets.homeTimeLimitBackground, fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.25))),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad(20)),
                child: Column(
                  children: [
                    SizedBox(height: sh(36)),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Get.back();
                          subController.checkAndShowRatingAfterPostDelay();
                        },
                      ),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Flexible(flex: 16, child: slideFade(fadeBanner, Image.asset(Assets.homeLimitedTime, fit: BoxFit.contain))),

                          SizedBox(height: sh(8)),
                          Flexible(flex: 3, child: offerTimer()),
                          SizedBox(height: sh(12)),

                          // PRICING AREA
                          slideFade(
                            fadePlans,
                            Column(
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${context.lang.only} ",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.w200),
                                      ),
                                      TextSpan(
                                        text: "$currencySymbol$pricePerWeek",
                                        style: TextStyle(color: AppColors.starFillColor, fontSize: sp(24), fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: " / ${context.lang.week}",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.w200),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: sh(6)),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${context.lang.total} $yearlyPrice/${context.lang.year} (",
                                        style: TextStyle(color: Colors.white, fontSize: sp(16), fontWeight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                        // text: "$currency$strikePrice/year",
                                        text: showOffer ? "$strikePrice/${context.lang.year}" : "$currencySymbol$strikePrice/${context.lang.year}",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          // Thoda fade colour strike ke liye accha lagta hai
                                          fontSize: sp(16),
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.lineThrough,
                                          // 👈 Ye line lagayega
                                          decorationColor: Colors.white,
                                          // Line ka color
                                          decorationThickness: 2, // Line ki motai
                                        ),
                                      ),
                                      TextSpan(
                                        text: ")",
                                        style: TextStyle(color: Colors.white, fontSize: sp(16), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // PURCHASE BUTTON
                          slideFade(
                            fadeButton,
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1877F2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(30))),
                                  padding: EdgeInsets.symmetric(vertical: pad(18)),
                                ),
                                onPressed: () async {
                                  if (package == null) {
                                    toast("Loading plans...");
                                    return;
                                  }
                                  // Controller ka universal buy function
                                  await subController.buyProduct(package);
                                  if (subController.isPremium.value) Get.back();
                                },
                                child: subController.isLoading.value
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        context.lang.seizeNow, //"Seize Now",
                                        style: TextStyle(color: Colors.white, fontSize: sp(18), fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),

                          SizedBox(height: sh(12)),
                          Text(
                            "${context.lang.termsApply} ${context.lang.googleIdCharge} $yearlyPrice ${context.lang.perYear} ${context.lang.cancelStore}",
                            //"Terms of service apply. Your Google ID will be charged $yearlyPrice per year. Cancel anytime via Play Store.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: sp(10), height: 1.4),
                          ),
                          SizedBox(height: sh(16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

Future showPremiumOfferSheet4(BuildContext context) {
  return showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const PremiumOfferSheetFullScreen4());
}

class PremiumOfferSheetFullScreen4 extends StatefulWidget {
  const PremiumOfferSheetFullScreen4({super.key});

  @override
  State<PremiumOfferSheetFullScreen4> createState() => _PremiumOfferSheetFullScreen4State();
}

class _PremiumOfferSheetFullScreen4State extends State<PremiumOfferSheetFullScreen4> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeTitle, fadeImage, fadePricing, fadeButton;

  // --- CAROUSEL VARIABLES ---
  late PageController _pageController;
  late Timer _carouselTimer;
  int _currentPage = 0;

  // iOS uses dedicated 1–6 mockups; Android keeps existing paywall1–6 assets.
  final List<String> carouselImages = Platform.isIOS
      ? [Assets.homePaywallIos1, Assets.homePaywallIos2, Assets.homePaywallIos3, Assets.homePaywallIos4, Assets.homePaywallIos5, Assets.homePaywallIos6]
      : [Assets.homePaywall1, Assets.homePaywall2, Assets.homePaywall3, Assets.homePaywall4, Assets.homePaywall5, Assets.homePaywall6];

  final Map<int, Size> imageSizes = {5: Size(sw(850), sh(850))};

  // final List<String> buttonTexts = ["Try for Free", "Get for ₹0.00", "Start Trial Now", "Unlock Access"];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    fadeTitle = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3));
    fadeImage = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6));
    fadePricing = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8));
    fadeButton = CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0));

    _controller.forward();

    _pageController = PageController(initialPage: 0);
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage++;
        });
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget slideFade(Animation<double> anim, Widget child, {double offset = 30}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final v = anim.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * offset), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());
    final lang = context.lang;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {

      final spinData = subController.spinInfo.value;
      bool showOffer = subController.shouldShowDiscountOnPaywall();

      // 1. Identify Package
      final standardPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
      final spinPackage = subController.spinYearlyPackage.value;

      // Choose package based on offer status
      final package = showOffer ? (spinPackage ?? standardPackage) : standardPackage;

      if (package == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      // 2. Real-time Store Data & Currency Fetch
      String yearlyPrice = subController.getDisplayYearlyPrice(
        spinData: spinData,
        discountPackage: spinPackage,
        standardPackage: standardPackage,
        showOffer: showOffer,
      );
      String currencySymbol = subController.resolvePaywallCurrencySymbol(
        package: package,
        displayPrice: yearlyPrice,
      );
      double rawPrice = subController.getDisplayYearlyRawPrice(
        spinData: spinData,
        discountPackage: spinPackage,
        standardPackage: standardPackage,
        showOffer: showOffer,
      );

      // 5. Button Texts Configurations
      final List<String> buttonTexts = [
        lang.btnTryFree,
        lang.btnGetForZero.replaceAll('{symbol}', currencySymbol), // Dynamic symbol string replacement
        lang.btnStartTrial,
        lang.btnUnlockAccess,
      ];

      // Weekly breakdown generation based on dynamic extraction
      String weeklyAvg = (rawPrice / 52).toStringAsFixed(2);

      final currentTextIndex = _currentPage % buttonTexts.length;
      // Apple Guideline 3.1.2(c): the rotating "Get for {symbol}0.00" label made a
      // $0.00 price more conspicuous than the billed amount. iOS uses one stable,
      // neutral label; Android keeps the rotating marketing labels.
      String currentButtonText = Platform.isIOS ? lang.startFreeTrial : buttonTexts[currentTextIndex];
      return PopScope(
        canPop: Platform.isIOS,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (Get.currentRoute == Routes.login) {
            Get.back(result: true);
            Get.offAllNamed(Routes.dashboard);
          } else {
            Get.back(result: false);
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0B0E1B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            image: DecorationImage(image: AssetImage(Assets.homePaywellBackground1), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken)),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad(24)),
              child: Column(
                children: [
                  SizedBox(height: sh(30)),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        // Agar current route login hai, toh dashboard bhej do
                        if (Get.currentRoute == Routes.login) {
                          Get.back(result: true);
                          Get.offAllNamed(Routes.dashboard);
                        } else {
                          Get.back(result: false);
                        }
                        subController.checkAndShowRatingAfterPostDelay();
                      },
                      icon: const Icon(Icons.close, color: Colors.white54, size: 28),
                    ),
                  ),

                  SizedBox(height: sh(16)),

                  slideFade(
                    fadeTitle,
                    Column(
                      children: [
                        // Apple Guideline 3.1.2(c): no prominent discount banner in the
                        // iOS purchase flow. Android keeps its "Lucky Spin" badge.
                        if (showOffer && !Platform.isIOS)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            margin: EdgeInsets.only(bottom: sh(10)),
                            decoration: BoxDecoration(
                              color: AppColors.starFillColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              Platform.isIOS
                                  ? lang.limitedPeriodOffer.replaceAll('{discount}', '${subController.paywallDiscountPercent}')
                                  : lang.luckySpinOffer,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10 * SizeConfigs.textScale,
                              ),
                            ),
                          ),
                        Text(
                          "${context.lang.trySleepableFree}\n${context.lang.trySleepableFree1}",
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sh(6)),

                  // CAROUSEL
                  Expanded(
                    flex: 8,
                    child: slideFade(
                      fadeImage,
                      PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final imgIndex = index % carouselImages.length;
                          final customSize = imageSizes[imgIndex] ?? Size(sw(550), sh(550));

                          return Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: customSize.width,
                              height: customSize.height,
                              child: Image.asset(carouselImages[imgIndex], fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: sh(6)),

                  // PRICING CHECK
                  slideFade(
                    fadePricing,
                    Padding(
                      padding: EdgeInsets.only(bottom: sh(16)),
                      child: Column(
                        children: [
                          if (showOffer && Platform.isIOS && standardPackage != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: sh(8)),
                              child: Text(
                                standardPackage.storeProduct.priceString,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white54,
                                  fontSize: 14 * SizeConfigs.textScale,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 22),
                              SizedBox(width: sw(8)),
                              Text(
                                showOffer
                                    ? (Platform.isIOS
                                        ? subController.formatIosYearlyPriceLine(
                                            prefix: context.lang.just,
                                            yearlyPrice: yearlyPrice,
                                            currencySymbol: currencySymbol,
                                            weeklyAvg: weeklyAvg,
                                          )
                                        : "${context.lang.just} $yearlyPrice ${context.lang.perYear} ($currencySymbol$weeklyAvg/${context.lang.perWeek})")
                                    : context.lang.noPaymentDue,
                                style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ACTION BUTTON
                  slideFade(
                    fadeButton,
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: sh(55),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              if (Platform.isIOS) {
                                Get.back();
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  showPremiumOfferSheet8(context);
                                });
                                return;
                              }
                              Get.back();
                              Future.delayed(const Duration(milliseconds: 100), () {
                                showPremiumOfferSheet7(context);
                              });
                            },
                            child: Text(
                              currentButtonText,
                              style: textTheme.titleLarge?.copyWith(color: Colors.black, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: sh(12)),
                        if (Platform.isIOS) ...[
                          // Apple Guideline 3.1.2(c): billed amount is the most
                          // conspicuous pricing element; the trial is subordinate.
                          Text(
                            "$yearlyPrice / ${context.lang.year}",
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 24 * SizeConfigs.textScale,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: sh(2)),
                          Text(
                            "3-day free trial, then $yearlyPrice per year ($currencySymbol$weeklyAvg / ${context.lang.week}). Cancel anytime.",
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(color: Colors.white54, fontSize: 11 * SizeConfigs.textScale),
                          ),
                        ] else
                          Text(
                            "${context.lang.just} $yearlyPrice ${context.lang.perYear} ($weeklyAvg/${context.lang.perWeek})",
                            style: textTheme.bodyMedium?.copyWith(color: Colors.white60, fontSize: 13 * SizeConfigs.textScale),
                          ),
                        buildIosSubscriptionLegalLinks(context),
                      ],
                    ),
                  ),
                  SizedBox(height: sh(24)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

showPremiumOfferSheet5(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const LuckySpinScreen());
}

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen> {
  SpinnerController controller = SpinnerController();
  bool _isSpinning = false;
  String? _statusText;
  bool _hasWon = false;

  final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

  // Segments logic (Probability match with your backend)
  final List<WheelSegment> _segments = [
    WheelSegment('80%', 80, color: Colors.black, probability: 0.5),
    WheelSegment('70%', 70, color: Colors.white, probability: 0.0),
    WheelSegment(Get.context?.lang.gift ?? 'Gift', 1, color: Colors.black, probability: 0.5),
    WheelSegment('60%', 60, color: Colors.white, probability: 0.0),
    WheelSegment('30%', 30, color: Colors.black, probability: 0.0),
    WheelSegment(Get.context?.lang.noLuck ?? 'No Luck', 0, color: Colors.white, probability: 0.0),
  ];

  void _spinWheel() async {
    final lang = Get.context?.lang;
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _statusText = lang?.goodLuck ?? "Good Luck!";
    });

    // 1. Backend API Call
    await subController.performSpin();

    if (subController.spinInfo.value != null) {
      // 2. Wheel Start
      controller.startSpin();
    } else {
      setState(() {
        _isSpinning = false;
        _statusText = "${lang?.connectionError}\n${lang?.tryAgainLater}";
        // _statusText = "Connection error.\nTry again later.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final double wheelSize = (size.width * 0.85).clamp(250.0, 400.0);
    final lang = context.lang;
    return PopScope(
      canPop: false, // User spin ke beech mein back nahi kar sakta
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText ?? ("${lang.spinToUnlockAn}\n${lang.exclusiveDiscount}"),
                  // key: ValueKey(_statusText),
                  key: ValueKey(_statusText ?? "initial_spin_status_key"),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(fontSize: 28 * SizeConfigs.textScale, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                ),
              ),

              const Spacer(flex: 1),

              // SPINNING WHEEL
              SizedBox(
                height: wheelSize,
                width: wheelSize,
                child: SpinnerWheel(
                  controller: controller,
                  segments: _segments,
                  labelStyle: WheelLabelStyle(
                    labelStyle: textTheme.titleMedium!.copyWith(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18 * SizeConfigs.textScale),
                  ),
                  onComplete: (win, index) {
                    setState(() {
                      _isSpinning = false;
                      _hasWon = true;

                      final spinData = subController.spinInfo.value;
                      final discount = spinData?.discountPct ?? 80;

                      //_statusText = "CONGRATS!\nYou unlocked $discount% OFF";
                      _statusText = "${lang.congrats}\n${lang.unlocked} $discount% ${lang.off}";
                      // ✅ Professional Toast logic
                      String toastMsg = (spinData?.message != null && spinData!.message!.isNotEmpty) ? spinData.message! : "🎉 ${lang.congrats} $discount% ${lang.discountUnlocked}";

                      toast(toastMsg);
                    });
                  },
                ),
              ),

              const Spacer(flex: 2),

              // BUTTON
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad(24), vertical: sh(16)),
                child: Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: sh(60),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      onPressed: () {
                        if (!_isSpinning && !_hasWon) {
                          _spinWheel();
                        } else if (_hasWon) {
                          // Sheet 5 close karke Sheet 6 open karein
                          Get.back();
                          showPremiumOfferSheet6(context);
                        }
                      },
                      child: subController.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _isSpinning ? lang.spinning : (_hasWon ? lang.claimDiscount : lang.spinNow),
                              // Text(
                              //         _isSpinning ? "SPINNING..." : (_hasWon ? "CLAIM DISCOUNT" : "Spin Now"),
                              style: textTheme.titleLarge?.copyWith(color: Colors.black, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh(16)),
            ],
          ),
        ),
      ),
    );
  }
}

showPremiumOfferSheet6(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const OneTimeOfferSheet());
}

class OneTimeOfferSheet extends StatefulWidget {
  const OneTimeOfferSheet({super.key});

  @override
  State<OneTimeOfferSheet> createState() => _OneTimeOfferSheetState();
}

class _OneTimeOfferSheetState extends State<OneTimeOfferSheet> {
  bool isFreeTrialEnabled = true;
  int selectedPlanIndex = 1; // Default Yearly selected

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      final weeklyPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.weekly);

      final spinData = subController.spinInfo.value;
      // ✅ Check karein ki spinData null toh nahi hai aur spin ho chuka hai
      // Ensure this condition is same in all sheets:
      bool showOffer = spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);
      final standardPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
      final spinPackage = subController.spinYearlyPackage.value;

      // Package select karein
      final yearlyPackage = showOffer ? (spinPackage ?? standardPackage) : standardPackage;

      if (yearlyPackage == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

      // Store-localized currency (Play Store country) — same approach as iOS
      String currencySymbol = subController.getCurrencySymbol(yearlyPackage.storeProduct.currencyCode);
      String yearlyDisplayPrice = yearlyPackage.storeProduct.priceString;
      double storePrice = yearlyPackage.storeProduct.price;

      String strikePrice = showOffer && standardPackage != null
          ? standardPackage.storeProduct.priceString
          : "$currencySymbol${(storePrice * 1.5).toStringAsFixed(2)}";

      double discountedYearlyRaw = storePrice;

      double actualDaily = discountedYearlyRaw / 365;
      String finalDailyPriceDisplay;

      if (yearlyPackage.storeProduct.currencyCode.toUpperCase() == "INR") {
        // ₹7.77 Lucky number formatting (India Play storefront only)
        if (actualDaily >= 7.0 && actualDaily <= 8.5) {
          finalDailyPriceDisplay = "7.77";
        } else {
          finalDailyPriceDisplay = actualDaily.toStringAsFixed(2);
        }
      } else {
        finalDailyPriceDisplay = actualDaily.toStringAsFixed(2);
      }

      // Weekly Average for sub-card
      String weeklyAvgFromYearly = (discountedYearlyRaw / 52).toStringAsFixed(2);

      final bool isYearly = selectedPlanIndex == 1;
      final String buttonText = isYearly ? (isFreeTrialEnabled ? "Start Free Trial" : "Continue with Yearly") : "Continue with Weekly";
      final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // ✅ FORCE CLOSE ALL MODALS
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        },
        child: Container(
          height: size.height,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad(24)),
                    child: Column(
                      children: [
                        SizedBox(height: sh(80)),

                        Text(
                          context.lang.oneTimeOfferTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(fontSize: 32 * SizeConfigs.textScale, fontWeight: FontWeight.w900, color: Colors.white),
                        ),

                        SizedBox(height: sh(24)),
                        _buildDiscountCard(homeController, textTheme),
                        SizedBox(height: sh(24)),
                        _buildFeatureRow("💤", context.lang.featureSleep, textTheme),
                        _buildFeatureRow("🎶", context.lang.featureSounds, textTheme),
                        _buildFeatureRow("📈", context.lang.featureAnalytics, textTheme),
                        SizedBox(height: sh(24)),

                        SizedBox(
                          width: double.infinity, // ✅ Poori width cover karega
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0), // Thoda margin safety ke liye
                            child: FittedBox(
                              fit: BoxFit.scaleDown, // ✅ Agar text bada ho jaye toh automatically scale karega
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    strikePrice,
                                    style: TextStyle(
                                      fontSize: 30,
                                      letterSpacing: 2.5,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.red,
                                      decorationThickness: 1.5,
                                      fontWeight: FontWeight.w900,
                                      foreground: Paint()
                                        ..style = PaintingStyle.fill
                                        ..strokeWidth = 1.5
                                        ..color = Colors.white38,
                                    ),
                                  ),

                                  const SizedBox(width: 30), // Space between prices

                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          // text: "$currency$finalDailyPriceDisplay/${context.lang.day}",
                                          text: "$currencySymbol$finalDailyPriceDisplay/${context.lang.day}",
                                          style: const TextStyle(fontSize: 50, color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sh(16)),
                        _buildPlanCard(
                          index: 1,
                          title: context.lang.yearlyPremium,
                          price: "$currencySymbol$weeklyAvgFromYearly/${context.lang.week ?? 'wk'}",
                          subTitle: "12mo • $yearlyDisplayPrice",
                          isPopular: true,
                          textTheme: textTheme,
                        ),

                        SizedBox(height: sh(30)),

                        // 5. DYNAMIC PURCHASE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: sh(60),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),

                            onPressed: () async {
                              final packageToBuy = isYearly ? yearlyPackage : weeklyPackage;
                              if (packageToBuy != null) {
                                await subController.buyProduct(packageToBuy);
                                // ✅ SUCCESS: Dashboard par bhejte waqt sab clear karein
                                if (subController.isPremium.value) {
                                  Get.until((route) => Get.isOverlaysClosed);
                                  Get.offAllNamed(Routes.dashboard);
                                }
                              }
                            },
                            child: subController.isLoading.value
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    buttonText, // Ab 'buttonText' available hai
                                    style: textTheme.titleLarge?.copyWith(fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                          ),
                        ),

                        SizedBox(height: sh(16)),
                        Text(context.lang.noCommitment, style: TextStyle(color: Colors.white54, fontSize: 14)),
                        SizedBox(height: sh(40)),
                      ],
                    ),
                  ),
                ),

                // CLOSE BUTTON
                Positioned(
                  top: sh(36),
                  right: pad(16),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28, color: Colors.white),
                    onPressed: () {
                      // Get.back(result: false);},
                      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                      subController.checkAndShowRatingAfterPostDelay();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // --- UI Helpers ---

  Widget _buildDiscountCard(homeController, textTheme) {
    return AnimatedBuilder(
      animation: homeController.animationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: sh(24)),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blueLine.withOpacity(.4), AppColors.blueLine.withOpacity(.9), AppColors.blueLine.withOpacity(.4)],
              stops: [homeController.animation.value - 0.4, homeController.animation.value, homeController.animation.value + 0.4],
            ),
          ),
          child: Column(
            children: [
              Text(
                "50% ${context.lang.off}",
                style: textTheme.displaySmall?.copyWith(fontSize: sp(48), fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text(
                context.lang.offForever,
                style: textTheme.headlineMedium?.copyWith(fontSize: sp(34), fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard({required int index, required String title, required String price, required String subTitle, bool isPopular = false, required TextTheme textTheme}) {
    bool isSelected = selectedPlanIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPlanIndex = index),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.white : Colors.white12, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.background,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (isPopular)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: sh(6)),
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(
                  context.lang.specialDiscountApplied, //"SPECIAL DISCOUNT APPLIED",
                  style: TextStyle(color: Colors.black, fontSize: sp(12), fontWeight: FontWeight.bold),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad(20), vertical: sh(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: sp(20), fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        subTitle,
                        style: TextStyle(color: Colors.white54, fontSize: sp(14)),
                      ),
                    ],
                  ),
                  Text(
                    price,
                    style: TextStyle(fontSize: sp(22), fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sh(8)),
      child: Row(
        children: [
          SizedBox(
            width: sw(30),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: sp(22))),
            ),
          ),
          SizedBox(width: sw(12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: sp(16), fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

showPremiumOfferSheet7(BuildContext context) {
  if (Platform.isIOS) return showPremiumOfferSheet4(context);
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const FreeTrialReminderScreen());
}

class FreeTrialReminderScreen extends StatelessWidget {
  const FreeTrialReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    final textTheme = Theme.of(context).textTheme;

    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final spinData = subController.spinInfo.value;
          // Ensure this condition is same in all sheets:
          bool showOffer = spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);

          // 1. Determine Package
          final package = showOffer
              ? (subController.spinYearlyPackage.value ?? subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual))
              : subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);

          if (package == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // Store-localized currency (Play Store country) — same approach as iOS
          String currencySymbol = subController.getCurrencySymbol(package.storeProduct.currencyCode);
          String yearlyPrice = package.storeProduct.priceString;
          double storePrice = package.storeProduct.price;
          String weeklyPrice = (storePrice / 52).toStringAsFixed(2);
          return PopScope(
            canPop: false, // 👈 Physical back button ko block karein
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // ✅ STEP 1: Check karein user kahan se aaya hai
              if (Get.currentRoute == Routes.login) {
                // Agar login se aaya hai, toh dashboard bhej do
                Get.offAllNamed(Routes.dashboard);
              } else {
                // Agar kisi aur screen (Recorder/Sounds) se aaya hai, toh sirf sheet band karo
                Get.back();
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sh(36)),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        // Agar current route login hai, toh dashboard bhej do
                        if (Get.currentRoute == Routes.login) {
                          Get.offAllNamed(Routes.dashboard);
                        } else {
                          // Warna sirf sheet close karo taki user wahi screen par rahe
                          Get.back(result: false);
                        }
                        subController.checkAndShowRatingAfterPostDelay();
                      },
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 2. TITLE
                  Text(
                    // "We'll send you\na reminder before\nyour\nfree trial ends",
                    "${context.lang.remindPart1}\n"
                    "${context.lang.remindPart2}\n"
                    "${context.lang.remindPart3}\n"
                    "${context.lang.remindPart4}",
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 34 * SizeConfigs.textScale, fontWeight: FontWeight.w900, height: 1.15),
                  ),

                  const Spacer(flex: 1),

                  // 3. BELL ANIMATION
                  SizedBox(
                    height: sh(180),
                    child: Lottie.asset(Assets.lottieNotificationBell, fit: BoxFit.contain, repeat: true),
                  ),

                  const Spacer(flex: 2),

                  // 4. STATUS TEXT
                  Padding(
                    padding: EdgeInsets.only(bottom: sh(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.starFillColor, size: 24),
                        SizedBox(width: sw(8)),
                        Text(
                          context.lang.noPaymentDue, // "No Payment Due Now",
                          style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // 5. MAIN ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: sh(60),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (subController.isPremium.value) {
                          Get.offAllNamed(Routes.dashboard);
                        } else {
                          Get.back();
                          showPremiumOfferSheet8(context);
                        }
                      },
                      child: subController.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              context.lang.continueFree,
                              style: textTheme.titleLarge?.copyWith(color: Colors.black, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  SizedBox(height: sh(16)),

                  // 6. PRICING SUBTEXT (Dynamic)
                  Text(
                    // "Just $yearlyPrice per year ($currencySymbol$weeklyPrice/Week)",
                    "${context.lang.just} $yearlyPrice ${context.lang.perYear} "
                    "($currencySymbol$weeklyPrice${context.lang.perWeek})",
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white60, fontSize: 14 * SizeConfigs.textScale),
                  ),

                  SizedBox(height: sh(32)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

showPremiumOfferSheet8(BuildContext context) {
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, enableDrag: false, builder: (_) => const UnifiedPremiumSheet());
}

class UnifiedPremiumSheet extends StatefulWidget {
  const UnifiedPremiumSheet({super.key});

  @override
  State<UnifiedPremiumSheet> createState() => _UnifiedPremiumSheetState();
}

class _UnifiedPremiumSheetState extends State<UnifiedPremiumSheet> {
  int selectedPlanIndex = 1; // 1 = Yearly (Default), 0 = Weekly

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    final textTheme = Theme.of(context).textTheme;
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      final spinData = subController.spinInfo.value;
      bool showOffer = Platform.isIOS
          ? subController.shouldShowDiscountOnPaywall()
          : spinData != null && (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);

      final standardAnnual = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
      final spinPackage = subController.spinYearlyPackage.value;
      final weeklyPackage = subController.packages.firstWhereOrNull((p) => p.packageType == PackageType.weekly);

      // 1. Offer priority
      final yearlyPackage = showOffer ? (spinPackage ?? standardAnnual) : standardAnnual;

      if (yearlyPackage == null) return const Center(child: CircularProgressIndicator());

      // 2. Real-time Store Data & Currency Fetch
      String yearlyPriceText = subController.getDisplayYearlyPrice(
        spinData: spinData,
        discountPackage: spinPackage,
        standardPackage: standardAnnual,
        showOffer: showOffer,
      );
      String currencySymbol = subController.resolvePaywallCurrencySymbol(
        package: yearlyPackage,
        displayPrice: yearlyPriceText,
      );

      // Weekly card price from App Store
      String weeklyPriceText = weeklyPackage?.storeProduct.priceString ?? yearlyPackage.storeProduct.priceString;
      String? weeklyOriginalPrice;
      String? yearlyOriginalPrice;
      if (showOffer && Platform.isIOS) {
        if (standardAnnual != null) {
          yearlyOriginalPrice = standardAnnual.storeProduct.priceString;
        }
        if (weeklyPackage != null) {
          weeklyOriginalPrice = weeklyPackage.storeProduct.priceString;
        }
      }

      double rawYearlyMath = subController.getDisplayYearlyRawPrice(
        spinData: spinData,
        discountPackage: spinPackage,
        standardPackage: standardAnnual,
        showOffer: showOffer,
      );

      String weeklyAvgFromYearly = (rawYearlyMath / 52).toStringAsFixed(2);

      final bool isYearly = (selectedPlanIndex == 1);
      final lang = context.lang;

      final String mainTitle = isYearly ? lang.startTrialToContinue : lang.unlockSleepableTitle;
      final String buttonText = isYearly ? lang.startFreeTrial : lang.startJourney;

      final String bottomSubText = isYearly
          ? (Platform.isIOS
              ? subController.formatIosTrialSubtext(
                  yearlyPrice: yearlyPriceText,
                  currencySymbol: currencySymbol,
                  weeklyAvg: weeklyAvgFromYearly,
                )
              : "${lang.threeDaysFreeThen} $yearlyPriceText ($currencySymbol$weeklyAvgFromYearly${lang.perWeek})")
          : "${lang.just} $weeklyPriceText ${lang.perWeek}";
      return PopScope(
        canPop: Platform.isIOS,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (Get.currentRoute == Routes.login) {
            Get.offAllNamed(Routes.dashboard);
          } else {
            Get.back();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sh(36)),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Get.back();
                        subController.checkAndShowPremiumSheet(context);
                        subController.checkAndShowRatingAfterPostDelay();
                      },
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),

                  // Apple Guideline 3.1.2(c): the prominent "50% OFF" discount banner
                  // was removed from this purchase flow — it made the introductory
                  // offer more conspicuous than the billed amount. It was already
                  // iOS-only here, so Android's flow is unaffected.

                  const Spacer(flex: 1),

                  Text(
                    mainTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 28 * SizeConfigs.textScale, fontWeight: FontWeight.w900),
                  ),

                  const Spacer(flex: 1),

                  // CENTER CONTENT (Timeline vs Features)
                  AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: isYearly ? _buildTimeline(textTheme) : _buildFeaturesList(textTheme)),

                  const Spacer(flex: 1),

                  // 4. PLAN SELECTION CARDS
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlanCard(
                          index: 0,
                          title: context.lang.weekly,
                          price: weeklyPriceText,
                          originalPrice: weeklyOriginalPrice,
                          textTheme: textTheme,
                        ),
                      ),
                      SizedBox(width: sw(12)),
                      Expanded(
                        child: _buildPlanCard(
                          index: 1,
                          title: context.lang.yearly,
                          price: yearlyPriceText,
                          originalPrice: yearlyOriginalPrice,
                          badge: context.lang.threeDaysFreeBadge,
                          textTheme: textTheme,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sh(24)),

                  // 5. STATUS TEXT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: isYearly ? const Color(0xFFF6A342) : Colors.white, size: 22),
                      SizedBox(width: sw(8)),
                      Text(
                        isYearly ? context.lang.noPaymentDue : context.lang.noCommitment,
                        style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  SizedBox(height: sh(16)),

                  // 6. CTA BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: sh(60),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isYearly ? const Color(0xFFF6A342) : Colors.white,
                        foregroundColor: isYearly ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      // onPressed: () async {
                      //   // Purchase Logic
                      //   final package = isYearly ? yearlyPackage : weeklyPackage;
                      //   if (package != null) {
                      //     await subController.buyProduct(package);
                      //     if (subController.isPremium.value) Get.back();
                      //   }
                      // },
                      onPressed: () async {
                        final package = isYearly ? yearlyPackage : weeklyPackage;
                        if (package != null) {
                          await subController.buyProduct(package);
                          if (subController.isPremium.value) {
                            Get.offAllNamed(Routes.dashboard);
                          }
                        }
                      },
                      child: subController.isLoading.value ? const CircularProgressIndicator() : Text(buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  SizedBox(height: sh(12)),

                  if (Platform.isIOS) ...[
                    // Apple Guideline 3.1.2(c): the total billed amount must be the
                    // MOST clear and conspicuous pricing element. It is shown largest
                    // here; the free trial and per-week breakdown are subordinate.
                    Text(
                      isYearly ? "$yearlyPriceText / ${lang.year}" : "$weeklyPriceText / ${lang.week}",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 30 * SizeConfigs.textScale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: sh(4)),
                    Text(
                      isYearly
                          ? "3-day free trial, then $yearlyPriceText per year ($currencySymbol$weeklyAvgFromYearly / ${lang.week}). Cancel anytime."
                          : "Billed $weeklyPriceText per week. Cancel anytime.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white54, fontSize: 12 * SizeConfigs.textScale),
                    ),
                  ] else
                    Text(
                      bottomSubText,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 14 * SizeConfigs.textScale),
                    ),

                  buildIosSubscriptionLegalLinks(context, fontSize: 12),

                  SizedBox(height: sh(24)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // --- CONTENT HELPERS ---

  Widget _buildFeaturesList(TextTheme textTheme) {
    final lang = context.lang;

    return Column(
      key: const ValueKey(0),
      children: [
        _featureRow(lang.easySleepTracking, lang.trackCyclesAuto, textTheme),
        SizedBox(height: sh(16)),
        _featureRow(lang.wakeUpRefreshed, lang.keepItSimple, textTheme),
        SizedBox(height: sh(16)),
        _featureRow(lang.trackProgress, lang.smartReminders, textTheme),
        // _featureRow("Easy sleep tracking", "Track your cycles automatically", textTheme),
        // SizedBox(height: sh(16)),
        // _featureRow("Wake up refreshed", "Keep it simple to make waking up easy", textTheme),
        // SizedBox(height: sh(16)),
        // _featureRow("Track your progress", "Smart reminders & insights", textTheme),
      ],
    );
  }

  Widget _featureRow(String title, String subtitle, TextTheme textTheme) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 28),
        SizedBox(width: sw(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white60, fontSize: 14 * SizeConfigs.textScale),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(TextTheme textTheme) {
    return Row(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildTimelineIcon(Icons.lock_open_rounded),
            Container(width: sw(3), height: sh(50), color: const Color(0xFFF6A342).withOpacity(0.4)),
            _buildTimelineIcon(Icons.notifications_none_rounded),
            Container(width: sw(3), height: sh(40), color: const Color(0xFFF6A342).withOpacity(0.4)),
            _buildTimelineIcon(Icons.stars_rounded),
          ],
        ),
        SizedBox(width: sw(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.lang.tlToday,
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(context.lang.tlTodaySub, style: textTheme.bodyMedium?.copyWith(color: Colors.white54)),
              SizedBox(height: sh(40)),
              Text(
                context.lang.tlReminder,
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(context.lang.tlReminderSub, style: textTheme.bodyMedium?.copyWith(color: Colors.white54)),
              SizedBox(height: sh(30)),

              // Step 3 (Naya Point)
              Text(
                context.lang.tlBilling,
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(context.lang.tlBillingSub, style: textTheme.bodyMedium?.copyWith(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineIcon(IconData icon) => Container(
    padding: EdgeInsets.all(pad(8)),
    decoration: const BoxDecoration(color: Color(0xFFF6A342), shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 20),
  );

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    String? originalPrice,
    String? badge,
    required TextTheme textTheme,
  }) {
    bool isSelected = selectedPlanIndex == index;
    final showStrike = Platform.isIOS && originalPrice != null && originalPrice != price;
    return GestureDetector(
      onTap: () => setState(() => selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: EdgeInsets.all(sh(16)),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFFF6A342) : Colors.white24, width: isSelected ? 2 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                    ),
                    if (showStrike)
                      Text(
                        originalPrice,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12 * SizeConfigs.textScale,
                        ),
                      ),
                    Text(
                      price,
                      style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFFF6A342) : Colors.white24, size: 28),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -sh(10),
              // Apple Guideline 3.1.2(c): the free-trial badge must stay subordinate
              // to the billed amount, so it is muted (not bright orange) on iOS.
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Platform.isIOS ? Colors.white24 : const Color(0xFFF6A342),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
