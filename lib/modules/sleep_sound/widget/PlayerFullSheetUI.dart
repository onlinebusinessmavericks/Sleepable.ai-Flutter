// import 'package:marquee/marquee.dart';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepable_ai/modules/sleep_tracker_screen/controllers/sleep_tracker_screen_controller.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/widgets/custom_loader.dart';

import '../../../core/utils/library.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/cached_image_widget.dart';
import '../../alarm/controllers/alarm_controller.dart';
import '../../music/views/music_view.dart';
import '../controllers/sleep_sound_controller.dart';
import '../model/SoundItem.dart';

enum SleepOnboardingStep { advanceTracker, setSmartAlarm, trySleepNote, sleepNote, placeDevice } //smartAlarm

Future<bool> isFirstTimeUser() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('sleep_onboarding_done') ?? false);
}

Future<void> setOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('sleep_onboarding_done', true);
}

Future<void> setSkipPlaceDevice(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('skip_place_device', value);
}

Future<bool> shouldSkipPlaceDevice() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('skip_place_device') ?? false;
}

Future<void> setSkipSetSmartAlarm(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('skip_set_smart_alarm', value);
}

Future<bool> shouldSkipSetSmartAlarm() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('skip_set_smart_alarm') ?? false;
}

void openSoundListBottomSheet(BuildContext context, SleepSoundController controller) {
  Get.bottomSheet(
    AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16 * SizeConfigs.paddingScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                context.lang.soundList,
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 35),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          SizedBox(height: 12 * SizeConfigs.paddingScale),

          /// 🔹 Sound list with animation

          Expanded(
            child: Obx(() {
              // 🔥 Uses the dynamic list we created above
              final list = controller.activePlaylist;

              if (list.isEmpty) {
                return  Center(
                  child: Text(context.lang.noItemsFound, style: TextStyle(color: Colors.white54)),
                );
              }

              return AnimationLimiter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 100.0,
                      curve: Curves.easeOutCubic,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: List.generate(list.length, (index) {
                      final sound = list[index];
                      final bool isCurrent = controller.playingMusic.any((m) => m.id == sound.id);
                      final bool isPlayingIcon = isCurrent && !controller.isPaused.value;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6 * SizeConfigs.paddingScale, horizontal: 4 * SizeConfigs.paddingScale),
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white.withOpacity(0.1) : AppColors.cardBackGroundGreyColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isCurrent ? Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1) : null,
                        ),
                        child: ListTile(
                          onTap: () => controller.toggleMusic(sound),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedImageWidget(url: sound.image, height: 45 * SizeConfigs.paddingScale, width: 45 * SizeConfigs.paddingScale, fit: BoxFit.cover),
                          ),
                          title: Text(
                            sound.name,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: isCurrent ? Colors.blueAccent : Colors.white, fontSize: 14 * SizeConfigs.textScale),
                          ),
                          subtitle: Text(
                            sound.artist?.name ?? (sound.categoryName.toLowerCase() == "story" ? context.lang.storyteller : context.lang.relaxingMelody),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w400, color: Colors.white70, fontSize: 12 * SizeConfigs.textScale),
                          ),
                          trailing: Material(
                            color: isCurrent ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => controller.toggleMusic(sound),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(isPlayingIcon ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24 * SizeConfigs.paddingScale),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}

class PlayerFullSheetUI extends StatelessWidget {
  final SoundItem sound;

  //bool? isFromStory;

  PlayerFullSheetUI({super.key, required this.sound}); //this.isFromStory

  final SleepSoundController controller = Get.find<SleepSoundController>();


  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            /// 🌄 DYNAMIC BACKGROUND IMAGE (Blurred)
            Obx(() {
              // Get the current sound from the list, or fallback to constructor sound
              final activeSound = controller.playingMusic.isNotEmpty ? controller.playingMusic.first : sound;

              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(activeSound.image), // Changed to activeSound
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(color: Colors.black.withOpacity(0.65)),
                  ),
                ),
              );
            }),

            /// 🔹 CONTENT
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 16 * SizeConfigs.paddingScale, right: 16 * SizeConfigs.paddingScale, top: 5 * SizeConfigs.paddingScale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// 🔹 TOP BAR
                    Row(
                      children: [
                        SmallCircleIcon(icon: Icons.arrow_back_rounded, size: 20 * SizeConfigs.textScale, iconColor: Colors.white, backgroundColor: Colors.white10, onTap: () => Get.back()),
                        const Spacer(),
                        Text(
                          context.lang.relaxYourBody,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Obx(() {
                          // Current active sound select karo
                          final activeSound = controller.playingMusic.isNotEmpty ? controller.playingMusic.first : sound;

                          final isFav = activeSound.isFavorite ?? false;

                          return GestureDetector(
                            onTap: () {
                              // Direct controller nu function call karo
                              controller.toggleLike(activeSound, activeSound.categoryName, activeSound.subcategoryName);
                            },
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                              child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 20),
                            ),
                          );
                        }),
                      ],
                    ),

                    /// 🖼 DYNAMIC MAIN COVER IMAGE
                    Obx(() {
                      final activeSound = controller.playingMusic.isNotEmpty ? controller.playingMusic.first : sound;

                      // 🔥 Dynamically check if the current playing item is a Story
                      final isStory = activeSound.categoryName.toLowerCase() == 'story';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: MediaQuery.of(context).size.width * 0.85,

                        // 🔥 Make the container shorter (landscape shape) if it's a story
                        height: isStory
                            ? MediaQuery.of(context).size.width * 0.55 // Wide aspect ratio for stories
                            : MediaQuery.of(context).size.height * 0.40, // Tall aspect ratio for music

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(activeSound.image),
                            // 🔥 Use contain for stories to ensure 0% cropping,
                            // or use cover (it will look much better now that the height is fixed)
                            fit: isStory ? BoxFit.contain : BoxFit.cover,
                          ),
                        ),
                      );
                    }),

                    /// 🔹 MAIN CONTENT
                    Column(
                      children: [
                        /// 🎵 TITLE & ARTIST (Reactive)
                        Obx(() {
                          final activeSound = controller.playingMusic.isNotEmpty ? controller.playingMusic.first : sound;

                          return Column(
                            children: [
                              Text(
                                activeSound.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4 * SizeConfigs.paddingScale),
                              Text(
                                activeSound.artist?.name ?? context.lang.unknownArtist,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 16 * SizeConfigs.textScale),
                              ),
                            ],
                          );
                        }),

                        SizedBox(height: 12 * SizeConfigs.paddingScale),

                        /// ⏱ SLEEP TIMER
                        Obx(() {
                          final d = controller.sleepTimerDuration.value;
                          return GestureDetector(
                            onTap: () => openBottomSheet(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 10 * SizeConfigs.paddingScale),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(_format(d), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          );
                        }),

                        SizedBox(height: 20 * SizeConfigs.paddingScale),

                        /// 🎚 SLIDER + TIME (Reactive)
                        Obx(() {
                          final pos = controller.currentPosition.value;
                          // Use dynamic total duration from active sound
                          final activeSound = controller.playingMusic.isNotEmpty ? controller.playingMusic.first : sound;
                          final total = controller.totalDurationPosition.value.inMilliseconds > 0 ? controller.totalDurationPosition.value : Duration(seconds: activeSound.duration ?? 0);

                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 8,
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                                  activeTrackColor: AppColors.graphIconColor,
                                  inactiveTrackColor: Colors.white24,
                                  thumbShape: const _MergedThumbShape(),
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: total.inMilliseconds.toDouble(),
                                  value: pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                                  onChanged: (v) {
                                    controller.seek(Duration(milliseconds: v.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_format(pos), style: const TextStyle(color: Colors.white70)),
                                    Text(_format(total), style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),

                        SizedBox(height: 20),

                        /// 🎛 CONTROLS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => _iconBtn(
                                Icons.repeat,
                                active: controller.isRepeatEnabled.value,
                                onTap: () async {
                                  controller.isRepeatEnabled.toggle();
                                  await controller.musicPlayer.setLoopMode(controller.isRepeatEnabled.value ? LoopMode.one : LoopMode.off);
                                },
                              ),
                            ),
                            _iconBtn(Icons.skip_previous, onTap: () => controller.skipPrevious()),
                            Obx(() => _iconBtn(controller.isPaused.value ? Icons.play_arrow_rounded : Icons.pause, big: true, onTap: () => controller.togglePause())),
                            _iconBtn(Icons.skip_next, onTap: () => controller.skipNext()),
                            _iconBtn(Icons.playlist_play, onTap: () => openSoundListBottomSheet(context, controller)),
                          ],
                        ),

                        SizedBox(height: 30),

                        /// 🌙 START SLEEP
                        Obx(() {

                          print("---controller.isTrackingActive.value -------${controller.isTrackingActive.value}");
                          // Hide the button if tracking is already active
                          if (controller.isTrackingActive.value) {
                            return const SizedBox.shrink();
                          }

                          return Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18 * SizeConfigs.paddingScale,
                                    vertical: 12 * SizeConfigs.paddingScale
                                ),
                              ),
                              onPressed: () async {
                                await openSleepOnboardingBottomSheet(context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(Assets.homeSleepableAppIcon, height: 24 * SizeConfigs.paddingScale),
                                  SizedBox(width: 8 * SizeConfigs.paddingScale),
                                  Text(
                                    context.lang.startSleep,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 16 * SizeConfigs.textScale,
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 HELPERS

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _iconBtn(IconData icon, {bool big = false, bool active = false, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: big ? 68 : 48,
        height: big ? 68 : 48,
        decoration: BoxDecoration(color: active ? Colors.blueAccent : Colors.white12, shape: BoxShape.circle),
        child: Icon(icon, size: big ? 38 : 24, color: Colors.white),
      ),
    );
  }
}

openSleepNoteBottomSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);
  final controller = Get.find<SleepSoundController>();

  return Column(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16 * SizeConfigs.paddingScale),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                context.lang.addSleepNote,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Obx(() {
          if (controller.isAnyNoteLoading) {
            return Center(child: LoaderWidget(size: sw(150)));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 8 * SizeConfigs.paddingScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(context,  context.lang.environment, controller.environmentTags, controller),
                _buildSection(context, context.lang.today, controller.todayTags, controller),
                _buildSection(context, context.lang.others, controller.otherTags, controller),

                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    context.lang.describeYourDay,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 16 * SizeConfigs.paddingScale),

                /// Description Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  padding: EdgeInsets.symmetric(horizontal: 12 * SizeConfigs.paddingScale, vertical: 6 * SizeConfigs.paddingScale),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.descriptionController,
                          maxLines: 5,
                          minLines: 1,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.text, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: context.lang.sleepNoteHintText, //"Today, I had 3 cups of coffee... and I was feeling sleepy/lazy in the noon 🥱",
                            hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.text.withOpacity(0.5), fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40 * SizeConfigs.paddingScale),
              ],
            ),
          );
        }),
      ),
    ],
  );
}

