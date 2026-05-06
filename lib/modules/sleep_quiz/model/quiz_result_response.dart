class QuizResultResponse {
  final bool success;
  final String message;
  final QuizResultData? data;

  QuizResultResponse({required this.success, required this.message, this.data});

  factory QuizResultResponse.fromJson(Map<String, dynamic> json) {
    return QuizResultResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null ? QuizResultData.fromJson(json['data']) : null,
    );
  }
}

class QuizResultData {
  final String disorder;
  final String resultDetails;
  final List<String> suggestions;

  QuizResultData({
    required this.disorder,
    required this.resultDetails,
    required this.suggestions,
  });

  factory QuizResultData.fromJson(Map<String, dynamic> json) {
    return QuizResultData(
      disorder: json['disorder'] ?? "Unknown",
      resultDetails: json['result_details'] ?? "",
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'disorder': disorder,
      'result_details': resultDetails,
      'suggestions': suggestions,
    };
  }
}