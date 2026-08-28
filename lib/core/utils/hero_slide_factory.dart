import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/favorites/domain/entities/favorite_item_entity.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/series/domain/entities/series_entity.dart';
import '../../features/series/presentation/screens/series_details_screen.dart';
import '../../features/vod/domain/entities/movie_entity.dart';
import '../../features/vod/presentation/screens/movie_details_screen.dart';
import '../models/content_type.dart';
import '../widgets/hero_carousel.dart';
import 'stream_url_resolver.dart';
import 'year_extractor.dart';

/// Builds [HeroSlideData] from catalog entities.
///
/// Home, Movies and Series all front a hero banner over the same two entity
/// types, so the wiring (resolve stream URL → push player, toggle
/// favorites, strip the year out of the title into the metadata line) lives
/// here once instead of three times.
///
/// Lives in `core/utils` alongside [StreamUrlResolver], which already
/// reaches into features for the same reason: these are cross-feature glue,
/// not feature-owned logic.
abstract class HeroSlideFactory {
  HeroSlideFactory._();

  /// [genre] should be the item's *category name* — Xtream list endpoints
  /// carry no genre field, and a category is precisely the genre bucket in
  /// an Xtream catalog. Pass null when the category is unknown.
  static HeroSlideData forMovie(
    BuildContext context,
    WidgetRef ref,
    MovieEntity movie, {
    required String badge,
    String? genre,
  }) {
    final isFavorite = ref
        .watch(favoritesControllerProvider)
        .any((f) => f.type == ContentType.movie && f.id == movie.streamId);

    return HeroSlideData(
      title: stripYearFromTitle(movie.name),
      badge: badge,
      imageUrl: movie.posterUrl,
      rating: movie.rating,
      year: extractYearFromTitle(movie.name),
      genre: genre,
      inMyList: isFavorite,
      onPlay: () {
        final url = StreamUrlResolver.vod(ref, movie.streamId, ext: movie.containerExtension);
        if (url == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              streamUrl: url,
              title: movie.name,
              contentType: ContentType.movie,
              contentId: movie.streamId,
              imageUrl: movie.posterUrl,
            ),
          ),
        );
      },
      onOpenDetails: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MovieDetailsScreen(vodId: movie.streamId, fallbackTitle: movie.name),
        ),
      ),
      onToggleMyList: () => ref.read(favoritesControllerProvider.notifier).toggle(
            FavoriteItemEntity(
              type: ContentType.movie,
              id: movie.streamId,
              title: movie.name,
              imageUrl: movie.posterUrl,
              addedAt: DateTime.now(),
            ),
          ),
    );
  }

  static HeroSlideData forSeries(
    BuildContext context,
    WidgetRef ref,
    SeriesEntity series, {
    required String badge,
    String? genre,
  }) {
    final isFavorite = ref
        .watch(favoritesControllerProvider)
        .any((f) => f.type == ContentType.series && f.id == series.seriesId);

    void openDetails() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SeriesDetailsScreen(seriesId: series.seriesId, fallbackTitle: series.name),
          ),
        );

    return HeroSlideData(
      title: stripYearFromTitle(series.name),
      badge: badge,
      imageUrl: series.coverUrl,
      rating: series.rating,
      year: extractYearFromTitle(series.name),
      genre: genre,
      inMyList: isFavorite,
      // A series has no single stream to play — both Play and the backdrop
      // land on the episode picker, which is the real "start watching" step.
      onPlay: openDetails,
      onOpenDetails: openDetails,
      onToggleMyList: () => ref.read(favoritesControllerProvider.notifier).toggle(
            FavoriteItemEntity(
              type: ContentType.series,
              id: series.seriesId,
              title: series.name,
              imageUrl: series.coverUrl,
              addedAt: DateTime.now(),
            ),
          ),
    );
  }
}
