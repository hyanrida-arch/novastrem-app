import 'package:flutter/foundation.dart';

import '../../features/live_tv/domain/entities/category_entity.dart';
import '../../features/live_tv/domain/entities/channel_entity.dart';
import '../../features/series/domain/entities/series_category_entity.dart';
import '../../features/series/domain/entities/series_entity.dart';
import '../../features/vod/domain/entities/movie_entity.dart';
import '../../features/vod/domain/entities/vod_category_entity.dart';
import '../utils/year_extractor.dart';

/// The whole catalog, fetched once and pre-arranged into exactly the lists
/// the UI renders — so screens never sort during `build`.
///
/// WHY: `HomeScreen.build` previously ran four full-catalog sorts on every
/// rebuild, one of which called a RegExp ([extractYearFromTitle]) inside
/// its comparator — i.e. O(n log n) regex evaluations per frame, repeated
/// on every favourite toggle and every EPG response. On a real provider's
/// catalog that is the difference between a smooth screen and an ANR.
///
/// Everything here is computed once, on a background isolate, by
/// [prepareCatalog].
@immutable
class PreparedCatalog {
  final List<ChannelEntity> channels;
  final List<CategoryEntity> liveCategories;

  /// Movies newest-first (provider `added` timestamp, then title year).
  final List<MovieEntity> moviesNewest;

  /// Movies highest-rated first.
  final List<MovieEntity> moviesTopRated;
  final List<VodCategoryEntity> vodCategories;

  /// Series most-recently-updated first (provider `last_modified`).
  final List<SeriesEntity> seriesNewest;
  final List<SeriesEntity> seriesTopRated;
  final List<SeriesCategoryEntity> seriesCategories;

  /// categoryId -> display name, across VOD and Series. Xtream exposes no
  /// genre field on list endpoints, so a category name *is* the genre.
  final Map<String, String> categoryNames;

  const PreparedCatalog({
    required this.channels,
    required this.liveCategories,
    required this.moviesNewest,
    required this.moviesTopRated,
    required this.vodCategories,
    required this.seriesNewest,
    required this.seriesTopRated,
    required this.seriesCategories,
    required this.categoryNames,
  });

  static const empty = PreparedCatalog(
    channels: [],
    liveCategories: [],
    moviesNewest: [],
    moviesTopRated: [],
    vodCategories: [],
    seriesNewest: [],
    seriesTopRated: [],
    seriesCategories: [],
    categoryNames: {},
  );

  bool get isEmpty =>
      channels.isEmpty && moviesNewest.isEmpty && seriesNewest.isEmpty;
}

/// Raw input handed to the background isolate. Kept as plain data so it can
/// cross the isolate boundary cheaply.
@immutable
class RawCatalog {
  final List<ChannelEntity> channels;
  final List<CategoryEntity> liveCategories;
  final List<MovieEntity> movies;
  final List<VodCategoryEntity> vodCategories;
  final List<SeriesEntity> series;
  final List<SeriesCategoryEntity> seriesCategories;

  const RawCatalog({
    required this.channels,
    required this.liveCategories,
    required this.movies,
    required this.vodCategories,
    required this.series,
    required this.seriesCategories,
  });
}

/// Top-level (isolate-safe) sort/group pass.
///
/// Must stay a top-level function with no closure captures so it can be
/// handed to [compute]. Note the year is extracted **once per movie** into
/// a lookup rather than inside the comparator — that turns O(n log n)
/// regex calls into O(n), which matters far more than the isolate hop.
PreparedCatalog prepareCatalog(RawCatalog raw) {
  final yearOf = <int, int>{
    for (final movie in raw.movies) movie.streamId: extractYearFromTitle(movie.name) ?? 0,
  };

  final moviesNewest = [...raw.movies]..sort((a, b) {
      final aAdded = a.addedAt;
      final bAdded = b.addedAt;
      if (aAdded != null && bAdded != null) return bAdded.compareTo(aAdded);
      if (aAdded != null) return -1;
      if (bAdded != null) return 1;
      final byYear = (yearOf[b.streamId] ?? 0).compareTo(yearOf[a.streamId] ?? 0);
      return byYear != 0 ? byYear : b.rating.compareTo(a.rating);
    });

  final moviesTopRated = [...raw.movies]..sort((a, b) => b.rating.compareTo(a.rating));

  final seriesNewest = [...raw.series]..sort((a, b) {
      final aMod = a.lastModified;
      final bMod = b.lastModified;
      if (aMod != null && bMod != null) return bMod.compareTo(aMod);
      if (aMod != null) return -1;
      if (bMod != null) return 1;
      return b.rating.compareTo(a.rating);
    });

  final seriesTopRated = [...raw.series]..sort((a, b) => b.rating.compareTo(a.rating));

  return PreparedCatalog(
    channels: raw.channels,
    liveCategories: raw.liveCategories,
    moviesNewest: moviesNewest,
    moviesTopRated: moviesTopRated,
    vodCategories: raw.vodCategories,
    seriesNewest: seriesNewest,
    seriesTopRated: seriesTopRated,
    seriesCategories: raw.seriesCategories,
    categoryNames: {
      for (final c in raw.vodCategories) c.categoryId: c.categoryName,
      for (final c in raw.seriesCategories) c.categoryId: c.categoryName,
    },
  );
}
