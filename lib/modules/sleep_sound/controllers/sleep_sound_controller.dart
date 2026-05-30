import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/shared_prefences.dart';
import '../../../core/utils/library.dart';
import '../../../data/models/common_model.dart';
import '../../../data/services/api_end_point.dart';
import '../../../data/services/api_sevices.dart';
import '../../../data/services/network_utils.dart';
import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../alarm/controllers/alarm_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../model/SoundItem.dart';
import '../model/sound_category_model.dart';
import '../model/sound_sub_category_model.dart';
import '../model/sounds_mixed_list_model.dart';
import '../widget/PlayerFullSheetUI.dart';
import '../widget/Sound_bootom_sheet widget.dart';

enum StopReason { userClose, timerFinished, systemCleanup }

class SleepSoundController extends GetxController {
  RxString selectedCategorySlug = ''.obs;
  RxString selectedSubCategorySlug = ''.obs;
  final RxList<SoundCategory> tabOrder = <SoundCategory>[].obs;
  final List<SoundItem> allSounds = [];

  /// 🎚️ VOLUME
  RxMap<int, double> soundVolumes = <int, double>{}.obs;
  RxMap<int, double> musicVolumes = <int, double>{}.obs;
  RxList<SoundItem> playingSounds = <SoundItem>[].obs;
  RxList<SoundItem> playingMusic = <SoundItem>[].obs;

  // For display only, you can keep names or assets if you need
  RxList<String> playingMusicLocale = <String>[].obs;
  late final AudioPlayer musicPlayer;

  // 🌊 Multiple sound players
  final Map<int, AudioPlayer> soundPlayers = {};

  static const String allSubSlug = "__all__";

  /// ⏱️ TIMER / UI
  RxBool isRunning = false.obs;
  RxBool isBottomSheetOpen = false.obs;

  /// Example mock data for sounds

  RxBool isClosingMode = false.obs;
  RxBool showMixBar = true.obs;
  RxBool isMusicPlaying = false.obs;
  RxBool isLiked = false.obs;

  List<int> presetTimes = [15, 30, 45, 60, 90];
  final RxMap<String, List<SoundSubCategory>> subCategoryMap = <String, List<SoundSubCategory>>{}.obs;
  final RxMap<String, List<SoundItem>> soundsBySubCategory = <String, List<SoundItem>>{}.obs;

  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingSubCategories = false.obs;
  final RxBool isLoadingSounds = false.obs;

  // Combines all tabs/filters into one page structure
  final RxList<Map<String, String>> combinedPages = <Map<String, String>>[].obs;

  final RxInt currentPageIndex = 0.obs;
  // Inside SleepSoundController
  var scale = 1.0.obs;

