import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo/demo_content.dart';
import '../providers/xtream_session_provider.dart';
import 'xtream_url_builder.dart';

/// Resolves a playable URL for a Live TV / Movie / Series-episode stream ID,
/// honoring whichever session type is active (demo catalog vs. a real
/// Xtream login). Returns null when there's nothing to play with (e.g. an
/// M3U session, which doesn't carry Xtream stream-ID semantics).
///
/// Centralized here because several screens independently need the same
/// "demo vs. Xtream" branch — `live_tv_screen`, [movie_details_screen],
/// [series_details_screen], Home's rails — plus global Search results.
abstract class StreamUrlResolver {
  StreamUrlResolver._();

  static String? live(WidgetRef ref, int streamId) {
    if (ref.read(isDemoSessionProvider)) return DemoContent.streamUrlFor(streamId);
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) return null;
    return XtreamUrlBuilder(
      serverUrl: creds.serverUrl,
      username: creds.username,
      password: creds.password,
    ).liveStreamUrl(streamId);
  }

  static String? vod(WidgetRef ref, int streamId, {String ext = 'mp4'}) {
    if (ref.read(isDemoSessionProvider)) return DemoContent.streamUrlFor(streamId);
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) return null;
    return XtreamUrlBuilder(
      serverUrl: creds.serverUrl,
      username: creds.username,
      password: creds.password,
    ).vodStreamUrl(streamId, ext: ext);
  }

  static String? seriesEpisode(WidgetRef ref, int episodeId, {String ext = 'mp4'}) {
    if (ref.read(isDemoSessionProvider)) return DemoContent.streamUrlFor(episodeId);
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) return null;
    return XtreamUrlBuilder(
      serverUrl: creds.serverUrl,
      username: creds.username,
      password: creds.password,
    ).seriesEpisodeUrl(episodeId, ext: ext);
  }
}
