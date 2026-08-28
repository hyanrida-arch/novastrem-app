import '../../../../core/utils/result.dart';
import '../entities/user_login_entity.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates the "log in with an Xtream Codes account" use case.
/// Kept as its own class (rather than calling the repository directly from
/// the provider) so business rules — e.g. trimming input, future MFA steps —
/// have one obvious home.
class LoginWithXtream {
  final AuthRepository repository;

  LoginWithXtream(this.repository);

  Future<Result<UserLoginEntity>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return repository.loginWithXtream(
      serverUrl: serverUrl.trim(),
      username: username.trim(),
      password: password.trim(),
    );
  }
}
