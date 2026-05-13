
class SocialLoginResponse {
  final bool success;
  final String message;
  final SocialLoginResponseData data;

  SocialLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SocialLoginResponse.fromJson(Map<String, dynamic> json) {
    return SocialLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SocialLoginResponseData.fromJson(json['data'])
          : SocialLoginResponseData.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data.toJson(),
  };
}

class SocialLoginResponseData {
  final int userId;
  final String uuid;
  final String name;
  final String email;
  final String? countryCode;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String provider;
  final String providerId;
  final String referralCode;
  final String usedReferralCode;
  final String lastLoginAt;
  final bool isOnboarded;
  final String avatarUrl;
  final Tokens tokens;
  final String type;
  final bool isPremium;

  SocialLoginResponseData({
    required this.userId,
    required this.uuid,
    required this.name,
    required this.email,
    this.countryCode,
    this.phone,
    this.gender,
    this.dateOfBirth,
    required this.provider,
    required this.providerId,
    required this.referralCode,
    required this.usedReferralCode,
    required this.lastLoginAt,
    required this.isOnboarded,
    required this.avatarUrl,
    required this.tokens,
    required this.type,
    required this.isPremium,
  });

  factory SocialLoginResponseData.fromJson(Map<String, dynamic> json) {
    return SocialLoginResponseData(
      userId: json['user_id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      countryCode: json['country_code'],
      phone: json['phone'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      provider: json['provider'] ?? '',
      providerId: json['provider_id'] ?? '',
      referralCode: json['referral_code'] ?? '',
      usedReferralCode: json['used_referral_code'] ?? '',
      lastLoginAt: json['last_login_at'] ?? '',
      isOnboarded: json['is_onboarded'] ?? false,
      avatarUrl: json['avatar_url'] ?? '',
      tokens: json['tokens'] != null ? Tokens.fromJson(json['tokens']) : Tokens.empty(),
      type: json['type'] ?? '',
      isPremium: json['is_premium'] ?? json['isPremium'] ?? false,
    );
  }

  factory SocialLoginResponseData.empty() {
    return SocialLoginResponseData(
      userId: 0,
      uuid: '',
      name: '',
      email: '',
      countryCode: null,
      phone: null,
      gender: null,
      dateOfBirth: null,
      provider: '',
      providerId: '',
      referralCode: '',
      usedReferralCode: '',
      lastLoginAt: '',
      isOnboarded: false,
      avatarUrl: '',
      tokens: Tokens.empty(),
      type: '',
      isPremium: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'uuid': uuid,
    'name': name,
    'email': email,
    'country_code': countryCode,
    'phone': phone,
    'gender': gender,
    'date_of_birth': dateOfBirth,
    'provider': provider,
    'provider_id': providerId,
    'referral_code': referralCode,
    'used_referral_code': usedReferralCode,
    'last_login_at': lastLoginAt,
    'is_onboarded': isOnboarded,
    'avatar_url': avatarUrl,
    'tokens': tokens.toJson(),
    'type': type,
    'is_premium': isPremium,
  };
}

class Tokens {
  final String access;
  final String refresh;

  Tokens({required this.access, required this.refresh});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }

  factory Tokens.empty() => Tokens(access: '', refresh: '');

  Map<String, dynamic> toJson() => {
    'access': access,
    'refresh': refresh,
  };
}
