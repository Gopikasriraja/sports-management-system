import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _preferenceKey = 'mrcas_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _hasExplicitSelection = false;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadSavedThemeMode();
  }

  Future<void> _loadSavedThemeMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_hasExplicitSelection) return;
      final savedMode = preferences.getString(_preferenceKey);
      _themeMode = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Could not load saved theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_preferenceKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    if (!saved) {
      throw StateError('The theme preference could not be saved.');
    }
    _hasExplicitSelection = true;
    _themeMode = mode;
    notifyListeners();
  }
}
