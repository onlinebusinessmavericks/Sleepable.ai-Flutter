import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/utils/library.dart';
import '../../../localization/lang_extension.dart';
import '../model/sleeppedia_item.dart';
import '../widget/sleeppedia_data.dart';

class SleepInfoController extends GetxController {
  final RxInt selectedTab = 0.obs;
  late PageController pageController;
  // final String apiKey = "AIzaSyD14Z9woGwGLTTK7rRMqFnuzT6dd3l9OSs";
  // final String channelId = "UCougSHk2I5pjtkyE0rMbvsA";
  final String apiKey = "AIzaSyD14Z9woGwGLTTK7rRMqFnuzT6dd3l9OSs";
// Updated to the new Channel ID
  final String channelId = "UCoaTc58Ssthp-ocWWQFqURw";
  var videos = <Map<String, dynamic>>[].obs;
  var isLoadingVideos = true.obs;
  final List<String> tabs = [
    Get.context?.lang.sleeppedia ?? "Sleeppedia",
    Get.context?.lang.sleepQuiz ?? "SleepQuiz",
    Get.context?.lang.youtube ?? "YouTube"
    // "Sleeppedia",
    // "SleepQuiz",
    // "YouTube"
  ];

  // Inside your GetxController
  var buttonScale = 1.0.obs;

  void updateScale(double value) {
    buttonScale.value = value;
  }
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['tabIndex'] != null) {
      selectedTab.value = args['tabIndex'];
    }

    pageController = PageController(initialPage: selectedTab.value);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChannelVideos();
    });
  }
  void changeTab(int index) {
    selectedTab.value = index;
    // Check clients to prevent "ScrollController not attached" errors
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  void onPageChanged(int index) {
    selectedTab.value = index;
  }

  @override
  void onClose() {
    if (pageController.hasClients) {
      pageController.position.hold(() {});
    }

    // 3. Now it is safe to dispose
    pageController.dispose();
    super.onClose();
  }

  final List<SleeppediaItem> sleeppedia = getLocalizedSleeppediaList();


  Future<void> fetchChannelVideos() async {
    try {
      isLoadingVideos(true);
      final url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&maxResults=20&order=date&type=video&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      // ✅ CRITICAL SAFETY CHECK
      // If the user navigated away while we were waiting for the API, stop here.
      if (isClosed) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        videos.value = List<Map<String, dynamic>>.from(data['items']);
      } else {
        print('YouTube API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
    } finally {
      // ✅ ANOTHER SAFETY CHECK
      if (!isClosed) {
        isLoadingVideos(false);
      }
    }
  }
}