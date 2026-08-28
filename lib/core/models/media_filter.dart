import 'package:equatable/equatable.dart';

enum SortBy {
  popular('Popular'),
  newest('Newest'),
  az('A-Z');

  final String label;
  const SortBy(this.label);
}

/// One entry in the Genre `ChoiceChip` row — deliberately decoupled from any
/// specific domain entity (Xtream category, series category, ...) so
/// [AdvancedFilterBottomSheet] stays reusable across Live TV/Movies/Series.
class FilterCategoryOption extends Equatable {
  final String id;
  final String name;
  const FilterCategoryOption({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Filter/sort criteria applied client-side over an already-fetched list —
/// Xtream Codes has no server-side query params for any of this beyond
/// category, so Genre/Year/Rating/Sort are all resolved locally.
class MediaFilter extends Equatable {
  final String? categoryId; // Genre — null = All
  final int? minYear;
  final double? minRating; // 0..10 scale
  final SortBy sortBy;

  const MediaFilter({this.categoryId, this.minYear, this.minRating, this.sortBy = SortBy.popular});

  /// Whether any *narrowing* criterion is set. Deliberately excludes
  /// [sortBy] — choosing a sort order doesn't exclude anything from the
  /// results, so it shouldn't light up the Filter icon's "active" badge.
  /// (This also matters because a screen like Live TV defaults to
  /// `SortBy.az` rather than `SortBy.popular` — comparing against a fixed
  /// "default" sort would make the badge show as active on first load,
  /// even though nothing was actually filtered.)
  bool get isDefault => categoryId == null && minYear == null && minRating == null;

  MediaFilter copyWith({
    String? categoryId,
    bool clearCategoryId = false,
    int? minYear,
    bool clearMinYear = false,
    double? minRating,
    bool clearMinRating = false,
    SortBy? sortBy,
  }) {
    return MediaFilter(
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [categoryId, minYear, minRating, sortBy];
}
