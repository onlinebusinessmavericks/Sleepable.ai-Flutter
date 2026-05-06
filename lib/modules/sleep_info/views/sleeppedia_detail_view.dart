
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../music/views/music_view.dart';
import '../model/sleeppedia_item.dart';

class SleeppediaDetailView extends StatelessWidget {
  final SleeppediaItem item;

  const SleeppediaDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    SizeConfigs2.init(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= Banner =================
                Stack(
                  children: [
                    Image.asset(
                      item.image,
                      width: double.infinity,
                      height: sh(260),
                      fit: BoxFit.cover,
                    ),

                    // Gradient overlay
                    Container(
                      width: double.infinity,
                      height: sh(260),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.backgroundColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: sh(50),
                      left: sw(20),
                      child:

                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SmallCircleIcon(
                            icon: Icons.arrow_back_rounded,
                            size: 20 * SizeConfigs.textScale,
                            iconColor: Colors.white,
                            backgroundColor: Colors.white10,
                            onTap: () => Get.back(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: sh(16)),

                // ================= Title =================
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad(22)),
                  child: Text(
                    item.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                      fontSize: sp(32),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: sh(10)),

                // Divider glow
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad(22)),
                  child: Container(
                    width: sw(60),
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.animationStartColor,
                          AppColors.animationEndColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: sh(20)),

                // ================= Sections =================
                ...item.sections.map((section) {
                  return _sectionCard(context, section);
                }),

                SizedBox(height: sh(40)),
              ],
            ),
          ),

        ],
      ),
    );
  }

  // ================= Section Card =================
  Widget _sectionCard(BuildContext context, SleeppediaSection section) {
    return Container(
      margin: EdgeInsets.fromLTRB(pad(18), pad(8), pad(18), pad(12)),
      padding: EdgeInsets.all(pad(16)),
      decoration: BoxDecoration(
        color: AppColors.cardBackGroundGreyColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            section.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: sp(20),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          SizedBox(height: sh(10)),

          // Paragraphs
          ...section.paragraphs.map(
                (text) => Padding(
              padding: EdgeInsets.only(bottom: sh(8)),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: sp(14),
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
          ),

          // Bullets
          ...section.bullets.map(
                (text) => Padding(
              padding: EdgeInsets.only(bottom: sh(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: sh(6)),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.blueColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: sw(10)),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: sp(14),
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
