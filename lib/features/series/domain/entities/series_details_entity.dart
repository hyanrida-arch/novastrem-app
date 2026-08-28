import 'package:equatable/equatable.dart';

import 'episode_entity.dart';

/// Full detail payload from `get_series_info`: metadata plus every episode,
/// grouped by season number for easy rendering as an expandable list.
class SeriesDetailsEntity extends Equatable {
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

  const SeriesDetailsEntity({
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

  @override
  List<Object?> get props => [
        seriesId,
        name,
        coverUrl,
        backdropUrl,
        description,
        genre,
        cast,
        releaseDate,
        rating,
        episodesBySeason,
      ];
}
