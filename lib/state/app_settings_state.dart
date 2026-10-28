import 'package:flutter/material.dart';

class AppSettingsState extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _unitSystem = 'Métrique (kg, cm)';

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get unitSystem => _unitSystem;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setUnitSystem(String value) {
    _unitSystem = value;
    notifyListeners();
  }
}

