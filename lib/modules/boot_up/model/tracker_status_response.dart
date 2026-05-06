class TrackerStatusResponse {
  final bool success;
  final TrackerStatusData data;

  TrackerStatusResponse({required this.success, required this.data});

  factory TrackerStatusResponse.fromJson(Map<String, dynamic> json) {
    return TrackerStatusResponse(
      success: json['success'] ?? false,
      data: TrackerStatusData.fromJson(json['data'] ?? {}),
    );
  }
}

class TrackerStatusData {
  final bool isRunning;
  final int sleepTrackerId;

  TrackerStatusData({required this.isRunning, required this.sleepTrackerId});

  factory TrackerStatusData.fromJson(Map<String, dynamic> json) {
    return TrackerStatusData(
      isRunning: json['is_running'] ?? false,
      sleepTrackerId: json['sleep_tracker_id'] ?? 0,
    );
  }
}