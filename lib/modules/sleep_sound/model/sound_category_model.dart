class SoundCategory {
  final int id;
  final String name;
  final String description;
  final String slug;

  SoundCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
  });

  factory SoundCategory.fromJson(Map<String, dynamic> json) {
    return SoundCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
    };
  }
}
class SoundCategoryResponse {
  final bool success;
  final String message;
  final List<SoundCategory> data;

  SoundCategoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SoundCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SoundCategoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => SoundCategory.fromJson(e))
          .toList(),
    );
  }
}