/// 🔹 Section Widget
Widget _buildSection(BuildContext context, String title, RxList<Map<String, dynamic>> items, SleepSoundController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// 🔹 Section Title
      Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
        ),
      ),
      SizedBox(height: 12 * SizeConfigs.paddingScale),

      /// 🔹 Grid
      Obx(
        () => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(left: 8 * SizeConfigs.paddingScale, top: 10 * SizeConfigs.paddingScale, bottom: 20 * SizeConfigs.paddingScale),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12 * SizeConfigs.paddingScale,
            mainAxisSpacing: 10 * SizeConfigs.paddingScale,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length + 1,
          itemBuilder: (context, i) {
            /// ➕ ADD BUTTON
            if (i == items.length) {
              return GestureDetector(
                onTap: () {
                  openCreateTagBottomSheet(context, controller, items, title);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.add, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.lang.add,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white60, fontSize: 11 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                      //
                    ),
                  ],
                ),
              );
            }

            final tag = items[i];
            final active = tag['isSelected'] == true;

            return GestureDetector(
              /// ✅ SELECT
              onTap: () {
                tag['isSelected'] = !active;
                items.refresh();
              },

              /// ✏️ EDIT
              // onLongPress: () {
              //   openCreateTagBottomSheet(context, controller, items, title, editTag: tag, editIndex: i);
              // },
              onLongPress: tag['isPublic'] == true
                  ? null
                  : () {
                      openCreateTagBottomSheet(context, controller, items, title, editTag: tag, editIndex: i);
                    },

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      /// MAIN CIRCLE
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? AppColors.blueBackground
                              : tag['isPublic'] == true
                              ? Colors.white12
                              : AppColors.cardColor,
                          // color: active ? AppColors.blueBackground : AppColors.cardColor,
                          boxShadow: active ? [BoxShadow(color: AppColors.blueColor.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)] : [],
                          border: Border.all(color: active ? AppColors.blueColor.withOpacity(0.6) : AppColors.borderColor.withOpacity(0.4), width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(tag['icon'], style: TextStyle(fontSize: 22 * SizeConfigs.textScale)),
                        // child: Text(icon, style: TextStyle(fontSize: 22 * SizeConfigs.textScale)),
                      ),
                      SizedBox(height: 6 * SizeConfigs.paddingScale),

                      /// ❌ DELETE
                      // if (active)
                      if (active && tag['isPublic'] != true)
                        Positioned(
                          top: -4,
                          right: -2,
                          child: GestureDetector(
                            onTap: () {
                              showDeleteNoteDialog(context: context, noteId: tag['id'], index: i, items: items, controller: controller);
                            },
                            child: Container(
                              height: 20,
                              width: 20,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                              child: const Icon(Icons.delete, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// NAME
                  Marquee(
                    child: Text(
                      tag['name'],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: active ? Colors.white : Colors.white70, fontSize: 11 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

void showDeleteNoteDialog({required BuildContext context, required int noteId, required int index, required RxList<Map<String, dynamic>> items, required SleepSoundController controller}) {
  showDialog(
    context: context,
    builder: (_) {
      return GiffyDialog(
        key: const Key("DeleteNoteDialog"),

        giffy: Lottie.asset(Assets.lottieDelete, height: 120, fit: BoxFit.fitHeight, repeat: true),

        title:  Text(
          context.lang.deleteNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),

        // content:  Text(
        //   context.lang.areSureWantDeleteNote 'Are you sure you want to delete this note? '
        // context.lang.thisActionCannotUndone 'This action cannot be undone.',
        //   textAlign: TextAlign.center,
        //   style: TextStyle(color: Colors.white70, fontSize: 16),
        // ),
        content: Text(
          '${context.lang.areSureWantDeleteNote} '
              '${context.lang.thisActionCannotUndone}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: const Color(0xFF1E1E1E),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(context.lang.cancel, style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);

              /// 🔥 Call API
              final response = await controller.deleteNote(noteId: noteId);

              if (response.success == true) {
                items.removeAt(index);
                items.refresh();
              } else {
                Get.snackbar(context.lang.error, context.lang.failedDeleteNote);
              }
            },
            child:  Text(context.lang.yesDelete, style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

void openCreateTagBottomSheet(BuildContext context, SleepSoundController controller, RxList<Map<String, dynamic>> targetList, String sectionTitle, {Map<String, dynamic>? editTag, int? editIndex}) {
  final isEdit = editTag != null;

  final TextEditingController tagController = TextEditingController(text: editTag?['name'] ?? '');

  controller.isTextNotEmpty.value = tagController.text.isNotEmpty;

  Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  /// TITLE
                  Text(
                    isEdit ? "${context.lang.edit} $sectionTitle ${context.lang.tag}" : "${context.lang.add} $sectionTitle ${context.lang.tag}",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 30),

                  /// INPUT
                  TextField(
                    controller: tagController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    onChanged: (v) => controller.isTextNotEmpty.value = v.trim().isNotEmpty,
                    decoration:  InputDecoration(
                      hintText: context.lang.enterTagName,
                      hintStyle: TextStyle(color: Colors.white38),
                      border: UnderlineInputBorder(),
                    ),
                  ),

                  // const Spacer(),
                  SizedBox(height: 40 * SizeConfigs.paddingScale),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52 * SizeConfigs.paddingScale,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            ),
                            child: Text(
                              context.lang.cancel,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Obx(() {
                          final isEnabled = controller.isTextNotEmpty.value;

                          return SizedBox(
                            height: 52 * SizeConfigs.paddingScale,
                            child: ElevatedButton(
                              onPressed: isEnabled
                                  ? () async {
                                      print("----in onpress----");
                                      final name = tagController.text.trim();

                                      if (isEdit && editIndex != null) {
                                        print("----in Edit----");

                                        /// ✏️ Call API
                                        final response = await controller.updateNote(noteId: editTag!['id'], title: name);

                                        if (response.success == true) {
                                          targetList[editIndex]['name'] = name;
                                          targetList.refresh();
                                          Get.back();
                                        }
                                      } else {
                                        print("----in add----");

                                        final newTag = {"icon": "⭐", "name": name, "isSelected": true};

                                        /// Add to correct category list
                                        final categoryList = controller.getCategoryListFromTitle(controller, sectionTitle);

                                        categoryList.add(newTag);

                                        /// Update UI list
                                        targetList.add(newTag);
                                        targetList.refresh();

                                        final success = await controller.submitSleepNote();

                                        if (success) {
                                          Get.back(); // ✅ close bottom sheet ONLY once

                                          await Future.delayed(const Duration(milliseconds: 200));

                                          Get.dialog(
                                            Dialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              backgroundColor: const Color(0xFF0A152F),
                                              child: Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Lottie.asset(Assets.lottieSleepSuccess, height: 150, repeat: true),
                                                    const SizedBox(height: 16),
                                                     Text(
                                                      context.lang.sleepNoteAddedSuccessfully,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.pinkAccent,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      onPressed: () {
                                                        // final controller =
                                                        // Get.find<SleepSoundController>();

                                                        Get.back(); // close dialog

                                                        // if (controller.steps.isNotEmpty) {
                                                        //   controller.nextStep();
                                                        // }
                                                        //
                                                        // controller.descriptionController.clear();
                                                      },
                                                      child:  Text(context.lang.oK , style: TextStyle(color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      // Get.back();

                                      /// Reset state after sheet closed
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        controller.isTextNotEmpty.value = false;
                                      });
                                    }
                                  : null,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEnabled ? AppColors.blueColor : Colors.white10,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),

                              child: Text(
                                isEdit ? context.lang.update : context.lang.add,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// LOADER OVERLAY
            Obx(() {
              if (controller.isAnyNoteLoading) {
                return Center(child: LoaderWidget(size: sw(150)));
              }

              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

void openBottomSheet(BuildContext context) {
  SizeConfigs.init(context); // ensure SizeConfigs initialized
  SizeConfigs2.init(context); // ensure SizeConfigs initialized

  // final List<int> minuteOptions = List.generate(18, (index) => (index + 1) * 5);
  // final RxInt selectedIndex = 2.obs; // Default: 15 min (index 2)
  final List<int> minuteOptions = List.generate(18, (index) => (index + 1) * 5);
  final RxInt selectedIndex = 2.obs;

  // 1. Define the controller outside the Obx
  final scrollController = FixedExtentScrollController(initialItem: selectedIndex.value);
  Get.bottomSheet(
    Container(
      height: SizeConfigs.screenHeight * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFF0A152F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16 * SizeConfigs.paddingScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Stack(
            alignment: Alignment.center,
            children: [
              // 🔹 Left close arrow
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  // onTap: () {
                  //   final controller = Get.find<SleepSoundController>();
                  //   final selectedMinutes = minuteOptions[selectedIndex.value];
                  //   controller.startSleepTimer(Duration(minutes: selectedMinutes));
                  //   Get.back();
                  // }, //=> Get.back(),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 38 * SizeConfigs.textScale),
                ),
              ),

              // 🔹 Center title
              Center(
                child: Text(
                  context.lang.setSleepTimer,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          // SizedBox(height: 12 * SizeConfigs.paddingScale),

          // 🔹 Vertical Scroll Picker
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Number scroller
                SizedBox(
                  height: 160 * SizeConfigs.paddingScale,
                  width: 60 * SizeConfigs.paddingScale,
                  child: ListWheelScrollView.useDelegate(
                    controller: scrollController,
                    // controller: FixedExtentScrollController(initialItem: selectedIndex.value),
                    itemExtent: 40 * SizeConfigs.paddingScale,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      selectedIndex.value = index;
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index >= minuteOptions.length) return null;
                        return Obx(() {
                          final isSelected = index == selectedIndex.value;
                          return Center(
                            child: Text(
                              "${minuteOptions[index]}",
                              style: TextStyle(
                                fontSize: (isSelected ? 28 : 20) * SizeConfigs.textScale,
                                color: isSelected ? Colors.white : Colors.white54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),

                // “min” label
                Padding(
                  padding: EdgeInsets.only(left: 4 * SizeConfigs.paddingScale),
                  child: Text(
                    context.lang.min,
                    style: TextStyle(color: Colors.white70, fontSize: 22 * SizeConfigs.textScale),
                  ),
                ),
              ],
            ),
          ),

          // SizedBox(height: 20 * SizeConfigs.paddingScale),

          // 🔹 Confirm button
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30 * SizeConfigs.paddingScale)),
                padding: EdgeInsets.symmetric(horizontal: 28 * SizeConfigs.paddingScale, vertical: 12 * SizeConfigs.paddingScale),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                final controller = Get.find<SleepSoundController>();
                final selectedMinutes = minuteOptions[selectedIndex.value];
                controller.startSleepTimer(Duration(minutes: selectedMinutes));
                Get.back();
              },
              child: Text(
                context.lang.setTimer,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MergedThumbShape extends SliderComponentShape {
  const _MergedThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(0, 0);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()..color = AppColors.greenColor;

    // Draw a merged rounded rectangle
    final rect = Rect.fromCenter(center: center, width: 40, height: 16);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    context.canvas.drawRRect(rrect, paint);
  }
}

openAdvanceSleepTrackerBottomSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);
  return SizedBox(
    width: double.infinity,
    child:
        /// 🔹 MAIN CONTENT
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //
              /// APP LOGO
              // Image.asset(Assets.homeSleepableAppIcon, height: 50),
              Center(child: Lottie.asset(height: MediaQuery.of(context).size.height * 0.20, Assets.lottiePillow2, repeat: true)),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              /// TITLE
              Text(
                "${context.lang.welcomeToTheMost}\n${context.lang.advancedSleepTracker}",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                // style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
              ),

              // const SizedBox(height: 40),
              // Spacer(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              /// FEATURES
               _FeatureItem(icon: Icons.pie_chart_outline, title: context.lang.knowAboutSleepPatterns, subtitle:  context.lang.gainInsightOfYourSleep),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

               _FeatureItem(icon: Icons.mic_none, title:  context.lang.trackSleepSounds, subtitle: context.lang.monitorTalkingAndSnoring),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

               _FeatureItem(icon: Icons.flash_on_outlined, title:  context.lang.smartSleepAnalysis, subtitle: context.lang.improveSleepEfficiency),
              // Spacer(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ],
          ),
        ),
  );
}

/// 🔹 FEATURE ROW WIDGET
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({required this.icon, required this.title, required this.subtitle});

  @override // Always include @override for build methods
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(left: 70), // Keep your centering logic
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.white, size: 28),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600, // Semi-bold for title
              fontSize: 19,
              letterSpacing: 0.5, // Improves readability across devices
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                // CHANGE: Use white with opacity instead of w200
                color: Colors.white.withOpacity(0.6),
                fontSize: 15 * SizeConfigs.textScale,
                fontWeight: FontWeight.w300, // Use w300 (Light) instead of w200
                height: 1.2, // Ensures consistent line height
              ),
            ),
          ),
        ),
      ),
    );
  }
}
opePlaceDevicePictureBottomSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);
  return SizedBox(
    width: double.infinity,
    child: Column(
      children: [
        /// 🔹 MAIN CONTENT
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20 * SizeConfigs.paddingScale),

                  /// ✅ Responsive image (NOT fixed 450)
                  // Image.asset(Assets.musicHealingMusic, height: MediaQuery.of(context).size.height * 0.35, fit: BoxFit.contain),
                  Lottie.asset(
                    height: MediaQuery.of(context).size.height * 0.35,
                    Assets.lottieIphoneCharging,
                    // fit: BoxFit.fill, // ✅ keeps animation aspect ratio perfect
                    repeat: true,
                  ),
                  SizedBox(height: 70 * SizeConfigs.paddingScale),

                  Text(
                    context.lang.placeTheDeviceAsPicture,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26),
                  ),

                  SizedBox(height: 20 * SizeConfigs.paddingScale),

                  Text(
                    context.lang.pleasePlacePhoneNextBedKeepChargerConnected,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w200),

                    //    Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70, fontSize: 20),
                  ),
                  SizedBox(height: 40 * SizeConfigs.paddingScale),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

openWakeUpAlarmBottomSheet(BuildContext context)  {

  SizeConfigs.init(context);
  SizeConfigs2.init(context);
  if (!Get.isRegistered<AlarmController>()) {
    Get.put(AlarmController(), permanent: true);
  }

  final AlarmController controller = Get.find<AlarmController>();
// FORCE RESET FOR TESTING
//   controller.hour.value = 8;
//   controller.minute.value = 30;
//   controller.isAm.value = true;
  // 1. Tell controller we are starting a new sync session
  controller.wakeUpWheelsSynced = false;

  // 2. Sync wheels AFTER the BottomSheet builds so 'hasClients' is true
  // Inside openWakeUpAlarmBottomSheet
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 150), () {
      print("🚀 BottomSheet sync triggered...");
      controller.syncWakeUpWheels();
    });
  });
  return SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(height: 20 * SizeConfigs.paddingScale),

          Text(
            context.lang.setYourWakeUpTime,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
            // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26),
          ),

          SizedBox(height: 0 * SizeConfigs.paddingScale),
          Spacer(),

          Container(
            padding: const EdgeInsets.only(top: 30, bottom: 30),
            margin: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // HOUR WHEEL (only numbers scroll)
                Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 50,
                      child: ListWheelScrollView.useDelegate(
                        controller: controller.hourController,
                        itemExtent: 35,
                        perspective: 0.002,
                        physics: const FixedExtentScrollPhysics(),

                        // onSelectedItemChanged: (index) {
                        //   // controller.setHour(index);
                        //   int val = (index % 12);
                        //   if (val == 0) val = 12;
                        //   controller.hour.value = val;
                        // },
                        onSelectedItemChanged: (index) {
                          int val = (index % 12);
                          if (val == 0) val = 12;
                          controller.hour.value = val;

                          // 🔥 CRITICAL: Every time the user moves the wheel,
                          // ensure the alarm is active and rescheduled.
                          controller.wakeUp.value = true;
                          controller.scheduleAlarm();
                        },

                        // childDelegate: ListWheelChildBuilderDelegate(
                        //   childCount: 12,
                        //   builder: (context, index) {
                        //     final value = index + 1;
                        //
                        //     return Obx(() {
                        //       final isSelected = controller.hour.value == value;
                        //
                        //       return Center(
                        //         child: Text(
                        //           value.toString().padLeft(2, '0'),
                        //           style: isSelected
                        //               ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale)
                        //               : Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                        //           //Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey, fontSize: 18 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                        //         ),
                        //       ); // Theme.of(context).textTheme.titleMedium?.copyWith(color: isSelected ? Colors.white : Colors.grey, fontSize: isSelected ? 20 : 18)
                        //     });
                        //   },
                        // ),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 10000, // 🟢 Set high for infinite feel
                          builder: (context, index) {
                            // 🟢 Calculate display number based on infinite index
                            int displayHour = (index % 12);
                            if (displayHour == 0) displayHour = 12;

                            return Obx(() {
                              final isSelected = controller.hour.value == displayHour;
                              return Center(
                                child: Text(
                                  displayHour.toString().padLeft(2, '0'),
                                  style: isSelected
                                      ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale)
                                      : Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ),

                    // FIXED "h"
                    Text(
                      context.lang.h,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                Text(
                  ":",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale),
                ),

                const SizedBox(width: 10),

                // MINUTE WHEEL (only numbers scroll)
                Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 50,
                      child: ListWheelScrollView.useDelegate(
                        controller: controller.minuteController,
                        itemExtent: 35,
                        perspective: 0.002,
                        physics: const FixedExtentScrollPhysics(),

                        // onSelectedItemChanged: (i) {
                        //   // controller.setMinute(i);
                        //   controller.minute.value = i % 60;
                        // },
                        onSelectedItemChanged: (i) {
                          controller.minute.value = i % 60;

                          // 🔥 CRITICAL
                          controller.wakeUp.value = true;
                          controller.scheduleAlarm();
                        },
                        // childDelegate: ListWheelChildBuilderDelegate(
                        //   childCount: 60,
                        //   builder: (context, index) {
                        //     return Obx(() {
                        //       final isSelected = controller.minute.value == index;
                        //
                        //       return Center(
                        //         child: Text(
                        //           index.toString().padLeft(2, '0'),
                        //           style: isSelected
                        //               ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale)
                        //               : Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                        //
                        //           //  Theme.of(context).textTheme.titleMedium?.copyWith(color: isSelected ? Colors.white : Colors.grey, fontSize: isSelected ? 20 : 18),
                        //         ),
                        //       );
                        //     });
                        //   },
                        // ),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 10000, // 🟢 High for infinite feel
                          builder: (context, index) {
                            int displayMin = index % 60;
                            return Obx(() {
                              final isSelected = controller.minute.value == displayMin;
                              return Center(
                                child: Text(
                                  displayMin.toString().padLeft(2, '0'),
                                  style: isSelected
                                      ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale)
                                      : Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ),

                    // FIXED "min"
                    Text(
                      context.lang.min,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale),
                    ),
                  ],
                ),

                const SizedBox(width: 15),

                // AM / PM wheel (unchanged)
                // AM / PM wheel
                SizedBox(
                  height: 120,
                  width: 50,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller.amPmController,
                    itemExtent: 35,
                    physics: const FixedExtentScrollPhysics(),

                    onSelectedItemChanged: (i) {
                      controller.setAmPm(i);
                      controller.wakeUp.value = true;
                      controller.scheduleAlarm();
                    },

                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2,
                      builder: (context, index) {
                        return Obx(() {
                          final text = index == 0 ?  context.lang.AM :  context.lang.PM;
                          final isSelected = controller.isAm.value == (index == 0);

                          return Center(
                            child: Text(
                              text,
                              style: isSelected
                                  ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 25 * SizeConfigs.textScale)
                                  : Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textBoldColor, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w300),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),
          SizedBox(height: 40 * SizeConfigs.paddingScale),
        ],
      ),
    ),
  );
}

openTrySleepNoteBottomSheet(BuildContext context) {
  SizeConfigs.init(context);
  SizeConfigs2.init(context);

  return SizedBox(
    width: double.infinity,
    child: Column(
      children: [
        /// 🔹 MAIN CONTENT
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30 * SizeConfigs.paddingScale),

                  /// ✅ Responsive image (NOT fixed 450)
                  // Image.asset(Assets.musicHealingMusic, height: MediaQuery.of(context).size.height * 0.35, fit: BoxFit.contain),
                  Lottie.asset(
                    height: MediaQuery.of(context).size.height * 0.35,
                    Assets.lottieNotes,
                    // Assets.lottieGraphBabyBlue,
                    fit: BoxFit.fill, // ✅ keeps animation aspect ratio perfect
                    repeat: true,
                  ),
                  SizedBox(height: 70 * SizeConfigs.paddingScale),

                  Text(
                    context.lang.trySleepNote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 24 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
                    // Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26),
                  ),

                  SizedBox(height: 20 * SizeConfigs.paddingScale),

                  Text(
                    context.lang.sleepNoteEasyRevealFactorsGoodNightsRest,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 15 * SizeConfigs.textScale, fontWeight: FontWeight.w200),
                  ), // ✅ reduced spacing
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

openSleepOnboardingBottomSheet(BuildContext context) async {
  SleepSoundController c;

  if (!Get.isRegistered<SleepSoundController>()) {
    c = Get.find<SleepSoundController>();
  } else {
    c = Get.find<SleepSoundController>();
  }

  // 🔥 Always refresh steps on opening
  await c.refreshSteps();

  showModalBottomSheet(context: context, isScrollControlled: true,useSafeArea: true ,enableDrag: false, backgroundColor: Colors.black87, builder: (_) => const _SleepOnboardingWrapper());
}

class _SleepOnboardingWrapper extends StatelessWidget {
  const _SleepOnboardingWrapper();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            /// 🔴 TOP 15% BACKGROUND COLOR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.15,
              child: Container(color: Colors.black87),
            ),

            /// 🟣 BOTTOM SHEET WITH PROPER ROUNDED CORNERS
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: const _SleepOnboardingSheet(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepOnboardingSheet extends StatelessWidget {
  const _SleepOnboardingSheet();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SleepSoundController>(
      builder: (c) {
        print("currentStep-------------- ${c.currentStep}");
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0A152F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: true,
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: c.steps.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500), // Slightly longer for a premium feel
                    switchInCurve: Curves.easeInOutCubic,      // Smoother acceleration
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      // 1. Create a slide-up animation
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 0.1), // Starts slightly lower
                        end: Offset.zero,
                      ).animate(animation);

                      // 2. Create a subtle scale-up animation
                      final scaleAnimation = Tween<double>(
                        begin: 0.95, // Starts slightly smaller
                        end: 1.0,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: ScaleTransition(
                            scale: scaleAnimation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(c.currentStep),
                      child: _buildStepContent(context, c.currentStep),
                    ),
                  ),
                ),

                c.currentStep == SleepOnboardingStep.sleepNote
                    ? Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
                  child: Center(
                    child: Obx(() => GestureDetector(
                      // 🔥 1. INSTANT FEEDBACK
                      onTapDown: (_) {
                        Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true); // Vibrate immediately
                        c.updateScale(0.92); // Shrink immediately
                      },
                      onTapUp: (_) {
                        c.updateScale(1.0); // Return to size
                        // No 'await' on logic if you want the screen to change now
                        _handleDonePress(c);
                      },
                      onTapCancel: () => c.updateScale(1.0),

                      child: AnimatedScale(
                        scale: c.scale.value,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child: Container(
                          width: SizeConfigs.screenWidth * 0.5,
                          height: 50 * SizeConfigs.paddingScale,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accentColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            context.lang.done,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 16 * SizeConfigs.textScale,
                                fontWeight: FontWeight.w500 // Increased weight for better look
                            ),
                          ),
                        ),
                      ),
                    )),
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: Center(
                    child: Obx(() => GestureDetector(
                      // 🔥 2. INSTANT FEEDBACK
                      onTapDown: (_) {
                        Haptics.vibrate(HapticsType.light,useAndroidHapticConstants: true);
                        c.updateScale(0.92);
                      },
                      onTapUp: (_) {
                        c.updateScale(1.0);
                        if (c.steps.isNotEmpty) c.nextStep();
                      },
                      onTapCancel: () => c.updateScale(1.0),

                      child: AnimatedScale(
                        scale: c.scale.value,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.steps.isEmpty ? Colors.grey : AppColors.accentColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            context.lang.continues,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 16 * SizeConfigs.textScale,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                    )),
                  ),
                ),
                c.currentStep == SleepOnboardingStep.sleepNote ? SizedBox() : SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                if (c.currentStep == SleepOnboardingStep.placeDevice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: GestureDetector(
                      onTap: () async {
                        // ✅ save preference
                        await setSkipPlaceDevice(true);

                        // ✅ immediately move forward
                        c.nextStep();
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 52,
                        child: Text(
                          context.lang.dontShowAgain,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w200) ?? const TextStyle(),

                          // style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ),
                c.currentStep == SleepOnboardingStep.sleepNote ? SizedBox() : SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, SleepOnboardingStep step) {
    switch (step) {
      case SleepOnboardingStep.advanceTracker:
        return openAdvanceSleepTrackerBottomSheet(context);
      case SleepOnboardingStep.setSmartAlarm:
        return openWakeUpAlarmBottomSheet(context);
      case SleepOnboardingStep.trySleepNote:
        return openTrySleepNoteBottomSheet(context);
      case SleepOnboardingStep.sleepNote:
        return openSleepNoteBottomSheet(context);
      case SleepOnboardingStep.placeDevice:
        return opePlaceDevicePictureBottomSheet(context);
    }
  }
  void _handleDonePress(dynamic c) async {
    final controller = Get.find<SleepSoundController>();

    // Logic for gathering tags
    final allSelectedTags = [
      ...controller.environmentTags.where((e) => e["isSelected"] == true),
      ...controller.todayTags.where((e) => e["isSelected"] == true),
      ...controller.otherTags.where((e) => e["isSelected"] == true),
    ];

    final List<int> noteIds = allSelectedTags.map<int>((e) => e["id"] as int).toList();
    final String description = controller.descriptionController.text.trim();

    // Save to Preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('sleep_note_ids', noteIds.map((e) => e.toString()).toList());
    await prefs.setString('sleep_description', description);

    // UI Reset
    controller.clearAllSelected();
    controller.descriptionController.clear();

    if (c.steps.isNotEmpty) c.nextStep();
  }
}
