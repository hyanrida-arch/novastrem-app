import 'package:hive/hive.dart';

import '../../../../core/models/content_type.dart';
import '../../domain/entities/favorite_item_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Backed by `HiveService.favoritesBox` — an untyped [Box] (plain
/// Map/primitive storage, no `@HiveType` model needed) since favorites are
/// simple enough that a hand-written `TypeAdapter` would be pure
/// boilerplate. Each entry is stored under [FavoriteItemEntity.key]
/// (`"type:id"`) as a `Map<String, dynamic>`.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final Box box;

  FavoritesRepositoryImpl(this.box);

  String _keyFor(ContentType type, int id) => '${type.name}:$id';

  @override
  List<FavoriteItemEntity> getAll() {
    final items = box.values.map((raw) => _decode(Map<String, dynamic>.from(raw as Map))).toList();
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  @override
  bool isFavorite(ContentType type, int id) => box.containsKey(_keyFor(type, id));

  @override
  Future<bool> toggle(FavoriteItemEntity item) async {
    final key = item.key;
    if (box.containsKey(key)) {
      await box.delete(key);
      return false;
    }
    await box.put(key, _encode(item));
    return true;
  }

  Map<String, dynamic> _encode(FavoriteItemEntity item) => {
        'type': item.type.index,
        'id': item.id,
        'title': item.title,
        'imageUrl': item.imageUrl,
        'addedAt': item.addedAt.millisecondsSinceEpoch,
      };

  FavoriteItemEntity _decode(Map<String, dynamic> map) => FavoriteItemEntity(
        type: ContentType.values[map['type'] as int],
        id: map['id'] as int,
        title: map['title'] as String,
        imageUrl: map['imageUrl'] as String?,
        addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
      );
}
