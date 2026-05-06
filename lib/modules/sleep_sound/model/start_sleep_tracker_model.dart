class StartSleepTrackerResponse {
  final bool success;
  final String message;
  final SleepTrackerData? data;

  StartSleepTrackerResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory StartSleepTrackerResponse.fromJson(Map<String, dynamic> json) {
    return StartSleepTrackerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SleepTrackerData.fromJson(json['data'])
          : null,
    );
  }
}
class SleepTrackerData {
  final int sleepTrackerId;
  final DateTime sleepStart;
  final String description;
  final int avgHeartRate;
  final List<int> notes;
  final String wakeUpTime;

  SleepTrackerData({
    required this.sleepTrackerId,
    required this.sleepStart,
    required this.description,
    required this.avgHeartRate,
    required this.notes,
    required this.wakeUpTime,
  });

  factory SleepTrackerData.fromJson(Map<String, dynamic> json) {
    return SleepTrackerData(
      sleepTrackerId: json['sleep_tracker_id'],
      sleepStart: DateTime.parse(json['sleep_start']),
      description: json['description'] ?? '',
      avgHeartRate: json['avg_heart_rate'] ?? 0,
      notes: List<int>.from(json['notes'] ?? []),
      wakeUpTime: json['wake_up_time'] ?? '',
    );
  }
}
