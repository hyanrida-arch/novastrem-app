import 'package:hive/hive.dart';

import '../../../../core/models/content_type.dart';
import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';

/// Backed by `HiveService.historyBox` — same untyped-`Box` approach as
/// Favorites (see that feature's repository for why).
class HistoryRepositoryImpl implements HistoryRepository {
  final Box box;

  HistoryRepositoryImpl(this.box);

  String _keyFor(ContentType type, int id) => '${type.name}:$id';

  @override
  List<HistoryEntryEntity> getAll() {
    final items = box.values.map((raw) => _decode(Map<String, dynamic>.from(raw as Map))).toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  HistoryEntryEntity? get(ContentType type, int id) {
    final raw = box.get(_keyFor(type, id));
    if (raw == null) return null;
    return _decode(Map<String, dynamic>.from(raw as Map));
  }

  /// Position saves must never clobber the accumulated [playCount] — the
  /// player writes progress every few seconds and doesn't know (or care)
  /// how many times the item has been started, so carry the stored value
  /// forward whenever the incoming entry would lower it.
  @override
  Future<void> save(HistoryEntryEntity entry) {
    final existing = get(entry.type, entry.id);
    final merged = existing != null && existing.playCount > entry.playCount
        ? entry.copyWith(playCount: existing.playCount)
        : entry;
    return box.put(merged.key, _encode(merged));
  }

  @override
  Future<void> remove(ContentType type, int id) => box.delete(_keyFor(type, id));

  @override
  Future<void> clear() => box.clear();

  Map<String, dynamic> _encode(HistoryEntryEntity e) => {
        'type': e.type.index,
        'id': e.id,
        'title': e.title,
        'imageUrl': e.imageUrl,
        'streamUrl': e.streamUrl,
        'positionMs': e.positionMs,
        'durationMs': e.durationMs,
        'updatedAt': e.updatedAt.millisecondsSinceEpoch,
        'playCount': e.playCount,
      };

  HistoryEntryEntity _decode(Map<String, dynamic> map) => HistoryEntryEntity(
        type: ContentType.values[map['type'] as int],
        id: map['id'] as int,
        title: map['title'] as String,
        imageUrl: map['imageUrl'] as String?,
        streamUrl: map['streamUrl'] as String,
        positionMs: map['positionMs'] as int,
        durationMs: map['durationMs'] as int,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
        // Entries written before play counts existed decode as 1.
        playCount: (map['playCount'] as int?) ?? 1,
      );
}
