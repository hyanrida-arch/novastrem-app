import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/content_type.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(HiveService.historyBox),
);

/// Mirrors [FavoritesController]'s pattern: an in-memory list kept in sync
/// with Hive so widgets can `watch` it reactively.
class HistoryController extends StateNotifier<List<HistoryEntryEntity>> {
  final HistoryRepository _repository;

  HistoryController(this._repository) : super(_repository.getAll());

  /// Where to resume `(type, id)` from, or 0 if there's no resumable entry.
  int startPositionFor(ContentType type, int id) {
    final entry = _repository.get(type, id);
    if (entry == null || !entry.isResumable) return 0;
    return entry.positionMs;
  }

  Future<void> save(HistoryEntryEntity entry) async {
    await _repository.save(entry);
    state = _repository.getAll();
  }

  /// Call once when playback *starts* (not on every position tick) so
  /// [HistoryEntryEntity.playCount] reflects real sessions — this is what
  /// the "Most Watched" rails rank by.
  Future<void> recordPlayStart(HistoryEntryEntity entry) async {
    final existing = _repository.get(entry.type, entry.id);
    await _repository.save(
      existing == null
          ? entry
          : existing.copyWith(
              // Refresh display metadata in case the title/artwork changed,
              // but keep the stored position — the player will overwrite it
              // with the real one on its first periodic save.
              title: entry.title,
              imageUrl: entry.imageUrl,
              streamUrl: entry.streamUrl,
              updatedAt: DateTime.now(),
              playCount: existing.playCount + 1,
            ),
    );
    state = _repository.getAll();
  }

  /// Items ranked by how often they've actually been played, newest-watched
  /// breaking ties. Returns an empty list until something has been watched.
  List<HistoryEntryEntity> mostWatched({ContentType? type, int limit = 14}) {
    final items = [
      for (final entry in state)
        if (type == null || entry.type == type) entry,
    ]..sort((a, b) {
        final byCount = b.playCount.compareTo(a.playCount);
        return byCount != 0 ? byCount : b.updatedAt.compareTo(a.updatedAt);
      });
    return items.take(limit).toList();
  }

  Future<void> remove(ContentType type, int id) async {
    await _repository.remove(type, id);
    state = _repository.getAll();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const [];
  }
}

final historyControllerProvider = StateNotifierProvider<HistoryController, List<HistoryEntryEntity>>(
  (ref) => HistoryController(ref.watch(historyRepositoryProvider)),
);
