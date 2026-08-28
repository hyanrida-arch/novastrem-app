import '../models/media_filter.dart';

/// Applies a [MediaFilter] to any list, given small accessor callbacks —
/// shared by Movies and Series so the filter/sort logic (and its "Older"
/// bucket semantics) is written exactly once.
List<T> applyMediaFilter<T>({
  required List<T> items,
  required MediaFilter filter,
  required String Function(T item) categoryIdOf,
  required double Function(T item) ratingOf,
  required String Function(T item) titleOf,
  required int? Function(T item) yearOf,
}) {
  final earliestRecentYear = DateTime.now().year - 5;

  final result = items.where((item) {
    if (filter.categoryId != null && categoryIdOf(item) != filter.categoryId) return false;
    if (filter.minRating != null && ratingOf(item) < filter.minRating!) return false;
    if (filter.minYear != null) {
      final year = yearOf(item);
      if (filter.minYear == 0) {
        // "Older" bucket — anything with a known year outside the recent chips.
        if (year == null || year >= earliestRecentYear) return false;
      } else if (year != filter.minYear) {
        return false;
      }
    }
    return true;
  }).toList();

  switch (filter.sortBy) {
    case SortBy.popular:
      result.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    case SortBy.newest:
      result.sort((a, b) => (yearOf(b) ?? 0).compareTo(yearOf(a) ?? 0));
    case SortBy.az:
      result.sort((a, b) => titleOf(a).toLowerCase().compareTo(titleOf(b).toLowerCase()));
  }
  return result;
}
