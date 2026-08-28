import 'package:equatable/equatable.dart';

/// Which playback engine a stream should be opened with.
///
/// NovaStream ships wired up to `flutter_vlc_player` end-to-end (see
/// [PlayerScreen]). [exoPlayer] is modeled here because IPTV Smarters-style
/// apps commonly offer the choice, but actually branching playback to a
/// second engine (e.g. the `video_player` / ExoPlayer-backed plugin) is a
/// separate integration — see the TODO in `player_screen.dart` for where
/// that branch would go.
enum PlayerBackend { vlc, exoPlayer }

/// App language. Kept to the two the Settings screen's toggle supports;
/// add more `Locale`s here and in `app.dart`'s `supportedLocales` together.
enum AppLanguage {
  english('en', 'English'),
  arabic('ar', 'العربية');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  static AppLanguage fromCode(String code) =>
      AppLanguage.values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.english);
}

/// All user-configurable, locally-persisted app preferences.
class SettingsEntity extends Equatable {
  final AppLanguage language;
  final bool hardwareAcceleration;
  final PlayerBackend defaultPlayer;

  /// VLC network-caching buffer, in milliseconds. Higher = smoother on flaky
  /// connections but slower to start; lower = snappier start but more
  /// prone to stalling. 3000ms is a reasonable IPTV default.
  final int bufferSizeMs;

  /// SHA-256 hex digest of the 4-digit Parental Control PIN, or null if the
  /// user hasn't set one. Never store the raw PIN — see
  /// `settings_repository_impl.dart` for the hashing.
  final String? parentalPinHash;

  /// When on, playback stops being recorded: no Watch History entries and no
  /// play counts, so nothing feeds "Continue Watching" or "Most Watched".
  /// Enforced in [PlayerScreen] — see its history-saving guard.
  final bool incognito;

  const SettingsEntity({
    this.language = AppLanguage.english,
    this.hardwareAcceleration = true,
    this.defaultPlayer = PlayerBackend.vlc,
    this.bufferSizeMs = 3000,
    this.parentalPinHash,
    this.incognito = false,
  });

  bool get hasParentalPin => parentalPinHash != null;

  SettingsEntity copyWith({
    AppLanguage? language,
    bool? hardwareAcceleration,
    PlayerBackend? defaultPlayer,
    int? bufferSizeMs,
    String? parentalPinHash,
    bool clearParentalPin = false,
    bool? incognito,
  }) {
    return SettingsEntity(
      language: language ?? this.language,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      defaultPlayer: defaultPlayer ?? this.defaultPlayer,
      bufferSizeMs: bufferSizeMs ?? this.bufferSizeMs,
      parentalPinHash: clearParentalPin ? null : (parentalPinHash ?? this.parentalPinHash),
      incognito: incognito ?? this.incognito,
    );
  }

  @override
  List<Object?> get props =>
      [language, hardwareAcceleration, defaultPlayer, bufferSizeMs, parentalPinHash, incognito];
}
