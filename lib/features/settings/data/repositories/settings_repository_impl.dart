import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource local;

  SettingsRepositoryImpl(this.local);

  @override
  SettingsEntity getSettings() => local.getSettings()?.toEntity() ?? const SettingsEntity();

  Future<void> _save(SettingsEntity entity) => local.saveSettings(SettingsModel.fromEntity(entity));

  @override
  Future<void> setLanguage(AppLanguage language) => _save(getSettings().copyWith(language: language));

  @override
  Future<void> setHardwareAcceleration(bool enabled) =>
      _save(getSettings().copyWith(hardwareAcceleration: enabled));

  @override
  Future<void> setDefaultPlayer(PlayerBackend backend) =>
      _save(getSettings().copyWith(defaultPlayer: backend));

  @override
  Future<void> setBufferSizeMs(int ms) => _save(getSettings().copyWith(bufferSizeMs: ms));

  @override
  Future<void> setIncognito(bool enabled) => _save(getSettings().copyWith(incognito: enabled));

  /// SHA-256 is sufficient here — a 4-digit PIN is a low-entropy local
  /// "don't let my kids open this" gate, not an account password. It's
  /// hashed anyway so the raw PIN never sits in plaintext in the Hive file.
  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  @override
  Future<void> setParentalPin(String pin) => _save(getSettings().copyWith(parentalPinHash: _hashPin(pin)));

  @override
  bool verifyParentalPin(String pin) {
    final stored = getSettings().parentalPinHash;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  @override
  Future<void> clearParentalPin() => _save(getSettings().copyWith(clearParentalPin: true));

  @override
  Future<void> clearCache() async {
    // Cached poster/logo/backdrop images (cached_network_image's backing store).
    await DefaultCacheManager().emptyCache();

    // Any scratch files NovaStream itself writes to the OS temp directory.
    final tempDir = await getTemporaryDirectory();
    await _clearDirectoryContents(tempDir);
  }

  Future<void> _clearDirectoryContents(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Best-effort: skip anything locked/in-use rather than fail the
        // whole operation over one file.
      }
    }
  }
}
