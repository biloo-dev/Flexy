import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  SettingsModel _djezzySettings = SettingsModel(typeOperator: 1, comPort: 'COM3');
  SettingsModel _mobilisSettings = SettingsModel(typeOperator: 2, comPort: 'COM4');
  SettingsModel _ooredooSettings = SettingsModel(typeOperator: 3, comPort: 'COM5');

  bool _isLoading = false;

  SettingsModel get djezzySettings => _djezzySettings;
  SettingsModel get mobilisSettings => _mobilisSettings;
  SettingsModel get ooredooSettings => _ooredooSettings;
  bool get isLoading => _isLoading;

  SettingsModel getSettingsByOperator(int op) {
    if (op == 1) return _djezzySettings;
    if (op == 2) return _mobilisSettings;
    return _ooredooSettings;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final settingsList = await DatabaseHelper.instance.getAllSettings();
    for (var s in settingsList) {
      if (s.typeOperator == 1) _djezzySettings = s;
      if (s.typeOperator == 2) _mobilisSettings = s;
      if (s.typeOperator == 3) _ooredooSettings = s;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSettings(SettingsModel settings) async {
    await DatabaseHelper.instance.updateSettings(settings);
    await loadSettings();
  }
}
