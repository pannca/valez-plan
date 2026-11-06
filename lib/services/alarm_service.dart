import 'package:flutter/foundation.dart';
import 'package:alarm/alarm.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._init();
  AlarmService._init();

  // Inisialisasi engine alarm
  Future<void> init() async {
    if (kIsWeb) return;
    await Alarm.init();
  }

  // Daftarkan alarm ke sistem OS HP (lengkap dengan opsi Pengingat Awal)
  Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    String notes = '',
    int earlyReminderMinutes = 0,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();

    // 1. Jadwalkan Pengingat Awal (Early Reminder) jika diaktifkan (> 0 menit)
    if (earlyReminderMinutes > 0) {
      final earlyTime = dateTime.subtract(Duration(minutes: earlyReminderMinutes));
      if (earlyTime.isAfter(now)) {
        final earlyAlarmId = id + 100000;
        final earlySettings = AlarmSettings(
          id: earlyAlarmId,
          dateTime: earlyTime,
          assetAudioPath: 'assets/sounds/alarm.mp3',
          loopAudio: false,
          vibrate: true,
          volume: 0.6,
          fadeDuration: 1.0,
          notificationSettings: NotificationSettings(
            title: '⏳ $earlyReminderMinutes Menit Lagi: $title',
            body: 'Jadwal dimulai pukul ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}. Siapkan dirimu!',
            stopButton: 'Mengerti',
          ),
        );
        await Alarm.set(alarmSettings: earlySettings);
      }
    }

    // 2. Jadwalkan Alarm Utama Tepat Waktu
    if (dateTime.isAfter(now)) {
      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: dateTime,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        volume: 1.0,
        fadeDuration: 2.0,
        notificationSettings: NotificationSettings(
          title: '⏰ ValezPlan: $title',
          body: notes.isNotEmpty ? notes : 'Waktunya menjalankan jadwal kamu!',
          stopButton: 'Matikan Alarm',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    }
  }

  // Batalkan alarm utama dan pengingat awal
  Future<void> cancelAlarm(int id) async {
    if (kIsWeb) return;
    await Alarm.stop(id);
    await Alarm.stop(id + 100000);
  }

  // Cek apakah alarm dengan ID tertentu sedang berdering
  Future<bool> isRinging(int id) async {
    if (kIsWeb) return false;
    return await Alarm.isRinging(id);
  }

  // Stream untuk mendeteksi kapan alarm berdering
  Stream<AlarmSettings> get ringStream =>
      kIsWeb ? const Stream.empty() : Alarm.ringStream.stream;
}

