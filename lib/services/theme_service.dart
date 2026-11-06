import 'package:flutter/material.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  // Default mode malam (Dark Mode)
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void setDarkMode(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    setDarkMode(!isDarkMode);
  }
}

