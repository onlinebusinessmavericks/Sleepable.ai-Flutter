
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/library.dart';
import '../../../routes/app_pages.dart';
import '../controllers/sleep_quiz_result_controller.dart';

class SleepQuizResultView extends GetView<SleepQuizResultController> {
  const SleepQuizResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate to dashboard if user tries to swipe back
        Get.offAllNamed(Routes.dashboard);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Results",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 21 * SizeConfigs.textScale,
                fontWeight: FontWeight.w500
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.redoQuiz,
              child: const Text("Redo", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            final data = controller.result.value;

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 40), // Reduced bottom padding since button is fixed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 Disorder
                  Text("Disorder", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    data.disorder,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 24),

                  /// 🔹 Result Details
                  Text("Result Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),

                  const SizedBox(height: 12),
                  Text(data.resultDetails, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15)),

                  const SizedBox(height: 26),

                  /// 🔹 Suggestions
                  Text("Suggestions", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),

                  const SizedBox(height: 14),
                  ...data.suggestions.map(
                        (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s, style: const TextStyle(color: Colors.white70, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        /// 🔵 Fixed Bottom CTA Button
        /// 🔵 Fixed Bottom CTA Button (Now with Bounce Animation!)
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: AnimatedBounceButton(
              onTap: () {
                // Direct navigation back to the Dashboard/Home
                Get.offAllNamed(Routes.dashboard);
              },
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66FF), // Your accent color
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A66FF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const AnimatedBounceButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.95, // How much it shrinks (0.95 = 95% of original size)
  });

  @override
  State<AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<AnimatedBounceButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = widget.scaleFactor);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    // Add a tiny delay so the user sees the button pop back up before navigating
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap();
    });
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}