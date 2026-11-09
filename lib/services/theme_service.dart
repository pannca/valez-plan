import 'package:flutter/material.dart';
import 'database_service.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  // Default mode malam (Dark Mode)
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> init() async {
    try {
      final saved = await DatabaseService.instance.getSetting('app_theme');
      if (saved != null) {
        if (saved == 'light') {
          themeModeNotifier.value = ThemeMode.light;
        } else if (saved == 'dark') {
          themeModeNotifier.value = ThemeMode.dark;
        }
      }
    } catch (e) {
      debugPrint('Error loading saved theme: $e');
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      await DatabaseService.instance.setSetting(
        'app_theme',
        isDark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }
}

