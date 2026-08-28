import 'url_normalizer.dart';

/// Builds every URL NovaStream needs to talk to an Xtream Codes panel.
///
/// Xtream Codes exposes a single PHP endpoint (`player_api.php`) for all
/// JSON queries, and separate path-based endpoints for the actual media
/// streams. Centralizing the string-building here means the rest of the app
/// never hand-rolls a URL.
class XtreamUrlBuilder {
  final String serverUrl;
  final String username;
  final String password;

  XtreamUrlBuilder({
    required String serverUrl,
    required this.username,
    required this.password,
  }) : serverUrl = normalizeUrl(serverUrl);

  /// `player_api.php` base query params shared by every action.
  Map<String, String> get _baseParams => {
        'username': username,
        'password': password,
      };

  /// Login / account-info call: `player_api.php?username=..&password=..`
  Uri get loginUrl => Uri.parse('$serverUrl/player_api.php').replace(
        queryParameters: _baseParams,
      );

  /// Generic `player_api.php` action call, e.g. `get_live_categories`.
  Uri action(String action, [Map<String, String>? extraParams]) {
    return Uri.parse('$serverUrl/player_api.php').replace(
      queryParameters: {
        ..._baseParams,
        'action': action,
        ...?extraParams,
      },
    );
  }

  /// Live TV stream URL: `/live/{user}/{pass}/{streamId}.{ext}`
  String liveStreamUrl(int streamId, {String ext = 'ts'}) {
    return '$serverUrl/live/$username/$password/$streamId.$ext';
  }

  /// VOD (movie) stream URL: `/movie/{user}/{pass}/{streamId}.{ext}`
  String vodStreamUrl(int streamId, {String ext = 'mp4'}) {
    return '$serverUrl/movie/$username/$password/$streamId.$ext';
  }

  /// Series episode stream URL: `/series/{user}/{pass}/{episodeId}.{ext}`
  String seriesEpisodeUrl(int episodeId, {String ext = 'mp4'}) {
    return '$serverUrl/series/$username/$password/$episodeId.$ext';
  }
}
