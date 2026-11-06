import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/plan_model.dart';
import 'alarm_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // In-memory fallback untuk testing di Web browser (Chrome)
  final List<PlanModel> _inMemoryPlans = [];
  int _nextWebId = 1;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('valezplan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT,
        scheduled_time TEXT NOT NULL,
        is_alarm_enabled INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        category TEXT NOT NULL,
        repeat_type TEXT NOT NULL DEFAULT 'none',
        early_reminder_minutes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE plans ADD COLUMN repeat_type TEXT NOT NULL DEFAULT 'none'");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE plans ADD COLUMN early_reminder_minutes INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  // Tambah jadwal baru dan mengembalikan ID dari database
  Future<int> insertPlan(PlanModel plan) async {
    if (kIsWeb) {
      final assignedId = _nextWebId++;
      final savedPlan = plan.copyWith(id: assignedId);
      _inMemoryPlans.add(savedPlan);
      return assignedId;
    }
    final db = await database;
    return await db.insert('plans', plan.toMap());
  }

  // Tambah sekumpulan jadwal sekaligus (misal dari template rutinitas)
  Future<List<int>> insertMultiplePlans(List<PlanModel> plans) async {
    final List<int> ids = [];
    for (final plan in plans) {
      final id = await insertPlan(plan);
      ids.add(id);
    }
    return ids;
  }

  // Sinkronisasi otomatis jadwal berulang (rutinitas) ke tanggal yang dibuka
  Future<void> _syncRecurringPlans(DateTime date) async {
    if (kIsWeb) {
      final recurringTemplates = _inMemoryPlans
          .where((p) => p.repeatType != 'none')
          .toList();

      for (var tmpl in recurringTemplates) {
        if (!_isMatchingRepeat(tmpl.repeatType, date)) continue;

        final alreadyExists = _inMemoryPlans.any((p) =>
            p.title == tmpl.title &&
            p.scheduledTime.year == date.year &&
            p.scheduledTime.month == date.month &&
            p.scheduledTime.day == date.day &&
            p.scheduledTime.hour == tmpl.scheduledTime.hour &&
            p.scheduledTime.minute == tmpl.scheduledTime.minute);

        if (!alreadyExists) {
          final instance = tmpl.copyWith(
            id: _nextWebId++,
            scheduledTime: DateTime(date.year, date.month, date.day,
                tmpl.scheduledTime.hour, tmpl.scheduledTime.minute),
            isCompleted: false,
          );
          _inMemoryPlans.add(instance);
        }
      }
      return;
    }

    final db = await database;
    // Cari semua agenda yang memiliki aturan berulang
    final result = await db.query(
      'plans',
      where: "repeat_type != 'none'",
    );

    final templates = result.map((m) => PlanModel.fromMap(m)).toList();
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    // Ambil jadwal yang sudah ada di tanggal target
    final existingPlansResult = await db.query(
      'plans',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startOfDay, endOfDay],
    );
    final existingPlans = existingPlansResult.map((m) => PlanModel.fromMap(m)).toList();

    // Hindari duplikasi template
    final Set<String> processedKeys = {};

    for (var tmpl in templates) {
      final key = '${tmpl.title}_${tmpl.scheduledTime.hour}:${tmpl.scheduledTime.minute}_${tmpl.repeatType}';
      if (processedKeys.contains(key)) continue;
      processedKeys.add(key);

      if (!_isMatchingRepeat(tmpl.repeatType, date)) continue;

      final alreadyExists = existingPlans.any((p) =>
          p.title == tmpl.title &&
          p.scheduledTime.hour == tmpl.scheduledTime.hour &&
          p.scheduledTime.minute == tmpl.scheduledTime.minute);

      if (!alreadyExists) {
        final targetDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          tmpl.scheduledTime.hour,
          tmpl.scheduledTime.minute,
        );

        final newInstance = PlanModel(
          title: tmpl.title,
          notes: tmpl.notes,
          scheduledTime: targetDateTime,
          isAlarmEnabled: tmpl.isAlarmEnabled,
          isCompleted: false,
          category: tmpl.category,
          repeatType: tmpl.repeatType,
          earlyReminderMinutes: tmpl.earlyReminderMinutes,
        );

        final newId = await db.insert('plans', newInstance.toMap());

        // Jika hari ini dan alarm aktif serta belum lewat, jadwalkan alarm
        final now = DateTime.now();
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        if (isToday && tmpl.isAlarmEnabled && targetDateTime.isAfter(now)) {
          await AlarmService.instance.scheduleAlarm(
            id: newId,
            dateTime: targetDateTime,
            title: tmpl.title,
            notes: tmpl.notes,
            earlyReminderMinutes: tmpl.earlyReminderMinutes,
          );
        }
      }
    }
  }

  bool _isMatchingRepeat(String repeatType, DateTime date) {
    if (repeatType == 'daily') return true;
    if (repeatType == 'weekdays') {
      return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
    }
    if (repeatType == 'weekends') {
      return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    }
    return false;
  }

  // Ambil semua jadwal untuk hari tertentu (default: hari ini)
  Future<List<PlanModel>> getPlansByDate(DateTime date) async {
    // 1. Sinkronkan rutinitas berulang terlebih dahulu
    await _syncRecurringPlans(date);

    if (kIsWeb) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final filtered = _inMemoryPlans.where((p) {
        return p.scheduledTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               p.scheduledTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
      filtered.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return filtered;
    }

    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'plans',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'scheduled_time ASC',
    );

    return result.map((map) => PlanModel.fromMap(map)).toList();
  }

  // Ambil semua riwayat: jadwal yang sudah dilaksanakan (selesai) atau jadwal yang sudah lewat
  Future<List<PlanModel>> getHistoryPlans() async {
    final now = DateTime.now();

    if (kIsWeb) {
      final past = _inMemoryPlans
          .where((p) => p.isCompleted || p.scheduledTime.isBefore(now))
          .toList();
      past.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return past;
    }

    final db = await database;
    // Jadwal yang sudah dilaksanakan (is_completed = 1) langsung masuk history,
    // begitu juga jadwal masa lalu yang sudah lewat.
    final result = await db.query(
      'plans',
      where: 'is_completed = 1 OR scheduled_time < ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'scheduled_time DESC',
    );

    return result.map((map) => PlanModel.fromMap(map)).toList();
  }

  // Hapus semua riwayat yang sudah selesai
  Future<int> deleteCompletedHistory() async {
    if (kIsWeb) {
      final before = _inMemoryPlans.length;
      _inMemoryPlans.removeWhere((p) => p.isCompleted);
      return before - _inMemoryPlans.length;
    }

    final db = await database;
    return await db.delete(
      'plans',
      where: 'is_completed = 1',
    );
  }

  // Hapus seluruh riwayat masa lalu dan yang sudah selesai
  Future<int> clearAllHistory() async {
    final now = DateTime.now();
    if (kIsWeb) {
      final before = _inMemoryPlans.length;
      _inMemoryPlans.removeWhere((p) => p.isCompleted || p.scheduledTime.isBefore(now));
      return before - _inMemoryPlans.length;
    }

    final db = await database;
    return await db.delete(
      'plans',
      where: 'is_completed = 1 OR scheduled_time < ?',
      whereArgs: [now.toIso8601String()],
    );
  }

  // Ambil 1 jadwal berdasarkan ID
  Future<PlanModel?> getPlanById(int id) async {
    if (kIsWeb) {
      try {
        return _inMemoryPlans.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final result = await db.query(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return PlanModel.fromMap(result.first);
    }
    return null;
  }

  // Update data jadwal (judul, waktu, catatan, alarm, kategori, dll)
  Future<int> updatePlan(PlanModel plan) async {
    if (plan.id == null) return 0;
    if (kIsWeb) {
      final index = _inMemoryPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _inMemoryPlans[index] = plan;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // Update status checklist (selesai / belum)
  Future<int> toggleComplete(int id, bool isCompleted) async {
    if (kIsWeb) {
      final index = _inMemoryPlans.indexWhere((p) => p.id == id);
      if (index != -1) {
        _inMemoryPlans[index] = _inMemoryPlans[index].copyWith(isCompleted: isCompleted);
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'plans',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hapus jadwal
  Future<int> deletePlan(int id) async {
    if (kIsWeb) {
      _inMemoryPlans.removeWhere((p) => p.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Simpan pengaturan aplikasi (key-value)
  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Ambil pengaturan aplikasi berdasarkan key
  Future<String?> getSetting(String key) async {
    if (kIsWeb) return null;
    final db = await database;
    final res = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }

  // Tutup koneksi database
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    db.close();
  }
}
