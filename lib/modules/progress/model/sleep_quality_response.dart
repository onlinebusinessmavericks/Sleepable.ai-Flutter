
class SleepQualityResponse {
  final bool success;
  final String message;
  final SleepQualityWrapper data;

  SleepQualityResponse({required this.success, required this.message, required this.data});

  factory SleepQualityResponse.fromJson(Map<String, dynamic> json) {
    return SleepQualityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: SleepQualityWrapper.fromJson(json['data'] ?? {}),
    );
  }
}

class SleepQualityWrapper {
  final double sleepScore;
  final double durationScore;
  final double environmentScore;
  final double sleepPhasesScore;
  final String timeInBed;
  final String timeAsleep;
  final double durationHours;
  final List<SleepQualityPoint> breakdown;

  SleepQualityWrapper({
    required this.sleepScore,
    required this.durationScore,
    required this.environmentScore,
    required this.sleepPhasesScore,
    required this.timeInBed,
    required this.timeAsleep,
    required this.breakdown,
    required this.durationHours,
  });

  factory SleepQualityWrapper.fromJson(Map<String, dynamic> json) {
    // Determine the breakdown list: try 'breakdown' then 'hourly'
    var rawBreakdown = json['breakdown'] ?? json['hourly'] ?? [];

    return SleepQualityWrapper(
      // Handling Today's key vs Historical Date keys
      sleepScore: (json['sleep_score'] ?? json['quality_score'] ?? json['summary']?['avg_quality_score'] ?? 0.0).toDouble(),
      durationScore: (json['duration_score'] ?? 0.0).toDouble(),
      durationHours: (json['duration_hours'] ?? 0.0).toDouble(),

      // Environment vs Noise
      environmentScore: (json['environment_score'] ?? json['noise_score'] ?? 0.0).toDouble(),

      // Sleep Phases vs Stage Score
      sleepPhasesScore: (json['sleep_phases_score'] ?? json['stage_score'] ?? 0.0).toDouble(),

      // Time in bed: Historical mein duration_hours aa raha hai
      timeInBed: json['time_in_bed'] ?? (json['duration_hours'] != null ? "${json['duration_hours']}h" : "--"),

      // Time asleep: check for minutes or hours
      timeAsleep: json['time_asleep_minutes']?.toString() ?? json['duration_hours']?.toString() ?? "0",

      breakdown: (rawBreakdown as List)
          .map((e) => SleepQualityPoint.fromJson(e))
          .toList(),
    );
  }
}
class SleepQualityPoint {
  final String label;
  final double score;
  final int stars;

  SleepQualityPoint({required this.label, required this.score, required this.stars});

  factory SleepQualityPoint.fromJson(Map<String, dynamic> json) {
    String generatedLabel = '';

    if (json.containsKey('interval')) {
      // "04:00 AM - 05:00 AM" -> "04 AM" short label for chart
      generatedLabel = json['interval'].toString().split(' ')[0] + " " + json['interval'].toString().split(' ')[1];
    } else if (json.containsKey('day')) {
      generatedLabel = json['day'].toString().substring(0, 3);
    } else if (json.containsKey('month')) {
      generatedLabel = json['month'].toString().substring(0, 3);
    } else if (json.containsKey('year')) {
      generatedLabel = json['year'].toString();
    }

    return SleepQualityPoint(
      label: generatedLabel,
      score: (json['quality_score'] ?? 0).toDouble(),
      stars: json['star_rating'] ?? 0,
    );
  }
}