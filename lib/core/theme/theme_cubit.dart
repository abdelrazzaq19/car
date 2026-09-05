import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's light / dark / system preference and persists it.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_read(_prefs));

  static ThemeMode _read(SharedPreferences prefs) {
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_key, mode.name);
  }

  /// Cycles system -> light -> dark -> system, for a single toolbar button.
  Future<void> toggle() {
    return set(switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  IconData get icon => switch (state) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  String get label => switch (state) {
        ThemeMode.system => 'Theme: follows system',
        ThemeMode.light => 'Theme: light',
        ThemeMode.dark => 'Theme: dark',
      };
}
