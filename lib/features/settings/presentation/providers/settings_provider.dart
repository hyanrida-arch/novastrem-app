import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_service.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

// ---------------------------------------------------------------------------
// Dependency wiring
// ---------------------------------------------------------------------------

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSourceImpl(HiveService.settingsBox),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Holds the current [SettingsEntity] and exposes one method per preference.
/// Every method persists immediately (no separate "Save" button) — the
/// standard pattern for a mobile settings screen.
class SettingsController extends StateNotifier<SettingsEntity> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(_repository.getSettings());

  Future<void> setLanguage(AppLanguage language) async {
    await _repository.setLanguage(language);
    state = state.copyWith(language: language);
  }

  Future<void> setHardwareAcceleration(bool enabled) async {
    await _repository.setHardwareAcceleration(enabled);
    state = state.copyWith(hardwareAcceleration: enabled);
  }

  Future<void> setDefaultPlayer(PlayerBackend backend) async {
    await _repository.setDefaultPlayer(backend);
    state = state.copyWith(defaultPlayer: backend);
  }

  Future<void> setBufferSizeMs(int ms) async {
    await _repository.setBufferSizeMs(ms);
    state = state.copyWith(bufferSizeMs: ms);
  }

  Future<void> setIncognito(bool enabled) async {
    await _repository.setIncognito(enabled);
    state = state.copyWith(incognito: enabled);
  }

  Future<void> setParentalPin(String pin) async {
    await _repository.setParentalPin(pin);
    // Re-read rather than guess the hash here — keeps the hashing logic
    // solely in the repository.
    state = _repository.getSettings();
  }

  bool verifyParentalPin(String pin) => _repository.verifyParentalPin(pin);

  Future<void> clearParentalPin() async {
    await _repository.clearParentalPin();
    state = state.copyWith(clearParentalPin: true);
  }

  /// Returns nothing on success; throws on failure so the UI can surface it.
  Future<void> clearCache() => _repository.clearCache();
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsEntity>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

/// Convenience provider `app.dart` watches to drive `MaterialApp.locale`.
final appLocaleProvider = Provider<AppLanguage>(
  (ref) => ref.watch(settingsControllerProvider).language,
);
