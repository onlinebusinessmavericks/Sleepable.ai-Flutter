import 'package:haptic_feedback/haptic_feedback.dart';

import '../core/utils/library.dart';

class AnimatedNextButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration delay;

  const AnimatedNextButton({
    super.key,
    required this.onPressed,
    this.delay = const Duration(seconds: 2),
  });

  @override
  State<AnimatedNextButton> createState() => _AnimatedNextButtonState();
}

class _AnimatedNextButtonState extends State<AnimatedNextButton>
    with TickerProviderStateMixin {

  // 🔹 Entrance animation
  late final AnimationController _entryController =
  AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _entryScale =
  Tween(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack, // 👈 POP effect
    ),
  );

  // 🔹 Press animation (your existing logic)
  late final AnimationController _pressController =
  AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  late final Animation<double> _pressScale =
  Tween(begin: 1.0, end: 0.92).animate(
    CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ),
  );

  bool _visible = false;

  @override
  void initState() {
    super.initState();

    // ⏱ Delay show
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox(
        width: 52,
        height: 52,
      );
    }

    return ScaleTransition(
      scale: _entryScale,
      child: ScaleTransition(
        scale: _pressScale,
        child: SizedBox(
          width: 52,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              await Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true);
              await _pressController.forward();
              await _pressController.reverse();
              widget.onPressed();
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.blue,
              elevation: 6,
              padding: EdgeInsets.zero,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
