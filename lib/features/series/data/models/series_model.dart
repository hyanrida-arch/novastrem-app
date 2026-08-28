import '../../../vod/data/models/movie_model.dart' show parseXtreamTimestamp;
import '../../domain/entities/series_entity.dart';

/// Maps one entry of `get_series`.
///
/// Example payload (trimmed):
/// ```json
/// {
///   "series_id": 431,
///   "name": "Severance",
///   "cover": "http://provider.com/covers/severance.jpg",
///   "category_id": "20",
///   "rating": "8.7",
///   "last_modified": "1642345678"
/// }
/// ```
class SeriesModel {
  final int seriesId;
  final String name;
  final String? cover;
  final String categoryId;
  final double rating;
  final DateTime? lastModified;

  const SeriesModel({
    required this.seriesId,
    required this.name,
    required this.categoryId,
    this.cover,
    this.rating = 0,
    this.lastModified,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      seriesId: int.tryParse('${json['series_id']}') ?? 0,
      name: (json['name'] ?? 'Untitled').toString(),
      cover: json['cover']?.toString(),
      categoryId: json['category_id'].toString(),
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0,
      lastModified: parseXtreamTimestamp(json['last_modified']),
    );
  }

  SeriesEntity toEntity() => SeriesEntity(
        seriesId: seriesId,
        name: name,
        coverUrl: cover,
        categoryId: categoryId,
        rating: rating,
        lastModified: lastModified,
      );
}
