import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/colors.dart';

class YouTubePlayerView extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubePlayerView({super.key, required this.videoId, required this.title});

  @override
  State<YouTubePlayerView> createState() => _YouTubePlayerViewState();
}
class _YouTubePlayerViewState extends State<YouTubePlayerView> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(playerListener); // Moved listener to a named function
  }

  void playerListener() {
    // FORCE CHECK: If the player value is ready, update the UI
    if (_controller.value.isReady && mounted && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Essential for Android stability
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF3A7CFF),
        // FIX: Some devices ignore onReady, so we handle it in the listener too
        onReady: () {
          debugPrint('Sleepable AI: YouTube Player Ready Callback');
          if (mounted) {
            setState(() {
              _isPlayerReady = true;
            });
            _controller.play();
          }
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            title: Text(widget.title, style: const TextStyle(fontSize: 14, color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // FIX: Wrapping player in a sized container helps the MediaCodec allocate space
              Container(
                width: double.infinity,
                child: player,
              ),
              const SizedBox(height: 20),
              // if (!_isPlayerReady)
              //   const Column(
              //     children: [
              //       CircularProgressIndicator(color: Color(0xFF3A7CFF)),
              //       SizedBox(height: 10),
              //       Text("Initializing secure stream...", style: TextStyle(color: Colors.white70)),
              //     ],
              //   ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(playerListener);
    _controller.dispose();
    super.dispose();
  }
}