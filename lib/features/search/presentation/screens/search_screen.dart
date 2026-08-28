import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../live_tv/presentation/providers/live_tv_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../series/presentation/providers/series_provider.dart';
import '../../../series/presentation/screens/series_details_screen.dart';
import '../../../vod/presentation/providers/vod_provider.dart';
import '../../../vod/presentation/screens/movie_details_screen.dart';

/// One row shape all three catalogs get flattened into so Search can
/// render/filter them uniformly without caring which feature they came
/// from until the moment the user taps one.
class _SearchResult {
  final ContentType type;
  final int id;
  final String title;
  final String? imageUrl;
  final String categoryId;
  final double rating;
  final String containerExtension;

  const _SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.categoryId,
    this.imageUrl,
    this.rating = 0,
    this.containerExtension = 'mp4',
  });
}

/// Global search across Live TV, Movies and Series, with type/category/
/// rating filters. Queries the same "all items" providers each catalog's
/// grid screen would (`liveChannelsProvider(null)`, `moviesProvider(null)`,
/// `seriesListProvider(null)`) rather than a dedicated search endpoint —
/// Xtream Codes has no server-side search, so this is client-side
/// filtering over whatever's already been fetched.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  String _query = '';
  final Set<ContentType> _typeFilter = {}; // empty = all types
  final Set<String> _categoryFilter = {}; // empty = all categories
  double _minRating = 0;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveChannels = ref.watch(liveChannelsProvider(null)).valueOrNull ?? [];
    final movies = ref.watch(moviesProvider(null)).valueOrNull ?? [];
    final series = ref.watch(seriesListProvider(null)).valueOrNull ?? [];

    final allResults = <_SearchResult>[
      for (final c in liveChannels)
        _SearchResult(type: ContentType.live, id: c.streamId, title: c.name, imageUrl: c.streamIcon, categoryId: c.categoryId),
      for (final m in movies)
        _SearchResult(
          type: ContentType.movie,
          id: m.streamId,
          title: m.name,
          imageUrl: m.posterUrl,
          categoryId: m.categoryId,
          rating: m.rating,
          containerExtension: m.containerExtension,
        ),
      for (final s in series)
        _SearchResult(
          type: ContentType.series,
          id: s.seriesId,
          title: s.name,
          imageUrl: s.coverUrl,
          categoryId: s.categoryId,
          rating: s.rating,
        ),
    ];

    final query = _query.trim().toLowerCase();
    final results = allResults.where((r) {
      if (query.isNotEmpty && !r.title.toLowerCase().contains(query)) return false;
      if (_typeFilter.isNotEmpty && !_typeFilter.contains(r.type)) return false;
      if (_categoryFilter.isNotEmpty && !_categoryFilter.contains(r.categoryId)) return false;
      if (_minRating > 0 && r.type != ContentType.live && r.rating < _minRating) return false;
      return true;
    }).toList();

    // Category chips only make sense once the results are scoped to a
    // single type — otherwise "News" (Live) and "Action" (Movies) would be
    // mixed in the same chip row with no way to tell them apart.
    final singleType = _typeFilter.length == 1 ? _typeFilter.first : null;
    final categories = singleType == null
        ? const <MapEntry<String, String>>[]
        : {for (final r in allResults.where((r) => r.type == singleType)) r.categoryId: r.categoryId}
            .entries
            .toList();

    return GlassScaffold(
      title: TextField(
        controller: _queryController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search Live TV, Movies & Series',
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
      // The body is a Column, not a scrollable, so apply GlassScaffold's
      // inset once as real padding — then strip it from the subtree so the
      // results ListView (which has no padding of its own, and would
      // otherwise auto-consume the same inset) doesn't double it up.
      body: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
        children: [
          _FilterBar(
            typeFilter: _typeFilter,
            onTypeToggled: (type) => setState(() {
              if (_typeFilter.contains(type)) {
                _typeFilter.remove(type);
              } else {
                _typeFilter.add(type);
              }
              _categoryFilter.clear(); // categories are type-scoped; reset on type change
            }),
            categories: categories,
            categoryFilter: _categoryFilter,
            onCategoryToggled: (categoryId) => setState(() {
              if (_categoryFilter.contains(categoryId)) {
                _categoryFilter.remove(categoryId);
              } else {
                _categoryFilter.add(categoryId);
              }
            }),
            minRating: _minRating,
            onMinRatingChanged: (value) => setState(() => _minRating = value),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyView(
                    message: query.isEmpty ? 'Search for a channel, movie or series.' : 'No matches.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => _ResultTile(result: results[index]),
                  ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final Set<ContentType> typeFilter;
  final ValueChanged<ContentType> onTypeToggled;
  final List<MapEntry<String, String>> categories;
  final Set<String> categoryFilter;
  final ValueChanged<String> onCategoryToggled;
  final double minRating;
  final ValueChanged<double> onMinRatingChanged;

  const _FilterBar({
    required this.typeFilter,
    required this.onTypeToggled,
    required this.categories,
    required this.categoryFilter,
    required this.onCategoryToggled,
    required this.minRating,
    required this.onMinRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              for (final type in ContentType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabel(type)),
                    selected: typeFilter.contains(type),
                    onSelected: (_) => onTypeToggled(type),
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.star_rounded, size: 16),
                  label: Text(minRating > 0 ? 'Rating ≥ ${minRating.toStringAsFixed(0)}' : 'Min rating'),
                  onPressed: () => _showRatingSheet(context),
                ),
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.value, style: const TextStyle(fontSize: 12.5)),
                      selected: categoryFilter.contains(category.key),
                      onSelected: (_) => onCategoryToggled(category.key),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _showRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minimum rating (Movies & Series): ${minRating.toStringAsFixed(1)}'),
                Slider(
                  value: minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setSheetState(() {});
                    onMinRatingChanged(value);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _typeLabel(ContentType type) {
    switch (type) {
      case ContentType.live:
        return 'Live TV';
      case ContentType.movie:
        return 'Movies';
      case ContentType.series:
        return 'Series';
    }
  }
}

class _ResultTile extends ConsumerWidget {
  final _SearchResult result;
  const _ResultTile({required this.result});

  IconData get _typeIcon {
    switch (result.type) {
      case ContentType.live:
        return Icons.live_tv_rounded;
      case ContentType.movie:
        return Icons.movie_rounded;
      case ContentType.series:
        return Icons.video_library_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: (result.imageUrl == null || result.imageUrl!.isEmpty)
              ? ColoredBox(color: AppColors.surfaceElevated, child: Icon(_typeIcon, color: AppColors.textSecondary))
              : CachedNetworkImage(
                  imageUrl: result.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => ColoredBox(color: AppColors.surfaceElevated, child: Icon(_typeIcon)),
                ),
        ),
      ),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_typeLabelFor(result.type), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: result.rating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 2),
                Text(result.rating.toStringAsFixed(1)),
              ],
            )
          : null,
      onTap: () => _open(context, ref),
    );
  }

  String _typeLabelFor(ContentType type) {
    switch (type) {
      case ContentType.live:
        return 'Live TV';
      case ContentType.movie:
        return 'Movie';
      case ContentType.series:
        return 'Series';
    }
  }

  void _open(BuildContext context, WidgetRef ref) {
    switch (result.type) {
      case ContentType.live:
        final url = StreamUrlResolver.live(ref, result.id);
        if (url == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              streamUrl: url,
              title: result.title,
              isLive: true,
              contentType: ContentType.live,
              contentId: result.id,
              imageUrl: result.imageUrl,
            ),
          ),
        );
      case ContentType.movie:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(vodId: result.id, fallbackTitle: result.title),
          ),
        );
      case ContentType.series:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SeriesDetailsScreen(seriesId: result.id, fallbackTitle: result.title),
          ),
        );
    }
  }
}
