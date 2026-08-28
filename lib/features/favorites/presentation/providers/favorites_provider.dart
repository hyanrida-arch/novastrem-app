import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/content_type.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/entities/favorite_item_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepositoryImpl(HiveService.favoritesBox),
);

/// Holds the current favorites list in memory so widgets can `watch` it
/// reactively (Hive's `Box` itself isn't a Riverpod-observable object).
/// Every mutation goes through [toggle], which writes to Hive first and
/// only updates `state` once that succeeds.
class FavoritesController extends StateNotifier<List<FavoriteItemEntity>> {
  final FavoritesRepository _repository;

  FavoritesController(this._repository) : super(_repository.getAll());

  bool isFavorite(ContentType type, int id) => _repository.isFavorite(type, id);

  Future<void> toggle(FavoriteItemEntity item) async {
    await _repository.toggle(item);
    state = _repository.getAll();
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, List<FavoriteItemEntity>>(
  (ref) => FavoritesController(ref.watch(favoritesRepositoryProvider)),
);
