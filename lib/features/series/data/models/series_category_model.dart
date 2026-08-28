import '../../domain/entities/series_category_entity.dart';

class SeriesCategoryModel {
  final String categoryId;
  final String categoryName;

  const SeriesCategoryModel({required this.categoryId, required this.categoryName});

  factory SeriesCategoryModel.fromJson(Map<String, dynamic> json) {
    return SeriesCategoryModel(
      categoryId: json['category_id'].toString(),
      categoryName: (json['category_name'] ?? 'Unnamed').toString(),
    );
  }

  SeriesCategoryEntity toEntity() =>
      SeriesCategoryEntity(categoryId: categoryId, categoryName: categoryName);
}
