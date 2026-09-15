class SoundsMixedListResponse {
  final bool success;
  final String message;
  final MixedPaginationData? data;

  SoundsMixedListResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SoundsMixedListResponse.fromJson(Map<String, dynamic> json) {
    return SoundsMixedListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MixedPaginationData.fromJson(json['data'])
          : null,
    );
  }
}
class MixedPaginationData {
  final int totalItems;
  final int pageSize;
  final int currentPage;
  final int totalPages;
  final List<MixedSoundRecord> records;

  MixedPaginationData({
    required this.totalItems,
    required this.pageSize,
    required this.currentPage,
    required this.totalPages,
    required this.records,
  });

  factory MixedPaginationData.fromJson(Map<String, dynamic> json) {
    return MixedPaginationData(
      totalItems: json['total_items'] ?? 0,
      pageSize: json['page_size'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      records: json['records'] != null
          ? List<MixedSoundRecord>.from(
        json['records'].map((e) => MixedSoundRecord.fromJson(e)),
      )
          : [],
    );
  }
}
class MixedSoundRecord {
  final int id;
  final String title;
  final String description;
  final List<MixedSoundItem> sounds;
  final bool isPublic; // Added this
  final DateTime? createdAt;

  MixedSoundRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.sounds,
    required this.isPublic,
    this.createdAt,
  });

  factory MixedSoundRecord.fromJson(Map<String, dynamic> json) {
    return MixedSoundRecord(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      // Description is a String in your JSON, not a Map!
      description: json['description'] ?? '',
      isPublic: json['is_public'] ?? false,
      sounds: json['sounds'] != null && json['sounds'] is List
          ? List<MixedSoundItem>.from(
        (json['sounds'] as List).map((e) {
          // Safety check: ensure 'e' is actually a Map before parsing
          if (e is Map<String, dynamic>) {
            return MixedSoundItem.fromJson(e);
          }
          // Fallback for unexpected data types
          return MixedSoundItem(id: 0, name: 'Unknown', image: '', file: '');
        }),
      )
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class MixedSoundItem {
  final int id;
  final String name;
  final String? emoji; // Added this (String? because it can be null)
  final String? thumbnail;
  final String image;
  final String file;

  MixedSoundItem({
    required this.id,
    required this.name,
    this.emoji,
    this.thumbnail,
    required this.image,
    required this.file,
  });

  factory MixedSoundItem.fromJson(Map<String, dynamic> json) {
    return MixedSoundItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      emoji: json['emoji'], // Map the emoji field
      thumbnail: json['thumbnail'],
      image: json['image'] ?? '',
      file: json['file'] ?? '',
    );
  }
}
