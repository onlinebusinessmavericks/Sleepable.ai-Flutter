class SleepCalendarResponse {
  final bool success;
  final List<CalendarMonth> months;

  SleepCalendarResponse({required this.success, required this.months});

  factory SleepCalendarResponse.fromJson(Map<String, dynamic> json) {
    return SleepCalendarResponse(
      success: json['success'] ?? false,
      months: (json['data']['months'] as List? ?? [])
          .map((m) => CalendarMonth.fromJson(m))
          .toList(),
    );
  }
}

class CalendarMonth {
  final String monthLabel; // e.g., "2026-03"
  final List<CalendarDay> days;

  CalendarMonth({required this.monthLabel, required this.days});

  factory CalendarMonth.fromJson(Map<String, dynamic> json) {
    return CalendarMonth(
      monthLabel: json['month'],
      days: (json['days'] as List? ?? [])
          .map((d) => CalendarDay.fromJson(d))
          .toList(),
    );
  }
}

class CalendarDay {
  final String date;
  final bool hasSleep;

  CalendarDay({required this.date, required this.hasSleep});

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
    date: json['date'],
    hasSleep: json['has_sleep'] ?? false,
  );
}