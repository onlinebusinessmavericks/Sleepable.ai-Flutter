import 'dart:convert';

class EmailLoginResponse {
  final bool? success;
  final String? message;
  final UserLoginData? data;

  EmailLoginResponse({this.success, this.message, this.data});

  factory EmailLoginResponse.fromJson(Map<String, dynamic> json) {
    return EmailLoginResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? UserLoginData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class UserLoginData {
  final int? userId;
  final String? uuid;
  final String? name;
  final String? email;
  final String? countryCode;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? provider;
  final String? providerId;
  final String? referralCode;
  final String? usedReferralCode;
  final String? lastLoginAt;
  final bool? isOnboarded;
  final String? avatarUrl;
  final TokenData? tokens;
  final String? type;
  // Dynamic fields handle karne ke liye agar runtime par backend extra boolean bhejta hai
  final bool isPremium;

  UserLoginData({
    this.userId,
    this.uuid,
    this.name,
    this.email,
    this.countryCode,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.provider,
    this.providerId,
    this.referralCode,
    this.usedReferralCode,
    this.lastLoginAt,
    this.isOnboarded,
    this.avatarUrl,
    this.tokens,
    this.type,
    this.isPremium = false,
  });

  factory UserLoginData.fromJson(Map<String, dynamic> json) {
    return UserLoginData(
      userId: json['user_id'],
      uuid: json['uuid'],
      name: json['name'],
      email: json['email'],
      countryCode: json['country_code'],
      phone: json['phone'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      provider: json['provider'],
      providerId: json['provider_id'],
      referralCode: json['referral_code'],
      usedReferralCode: json['used_referral_code'],
      lastLoginAt: json['last_login_at'],
      isOnboarded: json['is_onboarded'],
      avatarUrl: json['avatar_url'],
      type: json['type'],
      isPremium: json['is_premium'] ?? false, // Check safely
      tokens: json['tokens'] != null ? TokenData.fromJson(json['tokens']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'avatar_url': urlClean(avatarUrl),
      'is_premium': isPremium,
      'tokens': tokens?.toJson(),
      'type': type,
    };
  }

  static String? urlClean(String? url) => (url != null && url.isNotEmpty) ? url : null;
}

class TokenData {
  final String? refresh;
  final String? access;

  TokenData({this.refresh, this.access});

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      refresh: json['refresh'],
      access: json['access'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
      'access': access,
    };
  }
}