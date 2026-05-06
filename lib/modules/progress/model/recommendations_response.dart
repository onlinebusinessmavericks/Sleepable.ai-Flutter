class RecommendationsResponse {
  final bool success;
  final RecommendationData? data;

  RecommendationsResponse({required this.success, this.data});

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? RecommendationData.fromJson(json['data']) : null,
    );
  }
}

class RecommendationData {
  final List<RecommendationItem> recommendations;

  RecommendationData({required this.recommendations});

  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    return RecommendationData(
      recommendations: (json['recommendations'] as List? ?? [])
          .map((item) => RecommendationItem.fromJson(item))
          .toList(),
    );
  }
}

class RecommendationItem {
  final String title;
  final String description;

  RecommendationItem({required this.title, required this.description});

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}