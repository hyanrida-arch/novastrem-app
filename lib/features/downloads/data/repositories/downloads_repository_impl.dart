import 'package:hive/hive.dart';

import '../../../../core/models/content_type.dart';
import '../../domain/entities/download_task_entity.dart';
import '../../domain/repositories/downloads_repository.dart';

/// Backed by `HiveService.downloadsBox` — same untyped-`Box` approach as
/// Favorites/History.
class DownloadsRepositoryImpl implements DownloadsRepository {
  final Box box;

  DownloadsRepositoryImpl(this.box);

  @override
  List<DownloadTaskEntity> getAll() {
    final items = box.values.map((raw) => _decode(Map<String, dynamic>.from(raw as Map))).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> save(DownloadTaskEntity task) => box.put(task.key, _encode(task));

  @override
  Future<void> remove(String key) => box.delete(key);

  Map<String, dynamic> _encode(DownloadTaskEntity t) => {
        'type': t.type.index,
        'id': t.id,
        'title': t.title,
        'imageUrl': t.imageUrl,
        'sourceUrl': t.sourceUrl,
        'localPath': t.localPath,
        'status': t.status.index,
        'downloadedBytes': t.downloadedBytes,
        'totalBytes': t.totalBytes,
        'createdAt': t.createdAt.millisecondsSinceEpoch,
      };

  DownloadTaskEntity _decode(Map<String, dynamic> map) => DownloadTaskEntity(
        type: ContentType.values[map['type'] as int],
        id: map['id'] as int,
        title: map['title'] as String,
        imageUrl: map['imageUrl'] as String?,
        sourceUrl: map['sourceUrl'] as String,
        localPath: map['localPath'] as String?,
        status: DownloadStatus.values[map['status'] as int],
        downloadedBytes: map['downloadedBytes'] as int,
        totalBytes: map['totalBytes'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