  void updateScale(double value) {
    scale.value = value;
  }
  Future<void> fetchSoundCategories() async {
    try {
      isLoadingCategories.value = true;
      final res = await SoundsApis.fetchSoundCategories();
      tabOrder.assignAll(res.data);
    } catch (e) {
      debugPrint("Category API Error: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }
  Future<void> fetchSubCategories(String categorySlug) async {
    if (subCategoryMap.containsKey(categorySlug)) return;

    try {
      isLoadingSubCategories.value = true;

      final res = await SoundsApis.fetchSoundSubCategories(categorySlug: categorySlug);
      subCategoryMap[categorySlug] = res.data;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildPages(); // update combinedPages after fetching
      });

      // ❌ Don't force selectedCategorySlug/subCategorySlug here
    } catch (e) {
      debugPrint("SubCategory API Error: $e");
    } finally {
      isLoadingSubCategories.value = false;
    }
  }

  Future<void> toggleLike(SoundItem sound, String categorySlug, String subCategorySlug) async {
    final bool originalState = sound.isFavorite ?? false;
    final bool newState = !originalState;
    final isFavoritesTab = categorySlug.toLowerCase() == "favorites";

    try {
      // 1. Global Sync: Find this sound in EVERY subcategory and update it
      soundsBySubCategory.forEach((key, list) {
        for (var item in list) {
          if (item.id == sound.id) {
            item.isFavorite = newState;
          }
        }
      });

      // 2. Immediate Removal: If in Favorites tab and un-liked, remove it
      if (isFavoritesTab && newState == false) {
        final key = soundKey(categorySlug, subCategorySlug);
        soundsBySubCategory[key]?.removeWhere((element) => element.id == sound.id);
      }

      // 3. Trigger UI update across all observers
      soundsBySubCategory.refresh();

      // 4. API Call
      final response = await SoundsApis.toggleFavorite(soundId: sound.id);

      if (response.success != true) {
        throw Exception("API Failed"); // Trigger the catch block for rollback
      }else {
        _fetchAllFavorites("favorites");
      }
    } catch (e) {
      // Rollback: Revert the state globally
      soundsBySubCategory.forEach((key, list) {
        for (var item in list) {
          if (item.id == sound.id) {
            item.isFavorite = originalState;
          }
        }
      });

      // If we were in favorites and un-liked, we might need to re-fetch to restore the item
      if (isFavoritesTab) {
        await fetchSounds(categorySlug, subCategorySlug);
      }

      soundsBySubCategory.refresh();
      Get.snackbar("Error", "Could not update favorite. Please check your connection.");
      debugPrint("❌ Toggle Like Error: $e");
    }
  }

  Future<List<SoundItem>> _fetchSubCategoryWithPagination(String cat, String sub) async {
    List<SoundItem> results = [];
    int page = 1;
    int total = 1;

    try {
      do {
        final resp = await SoundsApis.fetchSoundsRaw(
            categorySlug: cat,
            subCategorySlug: sub,
            page: page
        );

        final data = resp['data'];

        // ✅ FIX: Check if data is a Map before accessing 'records'
        if (data is Map<String, dynamic> && data.containsKey('records')) {
          final List records = data['records'] ?? [];

          results.addAll(records.map((e) => SoundItem.fromJson(e)).toList());

          total = data['total_pages'] ?? 1;
          page++;
        } else {
          // If data is [] (List) or null, there are no more sounds. Break the loop.
          debugPrint("ℹ️ End of data or empty list for $sub");
          break;
        }
      } while (page <= total);
    } catch (e) {
      debugPrint("❌ Pagination Error in $sub: $e");
    }

    return results;
  }


  Future<void> _fetchAllSubCategorySounds(String categorySlug) async {
    final key = soundKey(categorySlug, allSubSlug);

    // 1. Get all actual subcategory slugs for this category
    final subs = subCategoryMap[categorySlug] ?? [];
    final List<SoundItem> mergedItems = [];

    // 2. Fetch each subcategory's data
    for (final s in subs) {
      if (s.slug == allSubSlug) continue; // Skip itself

      // Check if we already have these sounds in memory to avoid API calls
      final subKey = soundKey(categorySlug, s.slug);
      if (soundsBySubCategory.containsKey(subKey)) {
        mergedItems.addAll(soundsBySubCategory[subKey]!);
      } else {
        // If not in memory, fetch them (pagination logic)
        final items = await _fetchSubCategoryWithPagination(categorySlug, s.slug);
        soundsBySubCategory[subKey] = items;
        mergedItems.addAll(items);
      }
    }

    // 3. Update the "All" key with the merged list
    soundsBySubCategory[key] = mergedItems;
    soundsBySubCategory.refresh();
  }

  Future<void> _preloadPageSounds(List<SoundItem> sounds) async {
    // Limit preload to only first 5 sounds to save RAM and Network
    final limitedSounds = sounds.take(5).toList();

    for (var sound in limitedSounds) {
      if (!soundPlayers.containsKey(sound.id)) {
        final player = AudioPlayer(handleAudioSessionActivation: false);
        soundPlayers[sound.id] = player;

        try {
          // 🔥 Sequential loading with timeout protection
          await player.setUrl(sound.file, preload: true)
              .timeout(const Duration(seconds: 10));

          player.setLoopMode(LoopMode.one);
          player.setVolume(0.5);

          // Small gap between loads to let the UI breathe
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint("Silent preload failed for ${sound.name}: $e");
          // Clean up failed player to free memory
          await player.dispose();
          soundPlayers.remove(sound.id);
        }
      }
    }
  }
  final RxMap<String, bool> isCacheLoaded = <String, bool>{}.obs;
  void _preloadPageImages(List<SoundItem> sounds) {
    for (var sound in sounds) {
      if (sound.image.isNotEmpty) {
        // This "warms up" the image in the background
        precacheImage(
            CachedNetworkImageProvider(
              sound.image,
              // Force a smaller size in memory to prevent the cache from getting full
              maxWidth: 150,
              maxHeight: 150,
            ),
            Get.context!
        ).catchError((e) => debugPrint("Precache failed for ${sound.name}"));
      }
    }
  }


  Future<void> fetchSounds(String categorySlug, String subSlug) async {
    final cat = categorySlug.toLowerCase().trim();
    final sub = subSlug.toLowerCase().trim();
    final key = soundKey(categorySlug, subSlug);

    // 1. SILENT LOCK
    if (loadingKeys.contains(key)) return;

    // 2. HYDRATE
    if (!soundsBySubCategory.containsKey(key)) {
      await _hydrateFromCache(key);
    }

    // 3. SMART LOADER
    final bool hasCachedData = soundsBySubCategory.containsKey(key) &&
        soundsBySubCategory[key]!.isNotEmpty;

    if (!hasCachedData) {
      loadingKeys.add(key);
    }

    try {
      // --- 🔥 FIX 1: GLOBAL MIXES GUARD ---
      // Agar category 'mixes' hai, toh kabhi bhi step 4 (Standard API) par mat jao.
      if (cat == "mixes") {
        await fetchMixes();
        // Ensure UI knows we are done even if no sounds return
        if (!soundsBySubCategory.containsKey(key)) soundsBySubCategory[key] = [];
        return;
      }

      // --- SPECIAL CASES ---
      if (sub == allSubSlug) {
        await _fetchAllSubCategorySounds(categorySlug);
        return;
      }

      if (cat == "favorites") {
        await _fetchAllFavorites(subSlug);
        return;
      }

      // --- 4. ROBUST PAGINATION ---
      List<SoundItem> allItems = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final response = await SoundsApis.fetchSoundsRaw(
            categorySlug: categorySlug,
            subCategorySlug: sub,
            page: currentPage
        ).timeout(const Duration(seconds: 15)); // 🛡️ Timeout protection

        if (response != null && response['success'] == true) {
          final data = response['data'];

          if (data is Map<String, dynamic> && data.containsKey('records')) {
            final List records = data['records'] ?? [];
            allItems.addAll(records.map((e) => SoundItem.fromJson(e)).toList());

            totalPages = data['total_pages'] ?? 1;
            currentPage++;

            // 🔥 Performance Fix: Don't choke the thread
            await Future.delayed(const Duration(milliseconds: 50));
          } else {
            break;
          }
        } else {
          break;
        }
      } while (currentPage <= totalPages);

      // --- 5. ATOMIC UI UPDATE ---
      if (allItems.isNotEmpty) {
        final ids = <int>{};
        allItems.retainWhere((x) => ids.add(x.id));

        soundsBySubCategory[key] = allItems;
        _saveToCache(key, allItems);
        soundsBySubCategory.refresh();

        // --- 6. OPTIMIZED PRELOADING ---
        _preloadPageImages(allItems);

        // iOS Hang protection: sequential preload
        if (cat == "music" || cat == "story") {
          await _preloadPageSounds(allItems.take(3).toList());
        } else {
          // Sirf top 6 preload karein, poori list nahi
          await _preloadPageSounds(allItems.take(6).toList());
        }
      }
    } catch (e) {
      debugPrint("❌ fetchSounds Critical Error [$key]: $e");
    } finally {
      // 6. RELEASE LOCK
      loadingKeys.remove(key);
    }
  }
  Future<void> refreshCurrentTabSilently() async {
    // 1. Determine which category to refresh
    // Default to 'white-noise' if nothing is selected yet
    final category = selectedCategorySlug.value.isEmpty
        ? 'white-noise'
        : selectedCategorySlug.value;

    // 2. Fetch sub-categories in background (silent because we don't await/set loading flag)
    await fetchSubCategories(category);

    // 3. Determine sub-category
    String subCategory = selectedSubCategorySlug.value;
    if (subCategory.isEmpty) {
      final filters = getCurrentFilters(category);
      if (filters.isNotEmpty) subCategory = filters.first.slug;
    }

    if (subCategory.isNotEmpty) {
      // 🔥 THE TRICK: Call a version of fetchSounds that does NOT add to loadingKeys
      _fetchSoundsBackground(category, subCategory);
    }
  }
  Future<void> _fetchSoundsBackground(String cat, String sub) async {
    final key = soundKey(cat, sub);

    try {
      List<SoundItem> mergedItems = [];
      List<SoundSubCategory> targetFilters = [];

      if (sub == allSubSlug) {
        final Map<String, List<SoundSubCategory>> currentMap = subCategoryMap.value;
        targetFilters = (currentMap[cat] ?? [])
            .where((f) => f.slug != allSubSlug)
            .toList();
      } else {
        targetFilters = [SoundSubCategory(id: 0, name: "", slug: sub, category: 0)];
      }

      if (targetFilters.isEmpty) return;

      for (var filter in targetFilters) {
        if (isClosed) return; // Controller close ho gaya toh rukh jao

        // Category change hone par thoda lamba delay (600ms) taaki server chill rahe
        await Future.delayed(const Duration(milliseconds: 600));

        int currentPage = 1;
        int totalPages = 1;

        // --- PAGINATION LOOP START ---
        do {
          try {
            final response = await SoundsApis.fetchSoundsRaw(
              categorySlug: cat,
              subCategorySlug: filter.slug,
              page: currentPage, // 👈 Fix: Ab ye actual page number bhejega
            ).timeout(const Duration(seconds: 15));

            if (response == null || response['success'] != true) {
              debugPrint("⚠️ API Error on filter: ${filter.slug}. Skipping filter...");
              break;
            }

            final data = response['data'];
            if (data is Map<String, dynamic>) {
              totalPages = data['total_pages'] ?? 1;

              if (data['records'] is List) {
                final List records = data['records'];
                mergedItems.addAll(records.map((e) => SoundItem.fromJson(e)).toList());
              }
            } else {
              break; // Data empty hai toh loop se bahar
            }

            currentPage++;

            // Har page fetch ke baad chota delay (150ms) performance ke liye
            if (currentPage <= totalPages) {
              await Future.delayed(const Duration(milliseconds: 150));
            }

          } catch (e) {
            debugPrint("❌ Timeout/Error on page $currentPage of ${filter.slug}: $e");
            break; // Is filter ko chhod kar agle filter par jao
          }
        } while (currentPage <= totalPages);
        // --- PAGINATION LOOP END ---
      }

      // 3. UI Update (Atomic)
      if (mergedItems.isNotEmpty) {
        // Duplicate protection
        final ids = <int>{};
        mergedItems.retainWhere((x) => ids.add(x.id));

        soundsBySubCategory[key] = mergedItems;
        _saveToCache(key, mergedItems);
        soundsBySubCategory.refresh();

        print("✅ Background sync complete: ${mergedItems.length} sounds for $key");

        // Memory Optimization: Cleanup unused players after sync
        _cleanupUnusedPlayers();
      }
    } catch (e, stack) {
      debugPrint("❌ Background sync fatal failure: $e");
    }
  }
  // Sirf un players ko rakhein jo currently baj rahe hain (playingSounds)
// Baaki sab ko dispose karke memory free karein
  void _cleanupUnusedPlayers() {
    final playingIds = playingSounds.map((s) => s.id).toSet();

    soundPlayers.removeWhere((id, player) {
      if (!playingIds.contains(id)) {
        player.dispose(); // 🧹 Memory release
        return true;
      }
      return false;
    });
  }
  void _saveToCache(String key, List<SoundItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String rawJson = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('cache_sounds_$key', rawJson);
  }

  Future<void> _hydrateFromCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('cache_sounds_$key');

