import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;

// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sleepable_ai/data/services/api_end_point.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/shared_prefences.dart';
import '../../core/utils/library.dart';
import '../../modules/boot_up/model/tracker_status_response.dart';
import '../../modules/dreambot/model/chat_response_model.dart';
import '../../modules/home/model/artist_model.dart';
import '../../modules/home/model/home_page_response.dart';
import '../../modules/login/model/email_login_resposnse.dart';
import '../../modules/login/model/google_social_login_model.dart';
import '../../modules/profile/model/UpdateStreakResponse.dart';
import '../../modules/profile/model/UserSettings.dart';
import '../../modules/profile/model/consecutive_streak_response.dart';
import '../../modules/profile/model/user_profile_model.dart';
import '../../modules/progress/model/AIInsightsResponse.dart';
import '../../modules/progress/model/SnoringIntensityResponse.dart';
import '../../modules/progress/model/achievement_badges_response.dart';
import '../../modules/progress/model/dream_list_response.dart';
import '../../modules/progress/model/key_insights_response.dart';
import '../../modules/progress/model/recommendations_response.dart';
import '../../modules/progress/model/sleep_audio_response.dart';
import '../../modules/progress/model/sleep_calendar_response.dart';
import '../../modules/progress/model/sleep_consistency_response.dart';
import '../../modules/progress/model/sleep_duration_chart_response.dart';
import '../../modules/progress/model/sleep_quality_response.dart';
import '../../modules/progress/model/sleep_stages_response.dart';
import '../../modules/settings/model/user_settings_model.dart';
import '../../modules/sleep_quiz/model/quiz_result_response.dart';
import '../../modules/sleep_sound/model/SoundItem.dart';
import '../../modules/sleep_sound/model/sound_sub_category_model.dart';
import '../../modules/sleep_sound/model/sound_category_model.dart';
import '../../modules/sleep_sound/model/sounds_mixed_list_model.dart';
import '../../modules/sleep_sound/model/start_sleep_tracker_model.dart';
import '../../widgets/SubscriptionController.dart';

// import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// import 'package:in_app_purchase_android/billing_client_wrappers.dart'; // Add this for Params
import '../models/common_model.dart';
import 'config.dart';
import 'network_utils.dart';

import 'dart:async';
import 'dart:io';

// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // 🔥 Required
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class AuthServiceApis {
  static Future<SocialLoginResponse> socialLogin({required Map<String, dynamic> request}) async {
    final responseMap = await buildHttpResponse(
      endPoint: APIEndPoints.socialLogin,
      request: request,
      method: MethodType.post,
      allowTokenRefresh: false, // 🔥 IMPORTANT
    );

    return SocialLoginResponse.fromJson(responseMap);
  }

  static Future<void> updateFcmToken({required Map<String, dynamic> request}) async {
    try {
      await buildHttpResponse(endPoint: APIEndPoints.updateFCMToken, request: request, method: MethodType.post);
      dev.log("✅ FCM Token API Success");
    } catch (e) {
      dev.log("❌ FCM Token API Error: $e");
      // Isse throw mat karein taaki background process stop na ho
    }
  }

  static Future<CommonResponse> logOut({required Map request}) async {
    print("request------$request");

    final response = await buildHttpResponse(endPoint: APIEndPoints.logOut, request: request, method: MethodType.post);

    return CommonResponse.fromJson(response);
  }

  static Future<CommonResponse> deleteAccount() async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.deleteAccount, method: MethodType.delete);

    return CommonResponse.fromJson(response);
  }
  /// 1. Email Login API
  static Future<EmailLoginResponse> emailLogin({required Map<String, dynamic> request}) async {
    final responseMap = await buildHttpResponse(
      endPoint: 'users/email-login/', // Backend endpoint check karein
      request: request,
      method: MethodType.post,
    );
    return EmailLoginResponse.fromJson(responseMap);
  }

  /// 2. Email Verify OTP API
  static Future<SocialLoginResponse> verifyEmailOtp({required Map<String, dynamic> request}) async {
    final responseMap = await buildHttpResponse(
      endPoint: 'users/email-verify-otp/',
      request: request,
      method: MethodType.post,
    );
    // OTP verify hone ke baad backend SocialLoginResponse (tokens) hi bhejega
    return SocialLoginResponse.fromJson(responseMap);
  }

  /// 3. Email Register API (Optional for Review, but good to have)
  static Future<CommonResponse> emailRegister({required Map<String, dynamic> request}) async {
    final responseMap = await buildHttpResponse(
      endPoint: 'users/email-register/',
      request: request,
      method: MethodType.post,
    );
    return CommonResponse.fromJson(responseMap);
  }
}

