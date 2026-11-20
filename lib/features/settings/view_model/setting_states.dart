import 'package:flutter/material.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;

  const SettingsState({
    required this.locale,
    required this.themeMode,
  });

  bool get isArabic => locale.languageCode == 'ar';
  bool get isDark => themeMode == ThemeMode.dark;

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.locale.languageCode == locale.languageCode &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(locale.languageCode, themeMode);
}