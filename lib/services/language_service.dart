import 'dart:ui';
import 'package:flutter/material.dart';
import 'database_service.dart';

/// Service tunggal untuk mengelola bahasa aplikasi (Bilingual: ID & EN).
/// Mendukung opsi 'system' (default), 'id', dan 'en' dengan persistensi SQLite.
class LanguageService {
  static final LanguageService instance = LanguageService._init();
  LanguageService._init();

  String _currentPreference = 'system';
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('id');

  String get currentPreference => _currentPreference;
  String get effectiveLanguage => languageNotifier.value;
  bool get isEnglish => languageNotifier.value == 'en';

  String _resolveSystemLanguage() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final code = systemLocale.languageCode.toLowerCase();
    if (code.startsWith('id')) {
      return 'id';
    }
    return 'en';
  }

  Future<void> init() async {
    try {
      final saved = await DatabaseService.instance.getSetting('app_language');
      if (saved != null && (saved == 'id' || saved == 'en' || saved == 'system')) {
        _currentPreference = saved;
      } else {
        _currentPreference = 'system';
      }

      if (_currentPreference == 'system') {
        languageNotifier.value = _resolveSystemLanguage();
      } else {
        languageNotifier.value = _currentPreference;
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      languageNotifier.value = _resolveSystemLanguage();
    }
  }

  Future<void> setLanguage(String preference) async {
    _currentPreference = preference;
    if (preference == 'system') {
      languageNotifier.value = _resolveSystemLanguage();
    } else {
      languageNotifier.value = preference;
    }

    try {
      await DatabaseService.instance.setSetting('app_language', preference);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  String get preferenceLabel {
    if (_currentPreference == 'system') {
      return isEnglish ? 'System Default (English)' : 'Ikuti Sistem (Indonesia)';
    } else if (_currentPreference == 'id') {
      return 'Bahasa Indonesia';
    } else {
      return 'English';
    }
  }
}

/// Pusat teks kamus antarmuka bilingual (Indonesian & English).
class AppStrings {
  AppStrings._();

  static bool get isEn => LanguageService.instance.isEnglish;

  // Navigasi Utama
  static String get navTimeline => 'Timeline';
  static String get navHistory => isEn ? 'History' : 'Riwayat';
  static String get navSettings => isEn ? 'Settings' : 'Pengaturan';

  // Timeline & Beranda
  static String get timelineTitle => 'Timeline';
  static String get newPlan => isEn ? 'New Plan' : 'Jadwal Baru';
  static String get now => isEn ? 'NOW' : 'SEKARANG';
  static String get noPlansYet =>
      isEn ? 'No plans for this date' : 'Belum ada jadwal di tanggal ini';
  static String get noPlansSubtitle => isEn
      ? 'Tap the button below to add a new plan.'
      : 'Ketuk tombol di bawah untuk menambah jadwal baru.';
  static String get completed => isEn ? 'COMPLETED' : 'SELESAI';
  static String get overdue => isEn ? 'OVERDUE' : 'TERLEWAT';
  static String get edit => isEn ? 'Edit' : 'Edit';

  // Relative Time & Notifikasi
  static String minLeft(int min) => isEn ? '${min}m left' : '$min mnt lagi';
  static String hoursLeft(int hours, [int mins = 0]) => isEn
      ? (mins > 0 ? '${hours}h ${mins}m left' : '${hours}h left')
      : (mins > 0 ? '$hours jam $mins mnt lagi' : '$hours jam lagi');
  static String daysLeft(int days) =>
      isEn ? '$days days left' : '$days hari lagi';
  static String get shortly => isEn ? 'shortly' : 'sebentar lagi';
  static String get planCompletedLocked => isEn
      ? 'This plan is already completed and locked.'
      : 'Jadwal sudah selesai dan terkunci.';
  static String get planOverdueLocked => isEn
      ? 'This plan is overdue and locked.'
      : 'Jadwal telah terlewat dan terkunci.';
  static String planMarkedComplete(String title) => isEn
      ? 'Plan "$title" marked as completed.'
      : 'Jadwal "$title" berhasil diselesaikan.';

  // Validasi Selesaikan Lebih Awal
  static String get completeEarlyTitle =>
      isEn ? 'Complete Early?' : 'Selesaikan Lebih Awal?';
  static String completeEarlySubtitle(String remaining) => isEn
      ? 'This plan is not due yet ($remaining)'
      : 'Waktu jadwal ini belum tiba ($remaining)';
  static String get completeEarlyNoticeAlarm => isEn
      ? 'Once checked, this plan will be permanently locked and the alarm will be automatically disabled.'
      : 'Setelah diceklis, jadwal akan terkunci permanen dan alarm akan otomatis dinonaktifkan.';
  static String get completeEarlyNoticeNoAlarm => isEn
      ? 'Once checked, this plan will be permanently locked.'
      : 'Setelah diceklis, jadwal akan terkunci permanen.';
  static String get yesCompleteNow =>
      isEn ? 'Yes, Complete Now' : 'Ya, Selesaikan Sekarang';
  static String get cancel => isEn ? 'Cancel' : 'Batal';

  // Modal Tambah & Edit Jadwal (AddPlanSheet)
  static String get newPlanHeader => isEn ? 'New Plan' : 'Jadwal Baru';
  static String get editPlanHeader => isEn ? 'Edit Plan' : 'Edit Jadwal';
  static String get activityNameHint =>
      isEn ? 'Activity name' : 'Nama kegiatan';
  static String get notesHint =>
      isEn ? 'Notes (optional)' : 'Catatan (opsional)';
  static String get today => isEn ? 'Today' : 'Hari Ini';
  static String get pastTimeWarning => isEn
      ? 'Selected time has already passed'
      : 'Jam yang dipilih sudah lewat';
  static String get earlyReminder =>
      isEn ? 'Early Reminder' : 'Pengingat Awal';
  static String get onTime => isEn ? 'On time' : 'Tepat waktu';
  static String minBefore(int min) =>
      isEn ? '$min min before' : '$min mnt sebelum';
  static String get category => isEn ? 'CATEGORY' : 'KATEGORI';
  static String get repetition => isEn ? 'REPETITION' : 'PENGULANGAN';
  static String get once => isEn ? 'Once' : 'Sekali';
  static String get everyDay => isEn ? 'Every Day' : 'Tiap Hari';
  static String everyDayName(String day) =>
      isEn ? 'Every $day' : 'Tiap $day';
  static String get custom => isEn ? 'Custom' : 'Kustom';
  static String get repeatDuration =>
      isEn ? 'REPEAT DURATION' : 'DURASI PENGULANGAN';
  static String get forever => isEn ? 'Forever' : 'Selamanya';
  static String get twoWeeks => isEn ? '2 Weeks' : '2 Minggu';
  static String get oneMonth => isEn ? '1 Month' : '1 Bulan';
  static String get threeMonths => isEn ? '3 Months' : '3 Bulan';
  static String untilDate(String date) =>
      isEn ? 'until $date' : 's/d $date';
  static String get save => isEn ? 'Save' : 'Simpan';

  // Conflict Sheet
  static String get conflictTitle =>
      isEn ? 'Schedule Time Conflict' : 'Jadwal Waktu Bersamaan';
  static String get conflictSubtitle => isEn
      ? 'Another plan is scheduled at the exact same time'
      : 'Ada agenda lain di jam yang persis sama';
  static String shift15(String time) =>
      isEn ? 'Shift to $time (+15 Minutes)' : 'Geser ke $time (+15 Menit)';
  static String keepSameTime(String time) =>
      isEn ? 'Keep at $time anyway' : 'Tetap Simpan di $time';
  static String get changeTimeManually =>
      isEn ? 'Change Time Manually' : 'Ubah Jam Manual';

  // Layar Pengaturan (SettingsScreen)
  static String get settingsHeader => isEn ? 'Settings' : 'Pengaturan';
  static String get appearanceSection => isEn ? 'APPEARANCE' : 'TAMPILAN';
  static String get darkMode => isEn ? 'Dark Mode' : 'Mode Gelap';
  static String get lightMode => isEn ? 'Light Mode' : 'Mode Terang';
  static String get darkThemeActive =>
      isEn ? 'Dark theme active' : 'Tema gelap aktif';
  static String get lightThemeActive =>
      isEn ? 'Light theme active' : 'Tema terang aktif';

  static String get languageSection => isEn ? 'LANGUAGE' : 'BAHASA';
  static String get appLanguage => isEn ? 'App Language' : 'Bahasa Aplikasi';
  static String get selectLanguage =>
      isEn ? 'Select Language' : 'Pilih Bahasa';
  static String get selectLanguageDesc => isEn
      ? 'Choose app interface language'
      : 'Pilih bahasa pengantar antarmuka aplikasi';
  static String get systemDefault =>
      isEn ? 'System Default' : 'Ikuti Sistem HP';
  static String get systemDefaultDesc => isEn
      ? 'Automatically match device language'
      : 'Otomatis mengikuti pengaturan bahasa HP';
  static String get indonesian => 'Bahasa Indonesia';
  static String get indonesianDesc => 'Bahasa Indonesia (ID)';
  static String get english => 'English';
  static String get englishDesc => 'English (US/UK)';

  static String get timeDiscipline =>
      isEn ? 'TIME DISCIPLINE' : 'DISIPLIN WAKTU';
  static String get latenessTolerance =>
      isEn ? 'Lateness Tolerance' : 'Toleransi Keterlambatan';
  static String get toleranceSubtitle => isEn
      ? 'Time window before a plan is locked as overdue'
      : 'Batas waktu sebelum jadwal dikunci terlewat';
  static String get endOfDay => isEn ? 'End of day' : 'Akhir hari';

  static String get alarmRingtone =>
      isEn ? 'ALARM RINGTONE' : 'NADA DERING ALARM';
  static String get audioPreview => isEn ? 'Audio Preview' : 'Pratinjau Suara';

  static String get systemPermissions =>
      isEn ? 'SYSTEM PERMISSIONS' : 'IZIN SISTEM';
  static String get managePermissions => isEn
      ? 'Manage Permissions & Notifications'
      : 'Kelola Izin & Notifikasi';
  static String get permissionsSubtitle => isEn
      ? 'Alarm, exact timing, notifications, & battery'
      : 'Alarm, jadwal presisi, notifikasi, & optimasi baterai';

  static String get aboutApp => isEn ? 'ABOUT APP' : 'TENTANG APLIKASI';
  static String get version => isEn ? 'Version' : 'Versi';

  // Layar Riwayat (HistoryScreen)
  static String get historyHeader => isEn ? 'Plan History' : 'Riwayat Jadwal';
  static String get historySubtitle =>
      isEn ? 'All recorded activities' : 'Semua aktivitas yang telah tercatat';
  static String get all => isEn ? 'All' : 'Semua';
  static String get noHistoryYet =>
      isEn ? 'No history yet' : 'Belum ada riwayat';
  static String get noHistorySubtitle => isEn
      ? 'Completed and overdue plans will be recorded here.'
      : 'Jadwal yang telah selesai atau terlewat akan tercatat di sini.';
  static String get clearHistory =>
      isEn ? 'Clear History' : 'Hapus Riwayat';
  static String get deleteHistoryConfirmTitle =>
      isEn ? 'Delete History?' : 'Hapus Riwayat?';
  static String deleteHistoryItemConfirm(String title) =>
      isEn ? 'Delete "$title" from history?' : 'Hapus "$title" dari riwayat?';
  static String get delete => isEn ? 'Delete' : 'Hapus';
  static String get itemDeletedFromHistory =>
      isEn ? 'Item has been removed from history.' : 'Agenda telah dihapus dari riwayat.';
  static String get manageHistory => isEn ? 'Manage History' : 'Kelola Riwayat';
  static String get deleteCompletedHistory =>
      isEn ? 'Delete Completed History' : 'Hapus Riwayat Selesai';
  static String get deleteCompletedSubtitle =>
      isEn ? 'Clear activities that have been completed' : 'Bersihkan agenda yang telah selesai';
  static String get deleteAllHistory =>
      isEn ? 'Delete All History' : 'Hapus Semua Riwayat';
  static String get futurePlansSafe =>
      isEn ? 'Future schedules remain safe' : 'Jadwal masa depan tetap aman';
  static String get deleteCompletedConfirmTitle =>
      isEn ? 'Delete Completed History?' : 'Hapus Riwayat Selesai?';
  static String get deleteCompletedConfirmMsg =>
      isEn ? 'Completed activities will be cleared from history.' : 'Agenda selesai akan dibersihkan dari riwayat.';
  static String get deleteAllConfirmTitle =>
      isEn ? 'Delete All History?' : 'Hapus Seluruh Riwayat?';
  static String get deleteAllConfirmMsg =>
      isEn ? 'All past history will be permanently deleted.' : 'Semua riwayat lampau akan dihapus permanen.';
  static String get deleteAllWarningQuestion => isEn
      ? 'Are you sure you want to delete all activity history? This action is permanent and cannot be undone.'
      : 'Apakah Anda yakin ingin menghapus seluruh riwayat aktivitas? Tindakan ini permanen dan tidak dapat dibatalkan.';
  static String get deleteStatsImpact => isEn
      ? 'Compliance bar and category statistics will be reset (empty).'
      : 'Bar kepatuhan dan grafik statistik kategori akan kosong / di-reset.';
  static String get deleteListImpact => isEn
      ? 'All past completed and overdue agenda lists will be removed.'
      : 'Seluruh daftar agenda lampau yang selesai atau terlewat akan dihapus.';
  static String get deleteFutureSafeNotice => isEn
      ? 'Today\'s active tasks and future schedules remain safe.'
      : 'Jadwal hari ini yang masih aktif dan jadwal masa depan tetap aman.';
  static String get yesDelete => isEn ? 'Yes, Delete' : 'Ya, Hapus';

  // Filter Tanggal Riwayat
  static String get filterDate => isEn ? 'Date' : 'Tanggal';
  static String get filterAllTime => isEn ? 'All Time' : 'Semua Waktu';
  static String get filterToday => isEn ? 'Today' : 'Hari Ini';
  static String get filter7Days => isEn ? 'Last 7 Days' : '7 Hari Terakhir';
  static String get filter30Days => isEn ? 'Last 30 Days' : '30 Hari Terakhir';
  static String get filterThisMonth => isEn ? 'This Month' : 'Bulan Ini';
  static String get filterCustomRange =>
      isEn ? 'Custom Date Range' : 'Pilih Rentang Tanggal';
  static String get filterDateHeader =>
      isEn ? 'Filter by Date' : 'Filter Tanggal';
  static String get resetFilter => isEn ? 'Reset' : 'Reset';
  static String get noMatchingHistory =>
      isEn ? 'No matching history' : 'Tidak ada riwayat yang cocok';

  // Layar Alarm Berdering (AlarmRingingScreen)
  static String get timeForPlan =>
      isEn ? 'TIME FOR PLAN' : 'WAKTUNYA JADWAL';
  static String get stopAlarm => isEn ? 'Stop Alarm' : 'Hentikan Alarm';
  static String autoOffIn(int sec) =>
      isEn ? 'Auto-off in ${sec}s' : 'Alarm Otomatis Mati dalam ${sec}d';

  // Nama Hari Lengkap
  static String dayFull(int weekday) {
    if (isEn) {
      const days = {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      };
      return days[weekday] ?? 'Day';
    } else {
      const days = {
        1: 'Senin',
        2: 'Selasa',
        3: 'Rabu',
        4: 'Kamis',
        5: 'Jumat',
        6: 'Sabtu',
        7: 'Minggu',
      };
      return days[weekday] ?? 'Hari';
    }
  }

  // Nama Hari Pendek
  static String dayShort(int weekday) {
    if (isEn) {
      const days = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun',
      };
      return days[weekday] ?? 'Day';
    } else {
      const days = {
        1: 'Sen',
        2: 'Sel',
        3: 'Rab',
        4: 'Kam',
        5: 'Jum',
        6: 'Sab',
        7: 'Min',
      };
      return days[weekday] ?? 'Hari';
    }
  }

  // Nama Kategori
  static String categoryName(String cat) {
    if (!isEn) return cat;
    switch (cat.toLowerCase()) {
      case 'kerja':
        return 'Work';
      case 'pribadi':
        return 'Personal';
      case 'kesehatan':
        return 'Health';
      case 'belajar':
        return 'Study';
      case 'ibadah':
        return 'Worship';
      case 'istirahat':
        return 'Rest';
      case 'santai':
        return 'Leisure';
      case 'umum':
        return 'General';
      default:
        return cat;
    }
  }
}
