import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../localization/lang_extension.dart';
import '../../../localization/language_controller.dart';
import '../../music/views/music_view.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

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
            context.lang.language,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 21 * SizeConfigs.textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.languages.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = controller.languages[index];

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              controller.changeLanguage(item.code);
              // Get.back();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final isSelected =
                          controller.locale.value.languageCode == item.code;

                      return Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                          isSelected ? Colors.white : Colors.white54,
                          fontSize: 16 * SizeConfigs.textScale,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      );
                    }),
                  ),

                  /// ✅ Check icon reactive
                  Obx(() {
                    final isSelected =
                        controller.locale.value.languageCode == item.code;

                    return isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          );
        },
      ),


    );
  }
}
