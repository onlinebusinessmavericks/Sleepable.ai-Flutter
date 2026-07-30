import 'package:sleepable_ai/core/utils/library.dart';

import '../../../localization/lang_extension.dart';
import '../../../widgets/ai_consent_dialog.dart';
import '../../music/views/music_view.dart';
import '../controllers/settings_controller.dart';
import '../model/user_settings_model.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 22.0),
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0), // 👈 title padding
          child: Text(
              context.lang.settings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 21 * SizeConfigs.textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20 * SizeConfigs.paddingScale,
          vertical: 10 * SizeConfigs.paddingScale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSectionTitle(context, "Share"),
            // _buildTile(context, "Share Sleepable.ai", Icons.share_outlined, controller.onShareApp),
            const SizedBox(height: 20),
            _buildSectionTitle(context, context.lang.support),
            _buildGroupContainer(context, [
              // _buildGroupItem(context, "Like us, Rate us", controller.onRateUs),
              _buildGroupItem(context,context.lang.emailSupport, controller.onEmailSupport),
              // _buildGroupItem(context, "Restore Purchases", controller.onRestorePurchases),
              _buildGroupItem(context, aiDataSettingsLabel(), () => controller.onAiDataSharing(context)),
              // Apple Guideline 3.1.1: subscribers must be able to restore purchases.
              _buildGroupItem(context, "Restore Purchases", controller.onRestorePurchases),
              _buildGroupItem(context, context.lang.privacyPolicy, controller.onPrivacyPolicy),
              _buildGroupItem(context, context.lang.termsOfService, controller.onTermsOfService),
              // _buildGroupItem(context, "Community Guidelines", controller.onCommunityGuidelines),
            ]),
            const SizedBox(height: 20),

          const SizedBox(height: 20),

          _buildSectionTitle(context, context.lang.account),
          _buildGroupContainer(context, [
            _buildGroupItem(
              context,
              context.lang.logOut,
              // controller.logout,
                  () =>  controller.showLogoutDialog(context),
              icon: Icons.logout,
              isDestructive: true,
            ),
            _buildGroupItem(
              context,
            context.lang.deleteAccount,
                  () => controller.showDeleteAccountDialog(context),
              icon: Icons.delete_outline,
              isDestructive: true,
            ),
          ]),
        ],
      ),
    ));
  }
  Widget _buildSwitchItem(
      BuildContext context, {
        required String title,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.backgroundColor, width: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 14 * SizeConfigs.textScale,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }


  // 🔹 Section Title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * SizeConfigs.paddingScale),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white54,
          fontSize: 14 * SizeConfigs.textScale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 🔹 Single Tile
  Widget _buildTile(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
            padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 16),
            decoration: BoxDecoration(color:  AppColors.white10, borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDestructive ? Colors.redAccent : AppColors.white,
                    fontSize: 14 * SizeConfigs.textScale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white, size: 20 * SizeConfigs.textScale),
              ],
            )));

  }



  Widget _buildGroupContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color:AppColors.white10,// const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildGroupItem(
      BuildContext context,
      String title,
      VoidCallback onTap, {
        IconData? icon,                // 👈 optional icon
        bool isDestructive = false,    // 👈 optional style flag
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 16),
        decoration: const BoxDecoration(
          border: Border(

            bottom: BorderSide(color: AppColors.backgroundColor, width: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 👇 show icon only if provided

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDestructive ? Colors.redAccent : AppColors.white,
                fontSize: 14 * SizeConfigs.textScale,
              ),
            ),

            if (icon != null) ...[
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : Colors.white,
                size: 20 * SizeConfigs.textScale,
              ),
            ],
          ],
        ),
      ),
    );
  }

}
