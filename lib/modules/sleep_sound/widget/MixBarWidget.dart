import 'dart:ui';

import 'package:sleepable_ai/modules/sleep_sound/controllers/sleep_sound_controller.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/utils/library.dart';
import '../views/sleep_sound_view.dart';
import 'PlayerFullSheetUI.dart';

class MixBarWidget extends StatelessWidget {
  final bool isFromHome;
  final bool isFromsleepTracker;
  final SleepSoundController controller = Get.find<SleepSoundController>();

  MixBarWidget({super.key, this.isFromHome = false, this.isFromsleepTracker = false});


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. Logic remains the same
      final bool hasSounds = controller.playingSounds.isNotEmpty;
      final bool hasMusic = controller.playingMusic.isNotEmpty;
      final bool shouldShow = hasSounds || hasMusic;

      final combinedText = [...controller.playingSounds, ...controller.playingMusic].map((e) => e.name).join(", ");
      int dynamicMillis = (combinedText.length * 50).clamp(2000, 8000);

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Slide Up for entering, Slide Down for exiting
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        // 3. THIS IS THE FIX: The child MUST handle the 'empty' state with a Key
        child: shouldShow
            ? (isFromHome
            ? MusicGlowButton(
            key: const ValueKey('glowButton_visible'), // Unique key
            onPlayPause: () => controller.togglePause(),
            onClose: () => controller.fadeOutAndStopAll()
        )
            : _buildFullBar(context, combinedText, dynamicMillis))
            : const SizedBox(
            key: ValueKey('mixBar_empty'), // CRITICAL for the switcher
            width: 0,
            height: 0
        ),
      );
    });
  }
  Widget _buildFullBar(BuildContext context, String text, int millis) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            key: const ValueKey('mixBar_visible'),
            width: double.infinity,
            // margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              // Use a very light white or grey with low opacity
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.2), // The "shine" on the edge
                // width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 🔥 PLAY/PAUSE ICON (Decoupled Obx for speed)
                Obx(
                  () => GestureDetector(
                    onTap: () => controller.togglePause(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF3A7CFF), shape: BoxShape.circle),
                      child: Icon(controller.isPaused.value ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // TEXT / TAP AREA
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleNavigation(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(
                                                            "Mix",
                                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 13 * SizeConfigs.textScale),
                                                          ),
                                                          const SizedBox(height: 3),
                                                          Marquee(
                                                            animationDuration: Duration(milliseconds: millis),
                                                            backDuration: const Duration(milliseconds: 3500),
                                                            pauseDuration: const Duration(milliseconds: 500),
                                                            // animationDuration: const Duration(milliseconds: 3000),
                                                            child: Text(
                                                              text,
                                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 10 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                                            ),
                                                          ),
                      ],
                    ),
                  ),
                ),

                // CLOSE BUTTON
                GestureDetector(
                  onTap: () => controller.fadeOutAndStopAll(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: Colors.white70, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context) {
    if (controller.playingMusic.isNotEmpty && controller.playingSounds.isEmpty) {
      Get.bottomSheet(PlayerFullSheetUI(sound: controller.playingMusic.first), isScrollControlled: true,ignoreSafeArea: false);
    } else {
      controller.openBottomSheet(context);
    }
  }
}

class MusicGlowButton extends StatefulWidget {
  final VoidCallback onPlayPause;
  final Future<void> Function() onClose;

  const MusicGlowButton({super.key, required this.onPlayPause, required this.onClose});

  @override
  State<MusicGlowButton> createState() => _MusicGlowButtonState();
}

class _MusicGlowButtonState extends State<MusicGlowButton> {
  double scale = 1.0;
  final SleepSoundController controller = Get.find<SleepSoundController>();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => scale = 0.90),
      onPointerUp: (_) => setState(() => scale = 1.0),

      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,

        child: GestureDetector(
          onLongPress: () {
            controller.isClosingMode.value = true; // show red X
          },

          onTap: () async {
            if (controller.isClosingMode.value) {
              await controller.fadeOutAndStopAll();
              await controller.clearAllMusic();
              controller.isBottomSheetOpen.value = false;
            }
            if (controller.isClosingMode.value) {
              await widget.onClose();
              controller.isClosingMode.value = false;
            } else {
              widget.onPlayPause();
            }
          },

          child: Obx(() {
            final bool showClose = controller.isClosingMode.value;

            // ANYTHING PLAYING?
            final bool isPlayingAnything = controller.playingSounds.isNotEmpty || controller.playingMusic.isNotEmpty;

            // For pause icon
            print("--------isPaused-------4 ${controller.isPaused.value}");
            final bool isPaused = controller.isPaused.value;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xffad03e2), Color(0xffffaf2c)]),
                boxShadow: [
                  // LEFT half shadow
                  BoxShadow(
                    color: Color(0xffad03e2).withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 4,
                    offset: const Offset(-5, 0), // push left
                  ),

                  // RIGHT half shadow
                  BoxShadow(
                    color: Color(0xffffaf2c).withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(5, 0), // push right
                  ),
                ],
              ),

              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),

                  child:
                      // ❌ show close icon
                      showClose
                      ? Icon(Icons.close, color: Colors.white, size: 34, key: ValueKey("CLOSE"))
                      // ⏸ Play/Pause icon if ANYTHING is playing
                      : isPlayingAnything && !isPaused
                      ? Icon(Icons.pause_rounded, color: Colors.white, size: 38, key: ValueKey("PAUSE"))
                      // ▶️ Resume if paused
                      : isPlayingAnything && isPaused
                      ? Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38, key: ValueKey("PLAY"))
                      // 🖼 Default image thumbnail
                      : ClipRRect(
                          key: const ValueKey("THUMB"),
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            "https://img.freepik.com/premium-vector/colorful-musical-note-art-with-vibrant-splashes-musical-note-black-surrounded_53876-651215.jpg?semt=ais_hybrid&w=740&q=80",
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
