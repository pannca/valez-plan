import 'dart:async';
import 'package:flutter/material.dart';
import 'services/alarm_service.dart';
import 'services/alarm_sound_service.dart';
import 'services/system_permission_service.dart';
import 'services/theme_service.dart';
import 'services/tolerance_service.dart';
import 'theme/app_colors.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/alarm_ringing_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi service Tema, Alarm, Suara, Toleransi Keterlambatan, dan Izin Sistem
  await ThemeService.instance.init();
  await AlarmService.instance.init();
  await AlarmSoundService.instance.init();
  await ToleranceService.instance.init();
  await SystemPermissionService.instance.checkPermissions();

  runApp(const ValezPlanApp());
}

class ValezPlanApp extends StatefulWidget {
  const ValezPlanApp({super.key});

  @override
  State<ValezPlanApp> createState() => _ValezPlanAppState();
}

class _ValezPlanAppState extends State<ValezPlanApp> {
  StreamSubscription? _ringSubscription;

  @override
  void initState() {
    super.initState();
    // Mendengarkan saat alarm berdering di background/foreground
    _ringSubscription = AlarmService.instance.ringStream.listen((alarmSettings) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'ValezPlan',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Tema Terang (Light Mode)
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.bgLight,
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentLight,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.inkLight,
            ),
            dividerColor: AppColors.borderLight,
            useMaterial3: true,
          ),
          // Tema Gelap (Dark Mode)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.bgDark,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentDark,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.inkDark,
            ),
            dividerColor: AppColors.borderDark,
            useMaterial3: true,
          ),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

