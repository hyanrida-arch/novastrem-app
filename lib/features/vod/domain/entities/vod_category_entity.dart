import 'package:equatable/equatable.dart';

/// A Movies (VOD) category, e.g. "Action", "2024 Releases".
class VodCategoryEntity extends Equatable {
  final String categoryId;
  final String categoryName;

  const VodCategoryEntity({required this.categoryId, required this.categoryName});

  @override
  List<Object?> get props => [categoryId, categoryName];
}
