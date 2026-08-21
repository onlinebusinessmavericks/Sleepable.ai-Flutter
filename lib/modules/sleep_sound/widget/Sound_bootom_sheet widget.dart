import 'package:giffy_dialog/giffy_dialog.dart';

import '../../../core/utils/library.dart';
import '../controllers/sleep_sound_controller.dart';
import '../views/sleep_sound_view.dart';

class BlueCenterThumbShape extends SliderComponentShape {
  const BlueCenterThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer white circle
    final Paint outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Inner blue dot
    final Paint innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw outer white circle
    canvas.drawCircle(center, 9, outerPaint);

    // Draw inner blue dot (smaller)
    canvas.drawCircle(center, 4, innerPaint);
  }
}

class AnimatedBottomSheetContent extends StatefulWidget {
  @override
  State<AnimatedBottomSheetContent> createState() => AnimatedBottomSheetContentState();
}

class AnimatedBottomSheetContentState extends State<AnimatedBottomSheetContent> {
  // final controller = Get.put(SleepSoundController());
  final controller = Get.find<SleepSoundController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────── FIXED HEADER ───────────
          Obx(
            () => Row(
              children: [
                controller.playingSounds.toList().isEmpty
                    ? SizedBox()
                    : GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 38),
                      ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    Get.back();
                    controller.fadeOutAndStopAll();
                  },
                  child: Text(
                    "Clear All",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueAccent, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
                  ).paddingOnly(right: 5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─────────── SCROLLABLE BODY ───────────
          Expanded(
            child: SingleChildScrollView(
              // physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Obx(() {
                      final filteredSounds = controller.playingSounds;
                      final total = filteredSounds.length;
                      const maxSounds = 10;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(Assets.homeSoundWaves1, color: AppColors.white, width: 20, height: 20),
                              const SizedBox(width: 5),
                              Text(
                                "Sounds ($total/$maxSounds)",
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (filteredSounds.isEmpty) ...[
                            const Text("There is no sound in this mix", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Get.back();
                                print("jumpto white-noise");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text("Add Sound", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Obx(() {
                              return Column(
                                children: controller.playingSounds.map((sound) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        /// ICON
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Colors.white10,
                                          child: ClipOval(
                                            child: sound.image != null && sound.image!.isNotEmpty
                                                ? Image.network(
                                                    sound.image!,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) {
                                                      return const Text('🎵', style: TextStyle(fontSize: 22));
                                                    },
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                                    },
                                                  )
                                                : const Text('🎵', style: TextStyle(fontSize: 22)),
                                          ),
                                        ),

                                        /// NAME + SLIDER
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 18),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                /// ✅ SOUND NAME (THIS WAS MISSING)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                                                  child: Text(
                                                    sound.name,
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                                  ),
                                                ),

                                                /// ✅ REACTIVE SLIDER
                                                SliderTheme(
                                                  data: SliderThemeData(trackHeight: 3, overlayShape: SliderComponentShape.noOverlay, thumbShape: const BlueCenterThumbShape()),
                                                  child: Obx(() {
                                                    return Slider(
                                                      activeColor: Colors.blue,
                                                      inactiveColor: Colors.white24,
                                                      min: 0,
                                                      max: 1,
                                                      divisions: 100,
                                                      value: controller.soundVolumes[sound.id] ?? 0.5,
                                                      onChanged: (val) async {
                                                        controller.soundVolumes[sound.id] = val;
                                                        controller.soundVolumes.refresh();

                                                        final player = controller.soundPlayers[sound.id];
                                                        if (player != null) {
                                                          await player.setVolume(val);
                                                        }
                                                      },
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        /// DELETE BUTTON
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 20),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline_outlined, color: Colors.white70, size: 28),
                                            onPressed: () async {
                                              final player = controller.soundPlayers[sound.id];
                                              if (player != null) {
                                                await player.stop();
                                                await player.dispose();
                                                controller.soundPlayers.remove(sound.id);
                                              }

                                              controller.playingSounds.remove(sound);
                                              controller.soundVolumes.remove(sound.id);
                                              controller.playingSounds.refresh();
                                              controller.soundVolumes.refresh();

                                              if (controller.playingSounds.isEmpty && controller.playingMusic.isEmpty) {
                                                controller.resetTimer(0);
                                                controller.isBottomSheetOpen.value = false;
                                                await controller.fadeOutAndStopAll();
                                                Get.back();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, thickness: 1),
                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Obx(() {
                      final totalMusic = controller.playingMusic.length;
                      const maxMusic = 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Header
                          Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.white70, size: 18),

                              //Image.asset(Assets.homeSoundWaves, color: AppColors.white,fit: BoxFit.cover, width: 20, height: 20),
                              const SizedBox(width: 5),
                              Text(
                                "Music ($totalMusic/$maxMusic)",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 🔹 If no music added
                          if (controller.playingMusic.isEmpty) ...[
                            Text(
                              "There is no music in this mix",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Get.back();
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  controller.navigateToAddMusic();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Add Music",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Column(
                              children: controller.playingMusic.map((music) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 🔹 Album / Icon
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.white10,
                                        backgroundImage: music.image.isNotEmpty ? NetworkImage(music.image) : null,
                                        child: music.image.isEmpty ? const Icon(Icons.music_note, color: Colors.white) : null,
                                      ),

                                      // 🔹 Name + Volume slider
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(left: 12, bottom: 8),
                                                child: Text(
                                                  music.name,
                                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),

                                              SliderTheme(
                                                data: SliderThemeData(trackHeight: 3, thumbShape: const BlueCenterThumbShape(), overlayShape: SliderComponentShape.noOverlay),
                                                child: Slider(
                                                  activeColor: Colors.blueAccent,
                                                  inactiveColor: Colors.white24,
                                                  value: controller.musicVolumes[music.id] ?? 0.5,
                                                  onChanged: (val) async {
                                                    controller.musicVolumes[music.id] = val;
                                                    controller.musicVolumes.refresh();
                                                    await controller.musicPlayer.setVolume(val);
                                                    // final player = controller._soundPlayers[music.id];
                                                    // if (player != null) {
                                                    //   await player.setVolume(val);
                                                    // }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 🔹 Delete
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_outlined, color: Colors.white70, size: 28),
                                        onPressed: () async {
                                          await controller.stopMusic();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, thickness: 1),
                  const SizedBox(height: 18),

                  // Bottom buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TimerCircle(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: controller.togglePause,
                            child: Obx(() {
                              final hasAudio = controller.playingSounds.isNotEmpty || controller.playingMusic.isNotEmpty;

                              final isPlaying = hasAudio && !controller.isPaused.value;
                              print("--------isPaused-------${controller.isPaused.value}");
                              print("--------isPlaying-------$isPlaying");
                              return Container(
                                width: 74,
                                height: 74,
                                decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded, color: Colors.white, size: 50),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          const Text("", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      Obx(() {
                        // Check if current mix is already saved (local or API)
                        final alreadySaved = controller.resolvePlayingMixId() != null ||
                            controller.savedMixes.any((mix) {
                          final savedSounds = List<int>.from(mix['sounds'] ?? <int>[]);
                          final savedMusic = List<int>.from(mix['music'] ?? <int>[]);

                          final currentSoundIds = controller.playingSounds.map((e) => e.id);
                          final currentMusicIds = controller.playingMusic.map((e) => e.id);

                          return Set.from(savedSounds).containsAll(currentSoundIds) &&
                              Set.from(currentSoundIds).containsAll(savedSounds) &&
                              Set.from(savedMusic).containsAll(currentMusicIds) &&
                              Set.from(currentMusicIds).containsAll(savedMusic);
                        });

                        return GestureDetector(
                          onTap: () {
                            if (alreadySaved) {
                              showDialog(
                                context: context,
                                builder: (_) => GiffyDialog(
                                  key: const Key("RemoveMixDialog"),
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  giffy: Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.all(8),
                                    child: Center(child: Lottie.asset(Assets.lottieSleep, fit: BoxFit.contain, repeat: true)),
                                  ),
                                  title: const Text(
                                    'Remove Mix?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this mix?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.pinkAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);

                                        final mixId = controller.resolvePlayingMixId();
                                        if (mixId != null) {
                                          final ok = await controller.deleteMix(mixId);
                                          if (ok) {
                                            Get.snackbar(
                                              "Removed",
                                              "Mix deleted",
                                              snackPosition: SnackPosition.BOTTOM,
                                            );
                                          }
                                          return;
                                        }

                                        // Fallback: local-only mixes
                                        controller.savedMixes.removeWhere((mix) {
                                          final savedSounds = List<int>.from(mix['sounds'] ?? <int>[]);
                                          final savedMusic = List<int>.from(mix['music'] ?? <int>[]);
                                          final currentSoundIds = controller.playingSounds.map((e) => e.id);
                                          final currentMusicIds = controller.playingMusic.map((e) => e.id);

                                          return Set.from(savedSounds).containsAll(currentSoundIds) &&
                                              Set.from(currentSoundIds).containsAll(savedSounds) &&
                                              Set.from(savedMusic).containsAll(currentMusicIds) &&
                                              Set.from(currentMusicIds).containsAll(savedMusic);
                                        });

                                        controller.savedMixes.refresh();
                                      },
                                      child: const Text('Yes, Remove', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              if (controller.playingSounds.isEmpty) {
                                Get.snackbar(
                                  "Cannot Save Mix",
                                  "Please add at least one sound before saving.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(12),
                                  borderRadius: 12,
                                  duration: const Duration(seconds: 3),
                                );
                              } else if (controller.playingSounds.length == 1 && controller.playingMusic.isEmpty) {
                                Get.snackbar(
                                  "Add More Sounds",
                                  "Please select at least two sounds to save your mix.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.orangeAccent.withOpacity(0.9),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(12),
                                  borderRadius: 12,
                                  duration: const Duration(seconds: 3),
                                );
                              } else {
                                controller.openSaveMixBottomSheet(context);
                                controller.mixNameController.text = "Mix${controller.savedMixes.length}";
                                controller.isTextNotEmpty.value = true;
                              }
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                                child: Icon(alreadySaved ? Icons.favorite : Icons.favorite_border, color: alreadySaved ? Colors.pinkAccent : Colors.white, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alreadySaved ? "Remove Mix" : "Save Mix",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.starColor, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenSaveMixBottomSheet1 extends StatefulWidget {
  const OpenSaveMixBottomSheet1({super.key});

  @override
  State<OpenSaveMixBottomSheet1> createState() => OpenSaveMixBottomSheet1State();
}

class OpenSaveMixBottomSheet1State extends State<OpenSaveMixBottomSheet1> {
  final controller = Get.find<SleepSoundController>();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(microseconds: 100),
      curve: Curves.easeInOutCubic,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 36),
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            "Save this Mix",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          Obx(() {
            final items = [...controller.playingSounds, ...controller.playingMusic];

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: items.map((sound) {
                return CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white12,
                  backgroundImage: sound.image.isNotEmpty ? NetworkImage(sound.image) : null,
                  child: sound.image.isEmpty ? const Text('🎵', style: TextStyle(fontSize: 22)) : null,
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: TextField(
              controller: controller.mixNameController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: (value) {
                controller.isTextNotEmpty.value = value.trim().isNotEmpty;
              },
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
            ),
          ),

          const SizedBox(height: 18),
          Text(
            "Choose a name for this mix",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.starColor, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isTextNotEmpty.value
                    ? () {
                        print("save mix");

                        controller.saveCurrentMix(context);
                        Get.back(); // Close bottom sheet
                        print("Saving mix...");
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isTextNotEmpty.value ? AppColors.blueColor : AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
