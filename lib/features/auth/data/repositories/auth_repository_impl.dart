import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/url_normalizer.dart';
import '../../domain/entities/user_login_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_login_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  AuthRepositoryImpl({required this.remote, required this.local});

  @override
  Future<Result<UserLoginEntity>> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      final info = await remote.loginWithXtream(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      final userInfo = info.userInfo;
      final expTimestamp = userInfo['exp_date'];
      DateTime? expiryDate;
      if (expTimestamp != null) {
        final seconds = int.tryParse(expTimestamp.toString());
        if (seconds != null) {
          expiryDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }

      final entity = UserLoginEntity(
        type: PlaylistType.xtream,
        playlistName: (userInfo['username'] ?? username).toString(),
        serverUrl: serverUrl,
        username: username,
        password: password,
        status: userInfo['status']?.toString(),
        expiryDate: expiryDate,
        activeConnections: int.tryParse('${userInfo['active_cons'] ?? ''}'),
        maxConnections: int.tryParse('${userInfo['max_connections'] ?? ''}'),
      );

      await local.saveSession(UserLoginModel.fromEntity(entity));
      return Result.success(entity);
    } on XtreamAuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<UserLoginEntity>> loginWithM3u({
    required String m3uUrl,
    required String playlistName,
  }) async {
    try {
      // See XtreamUrlBuilder's normalizeUrl usage: users routinely omit the
      // http(s):// scheme, which otherwise fails at the connection level.
      final normalizedUrl = normalizeUrl(m3uUrl);
      await remote.validateM3uUrl(normalizedUrl);

      final entity = UserLoginEntity(
        type: PlaylistType.m3u,
        playlistName: playlistName.isEmpty ? 'My Playlist' : playlistName,
        m3uUrl: normalizedUrl,
      );

      await local.saveSession(UserLoginModel.fromEntity(entity));
      return Result.success(entity);
    } on XtreamAuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<UserLoginEntity> loginDemo() async {
    const entity = UserLoginEntity(type: PlaylistType.demo, playlistName: 'Quick Demo Account');
    await local.saveSession(UserLoginModel.fromEntity(entity));
    return entity;
  }

  @override
  UserLoginEntity? getSavedSession() => local.getSession()?.toEntity();

  @override
  Future<void> logout() => local.clearSession();
}
