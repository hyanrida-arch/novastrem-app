import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../../favorites/domain/entities/favorite_item_entity.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../domain/entities/channel_entity.dart';
import '../providers/live_tv_provider.dart';

/// A channel tile sized for horizontal rails: landscape logo plate, an
/// always-visible favorite toggle in the corner, and the current EPG
/// program plus an elapsed-progress bar underneath.
///
/// The heart is a direct toggle (not a menu) so favoriting never costs more
/// than one tap from browsing.
class LiveChannelCard extends ConsumerWidget {
  final ChannelEntity channel;
  final VoidCallback onTap;
  final double width;

  /// Shows the "what's on now" line + progress bar. Off for compact rails
  /// where the extra two lines would crowd the row.
  final bool showEpg;

  const LiveChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.width = 168,
    this.showEpg = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesControllerProvider.select(
        (favorites) => favorites.any((f) => f.type == ContentType.live && f.id == channel.streamId),
      ),
    );
    final program = showEpg ? ref.watch(currentEpgProvider(channel.streamId)).valueOrNull : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
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
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppColors.card,
                        child: (channel.streamIcon == null || channel.streamIcon!.isEmpty)
                            ? const Icon(Icons.live_tv_rounded, color: AppColors.textSecondary, size: 30)
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: CachedNetworkImage(
                                  imageUrl: channel.streamIcon!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.live_tv_rounded,
                                    color: AppColors.textSecondary,
                                    size: 30,
                                  ),
                                  placeholder: (_, _) => const SizedBox.shrink(),
                                ),
                              ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.live,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _FavoriteToggle(channel: channel, isFavorite: isFavorite),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (program != null) ...[
              const SizedBox(height: 3),
              Text(
                program.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: program.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small translucent scrim behind the heart so it stays legible over both
/// bright and dark channel logos.
class _FavoriteToggle extends ConsumerWidget {
  final ChannelEntity channel;
  final bool isFavorite;

  const _FavoriteToggle({required this.channel, required this.isFavorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
      ),
      child: InkWell(
        onTap: () => ref.read(favoritesControllerProvider.notifier).toggle(
              FavoriteItemEntity(
                type: ContentType.live,
                id: channel.streamId,
                title: channel.name,
                imageUrl: channel.streamIcon,
                addedAt: DateTime.now(),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17,
            color: isFavorite ? AppColors.accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
