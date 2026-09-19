class SnoringIntensityResponse {
  bool? success;
  String? message;
  SnoringWrapper? data;

  SnoringIntensityResponse({this.success, this.message, this.data});

  SnoringIntensityResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? SnoringWrapper.fromJson(json['data']) : null;
  }
}

class SnoringWrapper {
  String? dataType;
  List<SnoringBreakdown>? breakdown;

  SnoringWrapper({this.dataType, this.breakdown});

  SnoringWrapper.fromJson(Map<String, dynamic> json) {
    dataType = json['data_type'];
    // Today sends `hourly_breakdown`; Week/Month send `breakdown`.
    final raw = json['breakdown'] ?? json['hourly_breakdown'];
    if (raw != null) {
      breakdown = <SnoringBreakdown>[];
      raw.forEach((v) {
        breakdown!.add(SnoringBreakdown.fromJson(v));
      });
    }
  }
}

class SnoringBreakdown {
  String? label;
  double? avgIntensityPct;
  int? totalSeconds;

  SnoringBreakdown({this.label, this.avgIntensityPct, this.totalSeconds});

  SnoringBreakdown.fromJson(Map<String, dynamic> json) {
    // Dynamically pick the label
    if (json.containsKey('day') && json['day'] != null) {
      label = json['day'].toString().substring(0, 3);
    } else if (json.containsKey('month') && json['month'] != null) {
      label = json['month'].toString().substring(0, 3);
    } else if (json.containsKey('year') && json['year'] != null) {
      label = json['year'].toString();
    } else if (json['interval'] != null) {
      // "11:00 PM - 12:00 AM" → "11 PM" so hourly labels fit the chart.
      final start = json['interval'].toString().split(' - ').first.trim();
      label = start.replaceFirst(':00', '');
    }

    // 🔥 These match the names used in the Controller above
    avgIntensityPct = (json['avg_intensity_pct'] ?? 0).toDouble();
    totalSeconds = json['total_snoring_seconds'] ?? 0;
  }
}

class SnorePoint {
  final String time;
  final int intensity;
  final int duration;
  final int frequency;

  SnorePoint({
    required this.time,
    required this.intensity,
    required this.duration,
    required this.frequency
  });
}