class UpdateStreakResponse {
  final bool success;
  final String message;
  final StreakData? data;

  UpdateStreakResponse({required this.success, required this.message, this.data});

  factory UpdateStreakResponse.fromJson(Map<String, dynamic> json) {
    return UpdateStreakResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? StreakData.fromJson(json['data']) : null,
    );
  }
}

class StreakData {
  final int streakCount;
  final double avgTime;

  StreakData({required this.streakCount, required this.avgTime});

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      streakCount: json['streak_count'] ?? 0,
      avgTime: (json['avg_time'] ?? 0.0).toDouble(),
    );
  }
}