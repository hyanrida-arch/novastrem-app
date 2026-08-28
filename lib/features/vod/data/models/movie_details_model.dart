import '../../domain/entities/movie_details_entity.dart';

/// Maps the `get_vod_info` response, which is shaped as two nested objects:
/// `info` (metadata) and `movie_data` (stream identifiers).
///
/// Example payload (trimmed):
/// ```json
/// {
///   "info": {
///     "movie_image": "http://provider.com/posters/dune2.jpg",
///     "backdrop_path": ["http://provider.com/backdrops/dune2.jpg"],
///     "plot": "Paul Atreides unites with Chani...",
///     "cast": "Timothée Chalamet, Zendaya",
///     "director": "Denis Villeneuve",
///     "genre": "Sci-Fi, Adventure",
///     "releasedate": "2024-03-01",
///     "rating": "8.5",
///     "duration": "2h 46m"
///   },
///   "movie_data": { "stream_id": 8842, "name": "Dune: Part Two", "container_extension": "mkv" }
/// }
/// ```
class MovieDetailsModel {
  final int streamId;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;
  final String description;
  final String genre;
  final String director;
  final String cast;
  final String releaseDate;
  final double rating;
  final String duration;
  final String containerExtension;

  const MovieDetailsModel({
    required this.streamId,
    required this.name,
    this.posterUrl,
    this.backdropUrl,
    this.description = '',
    this.genre = '',
    this.director = '',
    this.cast = '',
    this.releaseDate = '',
    this.rating = 0,
    this.duration = '',
    this.containerExtension = 'mp4',
  });

  factory MovieDetailsModel.fromJson(Map<String, dynamic> json) {
    final info = (json['info'] as Map<String, dynamic>?) ?? {};
    final movieData = (json['movie_data'] as Map<String, dynamic>?) ?? {};

    String? backdrop;
    final backdropPath = info['backdrop_path'];
    if (backdropPath is List && backdropPath.isNotEmpty) {
      backdrop = backdropPath.first?.toString();
    } else if (backdropPath is String && backdropPath.isNotEmpty) {
      backdrop = backdropPath;
    }

    return MovieDetailsModel(
      streamId: int.tryParse('${movieData['stream_id'] ?? 0}') ?? 0,
      name: (movieData['name'] ?? info['name'] ?? 'Untitled').toString(),
      posterUrl: info['movie_image']?.toString(),
      backdropUrl: backdrop,
      description: (info['plot'] ?? info['description'] ?? '').toString(),
      genre: (info['genre'] ?? '').toString(),
      director: (info['director'] ?? '').toString(),
      cast: (info['cast'] ?? info['actors'] ?? '').toString(),
      releaseDate: (info['releasedate'] ?? info['release_date'] ?? '').toString(),
      rating: double.tryParse('${info['rating'] ?? 0}') ?? 0,
      duration: (info['duration'] ?? '').toString(),
      containerExtension: (movieData['container_extension'] ?? 'mp4').toString(),
    );
  }

  MovieDetailsEntity toEntity() => MovieDetailsEntity(
        streamId: streamId,
        name: name,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        description: description,
        genre: genre,
        director: director,
        cast: cast,
        releaseDate: releaseDate,
        rating: rating,
        duration: duration,
        containerExtension: containerExtension,
      );
}
