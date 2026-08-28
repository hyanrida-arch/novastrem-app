// Basic smoke test: NovaStream should boot to the login screen when no
// session has been restored, and show the brand wordmark + login button.
//
// `AuthRepository` and `SettingsRepository` are both overridden with
// in-memory fakes so the test never touches Hive (which needs platform
// channels normally set up in `main()`) — this is the same seam you'd use
// to unit-test any screen that depends on the auth session or settings.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novastream/app.dart';
import 'package:novastream/core/constants/app_strings.dart';
import 'package:novastream/core/utils/result.dart';
import 'package:novastream/features/auth/domain/entities/user_login_entity.dart';
import 'package:novastream/features/auth/domain/repositories/auth_repository.dart';
import 'package:novastream/features/auth/presentation/providers/auth_provider.dart';
import 'package:novastream/features/settings/domain/entities/settings_entity.dart';
import 'package:novastream/features/settings/domain/repositories/settings_repository.dart';
import 'package:novastream/features/settings/presentation/providers/settings_provider.dart';

class _FakeSettingsRepository implements SettingsRepository {
  SettingsEntity _settings = const SettingsEntity();

  @override
  SettingsEntity getSettings() => _settings;

  @override
  Future<void> setLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(language: language);
  }

  @override
  Future<void> setHardwareAcceleration(bool enabled) async {
    _settings = _settings.copyWith(hardwareAcceleration: enabled);
  }

  @override
  Future<void> setDefaultPlayer(PlayerBackend backend) async {
    _settings = _settings.copyWith(defaultPlayer: backend);
  }

  @override
  Future<void> setBufferSizeMs(int ms) async {
    _settings = _settings.copyWith(bufferSizeMs: ms);
  }

  @override
  Future<void> setIncognito(bool enabled) async {
    _settings = _settings.copyWith(incognito: enabled);
  }

  @override
  Future<void> setParentalPin(String pin) async {
    _settings = _settings.copyWith(parentalPinHash: pin);
  }

  @override
  bool verifyParentalPin(String pin) => _settings.parentalPinHash == pin;

  @override
  Future<void> clearParentalPin() async {
    _settings = _settings.copyWith(clearParentalPin: true);
  }

  @override
  Future<void> clearCache() async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  UserLoginEntity? getSavedSession() => null;

  @override
  Future<void> logout() async {}

  @override
  Future<UserLoginEntity> loginDemo() async =>
      const UserLoginEntity(type: PlaylistType.demo, playlistName: 'Quick Demo Account');

  @override
  Future<Result<UserLoginEntity>> loginWithM3u({
    required String m3uUrl,
    required String playlistName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<UserLoginEntity>> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('shows the login screen with the NovaStream brand', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        ],
        child: const NovaStreamApp(),
      ),
    );
    await tester.pump();

    // The hero logo shows the tagline only (no "NovaStream" wordmark text) —

    expect(find.text(AppStrings.appTagline), findsWidgets);
    expect(find.text(AppStrings.buttonConnectXtream), findsWidgets);
  });
}
