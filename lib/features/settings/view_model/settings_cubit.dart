import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/settings/view_model/setting_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const String _localeKey = 'settings_locale_code';
  static const String _themeKey = 'settings_theme_mode';

  SettingsCubit({
    Locale initialLocale = const Locale('ar'),
    ThemeMode initialThemeMode = ThemeMode.dark,
  }) : super(
    SettingsState(
      locale: initialLocale,
      themeMode: initialThemeMode,
    ),
  );

  static Future<SettingsState> loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedLocale = prefs.getString(_localeKey);
    final Locale locale =
    savedLocale == 'en' ? const Locale('en') : const Locale('ar');

    final String? savedTheme = prefs.getString(_themeKey);
    final ThemeMode themeMode =
    savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    return SettingsState(
      locale: locale,
      themeMode: themeMode,
    );
  }

  Future<void> changeLanguage(String languageCode) async {
    final String normalized = languageCode == 'en' ? 'en' : 'ar';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, normalized);
    emit(state.copyWith(locale: Locale(normalized)));
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleTheme() async {
    final ThemeMode nextMode =
    state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await changeThemeMode(nextMode);
  }
}