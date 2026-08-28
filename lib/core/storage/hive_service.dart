import 'package:hive_flutter/hive_flutter.dart';

import '../../features/auth/data/models/user_login_model.dart';
import '../../features/settings/data/models/settings_model.dart';
import '../constants/app_constants.dart';

/// Bootstraps Hive once at app startup (`main.dart`) and exposes the boxes
/// used across the app. Keeping this in `core/` (rather than inside any one
/// feature) reflects that storage is a cross-cutting concern — Favorites,
/// Watch History and Downloads all use their own untyped [Box] here rather
/// than a hand-written `TypeAdapter`, since they're simple enough that a
/// custom model class would be pure boilerplate (see each feature's
/// `*_repository_impl.dart` for the encode/decode logic).
class HiveService {
  static late Box<UserLoginModel> sessionBox;
  static late Box<SettingsModel> settingsBox;
  static late Box favoritesBox;
  static late Box historyBox;
  static late Box downloadsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserLoginModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    sessionBox = await Hive.openBox<UserLoginModel>(AppConstants.sessionBoxName);
    settingsBox = await Hive.openBox<SettingsModel>(AppConstants.settingsBoxName);
    favoritesBox = await Hive.openBox(AppConstants.favoritesBoxName);
    historyBox = await Hive.openBox(AppConstants.historyBoxName);
    downloadsBox = await Hive.openBox(AppConstants.downloadsBoxName);
  }
}
