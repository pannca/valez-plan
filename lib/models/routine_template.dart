import 'package:flutter/material.dart';

class RoutineItem {
  final String title;
  final int hour;
  final int minute;
  final String category; // 'Kerja', 'Belajar', 'Ibadah', 'Istirahat', 'Santai', 'Umum'
  final String notes;
  final bool isAlarmEnabled;

  const RoutineItem({
    required this.title,
    required this.hour,
    required this.minute,
    this.category = 'Umum',
    this.notes = '',
    this.isAlarmEnabled = true,
  });

  String get timeFormatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class RoutineTemplate {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<RoutineItem> items;

  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.items,
  });

  static List<RoutineTemplate> get defaultTemplates => [
        const RoutineTemplate(
          id: 'workday',
          title: 'Hari Kerja Produktif',
          subtitle: 'Struktur ritme kerja profesional, meeting, dan deep work',
          icon: Icons.work_outline_rounded,
          accentColor: Color(0xFF388AF6),
          items: [
            RoutineItem(
              title: 'Bangun Pagi & Olahraga Ringan',
              hour: 6,
              minute: 30,
              category: 'Istirahat',
              notes: 'Stretching 15 menit & sarapan berenergi',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Persiapan & Cek Prioritas Hari Ini',
              hour: 8,
              minute: 0,
              category: 'Kerja',
              notes: 'Cek email, chat tim, dan rapikan to-do list',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Deep Work: Selesaikan Task Terpenting',
              hour: 9,
              minute: 0,
              category: 'Kerja',
              notes: 'Fokus tanpa distraksi media sosial',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Makan Siang & Istirahat (Ishoma)',
              hour: 12,
              minute: 0,
              category: 'Istirahat',
              notes: 'Istirahatkan mata dan recharge energi',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Eksekusi Proyek & Sesi Kolaborasi',
              hour: 13,
              minute: 30,
              category: 'Kerja',
              notes: 'Meeting, review kerjaan, atau follow-up klien',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Evaluasi & Wrap Up Kerjaan',
              hour: 17,
              minute: 0,
              category: 'Kerja',
              notes: 'Tutup laptop, rekap pencapaian hari ini',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Santai & Quality Time Keluarga/Hobi',
              hour: 19,
              minute: 30,
              category: 'Santai',
              notes: 'Nonton, ngobrol, atau main game santai',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Waktunya Tidur & Regenerasi Tubuh',
              hour: 22,
              minute: 30,
              category: 'Istirahat',
              notes: 'Matikan lampu dan siapkan tidur nyenyak',
              isAlarmEnabled: true,
            ),
          ],
        ),
        const RoutineTemplate(
          id: 'study',
          title: 'Fokus Belajar & Riset',
          subtitle: 'Cocok buat kuliah, skripsi, sertifikasi, atau belajar skill baru',
          icon: Icons.auto_stories_rounded,
          accentColor: Color(0xFFA259FF),
          items: [
            RoutineItem(
              title: 'Review Catatan & Roadmap Belajar',
              hour: 8,
              minute: 0,
              category: 'Belajar',
              notes: 'Tentukan bab atau materi yang mau dipelajari hari ini',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Sesi Belajar 1: Pemahaman Teori & Konsep',
              hour: 9,
              minute: 30,
              category: 'Belajar',
              notes: 'Baca referensi buku/dokumentasi dan catat poin utama',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Istirahat Makan Siang',
              hour: 12,
              minute: 0,
              category: 'Istirahat',
              notes: 'Makan bergizi dan hidrasi tubuh',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Sesi Belajar 2: Latihan Praktek / Coding',
              hour: 13,
              minute: 30,
              category: 'Belajar',
              notes: 'Praktikkan langsung konsep yang dipelajari ke studi kasus',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Coffee Break & Brain Refresh',
              hour: 16,
              minute: 0,
              category: 'Istirahat',
              notes: 'Jalan-jalan sebentar hirup udara segar',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Sesi Belajar 3: Review & Summary',
              hour: 19,
              minute: 30,
              category: 'Belajar',
              notes: 'Tulis ringkasan dari apa yang sudah dipahami',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Istirahat Malam',
              hour: 22,
              minute: 0,
              category: 'Istirahat',
              notes: 'Tidur cukup agar memori otak terkonsolidasi',
              isAlarmEnabled: true,
            ),
          ],
        ),
        const RoutineTemplate(
          id: 'weekend',
          title: 'Akhir Pekan & Refresh Pikiran',
          subtitle: 'Seimbangkan istirahat, hobi, dan me-time tanpa rasa bersalah',
          icon: Icons.weekend_rounded,
          accentColor: Color(0xFF1DD1A1),
          items: [
            RoutineItem(
              title: 'Bangun Santai & Ngopi Pagi',
              hour: 8,
              minute: 0,
              category: 'Santai',
              notes: 'Nikmati pagi tanpa buru-buru alarm kerja',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Beberes Kamar & Bersih-bersih',
              hour: 9,
              minute: 30,
              category: 'Umum',
              notes: 'Rapikan meja kerja, cuci baju, dan buka jendela',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Kulineran / Masak Makanan Enak',
              hour: 12,
              minute: 30,
              category: 'Santai',
              notes: 'Makan makanan favorit bersama teman/keluarga',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Olahraga Sore / Jogging / Gowes',
              hour: 16,
              minute: 30,
              category: 'Istirahat',
              notes: 'Keluarkan keringat agar badan segar kembali',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Me-Time: Nonton Film / Gaming',
              hour: 19,
              minute: 0,
              category: 'Santai',
              notes: 'Relaksasi total menikmati hiburan',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Tidur Malam Nyenyak',
              hour: 23,
              minute: 0,
              category: 'Istirahat',
              notes: 'Persiapkan energi untuk minggu yang luar biasa',
              isAlarmEnabled: true,
            ),
          ],
        ),
        const RoutineTemplate(
          id: 'deadline_sprint',
          title: 'Mode Sprint Deadline',
          subtitle: 'Jadwal intensif fokus tinggi untuk mengejar target mepet',
          icon: Icons.bolt_rounded,
          accentColor: Color(0xFFFF9F43),
          items: [
            RoutineItem(
              title: 'Persiapan & Kafein Pagi',
              hour: 7,
              minute: 30,
              category: 'Istirahat',
              notes: 'Minum air putih, sarapan ringan, dan siapkan kopi',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Sprint 1: Hajar Bagian Paling Rumit',
              hour: 8,
              minute: 30,
              category: 'Kerja',
              notes: 'Blokir semua notifikasi sosmed',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Power Rest 20 Menit',
              hour: 11,
              minute: 40,
              category: 'Istirahat',
              notes: 'Pejamkan mata sejenak untuk reset otak',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Sprint 2: Selesaikan Fitur & Integrasi',
              hour: 13,
              minute: 0,
              category: 'Kerja',
              notes: 'Tuntaskan deliverable yang harus disubmit',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Final Testing & Quality Check',
              hour: 16,
              minute: 30,
              category: 'Kerja',
              notes: 'Cek ulang semua requirements',
              isAlarmEnabled: false,
            ),
            RoutineItem(
              title: 'Submit / Serah Terima Hasil Kerja',
              hour: 18,
              minute: 0,
              category: 'Kerja',
              notes: 'Kirim laporan/deliverable tepat waktu',
              isAlarmEnabled: true,
            ),
            RoutineItem(
              title: 'Perayaan Selesai & Relax',
              hour: 19,
              minute: 0,
              category: 'Santai',
              notes: 'Apresiasi diri sendiri sudah berjuang maksimal!',
              isAlarmEnabled: false,
            ),
          ],
        ),
      ];
}

