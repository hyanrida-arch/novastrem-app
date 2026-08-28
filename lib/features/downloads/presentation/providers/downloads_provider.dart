import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/models/content_type.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/repositories/downloads_repository_impl.dart';
import '../../domain/entities/download_task_entity.dart';
import '../../domain/repositories/downloads_repository.dart';

final downloadsRepositoryProvider = Provider<DownloadsRepository>(
  (ref) => DownloadsRepositoryImpl(HiveService.downloadsBox),
);

/// Drives offline downloads for Movies/Series episodes: kicks off a plain
/// `Dio().download()` to the app's private documents directory (sandboxed
/// per-app on both Android and iOS — not world-readable/shared storage,
/// which covers "secure" for a starter project without adding
/// encryption-at-rest; see the class doc below for how you'd go further),
/// tracks progress in memory, and persists metadata (not the bytes — those
/// are just a file on disk) via [DownloadsRepository] so completed/failed
/// downloads survive an app restart.
///
/// This is a foreground-only download manager: it stops if the app is
/// killed mid-download (the partial file and "downloading" status are left
/// behind — see [_resumeOrphanedDownloads]). For downloads that must
/// survive the app being killed or backgrounded for a long time, swap this
/// for a plugin backed by native background transfer APIs, e.g.
/// `background_downloader`.
class DownloadsController extends StateNotifier<List<DownloadTaskEntity>> {
  final DownloadsRepository _repository;
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadsController(this._repository) : super(_resumeOrphanedDownloads(_repository.getAll()));

  /// Anything still marked `downloading` after a restart means the app was
  /// killed mid-transfer — there's no process left updating it, so mark it
  /// `failed` (the user can retry) instead of leaving a phantom spinner.
  static List<DownloadTaskEntity> _resumeOrphanedDownloads(List<DownloadTaskEntity> tasks) {
    return tasks
        .map((t) => t.status == DownloadStatus.downloading ? t.copyWith(status: DownloadStatus.failed) : t)
        .toList();
  }

  DownloadTaskEntity? taskFor(ContentType type, int id) {
    final key = '${type.name}:$id';
    for (final task in state) {
      if (task.key == key) return task;
    }
    return null;
  }

  Future<void> start({
    required ContentType type,
    required int id,
    required String title,
    required String sourceUrl,
    String? imageUrl,
    String ext = 'mp4',
  }) async {
    final existing = taskFor(type, id);
    if (existing != null &&
        (existing.status == DownloadStatus.downloading || existing.status == DownloadStatus.completed)) {
      return;
    }

    final downloadsDir = await _downloadsDirectory();
    final key = '${type.name}:$id'; // matches DownloadTaskEntity.key
    final savePath = '${downloadsDir.path}/${key.replaceAll(':', '_')}.$ext';

    var task = DownloadTaskEntity(
      type: type,
      id: id,
      title: title,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );
    await _upsert(task, persist: true);

    final cancelToken = CancelToken();
    _cancelTokens[task.key] = cancelToken;
    var lastPersist = DateTime.now();

    try {
      await _dio.download(
        sourceUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          task = task.copyWith(downloadedBytes: received, totalBytes: total < 0 ? 0 : total);
          // Throttle Hive writes to ~once/second; the in-memory `state`
          // update (inside `_upsert`) still happens every tick so the
          // progress bar stays smooth.
          final shouldPersist = DateTime.now().difference(lastPersist) > const Duration(seconds: 1);
          if (shouldPersist) lastPersist = DateTime.now();
          _upsert(task, persist: shouldPersist);
        },
      );
      task = task.copyWith(status: DownloadStatus.completed, localPath: savePath);
      await _upsert(task, persist: true);
    } on DioException catch (e) {
      task = task.copyWith(status: CancelToken.isCancel(e) ? DownloadStatus.canceled : DownloadStatus.failed);
      await _upsert(task, persist: true);
      if (task.status == DownloadStatus.canceled) {
        await _deleteFileIfExists(savePath);
      }
    } catch (_) {
      task = task.copyWith(status: DownloadStatus.failed);
      await _upsert(task, persist: true);
    } finally {
      _cancelTokens.remove(task.key);
    }
  }

  void cancel(String key) => _cancelTokens[key]?.cancel();

  Future<void> delete(DownloadTaskEntity task) async {
    _cancelTokens[task.key]?.cancel();
    if (task.localPath != null) {
      await _deleteFileIfExists(task.localPath!);
    }
    await _repository.remove(task.key);
    state = state.where((t) => t.key != task.key).toList();
  }

  Future<void> _upsert(DownloadTaskEntity task, {required bool persist}) async {
    final next = [
      for (final t in state)
        if (t.key != task.key) t,
      task,
    ];
    state = next;
    if (persist) await _repository.save(task);
  }

  Future<Directory> _downloadsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${docsDir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<void> _deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort — a locked/already-gone file shouldn't block removal
        // of the download entry itself.
      }
    }
  }
}

final downloadsControllerProvider = StateNotifierProvider<DownloadsController, List<DownloadTaskEntity>>(
  (ref) => DownloadsController(ref.watch(downloadsRepositoryProvider)),
);
