class SoundSubCategoryResponse {
  final bool success;
  final String message;
  final List<SoundSubCategory> data;

  SoundSubCategoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SoundSubCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SoundSubCategoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => SoundSubCategory.fromJson(e))
          .toList(),
    );
  }
}

class SoundSubCategory {
  final int id;
  final String name;
  final int category;
  final String slug;

  SoundSubCategory({
    required this.id,
    required this.name,
    required this.category,
    required this.slug,
  });

  factory SoundSubCategory.fromJson(Map<String, dynamic> json) {
    return SoundSubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? 0,
      slug: json['slug'] ?? '',
    );
  }
}
