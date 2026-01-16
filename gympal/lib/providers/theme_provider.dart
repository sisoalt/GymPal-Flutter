import 'package:flutter/material.dart';
import '../data/services/hive_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'isDarkMode';

  bool _isDark = false;

  ThemeProvider() {
    final box = HiveService.settingsBox;
    _isDark = box.get(_key, defaultValue: false) as bool;
  }

  bool get isDark => _isDark;

  Future<void> setDark(bool value) async {
    _isDark = value;
    final box = HiveService.settingsBox;
    await box.put(_key, _isDark);
    notifyListeners();
  }
}
