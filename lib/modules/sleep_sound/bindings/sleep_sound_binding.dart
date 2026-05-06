import 'package:get/get.dart';

import '../controllers/sleep_sound_controller.dart';

import 'package:get/get.dart';
import '../controllers/sleep_sound_controller.dart';

// class SleepSoundBinding extends Bindings {
//   @override
//
//   void dependencies() {
//     Get.lazyPut<SleepSoundController>(() => SleepSoundController());
//   }
// }
// import 'dart:async';
//
// import 'package:get/get.dart';
// import 'package:giffy_dialog/giffy_dialog.dart';
// import 'package:just_audio/just_audio.dart';
//
// import '../../../core/utils/library.dart';
//
// import '../views/sleep_sound_view.dart';
//
// class SleepSoundController extends GetxController {
//   RxString selectedTopTab = "White Noise".obs;
//   RxString selectedFilter = "All".obs;
//   RxSet<String> playingSounds = <String>{}.obs;
//   RxMap<String, double> soundVolumes = <String, double>{}.obs;
//   final RxBool isBottomSheetOpen = false.obs;
// // Add at top
//   final Map<String, AudioPlayer> _soundPlayers = {};
//   final Map<String, AudioPlayer> _musicPlayers = {};
//   final tabOrder = ["My Aids", "White Noise", "Music", "Mixes", "Story", "Premium"];
//
//   final tabFilters = {
//     "My Aids": ["Favorites", "History"],
//     "White Noise": ["All", "Mixes", "Rain", "ASMR", "Nature", "Animal", "City", "Fan", "Melody", "Baby", "Noise", "Special"],
//     "Music": ["Healing Music", "Nature Melodies", "Lullaby", "Meditation Music", "Binaural Beats", "Special Music"],
//     "Mixes": ["All", "Sleep Noise Scenes", "Your Mixes"],
//     "Story": ["All", "Bedtime", "Fantasy", "Motivational"],
//     "Premium": ["All", "Exclusive", "Pro", "Relax"],
//   };
//
//   /// Example mock data for sounds
//   final Map<String, List<Map<String, String>>> soundLibrary = {
//     "All": [
//       {"asset": Assets.soundsRainSound,"icon": "🌧️", "name": "Rain", "category": "Rain"},
//       {"asset": Assets.soundsFanSound,"icon": "🌀", "name": "Exhaust Fan", "category": "Fan"},
//       {"asset": Assets.soundsCampfireFixed,"icon": "🔥", "name": "Campfire", "category": "Nature"},
//       {"asset": Assets.soundsOceanWavesSound,"icon": "🌊", "name": "Ocean Waves", "category": "Nature"},
//       {"asset": Assets.soundsRainOnLeavesSound,"icon": "🍃", "name": "Rain on Leaves", "category": "Rain"},
//       {"asset": Assets.soundsFluteSound,"icon": "🎶", "name": "Flute", "category": "Melody"},
//       {"asset": Assets.soundsClockSound,"icon": "⏰", "name": "Clock", "category": "Noise"},
//       {"asset": Assets.soundsCricketsSound,"icon": "🦗", "name": "Crickets", "category": "Animal"},
//       {"asset": Assets.soundsKeyboardSound,"icon": "⌨️", "name": "Keyboard", "category": "City"},
//       {"asset": Assets.soundsRainSound,"icon": "🏕️", "name": "Rain on Tent", "category": "Rain"},
//       {"asset": Assets.soundsSeagullSound,"icon": "🕊️", "name": "Seagull", "category": "Animal"},
//       {"asset": Assets.soundsRainSound,"icon": "🏠", "name": "Rain on Roof", "category": "Rain"},
//       {"asset": Assets.soundsWhiteNoiseSound,"icon": "💨", "name": "Wind", "category": "Nature"},
//       {"asset": Assets.soundsWhiteNoiseSound,"icon": "🔊", "name": "White Noise", "category": "Noise"},
//       {"icon": "🔵", "name": "Blue Noise", "category": "Noise"},
//       {"icon": "🟢", "name": "Green Noise", "category": "Noise"},
//       {"icon": "💨", "name": "Wind", "category": "Nature"},
//       {"icon": "🔊", "name": "White Noise", "category": "Noise"},
//       {"icon": "🔵", "name": "Blue Noise", "category": "Noise"},
//       {"icon": "🟢", "name": "Green Noise", "category": "Noise"},
//       {"icon": "💨", "name": "Wind", "category": "Nature"},
//       {"icon": "🔊", "name": "White Noise", "category": "Noise"},
//       {"icon": "🔵", "name": "Blue Noise", "category": "Noise"},
//       {"icon": "🟢", "name": "Green Noise", "category": "Noise"},
//     ],
//     "Mixes": [
//       {"name": "Relax Mix", "icon": "🎧"},
//       {"name": "Sleep Mix", "icon": "😴"},
//     ],
//     "Rain": [
//       {"name": "Soft Rain", "icon": "🌦️"},
//       {"name": "Heavy Rain", "icon": "🌧️"},
//     ],
//     "Healing Music": [
//       {"image": Assets.musicHealingMusic, "name": "Beat Insomnia", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Sleep at Ease", "duration": "24 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Happy Night", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Deep Sleep", "duration": "28 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Peaceful Sleep", "duration": "33 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Happy Night", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Happy Night", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Deep Sleep", "duration": "28 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Peaceful Sleep", "duration": "33 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Happy Night", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic, "name": "Beat Insomnia", "duration": "60 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Peaceful Sleep", "duration": "33 MIN"},
//     ],
//     "Nature Melodies": [
//       {"image": Assets.musicHealingMusic, "name": "Forest Stream", "duration": "45 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Morning Birds", "duration": "40 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Mountain Breeze", "duration": "50 MIN"},
//     ],
//     "Lullaby": [
//       {"image": Assets.musicHealingMusic, "name": "Baby Dreams", "duration": "30 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Night Lullaby", "duration": "35 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Starry Night", "duration": "32 MIN"},
//     ],
//     "Meditation Music": [
//       {"image": Assets.musicHealingMusic, "name": "Zen Vibes", "duration": "60 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Mind Calm", "duration": "55 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Tranquil Focus", "duration": "50 MIN"},
//     ],
//     "Binaural Beats": [
//       {"image": Assets.musicHealingMusic, "name": "Focus Alpha", "duration": "45 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Deep Delta", "duration": "60 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Relax Theta", "duration": "50 MIN"},
//     ],
//     "Special Music": [
//       {"image": Assets.musicHealingMusic, "name": "Candlelight Relax", "duration": "40 MIN"},
//       {"image": Assets.musicHealingMusic1, "name": "Sunset Mind", "duration": "50 MIN"},
//       {"image": Assets.musicNaturalMelody, "name": "Sleep Boost", "duration": "60 MIN"},
//     ],
//   };
//   List<int> presetTimes = [15, 30, 45, 60, 90];
//
//   // Combines all tabs/filters into one page structure
//   late final List<Map<String, String>> combinedPages = _buildPages();
//
//   List<Map<String, String>> _buildPages() {
//     final result = <Map<String, String>>[];
//     for (final tab in tabOrder) {
//       for (final filter in tabFilters[tab]!) {
//         result.add({"tab": tab, "filter": filter});
//       }
//     }
//     return result;
//   }
//
//   Map<String, String> pageAt(int index) => combinedPages[index];
//
//   int globalIndexFor(String tab, String filter) {
//     return combinedPages.indexWhere((page) => page["tab"] == tab && page["filter"] == filter);
//   }
//
//   List<Map<String, String>> soundsFor(String tab, String filter) {
//     if (tab == "White Noise" && filter == "All") {
//       return soundLibrary["All"]!;
//     }
//     if (soundLibrary.containsKey(filter)) {
//       return soundLibrary[filter]!;
//     }
//     return [];
//   }
//
//   void onGlobalPageChanged(int index) {
//     final page = pageAt(index);
//     final newTab = page["tab"]!;
//     final newFilter = page["filter"]!;
//
//     // 🔥 Force reactive refresh
//     if (selectedTopTab.value != newTab) {
//       selectedTopTab.value = newTab;
//     } else {
//       selectedTopTab.refresh();
//     }
//
//     if (selectedFilter.value != newFilter) {
//       selectedFilter.value = newFilter;
//     } else {
//       selectedFilter.refresh();
//     }
//   }
//
//   bool isMusic(String name) {
//     // All music-related categories
//     final musicCategories = ["Healing Music", "Nature Melodies", "Lullaby", "Meditation Music", "Binaural Beats", "Special Music"];
//
//     // Combine all names from those categories
//     final musicNames = musicCategories.where((key) => soundLibrary.containsKey(key)).expand((key) => soundLibrary[key]!).map((e) => e["name"]).toList();
//
//     return musicNames.contains(name);
//   }
// // --- SOUND HANDLING ---
//
//
//   Future<void> _stopSound(String name) async {
//     final player = _soundPlayers[name];
//     if (player != null) {
//       await player.stop();
//       await player.dispose();
//       _soundPlayers.remove(name);
//     }
//
//     playingSounds.remove(name);
//     soundVolumes.remove(name);
//
//     if (playingSounds.isEmpty && playingMusic.isEmpty) stopTimer();
//
//     playingSounds.refresh();
//     soundVolumes.refresh();
//
//     debugPrint("🛑 Stopped sound: $name");
//   }
//
//   void updateSoundVolume(String name, double volume) {
//     soundVolumes[name] = volume;
//     _soundPlayers[name]?.setVolume(volume);
//     soundVolumes.refresh();
//   }
//   // Future<void> toggleSound(String name) async {
//   //   if (isMusic(name)) {
//   //     toggleMusic(name);
//   //     return;
//   //   }
//   //
//   //   // If already playing → stop
//   //   if (playingSounds.contains(name)) {
//   //     await _stopSound(name);
//   //     return;
//   //   }
//   //
//   //   // Limit max 10
//   //   if (playingSounds.length >= 10) {
//   //     Get.snackbar(
//   //       "Limit Reached",
//   //       "You can select up to 10 sounds only.",
//   //       snackPosition: SnackPosition.BOTTOM,
//   //       backgroundColor: Colors.white10,
//   //       colorText: Colors.white,
//   //     );
//   //     return;
//   //   }
//   //
//   //   // Create new player for sound
//   //   final player = AudioPlayer();
//   //   _soundPlayers[name] = player;
//   //
//   //   // Example: asset path mapping (you can adjust folder & naming)
//   //   // final assetPath = 'assets/audio/sounds/${name.toLowerCase().replaceAll(' ', '_')}.mp3';
//   //   final assetPath = _getAssetPathForSound(name);
//   //
//   //   if (assetPath == null) {
//   //     debugPrint("⚠️ No asset found for sound '$name'");
//   //     return;
//   //   }
//   //
//   //   try {
//   //     await player.setAsset(assetPath);
//   //     await player.setLoopMode(LoopMode.all);
//   //     await player.setVolume(soundVolumes[name] ?? 0.5);
//   //     await player.play();
//   //
//   //     playingSounds.add(name);
//   //     soundVolumes[name] = 0.5;
//   //
//   //     if (!isRunning.value) startTimer();
//   //   } catch (e) {
//   //     debugPrint("⚠️ Failed to play sound '$name': $e");
//   //   }
//   //
//   //   playingSounds.refresh();
//   //   soundVolumes.refresh();
//   // }
//   void toggleSound(String name) async{
//     // ✅ Ignore if the selected item is actually a music track
//     if (isMusic(name)) {
//       toggleMusic(name);
//       return;
//     }
//     if (playingSounds.contains(name)) {
//       playingSounds.remove(name);
//       soundVolumes.remove(name);
//       if (playingSounds.isEmpty && playingMusic.isEmpty) stopTimer();
//     } else {
//       if (playingSounds.length >= 10) {
//         Get.snackbar("Limit Reached", "You can select up to 10 sounds only.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white10, colorText: Colors.white);
//         return;
//       }
//       playingSounds.add(name);
//       soundVolumes[name] = 0.5;
//       if (!isRunning.value) startTimer();
//     }
//
//     playingSounds.refresh();
//     soundVolumes.refresh();
//   }
//
//
//   void clearAllSounds() {
//     playingSounds.clear();
//     soundVolumes.clear();
//     print("isRunning.value${isRunning.value}");
//     // 🕒 Stop timer if running
//     if (isRunning.value) {
//       stopTimer();
//     }
//
//     // 🔄 Refresh observables
//     playingSounds.refresh();
//     soundVolumes.refresh();
//   }
//
//   /// 🔊 For music playback
//   RxSet<String> playingMusic = <String>{}.obs;
//   RxMap<String, double> musicVolumes = <String, double>{}.obs;
//
//   void toggleMusic(String name) {
//     // ✅ Only one music allowed
//     if (playingMusic.contains(name)) {
//       playingMusic.remove(name);
//       musicVolumes.remove(name);
//       if (playingMusic.isEmpty && playingSounds.isEmpty) stopTimer();
//     } else {
//       // replace existing music
//       if (playingMusic.isNotEmpty) {
//         final prev = playingMusic.first;
//         playingMusic.remove(prev);
//         musicVolumes.remove(prev);
//       }
//
//       playingMusic.add(name);
//       musicVolumes[name] = 0.5;
//       if (!isRunning.value) startTimer();
//     }
//
//     playingMusic.refresh();
//     musicVolumes.refresh();
//   }
// // --- MUSIC HANDLING ---
// //   Future<void> toggleMusic(String name) async {
// //     // Stop previous
// //     for (final player in _musicPlayers.values) {
// //       await player.stop();
// //       await player.dispose();
// //     }
// //     _musicPlayers.clear();
// //     playingMusic.clear();
// //     musicVolumes.clear();
// //
// //     // If same pressed → stop
// //     if (playingMusic.contains(name)) {
// //       stopTimer();
// //       return;
// //     }
// //
// //     final player = AudioPlayer();
// //     _musicPlayers[name] = player;
// //    // final assetPath = 'assets/audio/music/${name.toLowerCase().replaceAll(' ', '_')}.mp3';
// //     final assetPath = _getAssetPathForSound(name);
// //
// //     if (assetPath == null) {
// //       debugPrint("⚠️ No asset found for sound '$name'");
// //       return;
// //     }
// //
// //     try {
// //       await player.setAsset(assetPath);
// //       await player.setLoopMode(LoopMode.all);
// //       await player.setVolume(0.5);
// //       await player.play();
// //
// //       playingMusic.add(name);
// //       musicVolumes[name] = 0.5;
// //       if (!isRunning.value) startTimer();
// //     } catch (e) {
// //       debugPrint("⚠️ Failed to play music '$name': $e");
// //     }
// //
// //     playingMusic.refresh();
// //     musicVolumes.refresh();
// //   }
//   void updateMusicVolume(String name, double volume) {
//     musicVolumes[name] = volume;
//     _musicPlayers[name]?.setVolume(volume);
//     musicVolumes.refresh();
//   }
//
//   void clearAllMusic() {
//     playingMusic.clear();
//     musicVolumes.clear();
//     stopTimer();
//
//     playingMusic.refresh();
//     musicVolumes.refresh();
//   }
//
//   PageController pageController = PageController();
//
//   /// Jump to specific tab and filter
//   void jumpToTab(String tab, {String? filter}) {
//     // ✅ Ensure the pageController is initialized and has clients
//     if (pageController == null || !pageController.hasClients) {
//       pageController = PageController();
//     }
//
//     final index = globalIndexFor(tab, filter!);
//     if (index >= 0 && index < combinedPages.length) {
//       pageController.animateToPage(index, duration: const Duration(microseconds: 100), curve: Curves.easeInOut);
//     } else {
//       debugPrint("⚠️ jumpToTab: Invalid index for tab '$tab' filter '$filter'");
//     }
//   }
//
//   @override
//   void onInit() {
//     super.onInit();
//     pageController = PageController();
//
//   }
//
//   // inside SleepSoundController
//   RxString activeSheet = "none".obs;
//
//   void openBottomSheet(BuildContext context) {
//     if (playingSounds.isEmpty && playingMusic.isEmpty) return;
//     isBottomSheetOpen.value = true;
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       transitionAnimationController: AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 500)),
//       builder: (context) {
//         print("object");
//         return _AnimatedBottomSheetContent();
//       },
//     );
//   }
//
//   // /// Helper to clear all sounds
//   // void stopAll() {
//   //   playingSounds.clear();
//   //   soundVolumes.clear();
//   //   playingMusic.clear();
//   //   musicVolumes.clear();
//   //   playingSounds.refresh();
//   //   soundVolumes.refresh();
//   //   playingMusic.refresh();
//   //   musicVolumes.refresh();
//   //   isBottomSheetOpen.value = false;
//   //   stopTimer();
//   // }
// // --- STOP ALL ---
//   Future<void> stopAll() async {
//     for (final p in _soundPlayers.values) {
//       await p.stop();
//       await p.dispose();
//     }
//     for (final p in _musicPlayers.values) {
//       await p.stop();
//       await p.dispose();
//     }
//     _soundPlayers.clear();
//     _musicPlayers.clear();
//
//     playingSounds.clear();
//     soundVolumes.clear();
//     playingMusic.clear();
//     musicVolumes.clear();
//
//     isBottomSheetOpen.value = false;
//     stopTimer();
//
//     playingSounds.refresh();
//     playingMusic.refresh();
//   }
//   /// --- TIMER LOGIC ---
//
//   Duration totalDuration = const Duration(minutes: 30);
//   Rx<Duration> remaining = const Duration(minutes: 30).obs;
//   RxBool isRunning = false.obs;
//
//   Timer? _timer;
//   final TextEditingController mixNameController = TextEditingController(text: "Mix0");
//   final RxBool isTextNotEmpty = false.obs;
//
//   void startTimer() {
//     if (isRunning.value) return;
//     isRunning.value = true;
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (remaining.value.inSeconds > 0) {
//         remaining.value -= const Duration(seconds: 1);
//       } else {
//         stopTimer();
//       }
//     });
//   }
//
//   void stopTimer() {
//     _timer?.cancel();
//     isRunning.value = false;
//   }
//
//   void resetTimer(int minutes) {
//     stopTimer();
//     totalDuration = Duration(minutes: minutes);
//     remaining.value = totalDuration;
//     startTimer();
//   }
//
//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }
//
//   void openSaveMixBottomSheet(BuildContext context) {
//     if (playingSounds.isEmpty) return;
//
//     showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => const OpenSaveMixBottomSheet1());
//   }
//
//   // Add to SleepSoundController class (near other fields)
//   RxList<Map<String, dynamic>> savedMixes = <Map<String, dynamic>>[].obs;
//
//   // TextEditingController mixNameController = TextEditingController(text: "Mix0");
//   // RxBool isTextNotEmpty = false.obs;
//
//   // Call this when user taps Save in the Save Mix bottom sheet
//   void saveCurrentMix(BuildContext context) {
//     final mixName = mixNameController.text.trim();
//     if (mixName.isEmpty) {
//       print("⚠️ Mix name is empty — skipping save.");
//       return;
//     }
//
//     print("💾 Trying to save mix: $mixName");
//
//     final nameExists = savedMixes.any((mix) => mix['name'] == mixName);
//     final contentExists = savedMixes.any((mix) {
//       final savedSounds = List<String>.from(mix['sounds'] ?? <String>[]);
//       final savedMusic = List<String>.from(mix['music'] ?? <String>[]);
//       return Set.from(savedSounds).containsAll(playingSounds) &&
//           Set.from(playingSounds).containsAll(savedSounds) &&
//           Set.from(savedMusic).containsAll(playingMusic) &&
//           Set.from(playingMusic).containsAll(savedMusic);
//     });
//
//     if (nameExists) {
//       print("🚫 Mix name already exists: $mixName");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             "A mix with this name already exists.",
//             style: TextStyle(color: Colors.white, fontSize: 14),
//           ),
//           backgroundColor: Colors.white10,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//
//     if (contentExists) {
//       print("⚠️ Mix content already saved (duplicate mix).");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             "This exact mix is already saved.",
//             style: TextStyle(color: Colors.white, fontSize: 14),
//           ),
//           backgroundColor: Colors.white10,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//
//     final mixData = {
//       'name': mixName,
//       'sounds': playingSounds.toList(),
//       'music': playingMusic.toList(),
//       'createdAt': DateTime.now().toIso8601String(),
//     };
//
//     savedMixes.add(mixData);
//     mixNameController.clear();
//     isTextNotEmpty.value = false;
//
//     print("✅ Mix saved successfully: $mixName");
//     print("🎵 Sounds: ${mixData['sounds']}");
//     print("🎧 Music: ${mixData['music']}");
//     print("📦 Total saved mixes: ${savedMixes.length}");
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Mix '$mixName' saved successfully!"),
//         backgroundColor: Colors.white10,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
//
//   void restoreMix(List<String> sounds, List<String> music) {
//     // 🧹 Clear all currently active sounds & music
//     clearAllSounds();
//
//     // 🎵 Restore sounds
//     for (final s in sounds) {
//       if (!playingSounds.contains(s)) {
//         toggleSound(s);
//       }
//     }
//
//     // 🎶 Restore music
//     playingMusic.clear();
//     musicVolumes.clear();
//
//     if (music.isNotEmpty) {
//       final m = music.first;
//       playingMusic.add(m);
//       musicVolumes[m] = 0.5;
//     }
//
//     // ✅ Refresh all reactive lists
//     playingSounds.refresh();
//     playingMusic.refresh();
//     musicVolumes.refresh();
//
//     if (!isRunning.value) startTimer();
//   }
//   String? _getAssetPathForSound(String name) {
//     for (final entry in soundLibrary.entries) {
//       for (final sound in entry.value) {
//         if (sound['name'] == name && sound.containsKey('asset')) {
//           return sound['asset'];
//         }
//       }
//     }
//     return null;
//   }
//
// }
//
// class BlueCenterThumbShape extends SliderComponentShape {
//   const BlueCenterThumbShape();
//
//   @override
//   Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);
//
//   @override
//   void paint(
//       PaintingContext context,
//       Offset center, {
//         required Animation<double> activationAnimation,
//         required Animation<double> enableAnimation,
//         required bool isDiscrete,
//         required TextPainter? labelPainter,
//         required RenderBox parentBox,
//         required SliderThemeData sliderTheme,
//         required TextDirection textDirection,
//         required double value,
//         required double textScaleFactor,
//         required Size sizeWithOverflow,
//       }) {
//     final Canvas canvas = context.canvas;
//
//     // Outer white circle
//     final Paint outerPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.fill;
//
//     // Inner blue dot
//     final Paint innerPaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;
//
//     // Draw outer white circle
//     canvas.drawCircle(center, 9, outerPaint);
//
//     // Draw inner blue dot (smaller)
//     canvas.drawCircle(center, 4, innerPaint);
//   }
// }
//
//
// class _AnimatedBottomSheetContent extends StatefulWidget {
//   @override
//   State<_AnimatedBottomSheetContent> createState() => _AnimatedBottomSheetContentState();
// }
//
// class _AnimatedBottomSheetContentState extends State<_AnimatedBottomSheetContent> {
//   final controller = Get.put(SleepSoundController());
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       curve: Curves.easeInOutCubic,
//       height: MediaQuery.of(context).size.height * 0.75,
//       decoration: const BoxDecoration(
//         color: Color(0xFF0A152F),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.only(left: 12, right: 12, top: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ─────────── FIXED HEADER ───────────
//           Row(
//             children: [
//               GestureDetector(
//                 onTap: () => Get.back(),
//                 child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 38),
//               ),
//               const Spacer(),
//               GestureDetector(
//                 onTap: () {
//                   controller.stopAll();
//                   Get.back();
//                 },
//                 child: Text(
//                   "Clear All",
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueAccent, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
//                 ).paddingOnly(right: 5),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//
//           // ─────────── SCROLLABLE BODY ───────────
//           Expanded(
//             child: SingleChildScrollView(
//               // physics: const BouncingScrollPhysics(),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(left: 8),
//                     child: Obx(() {
//                       final filteredSounds = controller.playingSounds.where((name) => !controller.isMusic(name)).toList();
//                       final total = filteredSounds.length;
//
//                       const maxSounds = 10;
//
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // 🔹 Header row
//                           Row(
//                             children: [
//                               Image.asset(Assets.homeSoundWaves, color: AppColors.white, fit: BoxFit.cover, width: 20, height: 20),
//                               // const Icon(Icons.music_note, color: Colors.white70, size: 18),
//                               const SizedBox(width: 5),
//                               Text(
//                                 "Sounds ($total/$maxSounds)",
//                                 style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
//                               ),
//                             ],
//                           ),
//
//                           const SizedBox(height: 12),
//
//                           // 🔹 Condition: No sounds → show empty state
//                           if (filteredSounds.isEmpty) ...[
//                             Text(
//                               "There is no sound in this mix",
//                               style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
//                             ),
//                             const SizedBox(height: 16),
//                             GestureDetector(
//                               onTap: () {
//                                 Get.back();
//                                 // Jump directly to Music tab
//                                 Future.delayed(const Duration(microseconds: 100), () {
//                                   controller.jumpToTab("White Noise", filter: "All");
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const Icon(Icons.add, color: Colors.white, size: 18),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       "Add Sound",
//                                       style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ] else ...[
//                             // 🔹 Sound list
//                             Column(
//                               children: filteredSounds.map((name) {
//                                 final icon = controller.soundLibrary.values.expand((list) => list).firstWhere((s) => s['name'] == name, orElse: () => {'icon': '🎵'})['icon'];
//
//                                 return Padding(
//                                   padding: const EdgeInsets.symmetric(vertical: 6),
//                                   child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundColor: Colors.white10,
//                                         radius: 26,
//                                         child: Text(icon ?? '🎵', style: const TextStyle(fontSize: 22)),
//                                       ),
//                                       Expanded(
//                                         child: Padding(
//                                           padding: const EdgeInsets.only(left: 18),
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Padding(
//                                                 padding: const EdgeInsets.only(left: 12, bottom: 8),
//                                                 child: Text(
//                                                   name,
//                                                   style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
//                                                 ),
//                                               ),
//                                               SliderTheme(
//                                                 data: SliderThemeData(trackHeight: 3, thumbShape: const BlueCenterThumbShape(), overlayShape: SliderComponentShape.noOverlay),
//                                                 child: Slider(
//                                                   activeColor: Colors.blue,
//                                                   inactiveColor: Colors.white24,
//                                                   value: controller.soundVolumes[name] ?? 0.5,
//                                                   onChanged: (val) {
//                                                     controller.updateSoundVolume(name, val);
//                                                     controller.soundVolumes[name] = val;
//                                                     controller.soundVolumes.refresh();
//                                                   },
//                                                   // onChanged: (v) => controller.updateSoundVolume(name, v),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(left: 8, top: 20),
//                                         child: IconButton(
//                                           icon: const Icon(Icons.delete_outline_outlined, color: Colors.white70, size: 28),
//                                           onPressed: () {
//                                             controller.playingSounds.remove(name);
//                                             controller.playingSounds.refresh();
//                                             if (controller.playingSounds.isEmpty) {
//                                               Get.back();
//                                             }
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           ],
//                         ],
//                       );
//                     }),
//                   ),
//
//                   const SizedBox(height: 20),
//                   const Divider(color: Colors.white12, thickness: 1),
//                   const SizedBox(height: 18),
//
//                   Padding(
//                     padding: const EdgeInsets.only(left: 8),
//                     child: Obx(() {
//                       final totalMusic = controller.playingMusic.length;
//                       const maxMusic = 1;
//
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // 🔹 Header
//                           Row(
//                             children: [
//                               const Icon(Icons.music_note, color: Colors.white70, size: 18),
//
//                               //Image.asset(Assets.homeSoundWaves, color: AppColors.white,fit: BoxFit.cover, width: 20, height: 20),
//                               const SizedBox(width: 5),
//                               Text(
//                                 "Music ($totalMusic/$maxMusic)",
//                                 style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
//                               ),
//                             ],
//                           ),
//
//                           const SizedBox(height: 12),
//
//                           // 🔹 If no music added
//                           if (controller.playingMusic.isEmpty) ...[
//                             Text(
//                               "There is no music in this mix",
//                               style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700, fontSize: 12 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
//                             ),
//                             const SizedBox(height: 16),
//                             GestureDetector(
//                               onTap: () {
//                                 Get.back();
//                                 // Jump directly to Music tab
//                                 Future.delayed(const Duration(microseconds: 100), () {
//                                   controller.jumpToTab("Music", filter: "Healing Music");
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const Icon(Icons.add, color: Colors.white, size: 18),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       "Add Music",
//                                       style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w500),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ] else ...[
//                             // 🔹 Show single music item
//                             Column(
//                               children: controller.playingMusic.map((musicName) {
//                                 final icon = controller.soundLibrary.values.expand((list) => list).firstWhere((s) => s['name'] == musicName, orElse: () => {'icon': '🎶'})['icon'];
//
//                                 return Padding(
//                                   padding: const EdgeInsets.symmetric(vertical: 6),
//                                   child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundColor: Colors.white10,
//                                         radius: 26,
//                                         child: Text(icon ?? '🎶', style: const TextStyle(fontSize: 22)),
//                                       ),
//                                       Expanded(
//                                         child: Padding(
//                                           padding: const EdgeInsets.only(left: 18),
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Padding(
//                                                 padding: const EdgeInsets.only(left: 12, bottom: 8),
//                                                 child: Text(
//                                                   musicName,
//                                                   style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
//                                                 ),
//                                               ),
//                                               SliderTheme(
//                                                 data: SliderThemeData(trackHeight: 3, thumbShape: const BlueCenterThumbShape(), overlayShape: SliderComponentShape.noOverlay),
//                                                 child: Slider(
//                                                   activeColor: Colors.blueAccent,
//                                                   inactiveColor: Colors.white24,
//                                                   value: controller.musicVolumes[musicName] ?? 0.5,
//                                                   onChanged: (val) {
//                                                     controller.musicVolumes[musicName] = val;
//                                                     controller.musicVolumes.refresh();
//                                                   },
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(left: 8, top: 20),
//                                         child: IconButton(
//                                           icon: const Icon(Icons.delete_outline_outlined, color: Colors.white70, size: 28),
//                                           onPressed: () {
//                                             controller.playingMusic.remove(musicName);
//                                             controller.playingMusic.refresh();
//                                             if (controller.playingMusic.isEmpty && controller.playingSounds.isEmpty) {
//                                               print(controller.playingMusic.isEmpty);
//                                               print(controller.playingSounds.isEmpty);
//                                               controller.isBottomSheetOpen.value = false;
//                                               Get.back();
//                                             }
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           ],
//                         ],
//                       );
//                     }),
//                   ),
//
//                   const SizedBox(height: 20),
//                   const Divider(color: Colors.white12, thickness: 1),
//                   const SizedBox(height: 18),
//
//                   // Bottom buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       TimerCircle(),
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             width: 74,
//                             height: 74,
//                             decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
//                             child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text("", style: TextStyle(fontSize: 13)),
//                         ],
//                       ),
//                       Obx(() {
//                         // Dynamically check if current mix is already saved
//                         final alreadySaved = controller.savedMixes.any((mix) {
//                           final savedSounds = List<String>.from(mix['sounds'] ?? <String>[]);
//                           final savedMusic = List<String>.from(mix['music'] ?? <String>[]);
//                           return Set.from(savedSounds).containsAll(controller.playingSounds) &&
//                               Set.from(controller.playingSounds).containsAll(savedSounds) &&
//                               Set.from(savedMusic).containsAll(controller.playingMusic) &&
//                               Set.from(controller.playingMusic).containsAll(savedMusic);
//                         });
//
//                         return GestureDetector(
//                           onTap: () {
//                             if (alreadySaved) {
//                               showDialog(
//                                 context: context,
//                                 builder: (context) {
//                                   return GiffyDialog(
//                                     key: const Key("RemoveMixDialog"),
//
//                                     giffy: Lottie.asset(
//                                       height: 250,
//                                       Assets.lottieSleep,
//                                       fit: BoxFit.fill,
//                                       repeat: true,
//                                     ),
//
//                                     title: const Text(
//                                       'Remove Mix?',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w700,
//                                         fontSize: 20,
//                                       ),
//                                     ),
//
//                                     content: const Text(
//                                       'Are you sure you want to delete this mix?',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(color: Colors.white70, fontSize: 16),
//                                     ),
//
//                                     actionsAlignment: MainAxisAlignment.center,
//                                     backgroundColor: const Color(0xFF1E1E1E),
//
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(context),
//                                         child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
//                                       ),
//                                       ElevatedButton(
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.pinkAccent,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                         ),
//                                         onPressed: () {
//                                           Navigator.pop(context);
//
//                                           // 🔥 Remove mix logic
//                                           controller.savedMixes.removeWhere((mix) {
//                                             final savedSounds = List<String>.from(mix['sounds'] ?? <String>[]);
//                                             final savedMusic = List<String>.from(mix['music'] ?? <String>[]);
//                                             return Set.from(savedSounds).containsAll(controller.playingSounds) &&
//                                                 Set.from(controller.playingSounds).containsAll(savedSounds) &&
//                                                 Set.from(savedMusic).containsAll(controller.playingMusic) &&
//                                                 Set.from(controller.playingMusic).containsAll(savedMusic);
//                                           });
//                                           controller.savedMixes.refresh();
//
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(
//                                               content: const Text(
//                                                 "Mix removed successfully",
//                                                 style: TextStyle(color: Colors.white),
//                                               ),
//                                               backgroundColor: Colors.white10,
//                                               behavior: SnackBarBehavior.floating,
//                                               margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                               duration: const Duration(seconds: 2),
//                                             ),
//                                           );
//                                         },
//                                         child: const Text('Yes, Remove', style: TextStyle(color: Colors.white)),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//                             } else {
//                               // 🔹 Save new mix
//                               controller.openSaveMixBottomSheet(context);
//                               controller.mixNameController.text = "Mix${controller.savedMixes.length}";
//                               controller.isTextNotEmpty.value = true;
//                             }
//                           },
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 74,
//                                 height: 74,
//                                 decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
//                                 child: Icon(
//                                   alreadySaved ? Icons.favorite : Icons.favorite_border,
//                                   color: alreadySaved ? Colors.pinkAccent : Colors.white,
//                                   size: 28,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 alreadySaved ? "Remove Mix" : "Save Mix",
//                                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                   color: AppColors.starColor,
//                                   fontSize: 16 * SizeConfigs.textScale,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//
//                         //   GestureDetector(
//                         //   onTap: () {
//                         //     if (alreadySaved) {
//                         //       // 🔸 Remove the mix if already saved
//                         //       controller.savedMixes.removeWhere((mix) {
//                         //         final savedSounds = List<String>.from(mix['sounds'] ?? <String>[]);
//                         //         final savedMusic = List<String>.from(mix['music'] ?? <String>[]);
//                         //         return Set.from(savedSounds).containsAll(controller.playingSounds) &&
//                         //             Set.from(controller.playingSounds).containsAll(savedSounds) &&
//                         //             Set.from(savedMusic).containsAll(controller.playingMusic) &&
//                         //             Set.from(controller.playingMusic).containsAll(savedMusic);
//                         //       });
//                         //       controller.savedMixes.refresh();
//                         //
//                         //       ScaffoldMessenger.of(context).showSnackBar(
//                         //         SnackBar(
//                         //           content: const Text("Mix removed successfully", style: TextStyle(color: Colors.white)),
//                         //           backgroundColor: Colors.white10,
//                         //           behavior: SnackBarBehavior.floating,
//                         //           margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//                         //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         //           duration: const Duration(seconds: 2),
//                         //         ),
//                         //       );
//                         //     } else {
//                         //       // 🔹 Save the new mix
//                         //       controller.openSaveMixBottomSheet(context);
//                         //       controller.mixNameController.text = "Mix${controller.savedMixes.length}";
//                         //       controller.isTextNotEmpty.value = true;
//                         //     }
//                         //   },
//                         //   child: Column(
//                         //     mainAxisSize: MainAxisSize.min,
//                         //     children: [
//                         //       Container(
//                         //         width: 74,
//                         //         height: 74,
//                         //         decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
//                         //         child: Icon(
//                         //           alreadySaved ? Icons.favorite : Icons.favorite_border,
//                         //           color: alreadySaved ? Colors.pinkAccent : Colors.white,
//                         //           size: 28,
//                         //         ),
//                         //       ),
//                         //       const SizedBox(height: 8),
//                         //       Text(
//                         //         alreadySaved ? "Remove Mix" : "Save Mix",
//                         //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         //           color: AppColors.starColor,
//                         //           fontSize: 16 * SizeConfigs.textScale,
//                         //           fontWeight: FontWeight.w600,
//                         //         ),
//                         //       ),
//                         //     ],
//                         //   ),
//                         // );
//                       })
//
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class OpenSaveMixBottomSheet1 extends StatefulWidget {
//   const OpenSaveMixBottomSheet1({super.key});
//
//   @override
//   State<OpenSaveMixBottomSheet1> createState() => _OpenSaveMixBottomSheet1State();
// }
//
// class _OpenSaveMixBottomSheet1State extends State<OpenSaveMixBottomSheet1> {
//   final controller = Get.find<SleepSoundController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(microseconds: 100),
//       curve: Curves.easeInOutCubic,
//       height: MediaQuery.of(context).size.height * 0.75,
//       decoration: const BoxDecoration(
//         color: Color(0xFF0A152F),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Align(
//             alignment: Alignment.topLeft,
//             child: GestureDetector(
//               onTap: () => Get.back(),
//               child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 36),
//             ),
//           ),
//           const SizedBox(height: 10),
//
//           const Text(
//             "Save this Mix",
//             style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 24),
//
//           Obx(() {
//             final selected = controller.playingSounds.toList();
//             return Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 16,
//               runSpacing: 16,
//               children: selected.map((name) {
//                 final icon = controller.soundLibrary.values.expand((list) => list).firstWhere((s) => s['name'] == name, orElse: () => {'icon': '🎵'})['icon'];
//
//                 return CircleAvatar(
//                   radius: 26,
//                   backgroundColor: Colors.white12,
//                   child: Text(icon ?? '🎵', style: const TextStyle(fontSize: 22)),
//                 );
//               }).toList(),
//             );
//           }),
//
//           const SizedBox(height: 30),
//
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             decoration: const BoxDecoration(
//               border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
//             ),
//             child: TextField(
//               controller: controller.mixNameController,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.white, fontSize: 16),
//               onChanged: (value) {
//                 controller.isTextNotEmpty.value = value.trim().isNotEmpty;
//               },
//               decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
//             ),
//           ),
//
//           const SizedBox(height: 18),
//           Text(
//             "Choose a name for this mix",
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.starColor, fontSize: 16 * SizeConfigs.textScale, fontWeight: FontWeight.w100),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 40),
//
//           Obx(
//                 () => SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: controller.isTextNotEmpty.value
//                     ? () {
//                   print("save mix");
//                   controller.saveCurrentMix(context);
//                   Get.back(); // Close bottom sheet
//                 }
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: controller.isTextNotEmpty.value ? AppColors.blueColor : AppColors.card,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
//                 ),
//                 child: const Text(
//                   "Save",
//                   style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
