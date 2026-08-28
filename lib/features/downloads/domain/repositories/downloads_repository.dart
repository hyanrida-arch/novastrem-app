import '../entities/download_task_entity.dart';

/// Persists download *metadata* only (title, status, byte counts, local
/// path). The actual file I/O lives in `DownloadsController` /
/// `DownloadService` — this repository just remembers what's on disk
/// across app restarts.
abstract class DownloadsRepository {
  List<DownloadTaskEntity> getAll();
  Future<void> save(DownloadTaskEntity task);
  Future<void> remove(String key);
}
