import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/plan_model.dart';

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
      version: 1,
      onCreate: _createDB,
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
        category TEXT NOT NULL
      )
    ''');
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

  // Ambil semua jadwal untuk hari tertentu (default: hari ini)
  Future<List<PlanModel>> getPlansByDate(DateTime date) async {
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

  // Ambil semua jadwal masa lalu (sebelum hari ini) untuk riwayat/history
  Future<List<PlanModel>> getHistoryPlans() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (kIsWeb) {
      final past = _inMemoryPlans
          .where((p) => p.scheduledTime.isBefore(startOfToday))
          .toList();
      past.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return past;
    }

    final db = await database;
    final result = await db.query(
      'plans',
      where: 'scheduled_time < ?',
      whereArgs: [startOfToday.toIso8601String()],
      orderBy: 'scheduled_time DESC',
    );

    return result.map((map) => PlanModel.fromMap(map)).toList();
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

  // Tutup koneksi database
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    db.close();
  }
}
