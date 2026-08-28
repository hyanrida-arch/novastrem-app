import 'package:equatable/equatable.dart';

import '../../../../core/models/content_type.dart';

/// A "last watched" entry: which stream, how far into it the user got, and
/// the resolved URL to resume it with.
///
/// [streamUrl] is captured at save time rather than re-derived from Xtream
/// credentials at resume time — simpler, and correct for the common case
/// (resuming within the same signed-in session). If the active
/// session/account changes between watching and resuming, a stale entry's
/// URL may no longer be valid; `HistoryScreen` surfaces a normal playback
/// error in that case rather than silently failing.
class HistoryEntryEntity extends Equatable {
  final ContentType type;
  final int id;
  final String title;
  final String? imageUrl;
  final String streamUrl;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;

  /// How many times playback has been *started* for this item — incremented
  /// once per session by [HistoryController.recordPlayStart], not by the
  /// periodic position saves. This is what powers the "Most Watched" rails;
  /// Xtream exposes no server-side view counts, so this local signal is the
  /// only genuine popularity data the app has.
  final int playCount;

  const HistoryEntryEntity({
    required this.type,
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    this.imageUrl,
    this.playCount = 1,
  });

  String get key => '${type.name}:$id';

  HistoryEntryEntity copyWith({
    String? title,
    String? imageUrl,
    String? streamUrl,
    int? positionMs,
    int? durationMs,
    DateTime? updatedAt,
    int? playCount,
  }) {
    return HistoryEntryEntity(
      type: type,
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAt: updatedAt ?? this.updatedAt,
      playCount: playCount ?? this.playCount,
    );
  }

  /// 0..1, or 0 when duration isn't known yet (e.g. Live TV).
  double get progress => durationMs <= 0 ? 0 : (positionMs / durationMs).clamp(0, 1);

  /// Don't offer to "resume" something that's essentially finished.
  bool get isResumable => type != ContentType.live && progress < 0.95 && positionMs > 5000;

  @override
  List<Object?> get props =>
      [type, id, title, imageUrl, streamUrl, positionMs, durationMs, updatedAt, playCount];
}
