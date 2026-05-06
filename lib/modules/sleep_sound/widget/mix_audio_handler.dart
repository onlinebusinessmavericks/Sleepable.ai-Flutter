// import 'package:audio_service/audio_service.dart';
// import 'package:sleepable_ai/core/utils/library.dart';
// import 'package:get/get_state_manager/src/simple/get_controllers.dart';
// import 'package:just_audio/just_audio.dart';
//
// class MixAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
//   final AudioPlayer _player = AudioPlayer();
//
//   MixAudioHandler() {
//     _player.playerStateStream.listen((playerState) {
//       playbackState.add(PlaybackState(
//         controls: [
//           MediaControl.play,
//           MediaControl.pause,
//           MediaControl.stop,
//         ],
//         androidCompactActionIndices: [0, 1],
//         processingState: _convertProcessingState(playerState.processingState),
//         playing: playerState.playing,
//         updatePosition: _player.position,
//         bufferedPosition: _player.bufferedPosition,
//         speed: _player.speed,
//       ));
//     });
//   }
//
//   AudioProcessingState _convertProcessingState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
//
//   @override
//   Future<void> playMediaItem(MediaItem mediaItem) async {
//     print("----------$mediaItem----------");
//
//     // 1️⃣ Set the current media item (required for notification)
//     this.mediaItem.add(mediaItem);
//
//     // 2️⃣ Initialize playback state immediately
//     playbackState.add(PlaybackState(
//       controls: [MediaControl.play, MediaControl.pause, MediaControl.stop],
//       androidCompactActionIndices: [0, 1],
//       processingState: AudioProcessingState.ready,
//       playing: false,
//       updatePosition: Duration.zero,
//       bufferedPosition: Duration.zero,
//       speed: 1.0,
//     ));
//
//     final url = mediaItem.extras?['url'] ?? '';
//     if (url.isEmpty) return;
//
//     try {
//       // 3️⃣ Load asset or URL
//       if (url.startsWith('http')) {
//         await _player.setUrl(url);
//       } else {
//         await _player.setAsset(url);
//       }
//
//       await _player.setLoopMode(LoopMode.one);
//
//       // 4️⃣ Start playback
//       await _player.play();
//
//       // 5️⃣ Update playback state to playing
//       playbackState.add(PlaybackState(
//         controls: [MediaControl.play, MediaControl.pause, MediaControl.stop],
//         androidCompactActionIndices: [0, 1],
//         processingState: AudioProcessingState.ready,
//         playing: true,
//         updatePosition: _player.position,
//         bufferedPosition: _player.bufferedPosition,
//         speed: _player.speed,
//       ));
//
//     } catch (e) {
//       debugPrint("Error playing mediaItem '${mediaItem.title}': $e");
//     }
//   }
//
//
//   @override
//   Future<void> play() => _player.play();
//
//   @override
//   Future<void> pause() => _player.pause();
//
//   @override
//   Future<void> stop() async {
//     await _player.stop();
//     await super.stop();
//   }
// }
//
// class PlayerController extends GetxController {
//   final MixAudioHandler audioHandler;
//
//   RxBool isPlaying = false.obs;
//   MediaItem? currentMedia; // ← store the current media item
//
//   PlayerController({required this.audioHandler});
//
//   void playMedia(MediaItem mediaItem) async {
//     currentMedia = mediaItem;
//     await audioHandler.playMediaItem(mediaItem); // now mediaItem is defined
//     isPlaying.value = true;
//   }
// }
