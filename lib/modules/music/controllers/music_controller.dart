import 'package:sleepable_ai/core/utils/library.dart';

class MusicController extends GetxController with GetTickerProviderStateMixin {
  var isPlaying = false.obs;
  var currentSound = 'Forest Rain'.obs;
  var timer = 30.obs; // minutes
  late AnimationController animationController;
  late Animation<double> animation;
  final sounds = [
    {'title': 'Ocean Waves', 'subtitle': 'Calming beach sounds', 'isPlaying': true},
    {'title': 'Thunderstorm', 'subtitle': 'Distant thunder & rain', 'isPlaying': false},
    {'title': 'Campfire', 'subtitle': 'Crackling fire sounds', 'isPlaying': false},
    {'title': 'White Noise', 'subtitle': 'Pure white noise', 'isPlaying': false},
    {'title': 'Pink Noise', 'subtitle': 'Balanced frequency noise', 'isPlaying': false},
  ].obs;

  // Category list
  final categories = ["Nature", "White Noise", "ASMR", "Binaural"].obs;

  // Selected category
  final selectedCategory = "Nature".obs;

  void togglePlay() => isPlaying.value = !isPlaying.value;

  @override
  void onInit() {
    super.onInit();
    // 🎨 Looping animations (gradient + breathing)
    animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    animation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: animationController, curve: Curves.linear));
  }

  void playSound(int index) {
    for (var s in sounds) {
      s['isPlaying'] = false;
    }
    sounds[index]['isPlaying'] = true;
    currentSound.value = sounds[index]['title'].toString();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
