import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_login_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_with_m3u.dart';
import '../../domain/usecases/login_with_xtream.dart';

// ---------------------------------------------------------------------------
// Dependency wiring (data sources -> repository -> usecases)
// ---------------------------------------------------------------------------

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(HiveService.sessionBox),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  ),
);

final loginWithXtreamProvider =
    Provider((ref) => LoginWithXtream(ref.watch(authRepositoryProvider)));

final loginWithM3uProvider =
    Provider((ref) => LoginWithM3u(ref.watch(authRepositoryProvider)));

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

enum AuthStatus { idle, loading, success, failure }

class AuthState {
  final AuthStatus status;
  final UserLoginEntity? session;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.idle, this.session, this.errorMessage});

  AuthState copyWith({AuthStatus? status, UserLoginEntity? session, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the login screen and holds the active session once signed in.
class AuthController extends StateNotifier<AuthState> {
  final LoginWithXtream _loginWithXtream;
  final LoginWithM3u _loginWithM3u;
  final AuthRepository _repository;

  AuthController(this._loginWithXtream, this._loginWithM3u, this._repository)
      : super(AuthState(session: _repository.getSavedSession()));

  Future<void> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _loginWithXtream(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    result.when(
      success: (entity) => state = state.copyWith(status: AuthStatus.success, session: entity),
      failure: (f) => state = state.copyWith(status: AuthStatus.failure, errorMessage: f.message),
    );
  }

  Future<void> loginWithM3u({required String m3uUrl, required String playlistName}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _loginWithM3u(m3uUrl: m3uUrl, playlistName: playlistName);
    result.when(
      success: (entity) => state = state.copyWith(status: AuthStatus.success, session: entity),
      failure: (f) => state = state.copyWith(status: AuthStatus.failure, errorMessage: f.message),
    );
  }

  Future<void> loginDemo() async {
    state = state.copyWith(status: AuthStatus.loading);
    final entity = await _repository.loginDemo();
    state = state.copyWith(status: AuthStatus.success, session: entity);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(loginWithXtreamProvider),
    ref.watch(loginWithM3uProvider),
    ref.watch(authRepositoryProvider),
  );
});
