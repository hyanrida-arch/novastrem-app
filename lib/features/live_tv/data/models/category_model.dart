import '../../domain/entities/category_entity.dart';

/// Maps the JSON objects returned by `get_live_categories` (and, with the
/// same shape, `get_vod_categories` / `get_series_categories`) to
/// [CategoryEntity].
///
/// Example payload:
/// ```json
/// { "category_id": "5", "category_name": "USA - Sports", "parent_id": 0 }
/// ```
class CategoryModel {
  final String categoryId;
  final String categoryName;

  const CategoryModel({required this.categoryId, required this.categoryName});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'].toString(),
      categoryName: (json['category_name'] ?? 'Unnamed').toString(),
    );
  }

  CategoryEntity toEntity() => CategoryEntity(categoryId: categoryId, categoryName: categoryName);
}
