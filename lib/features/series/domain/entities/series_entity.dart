import 'package:equatable/equatable.dart';

/// A series as it appears in the grid (from `get_series`). Season/episode
/// data is fetched on demand via [SeriesDetailsEntity].
class SeriesEntity extends Equatable {
  final int seriesId;
  final String name;
  final String? coverUrl;
  final String categoryId;
  final double rating;

  /// Xtream's `last_modified` on `get_series` — bumped when a provider adds
  /// episodes, which makes it the best available "new season dropped"
  /// signal. Null when a panel omits the field.
  final DateTime? lastModified;

  const SeriesEntity({
    required this.seriesId,
    required this.name,
    required this.categoryId,
    this.coverUrl,
    this.rating = 0,
    this.lastModified,
  });

  @override
  List<Object?> get props => [seriesId, name, coverUrl, categoryId, rating, lastModified];
}
