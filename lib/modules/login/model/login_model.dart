class UserDataResponseModel {
  final String? refresh;
  String? access;
  final UserModel? userModel;

  UserDataResponseModel({
    this.refresh,
    this.access,
    this.userModel,
  });

  factory UserDataResponseModel.fromJson(Map<String, dynamic> json) {
    return UserDataResponseModel(
      refresh: json['refresh'] as String?,
      access: json['access'] as String?,
      userModel: json['user_serializer'] != null
          ? UserModel.fromJson(json['user_serializer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
      'access': access,
      'user_serializer': userModel?.toJson(),
    };
  }
}

class UserModel {
  final int? id;
  final String? email;
  final String? firstName;
  final String? lastName;

  UserModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
