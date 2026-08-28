import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/media_filter.dart';

/// The permanent Filter icon each of Live TV/Movies/Series carries in its
/// AppBar, with a small dot badge whenever a non-default filter is active
/// so it's obvious browsing isn't showing the full, unfiltered catalog.
class FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  const FilterIconButton({super.key, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter & Sort',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune_rounded),
          if (active)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium filter sheet shared by Live TV, Movies and Series. Shows Genre +
/// Sort always; Year + Rating are opt-in via [showYear]/[showRating] since
/// they don't mean anything for a live channel list.
///
/// Usage:
/// ```dart
/// final result = await AdvancedFilterBottomSheet.show(
///   context,
///   current: filter,
///   categories: categories.map((c) => FilterCategoryOption(id: c.categoryId, name: c.categoryName)).toList(),
/// );
/// if (result != null) setState(() => filter = result);
/// ```
class AdvancedFilterBottomSheet extends StatefulWidget {
  final MediaFilter current;
  final List<FilterCategoryOption> categories;
  final bool showYear;
  final bool showRating;

  /// Which Sort chips to offer — Live TV has no rating/year data to sort by
  /// (channels aren't rated or dated), so it passes just `[SortBy.az]`
  /// rather than showing "Newest"/"Popular" options that couldn't do
  /// anything.
  final List<SortBy> sortOptions;

  const AdvancedFilterBottomSheet({
    super.key,
    required this.current,
    required this.categories,
    this.showYear = true,
    this.showRating = true,
    this.sortOptions = SortBy.values,
  });

  static Future<MediaFilter?> show(
    BuildContext context, {
    required MediaFilter current,
    required List<FilterCategoryOption> categories,
    bool showYear = true,
    bool showRating = true,
    List<SortBy> sortOptions = SortBy.values,
  }) {
    return showModalBottomSheet<MediaFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedFilterBottomSheet(
        current: current,
        categories: categories,
        showYear: showYear,
        showRating: showRating,
        sortOptions: sortOptions,
      ),
    );
  }

  @override
  State<AdvancedFilterBottomSheet> createState() => _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState extends State<AdvancedFilterBottomSheet> {
  late MediaFilter _draft = widget.current;

  /// Recent-years chips generated off the real clock rather than hardcoded,
  /// so this doesn't quietly go stale — plus a catch-all "Older" bucket.
  late final List<int> _recentYears = List.generate(6, (i) => DateTime.now().year - i);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Filter & Sort', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      ),
                      TextButton(
                        // Reset to *this screen's* neutral sort (Live TV's
                        // is A-Z, Movies/Series' is Popular) rather than a
                        // fixed default — picking the first of whatever
                        // `sortOptions` this sheet was actually given.
                        onPressed: () => setState(
                          () => _draft = MediaFilter(sortBy: widget.sortOptions.first),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    children: [
                      if (widget.categories.isNotEmpty) ...[
                        _SectionLabel('Genre'),
                        _ChipWrap(
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _draft.categoryId == null,
                              onSelected: (_) => setState(() => _draft = _draft.copyWith(clearCategoryId: true)),
                            ),
                            for (final category in widget.categories)
                              ChoiceChip(
                                label: Text(category.name),
                                selected: _draft.categoryId == category.id,
                                onSelected: (_) => setState(() => _draft = _draft.copyWith(categoryId: category.id)),
                              ),
                          ],
                        ),
                      ],
                      if (widget.showYear) ...[
                        _SectionLabel('Release Year'),
                        _ChipWrap(
                          children: [
                            ChoiceChip(
                              label: const Text('Any'),
                              selected: _draft.minYear == null,
                              onSelected: (_) => setState(() => _draft = _draft.copyWith(clearMinYear: true)),
                            ),
                            for (final year in _recentYears)
                              ChoiceChip(
                                label: Text('$year'),
                                selected: _draft.minYear == year,
                                onSelected: (_) => setState(() => _draft = _draft.copyWith(minYear: year)),
                              ),
                            ChoiceChip(
                              label: const Text('Older'),
                              selected: _draft.minYear == 0,
                              onSelected: (_) => setState(() => _draft = _draft.copyWith(minYear: 0)),
                            ),
                          ],
                        ),
                      ],
                      if (widget.showRating) ...[
                        _SectionLabel('Rating'),
                        _ChipWrap(
                          children: [
                            ChoiceChip(
                              label: const Text('Any'),
                              selected: _draft.minRating == null,
                              onSelected: (_) => setState(() => _draft = _draft.copyWith(clearMinRating: true)),
                            ),
                            for (final stars in [3, 4, 4.5])
                              ChoiceChip(
                                avatar: const Icon(Icons.star_rounded, size: 16, color: AppColors.ratingGold),
                                label: Text('${stars.toStringAsFixed(stars == stars.roundToDouble() ? 0 : 1)}+'),
                                // Ratings in this app are 0..10; stars are the
                                // familiar 0..5 UI convention, so map 1:2.
                                selected: _draft.minRating == stars * 2,
                                onSelected: (_) => setState(() => _draft = _draft.copyWith(minRating: stars * 2)),
                              ),
                          ],
                        ),
                      ],
                      if (widget.sortOptions.length > 1) ...[
                        _SectionLabel('Sort By'),
                        _ChipWrap(
                          children: [
                            for (final sort in widget.sortOptions)
                              ChoiceChip(
                                label: Text(sort.label),
                                selected: _draft.sortBy == sort,
                                onSelected: (_) => setState(() => _draft = _draft.copyWith(sortBy: sort)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<Widget> children;
  const _ChipWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}
