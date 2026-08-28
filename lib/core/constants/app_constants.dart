import 'dart:io';

/// Non-copy, non-color constants: storage keys, Xtream Codes endpoints, etc.
abstract class AppConstants {
  AppConstants._();

  // ---- Identity ----
  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  /// The single source of truth for the User-Agent NovaStream sends. Both
  /// [ApiClient] and the Settings screen read this, so what Settings shows
  /// is always what actually goes over the wire.
  static String get userAgent => 'NovaStream/$appVersion ($_platformLabel; IPTV Client)';

  static String get _platformLabel {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  // ---- Hive box / key names ----
  static const String sessionBoxName = 'novastream_session_box';
  static const String favoritesBoxName = 'novastream_favorites_box';
  static const String settingsBoxName = 'novastream_settings_box';
  static const String historyBoxName = 'novastream_history_box';
  static const String downloadsBoxName = 'novastream_downloads_box';
  static const String sessionKey = 'active_session';
  static const String settingsKey = 'app_settings';

  // ---- Xtream Codes API action names ----
  // Full player_api.php contract: https://xtream-ui/ (provider-specific host)
  static const String actionGetLiveCategories = 'get_live_categories';
  static const String actionGetLiveStreams = 'get_live_streams';
  static const String actionGetVodCategories = 'get_vod_categories';
  static const String actionGetVodStreams = 'get_vod_streams';
  static const String actionGetVodInfo = 'get_vod_info';
  static const String actionGetSeriesCategories = 'get_series_categories';
  static const String actionGetSeries = 'get_series';
  static const String actionGetSeriesInfo = 'get_series_info';
  static const String actionGetShortEpg = 'get_short_epg';

  // ---- Stream container extensions ----
  static const String liveExtensionDefault = 'ts';
  static const String vodExtensionDefault = 'mp4';

  // ---- Networking ----
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
