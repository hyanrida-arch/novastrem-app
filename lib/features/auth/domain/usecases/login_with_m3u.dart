import '../../../../core/utils/result.dart';
import '../entities/user_login_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithM3u {
  final AuthRepository repository;

  LoginWithM3u(this.repository);

  Future<Result<UserLoginEntity>> call({
    required String m3uUrl,
    required String playlistName,
  }) {
    return repository.loginWithM3u(
      m3uUrl: m3uUrl.trim(),
      playlistName: playlistName.trim(),
    );
  }
}
