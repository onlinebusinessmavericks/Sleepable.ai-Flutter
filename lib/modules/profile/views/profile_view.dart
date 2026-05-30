import 'package:cached_network_image/cached_network_image.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:sleepable_ai/modules/settings/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../generated/assets.dart';
import '../../../localization/lang_extension.dart';
import '../../../localization/language_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../home/controllers/home_controller.dart';
import '../../language/views/language_view.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final controller = Get.put(ProfileController(), permanent: false);
  final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0824),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // title: Text("Profile", style: TextStyle(color: AppColors.blueColor.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 24)),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.textColor, AppColors.primary]).createShader(bounds),
          child: Text(
            context.lang.profileTitle,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          // PRO Button
          Obx(() {
            return
          (subController.isPremium.value == false)? GestureDetector(
            onTap: () {
              // 1. Check karein ki spin data exist karta hai aur spin ho chuka hai
              final bool hasAlreadySpun = subController.spinInfo.value?.alreadySpun ?? false;
              final controller = Get.find<HomeController>();
              if (hasAlreadySpun) {
                // ✅ Agar spin ho gaya hai toh Direct Discounted Sheet (Sheet 6)
                // showPremiumOfferSheet6(context);
                controller.showRotatingPremiumSheet(Get.context!);
              } else {
                // ❌ Agar spin nahi hua toh Normal Paywall ya Spin Wheel (Sheet 4 ya 5)
                // Aapne Sheet 4 kaha hai toh wahi open hogi
                showPremiumOfferSheet4(context);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.proLight, AppColors.proDark, // Bright Yellow/Gold
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child:  Text(
                context.lang.proButton,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
              ):SizedBox();}),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: true),
            child: Stack(
              children: [
                /// 🟣 Full-screen background (fixed)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        //Positioned.fill(child: Image.asset(Assets.musicCloudImage2, fit: BoxFit.cover)),
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF0C0E1B), // 👈 Your background color
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.99)]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🧠 Main content
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    // physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    controller: controller.screenScrollController,
                    padding: EdgeInsets.all(12 * SizeConfigs.paddingScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // SizedBox(height: 3 * SizeConfigs.paddingScale),


                        /// 👤 Profile Info Row (Avatar + Name/Email)
                        _buildUserInfo(context),
                        const SizedBox(height: 40),
                        _buildConsecutiveDays(context),

                        const SizedBox(height: 40),

                        /// 📊 Stats Grid (Tracked Nights, Avg Time, Score)
                        _buildStatsGrid(context),

                        const SizedBox(height: 30),
                        /// 🌙 Sleep Tracker Section
                        Container(
                          width: double.infinity,
                          // margin: const EdgeInsets.only(bo: 12),
                          padding: const EdgeInsets.only(top: 18, bottom: 15, left: 18, right: 18),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            // color: const Color(0xFF1B1035).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Text(
                                  context.lang.sleepTracker,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 21 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                ),
                              ),
                              SizedBox(height: 16 * SizeConfigs.paddingScale),

                              Obx(
                                () => _settingsTile(
                                  title: context.lang.sleepGoal,
                                  subtitle: controller.settings.value == null
                                      ? "--"
                                      : "${controller.formatTime(controller.settings.value!.bedtime)} - "
                                            "${controller.formatTime(controller.settings.value!.wakeUpTime)}",
                                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                  context: context,
                                  onTap: () {
                                    Get.toNamed(Routes.profileSleepGoal);
                                  },
                                ),
                              ),
                              Obx(
                                () => _settingsTile(
                                  title: context.lang.sleepReminder,
                                  subtitle: controller.settings.value?.sleepReminders == true ? controller.formatTime(controller.settings.value?.remindAt) : context.lang.offLabel,//"Off"
                                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                  context: context,
                                  onTap: () {
                                    Get.toNamed(Routes.profileSleepReminder);
                                  },
                                ),
                              ),

                              Obx(() {
                                final settings = controller.settings.value;
                                // Use the boolean directly from the model
                                final bool isAlarmOn = settings?.alarmEnabled ?? false;

                                return _settingsTile(
                                  title: context.lang.alarm,
                                  subtitle: isAlarmOn ? controller.formatTime(settings!.alarmTime) : context.lang.offLabel,
                                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                  context: context,
                                  onTap: () => Get.toNamed(Routes.alarm),
                                );
                              }),
                              _settingsTile(
                                title: context.lang.language, // "Language"
                                subtitle: Get.find<LanguageController>().languages.firstWhere(
                                        (l) => l.code == Get.locale?.languageCode,
                                    orElse: () => const LanguageItem(code: 'en', name: 'English')
                                ).name,
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                context: context,
                                onTap: () => Get.to(() => const LanguageView()), // Language screen par bhejein
                              ),
                              Obx(
                                () => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: _settingsSwitch(
                                    title: context.lang.batteryWarning,
                                    subtitle: context.lang.notifyLowBattery,
                                    value: controller.batteryWarning.value,
                                    onChanged: (v) {
                                      controller.batteryWarning.value = v;
                                      controller.updateToggles(); // Call API
                                    },
                                    context: context,
                                  ),
                                ),
                              ),

                              Obx(
                                () => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: _settingsSwitch(
                                    title: context.lang.heartRateTracker,
                                    subtitle: context.lang.trackHeartRate,
                                    value: controller.heartRateTracker.value,
                                    onChanged: (v) {
                                      controller.heartRateTracker.value = v;
                                      controller.updateToggles(); // Call API
                                    },
                                    context: context,
                                  ),
                                ),
                              ),

                              SizedBox(height: 5 * SizeConfigs.paddingScale),
                            ],
                          ),
                        ),

                        SizedBox(height: 20 * SizeConfigs.paddingScale),

                        SizedBox(height: 200 * SizeConfigs.paddingScale),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      // ),
    );
  }

  Widget _settingsSwitch({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged, required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      // padding: const EdgeInsets.only(left: 20, right: 16, top: 14, bottom: 14),
      decoration: BoxDecoration(color: AppColors.white10, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13 * SizeConfigs.textScale),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.blueAccent, inactiveTrackColor: Colors.white24),
        ],
      ),
    );
  }


  Widget _buildConsecutiveDays(BuildContext context) {
    // final List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final List<String> monthNames = [
      context.lang.jan, context.lang.feb, context.lang.mar,
      context.lang.apr, context.lang.may, context.lang.jun,
      context.lang.jul, context.lang.aug, context.lang.sep,
      context.lang.oct, context.lang.nov, context.lang.dec
    ];
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            /// 1. The Background Image
            Image.asset(
              Assets.homeFeathers,
              width: 160, // Increased size so the text (50px) fits inside
              height: 130,
              color: Colors.white, // Lower opacity helps text readability
              // filterQuality: FilterQuality.none,
            ),


            Obx(
              () => Padding(
                padding: const EdgeInsets.only(bottom: 35.0),
                child: Text(
                  // 🔥 This pads the string to a width of 2, using '0' as the filler
                  controller.currentStreak.value.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(2, 2))],
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          context.lang.consecutiveDays,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Obx(() {
            // If API hasn't loaded yet, show nothing or a loader
            if (controller.streakCalendar.isEmpty) return const SizedBox();

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.streakCalendar.map((item) {
                // 1. Parse the string date
                DateTime date = DateTime.parse(item.date);

                // 2. Logic Checkers
                DateTime now = DateTime.now();
                bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                bool isCompleted = item.hasSleep;

                // 3. UI Styling
                Color circleColor = isCompleted ? Colors.blueAccent : Colors.transparent;
                Color borderColor = isCompleted ? Colors.blueAccent : (isToday ? Colors.blueAccent : Colors.white24);

                return Column(
                  children: [
                    Text(
                      "${monthNames[date.month - 1]} ${date.day}",
                      style: TextStyle(color: isToday || isCompleted ? Colors.white : Colors.white38, fontSize: 11, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // color: circleColor,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: isCompleted ? const Icon(Icons.local_fire_department, size: 18, color: Colors.orange) : null,
                    ),
                  ],
                );
              }).toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Obx(() {
        final user = controller.profile.value;
        final String imageUrl = (user?.profileImage?.isNotEmpty ?? false)
            ? user!.profileImage!
            : (user?.avatarUrl?.isNotEmpty ?? false)
            ? user!.avatarUrl!
            : '';

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'profileImageHero',
                  child: GestureDetector(
                    onTap: () {
                      if (user != null) Get.toNamed(Routes.editProfile, arguments: user);
                    },
                    child: Container(
                      width: 90 * SizeConfigs.paddingScale,
                      height: 90 * SizeConfigs.paddingScale,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                      child: ClipOval(
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: (90 * SizeConfigs.paddingScale * Get.pixelRatio).round(),
                                placeholder: (context, url) => Image.asset(Assets.homeSleepableAppIcon, fit: BoxFit.cover),
                                errorWidget: (context, url, error) => Image.asset(Assets.homeSleepableAppIcon, fit: BoxFit.cover),
                              )
                            : Image.asset(Assets.homeSleepableAppIcon, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),

                /// ✏️ Edit Icon positioned exactly on the image corner
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      if (user != null) Get.toNamed(Routes.editProfile, arguments: user);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.edit, size: 14 * SizeConfigs.textScale, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            // Expanded(
            //   child:
            //   Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            Text(
              user?.name ?? context.lang.userPlaceholder,
              style: TextStyle(fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? context.lang.noEmail,
              style: TextStyle(fontSize: 14 * SizeConfigs.textScale, color: Colors.white38),
            ),
            //   ],
            // ),
            // ),
          ],
        );

      }),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // _statItem(context, Icons.dark_mode, "Tracked\nNights", "${controller.trackedNights.value}"),
        // _statItem(context, Icons.hotel, "Avg.\nSleep Time", "${controller.avgSleepHours.value.toStringAsFixed(1)}h"),
        // _statItem(context, Icons.speed, "Avg.\nSleep Score", "${controller.avgSleepScore.value}"),
        _statItem(context, Icons.dark_mode, "${context.lang.trackedNights}\n${context.lang.trackedNights1}", "${controller.trackedNights.value}"),
        _statItem(context, Icons.hotel, "${context.lang.avgSleepTime}\n${context.lang.avgSleepTime1}", "${controller.avgSleepHours.value.toStringAsFixed(1)}h"),
        _statItem(context, Icons.speed, "${context.lang.avgSleepScore}\n${context.lang.avgSleepScore1}", "${controller.avgSleepScore.value}"),
      ],
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13 * SizeConfigs.textScale),
        ),
        //style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

}

class AnimatedSettingsButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedSettingsButton({super.key, required this.onPressed});

  @override
  State<AnimatedSettingsButton> createState() => _AnimatedSettingsButtonState();
}

class _AnimatedSettingsButtonState extends State<AnimatedSettingsButton> {
  double _scale = 1.0;
  bool _isProcessing = false; // 🔥 To prevent double-taps

  // Use a standard void here, we handle the timing in TapUp
  void _onTapDown(TapDownDetails details) {
    if (_isProcessing) return;
    Haptics.vibrate(HapticsType.light, useAndroidHapticConstants: true);
    setState(() => _scale = 0.85); // A slightly deeper shrink is easier to see
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // 🔥 1. FORCE the button to stay small for a moment
    // This ensures the eye actually sees the "press"
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      // 2. Start the pop-back animation
      setState(() => _scale = 1.0);

      // 3. Wait for the pop-back to finish
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Now navigate
      widget.onPressed();
      _isProcessing = false;
    }
  }

  void _onTapCancel() {
    if (_isProcessing) return;
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100), // Match the delays above
        curve: Curves.easeOutBack, // 👈 Adds a slight "spring" feel
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5),
                blurRadius: _scale < 1.0 ? 4 : 12, // Shadow shrinks when pressed
                offset: Offset(0, _scale < 1.0 ? 2 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                context.lang.settingsLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _settingsTile({required String title, required String subtitle, Widget? trailing, required BuildContext context, VoidCallback? onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(color: AppColors.white10, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600) ?? const TextStyle(),
            ),
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13 * SizeConfigs.textScale),
              ),
            ),
          if (trailing != null) trailing,
        ],
      ),
    ),
  );
}
