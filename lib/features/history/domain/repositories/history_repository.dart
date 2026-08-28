import '../../../../core/models/content_type.dart';
import '../entities/history_entry_entity.dart';

abstract class HistoryRepository {
  /// Newest-first.
  List<HistoryEntryEntity> getAll();

  HistoryEntryEntity? get(ContentType type, int id);

  Future<void> save(HistoryEntryEntity entry);

  Future<void> remove(ContentType type, int id);

  Future<void> clear();
}
