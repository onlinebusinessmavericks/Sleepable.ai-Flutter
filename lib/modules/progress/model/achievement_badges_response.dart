class AchievementBadgesResponse {
  final bool success;
  final String message;
  final AchievementData? data;

  AchievementBadgesResponse({required this.success, required this.message, this.data});

  factory AchievementBadgesResponse.fromJson(Map<String, dynamic> json) {
    return AchievementBadgesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AchievementData.fromJson(json['data']) : null,
    );
  }
}

class AchievementData {
  final bool earlyBird;
  final bool nightOwl;
  final bool sleepChampion;
  final String sleepChampionDesc; // Added to show dynamic requirement
  final int sleepableWithYouCount;
  final int sleepChampQualifying; // Added
  final int sleepChampRequired;

  AchievementData({
    required this.earlyBird,
    required this.nightOwl,
    required this.sleepChampion,
    required this.sleepChampionDesc,
    required this.sleepableWithYouCount,
    required this.sleepChampQualifying,
    required this.sleepChampRequired,

  });

  factory AchievementData.fromJson(Map<String, dynamic> json) {
    return AchievementData(
      // Accessing .earned inside the nested objects
      earlyBird: json['early_bird']?['earned'] ?? false,
      nightOwl: json['night_owl']?['earned'] ?? false,
      sleepChampion: json['sleep_champion']?['earned'] ?? false,

      // Pulling the description to use as a subtitle in UI
      sleepChampionDesc: json['sleep_champion']?['description'] ?? "Wake up early",

      // 🔥 Variable name changed from 'sleepable_with_you_count' to 'sleepable_with_you_days'
      sleepableWithYouCount: json['sleepable_with_you_days'] ?? 0,
      sleepChampQualifying: json['sleep_champion']?['qualifying_days'] ?? 0,
      sleepChampRequired: json['sleep_champion']?['required_days'] ?? 0,
    );
  }
}