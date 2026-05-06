class SleepConsistencyResponse {
  final bool success;
  final String message;
  final SleepConsistencyData data;

  SleepConsistencyResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SleepConsistencyResponse.fromJson(Map<String, dynamic> json) {
    return SleepConsistencyResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: SleepConsistencyData.fromJson(json["data"] ?? {}),
    );
  }
}

class SleepConsistencyData {
  final String? averageBedTime;
  final String? averageWakeTime;
  final double bedtimeRegularity;
  final double waketimePattern;
  final String sleepWindowVariance; // 🔥 Added this

  SleepConsistencyData({
    required this.averageBedTime,
    required this.averageWakeTime,
    required this.bedtimeRegularity,
    required this.waketimePattern,
    required this.sleepWindowVariance,
  });

  factory SleepConsistencyData.fromJson(Map<String, dynamic> json) {
    return SleepConsistencyData(
      averageBedTime: json["average_bed_time"],
      averageWakeTime: json["average_wake_time"],
      bedtimeRegularity: (json["bedtime_regularity"] ?? 0).toDouble(),
      waketimePattern: (json["waketime_pattern"] ?? 0).toDouble(),
      // 🔥 Convert int from JSON to String for UI display (e.g., "1 min")
      sleepWindowVariance: "${json["sleep_window_variance"] ?? 0} min",
    );
  }
}