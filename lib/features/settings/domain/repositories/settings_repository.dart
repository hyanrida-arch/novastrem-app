import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  /// Reads the persisted settings, or defaults if none have been saved yet.
  SettingsEntity getSettings();

  Future<void> setLanguage(AppLanguage language);
  Future<void> setHardwareAcceleration(bool enabled);
  Future<void> setDefaultPlayer(PlayerBackend backend);
  Future<void> setBufferSizeMs(int ms);

  /// Toggles private playback. While on, nothing new is written to Watch
  /// History (existing entries are left alone).
  Future<void> setIncognito(bool enabled);

  /// Hashes and persists [pin] as the new Parental Control PIN.
  Future<void> setParentalPin(String pin);

  /// Constant-time-ish comparison against the stored hash. Returns false
  /// (never throws) when no PIN has been set.
  bool verifyParentalPin(String pin);

  Future<void> clearParentalPin();

  /// Deletes cached images (`flutter_cache_manager`) and the app's temp
  /// directory (`path_provider`). Returns nothing — throws on failure so
  /// the UI can show an error.
  Future<void> clearCache();
}
