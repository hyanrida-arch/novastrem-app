import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
import '../../../history/domain/entities/history_entry_entity.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../vod/presentation/widgets/poster_card.dart';
import '../../domain/entities/series_category_entity.dart';
import '../../domain/entities/series_entity.dart';
import '../providers/series_provider.dart';
import 'series_details_screen.dart';

/// Series: an immersive auto-playing hero banner, then a deliberately
/// prominent **Continue Watching** row — wide 16:9 resume cards with
/// progress bars, the only rail on the screen not using poster art, so
/// picking up a half-finished episode stays the most obvious action below
/// the banner.
///
/// Below those: **New Seasons** (provider `last_modified`), **Completed
/// Series** (only when the provider actually labels categories that way),
/// genre rows, then every remaining category.
class SeriesScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const SeriesScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
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
    CuratedBucket.drama,
    CuratedBucket.comedy,
    CuratedBucket.action,
    CuratedBucket.documentary,
  ];

  Future<void> _openFilterSheet(List<FilterCategoryOption> categories) async {
    final result = await AdvancedFilterBottomSheet.show(context, current: _filter, categories: categories);
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    final seriesAsync = ref.watch(seriesListProvider(null));

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
        title: const Text('Series', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
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
          ...seriesAsync.when(
            loading: () => [const SliverFillRemaining(child: LoadingView())],
            error: (err, _) => [
              SliverFillRemaining(
                child: ErrorView(
                  message: describeError(err),
                  onRetry: () => ref.invalidate(seriesListProvider(null)),
                ),
              ),
            ],
            data: (seriesList) {
              if (seriesList.isEmpty) {
                return [
                  const SliverFillRemaining(
                    child: EmptyView(message: 'No series found.', icon: Icons.tv_rounded),
                  ),
                ];
              }
              final categories = categoriesAsync.valueOrNull ?? const <SeriesCategoryEntity>[];
              return _filter.isDefault
                  ? _buildRails(seriesList, categories)
                  : _buildFilteredGrid(seriesList);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRails(List<SeriesEntity> seriesList, List<SeriesCategoryEntity> categories) {
    final pairs = [for (final c in categories) (id: c.categoryId, name: c.categoryName)];
    final categoryNames = {for (final c in categories) c.categoryId: c.categoryName};
    final slivers = <Widget>[];
    final claimed = <String>{};

    // ---- Hero: freshest seasons, falling back to top-rated ---------------
    final featured = _featured(seriesList);
    if (featured.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: HeroCarousel(
            slides: [
              for (final series in featured)
                HeroSlideFactory.forSeries(
                  context,
                  ref,
                  series,
                  badge: 'NEW SEASON',
                  genre: categoryNames[series.categoryId],
                ),
            ],
          ),
        ),
      );
    }

    // ---- Continue Watching --------------------------------------------
    // Still the first *row* under the banner, and still the only one using
    // wide 16:9 resume cards, so resuming stays the most obvious action.
    final resumable = ref
        .watch(historyControllerProvider)
        .where((e) => e.type == ContentType.series && e.isResumable)
        .take(10)
        .toList();
    if (resumable.isNotEmpty) {
      slivers.add(
        RailSection(
          title: 'Continue Watching',
          child: RailStrip(
            height: 186,
            children: [
              for (final entry in resumable) _ResumeCard(entry: entry, onTap: () => _resume(entry)),
            ],
          ),
        ),
      );
    }

    // ---- New Seasons: provider `last_modified` ---------------------------
    final withDates = [
      for (final series in seriesList)
        if (series.lastModified != null) series,
    ]..sort((a, b) => b.lastModified!.compareTo(a.lastModified!));
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final newSeasons = [
      for (final series in withDates)
        if (series.lastModified!.isAfter(monthAgo)) series,
    ];
    if (newSeasons.isNotEmpty) {
      slivers.add(_rail('New Seasons', newSeasons.take(14).toList()));
    }

    // ---- Completed Series -------------------------------------------------
    // Xtream's series list has no "ended/completed" flag, so this can only
    // be populated when the provider names a category that way. No match ->
    // the row is omitted rather than filled with a guess.
    final completedIds = CategoryMatcher.idsFor(CuratedBucket.completed, pairs);
    if (completedIds.isNotEmpty) {
      final completed = [
        for (final series in seriesList)
          if (completedIds.contains(series.categoryId)) series,
      ];
      if (completed.isNotEmpty) {
        claimed.addAll(completedIds);
        slivers.add(_rail('Completed Series', completed.take(20).toList(), categoryIds: completedIds));
      }
    }

    // ---- Genre rows -------------------------------------------------------
    for (final bucket in _buckets) {
      final ids = CategoryMatcher.idsFor(bucket, pairs);
      if (ids.isEmpty) continue;
      final items = [
        for (final series in seriesList)
          if (ids.contains(series.categoryId)) series,
      ];
      if (items.isEmpty) continue;
      claimed.addAll(ids);
      slivers.add(_rail(bucket.label, items.take(20).toList(), categoryIds: ids));
    }

    // ---- Remaining provider categories -----------------------------------
    for (final category in categories) {
      if (claimed.contains(category.categoryId)) continue;
      final items = [
        for (final series in seriesList)
          if (series.categoryId == category.categoryId) series,
      ];
      if (items.isEmpty) continue;
      slivers.add(
        _rail(category.categoryName, items.take(20).toList(), categoryIds: {category.categoryId}),
      );
    }

    return slivers;
  }

  /// Up to five banner picks: most recently updated by the provider's
  /// `last_modified`, falling back to highest-rated when it's absent.
  List<SeriesEntity> _featured(List<SeriesEntity> seriesList) {
    final dated = [
      for (final series in seriesList)
        if (series.lastModified != null) series,
    ]..sort((a, b) => b.lastModified!.compareTo(a.lastModified!));
    if (dated.length >= 3) return dated.take(5).toList();
    return ([...seriesList]..sort((a, b) => b.rating.compareTo(a.rating))).take(5).toList();
  }

  Widget _rail(String title, List<SeriesEntity> seriesList, {Set<String>? categoryIds}) {
    return RailSection(
      title: title,
      onSeeAll: categoryIds != null && categoryIds.length == 1
          ? () => setState(() => _filter = _filter.copyWith(categoryId: categoryIds.first))
          : null,
      child: MediaCardRail(
        cardWidth: 140,
        items: [
          for (final series in seriesList)
            CarouselItemData(
              title: series.name,
              imageUrl: series.coverUrl,
              rating: series.rating,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeriesDetailsScreen(seriesId: series.seriesId, fallbackTitle: series.name),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredGrid(List<SeriesEntity> seriesList) {
    final filtered = applyMediaFilter<SeriesEntity>(
      items: seriesList,
      filter: _filter,
      categoryIdOf: (s) => s.categoryId,
      ratingOf: (s) => s.rating,
      titleOf: (s) => s.name,
      yearOf: (s) => extractYearFromTitle(s.name),
    );

    if (filtered.isEmpty) {
      return [
        const SliverFillRemaining(
          child: EmptyView(message: 'No series match these filters.', icon: Icons.filter_alt_off_rounded),
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
              final series = filtered[index];
              return PosterCard(
                title: series.name,
                posterUrl: series.coverUrl,
                rating: series.rating,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SeriesDetailsScreen(seriesId: series.seriesId, fallbackTitle: series.name),
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

  void _resume(HistoryEntryEntity entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          streamUrl: entry.streamUrl,
          title: entry.title,
          contentType: entry.type,
          contentId: entry.id,
          imageUrl: entry.imageUrl,
          startPositionMs: entry.positionMs,
        ),
      ),
    );
  }
}

/// Wide 16:9 resume card — deliberately bigger and more detailed than the
/// poster cards below (play affordance, remaining-time label, progress bar)
/// so "Continue Watching" reads as the primary call to action.
class _ResumeCard extends StatelessWidget {
  final HistoryEntryEntity entry;
  final VoidCallback onTap;

  const _ResumeCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 232,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (entry.imageUrl == null || entry.imageUrl!.isEmpty)
                        const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.tv_rounded, color: AppColors.textSecondary, size: 30),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.surfaceElevated,
                            child: Icon(Icons.tv_rounded, color: AppColors.textSecondary, size: 30),
                          ),
                          placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceElevated),
                        ),
                      const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimBottom)),
                      const Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: entry.progress,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _remainingLabel(entry),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String _remainingLabel(HistoryEntryEntity entry) {
    final remainingMs = entry.durationMs - entry.positionMs;
    if (remainingMs <= 0) return 'Resume';
    final minutes = (remainingMs / 60000).ceil();
    return minutes >= 60
        ? '${(minutes / 60).floor()}h ${minutes % 60}m left'
        : '$minutes min left';
  }
}
