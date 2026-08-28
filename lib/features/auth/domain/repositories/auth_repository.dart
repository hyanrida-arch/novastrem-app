import '../../../../core/utils/result.dart';
import '../entities/user_login_entity.dart';

/// Contract the presentation layer codes against. The concrete
/// implementation (in `data/`) is the only place that knows about Dio/Hive.
abstract class AuthRepository {
  Future<Result<UserLoginEntity>> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<Result<UserLoginEntity>> loginWithM3u({
    required String m3uUrl,
    required String playlistName,
  });

  /// Signs in to the built-in, network-free sample catalog ("Try Quick
  /// Demo Account"). Never fails — there's no network call to fail on.
  Future<UserLoginEntity> loginDemo();

  /// Returns the persisted session, if any, without hitting the network.
  UserLoginEntity? getSavedSession();

  Future<void> logout();
}
