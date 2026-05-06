class SleepStagesResponse {
  final bool success;
  final String message;
  final SleepStagesData? data;

  SleepStagesResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SleepStagesResponse.fromJson(Map<String, dynamic> json) {
    return SleepStagesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SleepStagesData.fromJson(json['data']) : null,
    );
  }
}

class SleepStagesData {
  final String dataType;
  final String date;
  final SleepStagesSummary summary;
  final List<SleepInterval> intervals;
  final List<String> hourLabels;

  SleepStagesData({
    required this.dataType,
    required this.date,
    required this.summary,
    required this.intervals,
    required this.hourLabels,
  });

  factory SleepStagesData.fromJson(Map<String, dynamic> json) {
    return SleepStagesData(
      dataType: json['data_type'] ?? '',
      date: json['date'] ?? '',
      summary: SleepStagesSummary.fromJson(json['summary'] ?? {}),
      intervals: (json['intervals'] as List?)
          ?.map((item) => SleepInterval.fromJson(item))
          .toList() ??
          [],
      hourLabels: (json['hour_labels'] as List?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
    );
  }
}

class SleepStagesSummary {
  final int totalAwakeMinutes;
  final int totalDreamMinutes;
  final int totalLightSleepMinutes;
  final int totalDeepSleepMinutes;
  final double awakePercentage;
  final double dreamPercentage;
  final double lightSleepPercentage;
  final double deepSleepPercentage;

  SleepStagesSummary({
    required this.totalAwakeMinutes,
    required this.totalDreamMinutes,
    required this.totalLightSleepMinutes,
    required this.totalDeepSleepMinutes,
    required this.awakePercentage,
    required this.dreamPercentage,
    required this.lightSleepPercentage,
    required this.deepSleepPercentage,
  });

  factory SleepStagesSummary.fromJson(Map<String, dynamic> json) {
    return SleepStagesSummary(
      totalAwakeMinutes: json['total_awake_minutes'] ?? 0,
      totalDreamMinutes: json['total_dream_minutes'] ?? 0,
      totalLightSleepMinutes: json['total_light_sleep_minutes'] ?? 0,
      totalDeepSleepMinutes: json['total_deep_sleep_minutes'] ?? 0,
      // .toDouble() ensures it doesn't crash if the API sends an int (like 0) instead of a double (like 0.0)
      awakePercentage: (json['awake_percentage'] ?? 0).toDouble(),
      dreamPercentage: (json['dream_percentage'] ?? 0).toDouble(),
      lightSleepPercentage: (json['light_sleep_percentage'] ?? 0).toDouble(),
      deepSleepPercentage: (json['deep_sleep_percentage'] ?? 0).toDouble(),
    );
  }
}

class SleepInterval {
  final String startTime;
  final String endTime;
  final String stageName;
  final int stageIndex;

  SleepInterval({
    required this.startTime,
    required this.endTime,
    required this.stageName,
    required this.stageIndex,
  });

  factory SleepInterval.fromJson(Map<String, dynamic> json) {
    return SleepInterval(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      stageName: json['stage_name'] ?? '',
      stageIndex: json['stage_index'] ?? 0,
    );
  }
}