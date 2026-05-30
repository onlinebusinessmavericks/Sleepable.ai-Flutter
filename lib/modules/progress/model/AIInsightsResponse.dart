class AIInsightsResponse {
  final bool success;
  final String message;
  final AIInsightsContent? data;

  AIInsightsResponse({required this.success, required this.message, this.data});

  factory AIInsightsResponse.fromJson(Map<String, dynamic> json) {
    return AIInsightsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AIInsightsContent.fromJson(json['data']) : null,
    );
  }
}

class AIInsightsContent {
  final double precisionScore;
  final List<InsightItem> insights;

  AIInsightsContent({required this.precisionScore, required this.insights});

  factory AIInsightsContent.fromJson(Map<String, dynamic> json) {
    return AIInsightsContent(
      precisionScore: (json['precisionScore'] ?? 0).toDouble(),
      insights: (json['insights'] as List?)
          ?.map((item) => InsightItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class InsightItem {
  final String title;
  final String summary;

  InsightItem({required this.title, required this.summary});

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
    );
  }
}