// class SocialLoginResponse {
//   final bool status;
//   final String message;
//   final SocialLoginResponseData data;
//
//   SocialLoginResponse({
//     required this.status,
//     required this.message,
//     required this.data,
//   });
//
//   factory SocialLoginResponse.fromJson(Map<String, dynamic> json) {
//     return SocialLoginResponse(
//       status: json['status'] is bool ? json['status'] : false,
//       message: json['message']?.toString() ?? '',
//       data: json['data'] is Map<String, dynamic>
//           ? SocialLoginResponseData.fromJson(json['data'])
//           : SocialLoginResponseData.empty(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'status': status,
//       'message': message,
//       'data': data.toJson(),
//     };
//   }
// }
//
// class SocialLoginResponseData {
//   final int id;
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String username;
//   final String? emailVerifiedAt;
//   final String userType;
//   final String? gender;
//   final String? playerId;
//   final String? contactNumber;
//   final String? uid;
//   final int status;
//   final String createdAt;
//   final String updatedAt;
//   final String apiToken;
//   final String profileImage;
//   final List<dynamic> media;
//
//   SocialLoginResponseData({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     required this.username,
//     this.emailVerifiedAt,
//     required this.userType,
//     this.gender,
//     this.playerId,
//     this.contactNumber,
//     this.uid,
//     required this.status,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.apiToken,
//     required this.profileImage,
//     required this.media,
//   });
//
//   factory SocialLoginResponseData.fromJson(Map<String, dynamic> json) {
//     return SocialLoginResponseData(
//       id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
//       firstName: json['first_name']?.toString() ?? '',
//       lastName: json['last_name']?.toString() ?? '',
//       email: json['email']?.toString() ?? '',
//       username: json['username']?.toString() ?? '',
//       emailVerifiedAt: json['email_verified_at']?.toString(),
//       userType: json['user_type']?.toString() ?? '',
//       gender: json['gender']?.toString(),
//       playerId: json['player_id']?.toString(),
//       contactNumber: json['contact_number']?.toString(),
//       uid: json['uid']?.toString(),
//       status: json['status'] is int
//           ? json['status']
//           : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
//       createdAt: json['created_at']?.toString() ?? '',
//       updatedAt: json['updated_at']?.toString() ?? '',
//       apiToken: json['api_token']?.toString() ?? '',
//       profileImage: json['profile_image']?.toString() ?? '',
//       media: json['media'] is List ? List<dynamic>.from(json['media']) : [],
//     );
//   }
//
//   /// Fallback when no `data` object is present
//   factory SocialLoginResponseData.empty() {
//     return SocialLoginResponseData(
//       id: 0,
//       firstName: '',
//       lastName: '',
//       email: '',
//       username: '',
//       emailVerifiedAt: null,
//       userType: '',
//       gender: null,
//       playerId: null,
//       contactNumber: null,
//       uid: null,
//       status: 0,
//       createdAt: '',
//       updatedAt: '',
//       apiToken: '',
//       profileImage: '',
//       media: [],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'first_name': firstName,
//       'last_name': lastName,
//       'email': email,
//       'username': username,
//       'email_verified_at': emailVerifiedAt,
//       'user_type': userType,
//       'gender': gender,
//       'player_id': playerId,
//       'contact_number': contactNumber,
//       'uid': uid,
//       'status': status,
//       'created_at': createdAt,
//       'updated_at': updatedAt,
//       'api_token': apiToken,
//       'profile_image': profileImage,
//       'media': media,
//     };
//   }
// }
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
