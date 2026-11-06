import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class AlarmRingingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14171A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Alarm Bersih
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E272E),
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  size: 72,
                  color: Color(0xFFFF9F0A),
                ),
              ),
              const SizedBox(height: 28),

              // Judul & Deskripsi Alarm
              Text(
                alarmSettings.notificationSettings.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (alarmSettings.notificationSettings.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  alarmSettings.notificationSettings.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
              const Spacer(),

              // Tombol Matikan Alarm Ala iOS
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF453A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await Alarm.stop(alarmSettings.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Matikan Alarm',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

