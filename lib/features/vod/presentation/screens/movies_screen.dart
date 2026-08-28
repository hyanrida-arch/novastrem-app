import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/models/media_filter.dart';
import '../../../../core/utils/category_matcher.dart';
import '../../../../core/utils/hero_slide_factory.dart';
import '../../../../core/utils/media_filter_engine.dart';
import '../../../../core/utils/year_extractor.dart';
import '../../../../core/widgets/advanced_filter_bottom_sheet.dart';
import '../../../../core/widgets/common_app_bar_actions.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/hero_carousel.dart';
import '../../../../core/widgets/media_carousel.dart';
import '../../../../core/widgets/rail_section.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../domain/entities/movie_entity.dart';
import '../../domain/entities/vod_category_entity.dart';
import '../providers/vod_provider.dart';
import '../widgets/poster_card.dart';
import 'movie_details_screen.dart';

/// Movies: an immersive auto-playing hero banner over large-poster rails —
/// **New This Week**, **Most Watched**, **Arabic**, **Foreign**, genre rows
/// (Action / Comedy / Horror / Drama / Documentaries), then every remaining
/// provider category.
///
/// Applying a filter swaps banner and rails for a single flat poster grid:
/// the hero is a browsing showcase, not chrome, so it goes away once the
/// user is deliberately narrowing results.
class MoviesScreen extends ConsumerStatefulWidget {
  /// Opens straight into a category's filtered grid.
  final String? initialCategoryId;

  const MoviesScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  /// Drives the app bar's transparent -> glass crossfade. A notifier
  /// (rather than setState) so scrolling repaints only the bar.
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  late MediaFilter _filter = MediaFilter(categoryId: widget.initialCategoryId);

  static const _buckets = [
    CuratedBucket.arabic,
    CuratedBucket.foreign,
    CuratedBucket.action,
    CuratedBucket.comedy,
    CuratedBucket.horror,
    CuratedBucket.drama,
    CuratedBucket.documentary,
  ];

