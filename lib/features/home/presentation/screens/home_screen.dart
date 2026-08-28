import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/catalog/catalog_provider.dart';
import '../../../../core/catalog/prepared_catalog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/common_app_bar_actions.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/utils/hero_slide_factory.dart';
import '../../../../core/widgets/hero_carousel.dart';
import '../../../../core/widgets/media_carousel.dart';
import '../../../favorites/domain/entities/favorite_item_entity.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../history/domain/entities/history_entry_entity.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../live_tv/domain/entities/channel_entity.dart';
import '../../../live_tv/presentation/providers/live_tv_provider.dart';
import '../../../live_tv/presentation/screens/live_tv_screen.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../series/presentation/screens/series_details_screen.dart';
import '../../../series/presentation/screens/series_screen.dart';
import '../../../vod/presentation/screens/movie_details_screen.dart';
import '../../../vod/presentation/screens/movies_screen.dart';
import '../widgets/categories_rail.dart';
import '../widgets/live_channels_rail.dart';

/// NovaStream's home tab, structured as six sections top-to-bottom:
///
///   1. Hero banner       — auto-playing featured slider
///   2. Quick Live Channels
///   3. New / Trending Movies
///   4. Trending Series
///   5. Categories
///   6. Continue Watching / Favorites
///
/// Everything is edge-to-edge and rail-based: no boxed cards, no dividers,
/// no fixed-height "panels" — content bleeds off the right edge of every
/// row to signal there's more to scroll, and the hero runs full-bleed under
/// the translucent app bar. Section spacing is deliberately generous
/// ([_sectionGap]) so the layout breathes rather than feeling packed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Single source of truth for vertical rhythm between sections.
  static const double _sectionGap = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Everything below is read pre-sorted from [PreparedCatalog], computed
    // once on a background isolate during [InitializationScreen]. This
    // screen deliberately does NO sorting: it used to run four
    // full-catalog sorts per build (one calling a RegExp inside its
    // comparator), which re-ran on every favourite toggle and every EPG
    // response and hung the app on a real provider's catalog.
    final catalog = ref.watch(preparedCatalogProvider);
    final liveChannels = catalog.channels;
    final liveCategories = catalog.liveCategories;
    final vodCategories = catalog.vodCategories;
    final seriesCategories = catalog.seriesCategories;
    final newMovies = catalog.moviesNewest;
    final trendingSeries = catalog.seriesTopRated;

    final history = ref.watch(historyControllerProvider).where((e) => e.isResumable).take(12).toList();
    final favorites = ref.watch(favoritesControllerProvider).take(12).toList();

    final heroSlides = _buildHeroSlides(context, ref, catalog);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          GlassSliverAppBar(
            title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
            actions: commonAppBarActions(context),
          ),

          // ---- 1. Hero banner -------------------------------------------
          SliverToBoxAdapter(child: HeroCarousel(slides: heroSlides)),

          // ---- 2. Quick Live Channels -----------------------------------
          if (liveChannels.isNotEmpty)
            _Section(
              title: 'Quick Live Channels',
              onSeeAll: () => _push(context, const LiveTvScreen()),
              child: LiveChannelsRail(
                channels: [
                  for (final channel in liveChannels.take(14))
                    LiveChannelChipData(
                      name: channel.name,
                      logoUrl: channel.streamIcon,
                      nowPlaying: ref.watch(currentEpgProvider(channel.streamId)).valueOrNull?.title,
                      onTap: () => _playLive(context, ref, channel),
                    ),
                ],
              ),
            ),

          // ---- 3. New / Trending Movies ---------------------------------
          if (newMovies.isNotEmpty)
            _Section(
              title: 'New & Trending Movies',
              onSeeAll: () => _push(context, const MoviesScreen()),
              child: MediaCardRail(
                items: [
                  for (final movie in newMovies.take(14))
                    CarouselItemData(
                      title: movie.name,
                      imageUrl: movie.posterUrl,
                      rating: movie.rating,
                      onTap: () => _push(
                        context,
                        MovieDetailsScreen(vodId: movie.streamId, fallbackTitle: movie.name),
                      ),
                    ),
                ],
              ),
            ),

          // ---- 4. Trending Series ---------------------------------------
          if (trendingSeries.isNotEmpty)
            _Section(
              title: 'Trending Series',
              onSeeAll: () => _push(context, const SeriesScreen()),
              child: MediaCardRail(
                items: [
                  for (final series in trendingSeries.take(14))
                    CarouselItemData(
                      title: series.name,
                      imageUrl: series.coverUrl,
                      rating: series.rating,
                      onTap: () => _push(
                        context,
                        SeriesDetailsScreen(seriesId: series.seriesId, fallbackTitle: series.name),
                      ),
                    ),
                ],
              ),
            ),

          // ---- 5. Categories --------------------------------------------
          _Section(
            title: 'Categories',
            child: CategoriesRail(
              categories: [
                for (final category in liveCategories.take(6))
                  CategoryChipData(
                    name: category.categoryName,
                    icon: Icons.live_tv_rounded,
                    gradient: CategoriesRail.gradientFor(category.categoryName),
                    onTap: () => _push(context, LiveTvScreen(initialCategoryId: category.categoryId)),
                  ),
                for (final category in vodCategories.take(6))
                  CategoryChipData(
                    name: category.categoryName,
                    icon: Icons.movie_rounded,
                    gradient: CategoriesRail.gradientFor(category.categoryName),
                    onTap: () => _push(context, MoviesScreen(initialCategoryId: category.categoryId)),
                  ),
                for (final category in seriesCategories.take(6))
                  CategoryChipData(
                    name: category.categoryName,
                    icon: Icons.video_library_rounded,
                    gradient: CategoriesRail.gradientFor(category.categoryName),
                    onTap: () => _push(context, SeriesScreen(initialCategoryId: category.categoryId)),
                  ),
              ],
            ),
          ),

          // ---- 6. Continue Watching / Favorites -------------------------
          if (history.isNotEmpty)
            _Section(
              title: AppStrings.continueWatching,
              onSeeAll: () => _push(context, const HistoryScreen()),
              child: MediaCardRail(
                items: [
                  for (final entry in history)
                    CarouselItemData(
                      title: entry.title,
                      imageUrl: entry.imageUrl,
                      progress: entry.progress,
                      onTap: () => _resume(context, entry),
                    ),
                ],
              ),
            ),
          if (favorites.isNotEmpty)
            _Section(
              title: AppStrings.favorites,
              child: MediaCardRail(
                items: [
                  for (final item in favorites)
                    CarouselItemData(
                      title: item.title,
                      imageUrl: item.imageUrl,
                      onTap: () => _openFavorite(context, ref, item),
                    ),
                ],
              ),
            ),

          if (history.isEmpty && favorites.isEmpty)
            const SliverToBoxAdapter(child: _EmptyPersonalSections()),

          // Clearance for the translucent bottom nav the body scrolls under.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  /// Top-rated picks across movies and series, rotating in the hero.
  /// Top-rated picks across movies and series, rotating in the hero.
  List<HeroSlideData> _buildHeroSlides(
    BuildContext context,
    WidgetRef ref,
    PreparedCatalog catalog,
  ) {
    // Already rating-sorted by `prepareCatalog` — just take the top slice.
    final topMovies = catalog.moviesTopRated.take(3);
    final topSeries = catalog.seriesTopRated.take(2);
    final categoryNames = catalog.categoryNames;

    return [
      for (final movie in topMovies)
        HeroSlideFactory.forMovie(
          context,
          ref,
          movie,
          badge: 'NEW MOVIE',
          genre: categoryNames[movie.categoryId],
        ),
      for (final show in topSeries)
        HeroSlideFactory.forSeries(
          context,
          ref,
          show,
          badge: 'TRENDING SERIES',
          genre: categoryNames[show.categoryId],
        ),
    ];
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _playLive(BuildContext context, WidgetRef ref, ChannelEntity channel) {
    final url = StreamUrlResolver.live(ref, channel.streamId);
    if (url == null) return;
    _push(
      context,
      PlayerScreen(
        streamUrl: url,
        title: channel.name,
        isLive: true,
        contentType: ContentType.live,
        contentId: channel.streamId,
        imageUrl: channel.streamIcon,
      ),
    );
  }

  void _resume(BuildContext context, HistoryEntryEntity entry) {
    _push(
      context,
      PlayerScreen(
        streamUrl: entry.streamUrl,
        title: entry.title,
        contentType: entry.type,
        contentId: entry.id,
        imageUrl: entry.imageUrl,
        startPositionMs: entry.positionMs,
      ),
    );
  }

  void _openFavorite(BuildContext context, WidgetRef ref, FavoriteItemEntity item) {
    switch (item.type) {
      case ContentType.movie:
        _push(context, MovieDetailsScreen(vodId: item.id, fallbackTitle: item.title));
      case ContentType.series:
        _push(context, SeriesDetailsScreen(seriesId: item.id, fallbackTitle: item.title));
      case ContentType.live:
        final url = StreamUrlResolver.live(ref, item.id);
        if (url == null) return;
        _push(
          context,
          PlayerScreen(
            streamUrl: url,
            title: item.title,
            isLive: true,
            contentType: ContentType.live,
            contentId: item.id,
            imageUrl: item.imageUrl,
          ),
        );
    }
  }
}

/// A titled section wrapper: consistent heading treatment, optional
/// "See all", and the shared vertical rhythm. Rendered as a sliver so every
/// section sits directly in the [CustomScrollView] rather than being nested
/// inside one giant scrolling `Column`.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  const _Section({required this.title, required this.child, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: HomeScreen._sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  if (onSeeAll != null)
                    TextButton(onPressed: onSeeAll, child: const Text('See all')),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyPersonalSections extends StatelessWidget {
  const _EmptyPersonalSections();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 44),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.explore_outlined, size: 40, color: AppColors.textDisabled),
            SizedBox(height: 12),
            Text(
              'Start watching or favoriting something\nand it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
