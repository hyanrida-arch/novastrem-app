/// Centralized copy for NovaStream. Keeping strings here (instead of
/// scattered string literals) makes future localization a drop-in swap for
/// `AppLocalizations`.
abstract class AppStrings {
  AppStrings._();

  static const String appName = 'NovaStream';
  static const String appTagline = 'Your Universe of Entertainment';

  // Login screen
  static const String loginTitle = 'Sign in to NovaStream';
  static const String loginSubtitle = 'Sign in to access Live TV, Movies & Series';
  static const String demoAccountTitle = 'Try Quick Demo Account';
  static const String demoAccountSubtitle =
      'Instant access with pre-loaded Live TV, Movies & Series';
  static const String loginXtreamTab = 'Xtream Codes API';
  static const String loginM3uTab = 'M3U Playlist URL';
  static const String fieldProfileName = 'Profile Name (Optional)';
  static const String fieldServerUrl = 'Server URL (http://domain:port/)';
  static const String fieldServerUrlHint = 'http://your-provider.com:8080';
  static const String fieldUsername = 'Username';
  static const String fieldPassword = 'Password';
  static const String fieldM3uUrl = 'M3U URL';
  static const String fieldM3uUrlHint = 'http://provider.com/playlist.m3u';
  static const String fieldPlaylistName = 'Playlist Name (Optional)';
  static const String buttonLogin = 'Login';
  static const String buttonConnectXtream = 'CONNECT TO XTREAM CODES';
  static const String buttonConnectM3u = 'CONNECT TO PLAYLIST';
  static const String rememberMe = 'Remember me';
  static const String loginError = 'Unable to sign in. Check your details and try again.';

  // Dashboard
  static const String sectionHome = 'Home';
  static const String sectionLiveTv = 'Live TV';
  static const String sectionMovies = 'Movies';
  static const String sectionSeries = 'Series';
  static const String sectionSettings = 'Settings';

  // Home screen
  static const String continueWatching = 'Continue Watching';
  static const String favorites = 'Favorites';
  static const String downloads = 'Downloads';
  static const String search = 'Search';

  // Generic
  static const String retry = 'Retry';
  static const String loading = 'Loading…';
  static const String noData = 'Nothing to show yet.';
  static const String errorGeneric = 'Something went wrong.';
  static const String errorNoInternet = 'No internet connection.';
  static const String play = 'Play';
  static const String logout = 'Logout';
}
