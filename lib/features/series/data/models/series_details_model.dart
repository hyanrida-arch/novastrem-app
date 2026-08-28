import '../../domain/entities/episode_entity.dart';
import '../../domain/entities/series_details_entity.dart';

/// Maps the `get_series_info` response: an `info` metadata object plus an
/// `episodes` object keyed by season number (as a string), each holding a
/// list of episode objects.
///
/// Example payload (trimmed):
/// ```json
/// {
///   "info": {
///     "name": "Severance", "cover": "http://.../severance.jpg",
///     "plot": "...", "cast": "Adam Scott, ...", "genre": "Drama, Mystery",
///     "releaseDate": "2022-02-18", "rating": "8.7"
///   },
///   "episodes": {
///     "1": [
///       { "id": "55231", "episode_num": 1, "title": "Good News About Hell",
///         "container_extension": "mp4" }
///     ]
///   }
/// }
/// ```
class SeriesDetailsModel {
  final int seriesId;
  final String name;
  final String? coverUrl;
  final String? backdropUrl;
  final String description;
  final String genre;
  final String cast;
  final String releaseDate;
  final double rating;
  final Map<int, List<EpisodeEntity>> episodesBySeason;

  const SeriesDetailsModel({
    required this.seriesId,
    required this.name,
    this.coverUrl,
    this.backdropUrl,
    this.description = '',
    this.genre = '',
    this.cast = '',
    this.releaseDate = '',
    this.rating = 0,
    this.episodesBySeason = const {},
  });

  factory SeriesDetailsModel.fromJson(Map<String, dynamic> json, {required int fallbackSeriesId}) {
    final info = (json['info'] as Map<String, dynamic>?) ?? {};
    final episodesJson = (json['episodes'] as Map<String, dynamic>?) ?? {};

    String? backdrop;
    final backdropPath = info['backdrop_path'];
    if (backdropPath is List && backdropPath.isNotEmpty) {
      backdrop = backdropPath.first?.toString();
    }

    final episodesBySeason = <int, List<EpisodeEntity>>{};
    for (final entry in episodesJson.entries) {
      final seasonNum = int.tryParse(entry.key) ?? 0;
      final episodesList = (entry.value as List<dynamic>?) ?? [];
      episodesBySeason[seasonNum] = episodesList.whereType<Map<String, dynamic>>().map((e) {
        return EpisodeEntity(
          episodeId: int.tryParse('${e['id']}') ?? 0,
          title: (e['title'] ?? 'Episode').toString(),
          episodeNum: int.tryParse('${e['episode_num'] ?? 0}') ?? 0,
          season: seasonNum,
          containerExtension: (e['container_extension'] ?? 'mp4').toString(),
        );
      }).toList(growable: false);
    }

    return SeriesDetailsModel(
      seriesId: fallbackSeriesId,
      name: (info['name'] ?? 'Untitled').toString(),
      coverUrl: info['cover']?.toString(),
      backdropUrl: backdrop,
      description: (info['plot'] ?? '').toString(),
      genre: (info['genre'] ?? '').toString(),
      cast: (info['cast'] ?? '').toString(),
      releaseDate: (info['releaseDate'] ?? info['release_date'] ?? '').toString(),
      rating: double.tryParse('${info['rating'] ?? 0}') ?? 0,
      episodesBySeason: episodesBySeason,
    );
  }

  SeriesDetailsEntity toEntity() => SeriesDetailsEntity(
        seriesId: seriesId,
        name: name,
        coverUrl: coverUrl,
        backdropUrl: backdropUrl,
        description: description,
        genre: genre,
        cast: cast,
        releaseDate: releaseDate,
        rating: rating,
        episodesBySeason: episodesBySeason,
      );
}
