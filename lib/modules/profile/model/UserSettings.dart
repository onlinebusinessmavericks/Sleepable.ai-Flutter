import 'dart:convert';

class UserSettings {
  bool? alarmEnabled;
  String? alarmTime;
  String? meridiem;
  String? repeatType;
  List<String>? repeatDays;
  int? melodyId;
  int? snoozeMinutes;
  bool? fadeIn;
  String? bedtime;
  String? wakeUpTime;
  bool? sleepReminders;
  String? remindAt;
  bool? batteryWarning;
  bool? heartRateTracking;
  bool? notifications;
  final String timezone;

  UserSettings({
    this.alarmEnabled,
    this.alarmTime,
    this.meridiem,
    this.repeatType,
    this.repeatDays,
    this.melodyId,
    this.snoozeMinutes,
    this.fadeIn,
    this.bedtime,
    this.wakeUpTime,
    this.sleepReminders,
    this.remindAt,
    this.batteryWarning,
    this.heartRateTracking,
    this.notifications,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      "alarm_enabled": alarmEnabled,
      "alarm_time": alarmTime,
      "meridiem": meridiem,
      "repeat_type": repeatType,
      "repeat_days": repeatDays,
      "melody_id": melodyId,
      "snooze_minutes": snoozeMinutes,
      "fade_in": fadeIn,
      "bedtime": bedtime,
      "wake_up_time": wakeUpTime,
      "sleep_reminders": sleepReminders,
      "remind_at": remindAt,
      "battery_worning": batteryWarning, // matching your Postman typo 'worning'
      "heart_rate_tracking": heartRateTracking,
      "notifications": notifications,
      'timezone': timezone,
    };
  }
}