    if (cachedData != null) {
      try {
        final List decoded = jsonDecode(cachedData);
        final List<SoundItem> items = decoded.map((e) => SoundItem.fromJson(e)).toList();

        // Update the reactive map immediately
        soundsBySubCategory[key] = items;
        soundsBySubCategory.refresh();
        debugPrint("📦 Cached data restored for: $key");
      } catch (e) {
        debugPrint("Error decoding cache: $e");
      }
    }
  }
  /// Refactored Favorites to support Silent Refresh
  Future<void> _fetchAllFavorites(String subSlug) async {
    final key = soundKey("favorites", subSlug);

    // No need to add to loadingKeys here; fetchSounds handles the 'Empty' check.

    try {
      List<SoundItem> allFavs = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final response = await buildHttpResponse(
          endPoint: '${APIEndPoints.fetchFavoriteSounds}?page=$currentPage',
          method: MethodType.get,
        );

        final data = response['data'];
        if (data is Map<String, dynamic> && data['records'] is List) {
          final List records = data['records'];
          final pageItems = records.map((e) {
            return e['sound'] != null ? SoundItem.fromJson(e['sound']) : null;
          }).whereType<SoundItem>().toList();

          allFavs.addAll(pageItems);
          totalPages = data['total_pages'] ?? 1;
          currentPage++;
        } else {
          break;
        }
      } while (currentPage <= totalPages);

      soundsBySubCategory[key] = allFavs;
      soundsBySubCategory.refresh();
    } catch (e) {
      debugPrint("❌ _fetchAllFavorites Error: $e");
    }
  }
  List<SoundSubCategory> getCurrentFilters(String categorySlug) {
    final subs = subCategoryMap[categorySlug] ?? [];

    // 1. Define categories that should NOT have the "All" filter
    const excludedCategories = ["favorites", "mixes"];

    // 2. If it's an excluded category, just return the existing subcategories
    if (excludedCategories.contains(categorySlug.toLowerCase())) {
      debugPrint("🔍 [Filters] Skipping 'All' for specialized category: $categorySlug");
      return subs;
    }

    // 3. If already injected with "All", return as-is
    if (subs.isNotEmpty && subs.first.slug == allSubSlug) {
      return subs;
    }

    // 4. Inject "All" for standard categories
    return [
      SoundSubCategory(
        id: -1,
        name: "All",
        slug: allSubSlug,
        category: 0,
      ),
      ...subs,
    ];
  }


  void _rebuildPages() {
    final result = <Map<String, String>>[];

    for (final category in tabOrder) {
      final subs = getCurrentFilters(category.slug);

      for (final sub in subs) {
        result.add({"categorySlug": category.slug, "subCategorySlug": sub.slug});
      }
    }

    combinedPages.assignAll(result);
    debugPrint("✅ combinedPages rebuilt: ${combinedPages.length}");
  }

  Map<String, String> pageAt(int index) => combinedPages[index];

  int globalIndexFor(String categorySlug, String subSlug) {
    return combinedPages.indexWhere((p) => p["categorySlug"] == categorySlug && p["subCategorySlug"] == subSlug);
  }

  String soundKey(String categorySlug, String subCategorySlug) {
    return '$categorySlug::$subCategorySlug';
  }

  List<SoundItem> soundsFor(String category, String sub) {
    final key = soundKey(category, sub);
    return soundsBySubCategory[key] ?? [];
  }

  Future<void> onGlobalPageChanged(int index) async {
    currentPageIndex.value = index;
    final page = pageAt(index);
    final categorySlug = page["categorySlug"]!;
    final subSlug = page["subCategorySlug"]!;

    selectedCategorySlug.value = categorySlug;
    selectedSubCategorySlug.value = subSlug;

    await fetchSounds(categorySlug, subSlug);

    // Preload next category’s subcategories
    final nextIndex = index + 1;
    if (nextIndex < combinedPages.length) {
      final nextCategory = pageAt(nextIndex)["categorySlug"]!;
      if (!subCategoryMap.containsKey(nextCategory)) {
        fetchSubCategories(nextCategory); // fire & forget
      }
    }
  }

  final loadingKeys = <String>{}.obs;


  String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool hasRequested(String key) {
    return soundsBySubCategory.containsKey(key) || loadingKeys.contains(key);
  }

  Future<AudioPlayer> createPlayerForSound(SoundItem sound) async {
    final existing = soundPlayers[sound.id];
    if (existing != null) return existing;

    // Primary FIX: Session activation false rakhein
    final player = AudioPlayer(handleAudioSessionActivation: false);
    soundPlayers[sound.id] = player;

    try {
      // MediaItem ke bina setUrl use karein taaki background service ise ignore kare
      await player.setUrl(sound.file);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(soundVolumes[sound.id] ?? 0.5);
    } catch (e) {
      debugPrint("❌ Ambient Error: $e");
    }
    return player;
  }
  Future<void> clearAllSounds() async {
    for (final player in soundPlayers.values) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }

    soundPlayers.clear();
    playingSounds.clear();
    soundVolumes.clear();
  }

  final isAnyPlayerVisible = false.obs;

  Future<void> toggleMusic(SoundItem music) async {
    final int musicId = music.id;
    bool isSameMusic = playingMusic.any((m) => m.id == musicId);

    // 1. UPDATE UI STATE INSTANTLY (0ms Delay)
    _isToggling = true; // Lock the listener

    if (isSameMusic) {
      // Instant Stop UI
      playingMusic.clear();
      isMusicPlaying.value = false;
      isPaused.value = false;
      stopMusic(); // Background stop
      _isToggling = false;
      return;
    }

    // Instant Play UI
    playingMusic.assign(music);
    isMusicPlaying.value = true;
    isPaused.value = false;
    playingMusic.refresh();

    // 2. FIRE BACKGROUND AUDIO LOADER
    _loadAndPlayMusic(music);
    _updateSimpleTextNotification();
    // 3. RELEASE LOCK AFTER BUFFERING
    // Give the hardware 2 seconds to reach 'Ready' state
    Future.delayed(const Duration(seconds: 2), () {
      _isToggling = false;
    });
  }

  void _loadAndPlayMusic(SoundItem music) async {
    print("🎵 [MUSIC_DEBUG] 1. Initializing load for: ${music.name}");
    try {
      String audioUrl = music.file;
      if (!audioUrl.startsWith('http')) {
        audioUrl = "https://api.sleepable.ai$audioUrl";
      }
      print("🎵 [MUSIC_DEBUG] 2. URL formed: $audioUrl");

      await musicPlayer.setUrl(audioUrl,preload: true);

      // 🔥 iOS Fix: Wake up the hardware after network loading
      final session = await AudioSession.instance;
      await session.setActive(true);

      if (playingMusic.any((m) => m.id == music.id)) {
        double initialVolume = playingSounds.isEmpty ? 1.0 : 0.5;
        await musicPlayer.setVolume(initialVolume);

        print("🎵 [MUSIC_DEBUG] 3. Triggering hardware PLAY.");
        musicPlayer.play();

        syncVolumesAndLoop();
      }
    } catch (e) {
      print("❌ [MUSIC_ERROR] Load failed: $e");
      _isToggling = false;
    }
  }
  void _bindMusicListeners() {
    musicPlayer.positionStream.listen((pos) {
      currentPosition.value = pos; // 👈 Isse UI progress aage badhegi
    });

    musicPlayer.durationStream.listen((dur) {
      if (dur != null) totalDurationPosition.value = dur;
    });

    musicPlayer.playerStateStream.listen((state) async {
      if (_isToggling || state.processingState == ProcessingState.buffering) return;

      // Update Play/Pause UI
      isPaused.value = !state.playing;

      if (state.processingState == ProcessingState.completed) {
        if (isRepeatEnabled.value) {
          await musicPlayer.seek(Duration.zero);
          musicPlayer.play();
        } else {
          await skipNext();
        }
      }
    });
  }
  Future<void> stopMusic() async {
    try {
      await musicPlayer.stop();
      await musicPlayer.seek(Duration.zero);

      // Reset volume to 1.0 here so the NEXT song doesn't start at 0.0
      await musicPlayer.setVolume(1.0);

      playingMusic.clear();
      playingMusicLocale.clear();
      await FlutterLocalNotificationsPlugin().cancel(id:888);
      isMusicPlaying.value = false;
      isPaused.value = false; // Reset pause state for next session

      debugPrint("🎵 Music Stopped and State Cleared");
    } catch (e) {
      debugPrint("Error in stopMusic: $e");
    }
  }

  Future<void> clearAllMusic({Duration duration = const Duration(milliseconds: 800)}) async {
    if (!musicPlayer.playing) {
      _clearMusicState();
      return;
    }

    const int steps = 20;
    final stepTime = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final volume = 1 - (i / steps);
      await musicPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: stepTime));
    }

    await musicPlayer.stop();
    await musicPlayer.setVolume(0.5);

    _clearMusicState();
  }

  void _clearMusicState() {
    playingMusic.clear();
    playingMusicLocale.clear();
    musicVolumes.clear();

    playingMusic.refresh();
    musicVolumes.refresh();

    isMusicPlaying.value = false;
    isPaused.value = true;
  }
  final subController = Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : Get.put(SubscriptionController());

  @override
  void onInit() {
    print('--- on init ---');
    super.onInit();

    // 🟢 ADD THIS LINE: This stops just_audio from internally
    // pausing when it thinks another app (or your recorder) wants focus.
    musicPlayer = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    if (Platform.isIOS) {
      musicPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
    }
    _bindMusicListeners();
    resetTimer(0);
    _setupSteps();
    _preWarmCache();
    ever(subController.isPremium, (bool premium) {
      print("💎 Worker Triggered: Premium is $premium");

      // Jab status change ho, toh old memory clear karke re-fetch karein
      // Isse locked icons turant gayab honge
      soundsBySubCategory.clear();
      onSoundTabVisible();
    });
    _initializeData();
    checkTrackingStatus();
  }
  RxBool isTrackingActive = false.obs;
  Future<void> checkTrackingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Sync the reactive variable with SharedPreferences
    isTrackingActive.value = prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
  }
  Future<void> _preWarmCache() async {
    final prefs = await SharedPreferences.getInstance();

    // List the keys you want to be "Instant"
    // You might need to save a list of subcategory slugs to iterate here
    final cachedKeys = prefs.getKeys().where((k) => k.startsWith('cache_sounds_'));

    for (String fullKey in cachedKeys) {
      final key = fullKey.replaceFirst('cache_sounds_', '');
      final String? data = prefs.getString(fullKey);
      if (data != null) {
        final List decoded = jsonDecode(data);
        soundsBySubCategory[key] = decoded.map((e) => SoundItem.fromJson(e)).toList();
      }
    }
    soundsBySubCategory.refresh();
  }

  @override
  void onReady() async {
    print("🔊 [SYSTEM_DEBUG] Configuring iOS Audio Session...");
    super.onReady();
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
        AVAudioSessionCategoryOptions.mixWithOthers |
        AVAudioSessionCategoryOptions.defaultToSpeaker | // 🔥 Speaker force
        AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
      await session.setActive(true);
      print("✅ [SYSTEM_DEBUG] Audio Session Active and forced to Speaker.");
      fetchMixes();
    } catch (e) {
      print("❌ [SYSTEM_ERROR] Configuration failed: $e");
    }
  }
  final RxBool isPauseAction = false.obs;
  bool _isToggling = false;

  Future<void> toggleSound(SoundItem sound) async {
    final lang = Get.context!.lang;
    if (_isClearing) return;
    final id = sound.id;
    final isAlreadyInList = playingSounds.any((s) => s.id == id);

    // --- 1. HANDLE REMOVAL (Instant) ---
    if (isAlreadyInList) {
      playingSounds.removeWhere((s) => s.id == id);
      playingSounds.refresh();

      // Fire and forget the stop command
      soundPlayers[id]?.stop();
      _updateAudioNotification();
      return;
    }

    // --- 2. HANDLE STORY STOP (Instant) ---
    bool isPlayingStory = playingMusic.any((m) => m.categoryName.toLowerCase() == "story");
    if (isPlayingStory) {
      debugPrint("📖 Story detected. Stopping story.");
      // Don't 'await' this if you want ambient sounds to show 'active' immediately
      stopMusic();
    }

    // --- 3. CHECK LIMIT ---
    if (playingSounds.length >= 10) {
      toast(lang.maxSoundsLimit);
      return;
    }

    // --- 4. UI UPDATE (Total Instant - This highlights the button NOW) ---
    playingSounds.add(sound);
    if (isPaused.value) isPaused.value = false;
    playingSounds.refresh();
    _updateSimpleTextNotification();
    // --- 5. AUDIO LOGIC (Non-blocking) ---
    _startSoundBackground(sound);
  }

  void _startSoundBackground(SoundItem sound) async {
    final id = sound.id;
    print("🔊 [AMBIENT_DEBUG] 1. Attempting sound: ${sound.name}");

    try {
      AudioPlayer player = soundPlayers[id] ?? await createPlayerForSound(sound);

      // 🔥 iOS Fix: Ensure volume is up and session is awake
      await player.setVolume(soundVolumes[id] ?? 0.5);
      await player.setLoopMode(LoopMode.one);

      if (playingSounds.any((s) => s.id == id)&& !_isClearing) {
        // Hardware check before play
        final session = await AudioSession.instance;
        await session.setActive(true);

        print("🔊 [AMBIENT_DEBUG] 2. Sending Play command to Hardware...");
        player.play();

        _updateAudioNotification();
        syncVolumesAndLoop();
        print("✅ [AMBIENT_SUCCESS] ${sound.name} should be audible now.");
      }
    } catch (e) {
      print("❌ [AMBIENT_ERROR] Playback failed: $e");
    }
  }
