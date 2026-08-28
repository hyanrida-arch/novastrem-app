import '../../domain/entities/vod_category_entity.dart';

class VodCategoryModel {
  final String categoryId;
  final String categoryName;

  const VodCategoryModel({required this.categoryId, required this.categoryName});

  factory VodCategoryModel.fromJson(Map<String, dynamic> json) {
    return VodCategoryModel(
      categoryId: json['category_id'].toString(),
      categoryName: (json['category_name'] ?? 'Unnamed').toString(),
    );
  }

  VodCategoryEntity toEntity() =>
      VodCategoryEntity(categoryId: categoryId, categoryName: categoryName);
}
