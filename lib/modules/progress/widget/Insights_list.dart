import '../../../core/utils/library.dart';
import '../../../data/services/api_sevices.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../controllers/progress_controller.dart';
import '../model/AIInsightsResponse.dart';

class InsightsList extends StatelessWidget {
  const InsightsList({super.key});

  Color _getBorderColor(int index) {
    const colors = [Color(0xFF1EA86D), Color(0xFF2F5BFF), Color(0xFFECA72C), Color(0xFFB24BF3)];
    return colors[index % colors.length];
  }

  IconData _getIcon(int index) {
    const icons = [Icons.trending_up_rounded, Icons.trending_down_rounded, Icons.nights_stay, Icons.schedule_rounded];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProgressController>();
    final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

    return Obx(() {
      if (controller.isAIInsightsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Colors.white24));
      }

      if (controller.aiInsightsList.isEmpty) {
        final tab = controller.selectedTab.value;
        final emptyMsg = (subController.isPremium.value == false)
            ? context.lang.proInsightsPrompt
            : (tab == context.lang.week)
                ? context.lang.noInsightsWeek
                : (tab == context.lang.month)
                    ? context.lang.noInsightsMonth
                    : context.lang.noInsightsToday;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              emptyMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.only(top: 12 * SizeConfigs.paddingScale),
        shrinkWrap: true, // Let the parent container control height
        physics: const BouncingScrollPhysics(),
        itemCount: controller.aiInsightsList.length,
        itemBuilder: (context, index) {
          final item = controller.aiInsightsList[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12 * SizeConfigs.paddingScale, right: 12 * SizeConfigs.paddingScale),
            child: _buildInsightCard(
              context,
              title: item.title,
              description: item.summary,
              borderColor: _getBorderColor(index),
              icon: _getIcon(index),
            ),
          );
        },
      );
    });
  }

  Widget _buildInsightCard(BuildContext context,
      {required String title, required String description, required Color borderColor, required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(12 * SizeConfigs.paddingScale),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        color: const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 24 * SizeConfigs.textScale),
          SizedBox(width: 12 * SizeConfigs.paddingScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(color: Colors.white70, fontSize: 12 * SizeConfigs.textScale, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
