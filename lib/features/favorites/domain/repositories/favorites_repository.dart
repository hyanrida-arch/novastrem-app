import '../../../../core/models/content_type.dart';
import '../entities/favorite_item_entity.dart';

abstract class FavoritesRepository {
  /// Newest-first.
  List<FavoriteItemEntity> getAll();

  bool isFavorite(ContentType type, int id);

  /// Adds [item] if not already favorited, removes it otherwise.
  /// Returns the new favorited state (true = now favorited).
  Future<bool> toggle(FavoriteItemEntity item);
}
