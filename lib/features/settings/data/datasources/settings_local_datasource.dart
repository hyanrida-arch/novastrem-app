import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/settings_model.dart';

abstract class SettingsLocalDataSource {
  SettingsModel? getSettings();
  Future<void> saveSettings(SettingsModel model);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box<SettingsModel> box;

  SettingsLocalDataSourceImpl(this.box);

  @override
  SettingsModel? getSettings() => box.get(AppConstants.settingsKey);

  @override
  Future<void> saveSettings(SettingsModel model) => box.put(AppConstants.settingsKey, model);
}
