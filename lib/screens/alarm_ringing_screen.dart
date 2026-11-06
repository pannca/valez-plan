import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class AlarmRingingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    final isEarlyReminder = alarmSettings.id >= 100000;
    final accentColor = isEarlyReminder ? const Color(0xFF388AF6) : const Color(0xFFFF9F0A);
    final buttonColor = isEarlyReminder ? const Color(0xFF388AF6) : const Color(0xFFFF453A);

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
              // Icon Header (Hourglass untuk pengingat awal, Alarm untuk alarm utama)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarlyReminder
                      ? const Color(0xFF388AF6).withValues(alpha: 0.15)
                      : const Color(0xFF1E272E),
                ),
                child: Icon(
                  isEarlyReminder ? Icons.hourglass_top_rounded : Icons.alarm_rounded,
                  size: 72,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 28),

              // Badge Tipe Pengingat
              if (isEarlyReminder)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388AF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENGINGAT PERSIAPAN',
                    style: TextStyle(
                      color: Color(0xFF388AF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

              // Judul & Deskripsi Alarm
              Text(
                alarmSettings.notificationSettings.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (alarmSettings.notificationSettings.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  alarmSettings.notificationSettings.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
              const Spacer(),

              // Tombol Konfirmasi / Matikan Alarm
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await Alarm.stop(alarmSettings.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    isEarlyReminder ? 'Siap, Mengerti!' : 'Matikan Alarm',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