/// HOME---------------------------------------------------------------------------------------------------------------

class HomeApis {
  static Future<HomePageResponse> getHomePage() async {
    final endpoint = APIEndPoints.homePage;

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return HomePageResponse.fromJson(response);
  }

  // static Future<ArtistResponse> fetchArtists() async {
  //   final response = await buildHttpResponse(endPoint: APIEndPoints.fetchSoundsArtists, method: MethodType.get);
  //
  //   return ArtistResponse.fromJson(response);
  // }
}

/// SOUNDS---------------------------------------------------------------------------------------------------------------

class SoundsApis {
  /// Fetch main categories
  static Future<SoundCategoryResponse> fetchSoundCategories() async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.fetchSoundsCategories, method: MethodType.get);

    return SoundCategoryResponse.fromJson(response);
  }

  /// Fetch sub categories using category slug
  static Future<SoundSubCategoryResponse> fetchSoundSubCategories({required String categorySlug}) async {
    final response = await buildHttpResponse(endPoint: '${APIEndPoints.fetchSoundsSubCategories}$categorySlug', method: MethodType.get);

    return SoundSubCategoryResponse.fromJson(response);
  }

  /// Fetch sounds dynamically using category + subcategory slug

  static Future<List<SoundItem>> fetchSoundsBySlug({required String categorySlug, required String subCategorySlug, int page = 1, int pageSize = 10}) async {
    final response = await buildHttpResponse(
      endPoint: '${APIEndPoints.fetchSoundsList}?page=$page&page_size=$pageSize&category_slug=$categorySlug&subcategory_slug=$subCategorySlug',
      method: MethodType.get,
    );

    // ✅ Safely get records
    final data = response['data'];
    if (data is Map && data['records'] is List) {
      final List<Map<String, dynamic>> records = List<Map<String, dynamic>>.from(data['records']);
      return records.map((e) => SoundItem.fromJson(e)).toList();
    }

    // fallback empty list
    return [];
  }

  static Future<Map<String, dynamic>> fetchSoundsRaw({required String categorySlug, required String subCategorySlug, int page = 1}) async {
    return await buildHttpResponse(endPoint: '${APIEndPoints.fetchSoundsList}?page=$page&category_slug=$categorySlug&subcategory_slug=$subCategorySlug', method: MethodType.get);
  }

  static Future<CommonResponse> soundsMixedCreate({required Map request}) async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.soundsMixedCreate, request: request, method: MethodType.post);
    return CommonResponse.fromJson(response);
  }

  // static Future<List<MixedSoundRecord>> fetchSoundsMixedRecords({int page = 1, int pageSize = 10}) async {
  //   final response = await buildHttpResponse(endPoint: '${APIEndPoints.soundsMixedList}?page=$page&page_size=$pageSize', method: MethodType.get);
  //
  //   // Use the main response class for parsing logic consistency
  //   final mixedListResponse = SoundsMixedListResponse.fromJson(response);
  //
  //   return mixedListResponse.data?.records ?? [];
  // }
  static Future<List<MixedSoundRecord>> fetchSoundsMixedRecords({int page = 1, int pageSize = 10}) async {
    final response = await buildHttpResponse(endPoint: '${APIEndPoints.soundsMixedList}?page=$page&page_size=$pageSize', method: MethodType.get);

    // 🔥 THE FIX: If the API returns 'data' as an empty List instead of a Map,
    // catch it early and return an empty list so the app doesn't crash.
    if (response != null && response['data'] is List) {
      if ((response['data'] as List).isEmpty) {
        return []; // Return empty list immediately
      }
    }

    // If there is actual data (Map), parse it normally
    final mixedListResponse = SoundsMixedListResponse.fromJson(response);

    return mixedListResponse.data?.records ?? [];
  }

  //
  // static Future<List<MixedSoundRecord>> fetchSoundsMixedRecords({int page = 1, int pageSize = 10}) async {
  //   final response = await buildHttpResponse(endPoint: '${APIEndPoints.soundsMixedList}?page=$page&page_size=$pageSize', method: MethodType.get);
  //
  //   final data = response['data'];
  //   if (data is Map && data['records'] is List) {
  //     return List<MixedSoundRecord>.from(data['records'].map((e) => MixedSoundRecord.fromJson(e)));
  //   }
  //
  //   return [];
  // }
  // static Future<List<SoundItem>> fetchFavoriteSoundsList({required String categorySlug, required String subCategorySlug}) async {
  //   final response = await buildHttpResponse(
  //     endPoint: '${APIEndPoints.fetchSoundsList}?page=1&subcategory_slug=$subCategorySlug&category_slug=$categorySlug',
  //     method: MethodType.get,
  //   );
  //
  //   final data = response['data'];
  //   if (data is Map && data['records'] is List) {
  //     return (data['records'] as List).map((e) {
  //       // 🔥 Extract the "sound" object from the record wrapper
  //       return SoundItem.fromJson(e['sound']);
  //     }).toList();
  //   }
  //   return [];
  // }
  // static Future<List<SoundItem>> fetchFavoriteSoundsList({required String categorySlug, required String subCategorySlug}) async {
  //   final response = await buildHttpResponse(
  //     endPoint: '${APIEndPoints.fetchSoundsList}?page=1&subcategory_slug=$subCategorySlug&category_slug=$categorySlug',
  //     method: MethodType.get,
  //   );
  //
  //   // 1. Ensure response is not null and has data
  //   if (response == null || response['data'] == null) return [];
  //
  //   final data = response['data'];
  //
  //   if (data is Map && data['records'] is List) {
  //     return (data['records'] as List).map((e) {
  //       // 2. Safely check if 'sound' exists and is a Map
  //       if (e != null && e['sound'] is Map<String, dynamic>) {
  //         return SoundItem.fromJson(e['sound']);
  //       }
  //       // 3. Return a null or handle empty items (we filter them out below)
  //       return null;
  //     })
  //         .whereType<SoundItem>() // 4. This removes any nulls from the list
  //         .toList();
  //   }
  //   return [];
  // }
  // static Future<List<SoundItem>> fetchFavoriteSoundsList({int page = 1}) async {
  //   final response = await buildHttpResponse(
  //     // 🔥 Use the specific Favorite List endpoint
  //     endPoint: '${APIEndPoints.fetchFavoriteSounds}?page=$page',
  //     method: MethodType.get,
  //   );
  //
  //   if (response == null || response['data'] == null) return [];
  //
  //   final data = response['data'];
  //
  //   // Handle both cases: Data as Map (Paginated) or Data as List (Empty)
  //   if (data is Map<String, dynamic> && data['records'] is List) {
  //     final List records = data['records'];
  //
  //     return records.map((e) {
  //       // 🔥 CRITICAL: Extract the nested 'sound' object
  //       if (e != null && e['sound'] is Map<String, dynamic>) {
  //         return SoundItem.fromJson(e['sound']);
  //       }
  //       return null;
  //     }).whereType<SoundItem>().toList();
  //   }
  //
  //   return [];
  // }

  // // In your SoundsApis class
  static Future<CommonResponse> toggleFavorite({required int soundId}) async {
    final request = {"sound_id": soundId};
    final response = await buildHttpResponse(endPoint: APIEndPoints.toggleFavorite, request: request, method: MethodType.post);
    return CommonResponse.fromJson(response);
  }
}

