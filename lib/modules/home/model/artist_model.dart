class Artist {
  final int id;
  final String name;
  final String bio;
  final String slug;
  final String image;
  final int soundCount;

  Artist({
    required this.id,
    required this.name,
    required this.bio,
    required this.slug,
    required this.image,
    required this.soundCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'] ?? '',
      soundCount: json['sound_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'slug': slug,
      'image': image,
      'sound_count': soundCount,
    };
  }
}
class ArtistResponse {
  final bool success;
  final String message;
  final List<Artist> data;

  ArtistResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ArtistResponse.fromJson(Map<String, dynamic> json) {
    return ArtistResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => Artist.fromJson(e))
          .toList(),
    );
  }
}
