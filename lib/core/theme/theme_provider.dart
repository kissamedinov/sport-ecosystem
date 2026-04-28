import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeProvider(this._prefs)
      : _mode = _decode(_prefs.getString(_key)) ?? ThemeMode.system;

  ThemeMode get themeMode => _mode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _prefs.setString(_key, _encode(mode));
    } catch (e, s) {
      debugPrint('ThemeProvider: failed to persist theme mode: $e\n$s');
    }
  }

  static String _encode(ThemeMode m) => m.name;

  static ThemeMode? _decode(String? s) {
    if (s == null) return null;
    for (final m in ThemeMode.values) {
      if (m.name == s) return m;
    }
    return null;
  }
}
