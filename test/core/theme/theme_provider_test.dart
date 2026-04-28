import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to ThemeMode.system when no value persisted', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('decodes a persisted value on construction', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('falls back to system on invalid persisted value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'garbage'});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state, notifies, and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(notified, 1);
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setThemeMode is a no-op if mode unchanged', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setThemeMode(ThemeMode.system);

      expect(notified, 0);
    });
  });
}