// Helper function: Sirf Ambient sounds ke liye simple text notification
  void _showAmbientOnlyNotification() {
    if (playingSounds.isEmpty) return;

    String subText = playingSounds.length == 1
        ? playingSounds.first.name
        : "${playingSounds.first.name} + ${playingSounds.length - 1} more";

    musicPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse("https://api.sleepable.ai/silent.mp3"), // Dummy silent file
        tag: MediaItem(
          id: 'ambient_mix_active',
          album: "Sleepable AI",
          title: "Sound Playing",
          artist: subText,
          duration: null,
        ),
      ),
      preload: false,
    );
  }
  // Inside SleepSoundController
  void setJumpArguments({required String jumpTab, required String jumpFilter}) {
    // 1. Update Category
    selectedCategorySlug.value = jumpTab;

    // 2. Map "__all__" to an empty string so onSoundTabVisible()
    // can pick the first available subcategory automatically.
    if (jumpFilter == "__all__") {
      selectedSubCategorySlug.value = "";
    } else {
      selectedSubCategorySlug.value = jumpFilter;
    }

    // 3. Refresh Data
    onSoundTabVisible();
  }
  Future<void> syncVolumesAndLoop() async {
    // 1. Initial Check
    if (playingMusic.isEmpty) return;

    try {
      bool hasSounds = playingSounds.isNotEmpty;
      double targetVol = hasSounds ? 0.5 : 1.0;
      LoopMode targetLoop = hasSounds ? LoopMode.one : LoopMode.off;

      await musicPlayer.setLoopMode(targetLoop);

      double startVol = musicPlayer.volume;
      int steps = 10;

      for (int i = 1; i <= steps; i++) {
        // 2. 🔥 SAFETY: If music was cleared during the loop (e.g. by fadeOutAndStopAll), stop immediately
        if (playingMusic.isEmpty) return;

        double currentFrameVol = startVol + (targetVol - startVol) * (i / steps);
        await musicPlayer.setVolume(currentFrameVol);
        await Future.delayed(const Duration(milliseconds: 30));
      }

      // 3. 🔥 CRITICAL FIX: Verify list is still NOT empty before calling .first
      if (playingMusic.isNotEmpty) {
        int musicId = playingMusic.first.id;
        musicVolumes[musicId] = targetVol;
        musicVolumes.refresh();
      }
    } catch (e) {
      debugPrint("⚠️ syncVolumesAndLoop interrupted: $e");
      // This usually happens if the music player is disposed while fading. Safe to ignore.
    }
  }