/// SETTINGS---------------------------------------------------------------------------------------------------------------

class SettingsApis {
  static Future<CommonResponse> updateProfile({required Map<String, String> fields, File? profileImage}) async {
    final uri = Uri.parse(BASE_URL + APIEndPoints.updateProfile);

    final request = http.MultipartRequest('PUT', uri);

    /// 🔐 Authorization header
    final token = getStringAsync(AppSharedPreferenceKeys.apiToken);
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';

    /// 📤 Fields
    request.fields.addAll(fields);

    /// 🖼 Image
    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_image', profileImage.path));
    }

    /// 🔍 PRINT REQUEST
    print("========== UPDATE PROFILE API REQUEST ==========");
    print("URL: $uri");
    print("Method: PUT");
    print("Headers:");
    request.headers.forEach((k, v) => print("  $k : $v"));

    print("Fields:");
    fields.forEach((k, v) => print("  $k : $v"));

    if (profileImage != null) {
      print("Image Path: ${profileImage.path}");
    } else {
      print("Image: NULL");
    }
    print("===============================================");

    /// 🌐 SEND REQUEST
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    /// 🔍 PRINT RESPONSE
    print("========== UPDATE PROFILE API RESPONSE ==========");
    print("Status Code: ${response.statusCode}");
    print("Headers: ${response.headers}");
    print("Body:");
    print(response.body);
    print("================================================");

