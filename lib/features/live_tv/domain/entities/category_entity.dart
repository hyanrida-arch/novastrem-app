import 'package:equatable/equatable.dart';

/// A Live TV category (e.g. "Sports", "News", "Kids") as returned by
/// Xtream's `get_live_categories` action.
class CategoryEntity extends Equatable {
  final String categoryId;
  final String categoryName;

  const CategoryEntity({required this.categoryId, required this.categoryName});

  @override
  List<Object?> get props => [categoryId, categoryName];
}
