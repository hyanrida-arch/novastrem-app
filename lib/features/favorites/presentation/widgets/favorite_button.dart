import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../domain/entities/favorite_item_entity.dart';
import '../providers/favorites_provider.dart';

/// Heart toggle button reused on channel tiles, poster cards, and details
/// screens across Live TV / Movies / Series. Filled + accent color when
/// favorited, outline + secondary color otherwise.
class FavoriteButton extends ConsumerWidget {
  final ContentType type;
  final int id;
  final String title;
  final String? imageUrl;

  /// Smaller icon for use inside a grid card's corner badge; the default
  /// size suits an `IconButton` on a details screen's action row.
  final double size;

  const FavoriteButton({
    super.key,
    required this.type,
    required this.id,
    required this.title,
    this.imageUrl,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesControllerProvider.select((favorites) => favorites.any((f) => f.type == type && f.id == id)),
    );

    return IconButton(
      iconSize: size,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? AppColors.accent : Colors.white,
      ),
      tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      onPressed: () {
        ref.read(favoritesControllerProvider.notifier).toggle(
              FavoriteItemEntity(
                type: type,
                id: id,
                title: title,
                imageUrl: imageUrl,
                addedAt: DateTime.now(),
              ),
            );
      },
    );
  }
}
