
class HomePageResponse {
  final bool success;
  final String message;
  final HomePageData? data;

  HomePageResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory HomePageResponse.fromJson(Map<String, dynamic> json) {
    return HomePageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null ? HomePageData.fromJson(json['data']) : null,
    );
  }

  // 🔥 Added for caching
  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "data": data?.toJson(),
    };
  }
}

class HomePageData {
  final PremiumBanner premiumBanner;
  final SleepSummary sleepSummary;
  final TonightSleepGoal tonightSleepGoal;
  final List<WeeklySleepPattern> weeklySleepPattern;
  final List<HomeSoundItem> recentSounds;
  final List<HomeSoundItem> featuredSounds;
  final List<SoundCategory> soundCategories;
  final SoundSection healingSounds;
  final SoundSection sleepStory;
  final SoundSection sleepMeditation;
  final SoundSection soundScape;
  final SoundSection soundScenes;
  final SleepQuiz sleepQuiz;
  final List<String> sleepInsights;
  final DailyQuote dailyQuote;
  final SleepStatus? sleepStatus;

  HomePageData({
    required this.premiumBanner,
    required this.sleepSummary,
    required this.tonightSleepGoal,
    required this.weeklySleepPattern,
    required this.recentSounds,
    required this.featuredSounds,
    required this.soundCategories,
    required this.healingSounds,
    required this.sleepStory,
    required this.sleepMeditation,
    required this.soundScape,
    required this.soundScenes,
    required this.sleepQuiz,
    required this.sleepInsights,
    required this.dailyQuote,
    this.sleepStatus,
  });

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    return HomePageData(
      premiumBanner: PremiumBanner.fromJson(json['premium_banner'] ?? {}),
      sleepSummary: SleepSummary.fromJson(json['sleep_summary'] ?? {}),
      tonightSleepGoal: TonightSleepGoal.fromJson(json['tonight_sleep_goal'] ?? {}),
      weeklySleepPattern: (json['weekly_sleep_pattern'] as List? ?? [])
          .map((e) => WeeklySleepPattern.fromJson(e))
          .toList(),
      recentSounds: (json['recent_sounds'] as List? ?? [])
          .map((e) => HomeSoundItem.fromJson(e))
          .toList(),
      featuredSounds: (json['featured_sounds'] as List? ?? [])
          .map((e) => HomeSoundItem.fromJson(e))
          .toList(),
      soundCategories: (json['sound_categories'] as List? ?? [])
          .map((e) => SoundCategory.fromJson(e))
          .toList(),
      healingSounds: SoundSection.fromJson(json['healing_sounds'] ?? {}),
      sleepStory: SoundSection.fromJson(json['sleep_story'] ?? {}),
      sleepMeditation: SoundSection.fromJson(json['sleep_meditation'] ?? {}),
      soundScape: SoundSection.fromJson(json['sound_scape'] ?? {}),
      soundScenes: SoundSection.fromJson(json['sound_scenes'] ?? {}),
      sleepQuiz: SleepQuiz.fromJson(json['sleep_quiz'] ?? {}),
      sleepInsights: List<String>.from(json['sleep_insights'] ?? []),
      dailyQuote: DailyQuote.fromJson(json['daily_quote'] ?? {}),
      sleepStatus: json['sleep_status'] != null
          ? SleepStatus.fromJson(json['sleep_status'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "premium_banner": premiumBanner.toJson(),
      "sleep_summary": sleepSummary.toJson(),
      "tonight_sleep_goal": tonightSleepGoal.toJson(),
      "weekly_sleep_pattern": weeklySleepPattern.map((e) => e.toJson()).toList(),
      "recent_sounds": recentSounds.map((e) => e.toJson()).toList(),
      "featured_sounds": featuredSounds.map((e) => e.toJson()).toList(),
      "sound_categories": soundCategories.map((e) => e.toJson()).toList(),
      "healing_sounds": healingSounds.toJson(),
      "sleep_story": sleepStory.toJson(),
      "sleep_meditation": sleepMeditation.toJson(),
      "sound_scape": soundScape.toJson(),
      "sound_scenes": soundScenes.toJson(),
      "sleep_quiz": sleepQuiz.toJson(),
      "sleep_insights": sleepInsights,
      "daily_quote": dailyQuote.toJson(),
      "sleep_status": sleepStatus?.toJson(),
    };
  }
}

class PremiumBanner {
  final bool isPremium;
  PremiumBanner({required this.isPremium});
  factory PremiumBanner.fromJson(Map<String, dynamic> json) =>
      PremiumBanner(isPremium: json['is_premium'] ?? false);

  Map<String, dynamic> toJson() => {"is_premium": isPremium};
}

class SleepQuiz {
  final String title;
  final List<dynamic> items;
  SleepQuiz({required this.title, required this.items});
  factory SleepQuiz.fromJson(Map<String, dynamic> json) =>
      SleepQuiz(title: json['title'] ?? "", items: json['items'] ?? []);

  Map<String, dynamic> toJson() => {"title": title, "items": items};
}
class SleepStatus {
  final String title;
  final String subtitle;
  final double sleepHours;
  final double sleepQuality;

  SleepStatus({
    required this.title,
    required this.subtitle,
    required this.sleepHours,
    required this.sleepQuality,
  });

