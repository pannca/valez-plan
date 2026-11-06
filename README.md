# 📅 ValezPlan

**ValezPlan** adalah aplikasi *Personal Daily Planner & Alarm Weker* yang dirancang dengan gaya **Structured Vertical Timeline** dan didukung penyimpanan lokal **SQLite** offline-first.

---

## ✨ Fitur Utama

- 🕒 **Structured Vertical Timeline:** Garis waktu vertikal menghubungkan seluruh kegiatan harian dengan indikator jam sekarang (*live indicator*) dan jeda waktu luang (*free time gap*).
- ⏰ **Reliable Alarm Weker:** Notifikasi alarm berdering kencang yang terintegrasi langsung dengan sistem OS Android (`AlarmManager`).
- 📜 **Riwayat Kegiatan (History):** Rekap agenda kegiatan kemarin, minggu lalu, dan hari-hari sebelumnya lengkap dengan statistik kedisiplinan.
- 🌓 **Mode Siang & Mode Malam:** Pengaturan tema gelap (Dark Mode) dan tema terang (Light Mode) yang dapat diganti secara instan di tab Pengaturan.
- 📱 **Offline-First & Cepat:** Semua data tersimpan aman di memori HP menggunakan SQLite lokal (`valezplan.db`) tanpa butuh koneksi internet.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **Database:** SQLite (`sqflite`)
- **Alarm Engine:** `alarm` (Android native `AlarmManager` & Full Screen Intent)
- **Date & Time:** `intl`

---

## 🚀 Cara Menjalankan

1. Clone repositori ini:
   ```bash
   git clone https://github.com/pannca/valez-plan.git
   cd valez-plan
   ```
2. Ambil dependensi:
   ```bash
   flutter pub get
   ```
3. Colok perangkat Android atau buka emulator, lalu jalankan:
   ```bash
   flutter run
   ```

---

## 📦 Build APK

Untuk membuat file APK rilis:
```bash
flutter build apk --release
```
File APK akan berada di: `build/app/outputs/flutter-apk/app-release.apk`
