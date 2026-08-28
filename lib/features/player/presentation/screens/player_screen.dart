import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../../history/domain/entities/history_entry_entity.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Universal playback screen shared by Live TV, Movies and Series.
///
/// Backed by `flutter_vlc_player` (libVLC), which — unlike the stock
/// `video_player` plugin — natively handles the container/codec zoo IPTV
/// providers throw at clients: MPEG-TS (`.ts`) live streams, HLS (`.m3u8`),
/// `.mp4`, and `.mkv` VOD files, all through one consistent API.
///
/// Reads "Hardware Acceleration" and "Buffer Size" straight from the
/// Settings screen's persisted preferences (see `settings_provider.dart`)
/// so those controls actually affect playback, not just sit there.
///
/// When [contentType]/[contentId] are supplied (movies, series episodes,
/// and Live TV all pass them), this screen doubles as the write side of
/// Watch History: it saves playback position every few seconds and once
/// more on dispose, and — if [startPositionMs] is non-zero — seeks there
/// once the stream initializes, so tapping a "Continue Watching" entry
/// picks up where you left off.
///
/// `defaultPlayer` (VLC vs ExoPlayer) is *not* branched on yet: this
/// starter only wires up flutter_vlc_player. To honor that preference for
/// real, add a second engine (e.g. the `video_player` plugin, which uses
/// ExoPlayer on Android) and switch between two implementations of this
/// screen's body based on
/// `ref.watch(settingsControllerProvider).defaultPlayer`.
class PlayerScreen extends ConsumerStatefulWidget {
  final String streamUrl;
  final String title;

  /// True for Live TV (shows a LIVE badge, no seek bar, never resumed).
  final bool isLive;

  /// True when [streamUrl] is actually a local filesystem path — i.e.
  /// playing back a completed [DownloadTaskEntity]. Swaps
  /// `VlcPlayerController.network` for `.file` so libVLC opens it as a
  /// file:// URI instead of trying to fetch it over the network.
  final bool isLocalFile;

  final ContentType? contentType;
  final int? contentId;
  final String? imageUrl;

  /// Where to seek to once the stream is ready. 0 = start from the top.
  final int startPositionMs;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.isLive = false,
    this.isLocalFile = false,
    this.contentType,
    this.contentId,
    this.imageUrl,
    this.startPositionMs = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final VlcPlayerController _controller;
  Timer? _historyTimer;
  bool _hasSeekedToStart = false;

  /// Whether this session may write to Watch History. Resolved once in
  /// [initState] — flipping Incognito mid-playback shouldn't half-record a
  /// session that already counted a play.
  bool _tracksHistory = false;

  @override
  void initState() {
    super.initState();
    // Force landscape + immersive chrome for a "TV" feel while playing.
    SystemChromeHelper.enterImmersivePlayback();

    final settings = ref.read(settingsControllerProvider);
    // Incognito (Settings > History) suppresses play counts and resume
    // positions entirely — existing history is left alone, we just stop
    // adding to it.
    _tracksHistory =
        widget.contentType != null && widget.contentId != null && !settings.incognito;
    final hwAcc = settings.hardwareAcceleration ? HwAcc.full : HwAcc.disabled;

    _controller = widget.isLocalFile
        ? VlcPlayerController.file(
            File(widget.streamUrl),
            hwAcc: hwAcc,
            autoPlay: true,
          )
        : VlcPlayerController.network(
            widget.streamUrl,
            hwAcc: hwAcc,
            autoPlay: true,
            options: VlcPlayerOptions(
              advanced: VlcAdvancedOptions([
                VlcAdvancedOptions.networkCaching(settings.bufferSizeMs),
              ]),
            ),
          );
    _controller.addListener(_onControllerUpdate);

    if (_tracksHistory) {
      // Count this as one play session up front (not per position-save), so
      // the "Most Watched" rails rank by real play counts.
      unawaited(
        ref.read(historyControllerProvider.notifier).recordPlayStart(
              HistoryEntryEntity(
                type: widget.contentType!,
                id: widget.contentId!,
                title: widget.title,
                imageUrl: widget.imageUrl,
                streamUrl: widget.streamUrl,
                positionMs: 0,
                durationMs: 0,
                updatedAt: DateTime.now(),
              ),
            ),
      );

      // Periodic rather than continuous so we're not hammering Hive on
      // every video frame — every 8s is frequent enough that a crash/kill
      // loses at most a few seconds of resume accuracy.
      _historyTimer = Timer.periodic(const Duration(seconds: 8), (_) => _saveHistory());
    }

    if (widget.startPositionMs > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final resumeAt = Duration(milliseconds: widget.startPositionMs);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resuming from ${_formatDuration(resumeAt)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  /// Seeks to [PlayerScreen.startPositionMs] the first time the controller
  /// reports itself initialized — `flutter_vlc_player`'s controller doesn't
  /// expose a one-shot "ready" future, so we watch its `ValueNotifier` and
  /// act once.
  void _onControllerUpdate() {
    if (!_hasSeekedToStart && widget.startPositionMs > 0 && _controller.value.isInitialized) {
      _hasSeekedToStart = true;
      _controller.seekTo(Duration(milliseconds: widget.startPositionMs));
    }
  }

  Future<void> _saveHistory() async {
    if (!_tracksHistory || !mounted) return;
    final value = _controller.value;
    if (!value.isInitialized) return;

    // Live streams don't have a meaningful duration/resume position, but we
    // still log them (durationMs: 0) so they show up in "recently watched".
    if (!widget.isLive && value.duration.inMilliseconds <= 0) return;

    await ref.read(historyControllerProvider.notifier).save(
          HistoryEntryEntity(
            type: widget.contentType!,
            id: widget.contentId!,
            title: widget.title,
            imageUrl: widget.imageUrl,
            streamUrl: widget.streamUrl,
            positionMs: widget.isLive ? 0 : value.position.inMilliseconds,
            durationMs: widget.isLive ? 0 : value.duration.inMilliseconds,
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    unawaited(_saveHistory()); // best-effort final save; Hive I/O needs no BuildContext
    _controller.removeListener(_onControllerUpdate);
    SystemChromeHelper.exitImmersivePlayback();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: VlcPlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  if (widget.isLive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

/// Small helper wrapping `SystemChrome` calls so the player screen reads
/// cleanly: forces landscape + hides system bars while a stream is
/// playing, then restores the app's normal chrome on the way out.
abstract class SystemChromeHelper {
  static void enterImmersivePlayback() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static void exitImmersivePlayback() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
