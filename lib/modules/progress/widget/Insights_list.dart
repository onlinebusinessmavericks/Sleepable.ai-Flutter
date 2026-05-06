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

      // if (controller.aiInsightsList.isEmpty) {
      //   return const Center(child: Text("No insights found", style: TextStyle(color: Colors.white54)));
      // }
      if (controller.aiInsightsList.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              // Agar user premium nathi, to upgrade mate no message
              (subController.isPremium.value == false)
                  ? context.lang.proInsightsPrompt
                  : context.lang.noInsightsToday,
                  // ? "No insights found. Get personalized AI sleep insights with Sleepable Premium ✨"
                  // : "No insights found for today.",
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
// class _InsightsListState extends State<InsightsList> {
//   final ScrollController _scrollController = ScrollController();
//   late Future<AIInsightsResponse> _insightsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize the API call
//     _insightsFuture = ProgressApis.getAIInsights(dataType: type, date: date);
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   // Helper to pick a color based on index so the UI stays colorful
//   Color _getBorderColor(int index) {
//     List<Color> colors = [
//       const Color(0xFF1EA86D),
//       const Color(0xFF2F5BFF),
//       const Color(0xFFECA72C),
//       const Color(0xFFB24BF3),
//     ];
//     return colors[index % colors.length];
//   }
//
//   // Helper to pick an icon based on index or title keywords
//   IconData _getIcon(int index) {
//     List<IconData> icons = [
//       Icons.trending_up_rounded,
//       Icons.trending_down_rounded,
//       Icons.nights_stay,
//       Icons.schedule_rounded,
//     ];
//     return icons[index % icons.length];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<AIInsightsResponse>(
//       future: _insightsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Colors.white24));
//         } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.success) {
//           return const Center(child: Text("No insights available", style: TextStyle(color: Colors.white54)));
//         }
//
//         // Access the nested insights list
//         final insights = snapshot.data?.data?.insights ?? [];
//
//         if (insights.isEmpty) {
//           return const Center(child: Text("No insights found", style: TextStyle(color: Colors.white54)));
//         }
//
//         return LayoutBuilder(
//           builder: (context, constraints) {
//             return Scrollbar(
//               controller: _scrollController,
//               thumbVisibility: true,
//               thickness: 4,
//               radius: const Radius.circular(8),
//               interactive: true,
//               child: SingleChildScrollView(
//                 controller: _scrollController,
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                       right: 12 * SizeConfigs.paddingScale,
//                       top: 12 * SizeConfigs.paddingScale,
//                       bottom: 12 * SizeConfigs.paddingScale,
//                     ),
//                     child: Column(
//                       children: List.generate(insights.length, (index) {
//                         final item = insights[index];
//                         return Padding(
//                           padding: EdgeInsets.only(bottom: 12 * SizeConfigs.paddingScale),
//                           child: _buildInsightCard1(
//                             context,
//                             title: item.title,
//                             description: item.summary,
//                             borderColor: _getBorderColor(index),
//                             icon: _getIcon(index),
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//   Widget _buildInsightCard1(BuildContext context,
//       {required String title, required String description, required Color borderColor, required IconData icon}) {
//     return Container(
//       padding: EdgeInsets.all(12 * SizeConfigs.paddingScale),
//       decoration: BoxDecoration(
//         border: Border(left: BorderSide(color: borderColor, width: 4)),
//         color: const Color(0xFF161B27),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: borderColor, size: 24 * SizeConfigs.textScale),
//           SizedBox(width: 12 * SizeConfigs.paddingScale),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 2),
//                 Text(
//                   title,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   description,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: Colors.white70, fontSize: 12 * SizeConfigs.textScale),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