  factory SleepStatus.fromJson(Map<String, dynamic> json) => SleepStatus(
    title: json["title"] ?? "",
    subtitle: json["subtitle"] ?? "",
    sleepHours: (json["sleep_hours"] ?? 0).toDouble(),
    sleepQuality: (json["sleep_quality"] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "subtitle": subtitle,
    "sleep_hours": sleepHours,
    "sleep_quality": sleepQuality,
  };
}
class DailyQuote {
  final String title;
  final String? quote;
  final String? author;
  DailyQuote({required this.title, this.quote, this.author});
  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
    title: json['title'] ?? "",
    quote: json['quote'],
    author: json['author'],
  );

  Map<String, dynamic> toJson() => {"title": title, "quote": quote, "author": author};
}

class SoundSection {
  final String title;
  final String description;
  final List<HomeSoundItem> items;

  SoundSection({required this.title, required this.description, required this.items});

  factory SoundSection.fromJson(Map<String, dynamic> json) => SoundSection(
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    items: (json["items"] as List? ?? [])
        .map((x) => HomeSoundItem.fromJson(x))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "items": items.map((e) => e.toJson()).toList(),
  };
}

class HomeSoundItem {
  final int id;
  final String name;
  final String? thumbnail;
  final String? image;
  final String? file;
  final String? artist;
  final String? subcategory;
  final int duration;
  final bool isNew;
  final bool isPremium;
  final bool isLocked;
  final String? type;

  HomeSoundItem({
    required this.id,
    required this.name,
    this.thumbnail,
    this.image,
    this.file,
    this.artist,
    this.subcategory,
    required this.duration,
    required this.isNew,
    required this.isPremium,
    required this.isLocked,
    this.type,
  });

  factory HomeSoundItem.fromJson(Map<String, dynamic> json) {
    return HomeSoundItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      thumbnail: json['thumbnail'],
      image: json['image'],
      file: json['file'],
      artist: json['artist'],
      subcategory: json['subcategory'],
      duration: json['duration'] ?? 0,
      isNew: json['is_new'] ?? false,
      isPremium: json['is_premium'] ?? false,
      isLocked: json['is_locked'] ?? false,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "thumbnail": thumbnail,
    "image": image,
    "file": file,
    "artist": artist,
    "subcategory": subcategory,
    "duration": duration,
    "is_new": isNew,
    "is_premium": isPremium,
    "is_locked": isLocked,
    "type": type,
  };
}

class SleepSummary {
  final double goalHours;
  final int progressPercentage;
  final double totalSleepHours;
  final double? qualityRating;
  final String? sleepQuality;
  final String? message;

  SleepSummary({
    required this.goalHours,
    required this.progressPercentage,
    required this.totalSleepHours,
    this.qualityRating,
    this.sleepQuality,
    this.message,
  });

  factory SleepSummary.fromJson(Map<String, dynamic> json) => SleepSummary(
    goalHours: (json["goal_hours"] ?? 0).toDouble(),
    progressPercentage: json["progress_percentage"] ?? 0,
    totalSleepHours: (json["total_sleep_hours"] ?? 0).toDouble(),
    qualityRating: json["quality_rating"] != null ? (json["quality_rating"] as num).toDouble() : null,
    sleepQuality: json["sleep_quality"]?.toString(),
    message: json["message"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "goal_hours": goalHours,
    "progress_percentage": progressPercentage,
    "total_sleep_hours": totalSleepHours,
    "quality_rating": qualityRating,
    "sleep_quality": sleepQuality,
    "message": message,
  };
}

class TonightSleepGoal {
  final String targetBedtime;
  final double goalHours;
  final double hoursUntilBedtime;
  final double lastNightHours;
  final bool reminderEnable;

  TonightSleepGoal({
    required this.targetBedtime,
    required this.goalHours,
    required this.hoursUntilBedtime,
    required this.lastNightHours,
    required this.reminderEnable,
  });

  factory TonightSleepGoal.fromJson(Map<String, dynamic> json) => TonightSleepGoal(
    targetBedtime: json["target_bedtime"] ?? "",
    goalHours: (json["goal_hours"] ?? 0).toDouble(),
    hoursUntilBedtime: (json["hours_until_bedtime"] ?? 0).toDouble(),
    lastNightHours: (json["last_night_hours"] ?? 0).toDouble(),
    reminderEnable: json["reminder_enabled"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "target_bedtime": targetBedtime,
    "goal_hours": goalHours,
    "hours_until_bedtime": hoursUntilBedtime,
    "last_night_hours": lastNightHours,
    "reminder_enabled": reminderEnable,
  };
}

class WeeklySleepPattern {
  final String day;
  final double averageHours;

  WeeklySleepPattern({required this.day, required this.averageHours});

  factory WeeklySleepPattern.fromJson(Map<String, dynamic> json) {
    return WeeklySleepPattern(
      day: json['day'] ?? "",
      averageHours: (json['average_hours'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {"day": day, "average_hours": averageHours};
}

class SoundCategory {
  final int id;
  final String name;
  final String? description;

  SoundCategory({required this.id, required this.name, this.description});

  factory SoundCategory.fromJson(Map<String, dynamic> json) {
    return SoundCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name, "description": description};
}