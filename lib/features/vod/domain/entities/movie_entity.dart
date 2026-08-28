import 'package:equatable/equatable.dart';

/// A movie as it appears in a grid (list item from `get_vod_streams`) —
/// intentionally lightweight; full details are fetched on demand via
/// [MovieDetailsEntity] to keep the grid fast.
class MovieEntity extends Equatable {
  final int streamId;
  final String name;
  final String? posterUrl;
  final String categoryId;
  final double rating;
  final String containerExtension;

  /// When the provider added this title to their catalog (Xtream's `added`
  /// unix timestamp on `get_vod_streams`). This is the only *real* recency
  /// signal Xtream offers — "New This Week" uses it rather than guessing
  /// from a year in the title. Null when a panel omits the field.
  final DateTime? addedAt;

  const MovieEntity({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.posterUrl,
    this.rating = 0,
    this.containerExtension = 'mp4',
    this.addedAt,
  });

  @override
  List<Object?> get props =>
      [streamId, name, posterUrl, categoryId, rating, containerExtension, addedAt];
}
