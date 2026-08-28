import 'package:equatable/equatable.dart';

/// Full detail payload from `get_vod_info`, used by the movie details page.
class MovieDetailsEntity extends Equatable {
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

  const MovieDetailsEntity({
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

  @override
  List<Object?> get props => [
        streamId,
        name,
        posterUrl,
        backdropUrl,
        description,
        genre,
        director,
        cast,
        releaseDate,
        rating,
        duration,
        containerExtension,
      ];
}
