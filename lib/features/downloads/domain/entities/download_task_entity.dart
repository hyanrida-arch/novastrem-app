import 'package:equatable/equatable.dart';

import '../../../../core/models/content_type.dart';

enum DownloadStatus { queued, downloading, completed, failed, canceled }

/// A single offline download — a Movie or Series episode saved to the
/// app's private documents directory for playback without a network
/// connection. Live TV isn't downloadable (there's nothing fixed to save).
class DownloadTaskEntity extends Equatable {
  final ContentType type;
  final int id;
  final String title;
  final String? imageUrl;
  final String sourceUrl;

  /// Absolute path to the file on disk once [status] is `completed`.
  final String? localPath;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime createdAt;

  const DownloadTaskEntity({
    required this.type,
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.localPath,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  String get key => '${type.name}:$id';

  double get progress => totalBytes <= 0 ? 0 : (downloadedBytes / totalBytes).clamp(0, 1);

  DownloadTaskEntity copyWith({
    String? localPath,
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return DownloadTaskEntity(
      type: type,
      id: id,
      title: title,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [type, id, title, imageUrl, sourceUrl, localPath, status, downloadedBytes, totalBytes, createdAt];
}
