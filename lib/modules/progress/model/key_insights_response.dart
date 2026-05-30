class KeyInsightsResponse {
  final bool success;
  final String message;
  final KeyInsightsData data;

  KeyInsightsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory KeyInsightsResponse.fromJson(Map<String, dynamic> json) {
    return KeyInsightsResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: KeyInsightsData.fromJson(json["data"] ?? {}),
    );
  }
}


class KeyInsightsData {
  final double averageSleepHours;
  final double sleepDurationTrend; // New
  final double sleepQualityScore;
  final double sleepQualityTrend; // New
  final double sleepStreakDays;
  final double consistencyScore;
  final double consistencyTrend; // New

  KeyInsightsData({
    required this.averageSleepHours,
    required this.sleepDurationTrend,
    required this.sleepQualityScore,
    required this.sleepQualityTrend,
    required this.sleepStreakDays,
    required this.consistencyScore,
    required this.consistencyTrend,
  });

  factory KeyInsightsData.fromJson(Map<String, dynamic> json) {
    return KeyInsightsData(
      averageSleepHours: (json["average_sleep_hours"] ?? 0).toDouble(),
      sleepDurationTrend: (json["sleep_duration_trend_minutes"] ?? 0).toDouble(),
      sleepQualityScore: (json["sleep_quality_score"] ?? 0).toDouble(),
      sleepQualityTrend: (json["sleep_quality_trend_pct"] ?? 0).toDouble(),
      sleepStreakDays: (json["sleep_streak_days"] ?? 0).toDouble(),
      consistencyScore: (json["consistency_score"] ?? 0).toDouble(),
      consistencyTrend: (json["consistency_trend_pct"] ?? 0).toDouble(),
    );
  }
}