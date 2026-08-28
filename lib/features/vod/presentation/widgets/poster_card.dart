import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_surface.dart';

/// A single poster tile used by both the Movies and Series filtered grids
/// (the flat "results" view — [MediaCard] is the equivalent for Netflix-
/// style horizontal rails). Shares [RatingBadge] and [AppColors.cardShadow]
/// with [MediaCard] so both views read as one consistent design language.
class PosterCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final double rating;
  final VoidCallback onTap;

  const PosterCard({
    super.key,
    required this.title,
    required this.onTap,
    this.posterUrl,
    this.rating = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _poster(),
                    if (rating > 0)
                      Positioned(top: 6, right: 6, child: RatingBadge(rating: rating)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.25),
          ),
        ],
      ),
    );
  }

  Widget _poster() {
    if (posterUrl == null || posterUrl!.isEmpty) {
      return const ColoredBox(
        color: AppColors.card,
        child: Icon(Icons.movie_rounded, color: AppColors.textSecondary, size: 32),
      );
    }
    return CachedNetworkImage(
      imageUrl: posterUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.surfaceElevated,
        child: const ColoredBox(color: AppColors.card),
      ),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.card,
        child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
      ),
    );
  }
}
