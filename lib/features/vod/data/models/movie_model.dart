import '../../domain/entities/movie_entity.dart';

/// Maps one entry of `get_vod_streams`.
///
/// Example payload (trimmed):
/// ```json
/// {
///   "stream_id": 8842,
///   "name": "Dune: Part Two",
///   "stream_icon": "http://provider.com/posters/dune2.jpg",
///   "category_id": "12",
///   "rating": "8.5",
///   "container_extension": "mkv",
///   "added": "1642345678"
/// }
/// ```
class MovieModel {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String categoryId;
  final double rating;
  final String containerExtension;
  final DateTime? addedAt;

  const MovieModel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.rating = 0,
    this.containerExtension = 'mp4',
    this.addedAt,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      streamId: int.tryParse('${json['stream_id']}') ?? 0,
      name: (json['name'] ?? 'Untitled').toString(),
      streamIcon: json['stream_icon']?.toString(),
      categoryId: json['category_id'].toString(),
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0,
      containerExtension: (json['container_extension'] ?? 'mp4').toString(),
      addedAt: parseXtreamTimestamp(json['added']),
    );
  }

  MovieEntity toEntity() => MovieEntity(
        streamId: streamId,
        name: name,
        posterUrl: streamIcon,
        categoryId: categoryId,
        rating: rating,
        containerExtension: containerExtension,
        addedAt: addedAt,
      );
}

/// Xtream sends unix-epoch **seconds**, usually as a string, sometimes
/// absent or empty. Shared by [MovieModel] and `SeriesModel`.
DateTime? parseXtreamTimestamp(dynamic raw) {
  if (raw == null) return null;
  final seconds = int.tryParse(raw.toString().trim());
  if (seconds == null || seconds <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
