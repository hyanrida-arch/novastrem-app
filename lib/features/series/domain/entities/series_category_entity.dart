import 'package:equatable/equatable.dart';

class SeriesCategoryEntity extends Equatable {
  final String categoryId;
  final String categoryName;

  const SeriesCategoryEntity({required this.categoryId, required this.categoryName});

  @override
  List<Object?> get props => [categoryId, categoryName];
}
