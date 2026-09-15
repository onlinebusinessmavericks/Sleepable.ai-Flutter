/// Backend access block from login, OTP, GET /users/subscription/, and
/// homepage `data.access`. Stored only — screens still read isPremium/isTrial.
class AccessFeatureFlag {
  final bool unlocked;
  final bool? canAnalyze;
  final int? used;
  final int? limit;
  final String? firstReportDate;
  final bool? premiumItemsUnlocked;

  const AccessFeatureFlag({
    required this.unlocked,
    this.canAnalyze,
    this.used,
    this.limit,
    this.firstReportDate,
    this.premiumItemsUnlocked,
  });

  factory AccessFeatureFlag.fromJson(dynamic raw) {
    if (raw is! Map) return const AccessFeatureFlag(unlocked: false);
    final json = Map<String, dynamic>.from(raw);
    return AccessFeatureFlag(
      unlocked: json['unlocked'] == true,
      canAnalyze: json['can_analyze'] is bool ? json['can_analyze'] as bool : null,
      used: _asIntOrNull(json['used']),
      limit: json['limit'] == null ? null : _asInt(json['limit']),
      firstReportDate: _asDateString(json['first_report_date']),
      premiumItemsUnlocked: json['premium_items_unlocked'] is bool
          ? json['premium_items_unlocked'] as bool
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked,
        if (canAnalyze != null) 'can_analyze': canAnalyze,
        if (used != null) 'used': used,
        if (limit != null) 'limit': limit,
        if (firstReportDate != null) 'first_report_date': firstReportDate,
        if (premiumItemsUnlocked != null) 'premium_items_unlocked': premiumItemsUnlocked,
      };
}

class AccessFeatures {
  final AccessFeatureFlag dreamBot;
  final AccessFeatureFlag reports;
  final AccessFeatureFlag sounds;
  final AccessFeatureFlag stories;
  final AccessFeatureFlag music;
  final AccessFeatureFlag sleepRecorder;
  final AccessFeatureFlag sleepQuiz;
  final AccessFeatureFlag export;
  final bool showPaywall;

  const AccessFeatures({
    required this.dreamBot,
    required this.reports,
    required this.sounds,
    required this.stories,
    required this.music,
    required this.sleepRecorder,
    required this.sleepQuiz,
    required this.export,
    required this.showPaywall,
  });

  factory AccessFeatures.fromJson(dynamic raw) {
    final json = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return AccessFeatures(
      dreamBot: AccessFeatureFlag.fromJson(json['dream_bot']),
      reports: AccessFeatureFlag.fromJson(json['reports']),
      sounds: AccessFeatureFlag.fromJson(json['sounds']),
      stories: AccessFeatureFlag.fromJson(json['stories']),
      music: AccessFeatureFlag.fromJson(json['music']),
      sleepRecorder: AccessFeatureFlag.fromJson(json['sleep_recorder']),
      sleepQuiz: AccessFeatureFlag.fromJson(json['sleep_quiz']),
      export: AccessFeatureFlag.fromJson(json['export']),
      showPaywall: json['show_paywall'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'dream_bot': dreamBot.toJson(),
        'reports': reports.toJson(),
        'sounds': sounds.toJson(),
        'stories': stories.toJson(),
        'music': music.toJson(),
        'sleep_recorder': sleepRecorder.toJson(),
        'sleep_quiz': sleepQuiz.toJson(),
        'export': export.toJson(),
        'show_paywall': showPaywall,
      };
}

class AccessBlock {
  final bool isPremium;
  final bool isTrial;
  final bool hasAccess;
  final String? trialEndsAt;
  final int trialNightsUsed;
  final int trialNightsLimit;
  final int trialDreamsUsed;
  final int trialDreamsLimit;
  final String firstReportDate;
  final AccessFeatures? features;
  final String? planName;
  final String? price;
  final String? startsAt;
  final String? expiresAt;
  final String? productId;

  const AccessBlock({
    required this.isPremium,
    required this.isTrial,
    required this.hasAccess,
    this.trialEndsAt,
    this.trialNightsUsed = 0,
    this.trialNightsLimit = 3,
    this.trialDreamsUsed = 0,
    this.trialDreamsLimit = 1,
    this.firstReportDate = '',
    this.features,
    this.planName,
    this.price,
    this.startsAt,
    this.expiresAt,
    this.productId,
  });

  factory AccessBlock.fromJson(Map<String, dynamic> json) {
    final paid = json['is_premium'] == true;
    final trial = json['is_trial'] == true;
    final hasAccess = json.containsKey('has_access')
        ? json['has_access'] == true
        : paid || trial;
    return AccessBlock(
      isPremium: paid,
      isTrial: trial,
      hasAccess: hasAccess,
      trialEndsAt: _asDateString(json['trial_ends_at']),
      trialNightsUsed: _asInt(json['trial_nights_used']),
      trialNightsLimit: _asInt(json['trial_nights_limit'], 3),
      trialDreamsUsed: _asInt(json['trial_dreams_used']),
      trialDreamsLimit: _asInt(json['trial_dreams_limit'], 1),
      firstReportDate: _asDateString(json['first_report_date']) ?? '',
      features: json['features'] is Map
          ? AccessFeatures.fromJson(json['features'])
          : null,
      planName: json['plan_name']?.toString(),
      price: json['price']?.toString(),
      startsAt: json['starts_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      productId: json['product_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_premium': isPremium,
        'is_trial': isTrial,
        'has_access': hasAccess,
        'trial_ends_at': trialEndsAt,
        'trial_nights_used': trialNightsUsed,
        'trial_nights_limit': trialNightsLimit,
        'trial_dreams_used': trialDreamsUsed,
        'trial_dreams_limit': trialDreamsLimit,
        'first_report_date': firstReportDate.isEmpty ? null : firstReportDate,
        if (features != null) 'features': features!.toJson(),
        if (planName != null) 'plan_name': planName,
        if (price != null) 'price': price,
        if (startsAt != null) 'starts_at': startsAt,
        if (expiresAt != null) 'expires_at': expiresAt,
        if (productId != null) 'product_id': productId,
      };

  /// Only keys the backend actually sent, so a login body without `is_trial`
  /// cannot wipe a cached trial before GET /users/subscription/ returns.
  static Map<String, dynamic> slice(Map<String, dynamic> json) {
    const keys = {
      'is_premium',
      'is_trial',
      'has_access',
      'trial_ends_at',
      'trial_nights_used',
      'trial_nights_limit',
      'trial_dreams_used',
      'trial_dreams_limit',
      'first_report_date',
      'features',
      'plan_name',
      'price',
      'starts_at',
      'expires_at',
      'product_id',
    };
    return {
      for (final key in keys)
        if (json.containsKey(key)) key: json[key],
    };
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

String? _asDateString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty || text == 'null') return null;
  return text;
}
