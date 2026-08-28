import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/user_login_model.dart';

/// Persists the "currently signed in" session so NovaStream can skip the
/// login screen on next launch (classic IPTV-app auto-login behaviour).
abstract class AuthLocalDataSource {
  Future<void> saveSession(UserLoginModel model);
  UserLoginModel? getSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<UserLoginModel> box;

  AuthLocalDataSourceImpl(this.box);

  @override
  Future<void> saveSession(UserLoginModel model) => box.put(AppConstants.sessionKey, model);

  @override
  UserLoginModel? getSession() => box.get(AppConstants.sessionKey);

  @override
  Future<void> clearSession() => box.delete(AppConstants.sessionKey);
}
