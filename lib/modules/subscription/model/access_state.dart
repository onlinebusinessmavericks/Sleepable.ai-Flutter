/// What the signed-in user may do, exactly as the backend reports it.
///
/// The same block comes back from login, email-login, email-verify-otp,
/// GET /users/subscription/ and GET /homepage/home-page/ (as `data.access`).
/// Every lock and every paywall decision in the app reads from here - never
/// from store receipts, cached flags or translated strings.
class AccessState {
  /// Paid Premium only. The one legitimate UI use is a "Premium member" label.
  final bool isPremium;
  final bool isTrial;

  /// Paid or trial.
  final bool hasAccess;
  final DateTime? trialEndsAt;
  final int trialDreamsUsed;
  final int trialDreamsLimit;
  final int trialNightsUsed;
  final int trialNightsLimit;
  final String? firstReportDate;
  final int? firstReportTrackerId;
  final AccessFeatures features;

  /// False until a real access block has been parsed. Nothing should upsell
  /// or unlock on the strength of a state the backend never sent.
  final bool isKnown;

  /// The block as received, kept so it can be cached and restored verbatim.
  final Map<String, dynamic> raw;

  const AccessState({
    required this.isPremium,
    required this.isTrial,
    required this.hasAccess,
    required this.trialEndsAt,
    required this.trialDreamsUsed,
    required this.trialDreamsLimit,
    required this.trialNightsUsed,
    required this.trialNightsLimit,
    required this.firstReportDate,
    required this.firstReportTrackerId,
    required this.features,
    required this.isKnown,
    required this.raw,
  });

  /// Nothing known yet: everything locked, no paywall.
  factory AccessState.unknown() => const AccessState(
        isPremium: false,
        isTrial: false,
        hasAccess: false,
        trialEndsAt: null,
        trialDreamsUsed: 0,
        trialDreamsLimit: 0,
        trialNightsUsed: 0,
        trialNightsLimit: 0,
        firstReportDate: null,
        firstReportTrackerId: null,
        features: AccessFeatures.none,
        isKnown: false,
        raw: {},
      );

  bool get showPaywall => features.showPaywall;

  /// True when [json] carries an access block at all. Responses that do not
  /// (an older backend, an unrelated payload) must not wipe the current state.
  static bool looksLikeAccessBlock(dynamic json) =>
      json is Map &&
      (json.containsKey('has_access') || json.containsKey('features') || json.containsKey('is_premium'));

  /// Parses [json], or returns null when it is not an access block.
  static AccessState? tryParse(dynamic json) {
    if (!looksLikeAccessBlock(json)) return null;
    final map = Map<String, dynamic>.from(json as Map);
    final isPremium = map['is_premium'] == true;
    final isTrial = map['is_trial'] == true;
    final features = AccessFeatures.fromJson(map['features'], topLevel: map);
    return AccessState(
      isPremium: isPremium,
      isTrial: isTrial,
      // has_access is part of the contract; the fallback only covers a
      // response from before the field existed.
      hasAccess: map.containsKey('has_access') ? map['has_access'] == true : (isPremium || isTrial),
      trialEndsAt: _date(map['trial_ends_at']),
      trialDreamsUsed: _int(map['trial_dreams_used']) ?? 0,
      trialDreamsLimit: _int(map['trial_dreams_limit']) ?? 0,
      trialNightsUsed: _int(map['trial_nights_used']) ?? 0,
      trialNightsLimit: _int(map['trial_nights_limit']) ?? 0,
      firstReportDate: _string(map['first_report_date']) ?? features.reports.firstReportDate,
      firstReportTrackerId: _int(map['first_report_tracker_id']) ?? features.reports.firstReportTrackerId,
      features: features,
      isKnown: true,
      raw: _accessOnly(map),
    );
  }

  /// Only the access fields, so a login body's tokens and profile are never
  /// written into the access cache.
  static Map<String, dynamic> _accessOnly(Map<String, dynamic> map) {
    const keys = [
      'is_premium',
      'is_trial',
      'has_access',
      'trial_ends_at',
      'trial_dreams_used',
      'trial_dreams_limit',
      'trial_nights_used',
      'trial_nights_limit',
      'first_report_date',
      'first_report_tracker_id',
      'features',
      'show_paywall',
    ];
    return {for (final k in keys) if (map.containsKey(k)) k: map[k]};
  }
}

/// `features` from the access block.
class AccessFeatures {
  final AccessFeature dreamBot;
  final AccessFeature reports;
  final AccessFeature sounds;
  final AccessFeature stories;
  final AccessFeature music;
  final AccessFeature sleepRecorder;
  final AccessFeature sleepQuiz;
  final AccessFeature export;
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

  static const none = AccessFeatures(
    dreamBot: AccessFeature.locked,
    reports: AccessFeature.locked,
    sounds: AccessFeature.locked,
    stories: AccessFeature.locked,
    music: AccessFeature.locked,
    sleepRecorder: AccessFeature.locked,
    sleepQuiz: AccessFeature.locked,
    export: AccessFeature.locked,
    showPaywall: false,
  );

  /// [topLevel] is the enclosing block: `show_paywall` is documented inside
  /// `features`, but is read from the top level too if it only appears there.
  factory AccessFeatures.fromJson(dynamic json, {Map<String, dynamic>? topLevel}) {
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final paywall = map.containsKey('show_paywall') ? map['show_paywall'] : topLevel?['show_paywall'];
    return AccessFeatures(
      dreamBot: AccessFeature.fromJson(map['dream_bot']),
      reports: AccessFeature.fromJson(map['reports']),
      sounds: AccessFeature.fromJson(map['sounds']),
      stories: AccessFeature.fromJson(map['stories']),
      music: AccessFeature.fromJson(map['music']),
      sleepRecorder: AccessFeature.fromJson(map['sleep_recorder']),
      sleepQuiz: AccessFeature.fromJson(map['sleep_quiz']),
      export: AccessFeature.fromJson(map['export']),
      showPaywall: paywall == true,
    );
  }
}

/// One entry of `features`. Only `unlocked` is common to all of them; the
/// rest are present on the features that use them.
class AccessFeature {
  final bool unlocked;
  final bool canAnalyze;
  final int? used;
  final int? limit;
  final bool premiumItemsUnlocked;
  final String? firstReportDate;
  final int? firstReportTrackerId;

  const AccessFeature({
    required this.unlocked,
    this.canAnalyze = false,
    this.used,
    this.limit,
    this.premiumItemsUnlocked = false,
    this.firstReportDate,
    this.firstReportTrackerId,
  });

  static const locked = AccessFeature(unlocked: false);

  factory AccessFeature.fromJson(dynamic json) {
    if (json is! Map) return locked;
    final map = Map<String, dynamic>.from(json);
    return AccessFeature(
      unlocked: map['unlocked'] == true,
      canAnalyze: map['can_analyze'] == true,
      used: _int(map['used']),
      limit: _int(map['limit']),
      premiumItemsUnlocked: map['premium_items_unlocked'] == true,
      firstReportDate: _string(map['first_report_date']),
      firstReportTrackerId: _int(map['first_report_tracker_id']),
    );
  }
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _string(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return (s.isEmpty || s == 'null') ? null : s;
}

DateTime? _date(dynamic v) {
  final s = _string(v);
  return s == null ? null : DateTime.tryParse(s)?.toUtc();
}
