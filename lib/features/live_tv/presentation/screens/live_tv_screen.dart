import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/models/media_filter.dart';
import '../../../../core/utils/category_matcher.dart';
import '../../../../core/utils/media_filter_engine.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/advanced_filter_bottom_sheet.dart';
import '../../../../core/widgets/common_app_bar_actions.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/rail_section.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/channel_entity.dart';
import '../providers/live_tv_provider.dart';
import '../widgets/live_channel_card.dart';

/// Live TV as browsable rails rather than one endless channel list.
///
/// Rows, in order: **Live Now** (channels currently airing a program),
/// **Most Watched** (this device's real play counts), then the semantic
/// genre rows (Sports / Movies / News / Arabic / Kids) matched against the
/// provider's own category names, then every remaining category as its own
/// row so nothing in the catalog is hidden.
///
/// Applying a filter from the AppBar collapses all of that into a single
/// flat filtered list — rails are for browsing, the filtered view is for
/// finding.
class LiveTvScreen extends ConsumerStatefulWidget {
  /// Opens straight into a category's filtered list (used by Home's
  /// Categories rail).
  final String? initialCategoryId;

  const LiveTvScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  /// How many channels we're willing to ask the panel for EPG data.
  /// Keep this small: it's one HTTP request per channel, re-evaluated
  /// on every rebuild.
  static const int _epgProbeLimit = 24;

  late MediaFilter _filter =
      MediaFilter(categoryId: widget.initialCategoryId, sortBy: SortBy.az);

  /// Genre rows this screen surfaces, in display order.
  static const _buckets = [
    CuratedBucket.sports,
    CuratedBucket.movies,
    CuratedBucket.news,
    CuratedBucket.arabic,
    CuratedBucket.kids,
  ];

  Future<void> _openFilterSheet(List<FilterCategoryOption> categories) async {
    final result = await AdvancedFilterBottomSheet.show(
      context,
      current: _filter,
      categories: categories,
      // Channels carry no rating or release year.
      showYear: false,
      showRating: false,
      sortOptions: const [SortBy.az],
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(liveCategoriesProvider);
    final channelsAsync = ref.watch(liveChannelsProvider(null));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          GlassSliverAppBar(
            title: const Text('Live TV', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
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
          ...channelsAsync.when(
            loading: () => [const SliverFillRemaining(child: LoadingView())],
            error: (err, _) => [
              SliverFillRemaining(
                child: ErrorView(
                  message: describeError(err),
                  onRetry: () => ref.invalidate(liveChannelsProvider(null)),
                ),
              ),
            ],
            data: (channels) {
              if (channels.isEmpty) {
                return [
                  const SliverFillRemaining(
                    child: EmptyView(message: 'No channels found.', icon: Icons.live_tv_rounded),
                  ),
                ];
              }
              final categories = categoriesAsync.valueOrNull ?? const <CategoryEntity>[];
              return _filter.isDefault
                  ? _buildRails(channels, categories)
                  : _buildFilteredList(channels);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Browsing mode: curated + per-category rails
  // -------------------------------------------------------------------------

  List<Widget> _buildRails(List<ChannelEntity> channels, List<CategoryEntity> categories) {
    final pairs = [for (final c in categories) (id: c.categoryId, name: c.categoryName)];
    final slivers = <Widget>[];

    // Categories already represented by a curated row — skipped in the
    // per-category rows below so the same channels don't appear twice.
    final claimed = <String>{};

    // ---- Live Now: channels with EPG data currently airing ---------------
    // IMPORTANT: only probe EPG for a bounded window of channels. Each
    // `currentEpgProvider` watch is a separate `get_short_epg` request, so
    // asking the whole catalog (real providers carry thousands of channels)
    // spawned thousands of providers and HTTP calls on every rebuild and
    // hung the app. Probe the first [_epgProbeLimit] and show whichever of
    // those are airing — the row only displays 14 anyway.
    final liveNow = [
      for (final channel in channels.take(_epgProbeLimit))
        if (ref.watch(currentEpgProvider(channel.streamId)).valueOrNull != null) channel,
    ];
    if (liveNow.isNotEmpty) {
      slivers.add(_rail('Live Now', liveNow.take(14).toList()));
    }

    // ---- Most Watched: real local play counts ----------------------------
    final mostWatchedIds = ref
        .watch(historyControllerProvider.notifier)
        .mostWatched(type: ContentType.live)
        .map((e) => e.id)
        .toList();
    if (mostWatchedIds.isNotEmpty) {
      final byId = {for (final c in channels) c.streamId: c};
      final mostWatched = [
        for (final id in mostWatchedIds)
          if (byId[id] != null) byId[id]!,
      ];
      if (mostWatched.isNotEmpty) {
        slivers.add(_rail('Most Watched', mostWatched));
      }
    }

    // ---- Semantic genre rows --------------------------------------------
    for (final bucket in _buckets) {
      final ids = CategoryMatcher.idsFor(bucket, pairs);
      if (ids.isEmpty) continue; // provider has no such category — skip the row
      final items = [
        for (final channel in channels)
          if (ids.contains(channel.categoryId)) channel,
      ];
      if (items.isEmpty) continue;
      claimed.addAll(ids);
      slivers.add(_rail(bucket.label, items.take(20).toList(), categoryIds: ids));
    }

    // ---- Everything else, one row per remaining category -----------------
    for (final category in categories) {
      if (claimed.contains(category.categoryId)) continue;
      final items = [
        for (final channel in channels)
          if (channel.categoryId == category.categoryId) channel,
      ];
      if (items.isEmpty) continue;
      slivers.add(
        _rail(category.categoryName, items.take(20).toList(), categoryIds: {category.categoryId}),
      );
    }

    return slivers;
  }

  Widget _rail(String title, List<ChannelEntity> channels, {Set<String>? categoryIds}) {
    return RailSection(
      title: title,
      // "See all" only makes sense when the row maps to real categories —
      // Live Now / Most Watched are computed, not filterable.
      onSeeAll: categoryIds != null && categoryIds.length == 1
          ? () => setState(() => _filter = _filter.copyWith(categoryId: categoryIds.first))
          : null,
      child: RailStrip(
        height: 205,
        children: [
          for (final channel in channels)
            LiveChannelCard(channel: channel, onTap: () => _play(channel)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filtered mode: one flat list
  // -------------------------------------------------------------------------

  List<Widget> _buildFilteredList(List<ChannelEntity> channels) {
    final filtered = applyMediaFilter<ChannelEntity>(
      items: channels,
      filter: _filter,
      categoryIdOf: (c) => c.categoryId,
      ratingOf: (_) => 0,
      titleOf: (c) => c.name,
      yearOf: (_) => null,
    );

    if (filtered.isEmpty) {
      return [
        const SliverFillRemaining(
          child: EmptyView(message: 'No channels match this filter.', icon: Icons.filter_alt_off_rounded),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final channel = filtered[index];
              return LiveChannelCard(
                channel: channel,
                width: double.infinity,
                onTap: () => _play(channel),
              );
            },
            childCount: filtered.length,
          ),
        ),
      ),
    ];
  }

  void _play(ChannelEntity channel) {
    final url = StreamUrlResolver.live(ref, channel.streamId);
    if (url == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          streamUrl: url,
          title: channel.name,
          isLive: true,
          contentType: ContentType.live,
          contentId: channel.streamId,
          imageUrl: channel.streamIcon,
        ),
      ),
    );
  }
}