  Future<void> _openFilterSheet(List<FilterCategoryOption> categories) async {
    final result = await AdvancedFilterBottomSheet.show(context, current: _filter, categories: categories);
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(vodCategoriesProvider);
    final moviesAsync = ref.watch(moviesProvider(null));

    // A hero banner only exists in browsing mode; with a filter applied the
    // body is a plain grid, so the bar must stay glass to stay readable.
    final hasHero = _filter.isDefault;

    return Scaffold(
      // Lets the hero run to the very top edge, under both this bar and the
      // status bar.
      extendBodyBehindAppBar: true,
      appBar: HeroOverlayAppBar(
        scrollOffset: _scrollOffset,
        transparentAtTop: hasHero,
        title: const Text('Movies', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        actions: [
              categoriesAsync.maybeWhen(
                data: (categories) => FilterIconButton(
                  active: !_filter.isDefault,
                  onPressed: () => _openFilterSheet([
                    for (final c in categories)
                      FilterCategoryOption(id: c.categoryId, name: c.categoryName),
                  ]),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
          ...commonAppBarActions(context),
        ],
      ),
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _scrollOffset.value = notification.metrics.pixels;
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
          ...moviesAsync.when(
            loading: () => [const SliverFillRemaining(child: LoadingView())],
            error: (err, _) => [
              SliverFillRemaining(
                child: ErrorView(
                  message: describeError(err),
                  onRetry: () => ref.invalidate(moviesProvider(null)),
                ),
              ),
            ],
            data: (movies) {
              if (movies.isEmpty) {
                return [
                  const SliverFillRemaining(
                    child: EmptyView(message: 'No movies found.', icon: Icons.movie_rounded),
                  ),
                ];
              }
              final categories = categoriesAsync.valueOrNull ?? const <VodCategoryEntity>[];
              return _filter.isDefault ? _buildRails(movies, categories) : _buildFilteredGrid(movies);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRails(List<MovieEntity> movies, List<VodCategoryEntity> categories) {
    final pairs = [for (final c in categories) (id: c.categoryId, name: c.categoryName)];
    final categoryNames = {for (final c in categories) c.categoryId: c.categoryName};
    final slivers = <Widget>[];
    final claimed = <String>{};

    // ---- Hero: newest arrivals, falling back to top-rated ----------------
    // First sliver in the scroll view, and the Scaffold uses
    // `extendBodyBehindAppBar`, so it runs to the very top edge — under the
    // transparent app bar and the status bar — then scrolls away.
    final featured = _featured(movies);
    if (featured.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: HeroCarousel(
            slides: [
              for (final movie in featured)
                HeroSlideFactory.forMovie(
                  context,
                  ref,
                  movie,
                  badge: 'NEW MOVIE',
                  genre: categoryNames[movie.categoryId],
                ),
            ],
          ),
        ),
      );
    }

    // ---- New This Week: real `added` timestamps from the provider --------
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final newThisWeek = [
      for (final movie in movies)
        if (movie.addedAt != null && movie.addedAt!.isAfter(weekAgo)) movie,
    ]..sort((a, b) => b.addedAt!.compareTo(a.addedAt!));
    if (newThisWeek.isNotEmpty) {
      slivers.add(_rail('New This Week', newThisWeek.take(14).toList()));
    }

    // ---- Most Watched: this device's real play counts --------------------
    final watchedIds =
        ref.watch(historyControllerProvider.notifier).mostWatched(type: ContentType.movie).map((e) => e.id);
    final byId = {for (final m in movies) m.streamId: m};
    final mostWatched = [
      for (final id in watchedIds)
        if (byId[id] != null) byId[id]!,
    ];
    if (mostWatched.isNotEmpty) {
      slivers.add(_rail('Most Watched', mostWatched));
    }

    // ---- Semantic genre rows --------------------------------------------
    for (final bucket in _buckets) {
      final ids = CategoryMatcher.idsFor(bucket, pairs);
      if (ids.isEmpty) continue;
      final items = [
        for (final movie in movies)
          if (ids.contains(movie.categoryId)) movie,
      ];
      if (items.isEmpty) continue;
      claimed.addAll(ids);
      final label = bucket == CuratedBucket.arabic || bucket == CuratedBucket.foreign
          ? '${bucket.label} Movies'
          : bucket.label;
      slivers.add(_rail(label, items.take(20).toList(), categoryIds: ids));
    }

    // ---- Remaining provider categories -----------------------------------
    for (final category in categories) {
      if (claimed.contains(category.categoryId)) continue;
      final items = [
        for (final movie in movies)
          if (movie.categoryId == category.categoryId) movie,
      ];
      if (items.isEmpty) continue;
      slivers.add(
        _rail(category.categoryName, items.take(20).toList(), categoryIds: {category.categoryId}),
      );
    }

    return slivers;
  }

  /// Up to five banner picks: genuinely newest by the provider's `added`
  /// timestamp, falling back to highest-rated for panels that omit it.
  List<MovieEntity> _featured(List<MovieEntity> movies) {
    final dated = [
      for (final movie in movies)
        if (movie.addedAt != null) movie,
    ]..sort((a, b) => b.addedAt!.compareTo(a.addedAt!));
    if (dated.length >= 3) return dated.take(5).toList();
    return ([...movies]..sort((a, b) => b.rating.compareTo(a.rating))).take(5).toList();
  }

  Widget _rail(String title, List<MovieEntity> movies, {Set<String>? categoryIds}) {
    return RailSection(
      title: title,
      onSeeAll: categoryIds != null && categoryIds.length == 1
          ? () => setState(() => _filter = _filter.copyWith(categoryId: categoryIds.first))
          : null,
      child: MediaCardRail(
        cardWidth: 140,
        items: [
          for (final movie in movies)
            CarouselItemData(
              title: movie.name,
              imageUrl: movie.posterUrl,
              rating: movie.rating,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(vodId: movie.streamId, fallbackTitle: movie.name),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredGrid(List<MovieEntity> movies) {
    final filtered = applyMediaFilter<MovieEntity>(
      items: movies,
      filter: _filter,
      categoryIdOf: (m) => m.categoryId,
      ratingOf: (m) => m.rating,
      titleOf: (m) => m.name,
      // Prefer the provider's real `added` year; fall back to the title.
      yearOf: (m) => m.addedAt?.year ?? extractYearFromTitle(m.name),
    );

    if (filtered.isEmpty) {
      return [
        const SliverFillRemaining(
          child: EmptyView(message: 'No movies match these filters.', icon: Icons.filter_alt_off_rounded),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 18,
            crossAxisSpacing: 12,
            childAspectRatio: 0.56,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final movie = filtered[index];
              return PosterCard(
                title: movie.name,
                posterUrl: movie.posterUrl,
                rating: movie.rating,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(vodId: movie.streamId, fallbackTitle: movie.name),
                  ),
                ),
              );
            },
            childCount: filtered.length,
          ),
        ),
      ),
    ];
  }
}
