import 'dart:async';
import 'package:flutter/material.dart';
import 'services/alarm_service.dart';
import 'services/alarm_sound_service.dart';
import 'services/theme_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/alarm_ringing_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi service Alarm & Suara
  await AlarmService.instance.init();
  await AlarmSoundService.instance.init();

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
            scaffoldBackgroundColor: const Color(0xFFF5F6FA),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF388AF6),
              surface: Colors.white,
            ),
            useMaterial3: true,
          ),
          // Tema Gelap (Dark Mode)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF14171A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF388AF6),
              surface: Color(0xFF1E272E),
            ),
            useMaterial3: true,
          ),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

