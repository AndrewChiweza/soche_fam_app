import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themeKey = 'isDarkMode';

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme(); // Load the saved theme when provider initializes
  }

  void toggleTheme(bool value) {
    _isDark = value;
    _saveTheme(value);
    notifyListeners();
  }

  // Save the theme mode in SharedPreferences
  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDark);
  }

  // Load the theme mode from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(themeKey) ?? false; // default to light mode
    notifyListeners();
  }
}
