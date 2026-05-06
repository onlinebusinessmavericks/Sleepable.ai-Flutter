class UserSettingsResponse {
  final bool success;
  final UserSettingsData? data;

  UserSettingsResponse({required this.success, this.data});

  factory UserSettingsResponse.fromJson(Map<String, dynamic> json) {
    return UserSettingsResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? UserSettingsData.fromJson(json['data']) : null,
    );
  }
}

class UserSettingsData {
  final bool alarmEnabled;
  final String alarmTime;
  final String meridiem;
  final String repeatType;
  final List<String> repeatDays;
  final int melodyId;
  final int snoozeMinutes;
  final bool fadeIn;
  final String bedtime;
  final String wakeUpTime;
  final bool sleepReminders;
  final String remindAt;
  final bool batteryWorning;
  final bool heartRateTracking;
  final bool notifications;

  UserSettingsData({
    required this.alarmEnabled,
    required this.alarmTime,
    required this.meridiem,
    required this.repeatType,
    required this.repeatDays,
    required this.melodyId,
    required this.snoozeMinutes,
    required this.fadeIn,
    required this.bedtime,
    required this.wakeUpTime,
    required this.sleepReminders,
    required this.remindAt,
    required this.batteryWorning,
    required this.heartRateTracking,
    required this.notifications,
  });

  factory UserSettingsData.fromJson(Map<String, dynamic> json) {
    return UserSettingsData(
      alarmEnabled: json['alarm_enabled'] ?? false,
      alarmTime: json['alarm_time'] ?? '',
      meridiem: json['meridiem'] ?? '',
      repeatType: json['repeat_type'] ?? '',
      repeatDays: json['repeat_days'] != null
          ? List<String>.from(json['repeat_days'])
          : [],
      melodyId: json['melody_id'] ?? 0,
      snoozeMinutes: json['snooze_minutes'] ?? 0,
      fadeIn: json['fade_in'] ?? false,
      bedtime: json['bedtime'] ?? '',
      wakeUpTime: json['wake_up_time'] ?? '',
      sleepReminders: json['sleep_reminders'] ?? false,
      remindAt: json['remind_at'] ?? '',
      batteryWorning: json['battery_worning'] ?? false,
      heartRateTracking: json['heart_rate_tracking'] ?? false,
      notifications: json['notifications'] ?? false,
    );
  }

  /// ✅ copyWith to update immutable fields
  UserSettingsData copyWith({
    bool? alarmEnabled,
    bool? sleepReminders,
    bool? heartRateTracking,
    bool? notifications,
    String? alarmTime,
    String? meridiem,
    String? repeatType,
    List<String>? repeatDays,
    int? melodyId,
    int? snoozeMinutes,
    bool? fadeIn,
    String? bedtime,
    String? wakeUpTime,
    String? remindAt,
    bool? batteryWorning,
  }) {
    return UserSettingsData(
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      sleepReminders: sleepReminders ?? this.sleepReminders,
      heartRateTracking: heartRateTracking ?? this.heartRateTracking,
      notifications: notifications ?? this.notifications,
      alarmTime: alarmTime ?? this.alarmTime,
      meridiem: meridiem ?? this.meridiem,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      melodyId: melodyId ?? this.melodyId,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      fadeIn: fadeIn ?? this.fadeIn,
      bedtime: bedtime ?? this.bedtime,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      remindAt: remindAt ?? this.remindAt,
      batteryWorning: batteryWorning ?? this.batteryWorning,
    );
  }
}
