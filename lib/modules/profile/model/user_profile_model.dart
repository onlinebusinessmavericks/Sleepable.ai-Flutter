class UserProfileData {
  final String? name;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? profileImage;
  final String? avatarUrl;

  // New Fields from response
  final int? daysWithSleepable;
  final String? joinedDate;
  final int? trackedNights;
  final double? avgSleepHours;
  final int? avgSleepScore;
  final int? streakCount;
  final int? bestStreak;
  final List<Milestone>? milestones;

  UserProfileData({
    this.name,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profileImage,
    this.avatarUrl,
    this.daysWithSleepable,
    this.joinedDate,
    this.trackedNights,
    this.avgSleepHours,
    this.avgSleepScore,
    this.streakCount,
    this.bestStreak,
    this.milestones,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      name: json['name'],
      email: json['email'],
      countryCode: json['country_code'] ?? json['countryCode'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      gender: json['gender'],
      address: json['address'],
      profileImage: json['profile_image'] ?? json['profileImage'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],

      // Parsing new fields
      daysWithSleepable: json['days_with_sleepable'],
      joinedDate: json['joined_date'],
      trackedNights: json['tracked_nights'],
      // Using .toDouble() ensures safety if the API sends an int
      avgSleepHours: json['avg_sleep_hours']?.toDouble(),
      avgSleepScore: json['avg_sleep_score'],
      streakCount: json['streak_count'],
      bestStreak: json['best_streak'],
      milestones: json['milestones'] != null
          ? List<Milestone>.from(
          json['milestones'].map((x) => Milestone.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'country_code': countryCode,
    'phone_number': phoneNumber,
    'date_of_birth': dateOfBirth,
    'gender': gender,
    'address': address,
    'profile_image': profileImage,
    'avatar_url': avatarUrl,
    'days_with_sleepable': daysWithSleepable,
    'joined_date': joinedDate,
    'tracked_nights': trackedNights,
    'avg_sleep_hours': avgSleepHours,
    'avg_sleep_score': avgSleepScore,
    'streak_count': streakCount,
    'best_streak': bestStreak,
    'milestones': milestones?.map((x) => x.toJson()).toList(),
  };
}

class Milestone {
  final int? days;
  final bool? achieved;

  Milestone({this.days, this.achieved});

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      days: json['days'],
      achieved: json['achieved'],
    );
  }

  Map<String, dynamic> toJson() => {
    'days': days,
    'achieved': achieved,
  };
}