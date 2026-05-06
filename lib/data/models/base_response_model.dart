class BaseResponseModel {
  int statusCode;
  String message;

  dynamic data;

  BaseResponseModel({
    this.message = "",
    this.statusCode = -1,
    this.data,
  });

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      statusCode: json['status'] is int ? json['status'] : -1,
      message: json['message'] is String ? json['message'] : "",
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'status': statusCode,
      'message': message,
    };
  }
}