// 🔥 Change 1: Ensure _isToggling is true during the transition to block listeners
  Future<void> togglePause() async {
    if (playingSounds.isEmpty && playingMusic.isEmpty) return;

    // 1. BLOCK the listener immediately
    _isToggling = true;

    try {
      // 2. Toggle the UI state first (Instant feedback)
      final bool targetPauseState = !isPaused.value;
      isPaused.value = targetPauseState;
      isPaused.refresh();

      debugPrint("➡️ [togglePause] UI Updated to: ${targetPauseState ? 'PAUSED' : 'PLAYING'}");

      // 3. Apply to Hardware
      if (targetPauseState) {
        // Use Future.wait to fire all hardware commands at once
        List<Future> pauseTasks = [];
        for (var sound in playingSounds) {
          if (soundPlayers.containsKey(sound.id)) {
            pauseTasks.add(soundPlayers[sound.id]!.pause());
          }
        }
        pauseTasks.add(musicPlayer.pause());
        await Future.wait(pauseTasks);
      } else {
        List<Future> playTasks = [];
        for (var sound in playingSounds) {
          if (soundPlayers.containsKey(sound.id)) {
            playTasks.add(soundPlayers[sound.id]!.play());
          }
        }
        if (playingMusic.isNotEmpty) playTasks.add(musicPlayer.play());
        await Future.wait(playTasks);
      }
    } catch (e) {
      debugPrint("❌ [togglePause] Error: $e");
    } finally {
      // 🔥 Change 2: Small delay before releasing the lock
      // This gives the hardware stream time to settle so it doesn't "flicker" the UI
      Future.delayed(const Duration(milliseconds: 500), () {
        _isToggling = false;
        debugPrint("✅ [togglePause] Lock released");
      });
    }
  }
  void debugPlayers() {
    print("---- 🔍 PLAYER MAP DATA ----");
    print("Active Mix: ${playingSounds.map((e) => e.name).toList()}");

    soundPlayers.forEach((id, player) {
      // Try to find the name in the active sounds list first
      final sound = playingSounds.firstWhere(
        (s) => s.id == id,
        orElse: () => SoundItem(
          id: id,
          name: "Inactive/Preloaded",
          file: "",
          image: "",
          // Required field
          subcategory: "",
          // Required field
          categoryName: "",
          // Required field
          subcategoryName: "",
          // Required field
          slug: "",
          // Required field
          isPremium: false,
          // Required field
          isNew: false,
          // Required field
          isFavorite: false, // Required field
        ),
      );

      print("ID: $id | Name: ${sound.name} | Playing: ${player.playing} | Volume: ${player.volume}");
    });
    print("----------------------------");
  }

  /// Helper to clear all sounds
  void stopAll() {
    print("🛑 stopAll() CALLED");
    print("🛑 playingSounds BEFORE: ${playingSounds.map((e) => e.name).toList()}");
    print("🛑 playingMusic BEFORE: ${playingMusic.map((e) => e.name).toList()}");
    print("🛑 isBottomSheetOpen BEFORE: ${isBottomSheetOpen.value}");

    playingSounds.clear();
    soundVolumes.clear();
    playingMusic.clear();
    musicVolumes.clear();

    playingSounds.refresh();
    soundVolumes.refresh();
    playingMusic.refresh();
    musicVolumes.refresh();
    playingMusicLocale.clear();
     FlutterLocalNotificationsPlugin().cancel(id:888);
    isBottomSheetOpen.value = false;
    stopTimer();

    print("🛑 stopAll() DONE");
  }

  bool _isClearing = false;

  Future<void> fadeOutAndStopAll({
    Duration duration = const Duration(milliseconds: 600),
    StopReason reason = StopReason.systemCleanup
  }) async {
    if (_isClearing) return;

    debugPrint("🛑 [fadeOutAndStopAll] START. Reason: $reason");
    _isClearing = true;
    _isToggling = true;

    try {
      // 1. Notifications turant cancel karein
      await FlutterLocalNotificationsPlugin().cancel(id: 888);

      // 2. Players ki snapshot lein
      final List<AudioPlayer> soundPlayersSnapshot = soundPlayers.values.toList();
      final List<AudioPlayer> activePlayers = [
        ...soundPlayersSnapshot,
        if (musicPlayer.playing) musicPlayer
      ];

      if (activePlayers.isEmpty) {
        _clearState();
        return;
      }

      // 3. FADE OUT LOGIC (With Safety check)
      if (!isPaused.value && activePlayers.isNotEmpty) {
        const int steps = 12; // Steps kam rakhein taaki hang na ho
        final int stepDelay = duration.inMilliseconds ~/ steps;

        for (int i = steps; i >= 0; i--) {
          // 🔥 Essential Guard: Agar cleanup ke beech mein kuch crash ho toh loop break ho jaye
          if (activePlayers.isEmpty) break;

          final double fadePercentage = i / steps;

          // try-catch inside loop taaki ek player fail ho toh dusra chalta rahe
          try {
            for (var p in activePlayers) {
              if (p.processingState != ProcessingState.idle) {
                p.setVolume(fadePercentage).catchError((_) => null);
              }
            }
          } catch (_) {}

          await Future.delayed(Duration(milliseconds: stepDelay));
        }
      }

      // 4. ⏹️ HARD STOP (Future.wait se hata kar individual kiya taaki deadlock na ho)
      for (var p in activePlayers) {
        try {
          await p.stop().timeout(const Duration(milliseconds: 300), onTimeout: () => null);
        } catch (e) {
          debugPrint("Error stopping player: $e");
        }
      }

      // 5. Memory Disposal
      for (var p in soundPlayersSnapshot) {
        p.dispose().catchError((_) => null);
      }

      // 6. UI Reset
      soundPlayers.clear();
      playingSounds.clear();
      playingMusic.clear(); // Ensure music list is also empty

      clearSleepTimer();
      stopTimer(stopAudio: false);
      _clearState();

      debugPrint("✅ [fadeOutAndStopAll] SUCCESS");

    } catch (e) {
      debugPrint("❌ [fadeOutAndStopAll] CRITICAL ERROR: $e");
      // Emergency cleanup agar sab crash ho jaye
      _clearState();
    } finally {
      _isToggling = false;
      _isClearing = false;
    }
  }
  void _clearState() {
    debugPrint("🧨 Clearing state and closing UI");
    remaining.value = Duration.zero;
    // 1. 🔥 THE KEY FIX: Close the Full Player or Mix sheet if open
    // We use Get.isBottomSheetOpen to ensure we don't accidentally close a screen
    // if (Get.isBottomSheetOpen ?? false) {
    //   print("-------in bottom sheet");
    //   Get.back();
    // }
    if (Get.isBottomSheetOpen ?? false) {
      // Check if the current route is NOT the sleep tracker
      if (Get.currentRoute != Routes.sleepTracker) {
        debugPrint("Closing player bottom sheet...");
        Get.back();
      } else {
        debugPrint("On Sleep Tracker: keeping screen open, just hiding MixBar.");
      }
    }

    // 2. Clear all audio data
    playingSounds.clear();
    playingMusic.clear();
    playingMusicLocale.clear();

    soundVolumes.clear();
    musicVolumes.clear();

    // 3. Update UI observers
    playingSounds.refresh();
    playingMusic.refresh();
    playingMusicLocale.refresh();

    // 4. Reset flags
    isPaused.value = false;
    isRunning.value = false;
    isAnyPlayerVisible.value = false; // Reset the visibility lock for future plays

    debugPrint("✅ State and UI reset complete.");
  }

  Future<void> stopAllAudio() async {
    // 🌊 Stop all ambient sounds
    for (final player in soundPlayers.values) {
      try {
        await player.stop();
        await player.seek(Duration.zero);
      } catch (_) {}
    }

    // 🎵 Stop music
    try {
      await musicPlayer.stop();
      await musicPlayer.seek(Duration.zero);
    } catch (_) {}

    // 🧹 Reset state
    playingSounds.clear();
    playingMusic.clear();
    playingMusicLocale.clear();

    currentPosition.value = Duration.zero;
    totalDurationPosition.value = Duration.zero;

    isMusicPlaying.value = false;
    isPaused.value = false;

    showMixBar.value = false;
  }

  Future<void> closeAllAudio() async {
    // 🌊 Stop & dispose sound players
    for (final player in soundPlayers.values) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }

    soundPlayers.clear();
    playingSounds.clear();
    soundVolumes.clear();

    // 🎵 Stop music ONLY (do NOT dispose)
    try {
      await musicPlayer.stop();
      await musicPlayer.seek(Duration.zero);
    } catch (_) {}

    playingMusic.clear();
    playingMusicLocale.clear();
    musicVolumes.clear();

    isMusicPlaying.value = false;
    isPaused.value = true;
  }

  Future<void> _initializeData() async {
    await fetchSoundCategories();
    if (tabOrder.isNotEmpty) {
      for (var cat in tabOrder.take(3)) {
        final filters = getCurrentFilters(cat.slug);
        if (filters.isNotEmpty) {
          _hydrateFromCache(soundKey(cat.slug, filters.first.slug));
        }
      }
    }
    for (final category in tabOrder) {
      await fetchSubCategories(category.slug);
    }

    if (tabOrder.isNotEmpty) {
      final firstCategorySlug = tabOrder.first.slug;

      selectedCategorySlug.value = firstCategorySlug;
      selectedSubCategorySlug.value = allSubSlug;

      await fetchSounds(firstCategorySlug, allSubSlug);
    }
  }

  Future<void> onSoundTabVisible() async {
    final category = selectedCategorySlug.value.isEmpty ? 'white-noise' : selectedCategorySlug.value;

    // Await subcategory fetch
    await fetchSubCategories(category);

    // Select first subcategory if nothing is selected
    if (selectedSubCategorySlug.value.isEmpty) {
      final filters = getCurrentFilters(category);
      if (filters.isNotEmpty) {
        selectedSubCategorySlug.value = filters.first.slug;
      }
    }

    // Now fetch sounds safely
    if (selectedSubCategorySlug.value.isNotEmpty) {
      await fetchSounds(category, selectedSubCategorySlug.value);
    }
  }

  RxString activeSheet = "none".obs;

  void openBottomSheet(BuildContext context) {
    if (playingSounds.isEmpty && playingMusic.isEmpty) return;
    isBottomSheetOpen.value = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      // 👈 Prevent closing when tapping outside
      enableDrag: false,
      // 👈 Prevent swipe-down to close
      transitionAnimationController: AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 500)),
      builder: (context) {
        // kkkk
        print("Bottom sheet opened");
        return AnimatedBottomSheetContent();
      },
    );
  }

  /// --- TIMER LOGIC ---

  Duration totalDuration = const Duration(minutes: 0);
  Rx<Duration> remaining = const Duration(minutes: 0).obs;

  // RxBool isRunning = false.obs;
  RxBool isPaused = false.obs; // ✅ new: pause/resume support

  Timer? _timer;
  final TextEditingController mixNameController = TextEditingController(text: "Mix0");
  final RxBool isTextNotEmpty = false.obs;

  void startTimer() {
    _timer?.cancel();

    if (remaining.value.inSeconds <= 0) return;

    isRunning.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      // If global pause is active, just wait
      if (isPaused.value) return;

      if (remaining.value.inSeconds > 0) {
        remaining.value -= const Duration(seconds: 1);
      } else {
        t.cancel();
        isRunning.value = false;

        // 🏁 The timer naturally reached zero
        debugPrint("⏱ Timer hit zero. Cleaning up...");

        // 1. Call the smooth fade out you built
        await fadeOutAndStopAll(reason: StopReason.timerFinished);

        // 2. 🔥 Reset variables so the sheet opens "fresh" next time
        totalDuration = Duration.zero;
        remaining.value = Duration.zero;
        isInfinite.value = false;
        Get.back();
      }
    });
  }

  void resetTimer(int minutes) {
    _timer?.cancel();

    if (minutes == 0) {
      isInfinite.value = true;
      totalDuration = Duration.zero;
      remaining.value = Duration.zero;
      isRunning.value = false;
      return;
    }

    isInfinite.value = false;
    totalDuration = Duration(minutes: minutes);
    remaining.value = totalDuration;

    // If sounds are already playing, start the timer countdown immediately
    if (playingSounds.isNotEmpty || playingMusic.isNotEmpty) {
      startTimer();
    }
  }

  void stopTimer({bool stopAudio = true}) {
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = false; // IMPORTANT FIX
    remaining.value = totalDuration;

    if (stopAudio) {
      print("stopaudio------$stopAudio");
      stopAllAudio();
    }
  }

  RxBool isInfinite = false.obs;


  @override
  void onClose() {
    _timer?.cancel();
    musicPlayer.dispose();
    closeAllAudio();
    super.onClose();
  }

  final RxList<MixedSoundRecord> apiMixes = <MixedSoundRecord>[].obs;
  final RxBool isMixesLoading = false.obs;

  Future<void> fetchMixes() async {
    if (isMixesLoading.value) return;

    try {
      isMixesLoading.value = true;
      final List<MixedSoundRecord> records = await SoundsApis.fetchSoundsMixedRecords();

      // Store the objects directly—no manual mapping needed!
      apiMixes.assignAll(records);

    } catch (e, stack) {
      debugPrint("❌ fetchMixes Error: $e");
    } finally {
      isMixesLoading.value = false;
    }
  }
  Future<void> restoreMixFromApi(MixedSoundRecord mix) async {
    try {
      debugPrint("🔄 Restoring Full Mix: ${mix.title}");

      // 1. Stop everything currently playing
      await fadeOutAndStopAll(reason: StopReason.systemCleanup);

      // Clear lists to ensure a clean slate
      playingSounds.clear();
      playingMusic.clear();

      // 2. Sort and Convert items from the API
      for (var item in mix.sounds) {
        final soundItem = SoundItem(
                  id: item.id,
                  name: item.name,
                  emoji: item.emoji,
                  thumbnail: item.thumbnail,
                  image: item.image,
                  file: item.file,
                  // Missing fields in MixedSoundItem - using defaults:
                  subcategory: "",
                  categoryName: 'Mix',
                  subcategoryName: 'Mix',
                  slug: item.name.toLowerCase().replaceAll(' ', '-'),
                  isPremium: false,
                  isNew: false,
                  isFavorite: false,
                  artist: null,
                  duration: null,
                );

        // Check if it's music or a sound based on category
        if (soundItem.categoryName.toLowerCase() == "music"
            || soundItem.categoryName.toLowerCase() == "story"
        ) {
          playingMusic.add(soundItem);
        } else {
          playingSounds.add(soundItem);
        }
      }

      // 3. Batch Start Audio
      await _playAllRestoredItems();

      // 4. Update UI
      isPaused.value = false;
      isAnyPlayerVisible.value = true;
      playingSounds.refresh();
      playingMusic.refresh();

    } catch (e) {
      debugPrint("❌ Mix Restore Error: $e");
    }
  }

  Future<void> _playAllRestoredItems() async {
    // Create a list of all play futures
    List<Future> playTasks = [];

    // A. Prep Ambient Sounds
    for (var sound in playingSounds) {
      final player = soundPlayers[sound.id] ?? await createPlayerForSound(sound);
      playTasks.add(player.setVolume(soundVolumes[sound.id] ?? 0.5));
      playTasks.add(player.setLoopMode(LoopMode.one));
      playTasks.add(player.play());
    }

    // B. Prep Music
    if (playingMusic.isNotEmpty) {
      final music = playingMusic.last;
      playTasks.add(musicPlayer.setUrl(music.file).then((_) => musicPlayer.play()));
    }

    // Fire everything at once!
    await Future.wait(playTasks);
  }
  void openSaveMixBottomSheet(BuildContext context) {
    if (playingSounds.isEmpty) return;

    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => const OpenSaveMixBottomSheet1());
  }

  // Add to SleepSoundController class (near other fields)
  RxList<Map<String, dynamic>> savedMixes = <Map<String, dynamic>>[].obs;

  void saveCurrentMix(BuildContext context) async {
    final lang = context.lang;
    final mixName = mixNameController.text.trim();
    if (mixName.isEmpty) {
      print("⚠️ Mix name is empty — skipping save.");
      return;
    }

    print("💾 Trying to save mix: $mixName");

    // Check for duplicate mix name
    final nameExists = savedMixes.any((mix) => mix['name'] == mixName);

    // Check for duplicate content (by comparing IDs)
    final contentExists = savedMixes.any((mix) {
      final savedSounds = List<int>.from(mix['sounds'] ?? <int>[]);
      final savedMusic = List<int>.from(mix['music'] ?? <int>[]);

      return Set.from(savedSounds).containsAll(playingSounds.map((e) => e.id)) &&
          Set.from(playingSounds.map((e) => e.id)).containsAll(savedSounds) &&
          Set.from(savedMusic).containsAll(playingMusic.map((e) => e.id)) &&
          Set.from(playingMusic.map((e) => e.id)).containsAll(savedMusic);
    });

    if (nameExists) {
      print("🚫 Mix name already exists: $mixName");
      Get.snackbar(
        // "Duplicate Name",
        // "A mix with this name already exists.",
        lang.duplicateNameTitle,
        lang.duplicateMixName,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (contentExists) {
      print("⚠️ Mix content already saved (duplicate mix).");
      Get.snackbar(
        lang.duplicateMixTitle,
        lang.duplicateMixContent,
        // "Duplicate Mix",
        //         "This exact mix is already saved.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Minimum sounds check
    if (playingSounds.isEmpty || (playingSounds.length == 1 && playingMusic.isEmpty)) {
      print("⚠️ Not enough sounds to save");
      Get.snackbar(
        lang.cannotSaveTitle,
        lang.mixMinSoundsError,
        // "Cannot Save Mix",
        // "Please select at least two sounds or one sound with music.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Prepare mix data
    final mixData = {'name': mixName, 'sounds': playingSounds.map((e) => e.id).toList(), 'music': playingMusic.map((e) => e.id).toList(), 'createdAt': DateTime.now().toIso8601String()};

    savedMixes.add(mixData);
    mixNameController.clear();
    isTextNotEmpty.value = false;

    print("✅ Mix saved locally: $mixName");
    print("🎵 Sounds: ${mixData['sounds']}");
    print("🎧 Music: ${mixData['music']}");
    print("📦 Total saved mixes: ${savedMixes.length}");

    // Prepare server payload
    try {
      final request = {
        'title': mixName,
        'sound_ids': [...playingSounds.map((item) => item.id), ...playingMusic.map((item) => item.id)],
        'description': [...playingSounds.map((item) => item.name), ...playingMusic.map((item) => item.name)],
      };

      print("🌐 Server request payload: $request");

      // 🔹 Uncomment this to call API
      final response = await SoundsApis.soundsMixedCreate(request: request);
      if (response.success) {
        Get.snackbar(
          lang.mixSaved,
          // "Mix Saved",
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print("⚠️ Error saving mix on server: $e");
    }
  }

  TextEditingController descriptionController = TextEditingController();

  RxList<Map<String, dynamic>> environmentTags = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> todayTags = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> otherTags = <Map<String, dynamic>>[].obs;

  RxBool isLoadingNotes = false.obs;
  RxBool isLoadingDeleteNotes = false.obs;
  RxBool isLoadingEditNotes = false.obs;
  RxBool isLoadingCreateNotes = false.obs;

  bool get isAnyNoteLoading => isLoadingNotes.value || isLoadingDeleteNotes.value || isLoadingEditNotes.value || isLoadingCreateNotes.value;

  Future<void> fetchSleepNoteCategories() async {
    print("----- call api open on ready -----");
    try {
      isLoadingNotes.value = true;

      final response = await TrackerApis.fetchNoteCategories();
      if (response['success'] != true) return;

      environmentTags.clear();
      todayTags.clear();
      otherTags.clear();

      for (final category in response['data']) {
        final slug = category['slug'];
        final notes = category['notes'] as List;

        final mappedNotes = notes.map<Map<String, dynamic>>((n) {
          return {"id": n['id'], "icon": n['emoji'], "name": n['title'], "isSelected": false, "isPublic": n['is_public'] == true};
        }).toList();

        if (slug == 'environment') {
          environmentTags.assignAll(mappedNotes);
        } else if (slug == 'today') {
          todayTags.assignAll(mappedNotes);
        } else if (slug == 'others') {
          otherTags.assignAll(mappedNotes);
        }
      }
    } catch (e) {
      debugPrint('❌ fetchSleepNoteCategories error: $e');
    } finally {
      isLoadingNotes.value = false;
    }
  }

  void clearSelected(RxList<Map<String, dynamic>> tags) {
    for (var t in tags) {
      t["isSelected"] = false;
    }
    tags.refresh();
  }

  void clearAllSelected() {
    clearSelected(environmentTags);
    clearSelected(todayTags);
    clearSelected(otherTags);
  }

  Future<bool> submitSleepNote() async {
    if (isLoadingCreateNotes.value) {
      print("⚠️ submitSleepNote already running");
      return false;
    }

    isLoadingCreateNotes.value = true;

    try {
      print("----- submitSleepNote START -----");

      final selectedEnvironment = environmentTags.where((e) => e["isSelected"] == true).toList();

      final selectedToday = todayTags.where((e) => e["isSelected"] == true).toList();

      final selectedOthers = otherTags.where((e) => e["isSelected"] == true).toList();

      print("Environment selected: ${selectedEnvironment.length}");
      print("Today selected: ${selectedToday.length}");
      print("Other selected: ${selectedOthers.length}");

      final description = descriptionController.text.trim();

      if (selectedEnvironment.isEmpty && selectedToday.isEmpty && selectedOthers.isEmpty && description.isEmpty) {
        print("⚠️ Nothing to submit");
        return true;
      }

      /// 🔥 IMPORTANT: Prevent duplicate titles in same request
      final Set<String> uniqueTitles = {};

      Future<void> createIfNotDuplicate(String title, int categoryId) async {
        final normalized = title.trim().toLowerCase();

        if (uniqueTitles.contains(normalized)) {
          print("⚠️ Skipping duplicate in same batch: $title");
          return;
        }

        uniqueTitles.add(normalized);

        try {
          print("➡️ Creating note: $title (category $categoryId)");

          final response = await TrackerApis.createNote(title: title, categoryId: categoryId);

          if (response?.success == true) {
            print("✅ Created: $title");
          } else {
            print("❌ Failed or null response for $title");
          }
        } catch (e) {
          print("❌ Error creating $title : $e");
        }
      }

      /// 🔥 Sequential execution (NO Future.wait)
      for (final tag in selectedEnvironment) {
        await createIfNotDuplicate(tag["name"], 1);
      }

      for (final tag in selectedToday) {
        await createIfNotDuplicate(tag["name"], 2);
      }

      for (final tag in selectedOthers) {
        await createIfNotDuplicate(tag["name"], 3);
      }

      /// Refresh from server (single source of truth)
      await fetchSleepNoteCategories();

      print("----- submitSleepNote END -----");

      return true;
    } catch (e) {
      print("🔥 submitSleepNote fatal error: $e");
      return false;
    } finally {
      isLoadingCreateNotes.value = false;
    }
  }

  Future<CommonResponse> updateNote({required int noteId, required String title}) async {
    try {
      isLoadingEditNotes.value = true;

      final response = await TrackerApis.updateSleepNote(noteId: noteId, title: title);

      return response;
    } catch (e) {
      debugPrint("❌ Error updating note: $e");
      return CommonResponse(success: false, message: "Error");
    } finally {
      isLoadingEditNotes.value = false;
    }
  }

  Future<CommonResponse> deleteNote({required int noteId}) async {
    try {
      isLoadingDeleteNotes.value = true;

      final response = await TrackerApis.deleteSleepNote(noteId: noteId);

      return response;
    } catch (e) {
      debugPrint("❌ Error deleting note: $e");
      return CommonResponse(success: false, message: "Error");
    } finally {
      isLoadingDeleteNotes.value = false;
    }
  }

  int getCategoryIdFromTitle(String title) {
    switch (title.toLowerCase()) {
      case 'environment':
        return 1;
      case 'today':
        return 2;
      case 'others':
        return 3;
      default:
        return 0;
    }
  }

  RxList<Map<String, dynamic>> getCategoryListFromTitle(SleepSoundController controller, String title) {
    switch (title.toLowerCase()) {
      case 'environment':
        return controller.environmentTags;
      case 'today':
        return controller.todayTags;
      case 'others':
        return controller.otherTags;
      default:
        return <Map<String, dynamic>>[].obs;
    }
  }


  /// 📜 Dynamic Playlist that switches based on what is playing
  List<SoundItem> get activePlaylist {
    // 1. Determine current mode
    bool isStoryMode = playingMusic.isNotEmpty && playingMusic.first.categoryName.toLowerCase() == "story";

    // 2. Filter the loaded sounds based on that mode
    final allLoaded = soundsBySubCategory.entries.where((entry) => isStoryMode ? entry.key.startsWith('story::') : entry.key.startsWith('music::')).expand((entry) => entry.value).toList();

    // 3. Remove duplicates
    final seenIds = <int>{};
    return allLoaded.where((s) => seenIds.add(s.id)).toList();
  }

  /// 🔢 Always finds the index in the CORRECT playlist (Story or Music)
  int get currentActiveIndex {
    if (playingMusic.isEmpty) return -1;
    return activePlaylist.indexWhere((m) => m.id == playingMusic.first.id);
  }

  /// ⏭ Unified Skip Next
  Future<void> skipNext() async {
    final list = activePlaylist;
    if (list.isEmpty) return;
    int index = currentActiveIndex;
    int nextIndex = (index == -1 || index >= list.length - 1) ? 0 : index + 1;
    await toggleMusic(list[nextIndex]);
  }

  /// ⏮ Unified Skip Previous
  Future<void> skipPrevious() async {
    final list = activePlaylist;
    if (list.isEmpty) return;
    int index = currentActiveIndex;
    int prevIndex = (index <= 0) ? list.length - 1 : index - 1;
    await toggleMusic(list[prevIndex]);
  }

  var currentPosition = Duration.zero.obs;
  var totalDurationPosition = Duration.zero.obs;

  Future<void> seek(Duration position) async {
    if (playingMusic.isEmpty) return;

    try {
      await musicPlayer.seek(position);
    } catch (e) {
      debugPrint("❌ Seek error: $e");
    }
  }

  Rx<Duration> sleepTimerDuration = Duration.zero.obs; // visible on UI
  Timer? sleepTimer;

  // REPEAT
  RxBool isRepeatEnabled = false.obs;

  void startSleepTimer(Duration duration) {
    clearSleepTimer();
    sleepTimerDuration.value = duration;

    // 🔥 Ensure music loops while timer is active
    if (playingMusic.isNotEmpty) {
      musicPlayer.setLoopMode(LoopMode.one);
    }

    sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (isPaused.value) return;

      final secondsLeft = sleepTimerDuration.value.inSeconds;

      if (secondsLeft <= 1) {
        timer.cancel();
        sleepTimerDuration.value = Duration.zero;

        debugPrint("⏱ Timer hit zero! Forcing stop.");

        // Stop everything and reset loop mode
        await stopAllAudio();
        await musicPlayer.setLoopMode(LoopMode.off);

        playingMusic.clear();
        playingSounds.clear();

        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        return;
      }
      sleepTimerDuration.value = Duration(seconds: secondsLeft - 1);
    });
  }

  void clearSleepTimer() {
    sleepTimer?.cancel();
    sleepTimer = null;
    sleepTimerDuration.value = Duration.zero;
  }

  // keep RxInt if you like, but we'll also call update() for GetBuilder
  final RxInt currentStepIndex = 0.obs;

  // safe default
  List<SleepOnboardingStep> steps = [];

  Future<void> refreshSteps() async {
    await _setupSteps();
  }

  Future<void> _setupSteps() async {
    final firstTime = await isFirstTimeUser();
    final skipPlaceDevice = await shouldSkipPlaceDevice();
    // final skipSmartAlarm = await shouldSkipSmartAlarm();
    final skipSetSmartAlarm = await shouldSkipSetSmartAlarm();

    final baseSteps = firstTime
        ? [
            SleepOnboardingStep.advanceTracker,
            // SleepOnboardingStep.smartAlarm,
            SleepOnboardingStep.setSmartAlarm,
            SleepOnboardingStep.trySleepNote,
            SleepOnboardingStep.sleepNote,
            SleepOnboardingStep.placeDevice,
          ]
        : [
            // SleepOnboardingStep.smartAlarm,
            SleepOnboardingStep.setSmartAlarm,
            SleepOnboardingStep.sleepNote,
            SleepOnboardingStep.placeDevice,
          ];

    steps = baseSteps.where((step) {
      if (step == SleepOnboardingStep.placeDevice && skipPlaceDevice) return false;
      // if (step == SleepOnboardingStep.smartAlarm && skipSmartAlarm) return false;
      if (step == SleepOnboardingStep.setSmartAlarm && skipSetSmartAlarm) return false;
      return true;
    }).toList();

    currentStepIndex.value = 0;
    Future.microtask(() async {
      if (steps.contains(SleepOnboardingStep.sleepNote)) {
        fetchSleepNoteCategories();
      }
    });
    update();
  }

  SleepOnboardingStep get currentStep {
    if (steps.isEmpty) {
      currentStepIndex.value = 0;
      return SleepOnboardingStep.advanceTracker;
    }

    if (currentStepIndex.value >= steps.length) {
      currentStepIndex.value = 0; // prevents jump to last step
    }

    return steps[currentStepIndex.value];
  }

  Future<void> saveSmartAlarmPreference() async {
    if (!Get.isRegistered<AlarmController>()) {
      Get.put(AlarmController(), permanent: true);
    }
    final alarmController = Get.find<AlarmController>();
    final prefs = await SharedPreferences.getInstance();

    int hour12 = alarmController.hour.value;
    int minute = alarmController.minute.value;
    bool isAm = alarmController.isAm.value;

    int hour24 = isAm ? hour12 % 12 : (hour12 % 12) + 12;

    final wakeUpTime =
        "${hour24.toString().padLeft(2, '0')}:"
        "${minute.toString().padLeft(2, '0')}";

    final displayTime =
        "${hour12.toString().padLeft(2, '0')}:"
        "${minute.toString().padLeft(2, '0')} "
        "${isAm ? 'AM' : 'PM'}";

    await prefs.setBool('smart_alarm_enabled', true);
    await prefs.setString('wake_up_time', wakeUpTime);
    await prefs.setString('wake_up_time_display', displayTime);
    print(wakeUpTime);
    print(displayTime);
    // toast("⏰ --nextStep--- Wake up time: $displayTime");
  }

  void nextStep() async {
    final currentStep = steps[currentStepIndex.value];
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    final alarmCtrl = Get.isRegistered<AlarmController>()
        ? Get.find<AlarmController>()
        : Get.put(AlarmController());



    // --- 1. Handle API Saves per Step ---
    if (currentStep == SleepOnboardingStep.setSmartAlarm) {
      // Save local preferences first
      await saveSmartAlarmPreference();

      // Call Global API via ProfileController
       profileCtrl.updateSettings(
        customNewData: profileCtrl.settings.value?.copyWith(
          alarmTime: alarmCtrl.apiAlarmTime,
          alarmEnabled: true,
          meridiem: alarmCtrl.isAm.value ? "AM" : "PM",
        ),
      );
    }



    // --- 3. Navigation Logic ---
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('wake_up_time_display')) {
      await saveSmartAlarmPreference();
    }

    if (currentStepIndex.value < steps.length - 1) {
      currentStepIndex.value++;
      update();
    } else {
      // Onboarding Finished
      await setOnboardingDone();
      Get.back();

      Future.delayed(const Duration(milliseconds: 100), () {
        Get.toNamed(Routes.heartBPMMeasurement);
      });
    }
  }

  void previousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
      update();
    }
  }

  void setStepIndex(int i) {
    if (i >= 0 && i < steps.length) {
      currentStepIndex.value = i;
      update();
    }
  }

  Future<void> _updateSimpleTextNotification() async {
    // Isse bilkul khali chhod dein.
    // Tracker wali notification ko baar-baar update karne se hi wo blink/restart hoti hai.
    return;
  }

  Future<void> _updateAudioNotification() async {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    final lang = Get.context!.lang;
    // 🔥 CRITICAL: Agar music aur sounds dono band hain, toh notification hata do
    if (playingMusic.isEmpty && playingSounds.isEmpty) {
      await localNotifications.cancel(id:888);
      return;
    }

    String notifyContent = "";
    if (playingMusic.isNotEmpty) {
      notifyContent = "${playingMusic.first.categoryName} Playing: ${playingMusic.first.name}";
    } else {
      notifyContent = lang.ambientPlaying;
    }

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'audio_status_channel', 'Audio Status',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Swipe se nahi hatega
        icon: 'mipmap/ic_launcher',
      ),
    );

    await localNotifications.show(
      id: 888,
      title: lang.nowPlaying,
      body: notifyContent,
      notificationDetails: platformChannelSpecifics,
    );
  }
  void _clearNowPlayingNotification() {
    FlutterLocalNotificationsPlugin().cancel(id:888);
  }
}

