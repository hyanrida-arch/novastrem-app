import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'glass_surface.dart';

/// Everything a [MediaCard] needs, decoupled from whichever domain entity
/// (movie, series, channel, history entry...) it's rendering — lets Home's
/// carousels mix content types in one rail without each screen re-deriving
/// this shape itself.
class CarouselItemData {
  final String title;
  final String? imageUrl;
  final double rating;
  final VoidCallback onTap;

  /// 0..1 — draws a thin progress bar under the card (Continue Watching).
  final double? progress;

  const CarouselItemData({
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.rating = 0,
    this.progress,
  });
}

/// Netflix-style poster card: rounded corners, drop shadow, rating badge
/// over the artwork, optional progress sliver for "Continue Watching."
class MediaCard extends StatelessWidget {
  final CarouselItemData data;
  final double width;
  final double aspectRatio;

  const MediaCard({super.key, required this.data, this.width = 128, this.aspectRatio = 2 / 3});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data.imageUrl == null || data.imageUrl!.isEmpty)
                        const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.movie_creation_outlined, color: AppColors.textSecondary, size: 32),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: data.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceElevated),
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.surfaceElevated,
                            child: Icon(Icons.movie_creation_outlined, color: AppColors.textSecondary, size: 32),
                          ),
                        ),
                      if (data.rating > 0)
                        Positioned(top: 6, right: 6, child: RatingBadge(rating: data.rating)),
                      if (data.progress != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: data.progress!.clamp(0, 1),
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled horizontal rail of [MediaCard]s — the building block of every
/// Netflix-style row across Home, Movies and Series.
class MediaCarouselSection extends StatelessWidget {
  final String title;
  final List<CarouselItemData> items;
  final VoidCallback? onSeeAll;
  final double cardWidth;

  const MediaCarouselSection({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.cardWidth = 128,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        MediaCardRail(items: items, cardWidth: cardWidth),
        const SizedBox(height: 22),
      ],
    );
  }
}

/// Just the horizontal strip of [MediaCard]s, with no heading of its own —
/// for callers that already render their own section header (Home's
/// `_Section` does, so it would otherwise draw two).
class MediaCardRail extends StatelessWidget {
  final List<CarouselItemData> items;
  final double cardWidth;

  const MediaCardRail({super.key, required this.items, this.cardWidth = 128});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      // Poster (aspectRatio 2/3 -> height = width*1.5) + spacing + up to
      // two lines of title text. Measured empirically with a margin —
      // Text's rendered height runs a few px over the naive
      // fontSize*lineHeight*lines math because of font metrics.
      height: cardWidth * 1.5 + 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => MediaCard(data: items[index], width: cardWidth),
      ),
    );
  }
}
