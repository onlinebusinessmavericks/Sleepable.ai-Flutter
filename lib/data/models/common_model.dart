class CommonResponse {
  final bool success;
  final String message;
  final dynamic data;

  CommonResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CommonResponse.fromJson(Map<String, dynamic> json) {
    return CommonResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}
