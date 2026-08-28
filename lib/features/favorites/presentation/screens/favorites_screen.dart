import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../series/presentation/screens/series_details_screen.dart';
import '../../../vod/presentation/screens/movie_details_screen.dart';
import '../../../vod/presentation/widgets/poster_card.dart';
import '../../domain/entities/favorite_item_entity.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorite_button.dart';

/// "My List" — everything the user has hearted, newest first.
///
/// NOTE ON NAMING: in NovaStream, "My List" and "Favorites" are the *same*
/// collection. The hero banner's "+ My List" button and the heart toggles
/// on cards/rows both write to [favoritesControllerProvider]; there is only
/// one store. This screen is the single place that collection is browsable
/// in full. (If a separate watch-later list is ever wanted, it needs its
/// own repository + Hive box — it isn't just a second label on this one.)
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// null = "All".
  ContentType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(favoritesControllerProvider);
    final items = _typeFilter == null
        ? all
        : [
            for (final item in all)
              if (item.type == _typeFilter) item,
          ];

    return GlassScaffold(
      title: const Text('My List'),
      body: Builder(
        builder: (context) {
          final topInset = MediaQuery.paddingOf(context).top;

          if (all.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topInset),
              child: const EmptyView(
                message: 'Nothing saved yet.\nTap the heart on any channel, movie or series.',
                icon: Icons.favorite_border_rounded,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _TypeChip(
                        label: 'All',
                        count: all.length,
                        selected: _typeFilter == null,
                        onSelected: () => setState(() => _typeFilter = null),
                      ),
                      for (final type in ContentType.values)
                        () {
                          final count = all.where((i) => i.type == type).length;
                          if (count == 0) return const SizedBox.shrink();
                          return _TypeChip(
                            label: _labelFor(type),
                            count: count,
                            selected: _typeFilter == type,
                            onSelected: () => setState(() => _typeFilter = type),
                          );
                        }(),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(message: 'Nothing saved in this section.', icon: Icons.favorite_border_rounded),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.56,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FavoriteTile(item: items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _labelFor(ContentType type) {
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

/// Poster tile with the heart overlaid, so removing something from the list
/// doesn't require opening it first.
class _FavoriteTile extends ConsumerWidget {
  final FavoriteItemEntity item;
  const _FavoriteTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: PosterCard(
            title: item.title,
            posterUrl: item.imageUrl,
            onTap: () => _open(context, ref),
          ),
        ),
        Positioned(
          top: -4,
          left: -4,
          child: FavoriteButton(
            type: item.type,
            id: item.id,
            title: item.title,
            imageUrl: item.imageUrl,
            size: 20,
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    switch (item.type) {
      case ContentType.movie:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(vodId: item.id, fallbackTitle: item.title),
          ),
        );
      case ContentType.series:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SeriesDetailsScreen(seriesId: item.id, fallbackTitle: item.title),
          ),
        );
      case ContentType.live:
        // Channels have no details screen — play them straight away.
        final url = StreamUrlResolver.live(ref, item.id);
        if (url == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              streamUrl: url,
              title: item.title,
              isLive: true,
              contentType: ContentType.live,
              contentId: item.id,
              imageUrl: item.imageUrl,
            ),
          ),
        );
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label · $count'),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
