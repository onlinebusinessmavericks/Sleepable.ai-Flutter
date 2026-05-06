class SleepDurationChartResponse {
  final bool success;
  final String message;
  final SleepDurationData data;

  SleepDurationChartResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SleepDurationChartResponse.fromJson(Map<String, dynamic> json) {
    return SleepDurationChartResponse(
      success: json['success'],
      message: json['message'],
      data: SleepDurationData.fromJson(json['data']),
    );
  }
}

class SleepDurationData {
  final double averageHours;
  final List<SleepBreakdown> breakdown;

  SleepDurationData({
    required this.averageHours,
    required this.breakdown,
  });

  factory SleepDurationData.fromJson(Map<String, dynamic> json) {
    return SleepDurationData(
      averageHours: (json['average_hours'] ?? 0).toDouble(),
      breakdown: (json['breakdown'] as List)
          .map((e) => SleepBreakdown.fromJson(e))
          .toList(),
    );
  }
}
class SleepBreakdown {
  final String label;
  final double value; // Generic name to hold whichever hour value we get

  SleepBreakdown({
    required this.label,
    required this.value,
  });

  factory SleepBreakdown.fromJson(Map<String, dynamic> json) {
    String generatedLabel = '';

    // Helper to shorten "Monday" -> "Mon" or "January" -> "Jan"
    String shorten(String text) {
      return text.length >= 3 ? text.substring(0, 3) : text;
    }

    // 1. Identify the Label (Handles day, month, or year keys)
    if (json.containsKey('day')) {
      generatedLabel = shorten(json['day']);
    } else if (json.containsKey('month')) {
      generatedLabel = shorten(json['month']);
    } else if (json.containsKey('year')) {
      generatedLabel = json['year'].toString();
    }

    // 2. Identify the Value (Handles total_hours or average_hours keys)
    double hourValue = 0.0;
    if (json.containsKey('total_hours')) {
      hourValue = (json['total_hours'] ?? 0).toDouble();
    } else if (json.containsKey('average_hours')) {
      hourValue = (json['average_hours'] ?? 0).toDouble();
    }

    return SleepBreakdown(
      label: generatedLabel,
      value: hourValue,
    );
  }
}