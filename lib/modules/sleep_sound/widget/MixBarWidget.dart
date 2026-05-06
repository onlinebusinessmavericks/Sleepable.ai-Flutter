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

  //   @override
  //   Widget build(BuildContext context) {
  //     return Obx(() {
  //       // 🔹 Debug basic controller state
  //       print("--------- MIXBAR BUILD ---------");
  //       print("Controller hash: ${controller.hashCode}");
  //       print("playingSounds count: ${controller.playingSounds.length}");
  //       print("playingSounds: ${controller.playingSounds.map((s) => s.name).toList()}");
  //       print("playingMusic count: ${controller.playingMusic.length}");
  //       print("playingMusicLocale: ${controller.playingMusicLocale.toList()}");
  //       print("isPaused: ${controller.isPaused.value}");
  //       print("remaining timer: ${controller.remaining.value.inSeconds}");
  //       print("sleepTimerDuration: ${controller.sleepTimerDuration.value.inSeconds}");
  //       final hasMusicOnly = controller.playingMusic.isNotEmpty && controller.playingSounds.isEmpty;
  //
  //       final hasMixPlaying = controller.playingSounds.isNotEmpty || (controller.playingMusic.isNotEmpty && controller.playingSounds.isNotEmpty);
  //
  //       final shouldShow = controller.playingSounds.isNotEmpty || controller.playingMusic.isNotEmpty;//||
  //           //controller.isMusicPlaying.value;
  //
  //       // Combine all currently playing sounds/music
  //       final combinedText = [...controller.playingSounds, ...controller.playingMusic].map((e) => e.name).join(", ");
  //       print("-------------cobinedtext-------$combinedText");
  //       final hasAnythingPlaying = controller.playingSounds.isNotEmpty || controller.playingMusic.isNotEmpty;
  //
  //       final switcherKey = const ValueKey('mixBar_visible');
  //
  //       print("AnimatedSwitcher key: $switcherKey");
  //       int dynamicMillis = combinedText.length * 50;
  //
  // // 2. Clamp the values so it doesn't get ridiculously fast or slow
  //       dynamicMillis = dynamicMillis.clamp(2000, 8000);
  //
  //       return AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 350),
  //         switchInCurve: Curves.easeOut,
  //         switchOutCurve: Curves.easeIn,
  //         layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
  //           return Stack(alignment: Alignment.center, children: <Widget>[...previousChildren, if (currentChild != null) currentChild]);
  //         },
  //         transitionBuilder: (Widget child, Animation<double> animation) {
  //           final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut)).animate(animation);
  //           return SlideTransition(
  //             position: offsetAnim,
  //             child: FadeTransition(opacity: animation, child: child),
  //           );
  //         },
  //         child: shouldShow
  //             ? isFromHome
  //                   // 🔥 HOME → GLOW BUTTON
  //                   ? MusicGlowButton(
  //                       onPlayPause: () {
  //                         print("in MusicGlowButton onPlayPause");
  //                         controller.togglePause();
  //                       },
  //                       onClose: () async {
  //                         print("in MusicGlowButton onClose");
  //                         await controller.fadeOutAndStopAll();
  //                       },
  //                     )
  //                   // 🔹 OTHER SCREENS → FULL MIX BAR
  //                   : SizedBox(
  //                       width: MediaQuery.of(context).size.width,
  //                       child: Container(
  //                         // key: switcherKey,
  //                         key: const ValueKey('mixBar_visible'),
  //                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                         margin: const EdgeInsets.symmetric(horizontal: 12),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey.withOpacity(0.4),
  //                           borderRadius: BorderRadius.circular(50),
  //                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             Obx(() {
  //                               final paused = controller.isPaused.value;
  //
  //                               return GestureDetector(
  //                                 onTap: ()  { // Add async keyword
  //                                   debugPrint("🖱️ Play/Pause tapped UI");
  //                                    controller.togglePause(); // Await the toggle
  //                                 },
  //
  //                                 child: Container(
  //                                   width: 50,
  //                                   height: 50,
  //                                   decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
  //                                   child: Icon(paused ? Icons.play_arrow_rounded : Icons.pause, color: Colors.white),
  //                                 ),
  //                               );
  //                             }),
  //
  //                             const SizedBox(width: 12),
  //
  //                             // 📝 Mix Text
  //                             // Expanded(
  //                             //   child: GestureDetector(
  //                             //     behavior: HitTestBehavior.opaque,
  //                             //     onTap: () {
  //                             //       final hasSound = controller.playingSounds.isNotEmpty;
  //                             //       final hasMusic = controller.playingMusic.isNotEmpty;
  //                             //       if (isFromsleepTracker) {
  //                             //         Get.to(() => SleepSoundView(fromMixBar: true), arguments: {"jumpTab": "white-noise", "jumpFilter": "__all__"});
  //                             //       }
  //                             //
  //                             //       // 🔹 if sound playing (with or without music) → open mix bottom sheet
  //                             //       if (hasSound) {
  //                             //         controller.openBottomSheet(context);
  //                             //         return;
  //                             //       }
  //                             //
  //                             //       // 🔹 only music → open full player sheet
  //                             //       if (hasMusic) {
  //                             //         Get.bottomSheet(PlayerFullSheetUI(sound: controller.playingMusic.first), isScrollControlled: true, ignoreSafeArea: false, backgroundColor: Colors.transparent);
  //                             //         return;
  //                             //       }
  //                             //
  //                             //       // 🔹 nothing playing → no action (optional)
  //                             //     },
  //                             Expanded(
  //                               child: GestureDetector(
  //                                 behavior: HitTestBehavior.opaque,
  //                                 onTap: () {
  //                                   final hasMusic = controller.playingMusic.isNotEmpty;
  //                                   final hasSound = controller.playingSounds.isNotEmpty;
  //
  //                                   // Identify if Story is active
  //                                   bool isStory = hasMusic &&
  //                                       controller.playingMusic.first.categoryName.toLowerCase() == "story";
  //
  //                                   if (isStory || hasMusic && !hasSound) {
  //                                     // Open Full Player for Story or Music-only
  //                                     if (!controller.isAnyPlayerVisible.value) {
  //                                       controller.isAnyPlayerVisible.value = true;
  //                                       Get.bottomSheet(
  //                                         PlayerFullSheetUI(sound: controller.playingMusic.first),
  //                                         isScrollControlled: true,
  //                                         ignoreSafeArea: false,
  //                                         backgroundColor: Colors.transparent,
  //                                       ).whenComplete(() => controller.isAnyPlayerVisible.value = false);
  //                                     }
  //                                   } else if (hasSound) {
  //                                     // Open Mix Editor for ambient sounds
  //                                     controller.openBottomSheet(context);
  //                                   }
  //                                 },
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       "Mix",
  //                                       style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 13 * SizeConfigs.textScale),
  //                                     ),
  //                                     const SizedBox(height: 3),
  //                                     Marquee(
  //                                       animationDuration: Duration(milliseconds: dynamicMillis),
  //                                       backDuration: const Duration(milliseconds: 3500),
  //                                       pauseDuration: const Duration(milliseconds: 500),
  //                                       // animationDuration: const Duration(milliseconds: 3000),
  //                                       child: Text(
  //                                         combinedText,
  //                                         style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 10 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //
  //                             const SizedBox(width: 12),
  //
  //                             // ⏱ Timer
  //                             Obx(() {
  //                               final timerText = controller.sleepTimerDuration.value.inSeconds > 0
  //                                   ? "${controller.sleepTimerDuration.value.inMinutes.toString().padLeft(2, '0')}:${(controller.sleepTimerDuration.value.inSeconds % 60).toString().padLeft(2, '0')}"
  //                                   : controller.remaining.value.inSeconds > 0
  //                                   ? "${controller.remaining.value.inMinutes.toString().padLeft(2, '0')}:${(controller.remaining.value.inSeconds % 60).toString().padLeft(2, '0')}"
  //                                   : null;
  //
  //                               return timerText != null
  //                                   ? Container(
  //                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                                       decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
  //                                       child: Text(timerText, style: const TextStyle(color: Colors.white, fontSize: 12)),
  //                                     )
  //                                   : const SizedBox.shrink();
  //                             }),
  //
  //                             const SizedBox(width: 8),
  //
  //                             const Icon(Icons.queue_music, color: Colors.white, size: 30),
  //
  //                             // ❌ Close
  //                             GestureDetector(
  //                               onTap: () async {
  //                                 // controller.clearAllSounds();
  //                                 await controller.fadeOutAndStopAll();
  //                               },
  //                               child: const Icon(Icons.close, color: Colors.white, size: 30),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     )
  //             : const SizedBox(key: ValueKey('mixBar_empty'), height: 0, width: 0),
  //       );
  //     });
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Obx(() {
  //     // Visibility Logic
  //     final bool hasSounds = controller.playingSounds.isNotEmpty;
  //     final bool hasMusic = controller.playingMusic.isNotEmpty;
  //     final bool shouldShow = hasSounds || hasMusic;
  //
  //     if (!shouldShow) return const SizedBox(key: ValueKey('mixBar_empty'));
  //
  //     // Text Logic
  //     final combinedText = [...controller.playingSounds, ...controller.playingMusic].map((e) => e.name).join(", ");
  //     int dynamicMillis = (combinedText.length * 50).clamp(2000, 8000);
  //
  //     return AnimatedSwitcher(
  //       duration: const Duration(milliseconds: 350),
  //       transitionBuilder: (Widget child, Animation<double> animation) {
  //         return FadeTransition(
  //           opacity: animation,
  //           child: ScaleTransition(scale: animation, child: child),
  //         );
  //       },
  //       child: isFromHome ? MusicGlowButton(onPlayPause: () => controller.togglePause(), onClose: () => controller.fadeOutAndStopAll()) : _buildFullBar(context, combinedText, dynamicMillis),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. Logic remains the same
      final bool hasSounds = controller.playingSounds.isNotEmpty;
      final bool hasMusic = controller.playingMusic.isNotEmpty;
      final bool shouldShow = hasSounds || hasMusic;

      final combinedText = [...controller.playingSounds, ...controller.playingMusic].map((e) => e.name).join(", ");
      int dynamicMillis = (combinedText.length * 50).clamp(2000, 8000);

      // 2. DO NOT return early here. Let AnimatedSwitcher handle it.
      // return AnimatedSwitcher(
        //         duration: const Duration(milliseconds: 350),
        //         switchInCurve: Curves.easeOut,
        //         switchOutCurve: Curves.easeIn,
        //         layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        //           return Stack(alignment: Alignment.center, children: <Widget>[...previousChildren, if (currentChild != null) currentChild]);
        //         },
        //         transitionBuilder: (Widget child, Animation<double> animation) {
        //           final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut)).animate(animation);
        //           return SlideTransition(
        //             position: offsetAnim,
        //             child: FadeTransition(opacity: animation, child: child),
        //           );
        //         },
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
            // decoration: BoxDecoration(
            //   color: Colors.grey.withOpacity(0.7),
            //   borderRadius: BorderRadius.circular(50),
            //   // backdropFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Adds premium feel
            // ),
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
                        // const Text("Currently Playing", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        // Marquee(
                        //   animationDuration: Duration(milliseconds: millis),
                        //   child: Text(
                        //     text,
                        //     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        //   ),
                        // ),
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
