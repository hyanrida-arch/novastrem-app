import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CategoryChipData {
  final String name;

  /// Which section this genre belongs to — drives both the icon and where
  /// tapping it navigates (Live TV vs Movies vs Series).
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const CategoryChipData({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

/// "Categories" — wide gradient tiles rather than plain text chips, so the
/// genre row reads as browsable artwork instead of a filter bar (the app
/// already has a real filter sheet for that).
class CategoriesRail extends StatelessWidget {
  final List<CategoryChipData> categories;
  const CategoriesRail({super.key, required this.categories});

  /// Deterministic palette so a given genre keeps the same colors between
  /// launches — `hashCode` on the name rather than a random pick.
  static List<Color> gradientFor(String name) {
    const palettes = [
      [Color(0xFF7C4DFF), Color(0xFF448AFF)],
      [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
      [Color(0xFFFF6E40), Color(0xFFFF3D00)],
      [Color(0xFFEC407A), Color(0xFF7C4DFF)],
      [Color(0xFF00B0FF), Color(0xFF00E5FF)],
      [Color(0xFFFFA726), Color(0xFFFF7043)],
    ];
    return palettes[name.hashCode.abs() % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CategoryTile(data: categories[index]),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryChipData data;
  const _CategoryTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Oversized watermark icon bleeding off the corner — adds depth
            // without competing with the label.
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(data.icon, size: 78, color: Colors.white.withValues(alpha: 0.16)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(data.icon, size: 20, color: Colors.white),
                  Text(
                    data.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
