import 'package:sleepable_ai/core/utils/library.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:sleepable_ai/localization/lang_extension.dart';

void showNotBedTimeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: false,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 1,
      minChildSize: 1,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: const SleepOfferSheet(),
        );
      },
    ),
  );
}

/// =======================
/// BOTTOM SHEET
/// =======================
class SleepOfferSheet extends StatefulWidget {
  const SleepOfferSheet({super.key});

  @override
  State<SleepOfferSheet> createState() => SleepOfferSheetState();
}

class SleepOfferSheetState extends State<SleepOfferSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> titleAnim, imageAnim, plansAnim, buttonAnim;

  final RxInt selectedPlan = 1.obs; // default 12 months

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    titleAnim = CurvedAnimation(parent: _controller, curve: const Interval(0, .2));
    imageAnim = CurvedAnimation(parent: _controller, curve: const Interval(.2, .45));
    plansAnim = CurvedAnimation(parent: _controller, curve: const Interval(.45, .75));
    buttonAnim = CurvedAnimation(parent: _controller, curve: const Interval(.75, 1));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _slideFade({required Animation<double> animation, required Widget child, double offset = 30}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final animValue = animation.value;
        return Opacity(
          opacity: animValue,
          child: Transform.translate(offset: Offset(0, (1 - animValue) * offset), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),child: Container(
        // height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF0A152F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Get.offNamed(Routes.dashboard);
                  // Get.back();
                },
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            _slideFade(
              animation: titleAnim,
              child: Text(
                context.lang.justSleepableSleepWell,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26),
                // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.w600)
              ),
            ),
            // SizedBox(height: 10 * SizeConfigs.paddingScale),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            _slideFade(
              animation: titleAnim,
              child: Text(context.lang.getUnlimitedAccessSleepSoundsSleepAnalysisSnoreRecordingSmartAlarm,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 15),
                // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.w600)
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),

            // SizedBox(height: 30 * SizeConfigs.paddingScale),
            _slideFade(
              animation: imageAnim,
              offset: 40,
              child: Container(
                child: Lottie.asset(
                  Assets.lottieGraphBabyBlue,
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height * 0.29, // <-- correct
                  repeat: true,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            /// ✅ UPDATED PLANS
            _slideFade(
              animation: plansAnim,
              offset: 40,
              child: Obx(
                () => Container(
                  height: // MediaQuery.of(context).size.height * 0.19,
                      180,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PlanCard(
                          title: "1",
                          subtitle: context.lang.month,
                          price: "₹890.00/${context.lang.mo}",
                          bottomPrice: "                             ",
                          isSelected: selectedPlan.value == 0,
                          onTap: () => selectedPlan.value = 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PlanCard(
                          ribbonText: context.lang.dayFreeTrial,
                          title: "12",
                          subtitle: context.lang.months,
                          price: "₹450.0/${context.lang.mo}",
                          bottomPrice: "₹5,400.00/1 ${context.lang.year}",
                          isSelected: selectedPlan.value == 1,
                          onTap: () => selectedPlan.value = 1,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PlanCard(
                          ribbonText: context.lang.mostPopular,
                          title: "3",
                          subtitle: context.lang.months,
                          price: "₹983.33/${context.lang.mo}",
                          bottomPrice: "₹2,950.00/3 ${context.lang.months}",
                          isSelected: selectedPlan.value == 2,
                          onTap: () => selectedPlan.value = 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SizedBox(height: 10 * SizeConfigs.paddingScale),
            SizedBox(height: MediaQuery.of(context).size.height * 0.018),

            Text("✅ ${context.lang.noPaymentNow}", style: const TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(height: MediaQuery.of(context).size.height * 0.018),

            // SizedBox(height: 18 * SizeConfigs.paddingScale),
            _slideFade(
              animation: buttonAnim,
              offset: 30,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offNamed(Routes.dashboard);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        context.lang.continues,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _slideFade(
              animation: titleAnim,
              child: Text(
                context.lang.termsServicePrivacyPolicy,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 12),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          ],
        ),
      ),
    ));
  }
}

/// =======================
/// PLAN CARD (MATCHES IMAGE)
/// =======================
// class _PlanCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final String price;
//   final String? bottomPrice;
//   final String? ribbonText;
//   final bool isSelected;
//   final bool isPrimary;
//   final VoidCallback onTap;
//
//   const _PlanCard({required this.title, required this.subtitle, required this.price, required this.isSelected, required this.onTap, this.bottomPrice, this.ribbonText, this.isPrimary = false});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           AnimatedContainer(
//             duration: const Duration(microseconds: 650),
//             padding: const EdgeInsets.fromLTRB(14, 28, 14, 20),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(18),
//              border: Border.all(color: isSelected ? Colors.blue : Colors.white24, width: isSelected ? 2 : 1),
//             ),
//             child: Column(
//               children: [
//                 SizedBox(height: sh(4)),
//                 // SizedBox(height: 4 * SizeConfigs.paddingScale),
//                 Text(
//                   title,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize:sp(26) ),
//                 ),
//                 SizedBox(height: sh(4)),
//                 // SizedBox(height: 4 * SizeConfigs.paddingScale),
//                 Text(
//                   subtitle,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize:sp(16)),
//                 ),
//
//                 // const SizedBox(height: sh(12)),
//                 SizedBox(height: sh(12)),
//                 Text(
//                   price,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize:sp(13)),
//                   // Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70, fontSize: 13),
//                 ),
//                 // SizedBox(height: sh(4) * SizeConfigs.paddingScale),
//                 SizedBox(height: sh(4)),
//                 SizedBox(
//                   width: double.infinity, // ✅ KEY LINE
//                   child: bottomPrice != null
//                       ? Text(
//                           bottomPrice!,
//                           maxLines: 1,
//                           textAlign: TextAlign.center,
//                           overflow: TextOverflow.visible,
//                           style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
//                         )
//                       : const SizedBox(height: 16),
//                 ),
//               ],
//             ),
//           ),
//
//           /// 🔹 RIBBON
//           if (ribbonText != null)
//             Positioned(
//               top: -14,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isSelected ? AppColors.blueColor : AppColors.backGroundGreyColor, //const Color(0xFF1877F2) : Colors.grey[800],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     ribbonText!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String? bottomPrice;
  final String? ribbonText;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.bottomPrice,
    this.ribbonText,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              pad(14),
              pad(28),
              pad(14),
              pad(20),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(sw(18)),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.white24,
                width: isSelected ? sw(2) : sw(1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // mainAxisSize: MainAxisSize.min,
              children: [
                // SizedBox(height: sh(6)),

                /// TITLE
                // Text(
                //   title,
                //   textAlign: TextAlign.center,
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                //     color: Colors.white,
                //     fontSize: sp(isPrimary ? 28 : 24),
                //     fontWeight: FontWeight.w700,
                //   ),
                // ),
                SizedBox(
                  height: sh(36), // control vertical space
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isPrimary ? 28 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // SizedBox(height: sh(6)),

                /// SUBTITLE
                // Text(
                //   subtitle,
                //   textAlign: TextAlign.center,
                //   maxLines: 3,
                //   overflow: TextOverflow.ellipsis,
                //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                //     color: Colors.white70,
                //     fontSize: sp(14),
                //     height: 1.4,
                //   ),
                // ),
                SizedBox(
                  height: sh(20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // SizedBox(height: sh(14)),

                /// PRICE
                // Text(
                //   price,
                //   textAlign: TextAlign.center,
                //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //     color: Colors.white,
                //     fontWeight: FontWeight.w700,
                //     fontSize: sp(14),
                //   ),
                // ),
                SizedBox(
                  height: sh(20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      price,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),


                // SizedBox(height: sh(6)),

                /// BOTTOM PRICE
                // SizedBox(
                //   width: double.infinity,
                //   child: bottomPrice != null
                //       ? Text(
                //     bottomPrice!,
                //     textAlign: TextAlign.center,
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //       color: Colors.white,
                //       fontWeight: FontWeight.w600,
                //       fontSize: sp(12),
                //     ),
                //   )
                //       : SizedBox(height: sh(14)),
                // ),
                SizedBox(
                  height: sh(18),
                  child: bottomPrice != null
                      ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      bottomPrice!,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                      : const SizedBox(),
                ),

              ],
            ),
          ),

          /// 🔹 RIBBON
          if (ribbonText != null)
            Positioned(
              top: -sh(14),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: pad(14),
                    vertical: pad(6),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blueColor
                        : AppColors.backGroundGreyColor,
                    borderRadius: BorderRadius.circular(sw(20)),
                  ),
                  child: Text(
                    ribbonText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
