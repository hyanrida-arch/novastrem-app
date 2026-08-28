import 'package:equatable/equatable.dart';

import '../../../../core/models/content_type.dart';

/// A single favorited channel/movie/series. Deliberately flat (no nested
/// domain entities) since favorites only need enough to render a tile and
/// navigate back to the right screen — not the full catalog entity.
class FavoriteItemEntity extends Equatable {
  final ContentType type;
  final int id;
  final String title;
  final String? imageUrl;
  final DateTime addedAt;

  const FavoriteItemEntity({
    required this.type,
    required this.id,
    required this.title,
    required this.addedAt,
    this.imageUrl,
  });

  /// Storage/lookup key — unique per (type, id) pair.
  String get key => '${type.name}:$id';

  @override
  List<Object?> get props => [type, id, title, imageUrl, addedAt];
}
