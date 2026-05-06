
import '../../home/model/artist_model.dart';

class SoundItem {
  final int id;
  final String name;
  final String? emoji;
  final String? thumbnail;
  final String image;
  final String file;
  final String subcategory;
  final String categoryName;
  final String subcategoryName;
  final String slug;
  final bool isPremium;
  final bool isNew;
  bool? isFavorite;
  final Artist? artist;
  final int? duration;

  SoundItem({
    required this.id,
    required this.name,
    this.emoji,
    this.thumbnail,
    required this.image,
    required this.file,
    required this.subcategory,
    required this.categoryName,
    required this.subcategoryName,
    required this.slug,
    required this.isPremium,
    required this.isNew,
    required this.isFavorite,
    this.artist,
    this.duration,
  });

  factory SoundItem.fromJson(Map<String, dynamic> json) {
    return SoundItem(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0),
      // name: json['name'] ?? '',
      name: json['name']?.toString() ?? '',
      thumbnail: json['thumbnail'],
      emoji: json['emoji'],
      image: json['image'] ?? '',
      file: json['file'] ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      categoryName: json['category_name'] ?? '',
      subcategoryName: json['subcategory_name'] ?? '',
      slug: json['slug'] ?? '',
      isPremium: json['is_premium'] ?? false,
      isNew: json['is_new'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      artist: json['artist'] != null ? Artist.fromJson(json['artist']) : null,
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? ''),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'thumbnail': thumbnail,
      'image': image,
      'file': file,
      'subcategory': subcategory,
      'category_name': categoryName,
      'subcategory_name': subcategoryName,
      'slug': slug,
      'is_premium': isPremium,
      'is_new': isNew,
      'is_favorite': isFavorite,
      'artist': artist?.toJson(),
      'duration': duration,
    };
  }
}
