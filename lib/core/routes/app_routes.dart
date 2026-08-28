/// Named routes used with `Navigator`. Kept as plain string constants
/// (rather than a routing package) to keep the starter project dependency-
/// light; swap in `go_router` later if deep-linking becomes a requirement.
abstract class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  /// Post-login catalog preparation; fades into [dashboard] when done.
  static const String initializing = '/initializing';
  static const String dashboard = '/dashboard';
  static const String liveChannels = '/live-tv/channels';
  static const String movieDetails = '/movies/details';
  static const String seriesDetails = '/series/details';
  static const String player = '/player';
}
