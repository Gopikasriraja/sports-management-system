import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sports_management_system/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads the saved theme mode', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('mrcas_theme_mode', 'dark');

    final provider = ThemeProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('persists theme mode changes', () async {
    final provider = ThemeProvider();
    await provider.setThemeMode(ThemeMode.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('mrcas_theme_mode'), 'light');
    expect(provider.themeMode, ThemeMode.light);
  });
}
