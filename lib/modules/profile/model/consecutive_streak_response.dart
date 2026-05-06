class ConsecutiveStreakResponse {
  final bool? success;
  final StreakData? data;

  ConsecutiveStreakResponse({this.success, this.data});

  factory ConsecutiveStreakResponse.fromJson(Map<String, dynamic> json) {
    return ConsecutiveStreakResponse(
      success: json['success'],
      data: json['data'] != null ? StreakData.fromJson(json['data']) : null,
    );
  }
}

class StreakData {
  final int? currentStreak;
  final int? bestStreak;
  final List<StreakDay>? streakCalendar;
  final List<Milestone>? milestones;

  StreakData({this.currentStreak, this.bestStreak, this.streakCalendar, this.milestones});

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'],
      bestStreak: json['best_streak'],
      streakCalendar: json['streak_calendar'] != null
          ? List<StreakDay>.from(json['streak_calendar'].map((x) => StreakDay.fromJson(x)))
          : null,
      milestones: json['milestones'] != null
          ? List<Milestone>.from(json['milestones'].map((x) => Milestone.fromJson(x)))
          : null,
    );
  }
}

class StreakDay {
  final String date;
  final bool hasSleep;

  StreakDay({required this.date, required this.hasSleep});

  factory StreakDay.fromJson(Map<String, dynamic> json) => StreakDay(
    date: json['date'],
    hasSleep: json['has_sleep'] ?? false,
  );
}

class Milestone {
  final int? days;
  final bool? achieved;

  Milestone({this.days, this.achieved});

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      days: json['days'],
      achieved: json['achieved'] ?? false,
    );
  }
}