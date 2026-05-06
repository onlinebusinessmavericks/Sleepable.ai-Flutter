import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';
import '../controllers/selection_flow_controller.dart';

class SelectionListView extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;
  final RxList<String> selectedItems;
  final void Function(String) onToggle;
  final VoidCallback onContinue;
  final bool isMultiSelect;
  final double progress;
  final double currentStep;
  final double totalSteps;


  const SelectionListView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
    required this.onContinue,
    this.isMultiSelect = false,
    this.progress = 0.1,
    this.currentStep=1,
    this.totalSteps=11
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectionFlowController = Get.find<SelectionFlowController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Top bar with back button & progress
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 230, // fixed small width
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth * progress.clamp(0.0, 1.0);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: width,
                                decoration: BoxDecoration(
                                  color: AppColors.iconColor,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )


                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Title with bottom→top fade animation
              AnimatedTitle(
                title: title,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ).paddingAll(15),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Animated list
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Obx(() {
                      final isSelected = selectedItems.contains(item['title']);

                      return TweenAnimationBuilder<Offset>(
                        tween: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: const Offset(0, 0),
                        ),
                        duration: Duration(milliseconds: 400 + (index * 300)),
                        curve: Curves.easeOut,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: Offset(offset.dx * 200, 0),
                            child: Opacity(
                              opacity: 1 - offset.dx.abs(),
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!isMultiSelect) selectedItems.clear();
                            onToggle(item['title']);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cardColor
                                  : AppColors.cardColor,
                              //Colors.blue.shade900.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderColor,
                                //: Colors.transparent,
                                width: 1.8,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item['emoji'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item['title'],
                                  style: textTheme.titleLarge?.copyWith(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: onContinue,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blueAccent,
              //     minimumSize: const Size(double.infinity, 50),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   child: const Text("Continue", style: AppStyles.button),
              // ),
              Obx(() => GestureDetector(
                // Trigger shrink on touch down
                onTapDown: (_) => selectionFlowController.buttonScale.value = 0.94,
                // Reset on release or cancel
                onTapUp: (_) => selectionFlowController.buttonScale.value = 1.0,
                onTapCancel: () => selectionFlowController.buttonScale.value = 1.0,
                child: AnimatedScale(
                  scale: selectionFlowController.buttonScale.value,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  child: ElevatedButton(
                    // onPressed: () async{
                    //   // Optional: add haptics for that "filled" physical feel
                    //   Haptics.vibrate(HapticsType.selection);
                    //   await Future.delayed(const Duration(milliseconds: 50));
                    //   onContinue();
                    // },
                    onPressed: () async {
                      // 1. Trigger a "Medium Impact" (feels like a physical button click)
                      await Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true,);

                      onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Removes the default gray overlay so the scale is the star
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text("Continue", style: AppStyles.button),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// AnimatedTitle widget
class AnimatedTitle extends StatefulWidget {
  final String title;
  final TextStyle? style;

  const AnimatedTitle({super.key, required this.title, this.style});

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Text(
          widget.title,
          style: widget.style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
