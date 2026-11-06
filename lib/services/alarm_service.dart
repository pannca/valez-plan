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

  // Daftarkan alarm ke sistem OS HP
  Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    String notes = '',
  }) async {
    if (kIsWeb) return;
    // Kalau waktu jadwal sudah lewat, jangan jadwalkan alarm
    if (dateTime.isBefore(DateTime.now())) return;

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

  // Batalkan alarm
  Future<void> cancelAlarm(int id) async {
    if (kIsWeb) return;
    await Alarm.stop(id);
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