    /// ❗ SAFE JSON PARSE
    if (response.body.trim().startsWith('{')) {
      return CommonResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Invalid response (Not JSON)\n${response.body}");
    }
  }

  static Future<UserSettingsResponse> fetchUserSettings() async {
    final response = await buildHttpResponse(
      endPoint: APIEndPoints.userSettings, // "/users/settings/"
      method: MethodType.get,
    );

    // Convert JSON to model
    return UserSettingsResponse.fromJson(response);
  }

  // static Future<UserProfileData> fetchUserProfile() async {
  //   final response = await buildHttpResponse(endPoint: APIEndPoints.getProfile, method: MethodType.get);
  //
  //   return UserProfileData.fromJson(response);
  // }
  static Future<UserProfileData?> fetchUserProfile() async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.getProfile, method: MethodType.get);

    // Check if the response has the 'data' key before parsing
    if (response['success'] == true && response['data'] != null) {
      return UserProfileData.fromJson(response['data']);
    }
    return null;
  }

  static Future<UpdateStreakResponse> updateStreak(String date) async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.updateStreak, method: MethodType.post, request: {"date": date});
    return UpdateStreakResponse.fromJson(response);
  }

  static Future<ConsecutiveStreakResponse> getConsecutiveStreak() async {
    final response = await buildHttpResponse(
      endPoint: APIEndPoints.streak, // "users/streak/"
      method: MethodType.get,
    );

    // Parse the full response into your model
    return ConsecutiveStreakResponse.fromJson(response);
  }

  // static Future<CommonResponse> updateUserSettings(UserSettings settings) async {
  //   final uri = Uri.parse(BASE_URL + APIEndPoints.userSettings);
  //   final token = getStringAsync(AppSharedPreferenceKeys.apiToken);
  //
  //   final response = await http.put(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(settings.toJson()));
  //
  //   print("========== UPDATE SETTINGS API RESPONSE ==========");
  //   print("uri: $uri");
  //   print("Status Code: ${response.statusCode}");
  //   print("Body: ${response.body}");
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return CommonResponse.fromJson(jsonDecode(response.body));
  //   } else {
  //     throw Exception("Failed to update settings: ${response.body}");
  //   }
  // }
  static Future<CommonResponse> updateUserSettings(UserSettings settings) async {
    final uri = Uri.parse(BASE_URL + APIEndPoints.userSettings);
    final token = getStringAsync(AppSharedPreferenceKeys.apiToken);

    // 1. Prepare the request body
    final requestBody = jsonEncode(settings.toJson());

    // 2. Print Request Data for debugging
    print("🚀 ========== SENDING API REQUEST ==========");
    print("URL: $uri");
    print("Method: PUT");
    // Show only the last 5 characters of the token safely
    print("Headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ...${token.length > 5 ? token.substring(token.length - 5) : token}'}");
    print("Payload: $requestBody"); // <--- This shows the exact JSON going to the server
    print("============================================");

    try {
      final response = await http.put(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: requestBody);

      print("✅ ========== API RESPONSE RECEIVED ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("==============================================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CommonResponse.fromJson(jsonDecode(response.body));
      } else {
        print("❌ API ERROR SETTINGS: ${response.body}");
        return CommonResponse(success: false, message: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ NETWORK/PARSING ERROR: $e");
      return CommonResponse(success: false, message: e.toString());
    }
  }
  static Future<bool> updateUserLanguage(String languageCode) async {
    try {
      final request = {"language": languageCode};

      // buildHttpResponse automatically context se token uthata hai
      // aur method type PATCH use karega.
      final response = await buildHttpResponse(
        endPoint: APIEndPoints.updateUser,
        request: request,
        method: MethodType.patch,
      );

      // Agar backend success boolean bhej raha hai toh use check karein
      return response != null && response['success'] == true;
    } catch (e) {
      dev.log("❌ Update Language API Error: $e");
      return false;
    }
  }
}

/// TRACKER---------------------------------------------------------------------------------------------------------------

class TrackerApis {
  static Future<dynamic> fetchNoteCategories() async {
    final response = await buildHttpResponse(endPoint: APIEndPoints.trackerNotesCategories, method: MethodType.get);
    return response;
  }

  static Future<dynamic> createNote({required String title, required int categoryId}) async {
    final payload = {"title": title, "category_id": categoryId};

    final response = await buildHttpResponse(endPoint: APIEndPoints.createSleepNote, method: MethodType.post, request: payload);

    debugPrint("✅ Note created: ${response['data']?['note_id']}");
  }

  /// ✏️ Update Sleep Note
  static Future<CommonResponse> updateSleepNote({required int noteId, required String title}) async {
    final payload = {"title": title};

    final response = await buildHttpResponse(endPoint: '${APIEndPoints.updateSleepNote}$noteId/', method: MethodType.put, request: payload);

    return CommonResponse.fromJson(response);
  }

  /// 🗑 Delete Sleep Note
  static Future<CommonResponse> deleteSleepNote({required int noteId}) async {
    final response = await buildHttpResponse(endPoint: '${APIEndPoints.updateSleepNote}$noteId/', method: MethodType.delete);

    return CommonResponse.fromJson(response);
  }

  /// 🌙 Start Sleep Tracker
  static Future<StartSleepTrackerResponse> startSleepTracker({required String wakeUpTime, required List<int> noteIds, required String description, required int heartRate}) async {
    final payload = {
      "wake_up_time": wakeUpTime, // "10:00"
      "note_ids": noteIds, // [1,2,3]
      "description": description,
      "heart_rate": heartRate,
    };
    final prefs = await SharedPreferences.getInstance();
    final int activeId = prefs.getInt('sleep_tracker_id') ?? 0;
    final bool isTracking = prefs.getBool(AppSharedPreferenceKeys.isSleepTrackingActive) ?? false;
    print("active id -------$activeId");
    print("isTracking -------$isTracking");

    final response = await buildHttpResponse(endPoint: APIEndPoints.startSleepTracker, method: MethodType.post, request: payload);

    return StartSleepTrackerResponse.fromJson(response);
  }

  /// 🌙 Stop Sleep Tracker
  static Future<CommonResponse> stopSleepTracker({required int sleepTrackerId}) async {
    final payload = {"sleep_tracker_id": sleepTrackerId};

    final response = await buildHttpResponse(endPoint: APIEndPoints.stopSleepTracker, method: MethodType.post, request: payload);

    return CommonResponse.fromJson(response);
  }

  /// 🎙 Upload Sleep Tracker Audio
  static Future<CommonResponse> uploadTrackerAudio({required int sleepTrackerId, required File audioFile, required String recordedAt}) async {
    final fields = {
      "sleep_tracker_id": sleepTrackerId,
      "recorded_at": recordedAt, // format: yyyy-MM-dd HH:mm
    };

    final response = await buildMultipartHttpResponse(endPoint: APIEndPoints.uploadTrackerAudio, fields: fields, file: audioFile, fileKey: "audio_file", method: MethodType.post);

    return CommonResponse.fromJson(response);
  }

  static Future<TrackerStatusResponse> checkTrackerStatus() async {
    final response = await buildHttpResponse(
      endPoint: 'tracker/status/', // Ensure trailing slash as per your Postman
      method: MethodType.get,
    );
    return TrackerStatusResponse.fromJson(response);
  }
}

/// CHAT---------------------------------------------------------------------------------------------------------------

class ChatApis {
  static Future<ChatResponse> sendMessage({required String question, int? parentMessageId}) async {
    final payload = {"question": question, if (parentMessageId != null) "parent_message_id": parentMessageId};

    final response = await buildHttpResponse(endPoint: APIEndPoints.chat, method: MethodType.post, request: payload);

    return ChatResponse.fromJson(response);
  }
}

/// PROGRESS ---------------------------------------------------------------------------------------------------------------

class ProgressApis {
  /// 📊 Sleep Duration Chart
  static Future<SleepDurationChartResponse> getSleepDurationChart({
    required String dataType, // weekly / monthly / yearly
    String? date,
  }) async {
    final endpoint = "${APIEndPoints.sleepDurationChart}?data_type=$dataType";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return SleepDurationChartResponse.fromJson(response);
  }

  static Future<SleepCalendarResponse> getSleepCalendar({required String month}) async {
    // Pass month in format 'YYYY-MM'
    final endpoint = "${APIEndPoints.sleepCalendar}?month=$month";
    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return SleepCalendarResponse.fromJson(response);
  }

  static Future<SleepConsistencyResponse> getSleepConsistency({
    required String dataType, // weekly / monthly / yearly
    String? date,
  }) async {
    String endpoint = "${APIEndPoints.sleepConsistencyData}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return SleepConsistencyResponse.fromJson(response);
  }

  // static Future<KeyInsightsResponse> getKeyInsights({
  //   required String dataType, // weekly / monthly / yearly
  // }) async {
  //   final endpoint = "${APIEndPoints.keyInsights}?data_type=$dataType";
  //
  //   final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
  //
  //   return KeyInsightsResponse.fromJson(response);
  // }
  static Future<KeyInsightsResponse> getKeyInsights({required String dataType, String? date}) async {
    String endpoint = "${APIEndPoints.keyInsights}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return KeyInsightsResponse.fromJson(response);
  }

  static Future<AchievementBadgesResponse> getAchievementBadges({required String dataType, String? date}) async {
    // final endpoint = APIEndPoints.achievementBadges;
    String endpoint = "${APIEndPoints.achievementBadges}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return AchievementBadgesResponse.fromJson(response);
  }

  /// 🌙 GET: Retrieve list of analyzed dreams
  static Future<DreamListResponse> getDreamList() async {
    const endpoint = APIEndPoints.dreamList;

    // No 'request' or 'body' parameter needed for this GET call
    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return DreamListResponse.fromJson(response);
  }

  static Future<DreamListResponse> getDreamAnalysis({required String description, required int dreamId}) async {
    final response = await buildHttpResponse(
      endPoint: APIEndPoints.analyzeDream,
      method: MethodType.post,
      request: {
        "dream_description": description, // Use the dynamic description, not hardcoded!
        "dream_id": dreamId,
      },
    );

    // 🔥 THE FIX:
    // The analyze API returns 'data' as a single Map, but your DreamListResponse
    // expects it to be a List. We wrap it in a list so the model parses it perfectly.
    if (response != null && response['data'] is Map<String, dynamic>) {
      response['data'] = [response['data']];
    }

    return DreamListResponse.fromJson(response);
  }

  // static Future<SleepAudioResponse> getSleepAudioRecordings({required String dataType, String? date}) async {
  //   final response = await buildHttpResponse(
  //     // 🔥 Changed from 'sleep-audio-list/' to 'sleep-recorder'
  //     endPoint: APIEndPoints.sleepRecorder,
  //     method: MethodType.get,
  //   );
  static Future<SleepAudioResponse> getSleepAudioRecordings({required String dataType, String? date}) async {
    String endpoint = "${APIEndPoints.sleepRecorder}?data_type=$dataType";
    if (date != null && date.isNotEmpty) {
      endpoint += "&date=$date";
    }
    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return SleepAudioResponse.fromJson(response);
  }

  /// 😴 Snoring Intensity Data
  // static Future<SnoringIntensityResponse> getSnoringIntensity({
  //   required String dataType, // weekly / monthly / yearly
  // }) async {
  //   final endpoint = "${APIEndPoints.snoringIntensity}?data_type=$dataType";
  //
  //   final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
  //
  //   return SnoringIntensityResponse.fromJson(response);
  // }
  static Future<SnoringIntensityResponse> getSnoringIntensity({required String dataType, String? date}) async {
    String endpoint = "${APIEndPoints.snoringIntensity}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return SnoringIntensityResponse.fromJson(response);
  }

  /// ✨ Retrieve AI-generated sleep insights
  static Future<AIInsightsResponse> getAIInsights({required String dataType, String? date}) async {
    //  final endpoint = APIEndPoints.aiInsights; // Ensure this is "api/v1/progress/ai-insights/"
    String endpoint = "${APIEndPoints.aiInsights}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";
    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);

    return AIInsightsResponse.fromJson(response);
  }

  static Future<RecommendationsResponse> getRecommendations({required String type, String? date}) async {
    // final endpoint = APIEndPoints.personalizedRecommendations;
    String endpoint = "${APIEndPoints.personalizedRecommendations}?data_type=$type";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";
    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return RecommendationsResponse.fromJson(response);
  }

  // static Future<SleepQualityResponse> getSleepQuality({required String dataType}) async {
  //   final endpoint = "${APIEndPoints.sleepQuality}?data_type=$dataType";
  //   final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
  //   return SleepQualityResponse.fromJson(response);
  // }
  static Future<SleepQualityResponse> getSleepQuality({required String dataType, String? date}) async {
    // Append &date=YYYY-MM-DD if date is provided
    String endpoint = "${APIEndPoints.sleepQuality}?data_type=$dataType";
    if (date != null && date.isNotEmpty) endpoint += "&date=$date";

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return SleepQualityResponse.fromJson(response);
  }

  // static Future<SleepStagesResponse> getSleepStages({required String date}) async {
  //   // nightly view requires a date parameter
  //   final endpoint = "${APIEndPoints.sleepStages}?data_type=nightly&$date";
  //   final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
  //   return SleepStagesResponse.fromJson(response);
  // }
  // static Future<SleepStagesResponse> getSleepStages({required String type, String? date}) async {
  //   // Base endpoint with the dynamic data_type
  //   String endpoint = "${APIEndPoints.sleepStages}?data_type=$type";
  //
  //   // If it's nightly, properly append the date parameter
  //   if (type == "nightly" && date != null && date.isNotEmpty) {
  //     endpoint += "&date=$date";
  //   }
  //
  //   final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
  //   return SleepStagesResponse.fromJson(response);
  // }
  static Future<SleepStagesResponse> getSleepStages({required String type, String? date}) async {
    String endpoint = "${APIEndPoints.sleepStages}?data_type=$type";

    // The backend usually expects 'today' or 'nightly' for date-specific views
    if (date != null && date.isNotEmpty) {
      endpoint += "&date=$date";
    }

    final response = await buildHttpResponse(endPoint: endpoint, method: MethodType.get);
    return SleepStagesResponse.fromJson(response);
  }

  // Step 16: Start Session
  static Future<Map<String, dynamic>> startDreamSession() async {
    return await buildHttpResponse(endPoint: "progress/dreambot/start/", method: MethodType.post, request: {});
  }

  // Step 17 & 18: Send Message to Sleepy
  static Future<Map<String, dynamic>> sendDreamMessage(int dreamId, String message) async {
    return await buildHttpResponse(endPoint: "progress/dreambot/$dreamId/message/", method: MethodType.post, request: {"message": message});
  }

  // Step 19: Final Analysis (Generates Image & Summary)
  static Future<Map<String, dynamic>> finalizeDreamAnalysis(int dreamId) async {
    return await buildHttpResponse(endPoint: "progress/dreambot/$dreamId/analyze/", method: MethodType.post, request: {});
  }

  // --- Sleep Quiz ---
  static Future<QuizResultResponse?> submitSleepQuiz(Map<String, dynamic> payload) async {
    try {
      // 🔥 Changed to use buildHttpResponse for consistency with your architecture
      final response = await buildHttpResponse(endPoint: APIEndPoints.sleepQuiz, method: MethodType.post, request: payload);

      if (response != null) {
        return QuizResultResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Sleep Quiz API Error: $e");
      return null;
    }
  }
}


